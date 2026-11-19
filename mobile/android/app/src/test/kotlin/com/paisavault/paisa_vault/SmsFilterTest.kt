package com.paisavault.paisa_vault

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class SmsFilterTest {
    @Test fun keepsDebitAlert() =
        assertTrue(SmsFilter.looksLikeBankMessage("Rs 499.00 debited from A/c XX1234 on 20-11-26 to SWIGGY"))

    @Test fun keepsCreditCardSpend() =
        assertTrue(SmsFilter.looksLikeBankMessage("INR 1,250.00 spent on your card ending 4321 at AMAZON"))

    @Test fun keepsUpiCredit() =
        assertTrue(SmsFilter.looksLikeBankMessage("₹2000 credited to your account via UPI"))

    @Test fun dropsOtp() =
        assertFalse(SmsFilter.looksLikeBankMessage("123456 is your OTP for Rs 500 payment. Do not share."))

    @Test fun dropsMessageWithoutAmount() =
        assertFalse(SmsFilter.looksLikeBankMessage("Your card was debited. Call us if this was not you."))

    @Test fun dropsPersonalChat() =
        assertFalse(SmsFilter.looksLikeBankMessage("Dinner at 8? I paid last time"))

    @Test fun keepsDebitEvenWhenOtpWordAppears() =
        assertTrue(SmsFilter.looksLikeBankMessage("Rs 5000 debited. If not you, do not share OTP and call the bank"))
}
