import Flutter
import UIKit
import CallAppSDK

public class SwiftFlutterVnpayPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftFlutterVnpayPlugin()
        registrar.addApplicationDelegate(instance)
        
        let binaryMessenger = registrar.messenger()
        let methodChannel = FlutterMethodChannel(
            name: "com.daohoangson.flutter_vnpay/method_channel",
            binaryMessenger: binaryMessenger
        )
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        
        let eventChannel = FlutterEventChannel(
            name: "com.daohoangson.flutter_vnpay/event_channel",
            binaryMessenger: binaryMessenger
        )
        eventChannel.setStreamHandler(instance)
    }
    
    private var controller: UIViewController?
    private var eventSink: FlutterEventSink?
    private var scheme: String = ""
    private var sdkResult: FlutterResult?
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        print("[flutter_vnpay_debug] application:didFinishLaunchingWithOptions")
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sdkCompleted),
            name: Notification.Name("SDK_COMPLETED"),
            object: nil
        )
        
        if let rootViewController = application.delegate?.window??.rootViewController {
            controller = rootViewController
        }
        
        return true
    }
    
    public func application(_ application: UIApplication, open url: URL, sourceApplication: String, annotation: Any) -> Bool {
        print("[flutter_vnpay_debug] application:openURL")
        
        guard url.scheme == scheme else { return false }
        eventSink?.self(url.absoluteString)
        return true
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "setScheme":
            setScheme(call, result: result)
        case "show":
            show(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
    
    @objc private func sdkCompleted(_ notification: NSNotification) {
        guard notification.name.rawValue == "SDK_COMPLETED" else { return }
        
        if let dict = notification.object as? [String: Any],
           let action = dict["Action"] as? String {
            sdkResult?.self(action)
        }
    }
    
    private func setScheme(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let newScheme = arguments["scheme"] as? String,
              !newScheme.isEmpty else {
            return result(FlutterError(code: "scheme_is_invalid", message: "Invalid scheme", details: nil))
        }
        
        scheme = newScheme
        result(newScheme)
    }
    
    private func show(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        sdkResult = nil
        
        guard let homeViewController = controller else {
            return result(FlutterError(code: "controller_is_nil", message: "Controller has not been set", details: nil))
        }
        guard !scheme.isEmpty else {
            return result(FlutterError(code: "scheme_is_empty", message: "`configureApp2app` must be called before `show`", details: nil))
        }
        
        guard let arguments = call.arguments as? [String: Any] else {
            return result(FlutterError(code: "arguments_is_invalid", message: "Invalid arguments", details: nil))
        }
        
        if let isSandbox = arguments["is_sandbox"] as? Bool,
           let tmnCode = arguments["tmn_code"] as? String,
           let url = arguments["url"] as? String,
           let _appBackAlert = arguments["ios_app_back_alert"] as? String,
           let _beginColor = arguments["ios_begin_color"] as? String,
           let _endColor = arguments["ios_end_color"] as? String,
           let _iconBackName = arguments["ios_icon_back_name"] as? String,
           let _title = arguments["ios_title"] as? String,
           let _titleColor = arguments["ios_title_color"] as? String {
            CallAppInterface.setHomeViewController(homeViewController)
            CallAppInterface.setSchemes(scheme)
            CallAppInterface.setIsSandbox(isSandbox)
            CallAppInterface.setAppBackAlert(_appBackAlert)
            CallAppInterface.showPushPaymentwithPaymentURL(
                url,
                withTitle: _title,
                iconBackName: _iconBackName,
                beginColor: _beginColor,
                endColor: _endColor,
                titleColor: _titleColor,
                tmn_code: tmnCode
            )
            
            sdkResult = result
        }
    }
}
