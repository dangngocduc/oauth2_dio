import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class Oauth2Manager<OAuthInfoMixin> {
  static const TAG = 'Oauth2Manager';

  OAuthInfoMixin? currentValue;

  late StreamController<OAuthInfoMixin?> controller;

  ValueChanged<OAuthInfoMixin?>? onSave;

  Oauth2Manager({this.currentValue, this.onSave}) {
    controller = StreamController.broadcast();
    controller.stream.listen((event) {
      currentValue = event;
    });
  }

  void add(OAuthInfoMixin? event) {
    developer.log('add [event] : $event', name: TAG);
    currentValue = event;
    onSave!(event);
    controller.add(event);
  }

  void dispose() {
    controller.close();
  }
}

mixin OAuthInfoMixin {
  get accessToken;

  get refreshToken;
}
