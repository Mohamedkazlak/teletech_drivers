import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/network/api_client.dart';
import 'package:teletech_drivers/core/network/api_exception.dart';

import 'fake_token_storage.dart';

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonBody(Object data, {int status = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  late FakeTokenStorage storage;
  late Dio dio;
  late ApiClient client;
  var sessionExpiredCount = 0;

  setUp(() {
    storage = FakeTokenStorage();
    dio = Dio(BaseOptions(baseUrl: 'http://example.test/api/'));
    sessionExpiredCount = 0;
    client = ApiClient(
      tokenStorage: storage,
      dio: dio,
      baseUrl: 'http://example.test/api',
      onSessionExpired: () => sessionExpiredCount++,
    );
  });

  test('attaches Authorization Bearer header when token present', () async {
    storage.token = 'secret-token';
    RequestOptions? seen;
    dio.httpClientAdapter = _ScriptedAdapter((options) async {
      seen = options;
      return _jsonBody({'ok': true});
    });

    await client.get('places');

    expect(seen?.headers['Authorization'], 'Bearer secret-token');
  });

  test('401 with bearer triggers session expiry once', () async {
    storage.token = 'stale';
    dio.httpClientAdapter = _ScriptedAdapter((options) async {
      return _jsonBody({'message': 'Unauthenticated.'}, status: 401);
    });

    await expectLater(
      () => client.get('places'),
      throwsA(isA<UnauthorizedApiException>()),
    );
    await expectLater(
      () => client.get('places'),
      throwsA(isA<UnauthorizedApiException>()),
    );

    expect(sessionExpiredCount, 1);
    expect(storage.token, isNull);
  });

  test('login 401 does not trigger session expiry', () async {
    dio.httpClientAdapter = _ScriptedAdapter((options) async {
      return _jsonBody({'message': 'Invalid'}, status: 401);
    });

    await expectLater(
      () => client.post('auth/login', data: {'email': 'a', 'password': 'b'}),
      throwsA(isA<UnauthorizedApiException>()),
    );
    expect(sessionExpiredCount, 0);
  });

  test('maps 403/404/409/422/timeout/5xx', () async {
    Future<void> expectStatus(int status, Type type) async {
      dio.httpClientAdapter = _ScriptedAdapter((options) async {
        return _jsonBody({
          'message': 'msg',
          if (status == 422) 'errors': {'email': ['taken']},
        }, status: status);
      });
      await expectLater(() => client.get('x'), throwsA(isA<Object>().having(
        (e) => e.runtimeType,
        'type',
        type,
      )));
    }

    await expectStatus(403, ForbiddenApiException);
    await expectStatus(404, NotFoundApiException);
    await expectStatus(409, ConflictApiException);
    await expectStatus(429, TooManyRequestsApiException);

    dio.httpClientAdapter = _ScriptedAdapter((options) async {
      return _jsonBody({
        'message': 'invalid',
        'errors': {
          'email': ['taken'],
        },
      }, status: 422);
    });
    try {
      await client.get('x');
      fail('expected ValidationApiException');
    } on ValidationApiException catch (error) {
      expect(error.fieldErrors['email'], ['taken']);
    }

    dio.httpClientAdapter = _ScriptedAdapter((options) async {
      return _jsonBody({'message': 'boom'}, status: 500);
    });
    await expectLater(
      () => client.get('x'),
      throwsA(isA<ServerApiException>()),
    );

    dio.httpClientAdapter = _ScriptedAdapter((options) async {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionTimeout,
      );
    });
    await expectLater(
      () => client.get('x'),
      throwsA(isA<NetworkApiException>()),
    );
  });
}
