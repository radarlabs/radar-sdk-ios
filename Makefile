SDK ?= "iphonesimulator"
DESTINATION ?= "platform=iOS Simulator,name=iPhone 17,OS=26.4.1"
PROJECT := RadarSDK
PROJECT_EXAMPLE := Example/Example
SCHEME := XCFramework
SCHEME_EXAMPLE := Example
XC_ARGS := -sdk $(SDK) -project $(PROJECT).xcodeproj -scheme $(SCHEME) -destination $(DESTINATION) ONLY_ACTIVE_ARCH=NO OTHER_CFLAGS="-fembed-bitcode"
XC_TEST_ARGS := $(XC_ARGS) GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES
EXAMPLE_BUILD_DIR := Example/build
XC_EXAMPLE_ARGS := -sdk $(SDK) -project $(PROJECT_EXAMPLE).xcodeproj -scheme $(SCHEME_EXAMPLE) -destination $(DESTINATION) BUILD_DIR=$(EXAMPLE_BUILD_DIR) SYMROOT=$(EXAMPLE_BUILD_DIR)

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
	xcodebuild $(XC_EXAMPLE_ARGS) -jobs 1

run-example: build-example
	xcrun simctl boot "iPhone 17" 2>/dev/null || true
	open -a Simulator
	xcrun simctl install booted Example/build/Debug-iphonesimulator/Example.app
	xcrun simctl launch --console booted io.radar.iosexample

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
	set -o pipefail && xcodebuild $(XC_TEST_ARGS) test -skip-testing:RadarSDKTests/InAppMessageTest -skip-testing:RadarSDKTests/RadarSettingsTest -skip-testing:RadarSDKTests/RadarNotificationHelperTest | xcpretty --report junit

test-swift:
	xcodebuild $(XC_TEST_ARGS) test -only-testing:RadarSDKTests/InAppMessageTest -only-testing:RadarSDKTests/RadarSettingsTest -only-testing:RadarSDKTests/RadarNotificationHelperTest

build-example-pretty:
	set -o pipefail && xcodebuild $(XC_EXAMPLE_ARGS) | xcpretty

docs:
	jazzy

dist: clean-pretty test-pretty build-pretty lint docs

.PHONY: bootstrap clean test build lint format docs dist run-example
