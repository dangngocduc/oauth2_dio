import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:oauth2_dio/oauth2_manager.dart';

typedef OAuthInfoMixinParse = OAuthInfoMixin Function(Map map);

class Oauth2Interceptor extends Interceptor {
  static const TAG = 'Oauth2Interceptor';

  Dio dio;
  Dio oauth2Dio;
  String pathRefreshToken;
  String keyRefreshToken = 'refreshToken';
  Oauth2Manager<OAuthInfoMixin?> tokenProvider;
  OAuthInfoMixinParse parserJson;

  Oauth2Interceptor({
    required this.dio,
    required this.oauth2Dio,
    required this.pathRefreshToken,
    required this.tokenProvider,
    required this.parserJson,
    this.keyRefreshToken = 'refreshToken',
  });

  @override
  void onRequest(RequestOptions options,
      RequestInterceptorHandler handler) {
    options.headers.putIfAbsent('Authorization',
        () => 'Bearer ${tokenProvider.currentValue?.accessToken}');
    handler.next(options);
  }

  @override
  void onError(DioError error, ErrorInterceptorHandler handler) async {
    if (error.response?.statusCode == 401 && tokenProvider.currentValue != null) {
      developer.log('onError 401 [$error]', name: TAG);
      RequestOptions options = error.response!.requestOptions;
      if ('Bearer ${tokenProvider.currentValue?.accessToken}' !=
          options.headers["Authorization"]) {
        options.headers["Authorization"] =
            'Bearer ${tokenProvider.currentValue?.accessToken}';
        dio.fetch(options).then((value) {
          handler.resolve(value);
        }, onError: (error) {
          handler.reject(error);
        });
        return;
      }
      //region lock current Dio
      dio.lock();
      dio.interceptors.responseLock.lock();
      dio.interceptors.errorLock.lock();
      //endregion
      oauth2Dio.post(pathRefreshToken, data: {
        keyRefreshToken: tokenProvider.currentValue?.refreshToken
      }).then((value) {
        tokenProvider.add(parserJson(value.data));
        options.headers["Authorization"] =
            'Bearer ${tokenProvider.currentValue?.accessToken}';
      }, onError: (error){
        tokenProvider.add(null);
        handler.reject(error);
      }).whenComplete(() {
        //region unlock when refresh done
        dio.unlock();
        dio.interceptors.responseLock.unlock();
        dio.interceptors.errorLock.unlock();
        //endregion
      }).then((value) {
        dio.fetch(options).then((value) {
          handler.resolve(value);
        }, onError: (error) {
          handler.reject(error);
        });
      });
    } else {
      handler.next(error);
    }
  }
}
