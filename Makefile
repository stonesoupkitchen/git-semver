# PREAMBLE
#//////////////////////////////////////////////////////////////////////////////
#
MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:

# VARIABLES, CONFIG, & SETTINGS
#//////////////////////////////////////////////////////////////////////////////
#
DEBUG ?= false
BINNAME := git-semver

# Platform detection
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

# Target definitions for different platforms
LINUX_X86_64   := x86_64-unknown-linux-gnu
LINUX_AARCH64  := aarch64-unknown-linux-gnu
MACOS_X86_64   := x86_64-apple-darwin
MACOS_AARCH64  := aarch64-apple-darwin
WINDOWS_X86_64 := x86_64-pc-windows-msvc
WINDOWS_GNU    := x86_64-pc-windows-gnu
FREEBSD_X86_64 := x86_64-unknown-freebsd

# All supported targets
TARGETS := $(LINUX_X86_64) $(LINUX_AARCH64) $(MACOS_X86_64) $(MACOS_AARCH64) $(WINDOWS_X86_64) $(FREEBSD_X86_64)

# Default target based on current platform
ifeq ($(UNAME_S),Linux)
	ifeq ($(UNAME_M),x86_64)
		DEFAULT_TARGET := $(LINUX_X86_64)
	else ifeq ($(UNAME_M),aarch64)
		DEFAULT_TARGET := $(LINUX_AARCH64)
	endif
else ifeq ($(UNAME_S),Darwin)
	ifeq ($(UNAME_M),x86_64)
		DEFAULT_TARGET := $(MACOS_X86_64)
	else ifeq ($(UNAME_M),arm64)
		DEFAULT_TARGET := $(MACOS_AARCH64)
	endif
else ifeq ($(UNAME_S),FreeBSD)
	DEFAULT_TARGET := $(FREEBSD_X86_64)
endif

TARGET ?= $(DEFAULT_TARGET)

# Build directories
ifeq (true, $(DEBUG))
	BUILD_MODE := debug
	CARGO_FLAGS :=
else
	BUILD_MODE := release
	CARGO_FLAGS := --release
endif

# Install paths for different operating systems
ifeq ($(findstring windows,$(TARGET)),windows)
	BINARY_EXT := .exe
	INSTALL_PATH ?= C:/Program Files/$(BINNAME)
else
	BINARY_EXT :=
	ifeq ($(UNAME_S),Darwin)
		INSTALL_PATH ?= /usr/local/bin
	else
		INSTALL_PATH ?= /usr/local/bin
	endif
endif

BINDIR := $(CURDIR)/target/$(TARGET)/$(BUILD_MODE)
DISTDIR := $(CURDIR)/dist
BINARY := $(BINNAME)$(BINARY_EXT)

# Version information
DATE       = $(shell date -u +'%Y-%m-%dT%H:%M:%SZ')
GIT_COMMIT = $(shell git rev-parse HEAD)
GIT_SHA    = $(shell git rev-parse --short HEAD)
GIT_BRANCH = $(shell git rev-parse --abbrev-ref HEAD)
GIT_TAG    = $(shell git describe --tags --abbrev=0 --exact-match 2>/dev/null)

# Allows us to set VERSION from the command line.
# Otherwise, if BINARY_VERSION is not set, use the current git tag.
ifdef VERSION
	BINARY_VERSION = $(VERSION)
endif
BINARY_VERSION ?= ${GIT_TAG}

SRC := $(shell find . -type f -name '*.rs' -print) Cargo.toml Cargo.lock

# TASKS
#//////////////////////////////////////////////////////////////////////////////
#

.PHONY: all
all: build test ## Build and test for the default target

.PHONY: help
help: ## Show this help message
	@echo "Build targets for $(BINNAME)"
	@echo
	@grep -E '^[a-zA-Z_/-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "; printf "Usage:\n"}; {printf "  %-15s %s\n", $$1, $$2}'
	@echo
	@echo "Examples:"
	@echo "  make build-linux-x86_64"
	@echo "  make build-all"
	@echo "  make package-all"
	@echo "  make TARGET=x86_64-pc-windows-msvc build"

.PHONY: clean
clean: ## Remove all build artifacts
	@cargo clean
	@rm -rf $(DISTDIR)

.PHONY: changelog
changelog: ## Create changelog
	@git-cliff \
    --config "cliff.toml" \
    --output="CHANGELOG.md" \
    --tag "$(BINARY_VERSION)"

.PHONY: check
check: ## Quick check without building
	@cargo check --all-targets

.PHONY: fmt
fmt: ## Format source code with rustfmt
	@cargo fmt

.PHONY: lint
lint: ## Run clippy linter
	@cargo clippy --all-targets --all-features -- -D warnings

.PHONY: test
test: ## Run tests for default target
	@cargo test --target $(TARGET)

.PHONY: quality
quality: check fmt lint test ## Run all quality checks

# Build targets
.PHONY: build
build: $(BINDIR)/$(BINARY) ## Build for default target

$(BINDIR)/$(BINARY): $(SRC)
	@echo "Building $(BINNAME) for $(TARGET) ($(BUILD_MODE))"
	@cargo build --target $(TARGET) $(CARGO_FLAGS)

# Individual platform build targets
.PHONY: build-linux-x86_64
build-linux-x86_64: ## Build for Linux x86_64
	@$(MAKE) TARGET=$(LINUX_X86_64) build

.PHONY: build-linux-aarch64
build-linux-aarch64: ## Build for Linux ARM64
	@$(MAKE) TARGET=$(LINUX_AARCH64) build

.PHONY: build-macos-x86_64
build-macos-x86_64: ## Build for macOS x86_64
	@$(MAKE) TARGET=$(MACOS_X86_64) build

.PHONY: build-macos-aarch64
build-macos-aarch64: ## Build for macOS ARM64 (Apple Silicon)
	@$(MAKE) TARGET=$(MACOS_AARCH64) build

.PHONY: build-windows-x86_64
build-windows-x86_64: ## Build for Windows x86_64
	@$(MAKE) TARGET=$(WINDOWS_X86_64) build

.PHONY: build-freebsd-x86_64
build-freebsd-x86_64: ## Build for FreeBSD x86_64
	@$(MAKE) TARGET=$(FREEBSD_X86_64) build

.PHONY: build-all
build-all: setup-cross ## Build for all supported targets
	@for target in $(TARGETS); do \
		echo "Building for $$target..."; \
		$(MAKE) TARGET=$$target build || exit 1; \
	done

# Testing targets
.PHONY: test-all
test-all: ## Run tests for all supported targets
	@for target in $(TARGETS); do \
		echo "Testing for $$target..."; \
		$(MAKE) TARGET=$$target test || exit 1; \
	done

# Package creation
.PHONY: package
package: build ## Create distribution package for default target
	@mkdir -p $(DISTDIR)
	@if [[ "$(TARGET)" == *"windows"* ]]; then \
		cd $(BINDIR) && zip -r $(DISTDIR)/$(BINNAME)-$(BINARY_VERSION)-$(TARGET).zip $(BINARY); \
	else \
		cd $(BINDIR) && tar -czf $(DISTDIR)/$(BINNAME)-$(BINARY_VERSION)-$(TARGET).tar.gz $(BINARY); \
	fi
	@echo "Package created: $(DISTDIR)/$(BINNAME)-$(BINARY_VERSION)-$(TARGET).*"

.PHONY: package-all
package-all: build-all ## Create distribution packages for all targets
	@mkdir -p $(DISTDIR)
	@for target in $(TARGETS); do \
		echo "Packaging for $$target..."; \
		bindir="$(CURDIR)/target/$$target/$(BUILD_MODE)"; \
		if [[ "$$target" == *"windows"* ]]; then \
			binary="$(BINNAME).exe"; \
			cd "$$bindir" && zip -r $(DISTDIR)/$(BINNAME)-$(BINARY_VERSION)-$$target.zip "$$binary"; \
		else \
			binary="$(BINNAME)"; \
			cd "$$bindir" && tar -czf $(DISTDIR)/$(BINNAME)-$(BINARY_VERSION)-$$target.tar.gz "$$binary"; \
		fi; \
	done
	@echo "All packages created in $(DISTDIR)/"
	@ls -la $(DISTDIR)/

.PHONY: install
install: build ## Install binary to system path
	@echo "Installing $(BINARY) to $(INSTALL_PATH)"
	@mkdir -p "$(INSTALL_PATH)"
	@install "$(BINDIR)/$(BINARY)" "$(INSTALL_PATH)/$(BINARY)"

.PHONY: release
release: clean lint test package-all ## Full release build (clean, lint, test, package all)
	@echo "Release build complete!"
	@echo "Artifacts:"
	@ls -la $(DISTDIR)/

.PHONY: info
info: ## Show build configuration
	@echo "Configuration:"
	@echo "  Binary name:    $(BINNAME)"
	@echo "  Target:         $(TARGET)"
	@echo "  Build mode:     $(BUILD_MODE)"
	@echo "  Binary path:    $(BINDIR)/$(BINARY)"
	@echo "  Install path:   $(INSTALL_PATH)"
	@echo "  Version:        $(BINARY_VERSION)"
	@echo "  Git SHA:        $(GIT_SHA)"
	@echo "  Platform:       $(UNAME_S)/$(UNAME_M)"

.PHONY: setup-cross
setup-cross: ## Install cross-compilation tools
	@echo "Installing cross-compilation targets..."
	@rustup target add $(TARGETS)
	@if ! command -v cross >/dev/null 2>&1; then \
		echo "Installing cross..."; \
		cargo install cross; \
	fi

.PHONY: setup-git-cliff
setup-git-cliff: ## Install git-cliff
	@if ! command -v git-cliff >/dev/null 2>&1; then \
		echo "Installing git-cliff..."; \
		cargo install git-cliff; \
	fi

.PHONY: watch
watch: ## Watch for changes and rebuild
	@cargo watch -x "check --all-targets" -x test
