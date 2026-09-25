// Splash sprite models and loaders.
part of 'splash_screen.dart';

class _LetterSpec {
  const _LetterSpec(this.asset, this.origin, this.landingX);
  final String asset;
  final Offset origin;
  final double landingX;
}

class _Sprite {
  _Sprite(this.image, this.origin);
  final ui.Image image;
  final Offset origin;

  Rect get rect =>
      origin & Size(image.width * _assetScale, image.height * _assetScale);
}

class _Sprites {
  _Sprites({
    required this.cap,
    required this.ring,
    required this.infinity,
    required this.letters,
  });

  final _Sprite cap;
  final _Sprite ring;
  final _Sprite infinity;
  final List<_Sprite> letters;

  static Future<_Sprites> load() async {
    final cap = _load('shape_cap');
    final ring = _load('shape_circle');
    final infinity = _load('shape_infinity');
    final letters = [for (final l in _letters) _load(l.asset)];

    return _Sprites(
      cap: _Sprite(await cap, _capOrigin),
      ring: _Sprite(await ring, _ringOrigin),
      infinity: _Sprite(await infinity, _infinityOrigin),
      letters: [
        for (var i = 0; i < _letters.length; i++)
          _Sprite(await letters[i], _letters[i].origin),
      ],
    );
  }

  static Future<ui.Image> _load(String name) async {
    // ✅ المسار الصحيح — الصور في assets/ مباشرة
    final path = 'assets/$name.png';

    try {
      final data = await rootBundle.load(path);

      // ✅ التصحيح الحاسم: استخدام offsetInBytes و lengthInBytes
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      debugPrint('❌ فشل تحميل $path: $e');
      rethrow;
    }
  }
}

// ═══════════════════════════════════════════════════════════
//  خلفية الأيقونات
// ═══════════════════════════════════════════════════════════
