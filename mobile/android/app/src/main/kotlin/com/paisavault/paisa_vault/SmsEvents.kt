package com.paisavault.paisa_vault

import android.os.Handler
import android.os.Looper

/** Lets a running Flutter UI know that a message was just staged. */
object SmsEvents {
    @Volatile
    var listener: (() -> Unit)? = null

    fun arrived() {
        val l = listener ?: return
        Handler(Looper.getMainLooper()).post { l() }
    }
}
