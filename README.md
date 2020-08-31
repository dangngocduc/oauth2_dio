# oauth2_dio

## Implement

### 1, _OAuthInfoMixin_

Object hold info (token, refreshToken) is a mixin of OAuthInfoMixin

### 2, Create _Oauth2Interceptor_
```
    _oauth2manager = Oauth2Manager<SignInResponse>(
        currentValue: token,
        onSave: (value) {
          //TODO Save token to SharePreference
        });
        
    _dio.interceptors.add(
      Oauth2Interceptor(
        dio: _dio,
        oauth2Dio:
            Dio(BaseOptions(baseUrl: 'http://abc.xyz/api/')),
        pathRefreshToken: 'auth/refreshToken',
        parserJson: (json) {
          //TODO Parser json to object which a mixin of OAuthInfoMixin
        },
        tokenProvider: _oauth2manager,
      ),
    );
```