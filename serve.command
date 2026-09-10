#!/bin/bash
# Double-click-able bridge for automancia + the Apple Silicon "iPhone & iPad App"
# (App Store) build of Cinco Paus. That build has no bare .monkeystate file to poll --
# it stores the same save string inside its iOS-style preferences plist, under the
# key ".monkeystate", in a sandbox container named by a random UUID (not the bundle
# id). This finds that plist with the macOS-builtin `defaults` command (no Python
# needed for this part), mirrors it out to a real .monkeystate file here whenever it
# changes, and serves this folder -- one file, no typing required.
cd "$(dirname "$0")"

BUNDLE_ID="com.mightyvision.cinco"
PLIST=$(ls -d ~/Library/Containers/*/Data/Library/Preferences/"$BUNDLE_ID".plist 2>/dev/null | head -1)

if [ -z "$PLIST" ]; then
  echo "Could not find a Cinco Paus (App Store) save under ~/Library/Containers/."
  echo "Is it installed, and has it been opened at least once?"
  read -p "Press Enter to close..."
  exit 1
fi

DOMAIN="${PLIST%.plist}"
echo "watching: $PLIST"

(
  last=""
  while true; do
    cur=$(defaults read "$DOMAIN" .monkeystate 2>/dev/null)
    if [ -n "$cur" ] && [ "$cur" != "$last" ]; then
      printf '%s' "$cur" > .monkeystate
      last="$cur"
      echo "$(date '+%H:%M:%S') save updated"
    fi
    sleep 0.2
  done
) &
watcher_pid=$!
trap 'kill "$watcher_pid" 2>/dev/null' EXIT

echo "serving http://localhost:8000/  (Ctrl+C to stop)"
python3 -m http.server
