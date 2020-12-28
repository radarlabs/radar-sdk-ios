SDK ?= "iphonesimulator"
DESTINATION ?= "platform=iOS Simulator,name=iPhone 11"
PROJECT := RadarSDK
SCHEME := Framework
XC_ARGS := -sdk $(SDK) -project $(PROJECT).xcodeproj -scheme $(SCHEME) -destination $(DESTINATION)
XC_BUILD_ARGS := ONLY_ACTIVE_ARCH=NO OTHER_CFLAGS="-fembed-bitcode"
XC_TEST_ARGS := GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES
PROJECT_EXAMPLE := Example/Example
SCHEME_EXAMPLE := Example
XC_EXAMPLE_ARGS := -sdk $(SDK) -project $(PROJECT_EXAMPLE).xcodeproj -scheme $(SCHEME_EXAMPLE) -destination $(DESTINATION)

bootstrap:
	./bootstrap.sh

clean:
	xcodebuild $(XC_ARGS) clean

test:
	xcodebuild test $(XC_ARGS)

build:
	xcodebuild $(XC_ARGS) $(XC_BUILD_ARGS)

build-example:
	xcodebuild $(XC_EXAMPLE_ARGS) $(XC_BUILD_ARGS)

lint:
	pod lib lint --verbose

format:
	./clang_format.sh

clean-pretty:
	set -o pipefail && xcodebuild $(XC_ARGS) clean | xcpretty

test-pretty:
	set -o pipefail && xcodebuild test $(XC_ARGS) $(XC_TEST_ARGS) | xcpretty --report junit

build-pretty:
	set -o pipefail && xcodebuild $(XC_ARGS) $(XC_BUILD_ARGS) | xcpretty

build-example-pretty:
	set -o pipefail && xcodebuild $(XC_EXAMPLE_ARGS) $(XC_BUILD_ARGS) | xcpretty

docs:
	jazzy

dist: clean-pretty format test-pretty build-pretty docs lint

.PHONY: bootstrap clean test build lint format docs dist
