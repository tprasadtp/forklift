# Set the shell
SHELL := /bin/bash
NAME := sync-fork

# Base of operations
ROOT_DIR := $(strip $(patsubst %/, %, $(dir $(realpath $(firstword $(MAKEFILE_LIST))))))

# Default Goal
.DEFAULT_GOAL := help

# Embrace Extend and .. ooff Sorry, We dont do that anymore! We Love OpenSource. Said MikroSofty
ifeq ($(GITHUB_ACTIONS),true)
	BRANCH := $(shell echo "$$GITHUB_REF" | cut -d '/' -f 3- | sed -r 's/[\/\*\#]+/-/g' )
else
	BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
	GITHUB_SHA := $(shell git rev-parse HEAD)
	GITHUB_WORKFLOW := local
	GITHUB_RUN_NUMBER := "0"
	GITUNTRACKEDCHANGES := $(shell git status --porcelain --untracked-files=no)
	ifeq ($(GITUNTRACKEDCHANGES),)
		VERSION := $(shell git describe --exact-match --contains HEAD)
	else
		VERSION := ""
	endif
endif

# Version

# Enable Buidkit if not disabled
DOCKER_BUILDKIT ?= 1

DOCKER_USER := tprasadtp

# Prefix for github package registry images
DOCKER_PREFIX_GITHUB := docker.pkg.github.com/$(DOCKER_USER)/$(NAME)

.PHONY: lint
lint: docker-lint shellcheck ## Lint Everything


.PHONY: docker-lint
docker-lint: ## Lint Dockerfiles
	@echo -e "\033[92m➜ $@ \033[0m"
	docker run --rm -i hadolint/hadolint < $(ROOT_DIR)/src/Dockerfile

.PHONY: shellcheck
shellcheck: ## Runs the shellcheck.
	@echo -e "\033[92m➜ $@ \033[0m"
	shellcheck -e SC2036 $(ROOT_DIR)/src/entrypoint.sh

.PHONY: docker
docker: ## Build DockerHub image (runs as root inide docker)
	@echo -e "\033[92m➜ $@ \033[0m"
	@echo -e "\033[92m✱ Building Docker Image\033[0m"
	@DOCKER_BUILDKIT=$(DOCKER_BUILDKIT) docker build --target action -t $(NAME) \
		--build-arg GITHUB_SHA=$(GITHUB_SHA) \
		--build-arg GITHUB_WORKFLOW=$(GITHUB_WORKFLOW) \
		--build-arg GITHUB_RUN_NUMBER=$(GITHUB_RUN_NUMBER) \
		--build-arg VERSION=$(VERSION) \
		-f $(ROOT_DIR)/src/Dockerfile \
		$(ROOT_DIR)/src
	@if [ $(BRANCH) == "master" ]; then \
		echo -e "\033[92m✱ Tagging as latest \033[0m"; \
		docker tag $(NAME) $(DOCKER_USER)/$(NAME):latest; \
		docker tag $(NAME) $(DOCKER_PREFIX_GITHUB)/$(NAME):latest; \
		if [ ! -z $(VERSION) ]; then \
		echo -e "\033[92m✱ Tagging as $(VERSION)\033[0m"; \
			docker tag $(NAME) $(DOCKER_USER)/$(NAME):$(VERSION); \
			docker tag $(NAME) $(DOCKER_PREFIX_GITHUB)/$(NAME):$(VERSION); \
		else \
		echo -e "\033[93m✱ Commit is dirty or not tagged with a version\033[0m"; \
		fi; \
	else \
		echo -e "\033[95m✱ Tagging as $(BRANCH)\033[0m"; \
		docker tag $(NAME) $(DOCKER_USER)/$(NAME):$(BRANCH); \
		docker tag $(NAME) $(DOCKER_PREFIX_GITHUB)/$(NAME):$(BRANCH); \
	fi

.PHONY: docker-push
docker-push: ## Push docker images (action and user images)
	@echo -e "\033[92m➜ $@ \033[0m"
	@if [ $(BRANCH) == "master" ]; then \
		echo -e "\033[92m✱ Pushing Tag: latest [DockerHub]\033[0m"; \
		docker push $(DOCKER_USER)/$(NAME):latest; \
		if [ ! -z $(VERSION) ]; then \
		echo -e "\033[92m✱ Pushing Tag: $(VERSION) [DockerHub]\033[0m"; \
			docker push $(DOCKER_USER)/$(NAME):$(VERSION); \
		else \
		echo -e "\033[93m✱ Skip Pushing Version Tags [DockerHub]\033[0m"; \
		fi; \
		echo -e "\033[92m✱ Pushing Tag: latest [GitHub]\033[0m"; \
		#docker push $(DOCKER_PREFIX_GITHUB)/$(NAME):latest; \
		if [ ! -z $(VERSION) ]; then \
		echo -e "\033[92m✱ Pushing Tag: $(VERSION) [GitHub] \033[0m"; \
			docker push $(DOCKER_PREFIX_GITHUB)/$(NAME):$(VERSION); \
		else \
		echo -e "\033[93m✱ Skip Pushing Version Tags [GitHub]\033[0m"; \
		fi; \
	else \
		echo -e "\033[92m✱ Pushing Tag: $(BRANCH)[DockerHub].\033[0m"; \
		docker push $(DOCKER_USER)/$(NAME):$(BRANCH); \
		echo -e "\033[92m✱ Pushing Tag: $(BRANCH)[GitHub] \033[0m"; \
		docker push $(DOCKER_PREFIX_GITHUB)/$(NAME):$(BRANCH); \
	fi

.PHONY: help
help: ## This help dialog.
	@IFS=$$'\n' ; \
    help_lines=(`fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##/:/'`); \
	printf "%-32s %s\n" " Target " "    Help " ; \
    printf "%-32s %s\n" "--------" "------------" ; \
    for help_line in $${help_lines[@]}; do \
        IFS=$$':' ; \
        help_split=($$help_line) ; \
        help_command=`echo $${help_split[0]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
        help_info=`echo $${help_split[2]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
        printf '\033[92m'; \
        printf "➜ %-30s %s" $$help_command ; \
        printf '\033[0m'; \
        printf "%s\n" $$help_info; \
    done

.PHONY: debug-vars
debug-vars:
	@echo "GITHUB_ACTIONS: ${GITHUB_ACTIONS}"
	@echo "VERSION: ${VERSION}"
	@echo "BRANCH: ${BRANCH}"
	@echo "GITHUB_SHA: ${GITHUB_SHA}"
	@echo "GITHUB_WORKFLOW: ${GITHUB_WORKFLOW}"
	@echo "GITHUB_RUN_NUMBER: ${GITHUB_RUN_NUMBER}"
