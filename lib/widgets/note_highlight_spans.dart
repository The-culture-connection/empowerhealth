import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// A passage of paragraph text that the user highlighted when taking one or
/// more notes. [start]/[end] are offsets into the paragraph's plain text.
class NoteHighlightRange<T> {
  const NoteHighlightRange(this.start, this.end, this.items);

  final int start;
  final int end;

  /// The notes attached to this passage (more than one when highlights
  /// overlap or repeat).
  final List<T> items;
}

/// Finds [needle] in [text]. Exact match first, then a whitespace-tolerant
/// match (runs of spaces/newlines in either string compare equal).
/// Returns the matched `(start, end)` or null.
(int, int)? locateHighlight(String text, String needle) {
  final n = needle.trim();
  if (n.isEmpty || text.isEmpty) return null;
  final exact = text.indexOf(n);
  if (exact >= 0) return (exact, exact + n.length);
  final tokens = n
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .map(RegExp.escape)
      .toList();
  if (tokens.isEmpty) return null;
  final m = RegExp(tokens.join(r'\s+')).firstMatch(text);
  if (m == null || m.end <= m.start) return null;
  return (m.start, m.end);
}

/// Locates each item's highlighted text in [text] (first occurrence) and
/// returns sorted, non-overlapping ranges. Overlapping highlights are merged
/// into one range that carries all of their items. Items whose text is
/// shorter than [minLength] or isn't found are skipped.
List<NoteHighlightRange<T>> findNoteHighlightRanges<T>(
  String text,
  Iterable<T> items,
  String? Function(T item) highlightOf, {
  int minLength = 2,
}) {
  final found = <NoteHighlightRange<T>>[];
  for (final item in items) {
    final needle = highlightOf(item)?.trim();
    if (needle == null || needle.length < minLength) continue;
    final match = locateHighlight(text, needle);
    if (match == null) continue;
    found.add(NoteHighlightRange<T>(match.$1, match.$2, [item]));
  }
  if (found.length < 2) return found;

  found.sort((a, b) =>
      a.start != b.start ? a.start.compareTo(b.start) : b.end.compareTo(a.end));
  final merged = <NoteHighlightRange<T>>[];
  var current = found.first;
  for (final next in found.skip(1)) {
    if (next.start < current.end) {
      current = NoteHighlightRange<T>(
        current.start,
        math.max(current.end, next.end),
        [...current.items, ...next.items],
      );
    } else {
      merged.add(current);
      current = next;
    }
  }
  merged.add(current);
  return merged;
}

/// Splits flat [spans] (TextSpans with only `text` + `style`) so the text
/// inside each of [ranges] gets [highlightStyle], and inserts the span from
/// [emblemBuilder] right after each highlighted passage.
///
/// [ranges] must be sorted, non-overlapping and within the spans' combined
/// text (as returned by [findNoteHighlightRanges]).
List<InlineSpan> applyNoteHighlights<T>(
  List<TextSpan> spans,
  List<NoteHighlightRange<T>> ranges, {
  required TextStyle Function(TextStyle? base) highlightStyle,
  required InlineSpan Function(NoteHighlightRange<T> range) emblemBuilder,
}) {
  if (ranges.isEmpty) return List<InlineSpan>.of(spans);
  final out = <InlineSpan>[];
  var offset = 0;
  var ri = 0;
  for (final span in spans) {
    final t = span.text ?? '';
    var local = 0;
    while (local < t.length) {
      final range = ri < ranges.length ? ranges[ri] : null;
      if (range == null || offset + local < range.start) {
        final stop =
            range == null ? t.length : math.min(t.length, range.start - offset);
        out.add(TextSpan(text: t.substring(local, stop), style: span.style));
        local = stop;
      } else {
        final stop = math.min(t.length, range.end - offset);
        out.add(
          TextSpan(
            text: t.substring(local, stop),
            style: highlightStyle(span.style),
          ),
        );
        local = stop;
        if (offset + local >= range.end) {
          out.add(emblemBuilder(range));
          ri++;
        }
      }
    }
    offset += t.length;
  }
  return out;
}
