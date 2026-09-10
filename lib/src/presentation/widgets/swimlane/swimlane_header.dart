import 'package:flutter/material.dart';

import '../../../theme/twist_music_theme.dart';

/// Optional logo beside the lane title and subtitle.
class SwimlaneHeader extends StatelessWidget {
  const SwimlaneHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.logo,
  });

  final String title;
  final String subtitle;
  final ImageProvider? logo;

  @override
  Widget build(BuildContext context) {
    final theme = TwistMusicTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (logo != null) ...[
            ExcludeSemantics(
              child: Image(image: logo!, height: 30, fit: BoxFit.contain),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.headerTitleStyle),
                const SizedBox(height: 3),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.headerSubtitleStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
