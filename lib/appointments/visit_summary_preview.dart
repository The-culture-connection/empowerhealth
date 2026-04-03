// Shared logic for visit summary preview lines on Home and My Visits.
// Handles Firestore edge cases: summary stored as a Map, missing summaryData,
// or summary string containing a Dart map-style dump instead of markdown.

String formatSummaryFromMap(Map<String, dynamic> summaryMap) {
  final buffer = StringBuffer();

  void block(String heading, String body) {
    final t = body.trim();
    if (t.isEmpty) return;
    buffer.writeln(heading);
    buffer.writeln(t);
    buffer.writeln();
  }

  final wtm = summaryMap['whatThisMeans']?.toString() ?? '';
  if (wtm.trim().isNotEmpty) {
    block('## What This Means', wtm);
  }

  if (summaryMap['howBabyIsDoing'] != null) {
    block('## How Your Baby Is Doing', summaryMap['howBabyIsDoing'].toString());
  }

  if (summaryMap['howYouAreDoing'] != null) {
    block('## How You Are Doing', summaryMap['howYouAreDoing'].toString());
  }

  final nextParts = <String>[];
  final ins = summaryMap['importantNextSteps']?.toString().trim();
  if (ins != null && ins.isNotEmpty) nextParts.add(ins);
  final ns = summaryMap['nextSteps']?.toString().trim();
  if (ns != null && ns.isNotEmpty) nextParts.add(ns);
  final fu = summaryMap['followUpInstructions']?.toString().trim();
  if (fu != null && fu.isNotEmpty) nextParts.add(fu);
  if (summaryMap['empowermentTips'] is List) {
    for (final t in summaryMap['empowermentTips'] as List) {
      if (t != null && t.toString().trim().isNotEmpty) {
        nextParts.add(t.toString().trim());
      }
    }
  }
  if (nextParts.isNotEmpty) {
    block('## Important Next Steps', nextParts.join('\n\n'));
  }

  if (summaryMap['medications'] is List &&
      (summaryMap['medications'] as List).isNotEmpty) {
    buffer.writeln('## Medications Mentioned');
    for (final med in summaryMap['medications'] as List) {
      if (med is! Map) continue;
      final name = med['name']?.toString() ?? 'Medication';
      final purpose = med['purpose']?.toString();
      final instr = med['instructions']?.toString();
      var line = '**$name**';
      if (purpose != null && purpose.isNotEmpty) line += ': $purpose';
      if (instr != null && instr.isNotEmpty) line += ' — $instr';
      buffer.writeln(line);
    }
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

  final wtmMatch = RegExp(
    r'## What This Means\n(.*?)(?=\n## |$)',
    dotAll: true,
  ).firstMatch(summary);
  if (wtmMatch != null) {
    final content = wtmMatch.group(1)?.trim() ?? '';
    final firstSentence = content.split('.').first;
    if (firstSentence.isNotEmpty && firstSentence.length < 100) {
      return '$firstSentence.';
    }
    return content.length > 100
        ? '${content.substring(0, 100)}...'
        : content;
  }

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
