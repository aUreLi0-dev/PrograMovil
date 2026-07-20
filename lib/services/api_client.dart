import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'storage_service.dart';

class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details,
  });

  final int statusCode;
  final String code;
  final String message;
  final Object? details;

  @override
  String toString() => 'ApiException($statusCode, $code, $message)';
}

class ApiClient {
  ApiClient({String? configuredBaseUrl})
    : _configuredBaseUrl = configuredBaseUrl ?? _defaultConfiguredBaseUrl;

  static const _defaultConfiguredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const _timeout = Duration(seconds: 20);

  final String _configuredBaseUrl;

  String get baseUrl {
    if (_configuredBaseUrl.trim().isNotEmpty) {
      return _sanitizeBaseUrl(_configuredBaseUrl);
    }
    if (kReleaseMode) {
      throw StateError(
        'API_BASE_URL debe definirse en release con --dart-define.',
      );
    }
    if (kIsWeb) return 'http://localhost:5000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://localhost:5000';
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
    bool authenticated = true,
  }) {
    return _send(
      'GET',
      path,
      token: token,
      query: query,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
    bool authenticated = true,
  }) {
    return _send(
      'POST',
      path,
      token: token,
      body: body,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
    bool authenticated = true,
  }) {
    return _send(
      'PUT',
      path,
      token: token,
      body: body,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    String? token,
    bool authenticated = true,
  }) {
    return _send('DELETE', path, token: token, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    String? token,
    Map<String, String?> query = const {},
    Map<String, dynamic>? body,
    required bool authenticated,
  }) async {
    try {
      final resolvedToken = authenticated ? token ?? _savedJwt() : null;
      final request = http.Request(method, _uri(path, query));
      request.headers.addAll(_headers(resolvedToken));
      if (body != null) request.body = jsonEncode(body);

      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 401 && !path.contains('/api/sign-in')) {
        await _clearJwt();
      }

      return _decode(response);
    } on TimeoutException {
      throw ApiException(
        statusCode: 408,
        code: 'TIMEOUT',
        message: 'La solicitud tardo demasiado en responder.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        code: 'NETWORK_ERROR',
        message: 'No se pudo conectar con el servidor.',
        details: e.toString(),
      );
    }
  }

  Uri _uri(String path, Map<String, String?> query) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final params = {
      for (final entry in query.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
    return Uri.parse('$baseUrl/')
        .resolve(cleanPath)
        .replace(queryParameters: params.isEmpty ? null : params);
  }

  Map<String, String> _headers(String? token) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  String? _savedJwt() {
    try {
      return StorageService.to.savedJwt;
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearJwt() async {
    try {
      await StorageService.to.clearJwt();
    } catch (_) {}
  }

  String _sanitizeBaseUrl(String rawBaseUrl) {
    return rawBaseUrl.trim().replaceFirst(RegExp(r'/$'), '');
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body = utf8.decode(response.bodyBytes).trim();
    dynamic decoded;
    if (body.isEmpty) {
      decoded = <String, dynamic>{};
    } else {
      try {
        decoded = jsonDecode(body);
      } catch (_) {
        decoded = <String, dynamic>{'raw': body};
      }
    }

    final json = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{'data': decoded};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }

    final error = json['error'];
    if (error is Map) {
      throw ApiException(
        statusCode: response.statusCode,
        code: error['code']?.toString() ?? 'HTTP_ERROR',
        message: error['message']?.toString() ?? 'Error del servidor',
        details: error['details'],
      );
    }

    throw ApiException(
      statusCode: response.statusCode,
      code: error?.toString() ?? 'HTTP_ERROR',
      message: json['message']?.toString() ?? 'Error del servidor',
      details: json,
    );
  }
}
