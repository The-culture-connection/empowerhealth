import 'package:url_launcher/url_launcher.dart';

/// Hosted legal documentation (Privacy Policy, Terms, EULA).
/// Update only here if the Railway URL or on-page anchors change.
const String kLegalDocsBaseUrl =
    'https://empowerhealth-dev.up.railway.app/public-docs';

/// Fragment anchors on [kLegalDocsBaseUrl] (match headings/ids in the web app).
abstract final class LegalDocsFragments {
  static const String privacy = '#privacy';
  static const String terms = '#terms';
  static const String eula = '#eula';
}

Uri legalDocsUri(String fragment) {
  final f = fragment.startsWith('#') ? fragment : '#$fragment';
  return Uri.parse('$kLegalDocsBaseUrl$f');
}

Future<bool> launchLegalDocs(
  String fragment, {
  LaunchMode mode = LaunchMode.externalApplication,
}) {
  return launchUrl(legalDocsUri(fragment), mode: mode);
}
