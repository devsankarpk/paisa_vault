package com.paisavault.paisa_vault

import android.Manifest
import android.content.pm.PackageManager
import android.view.WindowManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var pendingPermission: MethodChannel.Result? = null
    private var channel: MethodChannel? = null

    private fun granted() =
        ContextCompat.checkSelfPermission(this, Manifest.permission.RECEIVE_SMS) == PackageManager.PERMISSION_GRANTED

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "paisa_vault/sms")
        channel = ch
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "hasPermission" -> result.success(granted())
                "requestPermission" -> {
                    if (granted()) {
                        result.success(true)
                    } else {
                        pendingPermission = result
                        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECEIVE_SMS), 1)
                    }
                }
                "pending" -> result.success(
                    SmsStage(this).pending().map {
                        mapOf(
                            "id" to it.id, "sender" to it.sender, "body" to it.body,
                            "receivedAt" to it.receivedAtMillis, "sub" to it.subscriptionId,
                        )
                    }
                )
                "acknowledge" -> {
                    val ids = call.argument<List<String>>("ids") ?: emptyList()
                    SmsStage(this).acknowledge(ids.toSet())
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        SmsEvents.listener = { ch.invokeMethod("arrived", null) }
        // FLAG_SECURE blocks screenshots and recordings and blanks the app switcher card.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "paisa_vault/screen")
            .setMethodCallHandler { call, result ->
                if (call.method == "setProtected") {
                    val on = call.arguments as? Boolean ?: false
                    runOnUiThread {
                        if (on) window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        else window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        SmsEvents.listener = null
        super.onDestroy()
    }

    override fun onRequestPermissionsResult(code: Int, permissions: Array<out String>, results: IntArray) {
        super.onRequestPermissionsResult(code, permissions, results)
        if (code == 1) {
            pendingPermission?.success(granted())
            pendingPermission = null
        }
    }
}
