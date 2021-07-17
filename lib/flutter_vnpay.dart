import 'dart:async';

import 'package:flutter/material.dart';
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
    ConfigiOS ios = const ConfigiOS(),
    required bool isSandbox,
    required String tmnCode,
    required String url,
  }) async {
    final result =
        await _methodChannel.invokeMethod<String>('show', <String, dynamic>{
      'is_sandbox': isSandbox,
      'url': url,
      'tmn_code': tmnCode,

      // iOS values
      'ios_app_back_alert': ios.appBackAlert,
      'ios_begin_color': ios.beginColor.code,
      'ios_end_color': ios.endColor.code,
      'ios_icon_back_name': ios.iconBackName,
      'ios_title': ios.title,
      'ios_title_color': ios.titleColor.code,
    });
    return result;
  }
}

/// Additional configuration for iOS.
@immutable
class ConfigiOS {
  /// Thông báo khi người dùng bấm back
  final String appBackAlert;

  /// Màu của background title
  final Color beginColor;

  /// Màu của background title
  final Color endColor;

  /// Icon back
  final String iconBackName;

  /// Title của trang thanh toán
  final String title;

  /// Màu của title
  final Color titleColor;

  static const _appBackAlertDefault = '';
  static const _backgroundColorDefault = const Color(0xFFFFFFFF);
  static const _iconBackNameDefault = 'ic_back';
  static const _titleDefault = 'VNPay';
  static const _titleColorDefault = const Color(0xFF000000);

  /// Creates an iOS config.
  const ConfigiOS({
    this.appBackAlert = _appBackAlertDefault,
    this.beginColor = _backgroundColorDefault,
    this.endColor = _backgroundColorDefault,
    this.iconBackName = _iconBackNameDefault,
    this.title = _titleDefault,
    this.titleColor = _titleColorDefault,
  });

  /// Creates a config with app bar colors (from theme).
  factory ConfigiOS.withThemeColor(
    BuildContext context, {
    String? appBackAlert,
    String? iconBackName,
    String? title,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appBarTheme = theme.appBarTheme;
    final backgroundColor = appBarTheme.backgroundColor ??
        (colorScheme.brightness == Brightness.dark
            ? colorScheme.surface
            : colorScheme.primary);

    return ConfigiOS(
      appBackAlert: appBackAlert ?? _appBackAlertDefault,
      beginColor: backgroundColor,
      endColor: backgroundColor,
      iconBackName: iconBackName ?? _iconBackNameDefault,
      title: title ?? _titleDefault,
      titleColor: appBarTheme.foregroundColor ??
          (colorScheme.brightness == Brightness.dark
              ? colorScheme.onSurface
              : colorScheme.onPrimary),
    );
  }
}

extension _ColorCode on Color {
  String get code =>
      '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}'.toUpperCase();
}
