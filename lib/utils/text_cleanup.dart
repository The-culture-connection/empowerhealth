/// Turns an accidental double period ("levels.. Take") into one, without
/// touching real ellipses ("..." or "…"). Used for AI-generated summaries saved
/// before the server formatter was fixed.
String fixDoublePeriods(String text) =>
    text.replaceAll(RegExp(r'(?<!\.)\.\.(?!\.)'), '.');
