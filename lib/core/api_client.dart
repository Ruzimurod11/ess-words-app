import 'package:dio/dio.dart';

import 'config.dart';
import 'session.dart';

/// Thrown by the API layer; carries the (already localized) backend error
/// message so the UI can surface it directly.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._() {
    _dio = Dio(BaseOptions(baseUrl: apiRoot));
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Accept-Language'] = Session.instance.language;
          final token = Session.instance.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (err, handler) {
          if (err.response?.statusCode == 401) {
            Session.instance.notifyUnauthorized();
          }
          handler.next(err);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();
  late final Dio _dio;

  /// Unwraps the `{ success, data | error }` envelope, or throws an
  /// [ApiException] with the backend's error string.
  T _unwrap<T>(dynamic body, T Function(dynamic data) map) {
    if (body is Map && body['success'] == true) {
      return map(body['data']);
    }
    final msg = (body is Map && body['error'] is String)
        ? body['error'] as String
        : 'error';
    throw ApiException(msg);
  }

  ApiException _toException(Object err) {
    if (err is ApiException) return err;
    if (err is DioException) {
      final data = err.response?.data;
      if (data is Map && data['error'] is String) {
        return ApiException(data['error'] as String);
      }
      return ApiException(err.message ?? 'Network error');
    }
    return ApiException(err.toString());
  }

  Future<T> get<T>(
    String path,
    T Function(dynamic data) map, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.get(path, queryParameters: _clean(query));
      return _unwrap(res.data, map);
    } catch (e) {
      throw _toException(e);
    }
  }

  Future<T> post<T>(
    String path,
    T Function(dynamic data) map, {
    Object? body,
  }) async {
    try {
      final res = await _dio.post(path, data: body);
      return _unwrap(res.data, map);
    } catch (e) {
      throw _toException(e);
    }
  }

  Future<T> put<T>(
    String path,
    T Function(dynamic data) map, {
    Object? body,
  }) async {
    try {
      final res = await _dio.put(path, data: body);
      return _unwrap(res.data, map);
    } catch (e) {
      throw _toException(e);
    }
  }

  Future<T> delete<T>(String path, T Function(dynamic data) map) async {
    try {
      final res = await _dio.delete(path);
      return _unwrap(res.data, map);
    } catch (e) {
      throw _toException(e);
    }
  }

  Map<String, dynamic>? _clean(Map<String, dynamic>? q) {
    if (q == null) return null;
    final out = <String, dynamic>{};
    q.forEach((k, v) {
      if (v != null) out[k] = v;
    });
    return out;
  }
}
