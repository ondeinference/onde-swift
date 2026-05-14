SHELL := /bin/sh

SWIFT_REPO := $(CURDIR)
ONDE_REPO ?= $(abspath ../onde)
CARGO_MANIFEST := $(ONDE_REPO)/Cargo.toml
BINDGEN_MANIFEST := $(ONDE_REPO)/uniffi-bindgen/Cargo.toml
BINDGEN := $(ONDE_REPO)/uniffi-bindgen/target/release/uniffi-bindgen

RUST_STABLE ?= +1.92.0
RUST_NIGHTLY ?= +nightly

IOS_DEPLOYMENT_TARGET ?= 16.0
MACOS_DEPLOYMENT_TARGET ?= 14.0
TVOS_DEPLOYMENT_TARGET ?= 16.0
VISIONOS_DEPLOYMENT_TARGET ?= 1.0
WATCHOS_DEPLOYMENT_TARGET ?= 9.0

LOCAL_DIR := $(SWIFT_REPO)/.local
GENERATED_DIR := $(LOCAL_DIR)/generated/Onde
HEADERS_DIR := $(LOCAL_DIR)/Headers
FRAMEWORK_DIR := $(SWIFT_REPO)/OndeFramework.xcframework
SWIFT_GLUE := $(SWIFT_REPO)/Sources/Onde/onde.swift

SUPPORTED_PLATFORMS := ios macos tvos visionos watchos

.PHONY: help platform ios macos tvos visionos watchos validate build-bindgen prepare generate-swift clean

help:
	@printf '%s\n' \
	  'Onde Swift local Apple-platform builds' \
	  '' \
	  'Usage:' \
	  '  make ios        Build OndeFramework.xcframework for iOS device + simulator' \
	  '  make macos      Build OndeFramework.xcframework for macOS (Apple silicon)' \
	  '  make tvos       Build OndeFramework.xcframework for tvOS device + simulator' \
	  '  make visionos   Build OndeFramework.xcframework for visionOS device + simulator' \
	  '  make watchos    Build OndeFramework.xcframework for watchOS device + simulator' \
	  '  make platform PLATFORM=ios' \
	  '' \
	  'Artifacts:' \
	  '  OndeFramework.xcframework' \
	  '  Sources/Onde/onde.swift (regenerated from the local Rust build)' \
	  '' \
	  'Optional overrides:' \
	  '  ONDE_REPO=/absolute/path/to/onde'

platform:
	@test -n "$(PLATFORM)" || { echo "Set PLATFORM=$(SUPPORTED_PLATFORMS)"; exit 1; }
	@case "$(PLATFORM)" in \
	  ios|macos|tvos|visionos|watchos) $(MAKE) "$(PLATFORM)" ;; \
	  *) echo "Unsupported PLATFORM='$(PLATFORM)'. Expected one of: $(SUPPORTED_PLATFORMS)"; exit 1 ;; \
	esac

validate:
	@test -f "$(CARGO_MANIFEST)" || { echo "Could not find onde Cargo.toml at $(CARGO_MANIFEST)"; exit 1; }
	@test -d "$(SWIFT_REPO)/Sources/Onde" || { echo "Run make from the onde-swift repository root."; exit 1; }

build-bindgen: validate
	cargo $(RUST_STABLE) build --manifest-path "$(BINDGEN_MANIFEST)" --release

prepare:
	@rm -rf "$(FRAMEWORK_DIR)" "$(GENERATED_DIR)" "$(HEADERS_DIR)"
	@mkdir -p "$(GENERATED_DIR)" "$(HEADERS_DIR)"

generate-swift:
	@test -n "$(BINDGEN_INPUT)" || { echo "BINDGEN_INPUT is required"; exit 1; }
	cd "$(ONDE_REPO)" && "$(BINDGEN)" generate "$(BINDGEN_INPUT)" --crate onde --language swift --out-dir "$(GENERATED_DIR)"
	cp "$(GENERATED_DIR)/onde.swift" "$(SWIFT_GLUE)"
	cp "$(GENERATED_DIR)/ondeFFI.h" "$(HEADERS_DIR)/ondeFFI.h"
	cp "$(GENERATED_DIR)/ondeFFI.modulemap" "$(HEADERS_DIR)/module.modulemap"
	@echo "Updated $(SWIFT_GLUE)"

ios: build-bindgen prepare
	IPHONEOS_DEPLOYMENT_TARGET=$(IOS_DEPLOYMENT_TARGET) cargo $(RUST_STABLE) rustc --manifest-path "$(CARGO_MANIFEST)" --target aarch64-apple-ios --release --lib --crate-type staticlib
	IPHONEOS_DEPLOYMENT_TARGET=$(IOS_DEPLOYMENT_TARGET) cargo $(RUST_STABLE) rustc --manifest-path "$(CARGO_MANIFEST)" --target aarch64-apple-ios-sim --release --lib --crate-type staticlib
	$(MAKE) generate-swift BINDGEN_INPUT="$(ONDE_REPO)/target/aarch64-apple-ios/release/libonde.a"
	xcodebuild -create-xcframework \
	  -library "$(ONDE_REPO)/target/aarch64-apple-ios/release/libonde.a" -headers "$(HEADERS_DIR)" \
	  -library "$(ONDE_REPO)/target/aarch64-apple-ios-sim/release/libonde.a" -headers "$(HEADERS_DIR)" \
	  -output "$(FRAMEWORK_DIR)"
	@echo "Built $(FRAMEWORK_DIR) for iOS"

macos: build-bindgen prepare
	MACOSX_DEPLOYMENT_TARGET=$(MACOS_DEPLOYMENT_TARGET) cargo $(RUST_STABLE) rustc --manifest-path "$(CARGO_MANIFEST)" --target aarch64-apple-darwin --release --lib --crate-type staticlib
	$(MAKE) generate-swift BINDGEN_INPUT="$(ONDE_REPO)/target/aarch64-apple-darwin/release/libonde.a"
	xcodebuild -create-xcframework \
	  -library "$(ONDE_REPO)/target/aarch64-apple-darwin/release/libonde.a" -headers "$(HEADERS_DIR)" \
	  -output "$(FRAMEWORK_DIR)"
	@echo "Built $(FRAMEWORK_DIR) for macOS"

tvos: build-bindgen prepare
	TVOS_DEPLOYMENT_TARGET=$(TVOS_DEPLOYMENT_TARGET) cargo $(RUST_NIGHTLY) rustc -Z build-std --manifest-path "$(CARGO_MANIFEST)" --target aarch64-apple-tvos --release --lib --crate-type staticlib
	TVOS_DEPLOYMENT_TARGET=$(TVOS_DEPLOYMENT_TARGET) cargo $(RUST_NIGHTLY) rustc -Z build-std --manifest-path "$(CARGO_MANIFEST)" --target aarch64-apple-tvos-sim --release --lib --crate-type staticlib
	$(MAKE) generate-swift BINDGEN_INPUT="$(ONDE_REPO)/target/aarch64-apple-tvos/release/libonde.a"
	xcodebuild -create-xcframework \
	  -library "$(ONDE_REPO)/target/aarch64-apple-tvos/release/libonde.a" -headers "$(HEADERS_DIR)" \
	  -library "$(ONDE_REPO)/target/aarch64-apple-tvos-sim/release/libonde.a" -headers "$(HEADERS_DIR)" \
	  -output "$(FRAMEWORK_DIR)"
	@echo "Built $(FRAMEWORK_DIR) for tvOS"

visionos: build-bindgen prepare
	XROS_DEPLOYMENT_TARGET=$(VISIONOS_DEPLOYMENT_TARGET) cargo $(RUST_NIGHTLY) rustc -Z build-std --manifest-path "$(CARGO_MANIFEST)" --target aarch64-apple-visionos --release --lib --crate-type staticlib
	XROS_DEPLOYMENT_TARGET=$(VISIONOS_DEPLOYMENT_TARGET) cargo $(RUST_NIGHTLY) rustc -Z build-std --manifest-path "$(CARGO_MANIFEST)" --target aarch64-apple-visionos-sim --release --lib --crate-type staticlib
	$(MAKE) generate-swift BINDGEN_INPUT="$(ONDE_REPO)/target/aarch64-apple-visionos/release/libonde.a"
	xcodebuild -create-xcframework \
	  -library "$(ONDE_REPO)/target/aarch64-apple-visionos/release/libonde.a" -headers "$(HEADERS_DIR)" \
	  -library "$(ONDE_REPO)/target/aarch64-apple-visionos-sim/release/libonde.a" -headers "$(HEADERS_DIR)" \
	  -output "$(FRAMEWORK_DIR)"
	@echo "Built $(FRAMEWORK_DIR) for visionOS"

watchos: build-bindgen prepare
	WATCHOS_DEPLOYMENT_TARGET=$(WATCHOS_DEPLOYMENT_TARGET) cargo $(RUST_NIGHTLY) rustc -Z build-std --manifest-path "$(CARGO_MANIFEST)" --target aarch64-apple-watchos --release --lib --crate-type staticlib
	WATCHOS_DEPLOYMENT_TARGET=$(WATCHOS_DEPLOYMENT_TARGET) cargo $(RUST_NIGHTLY) rustc -Z build-std --manifest-path "$(CARGO_MANIFEST)" --target aarch64-apple-watchos-sim --release --lib --crate-type staticlib
	$(MAKE) generate-swift BINDGEN_INPUT="$(ONDE_REPO)/target/aarch64-apple-watchos/release/libonde.a"
	xcodebuild -create-xcframework \
	  -library "$(ONDE_REPO)/target/aarch64-apple-watchos/release/libonde.a" -headers "$(HEADERS_DIR)" \
	  -library "$(ONDE_REPO)/target/aarch64-apple-watchos-sim/release/libonde.a" -headers "$(HEADERS_DIR)" \
	  -output "$(FRAMEWORK_DIR)"
	@echo "Built $(FRAMEWORK_DIR) for watchOS"

clean:
	rm -rf "$(FRAMEWORK_DIR)" "$(LOCAL_DIR)"
	@echo "Removed local Onde Swift build artifacts"
