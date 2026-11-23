import 'dart:async';

import 'package:dio/dio.dart';
import 'package:teletech_drivers/core/config/app_config.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/constants/api_paths.dart';
import 'package:teletech_drivers/core/constants/pagination_constants.dart';
import 'package:teletech_drivers/core/network/api_exception.dart';
import 'package:teletech_drivers/core/network/paginated_response.dart';
import 'package:teletech_drivers/core/network/token_storage.dart';

typedef SessionExpiredCallback = void Function();
typedef PasswordChangeRequiredCallback = void Function();

/// Dio wrapper: JSON headers, bearer auth, and single-shot 401 handling.
class ApiClient {
  ApiClient({
    required this._tokenStorage,
    Dio? dio,
    this.onSessionExpired,
    String? baseUrl,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: _normalizeBaseUrl(baseUrl ?? AppConfig.apiBaseUrl),
               connectTimeout: const Duration(seconds: 20),
               receiveTimeout: const Duration(seconds: 20),
               sendTimeout: const Duration(seconds: 20),
               headers: const {
                 Headers.acceptHeader: Headers.jsonContentType,
                 Headers.contentTypeHeader: Headers.jsonContentType,
               },
               responseType: ResponseType.json,
             ),
           ) {
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _attachBearer, onError: _mapError),
    );
  }

  final TokenStorage _tokenStorage;
  final Dio _dio;

  /// Wired by the auth session after construction (avoids DI cycles).
  SessionExpiredCallback? onSessionExpired;

  /// Wired by the auth session. Fired on 403 `password_change_required`.
  PasswordChangeRequiredCallback? onPasswordChangeRequired;

  bool _sessionExpirySignaled = false;

  Dio get dio => _dio;

  /// Resets the one-shot 401 latch after a successful interactive login.
  void resetSessionExpiryLatch() {
    _sessionExpirySignaled = false;
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return _request(
      () => _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _request(
      () => _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: headers == null ? null : Options(headers: headers),
      ),
    );
  }

  Future<Response<dynamic>> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(
      () => _dio.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      ),
    );
  }

  Future<Response<dynamic>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(
      () =>
          _dio.put<dynamic>(path, data: data, queryParameters: queryParameters),
    );
  }

  Future<Response<dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _request(
      () => _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: headers == null ? null : Options(headers: headers),
      ),
    );
  }

  /// Loads every page of a paginated list, capped by [PaginationConstants.maxPages].
  Future<List<T>> fetchAllPages<T>({
    required String path,
    Map<String, dynamic>? query,
    required T Function(Map<String, dynamic> json) mapItem,
    int perPage = PaginationConstants.defaultPerPage,
  }) async {
    final all = <T>[];
    var page = 1;
    while (page <= PaginationConstants.maxPages) {
      final response = await get(
        path,
        queryParameters: {
          ...?query,
          ApiJsonKeys.page: page,
          ApiJsonKeys.perPage: perPage,
        },
      );
      final body = _requireJsonMap(response.data);
      final pageData = PaginatedResponse.fromJson(body, mapItem);
      all.addAll(pageData.data);
      if (!pageData.hasMore) break;
      page += 1;
    }
    return all;
  }

  Future<Response<dynamic>> _request(
    Future<Response<dynamic>> Function() send,
  ) async {
    try {
      return await send();
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<void> _attachBearer(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _mapError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final status = error.response?.statusCode;
    if (status == 401 && _shouldTreatAsSessionExpiry(error.requestOptions)) {
      await _handleUnauthorizedOnce();
    } else if (status == 403 &&
        _readCode(error.response?.data) ==
            ForbiddenApiException.passwordChangeRequiredCode) {
      onPasswordChangeRequired?.call();
    }
    handler.next(error);
  }

  bool _shouldTreatAsSessionExpiry(RequestOptions options) {
    final path = options.path;
    if (path.contains(ApiPaths.authLogin) ||
        path.contains(ApiPaths.authRegister)) {
      return false;
    }
    final authHeader = options.headers['Authorization'];
    return authHeader is String && authHeader.startsWith('Bearer ');
  }

  Future<void> _handleUnauthorizedOnce() async {
    if (_sessionExpirySignaled) return;
    _sessionExpirySignaled = true;
    await _tokenStorage.clearToken();
    onSessionExpired?.call();
  }

  ApiException _toApiException(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const NetworkApiException();
    }

    final status = error.response?.statusCode;
    final payload = error.response?.data;
    final message = _readMessage(payload);
    final fieldErrors = _readFieldErrors(payload);

    return switch (status) {
      401 => UnauthorizedApiException(message: message),
      403 => ForbiddenApiException(message: message, code: _readCode(payload)),
      404 => NotFoundApiException(message: message),
      409 => ConflictApiException(
        message: message,
        code: _readCode(payload),
        distanceM: _readInt(payload, 'distance_m'),
        radiusM: _readInt(payload, 'radius_m'),
      ),
      422 => ValidationApiException(
        message: message,
        fieldErrors: fieldErrors,
        code: _readCode(payload),
        distanceM: _readInt(payload, 'distance_m'),
        radiusM: _readInt(payload, 'radius_m'),
      ),
      429 => TooManyRequestsApiException(message: message),
      final code when code != null && code >= 500 => ServerApiException(
        message: message,
        statusCode: code,
      ),
      _ => UnexpectedApiException(message: message, statusCode: status),
    };
  }

  static Map<String, dynamic> _requireJsonMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('Expected JSON object response');
  }

  static int? _readInt(Object? payload, String key) {
    if (payload is! Map) return null;
    final value = payload[key];
    if (value is int) return value;
    if (value is num) return value.round();
    return null;
  }

  static String? _readCode(Object? payload) {
    if (payload is! Map) return null;
    final code = payload[ApiJsonKeys.code];
    if (code is! String) return null;
    final trimmed = code.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _readMessage(Object? payload) {
    if (payload is! Map) return null;
    final message = payload[ApiJsonKeys.message];
    if (message is! String) return null;
    final trimmed = message.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static Map<String, List<String>> _readFieldErrors(Object? payload) {
    if (payload is! Map) return const {};
    final errors = payload[ApiJsonKeys.errors];
    if (errors is! Map) return const {};
    final result = <String, List<String>>{};
    errors.forEach((key, value) {
      if (key is! String) return;
      if (value is List) {
        result[key] = [
          for (final item in value)
            if (item is String && item.trim().isNotEmpty) item.trim(),
        ];
      } else if (value is String && value.trim().isNotEmpty) {
        result[key] = [value.trim()];
      }
    });
    return result;
  }

  static String _normalizeBaseUrl(String value) {
    if (value.endsWith('/')) return value;
    return '$value/';
  }
}
