import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

import 'api_endpoints.dart';
import 'token_store.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException: [$statusCode] $message';
}

class ApiClient {
  final http.Client _client;
  Future<bool>? _refreshInFlight;

  /// Invoked after stored tokens are cleared because refresh/session failed.
  void Function()? onSessionInvalidated;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _getHeaders({bool authenticated = true}) async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authenticated) {
      var token = await TokenStore.getAccessToken();
      if (token != null && token.isNotEmpty) {
        try {
          if (JwtDecoder.isExpired(token)) {
            final refreshed = await refreshSession();
            token = refreshed ? await TokenStore.getAccessToken() : null;
          }
        } catch (_) {
          await _clearStoredTokens();
          token = null;
        }
      }
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<bool> refreshSession() {
    return _refreshInFlight ??= _refreshSessionOnce().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _refreshSessionOnce() async {
    final accessToken = await TokenStore.getAccessToken();
    final refreshToken = await TokenStore.getRefreshToken();
    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      return false;
    }

    try {
      final decoded = JwtDecoder.decode(accessToken);
      final userId = decoded['sub']?.toString() ??
          decoded['nameid']?.toString() ??
          decoded['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier']
              ?.toString();
      if (userId == null || userId.isEmpty) {
        await _clearStoredTokens();
        return false;
      }

      final response = await _client.post(
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.refreshToken}'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'refreshToken': refreshToken,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        await _clearStoredTokens();
        return false;
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        await _clearStoredTokens();
        return false;
      }
      final nextAccessToken = body['accessToken'] as String? ?? '';
      final nextRefreshToken = body['refreshToken'] as String? ?? '';
      if (nextAccessToken.isEmpty || nextRefreshToken.isEmpty) {
        await _clearStoredTokens();
        return false;
      }

      await TokenStore.save(nextAccessToken, nextRefreshToken);
      return true;
    } catch (_) {
      await _clearStoredTokens();
      return false;
    }
  }

  Future<void> _clearStoredTokens() async {
    final hadSession =
        ((await TokenStore.getAccessToken())?.isNotEmpty ?? false) ||
            ((await TokenStore.getRefreshToken())?.isNotEmpty ?? false);
    await TokenStore.clear();
    if (hadSession) {
      onSessionInvalidated?.call();
    }
  }

  Future<http.Response> _sendWithAuthRetry(
    Future<http.Response> Function(Map<String, String> headers) send, {
    required bool authenticated,
  }) async {
    var headers = await _getHeaders(authenticated: authenticated);
    var response = await send(headers);

    if (authenticated && response.statusCode == 401) {
      final refreshed = await refreshSession();
      if (refreshed) {
        headers = await _getHeaders(authenticated: true);
        response = await send(headers);
      }
    }

    return response;
  }

  Future<dynamic> get(String endpoint, {bool authenticated = true}) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    final response = await _sendWithAuthRetry(
      (headers) => _client.get(uri, headers: headers),
      authenticated: authenticated,
    );
    return _processResponse(response);
  }

  Future<Uint8List> getBytes(String endpoint,
      {bool authenticated = true}) async {
    final uri = endpoint.startsWith('http')
        ? Uri.parse(endpoint)
        : Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    final response = await _sendWithAuthRetry(
      (headers) {
        final h = Map<String, String>.from(headers)
          ..remove('Accept')
          ..remove('Content-Type');
        return _client.get(uri, headers: h);
      },
      authenticated: authenticated,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }

    _processResponse(response);
    throw ApiException(response.statusCode, 'Không thể tải tệp.');
  }

  Future<dynamic> post(String endpoint,
      {dynamic body, bool authenticated = true}) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    final encodedBody = body != null ? jsonEncode(body) : null;
    final response = await _sendWithAuthRetry(
      (headers) => _client.post(uri, headers: headers, body: encodedBody),
      authenticated: authenticated,
    );
    return _processResponse(response);
  }

  Future<dynamic> postMultipart(
    String endpoint, {
    String? filePath,
    List<int>? fileBytes,
    String fileField = 'file',
    String? fileName,
    Map<String, String>? fields,
    bool authenticated = true,
  }) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');

    Future<http.Response> send(Map<String, String> headers) async {
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(Map<String, String>.from(headers)..remove('Content-Type'))
        ..fields.addAll(fields ?? const {});
      if (fileBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            fileField,
            fileBytes,
            filename: fileName,
          ),
        );
      } else if (filePath != null && filePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            fileField,
            filePath,
            filename: fileName,
          ),
        );
      } else {
        throw ArgumentError('Either fileBytes or filePath is required.');
      }

      final streamedResponse = await _client.send(request);
      return http.Response.fromStream(streamedResponse);
    }

    final response = await _sendWithAuthRetry(send, authenticated: authenticated);
    return _processResponse(response);
  }

  Future<dynamic> put(String endpoint,
      {dynamic body, bool authenticated = true}) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    final encodedBody = body != null ? jsonEncode(body) : null;
    final response = await _sendWithAuthRetry(
      (headers) => _client.put(uri, headers: headers, body: encodedBody),
      authenticated: authenticated,
    );
    return _processResponse(response);
  }

  Future<dynamic> delete(String endpoint, {bool authenticated = true}) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    final response = await _sendWithAuthRetry(
      (headers) => _client.delete(uri, headers: headers),
      authenticated: authenticated,
    );
    return _processResponse(response);
  }

  dynamic _processResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode == 204) {
      return null;
    }

    dynamic responseBody;
    try {
      if (response.body.isNotEmpty) {
        responseBody = jsonDecode(response.body);
      }
    } catch (_) {
      responseBody = response.body;
    }

    if (statusCode >= 200 && statusCode < 300) {
      return responseBody;
    }

    String errorMessage = 'Đã xảy ra lỗi.';
    if (responseBody is Map) {
      final errors = responseBody['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is Map && first['error'] is String) {
          errorMessage = first['error'] as String;
        }
      } else if (responseBody['message'] is String) {
        errorMessage = responseBody['message'] as String;
      } else if (responseBody['error'] is String) {
        errorMessage = responseBody['error'] as String;
      }
    } else if (response.body.isNotEmpty) {
      errorMessage = response.body;
    }

    throw ApiException(statusCode, errorMessage);
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
