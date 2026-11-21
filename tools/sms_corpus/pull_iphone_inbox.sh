#!/bin/sh
# Copy the Shortcut inbox from the iPhone and add any new lines to one cumulative file, so earlier
# collections are never overwritten. Then rebuild the anonymised samples.
# Needs the iPhone connected and unlocked. Prints counts only, never message text.
# Source app: Llm Bench (old Shortcut action). Use APP=com.paisavault.paisaVault for the real app's
# own stage once it is the only route (its messages are encrypted on the phone and are read by the app).
set -e
DEVICE="${1:-$(xcrun devicectl list devices 2>/dev/null | grep iPhone | grep -Eo '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' | head -1)}"
APP="${APP:-com.paisavault.llmBench}"
ALL=testdata/raw/iphone_inbox_all.jsonl
mkdir -p testdata/raw
TMP=$(mktemp)
xcrun devicectl device copy from --device "$DEVICE" --domain-type appDataContainer \
  --domain-identifier "$APP" --source Documents/shortcut_inbox.jsonl \
  --destination "$TMP" >/dev/null
touch "$ALL"
cat "$ALL" "$TMP" | grep -v '^$' | sort -u > "$ALL.new"
mv "$ALL.new" "$ALL"
rm -f "$TMP"
echo "Cumulative inbox lines: $(wc -l < "$ALL")"
python3 -I tools/sms_corpus/anonymise.py "$ALL" --format jsonl --all \
  -o testdata/iphone_inbox_samples.json --review testdata/iphone_inbox_review.txt | head -2
