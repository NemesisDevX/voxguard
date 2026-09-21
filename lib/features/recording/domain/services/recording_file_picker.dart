import 'package:file_picker/file_picker.dart';

import '../models/recording_models.dart';

/// VoxGuard seam over the platform file picker — UI code never calls
/// the plugin directly, so tests inject a fake with no platform
/// channel.
abstract interface class IRecordingFilePicker {
  /// Lets the user select exactly one audio file. Returns `null` on
  /// cancellation — a normal outcome, not an error.
  Future<PickedRecording?> pickRecording();
}

/// `file_picker`-backed implementation. Reads the bytes up front so
/// nothing downstream depends on a sandbox file path — the picker
/// grant can lapse before decode finishes on some OSes.
final class FilePickerRecordingPicker implements IRecordingFilePicker {
  const FilePickerRecordingPicker({
    Future<PlatformFile?> Function({
      FileType type,
      List<String>? allowedExtensions,
    })? pickFile,
  }) : _pickFile = pickFile ?? FilePicker.pickFile;

  /// Seam over `FilePicker.pickFile` — tests supply a stub
  /// `PlatformFile` so no platform channel is touched.
  final Future<PlatformFile?> Function({
    FileType type,
    List<String>? allowedExtensions,
  }) _pickFile;

  /// Common consumer recording formats — the decoder may support more,
  /// but these are the formats the product advertises.
  static const supportedExtensions = [
    'wav', 'mp3', 'm4a', 'aac', 'ogg', 'opus', 'flac',
  ];

  @override
  Future<PickedRecording?> pickRecording() async {
    final file = await _pickFile(
      type: FileType.custom,
      allowedExtensions: supportedExtensions,
    );
    if (file == null) return null; // user cancelled — normal outcome

    // When the platform already knows the size, reject oversized
    // picks BEFORE readAsBytes — the file is never buffered.
    final knownSize = file.lengthSync();
    if (knownSize != null && knownSize > kMaxRecordingSourceBytes) {
      throw const RecordingAnalysisException(
        'That file is too large — recordings up to 25 MB are '
        'supported.',
        code: 'tooLarge',
      );
    }

    // Post-read size still runs through the analyzer's own check —
    // some platforms cannot report a size before reading.
    final size = knownSize ?? await file.length() ?? 0;
    final bytes = await file.readAsBytes();
    final ext = (file.extension ?? '').toLowerCase();
    return PickedRecording(
      name: file.name,
      extension: ext.isEmpty ? 'audio' : ext,
      sizeBytes: size,
      bytes: bytes,
    );
  }
}
