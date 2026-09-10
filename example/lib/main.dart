import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:twist_music_player/twist_music_player.dart';

/// Pass the endpoint and store page at build time so nothing Twist-specific
/// lives in the source: `flutter run --dart-define=TWIST_TRACKS_URL=...`.
const String _tracksUrl = String.fromEnvironment(
  'TWIST_TRACKS_URL',
  defaultValue: 'https://api.twistmena.com/music/guest/tracks',
);
const String _storeUrl = String.fromEnvironment(
  'TWIST_STORE_URL',
  defaultValue: 'https://music.twistmena.com',
);

final ValueNotifier<Locale> _locale = ValueNotifier<Locale>(const Locale('en'));

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
      branding: const TwistBranding(
        headerLogo: AssetImage('assets/twist_wordmark_blue.png'),
        promoLogo: AssetImage('assets/twist_wordmark_white.png'),
      ),
      androidNotificationChannelId: 'com.example.twist.audio',
    ),
  );
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: _locale,
      builder: (context, locale, _) => MaterialApp(
        title: 'Twist demo host',
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          TwistMusicLocalizations.delegate,
        ],
        theme: ThemeData(colorSchemeSeed: const Color(0xFF2D5BFF), useMaterial3: true),
        builder: (context, child) => TwistPlayerHost(bottomInset: 0, child: child!),
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
            onPressed: () {
              _locale.value = _locale.value.languageCode == 'en'
                  ? const Locale('ar')
                  : const Locale('en');
              player.laneController.reload();
            },
            child: Text(_locale.value.languageCode == 'en' ? 'AR' : 'EN'),
          ),
        ],
      ),
      body: Builder(
        builder: (context) => ListView(
          padding: EdgeInsets.only(bottom: TwistPlayerHost.bottomPaddingOf(context) + 24),
          children: [
            const _FeedCard(title: 'Host content above the lane'),
            const TwistMusicSwimlane(),
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
