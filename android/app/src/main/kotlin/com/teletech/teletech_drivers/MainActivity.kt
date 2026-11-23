package com.teletech.teletech_drivers

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val dialerChannel = "com.teletech.teletech_drivers/dialer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, dialerChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "dial") {
                    val phone = call.arguments as? String
                    if (phone.isNullOrBlank()) {
                        result.error("invalid_phone", "Phone is empty", null)
                        return@setMethodCallHandler
                    }
                    val intent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:$phone"))
                    startActivity(intent)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
