import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:openapi/openapi.dart';

/// Adapter boundary for the generated Dart client and its session cookies.
class ApiClientAdapter {
  ApiClientAdapter({String? baseUrl, CookieJar? cookieJar, Dio? dio})
    : cookieJar = cookieJar ?? CookieJar(),
      dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl ?? Openapi.basePath)) {
    if (!this.dio.interceptors.any(
      (interceptor) => interceptor is CookieManager,
    )) {
      this.dio.interceptors.add(CookieManager(this.cookieJar));
    }
    api = Openapi(dio: this.dio);
  }

  final CookieJar cookieJar;
  final Dio dio;
  late final Openapi api;
}
