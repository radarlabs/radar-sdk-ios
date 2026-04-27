SDK ?= "iphonesimulator"
DESTINATION ?= "platform=iOS Simulator,name=iPhone 17,OS=26.4.1"
PROJECT := RadarSDK
PROJECT_EXAMPLE := Example/Example
SCHEME := XCFramework
SCHEME_EXAMPLE := Example
XC_ARGS := -sdk $(SDK) -project $(PROJECT).xcodeproj -scheme $(SCHEME) -destination $(DESTINATION) ONLY_ACTIVE_ARCH=NO OTHER_CFLAGS="-fembed-bitcode"
XC_TEST_ARGS := $(XC_ARGS) GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES
XC_EXAMPLE_ARGS := -sdk $(SDK) -project $(PROJECT_EXAMPLE).xcodeproj -scheme $(SCHEME_EXAMPLE) -destination $(DESTINATION) ONLY_ACTIVE_ARCH=NO OTHER_CFLAGS="-fembed-bitcode"

bootstrap:
	./bootstrap.sh

clean:
	xcodebuild $(XC_ARGS) clean

build:
	xcodebuild $(XC_ARGS)

test:
	xcodebuild $(XC_TEST_ARGS) test

test-swift:
	xcodebuild $(XC_TEST_ARGS) test -only-testing:RadarSDKTests/InAppMessageTest

build-example:
	xcodebuild $(XC_EXAMPLE_ARGS)

lint:
	@for spec in *.podspec; do \
		if [ "$$spec" != "RadarSDKIndoors.podspec" ]; then \
			pod lib lint "$$spec" || exit 1; \
		fi; \
	done 

format:
	./clang_format.sh

clean-pretty:
	set -o pipefail && xcodebuild $(XC_ARGS) clean | xcpretty

build-pretty:
	set -o pipefail && xcodebuild $(XC_ARGS) | xcpretty

test-pretty:
	@set -o pipefail; \
	  xcodebuild $(XC_TEST_ARGS) test -skip-testing:RadarSDKTests/InAppMessageTest -skip-testing:RadarSDKTests/RadarSettingsTest -skip-testing:RadarSDKTests/RadarNotificationHelperTest 2>&1 \
	    | tee /tmp/radar-sdk-ios-test.log \
	    | xcpretty --report junit; \
	  status=$$?; \
	  if [ $$status -ne 0 ]; then \
	    echo ""; \
	    echo "=== Swift Testing issues (hidden by xcpretty) ==="; \
	    grep -E "^(Testing failed:|.*✘ Test |.*recorded an issue|.* failed after .* with [0-9]+ issue|Crash: )" /tmp/radar-sdk-ios-test.log || echo "(no Swift Testing failure markers found — see /tmp/radar-sdk-ios-test.log)"; \
	  fi; \
	  exit $$status

test-swift:
	xcodebuild $(XC_TEST_ARGS) test -only-testing:RadarSDKTests/InAppMessageTest -only-testing:RadarSDKTests/RadarSettingsTest -only-testing:RadarSDKTests/RadarNotificationHelperTest

build-example-pretty:
	set -o pipefail && xcodebuild $(XC_EXAMPLE_ARGS) | xcpretty

docs:
	jazzy

dist: clean-pretty test-pretty build-pretty lint docs

.PHONY: bootstrap clean test build lint format docs dist
