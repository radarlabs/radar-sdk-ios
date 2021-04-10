SDK ?= "iphonesimulator"
DESTINATION ?= "platform=iOS Simulator,name=iPhone 11"
PROJECT := RadarSDK
PROJECT_EXAMPLE := Example/Example
SCHEME := XCFramework
SCHEME_TEST := RadarSDKTests
SCHEME_EXAMPLE := Example
XC_ARGS := -sdk $(SDK) -project $(PROJECT).xcodeproj -scheme $(SCHEME) -destination $(DESTINATION) ONLY_ACTIVE_ARCH=NO OTHER_CFLAGS="-fembed-bitcode"
XC_TEST_ARGS := -sdk $(SDK) -project $(PROJECT).xcodeproj -scheme $(SCHEME_TEST) -destination $(DESTINATION) GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES
XC_EXAMPLE_ARGS := -sdk $(SDK) -project $(PROJECT_EXAMPLE).xcodeproj -scheme $(SCHEME_EXAMPLE) -destination $(DESTINATION) ONLY_ACTIVE_ARCH=NO OTHER_CFLAGS="-fembed-bitcode"

bootstrap:
	./bootstrap.sh

clean:
	xcodebuild $(XC_ARGS) clean

build:
	xcodebuild $(XC_ARGS) $(XC_BUILD_ARGS)

test:
	xcodebuild test $(XC_TEST_ARGS)

build-example:
	xcodebuild $(XC_EXAMPLE_ARGS) $(XC_BUILD_ARGS)

lint:
	pod lib lint --verbose

format:
	./clang_format.sh

clean-pretty:
	set -o pipefail && xcodebuild $(XC_ARGS) clean | xcpretty

build-pretty:
	set -o pipefail && xcodebuild $(XC_ARGS) $(XC_BUILD_ARGS) | xcpretty

test-pretty:
	set -o pipefail && xcodebuild test $(XC_TEST_ARGS) | xcpretty --report junit

build-example-pretty:
	set -o pipefail && xcodebuild $(XC_EXAMPLE_ARGS) $(XC_BUILD_ARGS) | xcpretty

docs:
	jazzy

dist: clean-pretty format test-pretty build-pretty docs lint

.PHONY: bootstrap clean test build lint format docs dist
