/// Display-time helper that rewrites common third-person clinical phrasing
/// ("The patient's ...", "the patient has been ...") into second person
/// ("Your ...", "you have been ...") for already-stored generated text.
///
/// Intentionally conservative: only phrases built around "the patient" are
/// rewritten, and the capitalisation of the leading word is preserved.
class SecondPerson {
  SecondPerson._();

  // Ordered most-specific first. Each pattern starts with "the patient"
  // (case-insensitive on the "T" only) followed by a word boundary.
  static final List<MapEntry<RegExp, String>> _rules = [
    MapEntry(RegExp(r"\b([Tt])he patient(?:'|’)s\b"), 'your'),
    MapEntry(RegExp(r'\b([Tt])he patient has been\b'), 'you have been'),
    MapEntry(RegExp(r'\b([Tt])he patient has\b'), 'you have'),
    MapEntry(RegExp(r'\b([Tt])he patient was\b'), 'you were'),
    MapEntry(RegExp(r'\b([Tt])he patient is\b'), 'you are'),
    MapEntry(RegExp(r'\b([Tt])he patient does\b'), 'you do'),
    MapEntry(RegExp(r'\b([Tt])he patient needs\b'), 'you need'),
    MapEntry(RegExp(r'\b([Tt])he patient should\b'), 'you should'),
    MapEntry(RegExp(r'\b([Tt])he patient\b'), 'you'),
  ];

  /// Returns [text] with "the patient" phrasing converted to second person.
  static String convert(String text) {
    if (text.isEmpty || !text.toLowerCase().contains('the patient')) {
      return text;
    }
    var out = text;
    for (final rule in _rules) {
      out = out.replaceAllMapped(rule.key, (m) {
        final capital = m.group(1) == 'T';
        final replacement = rule.value;
        return capital
            ? replacement[0].toUpperCase() + replacement.substring(1)
            : replacement;
      });
    }
    return out;
  }
}
