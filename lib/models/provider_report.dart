/// User report about a provider listing (inaccurate / harmful / etc.).
class ProviderReportReason {
  static const inaccurateInfo = 'inaccurate_info';
  static const harmfulOrUnsafe = 'harmful_or_unsafe';
  static const wrongIdentityTags = 'wrong_identity_tags';
  static const spamOrDuplicate = 'spam_or_duplicate';
  static const other = 'other';

  static const labels = <String, String>{
    inaccurateInfo: 'Information looks wrong',
    harmfulOrUnsafe: 'Harmful or unsafe content',
    wrongIdentityTags: 'Identity / cultural tags seem wrong',
    spamOrDuplicate: 'Spam or duplicate listing',
    other: 'Other',
  };

  static List<MapEntry<String, String>> get options =>
      labels.entries.toList(growable: false);
}
