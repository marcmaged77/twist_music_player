import 'package:flutter/material.dart';

import '../../data/playback/twist_playback_snapshot.dart';
import '../../twist_music_player_impl.dart';
import '../widgets/full_player/full_player_body.dart';
import '../widgets/full_player/full_player_queue_sheet.dart';

/// Slide-up route hosting [TwistFullPlayerScreen], used when no
/// [TwistPlayerHost] is mounted. Pops with a [TwistDownloadPromptRequest]
/// when a prompt becomes due while open.
class TwistFullPlayerRoute extends PageRouteBuilder<Object?> {
  TwistFullPlayerRoute()
      : super(
          opaque: false,
          fullscreenDialog: true,
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, __, ___) => const TwistFullPlayerScreen(),
          transitionsBuilder: (_, animation, __, child) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
}

/// Route-based full player with drag-to-dismiss. Hosts that mount
/// [TwistPlayerHost] get the in-place expansion instead.
class TwistFullPlayerScreen extends StatefulWidget {
  const TwistFullPlayerScreen({super.key});

  @override
  State<TwistFullPlayerScreen> createState() => _TwistFullPlayerScreenState();
}

class _TwistFullPlayerScreenState extends State<TwistFullPlayerScreen> {
  late final TwistMusicPlayer _player;

  double _dragOffset = 0;
  bool _dragging = false;
  bool _popped = false;

  @override
  void initState() {
    super.initState();
    _player = TwistMusicPlayer.instance;
    _player.controller.addListener(_onSnapshot);
  }

  @override
  void dispose() {
    _player.controller.removeListener(_onSnapshot);
    super.dispose();
  }

  void _onSnapshot() {
    final snapshot = _player.controller.value;
    if (!snapshot.isActive) {
      _pop(null);
      return;
    }
    final prompt = snapshot.pendingDownloadPrompt;
    if (prompt != null && _player.claimDownloadPrompt(prompt)) {
      _pop(prompt);
    }
  }

  /// Pops when hosted as a pushed route; a host that mounts the screen as a
  /// root (tab, home) simply keeps it.
  void _pop(Object? result) {
    if (_popped || !mounted) return;
    final navigator = Navigator.of(context);
    if (!navigator.canPop()) return;
    _popped = true;
    navigator.pop(result);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragging = true;
      _dragOffset = (_dragOffset + details.delta.dy).clamp(0.0, double.infinity);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final height = MediaQuery.sizeOf(context).height;
    final projected = _dragOffset + details.velocity.pixelsPerSecond.dy * 0.2;
    if (projected > height * 0.5) {
      _pop(null);
      return;
    }
    setState(() {
      _dragging = false;
      _dragOffset = 0;
    });
  }

  Future<void> _openQueue() async {
    final snapshot = _player.controller.value;
    final track = snapshot.currentTrack;
    if (track != null) {
      _player.analytics.queueOpened(track, queueCount: snapshot.queue.length);
    }
    await showTwistQueueSheet(context,
        background: _player.artworkPalette.value.backgroundTop);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _dragging ? Duration.zero : const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, _dragOffset, 0),
      child: GestureDetector(
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(_dragOffset > 0 ? 45 : 0)),
          child: TwistFullPlayerBody(
            onCollapse: () => _pop(null),
            onOpenQueue: _openQueue,
          ),
        ),
      ),
    );
  }
}
