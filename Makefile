# Change shell to bash
SHELL := /bin/bash

# Define Paths
export REPO_ROOT := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

# Set default goal to help
.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this message (Default)
	@IFS=$$'\n' ; \
    help_lines=(`fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##/:/' | sort -u`); \
	printf "%-25s %s\n" "Target" "Info" ; \
    printf "%-25s %s\n" "-------------" "-------------" ; \
    for help_line in $${help_lines[@]}; do \
        IFS=$$':' ; \
        help_split=($$help_line) ; \
        help_command="$$(echo $${help_split[0]} | sed -e 's/^ *//' -e 's/ *$$//')" ; \
        help_info="$$(echo $${help_split[2]} | sed -e 's/^ *//' -e 's/ *$$//')" ; \
        printf '\033[92m'; \
        printf "↠ %-23s %s" $$help_command ; \
        printf '\033[0m'; \
        printf "%s\n" $$help_info; \
    done

.PHONY: shellcheck
shellcheck: ## Runs the shellcheck.
	@echo -e "\033[92m➜ $@ \033[0m"
	shellcheck -e SC2036 $(REPO_ROOT)/forklift.sh
