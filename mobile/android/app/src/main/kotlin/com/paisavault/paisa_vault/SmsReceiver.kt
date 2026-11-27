package com.paisavault.paisa_vault

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log

/**
 * Saves each new bank-looking SMS into the encrypted stage straight away, even when the app is
 * closed. Logs only the sender, SIM id and length, never the message text.
 */
class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
        val parts = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        if (parts.isEmpty()) return
        val sender = parts.first().originatingAddress ?: return
        val body = parts.joinToString("") { it.messageBody ?: "" }
        val subscription = intent.getIntExtra("subscription", -1)
        val keep = SmsFilter.looksLikeBankMessage(body)
        Log.i(TAG, "sender=$sender sub=$subscription bodyLength=${body.length} kept=$keep")
        if (!keep) return
        try {
            val stage = SmsStage(context)
            stage.add(sender, body, System.currentTimeMillis(), subscription)
            // App open: it picks the message up itself. App closed: say it was saved.
            if (SmsEvents.listener == null) SmsAlert.show(context, stage.pending().size)
            else SmsEvents.arrived()
        } catch (e: Exception) {
            Log.e(TAG, "stage failed: ${e.javaClass.simpleName}")
        }
    }

    companion object {
        const val TAG = "PV_SMS"
    }
}
