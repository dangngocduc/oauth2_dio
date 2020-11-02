import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:oauth2_dio/oauth2_manager.dart';

import 'refresh_exception.dart';

typedef OAuthInfoMixinParse = OAuthInfoMixin Function(Map map);

class Oauth2Interceptor extends Interceptor {
  static const TAG = 'Oauth2Interceptor';

  Dio dio;
  Dio oauth2Dio;
  String pathRefreshToken;
  String keyRefreshToken = 'refreshToken';
  Oauth2Manager<OAuthInfoMixin> tokenProvider;
  OAuthInfoMixinParse parserJson;

  Oauth2Interceptor({
    @required this.dio,
    @required this.oauth2Dio,
    @required this.pathRefreshToken,
    @required this.tokenProvider,
    @required this.parserJson,
    this.keyRefreshToken = 'refreshToken',
  });

  @override
  Future onRequest(RequestOptions options) {
    options.headers.putIfAbsent('Authorization',
        () => 'Bearer ${tokenProvider?.currentValue?.accessToken}');
    return super.onRequest(options);
  }

  @override
  Future onResponse(Response response) async {
    return super.onResponse(response);
  }

  @override
  Future onError(DioError error) async {
    if (error.response?.statusCode == 401) {
      developer.log('onError 401 [$error]', name: TAG);
      RequestOptions options = error.response.request;
      if ('Bearer ${tokenProvider?.currentValue?.accessToken}' !=
          options.headers["Authorization"]) {
        options.headers["Authorization"] =
            'Bearer ${tokenProvider?.currentValue?.accessToken}';
        return dio.request(options.path, options: options);
      }
      //region lock current Dio
      dio.lock();
      dio.interceptors.responseLock.lock();
      dio.interceptors.errorLock.lock();
      //endregion
      return oauth2Dio.post(pathRefreshToken, data: {
        keyRefreshToken: tokenProvider?.currentValue?.refreshToken
      }).then((value) {
        tokenProvider.add(parserJson(value.data));
        options.headers["Authorization"] =
            'Bearer ${tokenProvider?.currentValue?.accessToken}';
      }, onError: (error) {
        developer.log('onError: $error', name: TAG);
        tokenProvider.add(null);
      }).whenComplete(() {
        //region unlock when refresh done
        dio.unlock();
        dio.interceptors.responseLock.unlock();
        dio.interceptors.errorLock.unlock();
        //endregion
      }).then((value) {
        if (tokenProvider.currentValue != null) {
          return dio.request(options.path, options: options);
        } else {
          return dio.reject(RefreshException());
        }
      });
    }
    return super.onError(error);
  }
}
