import 'package:flutter/material.dart';

import 'bloc/safecall_state.dart';
import 'screens/safecall_screen.dart';
import 'widgets/post_call_safety_sheet.dart';

/// Shared SafeCall entry flow — used by Home and the onboarding
/// completion CTA so both paths get identical session + post-call
/// safety-sheet behavior. Never auto-starts the mic: the user picks
/// Live Mic or Demo inside the SafeCall screen.
Future<void> launchSafeCall(BuildContext context) async {
  final ended = await Navigator.of(context, rootNavigator: true)
      .push<SafeCallEnded>(
    MaterialPageRoute<SafeCallEnded>(
      builder: (_) => const SafeCallScreen(),
    ),
  );
  if (ended == null || !context.mounted) return;
  // Post-call safety flow: why flagged → verify identity → optional
  // family alert → incident summary.
  await PostCallSafetySheet.show(context, ended);
}
