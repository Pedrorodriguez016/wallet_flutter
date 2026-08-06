import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Interceptor global de Dio para wallet_flutter.
/// Gestiona la inyección del token Bearer, captura el error 401,
/// ejecuta el auto-refresh y reintenta automáticamente la petición HTTP que falló.
class WalletAuthInterceptor extends Interceptor {
  final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  WalletAuthInterceptor(this.dio);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'wallet_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // Si la petición devuelve un 401 Unauthorized y no es una llamada al propio refresh/login
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/auth/refresh') &&
        !err.requestOptions.path.contains('/auth/keycloak/login')) {
      print("WALLET_INTERCEPTOR: 401 detectado en ${err.requestOptions.path}. Intentando refresh...");

      final bool refreshSuccess = await _handleTokenRefresh();

      if (refreshSuccess) {
        final newToken = await _storage.read(key: 'wallet_token');
        print("WALLET_INTERCEPTOR: Refresh exitoso. Reintentando petición a ${err.requestOptions.path}...");

        try {
          final opts = Options(
            method: err.requestOptions.method,
            headers: {
              ...err.requestOptions.headers,
              'Authorization': 'Bearer $newToken',
            },
          );

          final response = await dio.request(
            err.requestOptions.path,
            data: err.requestOptions.data,
            queryParameters: err.requestOptions.queryParameters,
            options: opts,
          );

          return handler.resolve(response);
        } catch (retryError) {
          if (retryError is DioException) {
            return handler.next(retryError);
          }
        }
      } else {
        print("WALLET_INTERCEPTOR: Refresh token expirado. Borrando sesión...");
        await _storage.delete(key: 'wallet_token');
        await _storage.delete(key: 'wallet_refresh_token');
      }
    }

    return handler.next(err);
  }

  Future<bool> _handleTokenRefresh() async {
    try {
      final refreshToken = await _storage.read(key: 'wallet_refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final refreshDio = Dio(BaseOptions(
        baseUrl: dotenv.env['BACKEND_URL'] ?? 'http://172.20.10.2:8000',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final newAccessToken = response.data['access_token'];
        final newRefreshToken = response.data['refresh_token'];

        if (newAccessToken != null && newAccessToken.toString().isNotEmpty) {
          await _storage.write(key: 'wallet_token', value: newAccessToken.toString());
          if (newRefreshToken != null && newRefreshToken.toString().isNotEmpty) {
            await _storage.write(key: 'wallet_refresh_token', value: newRefreshToken.toString());
          }
          print("WALLET_INTERCEPTOR: Tokens guardados en FlutterSecureStorage.");
          return true;
        }
      }
      return false;
    } catch (e) {
      print("WALLET_INTERCEPTOR: Error refrescando token -> $e");
      return false;
    }
  }
}
