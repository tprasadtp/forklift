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
endif

# Enable Buidkit if not disabled
DOCKER_BUILDKIT ?= 1

DOCKER_USER := tprasadtp

# Prefix for github package registry images
DOCKER_PREFIX_GITHUB := docker.pkg.github.com/$(DOCKER_USER)/$(NAME)

.PHONY: docker-lint
docker-lint: ## Lint Dockerfiles
	@echo -e "\033[92m➜ $@ \033[0m"
	@docker run --rm -i hadolint/hadolint < Dockerfile

.PHONY: docker
docker: ## Build DockerHub image (runs as root inide docker)
	@echo -e "\033[92m➜ $@ \033[0m"
	@echo -e "\033[95m * Building Docker Image\033[0m"
	@DOCKER_BUILDKIT=$(DOCKER_BUILDKIT) docker build --target hub -t $(NAME) \
		--build-arg GITHUB_SHA=$(GITHUB_SHA) \
		--build-arg GITHUB_WORKFLOW=$(GITHUB_WORKFLOW) \
		--build-arg GITHUB_RUN_NUMBER=$(GITHUB_RUN_NUMBER) \
		--build-arg VERSION=$(VERSION) $(ROOT_DIR)/.
	@if [ $(BRANCH) == "master" ]; then \
		echo -e "\033[95m * On master tagging as $(VERSION) and latest \033[0m"; \
		docker tag $(NAME) $(DOCKER_USER)/$(NAME):latest; \
		docker tag $(NAME) $(DOCKER_USER)/$(NAME):$(VERSION); \
		docker tag $(NAME) $(DOCKER_PREFIX_GITHUB)/$(NAME):latest; \
		docker tag $(NAME) $(DOCKER_PREFIX_GITHUB)/$(NAME):$(VERSION); \
	else \
		echo -e "\033[95m * Not on master tagging as $(BRANCH).\033[0m"; \
		docker tag $(NAME) $(DOCKER_USER)/$(NAME):$(BRANCH); \
		docker tag $(NAME) $(DOCKER_PREFIX_GITHUB)/$(NAME):$(BRANCH); \
	fi

.PHONY: docker-push
docker-push: ## Push docker images (action and user images)
	@echo -e "\033[92m➜ $@ \033[0m"
	@echo -e "\033[95m * Pushing User Image\033[0m"
	@if [ $(BRANCH) == "master" ]; then \
		echo -e "\033[93m   + On master add pushing latest and $(VERSION) to DockerHub\033[0m"; \
		docker push $(DOCKER_USER)/$(NAME):latest; \
		docker push $(DOCKER_USER)/$(NAME):$(VERSION); \
		echo -e "\033[93m   + On master add pushing latest and $(VERSION) to GitHub \033[0m"; \
		docker push $(DOCKER_PREFIX_GITHUB)/$(NAME):latest; \
		docker push $(DOCKER_PREFIX_GITHUB)/$(NAME):$(VERSION); \
	else \
		echo -e "\033[93m   + Not on master and pushing $(BRANCH) to DockerHub.\033[0m"; \
		docker push $(DOCKER_USER)/$(NAME):$(BRANCH); \
		echo -e "\033[93m   + Not on master and pushing $(BRANCH) to GitHub \033[0m"; \
		docker push $(DOCKER_PREFIX_GITHUB)/$(NAME):$(BRANCH); \
	fi
	@echo -e "\033[95m * Pushing Action Image\033[0m"
	@if [ $(BRANCH) == "master" ]; then \
		echo -e "\033[93m   + On master add pushing latest and $(VERSION)[GitHub] \033[0m"; \
		docker push $(DOCKER_PREFIX_GITHUB)/action:latest; \
		docker push $(DOCKER_PREFIX_GITHUB)/action:$(VERSION); \
		echo -e "\033[93m   + On master add pushing latest and $(VERSION)[DockerHub] \033[0m"; \
		docker push $(DOCKER_USER)/$(NAME)-action:latest; \
		docker push $(DOCKER_USER)/$(NAME)-action:$(VERSION); \
	else \
		echo -e "\033[93m   + Not on master as pushing $(BRANCH) [GitHub].\033[0m"; \
		docker push $(DOCKER_PREFIX_GITHUB)/action:$(BRANCH); \
		echo -e "\033[93m   + Not on master as pushing $(BRANCH) [DockerHub].\033[0m"; \
		docker push $(DOCKER_USER)/$(NAME)-action:$(BRANCH); \
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
