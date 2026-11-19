package com.paisavault.paisa_vault

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import org.json.JSONObject
import java.io.File
import java.security.KeyStore
import java.util.UUID
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

data class StagedSms(
    val id: String,
    val sender: String,
    val body: String,
    val receivedAtMillis: Long,
    val subscriptionId: Int,
)

/**
 * Encrypted holding area for SMS that arrive while the app is closed. The Flutter side drains it
 * into the encrypted database the next time the app is unlocked. The key lives in the Android
 * Keystore and never leaves it. Message text is never logged.
 */
class SmsStage(context: Context) {
    private val file = File(context.filesDir, "sms_stage.log")

    private fun key(): SecretKey {
        val ks = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (ks.getKey(ALIAS, null) as? SecretKey)?.let { return it }
        val gen = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        gen.init(
            KeyGenParameterSpec.Builder(ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build()
        )
        return gen.generateKey()
    }

    @Synchronized
    fun add(sender: String, body: String, receivedAtMillis: Long, subscriptionId: Int) {
        val id = UUID.randomUUID().toString()
        val json = JSONObject()
            .put("sender", sender).put("body", body)
            .put("at", receivedAtMillis).put("sub", subscriptionId)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding").apply { init(Cipher.ENCRYPT_MODE, key()) }
        val sealed = cipher.iv + cipher.doFinal(json.toString().toByteArray())
        file.appendText("$id\t${Base64.encodeToString(sealed, Base64.NO_WRAP)}\n")
    }

    @Synchronized
    fun pending(): List<StagedSms> {
        if (!file.exists()) return emptyList()
        val out = ArrayList<StagedSms>()
        for (line in file.readLines()) {
            val parts = line.split('\t')
            if (parts.size != 2) continue
            try {
                val raw = Base64.decode(parts[1], Base64.NO_WRAP)
                val cipher = Cipher.getInstance("AES/GCM/NoPadding")
                    .apply { init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, raw.copyOfRange(0, 12))) }
                val j = JSONObject(String(cipher.doFinal(raw.copyOfRange(12, raw.size))))
                out.add(StagedSms(parts[0], j.getString("sender"), j.getString("body"), j.getLong("at"), j.getInt("sub")))
            } catch (e: Exception) {
                // Unreadable line (for example after a Keystore reset): skip it.
            }
        }
        return out
    }

    @Synchronized
    fun acknowledge(ids: Set<String>) {
        if (!file.exists()) return
        val keep = file.readLines().filter { it.substringBefore('\t') !in ids }
        file.writeText(if (keep.isEmpty()) "" else keep.joinToString("\n", postfix = "\n"))
    }

    private companion object {
        const val ALIAS = "pv_sms_stage_key"
    }
}
