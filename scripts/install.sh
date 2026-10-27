#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$CHEFS_REPO_ROOT"
if ! command -v flutter >/dev/null; then
  : "${FLUTTER_ROOT:?Install Flutter 3.38.10 or set FLUTTER_ROOT to a writable SDK directory.}"
  mkdir -p "$(dirname "$FLUTTER_ROOT")"
  git clone --depth 1 --branch 3.38.10 https://github.com/flutter/flutter.git "$FLUTTER_ROOT"
fi
if [[ "$(git -C "$(dirname "$(command -v flutter)")/.." rev-parse HEAD)" != c6f67dede3d4aa1aa7a69dd56a3494a5cde6cc80 ]]; then
  echo 'Use the pinned Flutter 3.38.10 SDK (.fvmrc). Existing SDK was not modified.' >&2
  exit 1
fi
flutter --version
if [[ -n "${ANDROID_HOME:-}" ]]; then flutter config --android-sdk "$ANDROID_HOME"; fi
if [[ -n "${JAVA_HOME:-}" && -x "$JAVA_HOME/bin/javac" ]]; then flutter config --jdk-dir "$JAVA_HOME"; fi
if [[ -f /usr/local/share/ca-certificates/environment-proxy-ca.crt && -d /workspace/tools ]]; then
  cp /etc/ssl/certs/java/cacerts /workspace/tools/android-java-cacerts
  keytool -importcert -noprompt -trustcacerts -alias chefs-session-proxy \
    -file /usr/local/share/ca-certificates/environment-proxy-ca.crt \
    -keystore /workspace/tools/android-java-cacerts -storepass changeit
fi
flutter precache --web
flutter pub get --enforce-lockfile
npm ci --no-audit --no-fund
./node_modules/.bin/firebase setup:emulators:firestore
echo 'Dependencies installed. See scripts/run_local.sh and README.md.'
