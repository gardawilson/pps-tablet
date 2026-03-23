#!/bin/bash
set -e

# ============================================================
# deploy.sh — Automate Flutter APK release & publish
#
# Usage:
#   ./deploy.sh <version> "<changelog>" [options]
#
# Options:
#   --dev        Build + publish ke backend lokal (test dulu)
#   --force      Paksa semua tablet update (forceUpdate: true)
#   --min <ver>  Set minVersion (default: 1.0.26)
#
# Alur yang disarankan:
#   1. ./deploy.sh 1.0.58 "Fix Bug" --dev    ← test di lokal dulu
#   2. ./deploy.sh 1.0.58 "Fix Bug"          ← production jika oke
# ============================================================

VERSION=$1
CHANGELOG=$2

# --- Parse flags ---
MODE="production"
FORCE_UPDATE="false"
MIN_VERSION="1.0.26"

shift 2 2>/dev/null || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dev)   MODE="dev" ;;
    --force) FORCE_UPDATE="true" ;;
    --min)   MIN_VERSION="$2"; shift ;;
    *)       echo "Unknown flag: $1"; exit 1 ;;
  esac
  shift
done

# --- Config ---
FILE_NAME="app-release.apk"
APK_OUTPUT="build/app/outputs/flutter-apk/app-release.apk"
UPDATE_TOKEN="${UPDATE_TOKEN:-"UTAMA-UPDATE-SECRET-123"}"

DEV_SERVER="http://192.168.11.153:7500"
PROD_SERVER="http://192.168.10.100:7500"

if [ "$MODE" == "dev" ]; then
  API_BASE_URL="$DEV_SERVER"
else
  API_BASE_URL="$PROD_SERVER"
fi

PUBLISH_URL="$API_BASE_URL/api/update/tablet/publish"

# --- Validation ---
if [ -z "$VERSION" ] || [ -z "$CHANGELOG" ]; then
  echo ""
  echo "Usage: ./deploy.sh <version> \"<changelog>\" [--dev] [--force] [--min <ver>]"
  echo ""
  echo "Examples:"
  echo "  ./deploy.sh 1.0.58 \"Fix Bug\"              # production"
  echo "  ./deploy.sh 1.0.58 \"Fix Bug\" --dev         # test lokal dulu"
  echo "  ./deploy.sh 1.0.58 \"Fix Bug\" --force       # production force update"
  echo ""
  exit 1
fi

# Extract build number from current pubspec (increment by 1)
CURRENT_BUILD=$(grep '^version:' pubspec.yaml | sed 's/.*+//')
NEXT_BUILD=$((CURRENT_BUILD + 1))

echo ""
echo "=================================================="
echo " PPS Tablet — Deploy Script"
echo "=================================================="
echo " Mode        : $MODE"
echo " Server      : $API_BASE_URL"
echo " Version     : $VERSION+$NEXT_BUILD"
echo " Min Version : $MIN_VERSION"
echo " Force Update: $FORCE_UPDATE"
echo " Changelog   : $CHANGELOG"
echo "=================================================="
echo ""

if [ "$MODE" == "production" ]; then
  echo "  WARNING: PRODUCTION — update akan diterima semua tablet!"
  echo ""
fi

read -p "Lanjutkan deploy? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "Deploy dibatalkan."
  exit 0
fi

# --- Step 1: Update pubspec.yaml version ---
echo ""
echo "[1/5] Updating version in pubspec.yaml..."
sed -i "s/^version: .*/version: $VERSION+$NEXT_BUILD/" pubspec.yaml
echo "      Done: version set to $VERSION+$NEXT_BUILD"

# --- Step 2: Set .env ---
echo ""
echo "[2/5] Setting .env ($MODE)..."
cat > .env << EOF
API_BASE_URL=$API_BASE_URL
SOCKET_BASE_URL=$API_BASE_URL
UPDATE_BASE_URL=$API_BASE_URL
APP_ID=tablet
EOF
echo "      Done: .env → $API_BASE_URL"

# --- Step 3: Build APK release ---
echo ""
echo "[3/5] Building APK release (this may take a few minutes)..."
flutter build apk --release
echo "      Done: APK built"

# --- Step 4: Show APK info ---
echo ""
echo "[4/5] APK ready..."
APK_SIZE=$(du -sh "$APK_OUTPUT" | cut -f1)
echo "      $APK_OUTPUT ($APK_SIZE)"

# --- Step 5: Upload APK + metadata to server ---
echo ""
echo "[5/5] Uploading APK and publishing update ($MODE)..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$PUBLISH_URL" \
  -H "x-update-token: $UPDATE_TOKEN" \
  -F "apk=@$APK_OUTPUT;filename=$FILE_NAME" \
  -F "latestVersion=$VERSION" \
  -F "minVersion=$MIN_VERSION" \
  -F "forceUpdate=$FORCE_UPDATE" \
  -F "changelog=$CHANGELOG")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "201" ]; then
  echo "      Done: Server responded $HTTP_CODE"
  echo "      Response: $BODY"
else
  echo "      ERROR: Server responded $HTTP_CODE"
  echo "      Response: $BODY"
  exit 1
fi

echo ""
echo "=================================================="
if [ "$MODE" == "dev" ]; then
  echo " Dev deploy selesai! Versi $VERSION tersedia di lokal."
  echo " Test di tablet, lalu jalankan:"
  echo "   ./deploy.sh $VERSION \"$CHANGELOG\" untuk production"
else
  echo " Deploy selesai! Version $VERSION berhasil publish ke production."
fi
echo "=================================================="
echo ""
