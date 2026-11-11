#!/usr/bin/env bash
# Copies the page into the Android project as assets/index.html.
# Run this after every change to home-work-orders.html, then rebuild in Android Studio.
set -euo pipefail
cd "$(dirname "$0")/.."

SRC=home-work-orders.html
ASSETS=android/app/src/main/assets
GRADLE=android/app/build.gradle.kts

page_ver=$(grep -o "APP_VERSION='[^']*'" "$SRC" | head -1 | sed "s/APP_VERSION='//;s/'//")
apk_ver=$(grep -o 'versionName = "[^"]*"' "$GRADLE" | head -1 | sed 's/versionName = "//;s/"//')
if [ -z "$page_ver" ] || [ "$page_ver" != "$apk_ver" ]; then
  echo "Version mismatch: page says '$page_ver', build.gradle.kts says '$apk_ver'. Make them match." >&2
  exit 1
fi

mkdir -p "$ASSETS/libs"
{
  printf '%s\n' '<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover"><style>[hidden]{display:none!important}</style>'
  sed \
    -e 's#https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js#libs/jspdf.umd.min.js#' \
    -e 's#https://cdnjs.cloudflare.com/ajax/libs/jspdf-autotable/3.8.2/jspdf.plugin.autotable.min.js#libs/jspdf.plugin.autotable.min.js#' \
    "$SRC"
} > "$ASSETS/index.html"

if grep -q 'cdnjs.cloudflare.com' "$ASSETS/index.html"; then
  echo "A CDN script is still referenced in index.html; add it to libs/ and to this script." >&2
  exit 1
fi
echo "Synced $SRC (v$page_ver) to $ASSETS/index.html"
