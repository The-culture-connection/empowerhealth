// Shared logic for visit summary preview lines on Home and My Visits.
// Handles Firestore edge cases: summary stored as a Map, missing summaryData,
// or summary string containing a Dart map-style dump instead of markdown.

String formatSummaryFromMap(Map<String, dynamic> summaryMap) {
  final buffer = StringBuffer();

  if (summaryMap['howBabyIsDoing'] != null) {
    buffer.writeln('## How Your Baby Is Doing');
    buffer.writeln(summaryMap['howBabyIsDoing']);
    buffer.writeln();
  }

  if (summaryMap['howYouAreDoing'] != null) {
    buffer.writeln('## How You Are Doing');
    buffer.writeln(summaryMap['howYouAreDoing']);
    buffer.writeln();
  }

  if (summaryMap['nextSteps'] != null) {
    buffer.writeln('## Actions To Take');
    buffer.writeln(summaryMap['nextSteps']);
    buffer.writeln();
  }

  if (summaryMap['followUpInstructions'] != null) {
    buffer.writeln(summaryMap['followUpInstructions']);
    buffer.writeln();
  }

  if (summaryMap['keyMedicalTerms'] != null &&
      summaryMap['keyMedicalTerms'] is List) {
    buffer.writeln('## Key Medical Terms Explained');
    for (final term in summaryMap['keyMedicalTerms'] as List) {
      if (term is Map) {
        buffer.writeln('**${term['term']}**: ${term['explanation']}');
      }
    }
    buffer.writeln();
  }

  if (summaryMap['questionsToAsk'] != null &&
      summaryMap['questionsToAsk'] is List) {
    buffer.writeln('## Questions to Ask at Your Next Visit');
    for (int i = 0; i < (summaryMap['questionsToAsk'] as List).length; i++) {
      buffer.writeln('${i + 1}. ${summaryMap['questionsToAsk'][i]}');
    }
    buffer.writeln();
  }

  if (summaryMap['visitNotes'] != null &&
      summaryMap['visitNotes'] is List &&
      (summaryMap['visitNotes'] as List).isNotEmpty) {
    buffer.writeln('## Notes');
    for (final n in summaryMap['visitNotes'] as List) {
      if (n != null && n.toString().trim().isNotEmpty) {
        buffer.writeln('- ${n.toString().trim()}');
      }
    }
    buffer.writeln();
  }

  return buffer.toString();
}

String extractPreviewText(String? summary) {
  if (summary == null) return '';

  final babyMatch = RegExp(
    r'## How Your Baby Is Doing\n(.*?)(?=\n## |$)',
    dotAll: true,
  ).firstMatch(summary);
  if (babyMatch != null) {
    final content = babyMatch.group(1)?.trim() ?? '';
    final firstSentence = content.split('.').first;
    if (firstSentence.isNotEmpty && firstSentence.length < 100) {
      return '$firstSentence.';
    }
    return content.length > 100
        ? '${content.substring(0, 100)}...'
        : content;
  }

  final lines = summary.split('\n');
  for (final line in lines) {
    if (line.trim().isNotEmpty && !line.startsWith('#')) {
      return line.trim();
    }
  }

  return summary.split('\n').first.replaceAll('#', '').trim();
}

bool _looksLikeDartMapDump(String t) {
  final s = t.trimLeft();
  if (!s.startsWith('{')) return false;
  return s.contains('questionsToAsk:') ||
      s.contains('howBabyIsDoing:') ||
      s.contains('howYouAreDoing:') ||
      s.contains('visitNotes:');
}

Map<String, dynamic>? _structuredSummaryMap(Map<String, dynamic> data) {
  final sd = data['summaryData'];
  if (sd is Map<String, dynamic>) return sd;
  if (sd is Map) return Map<String, dynamic>.from(sd);
  final sm = data['summary'];
  if (sm is Map<String, dynamic>) return sm;
  if (sm is Map) return Map<String, dynamic>.from(sm);
  return null;
}

/// Single line or short snippet for cards and list rows.
String? previewLineFromVisitSummary(Map<String, dynamic> data) {
  final structured = _structuredSummaryMap(data);
  if (structured != null) {
    final formatted = formatSummaryFromMap(structured).trim();
    if (formatted.isEmpty) return null;
    final line = extractPreviewText(formatted);
    return line.isEmpty ? null : line;
  }

  final raw = data['summary'];
  if (raw is String && raw.trim().isNotEmpty) {
    final t = raw.trim();
    if (_looksLikeDartMapDump(t)) {
      return null;
    }
    final line = extractPreviewText(t);
    return line.isEmpty ? null : line;
  }

  return null;
}
