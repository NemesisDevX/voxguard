#!/usr/bin/env bash
# PauseSignal - one-command local/judging run.
#
# Assembles --dart-define args from environment variables WITHOUT
# echoing their values, then runs the app. Any variable left unset
# simply isn't passed - the app resolves its truthful fallback.
#
# Usage (Git Bash / Linux / macOS):
#   export REVENUECAT_TEST_STORE_KEY=...        # judging Test Store key
#   export VOXGUARD_RELAY_TOKEN=...             # shared relay token
#   export VOXGUARD_ALERT_RELAY_URL=https://<worker>.workers.dev/alert
#   export VOXGUARD_RECORDING_TRANSCRIPTION_URL=https://<worker>.workers.dev
#   export ASSEMBLYAI_TOKEN_BROKER_URL=https://<worker>.workers.dev/aai-token
#   export VOXGUARD_SEMANTIC_PROXY_URL=https://<worker>.workers.dev
#   export ONESIGNAL_APP_ID=...
#
#   ./scripts/judge_local.sh run -d emulator-5554     # run on a device
#   ./scripts/judge_local.sh apk                       # build judging APK
#   ./scripts/judge_local.sh relay                     # wrangler dev relay
#   ./scripts/judge_local.sh doctor                    # config check - prints set/missing only, never values
#
# The script never prints, logs, or writes the values it forwards.
set -euo pipefail
cd "$(dirname "$0")/.."

DEFINES=()
add_define() {  # $1 = dart-define name, $2 = env value (may be unset)
  if [ -n "${2:-}" ]; then
    DEFINES+=("--dart-define=$1=$2")
  fi
}

add_define REVENUECAT_TEST_STORE_KEY "${REVENUECAT_TEST_STORE_KEY:-}"
add_define REVENUECAT_ANDROID_KEY "${REVENUECAT_ANDROID_KEY:-}"
add_define VOXGUARD_RELAY_TOKEN "${VOXGUARD_RELAY_TOKEN:-}"
add_define VOXGUARD_ALERT_RELAY_URL "${VOXGUARD_ALERT_RELAY_URL:-}"
add_define VOXGUARD_RECORDING_TRANSCRIPTION_URL "${VOXGUARD_RECORDING_TRANSCRIPTION_URL:-}"
add_define ASSEMBLYAI_TOKEN_BROKER_URL "${ASSEMBLYAI_TOKEN_BROKER_URL:-}"
add_define VOXGUARD_SEMANTIC_PROXY_URL "${VOXGUARD_SEMANTIC_PROXY_URL:-}"
add_define ONESIGNAL_APP_ID "${ONESIGNAL_APP_ID:-}"

mode="${1:-run}"
case "$mode" in
  doctor)
    # Report each expected env var as set/missing - never the value.
    # server/* variables are checked for awareness only; they belong
    # in server/.dev.vars or `wrangler secret`, not the app build.
    echo "PauseSignal integration config (values never printed):"
    for name in \
      REVENUECAT_TEST_STORE_KEY REVENUECAT_ANDROID_KEY \
      VOXGUARD_RELAY_TOKEN VOXGUARD_ALERT_RELAY_URL \
      VOXGUARD_RECORDING_TRANSCRIPTION_URL \
      ASSEMBLYAI_TOKEN_BROKER_URL VOXGUARD_SEMANTIC_PROXY_URL \
      ONESIGNAL_APP_ID; do
      if [ -n "${!name:-}" ]; then
        echo "  $name: set"
      else
        echo "  $name: missing"
      fi
    done
    echo "Relay-backed features need VOXGUARD_RELAY_TOKEN plus their URL var."
    ;;
  relay)
    echo "Starting local relay (wrangler dev) - secrets come from server/.dev.vars"
    (cd server && npx wrangler dev)
    ;;
  run)
    shift || true
    echo "Launching PauseSignal (${#DEFINES[@]} integration define(s) set)"
    flutter run --debug "${DEFINES[@]}" "$@"
    ;;
  apk)
    echo "Building judging APK (${#DEFINES[@]} integration define(s) set)"
    flutter build apk --debug "${DEFINES[@]}"
    echo "APK: build/app/outputs/flutter-apk/app-debug.apk"
    ;;
  *)
    echo "usage: $0 [run <flutter-run-args> | apk | relay | doctor]" >&2
    exit 2
    ;;
esac
