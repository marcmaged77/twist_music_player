import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme/twist_colors.dart';

/// Cached, rounded artwork with a neutral placeholder.
class TwistArtwork extends StatelessWidget {
  const TwistArtwork({
    super.key,
    required this.url,
    required this.size,
    this.radius = 10,
    this.placeholderColor,
  });

  final Uri? url;
  final double size;
  final double radius;
  final Color? placeholderColor;

  @override
  Widget build(BuildContext context) {
    final placeholder = placeholderColor ?? TwistColors.artworkPlaceholder;
    final fallback = ColoredBox(
      color: placeholder,
      child: Icon(Icons.music_note_rounded,
          size: size * 0.4, color: Colors.black.withValues(alpha: 0.25)),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: url == null
            ? fallback
            : CachedNetworkImage(
                imageUrl: url.toString(),
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 200),
                placeholder: (_, __) => ColoredBox(color: placeholder),
                errorWidget: (_, __, ___) => fallback,
              ),
      ),
    );
  }
}
