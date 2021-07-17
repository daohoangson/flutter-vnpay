# Unofficial VNPay integration for Flutter app

# Getting Started

## Add a pubspec dependency

The Android AAR file and iOS framework files are not included in this repo for licensing reason.
They need to be copied from VNPay sample projects into the correct directory.

- The `merchant-1.0.24.aar` file must be put into `./android/libs/`
- The whole `CallAppSDK.framework` directory must be put inside `./ios/Frameworks/`

A manual patch is required for iOS:
open `./ios/Frameworks/CallAppSDK.framework/Headers/CallAppSDK.h`
then insert this line at the end of it:

```h
#import <CallAppSDK/CallAppInterface.h>
```

The package is not published on `pub.dev` so a path dependency is required.
The easiest way to do this is to add this repo as a submodule into your project,
something like this should work:

```bash
git submodule add https://github.com/daohoangson/flutter-vnpay packages/flutter_vnpay
```

The submodule is optional, just clone the repo anywhere and put it in `pubspec.yaml`:

```yaml

  flutter_vnpay:
    path: ./packages/flutter_vnpay
```

## Prepare native projects

Decides a unique scheme before setting up the projects. The example uses `flutter_vnpay_scheme` for this.

### Android

Add an intent filter into the main `AndroidManifest.xml` file under the `.MainActivity` activity.
Take a look into the example project [here](/example/android/app/src/main/AndroidManifest.xml).

```xml
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.BROWSABLE" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:scheme="flutter_vnpay_scheme" />
            </intent-filter>
```

### iOS

Open the iOS workspace and set the URL scheme under `URL Types` in the `Info` tab.
Xcode will add something like this into `Info.plist`:

```xml
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>flutter_vnpay_scheme</string>
			</array>
		</dict>
	</array>
```

## The Dart side

```dart
import 'package:flutter_vnpay/flutter_vnpay.dart';

// configure this early on
FlutterVnpay.configureApp2app(
  onSuccess: () => debugPrint('[flutter_vnpay_debug] onA2aSuccess'),
  scheme: 'flutter_vnpay_scheme',
);

// start the payment flow
// some backend should return the `tmnCode`, `txnRef` and `url`
// you will need the ref to verify payment result upon completion
await FlutterVnpay.show(tmnCode: tmnCode, url: url);
```
