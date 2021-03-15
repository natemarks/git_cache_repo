#!/usr/bin/env bash
# Use to create a clone in a temporary build directory on a build agent host.
# Build agents clone often, so this  saves  time on every build job

#  to clone a remote repo into the build directory using a local
# mirror If the local mirror already exists, update it before cloning If it
# doesn't exist  create the local mirror , then clone  from that


set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

# shellcheck disable=SC2034
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-f] -p param_value command

If the mirror repo doens't exist create it
If it already exists, update it
Clone the local mirror directory a build directory

commands:
  clone         Clone the remote repo to the build dir using mirror
  push          Push the current build branch to mirror and remote

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
-b, --build     Path to build directory
-m, --mirror    Path to the mirror directory
-r, --remote    Remote location to clone
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    # shellcheck disable=SC2034
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
  # default values of variables set from params
  build=''
  mirror=''
  remote=''

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -xv ;;
    --no-color) NO_COLOR=1 ;;
    -b | --build) # example named parameter
      build="${2-}"
      shift
      ;;
    -m | --mirror) # example named parameter
      mirror="${2-}"
      shift
      ;;
    -r | --remote) # example named parameter
      remote="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")


  # check required params and arguments
  [[ -z "${build-}" ]] && die "Missing required parameter: build"
  [[ -z "${mirror-}" ]] && die "Missing required parameter: mirror"
  [[ -z "${remote-}" ]] && die "Missing required parameter: remote"
  [[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"

  return 0
}

parse_params "$@"
setup_colors


# given the remote target, return the short repo name
# this input:
# https://azureagent:SOME_TOKEN@stash.imprivata.com/scm/cldops/dna.git
# returns
#    dna
function short_repo() {
  # strip off everything before the last '/' leaving "dna.git"
  with_git=$(echo "${1}" | rev | cut -d/ -f1 | rev)
  # strip the .git and return it
  echo "${with_git%.git}"
}

function create_or_update_mirror() {
  if [ ! -d "${mirror}/${short}.git" ] 
  then
    msg "${GREEN}Creating local mirror clone: ${mirror}/${short}.git${NOFORMAT}"
    git -C "${mirror}" clone --mirror "${remote}"
  else
    msg "${GREEN}Updating local mirror clone: ${mirror}/${short}.git${NOFORMAT}"
    git -C "${mirror}/${short}.git" fetch "${remote}" --prune --all
  fi
  msg "${GREEN}Cloning ${build}/${short} from local mirror: ${mirror}/${short}.git${NOFORMAT}"
  git -C "${build}" clone "${mirror}/${short}.git"
}

function push_build_changes() {
  current_branch="$(git -C "${build_repo}" branch --show-current)"
  msg "${GREEN}Push branch (${current_branch}) in build repo ${build_repo} to local mirror ${mirror}/${short}.git${NOFORMAT}"
  git -C "${build_repo}" push -u origin "${current_branch}"
  msg "${GREEN}Push local mirror ${mirror}/${short}.git to remote${NOFORMAT}"
  git -C "${mirror}/${short}.git" push
}




# script logic here

msg "${GREEN}Read parameters:${NOFORMAT}"
msg "Creating build directory: ${build}"
mkdir -p "${build}"
msg "Creating mirror directory: ${mirror}"
mkdir -p "${mirror}"
msg "- remote: ${remote}"

declare command
command="${args[0]}"
msg "- command: ${command}"

declare short
short=$(short_repo "${remote}")
msg "The short repo name is: ${short} "

declare build_repo
build_repo="${build}/${short}"
msg "The build repo dir is: ${build_repo} "

case $command in

  clone)
    create_or_update_mirror
    ;;

  push)
    push_build_changes
    ;;

  *)
    echo "invalid command: ${command}"
    ;;
esac