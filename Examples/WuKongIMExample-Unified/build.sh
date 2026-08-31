#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PRODUCT_NAME="WuKongIMExample-Unified"
readonly BUNDLE_ID="com.wukongim.easysdk.example"
readonly DERIVED_DATA_PATH="${SCRIPT_DIR}/.build/xcode"
readonly IOS_PRODUCTS_DIR="${DERIVED_DATA_PATH}/Build/Products/Debug-iphonesimulator"
readonly IOS_APP_DIR="${SCRIPT_DIR}/.build/ios-simulator/${PRODUCT_NAME}.app"

show_usage() {
    cat <<'USAGE'
Usage: ./build.sh <ios|macos> [--run]

  ios      Build an installable iOS Simulator app bundle.
  macos    Build the macOS Swift Package executable.
  --run    Run after building. A simulator must already be booted for iOS.

Environment variables:
  IOS_DESTINATION  xcodebuild destination (default: generic/platform=iOS Simulator)
  SIMULATOR_ID     Booted simulator UDID or "booted" (default: booted)
USAGE
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
    show_usage
    exit 1
fi

readonly PLATFORM="$1"
readonly RUN_APP="${2:-}"

if [[ -n "${RUN_APP}" && "${RUN_APP}" != "--run" ]]; then
    show_usage
    exit 1
fi

build_ios() {
    local destination="${IOS_DESTINATION:-generic/platform=iOS Simulator}"
    local executable="${IOS_PRODUCTS_DIR}/${PRODUCT_NAME}"

    (
        cd "${SCRIPT_DIR}"
        xcodebuild \
            -quiet \
            -scheme "${PRODUCT_NAME}" \
            -destination "${destination}" \
            -derivedDataPath "${DERIVED_DATA_PATH}" \
            CODE_SIGNING_ALLOWED=NO \
            build
    )

    if [[ ! -x "${executable}" ]]; then
        echo "Expected iOS executable was not produced: ${executable}" >&2
        exit 1
    fi

    rm -rf "${IOS_APP_DIR}"
    mkdir -p "${IOS_APP_DIR}"
    cp "${executable}" "${IOS_APP_DIR}/${PRODUCT_NAME}"
    cp "${SCRIPT_DIR}/Shared/iOS-Info.plist" "${IOS_APP_DIR}/Info.plist"

    /usr/libexec/PlistBuddy -c "Set :CFBundleDevelopmentRegion en" "${IOS_APP_DIR}/Info.plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleExecutable ${PRODUCT_NAME}" "${IOS_APP_DIR}/Info.plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier ${BUNDLE_ID}" "${IOS_APP_DIR}/Info.plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleName ${PRODUCT_NAME}" "${IOS_APP_DIR}/Info.plist"
    /usr/libexec/PlistBuddy -c "Add :MinimumOSVersion string 15.0" "${IOS_APP_DIR}/Info.plist"
    /usr/libexec/PlistBuddy -c "Add :UIDeviceFamily array" "${IOS_APP_DIR}/Info.plist"
    /usr/libexec/PlistBuddy -c "Add :UIDeviceFamily:0 integer 1" "${IOS_APP_DIR}/Info.plist"
    /usr/libexec/PlistBuddy -c "Add :UIDeviceFamily:1 integer 2" "${IOS_APP_DIR}/Info.plist"

    find "${IOS_PRODUCTS_DIR}" -maxdepth 1 -type d -name '*.bundle' \
        -exec cp -R '{}' "${IOS_APP_DIR}/" ';'

    codesign --force --sign - "${IOS_APP_DIR}"
    echo "Built iOS Simulator app: ${IOS_APP_DIR}"

    if [[ "${RUN_APP}" == "--run" ]]; then
        local simulator_id="${SIMULATOR_ID:-booted}"
        if [[ "${simulator_id}" == "booted" ]] && ! xcrun simctl list devices | grep -q '(Booted)'; then
            echo "No iOS Simulator is booted. Boot one or set SIMULATOR_ID to its UDID." >&2
            exit 1
        fi
        xcrun simctl install "${simulator_id}" "${IOS_APP_DIR}"
        xcrun simctl launch "${simulator_id}" "${BUNDLE_ID}"
    fi
}

build_macos() {
    swift build --package-path "${SCRIPT_DIR}"
    if [[ "${RUN_APP}" == "--run" ]]; then
        swift run --package-path "${SCRIPT_DIR}" "${PRODUCT_NAME}"
    fi
}

case "${PLATFORM}" in
    ios) build_ios ;;
    macos) build_macos ;;
    *)
        show_usage
        exit 1
        ;;
esac
