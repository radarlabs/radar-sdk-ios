SDK ?= "iphonesimulator"
DESTINATION ?= "platform=iOS Simulator,name=iPhone 15"
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

build-example:
	xcodebuild $(XC_EXAMPLE_ARGS)

lint:
	pod lib lint --verbose

format:
	./clang_format.sh

clean-pretty:
	set -o pipefail && xcodebuild $(XC_ARGS) clean | xcpretty

build-pretty:
	set -o pipefail && xcodebuild $(XC_ARGS) | xcpretty

test-pretty:
	set -o pipefail && xcodebuild test $(XC_TEST_ARGS) | xcpretty --report junit

build-example-pretty:
	set -o pipefail && xcodebuild $(XC_EXAMPLE_ARGS) | xcpretty

docs:
	jazzy

dist: clean-pretty test-pretty build-pretty lint docs

.PHONY: bootstrap clean test build lint format docs dist
