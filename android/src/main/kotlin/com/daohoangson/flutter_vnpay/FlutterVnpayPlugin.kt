package com.daohoangson.flutter_vnpay

import android.app.Activity
import android.content.Intent
import android.util.Log
import androidx.annotation.NonNull
import com.vnpay.authentication.VNP_AuthenticationActivity

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

/** FlutterVnpayPlugin */
class FlutterVnpayPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.NewIntentListener {
    private lateinit var eventChannel: EventChannel
    private lateinit var methodChannel: MethodChannel

    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var eventSink: EventChannel.EventSink? = null
    private var scheme: String = ""

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Log.d("FlutterVnpayPlugin", "[flutter_vnpay_debug] onAttachedToEngine")

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.daohoangson.flutter_vnpay/event_channel")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                handleIntent(activity?.intent)
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.daohoangson.flutter_vnpay/method_channel")
        methodChannel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            "setScheme" -> setScheme(call, result)
            "show" -> show(call, result)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding

        binding.addOnNewIntentListener(this)
        handleIntent(activity?.intent)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeOnNewIntentListener(this)

        activity = null
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onNewIntent(intent: Intent?): Boolean {
        return handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?): Boolean {
        if (intent?.action != Intent.ACTION_VIEW) return false

        val data = intent.data
        if (data?.scheme != scheme) return false

        eventSink?.success(intent.dataString)
        Log.d("FlutterVnpayPlugin", String.format("[flutter_vnpay_debug] intent.data=%s", intent.dataString))

        return true
    }

    private fun setScheme(call: MethodCall, result: Result) {
        val newScheme = call.argument<String>("scheme")
        if (newScheme.isNullOrEmpty()) {
            return result.error("scheme_is_invalid", "Invalid scheme.", newScheme)
        }

        scheme = newScheme
        result.success(scheme)
    }

    private fun show(call: MethodCall, result: Result) {
        if (activity == null) {
            return result.error("activity_is_null", "Activity has not been attached.", null)
        }
        if (scheme.isEmpty()) {
            return result.error("scheme_is_empty", "`configureApp2app` must be called before `show`", null)
        }

        val intent = Intent(activity, VNP_AuthenticationActivity::class.java)
        intent.putExtra("is_sandbox", call.argument<Boolean>("is_sandbox"))
        intent.putExtra("scheme", scheme)
        intent.putExtra("tmn_code", call.argument<String>("tmn_code"))
        intent.putExtra("url", call.argument<String>("url"))
        VNP_AuthenticationActivity.setSdkCompletedCallback {
            result.success(it)
        }

        activity?.startActivity(intent)
    }
}
