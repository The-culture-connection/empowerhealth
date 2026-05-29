import 'package:flutter/material.dart';

import 'immediate_support_checkin_screen.dart';

/// Opens the universal immediate support check-in from anywhere in the app.
Future<void> openImmediateSupport(
  BuildContext context, {
  String entrySource = 'unknown',
}) {
  return Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => ImmediateSupportCheckInScreen(entrySource: entrySource),
    ),
  );
}
