import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:twist_music_player/twist_music_player.dart';

Map<String, dynamic> fixture() => jsonDecode(
        File('test/fixtures/tracks_en.json').readAsStringSync())
    as Map<String, dynamic>;

void main() {
  group('TwistLaneParser with the live fixture', () {
    late TwistLane lane;

    setUpAll(() => lane = TwistLaneParser.parse(fixture()));

    test('keeps the envelope and every playable track in order', () {
      expect(lane.title, 'Music, Podcast & Radio');
      expect(lane.subTitle, 'Download & Get 1 Month Premium');
      expect(lane.downloadUrl, startsWith('https://twist-music.go.link/'));
      expect(lane.tracks, hasLength(20));
      expect(lane.tracks.first.id, 358233598);
      expect(lane.tracks.first.artistName, 'Kadim Al Sahir');
      expect(lane.tracks.first.fullDurationSeconds, 441);
    });

    test('maps the backend prompt cadence', () {
      expect(lane.downloadPrompt.isEnabled, isTrue);
      expect(lane.downloadPrompt.maxCount, 10);
      expect(lane.downloadPrompt.intervalSeconds, 15);
    });

    test('prefixes https on protocol-relative artwork', () {
      for (final t in lane.tracks) {
        expect(t.previewUrl.scheme, 'https');
        for (final art in [t.artworkSmallUrl, t.artworkMediumUrl, t.artworkLargeUrl]) {
          expect(art, isNotNull);
          expect(art!.scheme, 'https');
          expect(art.host, 'dxfve6m7pg0pq.cloudfront.net');
        }
      }
    });

    test('artwork preferences follow the native order', () {
      final t = lane.tracks.first;
      expect(t.preferredFullArtworkUrl, t.artworkLargeUrl);
      expect(t.preferredCompactArtworkUrl, t.artworkMediumUrl);
      expect(t.preferredLockScreenArtworkUrl, t.artworkSmallUrl);
    });
  });

  group('TwistLaneParser edge cases', () {
    Map<String, dynamic> envelope(List<Map<String, dynamic>> items,
            {Object? prompt, Object? downloadUrl = 'https://x.y/z'}) =>
        {
          'title': ' Hot ',
          'subTitle': '',
          'downloadUrl': downloadUrl,
          'tracks': {'items': items},
          if (prompt != null) 'downloadPrompt': prompt,
          'unknownField': 42,
        };

    Map<String, dynamic> item(int id, {String? sample, Object? cover, Object? release}) => {
          'id': id,
          'title': 'T$id',
          'duration': 100,
          'sample': sample ?? 'https://cdn/previews/$id.aac',
          'mainArtist': {'id': 1, 'name': 'A'},
          'release': release,
          'cover': cover,
          'extra': {'nested': true},
        };

    test('drops tracks without a playable sample and keeps order', () {
      final lane = TwistLaneParser.parse(envelope([
        item(1),
        item(2, sample: ''),
        item(3, sample: '   '),
        item(4, sample: 'not a url'),
        item(5, sample: 'https://cdn/with space.aac'),
        item(6),
      ]));
      expect(lane.tracks.map((t) => t.id), [1, 6]);
    });

    test('tolerates null release and cover', () {
      final lane = TwistLaneParser.parse(envelope([item(1)]));
      final t = lane.tracks.single;
      expect(t.albumTitle, isNull);
      expect(t.artworkSmallUrl, isNull);
      expect(t.preferredFullArtworkUrl, isNull);
    });

    test('trims the title, blanks become null', () {
      final lane = TwistLaneParser.parse(envelope([item(1)], downloadUrl: '   '));
      expect(lane.title, 'Hot');
      expect(lane.subTitle, isNull);
      expect(lane.downloadUrl, isNull);
    });

    test('falls back to the default prompt policy when absent or partial', () {
      expect(TwistLaneParser.parse(envelope([])).downloadPrompt,
          TwistDownloadPromptPolicy.fallback);
      final partial = TwistLaneParser.parse(
          envelope([], prompt: {'maxCount': -3, 'intervalSeconds': 0}));
      expect(partial.downloadPrompt.isEnabled, isTrue);
      expect(partial.downloadPrompt.maxCount, 0);
      expect(partial.downloadPrompt.isActive, isFalse);
      expect(partial.downloadPrompt.intervalSeconds, 30);
    });

    test('accepts numeric ids as strings and ignores malformed items', () {
      final lane = TwistLaneParser.parse(envelope([
        {...item(7), 'id': '7'},
        {'title': 'no id', 'sample': 'https://cdn/x.aac'},
        {'id': 8, 'sample': 'https://cdn/x.aac'},
      ]));
      expect(lane.tracks.map((t) => t.id), [7]);
    });

    test('an envelope without tracks is empty', () {
      expect(TwistLaneParser.parse({'title': 'x'}).isEmpty, isTrue);
      expect(TwistLaneParser.parse({'tracks': 'nope'}).isEmpty, isTrue);
    });
  });

  group('formatTrackTime', () {
    test('formats like the native player', () {
      expect(formatTrackTime(0), '0:00');
      expect(formatTrackTime(0.4), '0:00');
      expect(formatTrackTime(7), '0:07');
      expect(formatTrackTime(29), '0:29');
      expect(formatTrackTime(60), '1:00');
      expect(formatTrackTime(90), '1:30');
      expect(formatTrackTime(12.9), '0:12');
      expect(formatTrackTime(-3), '0:00');
      expect(formatTrackTime(double.nan), '0:00');
      expect(formatTrackTime(double.infinity), '0:00');
    });
  });
}
