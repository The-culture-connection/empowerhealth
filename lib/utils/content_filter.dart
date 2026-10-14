/// Client-side objectionable-content filter for user-generated text.
///
/// Supports App Store Guideline 1.2 (Safety – User-Generated Content), which
/// requires a method for filtering objectionable content. This is a first-pass
/// filter that blocks submission of clearly abusive/objectionable language; it
/// is intentionally conservative to avoid false positives on health topics.
///
/// A server-side re-scan (Cloud Function) should back this up so the check
/// cannot be bypassed by a modified client.
class ContentFilter {
  ContentFilter._();

  /// Slurs / hate terms and explicit sexual terms that are never appropriate
  /// in this community. Matched on word boundaries, case-insensitive.
  static const List<String> _blockedTerms = [
    // Hate / slurs
    'nigger', 'nigga', 'faggot', 'fag', 'retard', 'retarded', 'spic', 'chink',
    'kike', 'wetback', 'tranny', 'coon',
    // Explicit sexual
    'cunt', 'whore', 'slut',
    // Severe harassment
    'kill yourself', 'kys',
  ];

  /// Returns `null` if [text] is acceptable, otherwise a short, user-facing
  /// reason explaining why the content was blocked.
  static String? check(String text) {
    final normalized = text.toLowerCase();
    for (final term in _blockedTerms) {
      final pattern = RegExp(
        r'(^|[^a-z0-9])' + RegExp.escape(term) + r'($|[^a-z0-9])',
        caseSensitive: false,
      );
      if (pattern.hasMatch(normalized)) {
        return 'Your post appears to contain language that violates our '
            'community guidelines. Please revise it and try again.';
      }
    }
    return null;
  }

  /// Convenience: true when [text] passes the filter.
  static bool isClean(String text) => check(text) == null;
}
