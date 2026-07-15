import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_endpoints.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException: [$statusCode] $message';
}

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _getHeaders({bool authenticated = true}) async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authenticated) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(String endpoint, {bool authenticated = true}) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    final headers = await _getHeaders(authenticated: authenticated);

    final response = await _client.get(uri, headers: headers);
    return _processResponse(response);
  }

  Future<Uint8List> getBytes(String endpoint,
      {bool authenticated = true}) async {
    final uri = endpoint.startsWith('http')
        ? Uri.parse(endpoint)
        : Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    final headers = await _getHeaders(authenticated: authenticated)
      ..remove('Accept')
      ..remove('Content-Type');

    final response = await _client.get(uri, headers: headers);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }

    _processResponse(response);
    throw ApiException(response.statusCode, 'Unable to download file.');
  }

  Future<dynamic> post(String endpoint,
      {dynamic body, bool authenticated = true}) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    final headers = await _getHeaders(authenticated: authenticated);
    final encodedBody = body != null ? jsonEncode(body) : null;

    final response =
        await _client.post(uri, headers: headers, body: encodedBody);
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
    final headers = await _getHeaders(authenticated: authenticated)
      ..remove('Content-Type');

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(headers)
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
    final response = await http.Response.fromStream(streamedResponse);
    return _processResponse(response);
  }

  Future<dynamic> put(String endpoint,
      {dynamic body, bool authenticated = true}) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    final headers = await _getHeaders(authenticated: authenticated);
    final encodedBody = body != null ? jsonEncode(body) : null;

    final response =
        await _client.put(uri, headers: headers, body: encodedBody);
    return _processResponse(response);
  }

  Future<dynamic> delete(String endpoint, {bool authenticated = true}) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    final headers = await _getHeaders(authenticated: authenticated);

    final response = await _client.delete(uri, headers: headers);
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
      // Body is not JSON
      responseBody = response.body;
    }

    if (statusCode >= 200 && statusCode < 300) {
      return responseBody;
    }

    String errorMessage = 'Something went wrong';
    if (responseBody is Map) {
      // FluentValidation errors arrive as {message: "One or more validation
      // errors occurred.", errors: [{field, error}, ...]} — the generic
      // top-level `message` is useless; the field-level `error` (e.g. the
      // Basic-tier trip/member limit copy) is what's actually worth showing.
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
