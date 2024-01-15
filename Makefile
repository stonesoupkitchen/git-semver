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
TARGET ?= x86_64-unknown-linux-gnu

ifeq (true, $(DEBUG))
BINDIR := $(CURDIR)/target/debug
else
BINDIR := $(CURDIR)/target/release
endif
BINNAME      := git-semver
INSTALL_PATH ?= /usr/local/bin

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
all: build test

.PHONY: help
help: ## Show this help message.
	@grep -E '^[a-zA-Z_/-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "; printf "\nUsage:\n"}; {printf "  %-15s %s\n", $$1, $$2}'
	@echo

.PHONY: clean
clean: ## Remove generated and built artifacts.
	@cargo clean

.PHONY: fmt
fmt: ## Format source code with Rustfmt.
	@cargo fmt

.PHONY: lint
lint: ## Run clippy against the source code.
	@cargo clippy

.PHONY: build
build: $(BINDIR)/$(BINNAME) ## Build the project.

$(BINDIR)/$(BINNAME): $(SRC)
	@if [[ "$(DEBUG)" == "true" ]]; then \
		cargo build --target $(TARGET); \
	else \
		cargo build --target $(TARGET) --release; \
	fi

.PHONY: test
test: ## Run automated tests.
	@cargo test --target $(TARGET) --all

.PHONY: install ## Install binary to $INSTALL_PATH.
install:
	@install "$(BINDIR)/$(BINNAME)" "$(INSTALL_PATH)/$(BINNAME)"

