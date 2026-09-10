import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../theme/twist_colors.dart';

/// Two dominant artwork colours and the darkened gradient derived from them.
class ArtworkPalette {
  const ArtworkPalette({required this.primary, required this.secondary});

  static const ArtworkPalette fallback = ArtworkPalette(
    primary: TwistColors.darkNavy,
    secondary: TwistColors.fallbackSecondary,
  );

  final Color primary;
  final Color secondary;

  Color get backgroundTop => _darken(primary, 0.55);
  Color get backgroundBottom => _darken(secondary, 0.65);

  static Color _darken(Color color, double amount) {
    final hsv = HSVColor.fromColor(color);
    return hsv
        .withValue((hsv.value * (1 - amount)).clamp(0.0, 1.0))
        .withSaturation((hsv.saturation * 1.2).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  bool operator ==(Object other) =>
      other is ArtworkPalette &&
      other.primary == primary &&
      other.secondary == secondary;

  @override
  int get hashCode => Object.hash(primary, secondary);
}

/// Port of the native `ImageColorExtractor`: sample a 40x40 grid, drop near
/// black, near white and washed-out pixels, bucket by colour distance and keep
/// the two largest distinct buckets.
ArtworkPalette paletteFromRgba(Uint8List rgba, int width, int height) {
  const grid = 40;
  if (width <= 0 || height <= 0 || rgba.length < width * height * 4) {
    return ArtworkPalette.fallback;
  }
  final buckets = <_Bucket>[];
  for (var gy = 0; gy < grid; gy++) {
    final y = (gy * height) ~/ grid;
    for (var gx = 0; gx < grid; gx++) {
      final x = (gx * width) ~/ grid;
      final offset = (y * width + x) * 4;
      final r = rgba[offset] / 255;
      final g = rgba[offset + 1] / 255;
      final b = rgba[offset + 2] / 255;
      final brightness = _max3(r, g, b);
      if (brightness < 0.05 || brightness > 0.95) continue;
      final saturation =
          brightness == 0 ? 0.0 : (brightness - _min3(r, g, b)) / brightness;
      if (saturation < 0.1 && brightness > 0.3) continue;
      _Bucket? match;
      for (final bucket in buckets) {
        if (bucket.distanceTo(r, g, b) < 0.2) {
          match = bucket;
          break;
        }
      }
      if (match == null) {
        buckets.add(_Bucket(r, g, b));
      } else {
        match.add(r, g, b);
      }
    }
  }
  if (buckets.isEmpty) return ArtworkPalette.fallback;
  buckets.sort((a, b) => b.count.compareTo(a.count));
  final primary = buckets.first.color;
  if (buckets.length == 1) {
    final hsv = HSVColor.fromColor(primary);
    return ArtworkPalette(
      primary: primary,
      secondary: hsv.withHue((hsv.hue + 0.08 * 360) % 360).toColor(),
    );
  }
  _Bucket secondary = buckets[1];
  final limit = buckets.length < 8 ? buckets.length : 8;
  for (var i = 1; i < limit; i++) {
    if (buckets[i].distanceToBucket(buckets.first) > 0.15) {
      secondary = buckets[i];
      break;
    }
  }
  return ArtworkPalette(primary: primary, secondary: secondary.color);
}

class _Bucket {
  _Bucket(double r, double g, double b)
      : _r = r,
        _g = g,
        _b = b,
        count = 1;

  double _r;
  double _g;
  double _b;
  int count;

  void add(double r, double g, double b) {
    _r = (_r * count + r) / (count + 1);
    _g = (_g * count + g) / (count + 1);
    _b = (_b * count + b) / (count + 1);
    count++;
  }

  double distanceTo(double r, double g, double b) =>
      (_r - r).abs() + (_g - g).abs() + (_b - b).abs();

  double distanceToBucket(_Bucket other) => distanceTo(other._r, other._g, other._b);

  Color get color => Color.fromARGB(
      255, (_r * 255).round(), (_g * 255).round(), (_b * 255).round());
}

double _max3(double a, double b, double c) => a > b ? (a > c ? a : c) : (b > c ? b : c);
double _min3(double a, double b, double c) => a < b ? (a < c ? a : c) : (b < c ? b : c);

/// Resolves an [ImageProvider], extracts its palette off the UI thread and
/// caches the result per provider.
class ArtworkPaletteResolver {
  ArtworkPaletteResolver({this.capacity = 10});

  final int capacity;
  final Map<Object, ArtworkPalette> _cache = <Object, ArtworkPalette>{};

  Future<ArtworkPalette> resolve(ImageProvider provider) async {
    final cached = _cache[provider];
    if (cached != null) return cached;
    final image = await _loadImage(provider);
    if (image == null) return ArtworkPalette.fallback;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final width = image.width;
    final height = image.height;
    image.dispose();
    if (data == null) return ArtworkPalette.fallback;
    final bytes = data.buffer.asUint8List();
    final palette = await compute(
      (_PaletteJob job) => paletteFromRgba(job.bytes, job.width, job.height),
      _PaletteJob(bytes, width, height),
    );
    if (_cache.length >= capacity) _cache.remove(_cache.keys.first);
    _cache[provider] = palette;
    return palette;
  }

  Future<ui.Image?> _loadImage(ImageProvider provider) {
    final completer = Completer<ui.Image?>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete(info.image);
      },
      onError: (_, __) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete(null);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }
}

class _PaletteJob {
  const _PaletteJob(this.bytes, this.width, this.height);
  final Uint8List bytes;
  final int width;
  final int height;
}
