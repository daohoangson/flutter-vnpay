import 'dart:async';
import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vnpay/flutter_vnpay.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// This hash should be kept secret on the server.
/// Do NOT ever include it in your production app.
const hashSecret = 'MVZHBMXNCMZACNGBIFYMZOVYGSHWGMEU';

/// Register as a test merchant at
/// https://sandbox.vnpayment.vn/
const tmnCode = 'KALZU1HT';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();

    FlutterVnpay.configureApp2app(
      onSuccess: () => debugPrint('[flutter_vnpay_debug] onA2aSuccess'),
      scheme: 'flutter_vnpay_scheme',
    );
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await FlutterVnpay.platformVersion ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Text('Running on: $_platformVersion\n'),
            ),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final url = await buildUrl();

                  final result = await FlutterVnpay.show(
                    ios: ConfigiOS.withThemeColor(context),
                    isSandbox: true,
                    tmnCode: tmnCode,
                    url: url,
                  );

                  debugPrint('[flutter_vnpay_debug] show() result=$result');
                },
                child: Text('show()'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds VNPay URL as per techspec 2.0.1.
  ///
  /// In a real deployment, this should be done on the server side,
  /// we are doing it here for demonstration purpose only.
  /// Do NOT ever include the [hashSecret] in your production app.
  Future<String> buildUrl() async {
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyyMMddHHmmss');

    final cloudflareTrace =
        await http.get(Uri.parse('https://www.cloudflare.com/cdn-cgi/trace'));
    final ipMatch = RegExp(r'ip=(.+)\n').firstMatch(cloudflareTrace.body);
    if (ipMatch == null) {
      throw UnsupportedError(cloudflareTrace.body);
    }
    // the address could be IPv6, which may not be accepted by VNPay -- I'm not sure
    final ipAddr = ipMatch.group(1)!;

    final params = <String, String>{
      'vnp_Version': '2.0.0',
      'vnp_Command': 'pay',
      'vnp_TmnCode': tmnCode,
      'vnp_BankCode': 'NCB', // the only bank available in sandbox
      'vnp_Locale': 'vn',
      'vnp_CurrCode': 'VND',
      'vnp_TxnRef': (now.millisecondsSinceEpoch / 1000).toString(),
      'vnp_OrderInfo': 'Top up 100k',
      'vnp_OrderType': 'topup',
      'vnp_Amount': '10000000',
      'vnp_ReturnUrl': 'http://success.sdk.merchantbackapp/',
      'vnp_IpAddr': ipAddr,
      'vnp_CreateDate': dateFormat.format(now),
      'vnp_ExpireDate': dateFormat.format(now.add(const Duration(hours: 1))),
    };

    final query = StringBuffer();

    final output = AccumulatorSink<crypto.Digest>();
    final sha256 = crypto.sha256.startChunkedConversion(output);
    sha256.add(utf8.encode(hashSecret));
    for (final key in params.keys.toList()..sort()) {
      final value = params[key]!;

      if (query.isNotEmpty) sha256.add(utf8.encode('&'));
      sha256.add(utf8.encode(key));
      sha256.add(utf8.encode('='));
      sha256.add(utf8.encode(value));

      query.write(query.isEmpty ? '?' : '&');
      query.write(Uri.encodeQueryComponent(key));
      query.write('=');
      query.write(Uri.encodeQueryComponent(value));
    }

    sha256.close();
    final secureHash = output.events.single;

    query.write('&vnp_SecureHashType=SHA256');
    query.write('&vnp_SecureHash=$secureHash');

    final url = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html$query';
    debugPrint('[flutter_vnpay_debug] url=$url');

    return url;
  }
}
