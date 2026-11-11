#!/usr/bin/env bash
# Copies the page into the Android project (assets/index.html) and the iOS project (IGotThis/Web/).
# Run this after every change to home-work-orders.html, then rebuild in Android Studio.
set -euo pipefail
cd "$(dirname "$0")/.."

SRC=home-work-orders.html
ASSETS=android/app/src/main/assets
GRADLE=android/app/build.gradle.kts
IOS_WEB=ios/IGotThis/Web
IOS_YML=ios/project.yml

page_ver=$(grep -o "APP_VERSION='[^']*'" "$SRC" | head -1 | sed "s/APP_VERSION='//;s/'//")
apk_ver=$(grep -o 'versionName = "[^"]*"' "$GRADLE" | head -1 | sed 's/versionName = "//;s/"//')
if [ -z "$page_ver" ] || [ "$page_ver" != "$apk_ver" ]; then
  echo "Version mismatch: page says '$page_ver', build.gradle.kts says '$apk_ver'. Make them match." >&2
  exit 1
fi

ios_mkt=$(grep -o 'MARKETING_VERSION: "[^"]*"' "$IOS_YML" | head -1 | sed 's/MARKETING_VERSION: "//;s/"//')
ios_build=$(grep -o 'CURRENT_PROJECT_VERSION: "[^"]*"' "$IOS_YML" | head -1 | sed 's/CURRENT_PROJECT_VERSION: "//;s/"//')
if [ "$ios_mkt.$ios_build" != "$page_ver" ]; then
  echo "iOS version mismatch: $IOS_YML says '$ios_mkt' build '$ios_build', the page says '$page_ver' (first three parts = MARKETING_VERSION, fourth = CURRENT_PROJECT_VERSION)." >&2
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
rm -rf "$IOS_WEB"; mkdir -p "$IOS_WEB"
cp "$ASSETS/index.html" "$IOS_WEB/index.html"
cp -r "$ASSETS/libs" "$IOS_WEB/libs"
echo "Synced $SRC (v$page_ver) to $ASSETS/index.html and $IOS_WEB/"
