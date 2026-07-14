SDK ?= "iphonesimulator"
DESTINATION ?= "platform=iOS Simulator,name=iPhone 17,OS=26.4.1"
PROJECT := RadarSDK
PROJECT_EXAMPLE := Example/Example
SCHEME := XCFramework
SCHEME_EXAMPLE := Example
SWIFTLINT := $(firstword $(wildcard .tools/swiftlint) swiftlint)
XC_ARGS := -sdk $(SDK) -project $(PROJECT).xcodeproj -scheme $(SCHEME) -destination $(DESTINATION) ONLY_ACTIVE_ARCH=NO OTHER_CFLAGS="-fembed-bitcode"
XC_TEST_ARGS := $(XC_ARGS) GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES
# The example app links MapLibre (swiftui-dsl), which needs two accommodations in a
# non-interactive build:
#   -skipMacroValidation      skips the one-time MapLibreSwiftMacros trust prompt.
XC_EXAMPLE_ARGS := -project $(PROJECT_EXAMPLE).xcodeproj -scheme $(SCHEME_EXAMPLE) -destination $(DESTINATION) -skipMacroValidation ONLY_ACTIVE_ARCH=NO OTHER_CFLAGS="-fembed-bitcode"
CI_SCHEME ?= RadarSDK
CI_WORKSPACE ?= Example/Example.xcodeproj/project.xcworkspace
CI_DESTINATION ?= platform=iOS Simulator,name=iPhone 17,OS=26.4.1
CI_XC_ARGS := -scheme $(CI_SCHEME) -workspace $(CI_WORKSPACE) -destination "$(CI_DESTINATION)"
CI_TEST_LOG ?= /tmp/radar-sdk-ios-ci-test.log
CI_SWIFT_TEST_LOG ?= /tmp/radar-sdk-ios-ci-swift-test.log

bootstrap:
	./bootstrap.sh

clean:
	xcodebuild $(XC_ARGS) clean

build:
	xcodebuild $(XC_ARGS)

test:
	xcodebuild $(XC_TEST_ARGS) test

build-example:
	xcodebuild $(XC_EXAMPLE_ARGS)

# Allow warnings for deprecated Beacons API calls in RadarSDK.podspec.
# TODO: update deprecated Beacons API calls and remove --allow-warnings.
lint:
	@for spec in *.podspec; do \
		if [ "$$spec" != "RadarSDKIndoors.podspec" ]; then \
			pod lib lint "$$spec" --allow-warnings || exit 1; \
		fi; \
	done

FORMAT_BASE ?= origin/master

lint-swift:
	@if ! command -v $(SWIFTLINT) >/dev/null 2>&1 && [ ! -f "$(SWIFTLINT)" ]; then \
		echo "swiftlint not installed; run 'make bootstrap'"; \
		exit 1; \
	fi
	@SWIFT_FILES=$$(git diff --diff-filter=ACM --name-only $(FORMAT_BASE)...HEAD -- '*.swift' 2>/dev/null); \
	if [ -z "$$SWIFT_FILES" ]; then \
		echo "No Swift files changed; skipping lint."; \
		exit 0; \
	fi; \
	echo "Linting changed Swift files:"; \
	echo "$$SWIFT_FILES" | tr '\n' ' '; echo; \
	echo "$$SWIFT_FILES" | xargs $(SWIFTLINT) lint --strict --baseline .swiftlint-baseline.json

lint-swift-fix:
	@if ! command -v $(SWIFTLINT) >/dev/null 2>&1 && [ ! -f "$(SWIFTLINT)" ]; then \
		echo "swiftlint not installed; run 'make bootstrap'"; \
		exit 1; \
	fi
	@SWIFT_FILES=$$(git diff --diff-filter=ACM --name-only $(FORMAT_BASE)...HEAD -- '*.swift' 2>/dev/null); \
	if [ -z "$$SWIFT_FILES" ]; then \
		echo "No Swift files changed; skipping lint."; \
		exit 0; \
	fi; \
	echo "Fixing lint in changed Swift files:"; \
	echo "$$SWIFT_FILES" | tr '\n' ' '; echo; \
	echo "$$SWIFT_FILES" | xargs $(SWIFTLINT) lint --strict --fix --baseline .swiftlint-baseline.json

# CI passes the changed Swift files explicitly via FORMAT_FILES (from `gh pr diff`).
# When it is empty (local use), fall back to diffing against FORMAT_BASE.
format-check:
	@if ! command -v swift-format >/dev/null; then \
		echo "swift-format not installed; run 'make bootstrap' or 'brew install swift-format'"; \
		exit 1; \
	fi
	@SWIFT_FILES="$(FORMAT_FILES)"; \
	if [ -z "$$SWIFT_FILES" ]; then \
		SWIFT_FILES=$$(git diff --diff-filter=ACM --name-only $(FORMAT_BASE)...HEAD -- '*.swift' 2>/dev/null); \
	fi; \
	if [ -z "$$SWIFT_FILES" ]; then \
		echo "No Swift files changed; skipping format check."; \
		exit 0; \
	fi; \
	echo "Checking format of changed Swift files:"; \
	echo "$$SWIFT_FILES" | tr '\n' ' '; echo; \
	echo "$$SWIFT_FILES" | xargs swift-format format -i --parallel; \
	git diff --exit-code -- $$SWIFT_FILES

format:
	./clang_format.sh
	swift-format format -i -r --parallel RadarSDK RadarSDKTests

clean-pretty:
	set -o pipefail && xcodebuild $(XC_ARGS) clean | xcpretty

build-pretty:
	set -o pipefail && xcodebuild $(XC_ARGS) | xcpretty

ci-build-analyze:
	@set -o pipefail; \
	  xcodebuild clean build analyze $(CI_XC_ARGS) 2>&1 \
	    | tee /tmp/radar-sdk-ios-ci-build-analyze.log \
	    | xcpretty; \
	  exit $$?

test-pretty:
	@set -o pipefail; \
	  xcodebuild $(XC_TEST_ARGS) test -skip-testing:RadarSDKTests/InAppMessageTest -skip-testing:RadarSDKTests/RadarSettingsTest -skip-testing:RadarSDKTests/RadarNotificationHelperTest -skip-testing:RadarSDKTests/RadarRevealRiskTests 2>&1 \
	    | tee /tmp/radar-sdk-ios-test.log \
	    | xcpretty --report junit; \
	  status=$$?; \
	  if [ $$status -ne 0 ]; then \
	    echo ""; \
	    echo "=== Swift Testing issues (hidden by xcpretty) ==="; \
	    grep -E "^(Testing failed:|.*✘ Test |.*recorded an issue|.* failed after .* with [0-9]+ issue|Crash: )" /tmp/radar-sdk-ios-test.log || echo "(no Swift Testing failure markers found — see /tmp/radar-sdk-ios-test.log)"; \
	  fi; \
	  exit $$status

ci-test-pretty:
	@set -o pipefail; \
	  xcodebuild test $(CI_XC_ARGS) -skip-testing:RadarSDKTests/InAppMessageTest -skip-testing:RadarSDKTests/RadarSettingsTest -skip-testing:RadarSDKTests/RadarNotificationHelperTest -skip-testing:RadarSDKTests/RadarRevealRiskTests 2>&1 \
	    | tee $(CI_TEST_LOG) \
	    | xcpretty --report junit; \
	  status=$$?; \
	  if [ $$status -ne 0 ]; then \
	    echo ""; \
	    echo "=== Swift Testing issues (hidden by xcpretty) ==="; \
	    grep -E "^(Testing failed:|.*✘ Test |.*recorded an issue|.* failed after .* with [0-9]+ issue|Crash: )" $(CI_TEST_LOG) || echo "(no Swift Testing failure markers found — see $(CI_TEST_LOG))"; \
	  fi; \
	  exit $$status

test-swift:
	xcodebuild $(XC_TEST_ARGS) test -only-testing:RadarSDKTests/InAppMessageTest -only-testing:RadarSDKTests/RadarSettingsTest -only-testing:RadarSDKTests/RadarNotificationHelperTest -only-testing:RadarSDKTests/RadarRevealRiskTests

ci-test-swift:
	@set -o pipefail; \
	  xcodebuild test $(CI_XC_ARGS) -only-testing:RadarSDKTests/InAppMessageTest -only-testing:RadarSDKTests/RadarSettingsTest -only-testing:RadarSDKTests/RadarNotificationHelperTest -only-testing:RadarSDKTests/RadarRevealRiskTests 2>&1 \
	    | tee $(CI_SWIFT_TEST_LOG); \
	  exit $$?

build-example-pretty:
	set -o pipefail && xcodebuild $(XC_EXAMPLE_ARGS) | xcpretty

ci-build-example:
	@set -o pipefail; \
	  xcodebuild -project $(PROJECT_EXAMPLE).xcodeproj -scheme $(SCHEME_EXAMPLE) -destination "$(CI_DESTINATION)" -skipMacroValidation ONLY_ACTIVE_ARCH=NO OTHER_CFLAGS="-fembed-bitcode" 2>&1 \
	    | tee /tmp/radar-sdk-ios-ci-build-example.log \
	    | xcpretty; \
	  exit $$?

docs:
	jazzy

dist: clean-pretty test-pretty build-pretty lint docs

.PHONY: bootstrap clean test build lint lint-swift format format-check ci-build-analyze ci-build-example ci-test-pretty ci-test-swift docs dist
