# SMS corpus tooling

Builds the test set for the Phase 0 LLM bake-off and the golden-SMS CI suite. Needs 20 or more messages per bank (HDFC, SBI, ICICI, Axis, Yes Bank) covering debit card, credit card, UPI, NEFT/IMPS, ATM, POS, failed transactions, refunds, OTP and promo messages.

**Banks recognised.** Core (counted in the scorecard): HDFC, SBI, ICICI, Axis, Yes Bank. Bonus (extra format variety, each sample is tagged `"core": false`): PNB, Bank of Baroda, Canara, Union, Kotak, IndusInd, IDFC First, Federal, Bank of India, Indian Bank, Central Bank, UCO, IDBI, RBL, AU, Bandhan, South Indian, Karnataka, Paytm Payments Bank, India Post Payments Bank. The sender codes are best-effort and vary by operator, so check them against your own export (see "Missing a sender?" below). The list lives in `BANK_CODES` in `anonymise.py`.

**Rule:** raw messages stay in `testdata/raw/`, which is git-ignored. Nothing personal is committed.

## 1. Export (pick what fits each phone)

### Android, with USB debugging (no app needed)
```sh
mkdir -p testdata/raw
adb shell content query --uri content://sms/inbox \
  --projection address:body:date:sub_id > testdata/raw/android.txt
```
`sub_id` tells the two SIMs apart (needed for the dual-SIM tests). If the command fails on your phone, use the next option.

### Android, with an app
Use "SMS Backup & Restore", back up to a file, and copy the XML to `testdata/raw/android.xml`.

### iPhone
iPhone has no SMS export. Two options:
- **Mac Messages database** (if Text Message Forwarding is on for your Mac): grant Terminal Full Disk Access, then copy `~/Library/Messages/chat.db` to `testdata/raw/chat.db`.
- **By hand:** copy each bank SMS into `testdata/raw/iphone.txt` in this format, one block per message:
  ```
  sender: VM-HDFCBK
  date: 2026-10-21
  Rs 480.00 debited from A/c XX4821 ...
  ---
  sender: AX-SBIINB
  ...
  ```
  Use the same format for RCS or any message the other routes miss.

## 2. Anonymise
```sh
python3 -I tools/sms_corpus/anonymise.py testdata/raw/android.txt --format adb
python3 -I tools/sms_corpus/anonymise.py testdata/raw/android.xml --format xml -o testdata/sms_android_xml.json
python3 -I tools/sms_corpus/anonymise.py testdata/raw/chat.db --format chatdb -o testdata/sms_iphone.json
python3 -I tools/sms_corpus/anonymise.py testdata/raw/iphone.txt --format blocks -o testdata/sms_iphone_txt.json
```
Only messages from the five banks' sender IDs are kept; add `--all` to keep others (for OTP and promo negatives from non-bank senders). Duplicates are dropped.

What it masks: URLs, e-mails, phone numbers, UPI handles made of digits, long account or card numbers (last 4 kept), account balances, and greeting names. What it keeps on purpose: the transaction amount, last 4 digits, merchant names and UPI handles of merchants, and reference numbers (needed for duplicate tests).

### Missing a sender?
List the distinct senders in an export, with counts and the bank each matches (`-` means no match). No message text is printed:
```sh
python3 -I tools/sms_corpus/anonymise.py testdata/raw/android.txt --format adb --list-senders
```
Send me any bank sender that shows `-` and I will add its code to `BANK_CODES`.

## 3. Review before anything is committed
Open `testdata/review.txt` and read every message. The script cannot find names that appear in the middle of a sentence, places or employer names. Fix them by hand in `testdata/sms_samples.json`.

Then tell me, and I will help label the expected output for each message in `testdata/sms_labels.json`.

## Tests
```sh
cd tools/sms_corpus && python3 -m unittest -v
```
