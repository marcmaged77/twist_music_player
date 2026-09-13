import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:twist_music_player/twist_music_player.dart';

/// Pass the lane endpoint and the store page at build time:
/// `flutter run --dart-define=TWIST_TRACKS_URL=... --dart-define=TWIST_STORE_URL=...`.
const String _tracksUrl = String.fromEnvironment(
  'TWIST_TRACKS_URL',
  defaultValue: 'https://example.com/music/tracks',
);
const String _storeUrl = String.fromEnvironment(
  'TWIST_STORE_URL',
  defaultValue: 'https://example.com/get-the-app',
);

final ValueNotifier<Locale> _locale = ValueNotifier<Locale>(const Locale('en'));

/// True docks the bar through [TwistPlayerHost]; false places [TwistMiniPlayer] by hand.
final ValueNotifier<bool> _useHost = ValueNotifier<bool>(true);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TwistMusicPlayer.init(
    TwistMusicConfig(
      laneSource: HttpTwistLaneSource(
        Uri.parse(_tracksUrl),
        headers: () => {'Accept-Language': _locale.value.languageCode},
      ),
      downloadFallbackUrl: Uri.parse(_storeUrl),
      onAnalyticsEvent: (name, parameters) => debugPrint('[analytics] $name $parameters'),
      onError: (error, stack) => debugPrint('[twist] $error'),
      androidNotificationChannelId: 'com.example.twist.audio',
    ),
  );
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_locale, _useHost]),
      builder: (context, _) => MaterialApp(
        title: 'Twist demo host',
        debugShowCheckedModeBanner: false,
        locale: _locale.value,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          TwistMusicLocalizations.delegate,
        ],
        theme: ThemeData(colorSchemeSeed: const Color(0xFF2D5BFF), useMaterial3: true),
        // Pattern 1: the host docks the bar and expands the player in place.
        builder: (context, child) =>
            _useHost.value ? TwistPlayerHost(bottomInset: 0, child: child!) : child!,
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final player = TwistMusicPlayer.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Twist demo host'),
        actions: [
          TextButton(
            onPressed: () => _useHost.value = !_useHost.value,
            child: Text(_useHost.value ? 'Manual bar' : 'Docked bar'),
          ),
          TextButton(
            onPressed: () {
              _locale.value =
                  _locale.value.languageCode == 'en' ? const Locale('ar') : const Locale('en');
              player.laneController.reload();
            },
            child: Text(_locale.value.languageCode == 'en' ? 'AR' : 'EN'),
          ),
        ],
      ),
      // Pattern 2: place the bar yourself. It renders nothing while idle, so
      // the bottom slot collapses until a track plays; a tap pushes the full
      // player route because no host is mounted.
      bottomNavigationBar: _useHost.value
          ? null
          : const SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TwistMiniPlayer(),
              ),
            ),
      body: Builder(
        builder: (context) => ListView(
          padding: EdgeInsets.only(bottom: TwistPlayerHost.bottomPaddingOf(context) + 24),
          children: [
            const _FeedCard(title: 'Host content above the lane'),
            const TwistMusicSwimlane(style: TwistSwimlaneStyle.banner),
            const _FeedCard(title: 'Host content below the lane'),
            ValueListenableBuilder<bool>(
              valueListenable: player.isActive,
              builder: (context, active, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    FilledButton(
                      onPressed: active ? () => player.openFullPlayer(context) : null,
                      child: const Text('Open full player'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: active ? () => player.stop(resetSession: true) : null,
                      child: const Text('Stop and reset session'),
                    ),
                  ],
                ),
              ),
            ),
            const _FeedCard(title: 'More host content'),
            const _FeedCard(title: 'Even more host content'),
          ],
        ),
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Card(
        child: SizedBox(
          height: 120,
          child: Center(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        ),
      ),
    );
  }
}
