#!/bin/bash
set -eo pipefail
readonly SCRIPT="docker run -it tprasadtp/sync-fork:latest"
readonly YELLOW=$'\e[33m'
readonly GREEN=$'\e[32m'
readonly RED=$'\e[31m'
readonly GRAY=$'\e[38;5;244m'
readonly NC=$'\e[0m'

function print_info()
{
  printf "✦ %s \n" "$@"
}

function print_success()
{
  printf "%s✔ %s %s\n" "${GREEN}" "$@" "${NC}"
}

function print_warning()
{
  printf "%s⚠ %s %s\n" "${YELLOW}" "$@" "${NC}"
}

function print_error()
{
   printf "%s✖ %s %s\n" "${RED}" "$@" "${NC}"
}

function print_debug()
{
  if [[ ${DEBUG} == "true" ]]; then
    printf "%s✦ %s %s\n" "${GRAY}" "$@" "${NC}"
  fi
}


function display_usage()
{
#Prints out help menu
cat <<EOF
Usage: ${GREEN}${SCRIPT} ${BLUE}  [options]${NC}

Keeps minimally modified forks in sync.
Please do not use this for forks with extensive
modifications as it might lead to lot of conflicts.
-----------------------------------------------------------
[-m --method]           [Method to use. (Defaults to merge-ff)]
[-b --branch]           [Branch to merge/rebase]
[-x --upstream-branch]  [Upstream Branch to merge/rebase (Defaults to master)]
[-u --upstream-url]     [Upstream URL to set (Required)]
[--no-push]             [Skip Git Push]
[-k -ssk-key]           [SSK Key. This is not a file but instead ascii armored key]
[-h --help]             [Display this help message]

Version: ${SYNC_FORK_VERSION:-UNKNOWN}

This is best used as github action.
For info on how to do it see https://github.com/tprasadtp/sync-fork
EOF
}

function disable_upstream_push()
{
  # check if push needs to be disabled
  if [[ $(git remote get-url --push upstream) == "DISABLED" ]]; then
      print_success "Upstream push is already disabled"
    else
      print_info "Disabling upstream push"
      if git remote set-url --push upstream DISABLED > /dev/null 2>&1; then
        print_success "Done"
      else
        print_error "Failed to disable upstream push"
        exit 1
      fi
  fi

}

function configure_upstream()
{
  local existing_upstream_url
  if existing_upstream_url=$(git remote get-url upstream 2>/dev/null ); then
    if [[ $existing_upstream_url == "$upstream_url" ]]; then
      print_success "Upstream already exists"
      disable_upstream_push
    else
      print_warning "Remote 'upstream' exists and has a different URL"
      if git remote set-url upstream "${upstream_url}" > /dev/null 2>&1; then
        print_success "Replaced ${upstream_url}"
        disable_upstream_push
      else
        print_error "Failed to fix upstream ${upstream_url}"
        exit 1
      fi
    fi
  else
    print_info "There seems to be no remote named upstream, adding now"
    if git remote add upstream "${upstream_url}" > /dev/null 2>&1; then
      print_success "Added ${upstream_url} as upstream"
      disable_upstream_push
    else
      print_error "Failed to add upstream remote ${upstream_url}"
      exit 1
    fi
  fi
}

function config_git()
{
  # push to publishing branch
  print_info "Setting up Git Config"
  git config user.name "${GIT_USER:-$GITHUB_ACTOR}"
  git config user.email "${GIT_EMAIL:-$GITHUB_ACTOR@users.noreply.github.com}"

  git config url."git@github.com:".insteadOf https://github.com/
  git config url."git@github.com:".insteadOf git://

  mkdir -p "${HOME}/.ssh"
  ssh-keyscan -t rsa github.com >> "${HOME}/.ssh/known_hosts"

  echo "${ssh_private_key}" > "${HOME}/.ssh/id_ed25519"
  chmod 400 "${HOME}/.ssh/id_ed25519"
}

function error_on_empty_variable()
{
  local var_val var_name
  var_val="${1}"
  var_name="${2}"
  if [[ -z $var_val ]]; then
    print_error "${var_name} is empty or undefined!"
    display_usage
    exit 10
  else
    print_debug "${var_name} is ${var_val}"
  fi
}

function update_fork()
{
  print_info "Checkout ${checkout_branch}"

  git checkout "${checkout_branch}"

  config_git

  print_info "Fetching upstream"
  git fetch upstream
  if [[ ${merge_method} == "rebase" ]]; then
    git rebase "upstream/${upstream_branch}"
    CONFLICTS=$(git ls-files -u | wc -l)
      if [ "$CONFLICTS" -gt 0 ] ; then
        print_error "Oops! merge conflict(s). Aborting"
        git rebase --abort
        exit 1
      fi
  elif [[ ${merge_method} == "merge-ff" ]]; then
    print_info "Using merge with --ff-only"
    git merge --ff-only "upstream/${upstream_branch}" "${checkout_branch}"
    CONFLICTS="$(git ls-files -u | wc -l)"
    if [[ $CONFLICTS -gt 0 ]] ; then
      print_error "Oops! merge conflict(s). Aborting"
      git merge --abort
      exit 1
    fi
  elif [[ ${merge_method} == "merge" ]]; then
    print_info "Using merge"
    git merge "upstream/${upstream_branch}" "${checkout_branch}"
    CONFLICTS="$(git ls-files -u | wc -l)"
    if [[ $CONFLICTS -gt 0 ]] ; then
      print_error "Oops! merge conflict(s). Aborting"
      git merge --abort
      exit 1
    fi
  else
    print_error "Update method ${merge_method} is not supported!"
    display_usage
    exit 1
  fi

  # Push back changes
  if [[ ${skip_push} == "true" ]]; then
    print_info "Skipping git push!"
  else
    print_info "Pushing back changes!"
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
  print_debug "Running with Arguments: ${*}"

  while [ "${1}" != "" ]; do
    case ${1} in
      -m | --method )             shift;merge_method="${1}";;
      -x | --upstream-branch)     shift;upstream_branch="${1}";;
      -u | --upstream-url)        shift;upstream_url="${1}";;
      -b | --branch)              shift;checkout_branch="${1}";;
      -k | --ssh-key)             shift;ssh_private_key="${1}";;
      -h | --help )               display_usage;
                                  exit $?
                                  ;;
      -n | --no-push)             skip_push="true";;
      * )                         print_error "Invalid argument: ${1} See usage below."
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
