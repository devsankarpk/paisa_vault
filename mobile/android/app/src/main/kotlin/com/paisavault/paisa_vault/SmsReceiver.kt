package com.paisavault.paisa_vault

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log

/**
 * Phase 0 spike: prove a new SMS reaches the app and tell the two SIMs apart.
 * Logs the sender and SIM subscription id only. The message text is never logged.
 */
class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
        val parts = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        val sender = parts.firstOrNull()?.originatingAddress
        val bodyLength = parts.sumOf { it.messageBody?.length ?: 0 }
        val subscription = intent.getIntExtra("subscription", -1)
        Log.i(TAG, "sender=$sender sub=$subscription parts=${parts.size} bodyLength=$bodyLength")
    }

    companion object {
        const val TAG = "PV_SMS"
    }
}
