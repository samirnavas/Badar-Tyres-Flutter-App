import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

/// Thrown when an API call fails (network error or non-2xx response).
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// A thin JSON HTTP wrapper around the mock API. Centralizes base-URL
/// resolution, headers, decoding, timeouts, and error handling so repositories
/// stay declarative.
class ApiClient {
  ApiClient({http.Client? client, this.timeout = const Duration(seconds: 10)})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = BadarApiConfig.baseUrl;
    final cleaned = path.startsWith('/') ? path : '/$path';
    final params = query
        ?.entries
        .where((e) => e.value != null && '${e.value}'.isNotEmpty)
        .map((e) => MapEntry(e.key, '${e.value}'));
    return Uri.parse('$base$cleaned').replace(
      queryParameters: params == null ? null : Map.fromEntries(params),
    );
  }

  Future<dynamic> getJson(String path, {Map<String, dynamic>? query}) async {
    return _send(() => _client.get(_uri(path, query), headers: _headers));
  }

  Future<dynamic> postJson(String path, Map<String, dynamic> body) async {
    return _send(
      () => _client.post(
        _uri(path),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );
  }

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    http.Response response;
    try {
      response = await request().timeout(timeout);
    } on TimeoutException {
      throw ApiException('Request timed out. Is the mock server running?');
    } catch (e) {
      throw ApiException(
        'Could not reach the server. Start it with `npm start` in the js/ '
        'folder. ($e)',
      );
    }

    final ok = response.statusCode >= 200 && response.statusCode < 300;
    if (!ok) {
      String message = 'Request failed (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['error'] != null) {
          message = decoded['error'].toString();
        }
      } catch (_) {}
      throw ApiException(message, statusCode: response.statusCode);
    }

    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  void dispose() => _client.close();
}
