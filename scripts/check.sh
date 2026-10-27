#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$CHEFS_REPO_ROOT"
dart --suppress-analytics format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
npm run test:rules
flutter build web --release --dart-define=USE_FIREBASE_EMULATORS=true --no-web-resources-cdn
