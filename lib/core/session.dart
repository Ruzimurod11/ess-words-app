import 'package:flutter/foundation.dart';

/// Synchronous holder for values the Dio interceptors need to read on every
/// request (auth token, current UI language). Riverpod notifiers keep these
/// fields in sync; the interceptor reads them without a container lookup.
class Session {
  Session._();
  static final Session instance = Session._();

  String? token;
  String language = 'uz';

  /// Called by the response interceptor on any 401 so the app can clear the
  /// stored admin token reactively.
  final List<VoidCallback> onUnauthorized = [];

  void notifyUnauthorized() {
    for (final cb in List.of(onUnauthorized)) {
      cb();
    }
  }
}
