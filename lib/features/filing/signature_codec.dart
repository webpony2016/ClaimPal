import 'dart:convert';
import 'dart:ui' show Offset;

/// Serializes a hand-drawn signature into a compact, self-describing string so
/// the captured stroke geometry — not just a point count — travels with the
/// filing draft and can be re-rendered, audited, or rasterized later.
///
/// The on-the-wire format is JSON:
///
/// ```json
/// {"v":1,"strokes":[[[x,y],[x,y],...],[...]]}
/// ```
///
/// where each inner list is one continuous pen stroke and each `[x, y]` pair is
/// a point rounded to [_precision] decimal places to keep the payload small.
/// A signature with no points encodes to the empty string, which keeps
/// `FilingDraft.isStep2Complete` (a non-empty check) honest.
class SignatureCodec {
  const SignatureCodec._();

  /// Current schema version, stored under the `v` key so future format changes
  /// can be detected on decode.
  static const int version = 1;

  /// Decimal places retained per coordinate. Sub-pixel precision is wasted on a
  /// finger signature, and trimming it roughly halves the payload size.
  static const int _precision = 2;

  /// Encodes a flat point list — where a `null` marks the end of one stroke and
  /// the start of the next, matching the gesture buffer in the signature pad —
  /// into the JSON string described above. Returns `''` when there are no
  /// points so the caller can treat "no signature" as an empty value.
  static String encode(List<Offset?> points) {
    final strokes = <List<List<double>>>[];
    var current = <List<double>>[];

    for (final point in points) {
      if (point == null) {
        if (current.isNotEmpty) {
          strokes.add(current);
          current = <List<double>>[];
        }
        continue;
      }
      current.add(<double>[_round(point.dx), _round(point.dy)]);
    }
    if (current.isNotEmpty) {
      strokes.add(current);
    }

    if (strokes.isEmpty) {
      return '';
    }
    return jsonEncode(<String, dynamic>{'v': version, 'strokes': strokes});
  }

  /// Decodes a string produced by [encode] back into stroke polylines. Returns
  /// an empty list for an empty/blank string or any payload that does not match
  /// the expected schema, so a malformed value degrades to "no signature"
  /// rather than throwing on a rendering or audit path.
  static List<List<Offset>> decode(String? data) {
    if (data == null || data.trim().isEmpty) {
      return const <List<Offset>>[];
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(data);
    } on FormatException {
      return const <List<Offset>>[];
    }

    if (decoded is! Map || decoded['v'] != version) {
      return const <List<Offset>>[];
    }
    final rawStrokes = decoded['strokes'];
    if (rawStrokes is! List) {
      return const <List<Offset>>[];
    }

    final strokes = <List<Offset>>[];
    for (final rawStroke in rawStrokes) {
      if (rawStroke is! List) continue;
      final stroke = <Offset>[];
      for (final rawPoint in rawStroke) {
        if (rawPoint is! List || rawPoint.length != 2) continue;
        final dx = rawPoint[0];
        final dy = rawPoint[1];
        if (dx is! num || dy is! num) continue;
        stroke.add(Offset(dx.toDouble(), dy.toDouble()));
      }
      if (stroke.isNotEmpty) {
        strokes.add(stroke);
      }
    }
    return strokes;
  }

  static double _round(double value) {
    final factor = _pow10(_precision);
    return (value * factor).roundToDouble() / factor;
  }

  static double _pow10(int exponent) {
    var result = 1.0;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }
}
