package com.paisavault.paisa_vault

/**
 * Loose pre-filter in the receiver so unrelated personal SMS are never stored.
 * The precise OTP and promotional filter runs later in Dart against the golden corpus.
 * Keeps a message only when it has an amount and a money-movement word.
 */
object SmsFilter {
    private val amount = Regex("""(?i)(rs\.?|inr|₹)\s*[\d,]+(\.\d+)?""")
    private val movement = Regex(
        """(?i)\b(debited|credited|debit|credit|spent|paid|withdrawn|received|sent|purchase|txn|transaction|payment)\b"""
    )
    private val otp = Regex("""(?i)\b(otp|one[- ]time password|verification code)\b""")
    private val strongMovement = Regex("""(?i)\b(debited|credited|spent|withdrawn)\b""")

    fun looksLikeBankMessage(body: String): Boolean {
        if (!amount.containsMatchIn(body) || !movement.containsMatchIn(body)) return false
        // "Your OTP for Rs 500 payment is 123456" is an OTP, not a transaction.
        if (otp.containsMatchIn(body) && !strongMovement.containsMatchIn(body)) return false
        return true
    }
}
