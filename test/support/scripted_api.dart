import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:teletech_drivers/core/network/api_client.dart';

import '../core/network/fake_token_storage.dart';

/// Request seen by [ScriptedApi] with its decoded JSON body.
class RecordedRequest {
  const RecordedRequest({
    required this.method,
    required this.path,
    required this.query,
    required this.body,
  });

  final String method;
  final String path;
  final Map<String, dynamic> query;

  /// Decoded JSON body, or null when no body was sent.
  final Object? body;
}

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._handler);

  final Future<ResponseBody> Function(
    RequestOptions options,
    Object? body,
  )
  _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object? body;
    if (requestStream != null) {
      final bytes = <int>[];
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
      if (bytes.isNotEmpty) {
        body = jsonDecode(utf8.decode(bytes));
      }
    }
    return _handler(options, body);
  }

  @override
  void close({bool force = false}) {}
}

/// JSON [ResponseBody] helper shared by data-source tests.
ResponseBody jsonResponse(Object data, {int status = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

/// Laravel-style `{ data, meta }` page.
Map<String, dynamic> paginatedPage(
  List<Map<String, dynamic>> items, {
  int page = 1,
  int lastPage = 1,
}) {
  return {
    'data': items,
    'meta': {
      'current_page': page,
      'last_page': lastPage,
      'per_page': 50,
      'total': items.length,
    },
  };
}

/// Real [ApiClient] backed by a scripted Dio adapter that records requests.
class ScriptedApi {
  ScriptedApi() {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test/api/'));
    dio.httpClientAdapter = _ScriptedAdapter((options, body) async {
      requests.add(
        RecordedRequest(
          method: options.method,
          path: options.path,
          query: Map<String, dynamic>.from(options.queryParameters),
          body: body,
        ),
      );
      return _respond(options, body);
    });
    client = ApiClient(
      tokenStorage: FakeTokenStorage(),
      dio: dio,
      baseUrl: 'http://example.test/api',
    );
  }

  late final ApiClient client;
  final requests = <RecordedRequest>[];

  Future<ResponseBody> Function(RequestOptions options, Object? body) _respond =
      (options, body) async => jsonResponse(const <String, dynamic>{});

  RecordedRequest get last => requests.last;

  /// Replies to every request with [data] (status [status]).
  void respondWith(Object data, {int status = 200}) {
    _respond = (options, body) async => jsonResponse(data, status: status);
  }

  /// Replies per request, e.g. for pagination.
  void respondWithHandler(
    Future<ResponseBody> Function(RequestOptions options, Object? body) handler,
  ) {
    _respond = handler;
  }
}
