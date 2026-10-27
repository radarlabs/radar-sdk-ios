#!/bin/bash
#
# Fails if the SDK's compiled code contains Swift "async-import thunks".
#
# WHAT THIS CATCHES
#   Writing `await` on an Objective-C callback API, for example
#       let settings = await UNUserNotificationCenter.current().notificationSettings()
#   makes the compiler add a hidden helper function (a "thunk") that turns the callback into an
#   async result. The thunk is a shared symbol: when an app links several libraries statically, the
#   linker keeps one copy for the whole app. Swift 6.2.x gives the Swift 5 and Swift 6 versions of a
#   thunk the same name even though their code differs. So if a customer's app has another library
#   that awaits the same API in the other language mode, one library runs the other's thunk and the
#   app crashes. See https://github.com/radarlabs/radar-sdk-ios/pull/759.
#
#   You can't see this in Swift source: the thunk is also generated when a protocol method we
#   declare happens to match an Apple async API's name. So this script checks the compiled object
#   files instead.
#
# HOW TO FIX A FAILURE
#   Call the completion-handler version of the API inside a continuation instead of awaiting the
#   async version. If a protocol method matches the API's name, rename the protocol method too.
#   See the UNUserNotificationCenter extension in RadarSDK/RadarNotificationHelper.swift:
#       await withCheckedContinuation { continuation in
#           getNotificationSettings { settings in continuation.resume(returning: settings) }
#       }
#
# HOW IT WORKS
#   1. Self-test: compile a tiny file that awaits an Objective-C callback API in Swift 5 and Swift 6
#      mode, and make sure the pattern below flags both. If a future Swift renames these thunks,
#      this step fails, and the pattern needs updating, instead of the check silently passing.
#   2. List the function symbols in every SDK object file with `nm` and fail on any thunk.
#
#   Thunk symbols are Swift-mangled names that contain `Iey` (the Objective-C block calling
#   convention) and end in `Tz_` (unchecked continuation) or `TZ_` (checked continuation). Run
#   `xcrun swift-demangle` on a symbol to read it, e.g. "@objc completion handler block
#   implementation for ... UNNotificationSettings".
#
# USAGE
#   ./check-async-thunks.sh <DerivedData path>
#   It reads the objects from an earlier build, normally `make ci-build-example`
#   (run it as `make check-async-thunks`).

set -euo pipefail

derived_data="${1:?usage: $0 <DerivedData path>}"
intermediates="$derived_data/Build/Intermediates.noindex"
modules=(RadarSDK RadarSDKMotion RadarSDKFraud)
thunk_pattern='_\$s[^ ]*Iey[^ ]*T[zZ]_$'

# Prints "<file> <symbol>" for each thunk defined in the given object files.
find_thunks() {
    for object in "$@"; do
        nm -m "$object" \
            | grep '(__TEXT,__text)' \
            | grep -oE "$thunk_pattern" \
            | sed "s|^|$(basename "$object") |" \
            || true
    done
}

# 1. Self-test
selftest_dir="$(mktemp -d)"
trap 'rm -rf "$selftest_dir"' EXIT
cat > "$selftest_dir/known_bad.swift" <<'EOF'
import UserNotifications
public func knownBad(_ center: UNUserNotificationCenter) async -> UNNotificationSettings {
    await center.notificationSettings()
}
EOF
sdk_path="$(xcrun --sdk iphonesimulator --show-sdk-path)"
for swift_version in 5 6; do
    object="$selftest_dir/known_bad_swift$swift_version.o"
    xcrun swiftc -c -parse-as-library -swift-version "$swift_version" \
        -target "$(uname -m)-apple-ios15.0-simulator" -sdk "$sdk_path" \
        "$selftest_dir/known_bad.swift" -o "$object"
    if [ -z "$(find_thunks "$object")" ]; then
        echo "::error::Self-test failed: the thunk pattern no longer matches what this Swift (Swift $swift_version mode) generates for 'await center.notificationSettings()'."
        echo "Symbols in the known-bad object that look like completion-handler thunks:"
        nm -m "$object" | grep '(__TEXT,__text)' | grep 'Iey' || echo "  (none)"
        echo "Update thunk_pattern in $0 to match, and keep the self-test passing."
        exit 1
    fi
done
echo "Self-test passed: the pattern flags known-bad code in Swift 5 and Swift 6 mode"

# 2. Scan the SDK
objects=()
for module in "${modules[@]}"; do
    module_objects=()
    while IFS= read -r object; do
        module_objects+=("$object")
    done < <(find "$intermediates/$module.build" -name '*.o' 2>/dev/null)
    if [ ${#module_objects[@]} -eq 0 ]; then
        echo "::error::No $module object files under $intermediates. Run 'make ci-build-example' first."
        exit 1
    fi
    objects+=("${module_objects[@]}")
done

thunks="$(find_thunks "${objects[@]}" | sort -u)"
echo "Checked ${#objects[@]} object files in ${modules[*]}"
if [ -n "$thunks" ]; then
    echo "::error::Found async-import thunks. Use the completion-handler API inside withChecked(Throwing)Continuation instead (see the header of $0):"
    while read -r file symbol; do
        echo "  $file: $(xcrun swift-demangle --compact "${symbol#_}")"
    done <<< "$thunks"
    exit 1
fi
echo "No async-import thunks found"
