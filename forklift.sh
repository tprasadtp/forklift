#!/usr/bin/env bash
# Copyright (c) 2020-2021. Prasad Tengse
#

set -o pipefail

# Script Constants
readonly CURDIR="$(cd -P -- "$(dirname -- "")" && pwd -P)"
readonly SCRIPT="$(basename "$0")"

# Handle Use interrupt
# trap ctrl-c and call ctrl_c()
trap ctrl_c_handler INT

readonly VERSION="0.2.0"

function ctrl_c_handler() {
  log_error "User Interrupt! CTRL-C"
  exit 4
}

## BEGIN AUTO-GENERATED CONTENT ##

# Basic colors
readonly YELLOW=$'\e[38;5;221m'
readonly GREEN=$'\e[38;5;42m'
readonly RED=$'\e[38;5;197m'
readonly NC=$'\e[0m'

# Enhanced colors

readonly PINK=$'\e[38;5;212m'
readonly BLUE=$'\e[38;5;159m'
readonly ORANGE=$'\e[38;5;208m'
readonly TEAL=$'\e[38;5;192m'
readonly VIOLET=$'\e[38;5;219m'
readonly GRAY=$'\e[38;5;246m'
readonly DARK_GRAY=$'\e[38;5;242m'

# Script Defaults
LOG_LVL=0

# Default Log Handlers

function log_info()
{
  printf "• %s \n" "$@"
}

function log_success()
{
  printf "%s• %s %s\n" "${GREEN}" "$@" "${NC}"
}

function log_warning()
{
  printf "%s• %s %s\n" "${YELLOW}" "$@" "${NC}"
}

function log_error()
{
   printf "%s• %s %s\n" "${RED}" "$@" "${NC}"
}

function log_debug()
{
  if [[ $LOG_LVL -gt 0  ]]; then
    printf "%s• %s %s\n" "${GRAY}" "$@" "${NC}"
  fi
}

function log_notice()
{
  printf "%s• %s %s\n" "${TEAL}" "$@" "${NC}"
}

function log_step_info()
{
  printf "  • %s\n" "$@"
}

function log_variable()
{
  local var
  var="$1"
  if [[ $LOG_LVL -gt 0  ]]; then
    printf "%s  » %-20s - %-10s %s\n" "${GRAY}" "${var}" "${!var}" "${NC}"
  fi
}
## END AUTO-GENERATED CONTENT ##



function display_usage()
{
#Prints out help menu
cat <<EOF
Usage: ${GREEN}${SCRIPT} ${BLUE}  [options]${NC}

- Keeps minimally modified forks in sync.
- Please do not use this for forks with extensive
  modifications.
${ORANGE}
-------------- Required Arguments ------------------------${NC}
[-u --upstream-url]     Upstream URL to set (Required)
${TEAL}
-------------- Optional Arguments ------------------------${NC}
[-m --method]           Method to use (Defaults is merge-ff)
[-b --branch]           Branch to merge/rebase
[-x --upstream-branch]  Upstream Branch to merge/rebase
                        (Defaults is master)
${GRAY}
---------------- Other Arguments -------------------------
[--no-push]             Skip Git Push
[-s skip-git-config]    Skip configuring git committer
[-v --verbose]          Enable verbose logging
[-h --help]             Display this help message
${NC}${PINK}
-------------- About & Version Info -----------------------${NC}
- Action Version - ${VERSION:-UNKNOWN}
- This is best used as Github Action.
- Defaults are only populated when running as GitHub action.

See ${BLUE}https://git.io/JtV8L${NC} for more info.
EOF
}

function disable_upstream_push()
{
  # check if push needs to be disabled
  if [[ $(git remote get-url --push upstream) == "DISABLED" ]]; then
      log_success "Upstream push is already disabled"
    else
      log_info "Disabling upstream push"
      if git remote set-url --push upstream DISABLED > /dev/null 2>&1; then
        log_success "Done"
      else
        log_error "Failed to disable upstream push"
        exit 1
      fi
  fi

}

function configure_upstream()
{
  local existing_upstream_url
  if existing_upstream_url=$(git remote get-url upstream 2>/dev/null ); then
    if [[ $existing_upstream_url == "$upstream_url" ]]; then
      log_success "Upstream already exists"
      disable_upstream_push
    else
      log_warning "Remote 'upstream' exists and has a different URL"
      if git remote set-url upstream "${upstream_url}" > /dev/null 2>&1; then
        log_success "Replaced ${upstream_url}"
        disable_upstream_push
      else
        log_error "Failed to fix upstream ${upstream_url}"
        exit 1
      fi
    fi
  else
    log_info "There seems to be no remote named upstream, adding now"
    if git remote add upstream "${upstream_url}" > /dev/null 2>&1; then
      log_success "Added ${upstream_url} as upstream"
      disable_upstream_push
    else
      log_error "Failed to add upstream remote ${upstream_url}"
      exit 1
    fi
  fi
}

function config_git()
{
  # push to publishing branch
  log_info "Setting up Git Config"
  git config user.name "${GIT_USER:-$GITHUB_ACTOR}"
  git config user.email "${GIT_EMAIL:-$GITHUB_ACTOR@users.noreply.github.com}"
}

function error_on_empty_variable()
{
  local var_val var_name
  var_val="${1}"
  var_name="${2}"
  if [[ -z $var_val ]]; then
    log_error "${var_name} is empty or undefined!"
    display_usage
    exit 10
  else
    log_debug "${var_name} is ${var_val}"
  fi
}

function update_fork()
{

  log_info "Unshallow"
  git fetch --prune --unshallow

  log_info "Checkout ${checkout_branch}"

  git checkout "${checkout_branch}"

  if [[ $skip_git_config == "true" ]]; then
    log_warning "Skipped configuring git committer!"
    log_warning "If not configured already this might cause issues!"
  else
    config_git
  fi

  log_info "Fetching upstream"
  git fetch upstream
  if [[ ${merge_method} == "rebase" ]]; then
    git rebase "upstream/${upstream_branch}"
    CONFLICTS=$(git ls-files -u | wc -l)
      if [ "$CONFLICTS" -gt 0 ] ; then
        log_error "Oops! merge conflict(s). Aborting"
        git rebase --abort
        exit 1
      fi
  elif [[ ${merge_method} == "merge-ff-only" ]]; then
    log_info "Using merge with --ff-only"
    git merge --ff-only "upstream/${upstream_branch}" "${checkout_branch}"
    CONFLICTS="$(git ls-files -u | wc -l)"
    if [[ $CONFLICTS -gt 0 ]] ; then
      log_error "Oops! merge conflict(s). Aborting"
      git merge --abort
      exit 1
    fi
  elif [[ ${merge_method} == "merge" ]]; then
    log_info "Using merge with ff"
    git merge "upstream/${upstream_branch}" "${checkout_branch}"
    CONFLICTS="$(git ls-files -u | wc -l)"
    if [[ $CONFLICTS -gt 0 ]] ; then
      log_error "Oops! merge conflict(s). Aborting"
      git merge --abort
      exit 1
    fi
  else
    log_error "Update method ${merge_method} is not supported!"
    display_usage
    exit 1
  fi

  # Push back changes
  if [[ ${skip_push} == "true" ]]; then
    log_info "Skipping git push!"
  else
    log_info "Pushing back changes!"
    if [[ ${merge_method} == "rebase" ]]; then
      #  Because it checks the remote branch for changes
      git push --force-with-lease
    else
      git push
    fi
  fi
}

function main()
{
  log_debug "Running with Arguments: ${*}"

  while [ "${1}" != "" ]; do
    case ${1} in
      -m | --method )             shift;merge_method="${1}";;
      -x | --upstream-branch)     shift;upstream_branch="${1}";;
      -u | --upstream-url)        shift;upstream_url="${1}";;
      -b | --branch)              shift;checkout_branch="${1}";;
      -n | --no-push)             skip_push="true";;
      -s | --skip-git-config)     skip_git_config="true";;
      -v | --verbose)             LOG_LVL=1;
                                  log_debug "Enabled DEBUG logs";;
      -h | --help )               display_usage;
                                  exit $?
                                  ;;
      * )                         log_error "Invalid argument: ${1} See usage below."
                                  display_usage;
                                  exit 1
                                  ;;
    esac
    shift
  done

  error_on_empty_variable "${merge_method}" "--method"
  error_on_empty_variable "${upstream_branch}" "--upstream-branch"
  error_on_empty_variable "${upstream_url}" "--upstream-url"
  error_on_empty_variable "${checkout_branch}" "--branch"


  configure_upstream
  update_fork

}

main "$@"
