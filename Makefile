SDK ?= "iphonesimulator"
DESTINATION ?= "platform=iOS Simulator,name=iPhone 11"
PROJECT := RadarSDK
SCHEME := Framework
XC_ARGS := -project $(PROJECT).xcodeproj -scheme $(SCHEME) -destination $(DESTINATION)
XC_BUILD_ARGS := ONLY_ACTIVE_ARCH=NO OTHER_CFLAGS="-fembed-bitcode"
XC_TEST_ARGS := GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES

bootstrap: ## download & install deps
	./bootstrap.sh

clean: ## clean
	xcodebuild $(XC_ARGS) clean

test: ## run all tests
	xcodebuild test $(XC_ARGS)

build: ## build module
	xcodebuild $(XC_ARGS) $(XC_BUILD_ARGS)

lint: ## lint all code in repo
	pod lib lint --verbose

format: ## format all code (.m's and .h's) in repo
	./clang_format.sh

clean-pretty: ## clean + format xcode output
	set -o pipefail && xcodebuild $(XC_ARGS) clean | xcpretty

test-pretty: ## test + format xcode output
	set -o pipefail && xcodebuild test $(XC_ARGS) $(XC_TEST_ARGS) | xcpretty --report junit

build-pretty: ## build + format xcode output
	set -o pipefail && xcodebuild $(XC_ARGS) $(XC_BUILD_ARGS) | xcpretty

docs: ## build docs
	jazzy

dist: clean-pretty format test-pretty build-pretty docs lint

# taken from https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: bootstrap clean test build lint format docs dist list
