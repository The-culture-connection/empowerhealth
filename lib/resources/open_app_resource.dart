import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_external_resources.dart';
import 'app_resources_screen.dart';

/// Tries [launchUrl] directly (no `canLaunchUrl` pre-check: on iOS that
/// returns false for schemes not listed in LSApplicationQueriesSchemes, which
/// blocked valid links / `tel:`). Never navigates — the user returns to the
/// same screen. Shows a SnackBar on failure.
Future<bool> _tryLaunch(
  BuildContext context,
  Uri? uri, {
  required LaunchMode mode,
  required String errorMessage,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  var ok = false;
  if (uri != null) {
    try {
      ok = await launchUrl(uri, mode: mode);
    } catch (_) {
      ok = false;
    }
  }
  if (!ok) {
    messenger?.showSnackBar(SnackBar(content: Text(errorMessage)));
  }
  return ok;
}

Future<void> launchAppExternalUrl(
  BuildContext context,
  String url, {
  String? errorMessage,
}) async {
  // Safari (external) keeps the app's navigation stack intact; users return
  // to the same screen via the iOS back-to-app control or app switcher.
  await _tryLaunch(
    context,
    Uri.tryParse(url),
    mode: LaunchMode.externalApplication,
    errorMessage: errorMessage ?? 'Could not open this link.',
  );
}

Future<void> launchAppExternalPhone(
  BuildContext context,
  String phoneTelUri, {
  String? errorMessage,
}) async {
  await _tryLaunch(
    context,
    Uri.tryParse(phoneTelUri),
    mode: LaunchMode.platformDefault,
    errorMessage: errorMessage ?? 'Could not start a phone call.',
  );
}

/// Opens in-app resources directory, optionally scrolled to [highlightResourceId].
Future<void> openAppResourcesScreen(
  BuildContext context, {
  String? highlightResourceId,
  String? categoryFilter,
}) async {
  await Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => AppResourcesScreen(
        highlightResourceId: highlightResourceId,
        categoryFilter: categoryFilter,
      ),
    ),
  );
}

/// Opens a known catalog link in the browser, or the resources page if [openInAppFirst].
Future<void> openAppResourceById(
  BuildContext context,
  String resourceId, {
  bool openInAppFirst = false,
}) async {
  if (openInAppFirst) {
    await openAppResourcesScreen(context, highlightResourceId: resourceId);
    return;
  }
  final resource = appExternalResourceById(resourceId);
  if (resource == null) {
    await openAppResourcesScreen(context);
    return;
  }
  await launchAppExternalUrl(context, resource.url);
}
