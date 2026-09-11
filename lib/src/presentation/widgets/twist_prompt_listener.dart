import 'package:flutter/widgets.dart';

import '../../analytics/twist_analytics.dart';
import '../../twist_music_player_impl.dart';

/// Presents a due download prompt from whichever package widget is mounted.
/// The facade's claim guarantees a single presentation per request; the full
/// player handles its own prompts while open.
class TwistPromptListener extends StatefulWidget {
  const TwistPromptListener({super.key, required this.child});

  final Widget child;

  @override
  State<TwistPromptListener> createState() => _TwistPromptListenerState();
}

class _TwistPromptListenerState extends State<TwistPromptListener> {
  late final TwistMusicPlayer _player;

  @override
  void initState() {
    super.initState();
    _player = TwistMusicPlayer.instance;
    _player.controller.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _player.controller.removeListener(_check);
    super.dispose();
  }

  void _check() {
    final request = _player.controller.value.pendingDownloadPrompt;
    if (request == null) return;
    // A route-based full player pops itself with the request; an in-host
    // expansion is collapsed by the facade before the sheet shows.
    if (_player.isFullPlayerOpen && !_player.hasSurface) return;
    if (!_player.claimDownloadPrompt(request)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _player.presentDownloadPrompt(context, request,
          source: TwistAnalyticsSources.promptMini);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
