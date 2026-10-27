#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$CHEFS_REPO_ROOT"
if [[ "${1:-}" == emulators ]]; then
  exec npm run emulators
fi
if ! curl --silent --fail --max-time 5 http://127.0.0.1:9099/ >/dev/null; then
  echo 'Start Auth and Firestore first: bash scripts/run_local.sh emulators' >&2
  exit 1
fi
exec flutter run -d web-server --web-hostname 127.0.0.1 --web-port 7357 \
  --dart-define=USE_FIREBASE_EMULATORS=true "$@"
