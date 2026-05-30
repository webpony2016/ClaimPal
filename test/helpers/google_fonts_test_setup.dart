import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_fonts/src/google_fonts_base.dart' as gf_base;

/// Inter variants used by `AppTextStyles` / the app theme, expressed as the
/// google_fonts API filename prefix (see google_fonts_variant.dart:
/// w400=Regular, w500=Medium, w600=SemiBold, w700=Bold).
const List<String> _interAssetPaths = <String>[
  'google_fonts/Inter-Regular.ttf',
  'google_fonts/Inter-Medium.ttf',
  'google_fonts/Inter-SemiBold.ttf',
  'google_fonts/Inter-Bold.ttf',
];

/// Configures google_fonts so `GoogleFonts.inter(...)` resolves Inter from a
/// mocked, bundled asset instead of attempting a network fetch.
///
/// Tests that build the theme or any `GoogleFonts.inter` style must call this
/// in `main()` (after `TestWidgetsFlutterBinding.ensureInitialized()`). The
/// font loader then finds the family in the (mocked) asset manifest and loads
/// real TTF bytes, keeping unit tests offline and deterministic.
///
/// Follows the pattern from the google_fonts package's own tests.
void setupGoogleFontsForTesting() {
  GoogleFonts.config.allowRuntimeFetching = false;

  // Inject an asset manifest that declares the Inter assets. Because this is
  // set directly, AssetManifest.loadFromAssetBundle is never invoked.
  gf_base.assetManifest = _FakeInterAssetManifest();

  final ByteData fontBytes = ByteData.sublistView(
    File('test/fixtures/test_font.ttf').readAsBytesSync(),
  );

  // Serve the font bytes for any rootBundle.load() of an Inter asset path.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (ByteData? message) {
        final String key = utf8.decode(message!.buffer.asUint8List());
        if (_interAssetPaths.contains(key)) {
          return Future<ByteData?>.value(fontBytes);
        }
        return Future<ByteData?>.value();
      });
}

class _FakeInterAssetManifest implements AssetManifest {
  @override
  List<String> listAssets() => _interAssetPaths;

  @override
  List<AssetMetadata>? getAssetVariants(String key) => null;
}
