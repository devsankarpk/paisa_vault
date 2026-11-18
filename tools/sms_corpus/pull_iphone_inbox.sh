#!/bin/sh
# Copy the Shortcut inbox from the iPhone (Llm Bench app, until the real app takes over)
# and rebuild the anonymised samples. Needs the iPhone connected and unlocked.
# Prints counts only, never message text.
set -e
DEVICE="${1:-$(xcrun devicectl list devices 2>/dev/null | awk '/iPhone/ && /available/ {print $3; exit}')}"
mkdir -p testdata/raw
xcrun devicectl device copy from --device "$DEVICE" --domain-type appDataContainer \
  --domain-identifier com.paisavault.llmBench --source Documents/shortcut_inbox.jsonl \
  --destination testdata/raw/iphone_inbox.jsonl >/dev/null
echo "Inbox lines: $(wc -l < testdata/raw/iphone_inbox.jsonl)"
python3 -I tools/sms_corpus/anonymise.py testdata/raw/iphone_inbox.jsonl --format jsonl --all \
  -o testdata/iphone_inbox_samples.json --review testdata/iphone_inbox_review.txt | head -2
