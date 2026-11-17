/// On-device safety screen for AI Assistant messages.
///
/// The model is told to put safety first, but a prompt is not a guarantee.
/// This check runs before anything is sent, so emergency and crisis actions
/// appear instantly and even if the AI reply is slow, fails, or misses it.
/// It is deliberately broad: a false alarm costs one extra card, a miss could
/// cost a life.
library;

enum AssistantSafetyLevel {
  none,

  /// Urgent maternal warning signs (CDC Hear Her / AIM list): get care now.
  maternalEmergency,

  /// Direct or indirect thoughts of suicide or self-harm, or of harming the baby.
  mentalHealthCrisis,
}

/// Firestore value stored on the user message, so the card stays in history.
String? assistantSafetyFieldValue(AssistantSafetyLevel level) {
  switch (level) {
    case AssistantSafetyLevel.maternalEmergency:
      return 'maternal_emergency';
    case AssistantSafetyLevel.mentalHealthCrisis:
      return 'mental_health_crisis';
    case AssistantSafetyLevel.none:
      return null;
  }
}

AssistantSafetyLevel assistantSafetyFromField(Object? value) {
  switch (value) {
    case 'maternal_emergency':
      return AssistantSafetyLevel.maternalEmergency;
    case 'mental_health_crisis':
      return AssistantSafetyLevel.mentalHealthCrisis;
    default:
      return AssistantSafetyLevel.none;
  }
}

RegExp _re(String pattern) => RegExp(pattern, caseSensitive: false);

// Crisis wording, including indirect forms like "they'd be better off without me".
final List<RegExp> _crisisPatterns = [
  _re(r'\bsuicid'),
  _re(r'\bkill(ing)?\s+my\s*self\b'),
  _re(r'\b(end|take)\s+my\s+(own\s+)?life\b'),
  _re(r'\bend\s+it\s+all\b'),
  _re(r'\b(want|wanted|wanting)\s+to\s+die\b'),
  _re(r"\bwish\s+i\s+(was|were)\s+(dead|gone|never\s+born)\b"),
  _re(r"\bbetter\s+off\s+without\s+me\b"),
  _re(r"\bbetter\s+off\s+if\s+i\s+(was|were|wasn'?t|weren'?t)\b"),
  _re(r"\bbetter\s+off\s+(dead|gone)\b"),
  _re(r'\bno\s+(reason|point)\s+(to|in)\s+(live|living|go(ing)?\s+on)\b'),
  _re(r"\b(can'?t|cannot)\s+go\s+on\b"),
  _re(r"\bdon'?t\s+want\s+to\s+(be\s+here|live|exist|wake\s+up)\b"),
  _re(r'\b(hurt|harm|cut)(ing)?\s+my\s*self\b'),
  _re(r'\bself[\s-]?harm'),
  _re(r'\b(hurt|harm|shake|smother)(ing)?\s+(my|the)\s+baby\b'),
  _re(r'\bthoughts?\s+of\s+(hurting|harming)\b'),
  _re(r'\bdisappear\s+(forever|for\s+good)\b'),
  _re(r'\bnot\s+be\s+(here|around)\s+anymore\b'),
];

// Signs that mean "get care now" on their own.
final List<RegExp> _emergencyPatterns = [
  // Heavy bleeding / hemorrhage.
  _re(
    r'\bsoak(ing|ed|s)?\s+(through\s+)?(a|one|my|the|\d+)?\s*(pad|pads|maxi)',
  ),
  _re(r'\b(pad|pads)\s+(every|each|in\s+(an?|one|less\s+than))\b'),
  _re(r'\b(heavy|heavily|lots?\s+of|a\s+lot\s+of|gushing)\s+bleed'),
  _re(r'\bbleeding\s+(heavily|a\s+lot|really\s+bad|won.?t\s+stop)'),
  _re(r'\b(large|big|golf\s*ball|egg)[\s-]*(sized\s+)?clots?\b'),
  _re(r'\bhemorrhag|\bhaemorrhag'),
  // Breathing, chest, seizure, fainting, stroke signs.
  _re(r'\bchest\s+pain'),
  _re(
    r"\b(can'?t|cannot|hard\s+to|trouble|difficulty|struggling\s+to)\s+(catch\s+my\s+)?breath",
  ),
  _re(r'\bshort(ness)?\s+of\s+breath'),
  _re(r'\bseizure|\bconvuls'),
  _re(
    r'\b(faint(ed|ing)?|passed\s+out|pass\s+out|blacked\s+out|unconscious)\b',
  ),
  _re(r'\b(face|mouth)\s+(is\s+)?droop|\bslurred\s+speech'),
  // Possible preeclampsia / eclampsia.
  _re(r'\b(severe|bad|terrible|worst|pounding|really\s+bad)\s+headache'),
  _re(r"\bheadache\s+(that\s+)?(won'?t|will\s+not|doesn'?t)\s+go\s+away"),
  // The condition name alone is often a learning question; its symptoms
  // (headache with vision changes or swelling) are caught below instead.
  _re(
    r'\b(blurry|blurred|double)\s+vision|\bseeing\s+(spots|stars|flashing)|\bvision\s+(changes?|loss|is\s+blurry)',
  ),
  _re(
    r'\b(face|facial|hands?)\s+(is\s+|are\s+)?(very\s+|really\s+)?(swollen|swelling|puffy)|\bswelling\s+(in|of)\s+(my\s+)?(face|hands)\b',
  ),
  // Baby movement.
  _re(
    r"\bbaby\s+(is\s+|has\s+)?(not|isn'?t|hasn'?t|stopped|stop)\s+(been\s+)?mov",
  ),
  _re(
    r'\b(no|less|fewer|decreased|reduced)\s+(fetal\s+|baby\s+)?(movement|movements|kicks)\b',
  ),
  // Fever, severe pain, leg clot signs.
  _re(r'\bfever\s+(of\s+|over\s+|above\s+)?(100\.4|10[1-5])'),
  _re(r'\b(severe|bad|terrible)\s+(belly|stomach|abdominal|pelvic)\s+pain'),
  _re(
    r'\b(leg|calf)\s+(is\s+)?(swollen|red|hot|painful).{0,40}\b(swollen|red|hot|pain)',
  ),
  // Bleeding or leaking fluid in pregnancy.
  _re(r'\bvaginal\s+bleeding'),
];

// Two softer signs together also count (e.g. headache + blurry vision).
final RegExp _headache = _re(r'\bheadache|\bmigraine');
final RegExp _visionOrSwelling = _re(
  r'\bvision|\bblurr|\bspots\b|\bswell|\bswollen|\bpuffy',
);
final RegExp _bleeding = _re(r'\bbleed|\bblood|\bclots?\b|\bpad\b|\bpads\b');
final RegExp _dizzy = _re(
  r'\bdizz|\blight[\s-]?headed|\bweak\b|\bracing\s+heart|\bheart\s+racing',
);

// Key words worth correcting when misspelled. People in distress type fast,
// so "killing myseld" must still count as "killing myself".
const List<String> _typoKeywords = [
  'myself',
  'suicide',
  'suicidal',
  'kill',
  'killing',
  'hurting',
  'harming',
  'smother',
  'without',
  'better',
  'anymore',
  'disappear',
  'living',
  'bleeding',
  'headache',
  'vision',
  'blurry',
  'blurred',
  'swollen',
  'swelling',
  'breath',
  'breathe',
  'breathing',
  'seizure',
  'fainted',
  'fainting',
  'unconscious',
  'hemorrhage',
  'movement',
  'movements',
  'dizzy',
  'lightheaded',
  'severe',
  'terrible',
  'chest',
  'vaginal',
];

// Real words one letter away from a key word; never "correct" these.
const Set<String> _typoKeep = {
  'spelling',
  'smelling',
  'breeding',
  'breach',
  'chess',
  'cheat',
  'kiln',
  'kilt',
  'kilo',
  'hunting',
  'hurling',
  'loving',
  'batter',
  'bitter',
  'smoother',
  'blurted',
  'visions',
  'fainter',
};

// Optimal string alignment distance (edits plus swapped neighbours), capped.
int _editDistance(String a, String b, int cap) {
  if ((a.length - b.length).abs() > cap) return cap + 1;
  final rows = List.generate(
    a.length + 1,
    (_) => List<int>.filled(b.length + 1, 0),
  );
  for (var i = 0; i <= a.length; i++) {
    rows[i][0] = i;
  }
  for (var j = 0; j <= b.length; j++) {
    rows[0][j] = j;
  }
  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      var best = rows[i - 1][j] + 1;
      if (rows[i][j - 1] + 1 < best) best = rows[i][j - 1] + 1;
      if (rows[i - 1][j - 1] + cost < best) best = rows[i - 1][j - 1] + cost;
      if (i > 1 &&
          j > 1 &&
          a[i - 1] == b[j - 2] &&
          a[i - 2] == b[j - 1] &&
          rows[i - 2][j - 2] + 1 < best) {
        best = rows[i - 2][j - 2] + 1;
      }
      rows[i][j] = best;
    }
  }
  return rows[a.length][b.length];
}

String _fixWord(String word) {
  final lower = word.toLowerCase();
  if (lower.length < 3 || _typoKeep.contains(lower)) return word;
  for (final key in _typoKeywords) {
    if (key == lower) return word;
  }
  for (final key in _typoKeywords) {
    if (key[0] != lower[0]) continue;
    final allowed = key.length >= 9 ? 2 : 1;
    if (_editDistance(lower, key, allowed) <= allowed) return key;
  }
  return word;
}

/// The message with likely misspellings of key safety words corrected.
String normalizeSafetyTypos(String text) =>
    text.replaceAllMapped(RegExp(r'[A-Za-z]+'), (m) => _fixWord(m[0]!));

AssistantSafetyLevel detectAssistantSafety(String message) {
  final text = message.trim();
  if (text.isEmpty) return AssistantSafetyLevel.none;
  final exact = _detect(text);
  if (exact != AssistantSafetyLevel.none) return exact;
  final corrected = normalizeSafetyTypos(text);
  return corrected == text ? exact : _detect(corrected);
}

AssistantSafetyLevel _detect(String text) {
  // Crisis wins: it needs 988 and a direct safety question first.
  for (final p in _crisisPatterns) {
    if (p.hasMatch(text)) return AssistantSafetyLevel.mentalHealthCrisis;
  }
  for (final p in _emergencyPatterns) {
    if (p.hasMatch(text)) return AssistantSafetyLevel.maternalEmergency;
  }
  if (_headache.hasMatch(text) && _visionOrSwelling.hasMatch(text)) {
    return AssistantSafetyLevel.maternalEmergency;
  }
  if (_bleeding.hasMatch(text) && _dizzy.hasMatch(text)) {
    return AssistantSafetyLevel.maternalEmergency;
  }
  return AssistantSafetyLevel.none;
}
