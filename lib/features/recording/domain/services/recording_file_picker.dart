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
  const FilePickerRecordingPicker();

  /// Common consumer recording formats — the decoder may support more,
  /// but these are the formats the product advertises.
  static const supportedExtensions = [
    'wav', 'mp3', 'm4a', 'aac', 'ogg', 'opus', 'flac',
  ];

  @override
  Future<PickedRecording?> pickRecording() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: supportedExtensions,
    );
    if (file == null) return null; // user cancelled — normal outcome
    // Reported size is available before the bytes are read, letting
    // oversized files be rejected without a full load.
    final size = file.lengthSync() ?? await file.length() ?? 0;
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
