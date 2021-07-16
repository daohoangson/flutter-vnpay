#import "FlutterVnpayPlugin.h"
#if __has_include(<flutter_vnpay/flutter_vnpay-Swift.h>)
#import <flutter_vnpay/flutter_vnpay-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_vnpay-Swift.h"
#endif

@implementation FlutterVnpayPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterVnpayPlugin registerWithRegistrar:registrar];
}
@end
