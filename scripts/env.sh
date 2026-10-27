#!/usr/bin/env bash
# Source this file; tool caches stay outside the Git checkout in cloud tasks.
set -euo pipefail
CHEFS_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export CHEFS_REPO_ROOT
export NO_PROXY="${NO_PROXY:+$NO_PROXY,}localhost,127.0.0.1,::1"
if [[ -d /workspace ]]; then
  export FLUTTER_ROOT="${FLUTTER_ROOT:-/workspace/tools/flutter}"
  export PUB_CACHE="${PUB_CACHE:-/workspace/.pub-cache}"
  export npm_config_cache="${npm_config_cache:-/workspace/.npm}"
  export FIREBASE_EMULATORS_PATH="${FIREBASE_EMULATORS_PATH:-/workspace/.firebase-emulators}"
  export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/workspace/.config}"
  export ANALYZER_STATE_LOCATION_OVERRIDE="${ANALYZER_STATE_LOCATION_OVERRIDE:-/workspace/.dart-analysis}"
  export CI="${CI:-true}"
  export ANDROID_USER_HOME="${ANDROID_USER_HOME:-/workspace/.android}"
  export GRADLE_USER_HOME="${GRADLE_USER_HOME:-/workspace/.gradle}"
  if [[ -d /workspace/tools/android-sdk ]]; then
    export ANDROID_HOME="${ANDROID_HOME:-/workspace/tools/android-sdk}"
  fi
  if [[ -x /workspace/tools/jdk-21/bin/javac ]]; then
    export JAVA_HOME="${JAVA_HOME:-/workspace/tools/jdk-21}"
    export PATH="$JAVA_HOME/bin:$PATH"
  fi
  if [[ -f /workspace/tools/android-java-cacerts ]]; then
    export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:-} -Djavax.net.ssl.trustStore=/workspace/tools/android-java-cacerts -Djavax.net.ssl.trustStorePassword=changeit"
  fi
  if [[ -n "${HTTPS_PROXY:-}" ]]; then
    read -r chefs_proxy_host chefs_proxy_port < <(python3 -c 'import os,urllib.parse; p=urllib.parse.urlparse(os.environ["HTTPS_PROXY"]); print(p.hostname,p.port or 80)')
    export GRADLE_OPTS="${GRADLE_OPTS:-} -Dhttp.proxyHost=$chefs_proxy_host -Dhttp.proxyPort=$chefs_proxy_port -Dhttps.proxyHost=$chefs_proxy_host -Dhttps.proxyPort=$chefs_proxy_port -Dorg.gradle.workers.max=2"
  fi
fi
if [[ -n "${FLUTTER_ROOT:-}" ]]; then export PATH="$FLUTTER_ROOT/bin:$PATH"; fi
