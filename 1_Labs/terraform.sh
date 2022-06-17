#!/bin/bash

## A wrapper to run terraform for the project
## It manages templating of terraform files prior to running terraform

set -e

readonly DIR="${0%/*}"
readonly NAME="${0##*/}"
readonly LOCKFILE="/tmp/terraform.sh.lock"
readonly LOCKFD=99

###
# Lock management
###
_lock()             { flock "-$1" "$LOCKFD"; }
_no_more_locking()  { _lock u; _lock xn && rm -f "$LOCKFILE"; }
_prepare_locking()  { eval "exec $LOCKFD>\"$LOCKFILE\""; trap _no_more_locking EXIT; }
exlock()            { _lock x; }   # obtain an exclusive lock
unlock()            { _lock u; }   # drop a lock

###
# Color management
###
_RST=$'\x1b'"[0m"; _BLD=$'\x1b'"[1m"; _BCK=$'\x1b'"[30m"
_RED=$'\x1b'"[31m"; _GRN=$'\x1b'"[32m"; _BRW=$'\x1b'"[33m"
_BLU=$'\x1b'"[34m"; _MTA=$'\x1b'"[35m"; _CYN=$'\x1b'"[36m"

if [ -t 1 ]; then
  # stdout is a terminal
  function color() { echo "$1$2${_RST}"; }
else
  # stdout is not a terminal
  function color() { echo "$2"; }
fi
function debug() { log 1 "[$(color "${_MTA}" "D")]" "$*"; }
function info()  { log 2 "[$(color "${_BLU}" "*")]" "$*"; }
function error() { log 3 "[$(color "${_RED}" "!")]" "$*"; }

###
# Usage
###
# Print a modified version of the usage
function usage() {
  terraform -help
}
function nonblock_read() {
  # use unique names to prevent conflicts
  #  CRC32(nonblock_read) = 1eb6a541
  local -n _1eb6a541_buffer="$1" _1eb6a541_status="$2"
  local _1eb6a541_line

  # read first line
  IFS='' read -r -t 0.001 _1eb6a541_buffer    # empty IFS to prevent line strip
  _1eb6a541_status=$?
  # Only append additional data if there is more data
  while [[ "$_1eb6a541_status" -eq 0 ]]; do
     IFS='' read -r -t 0.001 _1eb6a541_line
    _1eb6a541_status=$?
    _1eb6a541_buffer+=$'\n'"$_1eb6a541_line"
  done
}
function alter_terraform_usage() {
  set +e  # allow errors in this function
  # Used to modify terraform usage if one is found in stdin
  #  because terraform sometime print unfinished lines, we cannot only rely
  #  on sed. Need to use read in non-blocking mode to allow printing partial
  #  lines
  local usage_found=n status buffer
  nonblock_read buffer status  # status: 0 == line read; 1 == EoF;  > 128 == timeout
  while true; do
    # first try to find Usage to know wether substitution should occur
    if grep -q 'Usage: terraform' <<<"$buffer"; then usage_found=y; fi

    {
      # If read timed out, consider the buffer not terminated with newlines
      if [[ $status -ge 128 ]]; then
        echo -n "$buffer"
      else
        echo "$buffer"
      fi
    } | {
      # if usage was found, perform substitution. Otherwise, do not
      if [[ "$usage_found" == y ]]; then
        sed '
s/Usage: terraform/Usage: '"$NAME"'/
/Global options/a \
  -v            Increase verbosity\
  -q            Decrease verbosity\
  --parallel N  Run N lab infrastructure in parallel (-auto-approve should be\
                used with apply or destroy)\
  --common      Run only common infrastructure terraform\
  --lab         Run only lab infrastructure terraform'
      else
        cat
      fi
    }
    # stop reading if there is nothing left to read
    if [[ $status -eq 1 ]]; then break; fi
    # else read next line
    nonblock_read buffer status  # status: 0 == line read; 1 == EoF;  > 128 == timeout
  done
}

###
# Functions
###
# function to manage logging
function log() {
  local min_level="$1" prefix="$2" msg="$3"
  if [[ "$loglevel" -le "$min_level" ]]; then
    echo "$prefix $msg" >&2
  fi
}
function prepend_line_with() {
  set +e  # allow errors in this function
  # Used to prepend each line with a dedicated prefix
  local prefix="$1" status buffer
  nonblock_read buffer status  # status: 0 == line read; 1 == EoF;  > 128 == timeout
  while true; do
    {
      # If read timed out, consider the buffer not terminated with newlines
      if [[ $status -ge 128 ]]; then
        echo -n "$buffer"
      else
        echo "$buffer"
      fi
    } | {
      # append the prefix at the begining of each line
      sed 's/^/'"$(color "${_BRW}" "$prefix")"'/'
    }
    # stop reading if there is nothing left to read
    if [[ $status -eq 1 ]]; then break; fi
    # else read next line
    nonblock_read buffer status  # status: 0 == line read; 1 == EoF;  > 128 == timeout
  done
}

# Wrappers to ease calling terraform
function terraform() {
  # Allows $1 to be -q, not to print anything (for subshell $())
  local quiet=n
  if [[ "$1" == "-q" ]]; then quiet=y; shift; fi

  # Print debugging messages
  if [[ "$quiet" == n ]]; then debug "Executing: ($PWD) \$ terraform $*"; fi

  # Run terraform
  command terraform "$@" |& alter_terraform_usage
  local status="${PIPESTATUS[0]}"

  # Print debugging messages
  if [[ "$quiet" == n ]]; then debug "Execution result: $status"; fi
  return "$status"
}
function terraform_common() {
  (
    cd "$DIR/common_infra"
    terraform "$@"
  )
}
function terraform_lab() {
  (
    cd "$DIR/per_lab_infra"
    terraform "$@"
  )
}

# Main function
function main() {
  # Parse terraform args to extract variable arguments for console
  local -a terraform_args=()
  local loglevel=2 do_common=y do_lab=y run_parallel=1 cmd
  while [ -n "$1" ]; do
    case "$1" in
      -v )
        loglevel=1
        shift;;
      -q )
        loglevel=3
        shift;;
      --parallel )
        if [[ "$2" -ge 1 ]]; then
          run_parallel="$2"
          shift 2
        else
          error "Invalid value for --parallel: $2"
          error "Value should be an integer higher than 1"
          usage
          exit 1
        fi;;
      --common )
        do_common=y
        do_lab=n
        shift;;
      --lab )
        do_common=n
        do_lab=y
        shift;;
      -h | -help | --help )
        usage
        exit;;
      -*)
        terraform_args+=("$1")
        shift;;
      *)
        # save the first argument which is the terraform command
        if [[ -z "$cmd" ]]; then
          cmd="$1";
        else
          terraform_args+=("$1")
        fi
        shift;;
    esac
  done

  # Ensure a command was provided
  if [[ -z "$cmd" ]]; then
    usage
    exit 1
  fi

  # For destroy command first destroy labs. For other commands, start with
  # actions on common infra
  case "$cmd" in
    destroy )
      do_lab_infra
      do_common_infra;;
    * )
      do_common_infra
      do_lab_infra;;
  esac
}

function do_common_infra() {
  # Run terraform on the common infra
  if [[ "$do_common" == "y" ]]; then
    info "Running terraform on common infrastructure"
    terraform_common "$cmd" "${terraform_args[@]}"
  else
    debug "Skip actions on common infrastructure"
  fi
}

function do_lab_infra() {
  # Run terraform on the lab infra
  if [[ "$do_lab" == "y" ]]; then
    case "$cmd" in
      # Manage commands which do not require per lab action
      init | validate | console | fmt | get | login | logout | providers | test | version )
        do_lab_infra_once;;
      # Manage commands which do require per lab action
      * )
        do_lab_infra_each;;
    esac
  else
    debug "Skip actions on lab infrastructures"
  fi
}
function do_lab_infra_once() {
  # Run terraform commands which should be run once only
  info "Running terraform on lab infrastructure"
  terraform_lab "$cmd" "${terraform_args[@]}"
}
function change_lab() {
  local lab_name="$1"
  # Change or create the workspack
  if terraform_lab workspace list | grep -q '\<'"$lab_name"'\>'; then
    debug "Changing to workspace $lab_name"
    terraform_lab workspace select "$lab_name"
  else
    debug "Creating workspace $lab_name"
    terraform_lab workspace new "$lab_name"
  fi
}
function do_lab_infra_each() {
  # Run terraform commands which should be run on each workspace
  # first check if the common infra was deployed
  if ! terraform_common output -json lab_count &> /dev/null; then
    error "Cannot run command $cmd on labs before common infrastructure is deployed"
    return 1
  fi

  # Load number of labs
  info "Loading number of labs to run terraform on"
  lab_count="$(terraform_common -q output -json lab_count)"
  debug "Number of labs: $lab_count"

  # For apply, also load the previous lab count to destroy extra lab if needed
  if [[ "$cmd" == "apply" ]]; then
    # base the decision on the lab_count of Lab1
    change_lab "Lab1"
    if ! terraform_lab output -json lab_count &> /dev/null; then
      prev_lab_count=0
      debug "Found no previously deployed lab"
    else
      prev_lab_count="$(terraform_lab output -json lab_count)"
      debug "Found $prev_lab_count previously deployed lab"
    fi
  else
    prev_lab_count=0
  fi

  # For each lab, run the command
  info "Running terraform on each lab"
  if [[ "$run_parallel" -gt 1 ]]; then
    info "Run $run_parallel labs in parallel"
  fi

  local lab_name
  local max_lab_count="$((prev_lab_count > lab_count ? prev_lab_count : lab_count))"
  for ((i=0; i<run_parallel; i++)); do
    (
      debug "Starting thread $i"
      # prepare lockfile
      _prepare_locking

      for ((lab_id=i; lab_id<max_lab_count; lab_id+=run_parallel)); do
        # acquire a lock to ensure only one thread change the workspack at
        # a time
        exlock
        info "-- Lab $((lab_id+1)) --"

        # Ensure we select the right workspace
        lab_name="Lab$((lab_id+1))"
        # Change or create the workspack
        change_lab "$lab_name"

        # Run terrafrom
        #  Provide lab_id through env variables to be able manage commands
        #  which do not need variable and do not support -var option
        #  In case of apply, do a destroy on lab higher than lab_count
        if [[ "$cmd" == "apply" && "$i" -ge "$lab_count" ]]; then
          { TF_VAR_lab_id="$lab_id" terraform_lab destroy "${terraform_args[@]}" |& prepend_line_with "$lab_name:"$'\t'; } &
          pid=$!
        else
          { TF_VAR_lab_id="$lab_id" terraform_lab "$cmd" "${terraform_args[@]}" |& prepend_line_with "$lab_name:"$'\t'; } &
          pid=$!
        fi
        # release the lock and wait for the terraform to end
        unlock
        wait "$pid"
      done
    )&
  done
  # wait for all terraform commands to complete
  wait
}

###
# Run the script
###
main "$@"
