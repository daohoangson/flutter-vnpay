import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_vnpay/flutter_vnpay.dart';

void main() {
  const MethodChannel channel =
      MethodChannel('com.daohoangson.flutter_vnpay/method_channel');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await FlutterVnpay.platformVersion, '42');
  });
}
