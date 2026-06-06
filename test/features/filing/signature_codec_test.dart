import 'dart:convert';

import 'package:claimpal/features/filing/signature_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SignatureCodec.encode', () {
    test('returns empty string when there are no points', () {
      expect(SignatureCodec.encode(const <Offset?>[]), isEmpty);
    });

    test('returns empty string when points contain only stroke breaks', () {
      expect(SignatureCodec.encode(<Offset?>[null, null]), isEmpty);
    });

    test('encodes a single stroke as schema-versioned JSON', () {
      final encoded = SignatureCodec.encode(<Offset?>[
        const Offset(1, 2),
        const Offset(3, 4),
      ]);

      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(decoded['v'], SignatureCodec.version);
      expect(
        decoded['strokes'],
        <List<List<double>>>[
          <List<double>>[
            <double>[1, 2],
            <double>[3, 4],
          ],
        ],
      );
    });

    test('splits points into separate strokes on null breaks', () {
      final encoded = SignatureCodec.encode(<Offset?>[
        const Offset(0, 0),
        const Offset(1, 1),
        null,
        const Offset(5, 5),
      ]);

      final strokes = SignatureCodec.decode(encoded);
      expect(strokes, hasLength(2));
      expect(strokes[0], <Offset>[const Offset(0, 0), const Offset(1, 1)]);
      expect(strokes[1], <Offset>[const Offset(5, 5)]);
    });

    test('rounds coordinates to two decimal places', () {
      final encoded = SignatureCodec.encode(<Offset?>[
        const Offset(1.23456, 7.89123),
      ]);

      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(
        decoded['strokes'],
        <List<List<double>>>[
          <List<double>>[
            <double>[1.23, 7.89],
          ],
        ],
      );
    });
  });

  group('SignatureCodec.decode', () {
    test('returns empty list for null, empty, or blank input', () {
      expect(SignatureCodec.decode(null), isEmpty);
      expect(SignatureCodec.decode(''), isEmpty);
      expect(SignatureCodec.decode('   '), isEmpty);
    });

    test('returns empty list for malformed JSON', () {
      expect(SignatureCodec.decode('not json'), isEmpty);
    });

    test('returns empty list for a version mismatch', () {
      final payload = jsonEncode(<String, dynamic>{
        'v': SignatureCodec.version + 1,
        'strokes': <dynamic>[
          <dynamic>[
            <dynamic>[1, 2],
          ],
        ],
      });
      expect(SignatureCodec.decode(payload), isEmpty);
    });

    test('skips malformed points and empty strokes', () {
      final payload = jsonEncode(<String, dynamic>{
        'v': SignatureCodec.version,
        'strokes': <dynamic>[
          <dynamic>[
            <dynamic>[1, 2],
            <dynamic>['bad', 'point'],
            <dynamic>[3],
          ],
          <dynamic>[],
        ],
      });

      final strokes = SignatureCodec.decode(payload);
      expect(strokes, hasLength(1));
      expect(strokes[0], <Offset>[const Offset(1, 2)]);
    });

    test('round-trips a multi-stroke signature', () {
      final points = <Offset?>[
        const Offset(10.5, 20.25),
        const Offset(11, 21),
        null,
        const Offset(30, 40),
        const Offset(31.75, 41.5),
      ];

      final strokes = SignatureCodec.decode(SignatureCodec.encode(points));
      expect(strokes, <List<Offset>>[
        <Offset>[const Offset(10.5, 20.25), const Offset(11, 21)],
        <Offset>[const Offset(30, 40), const Offset(31.75, 41.5)],
      ]);
    });
  });
}
