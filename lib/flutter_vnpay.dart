import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FlutterVnpay {
  static const EventChannel _eventChannel =
      const EventChannel('com.daohoangson.flutter_vnpay/event_channel');
  static const MethodChannel _methodChannel =
      const MethodChannel('com.daohoangson.flutter_vnpay/method_channel');

  static Future<String?> get platformVersion async {
    final String? version =
        await _methodChannel.invokeMethod('getPlatformVersion');
    return version;
  }

  /// Configures app to app flow.
  ///
  /// The [scheme] must be setup properly on the native side.
  ///
  /// ### Android:
  ///
  /// Include an additional intent filter in the main Flutter activity.
  ///
  /// ```xml
  /// <intent-filter>
  ///   <action android:name="android.intent.action.VIEW" />
  ///   <category android:name="android.intent.category.BROWSABLE" />
  ///   <category android:name="android.intent.category.DEFAULT" />
  ///   <data android:scheme="some_unique_string" />
  /// </intent-filter>
  /// ```
  ///
  static Future<bool> configureApp2app({
    required VoidCallback onSuccess,
    required String scheme,
  }) async {
    final result =
        await _methodChannel.invokeMethod('setScheme', {'scheme': scheme});
    final setScheme = result == scheme;

    if (setScheme) {
      _eventChannel.receiveBroadcastStream().listen((_) => onSuccess());
    }

    return setScheme;
  }

  /// Starts payment via VNPay SDK.
  static Future<String?> show({
    required bool isSandbox,
    required String tmnCode,
    required String url,
  }) async {
    final result =
        await _methodChannel.invokeMethod<String>('show', <String, dynamic>{
      'is_sandbox': isSandbox,
      'url': url,
      'tmn_code': tmnCode,
    });
    return result;
  }
}
