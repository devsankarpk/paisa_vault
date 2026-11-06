package com.paisavault.paisa_vault

import android.Manifest
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Spike only. The real app shows the SMS disclosure screen before this prompt (Phase 1A).
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            requestPermissions(arrayOf(Manifest.permission.RECEIVE_SMS), 1)
        }
    }
}
