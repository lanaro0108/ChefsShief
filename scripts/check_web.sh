#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$CHEFS_REPO_ROOT"
if [[ ! -f build/web/main.dart.js ]]; then
  echo 'Build first: flutter build web --release --dart-define=USE_FIREBASE_EMULATORS=true --no-web-resources-cdn' >&2
  exit 1
fi
if curl --silent --max-time 2 http://127.0.0.1:7357/ >/dev/null; then
  echo 'Port 7357 is occupied. Existing services were left running.' >&2
  exit 1
fi
if [[ -z "${CHROMIUM_EXECUTABLE:-}" ]]; then
  CHROMIUM_EXECUTABLE="$(command -v chromium || command -v google-chrome || true)"
  export CHROMIUM_EXECUTABLE
fi
if [[ -z "$CHROMIUM_EXECUTABLE" ]]; then
  echo 'Install Chromium/Chrome or set CHROMIUM_EXECUTABLE.' >&2
  exit 1
fi
python3 -m http.server 7357 --bind 127.0.0.1 --directory build/web >/tmp/chefs-shelf-http.log 2>&1 &
chefs_http_pid=$!
trap 'kill "$chefs_http_pid" 2>/dev/null || true' EXIT
for attempt in {1..40}; do
  if curl --silent --fail http://127.0.0.1:7357/ >/dev/null; then break; fi
  sleep 0.25
done
node scripts/web_smoke.mjs
