import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:twist_music_player/twist_music_player.dart';

void main() {
  final endpoint = Uri.parse('https://api.example.com/music/guest/tracks');
  final fixtureBody = File('test/fixtures/tracks_en.json').readAsBytesSync();

  test('parses a 2xx JSON envelope and sends the dynamic headers', () async {
    http.Request? seen;
    var language = 'en';
    final source = HttpTwistLaneSource(
      endpoint,
      headers: () => {'Accept-Language': language},
      client: MockClient((request) async {
        seen = request;
        return http.Response.bytes(fixtureBody, 200,
            headers: {'content-type': 'application/json; charset=utf-8'});
      }),
    );

    final lane = await source.load();
    expect(lane.tracks, hasLength(20));
    expect(seen!.url, endpoint);
    expect(seen!.headers['Accept'], 'application/json');
    expect(seen!.headers['Accept-Language'], 'en');

    language = 'ar';
    await source.load();
    expect(seen!.headers['Accept-Language'], 'ar');
  });

  test('non-2xx statuses raise TwistLaneException with the code', () async {
    final source = HttpTwistLaneSource(
      endpoint,
      client: MockClient((_) async => http.Response('nope', 503)),
    );
    await expectLater(
      source.load(),
      throwsA(isA<TwistLaneException>().having((e) => e.statusCode, 'status', 503)),
    );
  });

  test('invalid JSON and non-object payloads raise TwistLaneException', () async {
    final broken = HttpTwistLaneSource(
      endpoint,
      client: MockClient((_) async => http.Response('{not json', 200)),
    );
    await expectLater(broken.load(), throwsA(isA<TwistLaneException>()));

    final array = HttpTwistLaneSource(
      endpoint,
      client: MockClient((_) async => http.Response(jsonEncode([1, 2]), 200)),
    );
    await expectLater(array.load(), throwsA(isA<TwistLaneException>()));
  });

  test('transport failures raise TwistLaneException with the cause', () async {
    final source = HttpTwistLaneSource(
      endpoint,
      client: MockClient((_) async => throw const SocketException('offline')),
    );
    await expectLater(
      source.load(),
      throwsA(isA<TwistLaneException>().having((e) => e.cause, 'cause', isA<SocketException>())),
    );
  });

  test('FixtureTwistLaneSource serves a parsed lane', () async {
    final source = FixtureTwistLaneSource.fromString(utf8.decode(fixtureBody));
    expect((await source.load()).tracks, hasLength(20));
  });
}
