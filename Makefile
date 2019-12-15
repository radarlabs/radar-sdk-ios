SDK ?= "iphonesimulator"
DESTINATION ?= "platform=iOS Simulator,name=iPhone 11"
PROJECT := RadarSDK
SCHEME := Framework
XC_ARGS := -project $(PROJECT).xcodeproj -scheme $(SCHEME) -destination $(DESTINATION)
XC_BUILD_ARGS := ONLY_ACTIVE_ARCH=NO OTHER_CFLAGS="-fembed-bitcode"
XC_TEST_ARGS := GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES

bootstrap:
	./bootstrap.sh

clean:
	xcodebuild $(XC_ARGS) clean

test:
	xcodebuild test $(XC_ARGS)

build:
	xcodebuild $(XC_ARGS) $(XC_BUILD_ARGS)

lint:
	pod lib lint --verbose

clean-pretty:
	set -o pipefail && xcodebuild $(XC_ARGS) clean | xcpretty

test-pretty:
	set -o pipefail && xcodebuild test $(XC_ARGS) $(XC_TEST_ARGS) | xcpretty --report junit

build-pretty:
	set -o pipefail && xcodebuild $(XC_ARGS) $(XC_BUILD_ARGS) | xcpretty

docs:
	jazzy

dist: clean-pretty test-pretty build-pretty docs lint

.PHONY: bootstrap clean test build lint docs dist
