#!/bin/bash
set -eo pipefail
readonly SCRIPT=$(basename "$0")
readonly YELLOW=$'\e[1;33m'
readonly GREEN=$'\e[1;32m'
readonly RED=$'\e[1;31m'
readonly BLUE=$'\e[1;34m'
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

function print_notice()
{
  printf "%s✦ %s %s\n" "${BLUE}" "$@" "${NC}"
}


function display_usage()
{
#Prints out help menu
cat <<EOF
Usage: ${GREEN}${SCRIPT} ${BLUE}  [options]${NC}

Adds Upstream remote URL for this repo and disables
push for it.
-----------------------------------------------------------
[-m --method]           [Method to use. (Defaults to merge-ff)]
[-x --upstream-branch]  [Upstream Branch to merge/rebase (Defaults to master)]
[-u --upstream-url]     [Upstream URL to set (Required)]
[-h --help]             [Display this help message]
EOF
}

function disable_upstream_push()
{
  # check if push needs to be disabled
  if [[ $(git remote get-url --push upstream) == "DISABLED" ]]; then
      print_success "Upstream push is already disabled"
    else
      print_notice "Disabling upstream push"
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
  local upstream_url
  if upstream_url=$(git remote get-url upstream 2>/dev/null ); then
    if [[ $upstream_url == "$INPUT_UPSTREAM_URL" ]]; then
      print_success "Upstream already exists"
      disable_upstream_push
    else
      print_warning "Remote 'upstream' exists and has a different URL"
      if git remote set-url upstream "${INPUT_UPSTREAM_URL}" > /dev/null 2>&1; then
        print_success "Replaced ${INPUT_UPSTREAM_URL}"
        disable_upstream_push
      else
        print_error "Failed to fix upstream ${INPUT_UPSTREAM_URL}"
        exit 1
      fi
    fi
  else
    print_notice "There seems to be no remote named upstream, adding now"
    if git remote add upstream "${INPUT_UPSTREAM_URL}" > /dev/null 2>&1; then
      print_success "Added ${INPUT_UPSTREAM_URL} as upstream"
      disable_upstream_push
    else
      print_error "Failed to add upstream remote ${INPUT_UPSTREAM_URL}"
      exit 1
    fi
  fi
}

function error_on_empty_variable()
{
  local var_val var_name
  var_val="${2}"
  var_name="${1}"
  if [[ -z $var_val ]]; then
    print_error "${var_name} is empty or undefined!"
    exit 10
  fi
}

function update_fork()
{
  print_info "checkout master"
  git checkout master
  print_info "Getting upstream branch master"
  git fetch upstream
-x | --upstream-branch
    CONFLICTS=$(git ls-files -u | wc -l)
    if [ "$CONFLICTS" -gt 0 ] ; then
      print_error "Oops! merge conflict(s). Aborting"
      git rebase --abort
      exit 1
    fi
  elif [[ $INPUT_METHOD == "merge-ff" ]]; then
    print_notice "Using ff merge with -ff"
    git merge -ff upstream/master master
    CONFLICTS=$(git ls-files -u | wc -l)
    if [ "$CONFLICTS" -gt 0 ] ; then
      print_error "Oops! merge conflict(s). Aborting"
      git merge --abort
      exit 1
    fi
  else
    print_error "Update method ${INPUT_METHOD} is not supported!"
    exit 1
  fi-x | --upstream-branch
  git push
}

function main()
{

  while [ "${1}" != "" ]; do
    case ${1} in
      -m | --method )             shift;INPUT_METHOD="${1}";;
      -x | --upstream-branch)     shift;INPUT_UPSTREAM_BRANCH="${1}";;
      -u | --upstream-url)        shift;INPUT_UPSTREAM_URL="${1}";;
      -h | --help )               display_usage;
                                  exit $?
                                  ;;
      * )                         print_error "Invalid argument(s). See usage below."
                                  usage;
                                  exit 1
                                  ;;
    esac
    shift
  done


  error_on_empty_variable "${INPUT_METHOD}" "INPUT_METHOD"
  error_on_empty_variable "${INPUT_UPSTREAM_BRANCH}" "INPUT_UPSTREAM_BRANCH"
  error_on_empty_variable "${INPUT_UPSTREAM_URL}" "INPUT_UPSTREAM_URL"

  configure_upstream
  update_fork

}

main "$@"
