import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_external_resources.dart';
import 'app_resources_screen.dart';

Future<void> launchAppExternalUrl(
  BuildContext context,
  String url, {
  String? errorMessage,
}) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  if (!await canLaunchUrl(uri)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Could not open this link.'),
        ),
      );
    }
    return;
  }
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> launchAppExternalPhone(
  BuildContext context,
  String phoneTelUri, {
  String? errorMessage,
}) async {
  final uri = Uri.tryParse(phoneTelUri);
  if (uri == null) return;
  if (!await canLaunchUrl(uri)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Could not start a phone call.'),
        ),
      );
    }
    return;
  }
  await launchUrl(uri);
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
