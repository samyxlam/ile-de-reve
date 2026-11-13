#!/bin/bash
# Cycle complet : serveur local + Chrome headless logiciel + capture.
# Usage : ./tools/capture.sh <sortie.png> [url_suffix] [attente_ms] [clics "x,y;x,y"]
PROJ="/c/Users/Isl4m/WorkBuddy AI/mergecontinu"
OUT="$1"
SUFFIX="${2:-}"
WAIT="${3:-22000}"
CLICKS="${4:-}"

cd "$PROJ" || exit 1
# Profil neuf à chaque capture : la sauvegarde du build web vit dans l'IndexedDB du navigateur.
PROFIL="/tmp/chromecap_$$"
rm -rf "$PROFIL"
python -m http.server 8123 --bind 127.0.0.1 >/dev/null 2>&1 &
SRV=$!
"/c/Program Files/Google/Chrome/Application/chrome.exe" --headless=new --disable-gpu \
  --enable-unsafe-swiftshader --use-gl=swiftshader --remote-debugging-port=9222 \
  --user-data-dir="$PROFIL" --no-first-run --no-default-browser-check about:blank >/dev/null 2>&1 &
CHR=$!
sleep 4

node "$PROJ/tools/shot.js" "http://127.0.0.1:8123/build/web/index.html$SUFFIX" "$OUT" "$WAIT" 460 900 "$CLICKS"
CODE=$?

kill "$CHR" 2>/dev/null
kill "$SRV" 2>/dev/null
exit $CODE
