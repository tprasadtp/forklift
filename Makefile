# Set Shell
SHELL := /bin/bash
NAME := forklift

# OCI Metadata
IMAGE_TITLE := "Keep Forks in Sync"
IMAGE_DESC := "GitHub Action to keep minimally modified forks in sync"
IMAGE_URL := "https://hub.docker.com/r/tprasadtp/forklift"
IMAGE_SOURCE := "https://github.com/tprasadtp/forklift"
IMAGE_LICENSES := "MIT"
IMAGE_DOCUMENTATION_URL := "https://github.com/tprasadtp/forklift"

include base.mk

# Because we need ROOT_DIR
DOCKER_CONTEXT_DIR := $(ROOT_DIR)/src

.PHONY: shellcheck
shellcheck: ## Runs the shellcheck.
	@echo -e "\033[92m➜ $@ \033[0m"
	shellcheck -e SC2036 $(ROOT_DIR)/src/entrypoint.sh
