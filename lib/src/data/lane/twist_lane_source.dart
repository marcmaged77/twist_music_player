import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/twist_download_prompt_policy.dart';
import '../models/twist_lane.dart';
import 'twist_lane_parser.dart';

/// Where the lane comes from. Hosts may implement this over their own HTTP
/// stack, a gateway, a cache or a fixture; [HttpTwistLaneSource] is the default.
abstract class TwistLaneSource {
  Future<TwistLane> load();
}

/// Raised by lane sources for transport, status and decoding failures.
class TwistLaneException implements Exception {
  const TwistLaneException(this.message, {this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() => 'TwistLaneException($message'
      '${statusCode != null ? ', status $statusCode' : ''}'
      '${cause != null ? ', cause: $cause' : ''})';
}

/// Plain `GET` of the tracks endpoint over `package:http`.
///
/// [headers] is evaluated on every request so values such as
/// `Accept-Language` can follow the app's current locale.
class HttpTwistLaneSource implements TwistLaneSource {
  HttpTwistLaneSource(
    this.endpoint, {
    this.headers,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
    this.fallbackPolicy = TwistDownloadPromptPolicy.fallback,
  }) : _client = client;

  final Uri endpoint;
  final Map<String, String> Function()? headers;
  final Duration timeout;
  final TwistDownloadPromptPolicy fallbackPolicy;
  final http.Client? _client;

  @override
  Future<TwistLane> load() async {
    final client = _client ?? http.Client();
    try {
      final response = await client
          .get(endpoint, headers: {
            'Accept': 'application/json',
            ...?headers?.call(),
          })
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw TwistLaneException('Unexpected status',
            statusCode: response.statusCode);
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const TwistLaneException('Payload is not a JSON object');
      }
      return TwistLaneParser.parse(decoded, fallbackPolicy: fallbackPolicy);
    } on TwistLaneException {
      rethrow;
    } on FormatException catch (error) {
      throw TwistLaneException('Invalid JSON', cause: error);
    } on TimeoutException catch (error) {
      throw TwistLaneException('Timed out', cause: error);
    } catch (error) {
      throw TwistLaneException('Transport failure', cause: error);
    } finally {
      if (_client == null) client.close();
    }
  }
}

/// In-memory lane for tests, demos and previews.
class FixtureTwistLaneSource implements TwistLaneSource {
  FixtureTwistLaneSource(Map<String, dynamic> json) : _lane = TwistLaneParser.parse(json);

  FixtureTwistLaneSource.fromString(String json)
      : _lane = TwistLaneParser.parse(jsonDecode(json) as Map<String, dynamic>);

  FixtureTwistLaneSource.lane(TwistLane lane) : _lane = lane;

  final TwistLane _lane;

  @override
  Future<TwistLane> load() async => _lane;
}
