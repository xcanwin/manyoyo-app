import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';

import 'package:manyoyo_app/core/auth_notifier.dart';

class ApiClient {
  ApiClient({required String baseUrl, required this.cookieJar})
    : _baseUrl = baseUrl {
    _dio = Dio(BaseOptions(baseUrl: baseUrl))
      ..interceptors.add(CookieManager(cookieJar))
      ..interceptors.add(_CsrfInterceptor())
      ..interceptors.add(_AuthInterceptor(_onUnauthorized));
  }

  String _baseUrl;
  late final Dio _dio;
  final CookieJar cookieJar;

  @visibleForTesting
  Dio get testDio => _dio;
  AuthNotifier? authNotifier;

  String get baseUrl => _baseUrl;

  void updateBaseUrl(String url) {
    _baseUrl = url;
    _dio.options.baseUrl = url;
  }

  void _onUnauthorized() {
    authNotifier?.logout();
  }

  Future<void> login(String username, String password) async {
    try {
      await _dio.post<dynamic>(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401) {
        throw Exception('用户名或密码错误。');
      }
      throw Exception('登录失败：${e.message}');
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<dynamic>('/auth/logout');
    } catch (_) {}
    authNotifier?.logout();
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.put<T>(
      path,
      data: data,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<String> getCookieHeader() async {
    final uri = Uri.parse(_baseUrl);
    final cookies = await cookieJar.loadForRequest(uri);
    return cookies.map((c) => '${c.name}=${c.value}').join('; ');
  }

  Future<WebSocket> connectWebSocket(String path) async {
    final wsBaseUrl = _baseUrl.replaceFirst(RegExp(r'^http'), 'ws');
    final cookieHeader = await getCookieHeader();
    return WebSocket.connect(
      '$wsBaseUrl$path',
      headers: cookieHeader.isNotEmpty ? {'Cookie': cookieHeader} : null,
    );
  }
}

class _CsrfInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Requested-With'] = 'XMLHttpRequest';
    handler.next(options);
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._onUnauthorized);

  final void Function() _onUnauthorized;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _onUnauthorized();
    }
    handler.next(err);
  }
}
