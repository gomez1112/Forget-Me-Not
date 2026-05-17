#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="${PROJECT_PATH:-$ROOT_DIR/Celmi.xcodeproj}"
SCHEME="${SCHEME:-Celmi}"
CONFIGURATION="${CONFIGURATION:-Debug}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-${TMPDIR:-/tmp}/Celmi-DerivedData}"
APP_NAME="${APP_NAME:-Celmi}"
BUNDLE_ID="${BUNDLE_ID:-com.transfinite.Celmi}"
IOS_SIMULATOR="${IOS_SIMULATOR:-iPhone 17 Pro}"
IPAD_SIMULATOR="${IPAD_SIMULATOR:-iPad Pro 13-inch (M5)}"
SIMULATOR_BOOT_TIMEOUT_SECONDS="${SIMULATOR_BOOT_TIMEOUT_SECONDS:-60}"
STOREKIT_CONFIGURATION_PATH="${STOREKIT_CONFIGURATION_PATH:-$ROOT_DIR/Celmi/StoreKit/Celmi.storekit}"
LEGACY_BUNDLE_IDENTIFIERS=("com.transfinite.Forget-Me-Not")

PLATFORM="ios"
MODE="run"
LAUNCH_ARGUMENTS=()

usage() {
    cat <<USAGE
usage: $0 [--macos|--ios|--ipad] [--build-only|--verify|--logs|--telemetry|--debug] [--paywall]

Defaults:
  platform      iOS Simulator
  scheme        $SCHEME
  configuration $CONFIGURATION
  StoreKit      $STOREKIT_CONFIGURATION_PATH

Environment overrides:
  PROJECT_PATH, SCHEME, CONFIGURATION, DERIVED_DATA_PATH, APP_NAME, BUNDLE_ID,
  IOS_SIMULATOR, IPAD_SIMULATOR, STOREKIT_CONFIGURATION_PATH
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --macos|macos)
            PLATFORM="macos"
            ;;
        --ios|ios)
            PLATFORM="ios"
            ;;
        --ipad|ipad)
            PLATFORM="ipad"
            ;;
        --build-only|build)
            MODE="build"
            ;;
        --verify|verify)
            MODE="verify"
            ;;
        --logs|logs)
            MODE="logs"
            ;;
        --telemetry|telemetry)
            MODE="telemetry"
            ;;
        --debug|debug)
            MODE="debug"
            ;;
        --paywall|paywall)
            LAUNCH_ARGUMENTS+=(--show-paywall)
            ;;
        --help|-h|help)
            usage
            exit 0
            ;;
        *)
            echo "unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

run_command() {
    printf '+'
    printf ' %q' "$@"
    printf '\n'
    "$@"
}

run_command_with_timeout() {
    local timeout_seconds="$1"
    shift

    printf '+'
    printf ' %q' "$@"
    printf ' # timeout=%ss\n' "$timeout_seconds"

    "$@" &
    local command_pid=$!

    (
        sleep "$timeout_seconds"
        kill "$command_pid" >/dev/null 2>&1 || true
    ) &
    local watchdog_pid=$!

    set +e
    wait "$command_pid"
    local status=$?
    set -e

    kill "$watchdog_pid" >/dev/null 2>&1 || true
    wait "$watchdog_pid" >/dev/null 2>&1 || true

    if [[ "$status" -eq 143 || "$status" -eq 137 ]]; then
        echo "command timed out after ${timeout_seconds}s" >&2
        return 124
    fi

    return "$status"
}

try_command_quietly() {
    printf '+'
    printf ' %q' "$@"
    printf '\n'
    "$@" >/dev/null 2>&1 || true
}

print_storekit_configuration() {
    if [[ -f "$STOREKIT_CONFIGURATION_PATH" ]]; then
        echo "StoreKit configuration: $STOREKIT_CONFIGURATION_PATH"
    else
        echo "StoreKit configuration not found: $STOREKIT_CONFIGURATION_PATH" >&2
    fi
}

xcodebuild_project() {
    if [[ "$MODE" == "build" ]]; then
        run_command xcodebuild \
            -project "$PROJECT_PATH" \
            -scheme "$SCHEME" \
            -configuration "$CONFIGURATION" \
            -derivedDataPath "$DERIVED_DATA_PATH" \
            "$@" \
            CODE_SIGNING_ALLOWED=NO
    else
        run_command xcodebuild \
            -project "$PROJECT_PATH" \
            -scheme "$SCHEME" \
            -configuration "$CONFIGURATION" \
            -derivedDataPath "$DERIVED_DATA_PATH" \
            "$@"
    fi
}

macos_app_path() {
    printf '%s/Build/Products/%s/%s.app\n' "$DERIVED_DATA_PATH" "$CONFIGURATION" "$APP_NAME"
}

open_macos_app() {
    local app_path="$1"

    if [[ "${#LAUNCH_ARGUMENTS[@]}" -gt 0 ]]; then
        run_command /usr/bin/open -n "$app_path" --args "${LAUNCH_ARGUMENTS[@]}"
    else
        run_command /usr/bin/open -n "$app_path"
    fi
}

launch_simulator_app() {
    local simulator_id="$1"

    if [[ "${#LAUNCH_ARGUMENTS[@]}" -gt 0 ]]; then
        run_command xcrun simctl launch "$simulator_id" "$BUNDLE_ID" --args "${LAUNCH_ARGUMENTS[@]}"
    else
        run_command xcrun simctl launch "$simulator_id" "$BUNDLE_ID"
    fi
}

uninstall_legacy_simulator_apps() {
    local simulator_id="$1"

    for legacy_bundle_id in "${LEGACY_BUNDLE_IDENTIFIERS[@]}"; do
        try_command_quietly xcrun simctl uninstall "$simulator_id" "$legacy_bundle_id"
    done
}

simulator_app_path() {
    printf '%s/Build/Products/%s-iphonesimulator/%s.app\n' "$DERIVED_DATA_PATH" "$CONFIGURATION" "$APP_NAME"
}

resolve_simulator_id() {
    local simulator_name="$1"

    /usr/bin/python3 - "$simulator_name" <<'PY'
import json
import subprocess
import sys

name = sys.argv[1]
payload = subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"])
data = json.loads(payload)

for devices in data.get("devices", {}).values():
    for device in devices:
        if device.get("name") == name and device.get("isAvailable", True):
            print(device["udid"])
            raise SystemExit(0)

print(f"No available simulator named {name!r}", file=sys.stderr)
raise SystemExit(1)
PY
}

simulator_state() {
    local simulator_id="$1"

    /usr/bin/python3 - "$simulator_id" <<'PY'
import json
import subprocess
import sys

udid = sys.argv[1]
payload = subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"])
data = json.loads(payload)

for devices in data.get("devices", {}).values():
    for device in devices:
        if device.get("udid") == udid:
            print(device.get("state", "Unknown"))
            raise SystemExit(0)

print("Unknown")
PY
}

launch_macos() {
    local app_path
    app_path="$(macos_app_path)"

    if [[ ! -d "$app_path" ]]; then
        echo "built app not found: $app_path" >&2
        exit 1
    fi

    pkill -x "$APP_NAME" >/dev/null 2>&1 || true

    case "$MODE" in
        build)
            ;;
        debug)
            run_command lldb -- "$app_path/Contents/MacOS/$APP_NAME"
            ;;
        logs)
            open_macos_app "$app_path"
            run_command /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
            ;;
        telemetry)
            open_macos_app "$app_path"
            run_command /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\" || process == \"$APP_NAME\""
            ;;
        verify)
            open_macos_app "$app_path"
            sleep 2
            run_command pgrep -x "$APP_NAME"
            ;;
        run)
            open_macos_app "$app_path"
            ;;
    esac
}

launch_simulator() {
    local simulator_name="$1"
    local simulator_id
    local app_path

    simulator_id="$(resolve_simulator_id "$simulator_name")"
    app_path="$(simulator_app_path)"

    if [[ ! -d "$app_path" ]]; then
        echo "built app not found: $app_path" >&2
        exit 1
    fi

    if [[ "$MODE" == "build" ]]; then
        return
    fi

    if [[ "$(simulator_state "$simulator_id")" != "Booted" ]]; then
        run_command xcrun simctl boot "$simulator_id"
    fi

    run_command_with_timeout "$SIMULATOR_BOOT_TIMEOUT_SECONDS" xcrun simctl bootstatus "$simulator_id" -b
    try_command_quietly xcrun simctl terminate "$simulator_id" "$BUNDLE_ID"
    uninstall_legacy_simulator_apps "$simulator_id"
    run_command xcrun simctl install "$simulator_id" "$app_path"

    case "$MODE" in
        build)
            ;;
        debug)
            echo "--debug is only wired for macOS. Launching the simulator app normally." >&2
            launch_simulator_app "$simulator_id"
            ;;
        logs|telemetry)
            launch_simulator_app "$simulator_id"
            run_command xcrun simctl spawn "$simulator_id" log stream --info --style compact --predicate "process == \"$APP_NAME\""
            ;;
        verify|run)
            launch_simulator_app "$simulator_id"
            ;;
    esac
}

print_storekit_configuration

case "$PLATFORM" in
    macos)
        xcodebuild_project -destination "platform=macOS" build
        launch_macos
        ;;
    ios)
        xcodebuild_project -destination "platform=iOS Simulator,name=$IOS_SIMULATOR" build
        launch_simulator "$IOS_SIMULATOR"
        ;;
    ipad)
        xcodebuild_project -destination "platform=iOS Simulator,name=$IPAD_SIMULATOR" build
        launch_simulator "$IPAD_SIMULATOR"
        ;;
esac
