import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('expired access token is refreshed before an authenticated request',
      () async {
    final expiredToken = _jwt(
      subject: '11111111-1111-1111-1111-111111111111',
      expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
    );
    final nextToken = _jwt(
      subject: '11111111-1111-1111-1111-111111111111',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
    SharedPreferences.setMockInitialValues({
      'access_token': expiredToken,
      'refresh_token': 'old-refresh-token',
    });

    final client = MockClient((request) async {
      if (request.url.path == '/auth/refresh') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['userId'], '11111111-1111-1111-1111-111111111111');
        expect(body['refreshToken'], 'old-refresh-token');
        return http.Response(
          jsonEncode({
            'accessToken': nextToken,
            'refreshToken': 'rotated-refresh-token',
            'user': <String, dynamic>{},
          }),
          200,
        );
      }

      expect(request.headers['Authorization'], 'Bearer $nextToken');
      return http.Response('{}', 200);
    });

    await ApiClient(client: client).get('/protected');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('access_token'), nextToken);
    expect(prefs.getString('refresh_token'), 'rotated-refresh-token');
  });

  test('rejected refresh clears both locally stored tokens', () async {
    SharedPreferences.setMockInitialValues({
      'access_token': _jwt(
        subject: '22222222-2222-2222-2222-222222222222',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
      'refresh_token': 'rejected-refresh-token',
    });
    final client = MockClient((request) async {
      if (request.url.path == '/auth/refresh') {
        return http.Response('{"message":"expired"}', 401);
      }
      return http.Response('{"message":"unauthorized"}', 401);
    });

    await expectLater(
      ApiClient(client: client).get('/protected'),
      throwsA(isA<ApiException>()),
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('access_token'), isNull);
    expect(prefs.getString('refresh_token'), isNull);
  });
}

String _jwt({required String subject, required DateTime expiresAt}) {
  String encode(Map<String, dynamic> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');

  return '${encode({'alg': 'none', 'typ': 'JWT'})}.'
      '${encode({
        'sub': subject,
        'exp': expiresAt.millisecondsSinceEpoch ~/ 1000
      })}.';
}
