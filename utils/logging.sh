#!/bin/bash
#
# Print message $3 with log-level $1 and options $2 to STDERR,
# colorized if terminal
# Example:
# for level in INFO DEBUG WARN ERROR CUSTOM; do
#   log $level this is a $level message;
# done;

function get_lvl_nb() {
# error levels
DBG=("DEBUG" 0)
INF=("INFO" 1)
WRN=("WARN" 2)
ERR=("ERROR" 3)
LVL_ARR=(
         DBG[@]
         INF[@]
         WRN[@]
         ERR[@]
         )

    local lvl=$1
    # search for corresponding error level number
    for ((i=0; i<${#LVL_ARR[@]}; i++)); do
        if [[ "${lvl}" == "${!LVL_ARR[i]:0:1}" ]]; then
            lvl_nb=${!LVL_ARR[i]:1:1}
        fi;
    done;
    echo ${lvl_nb}
}


log() {
    # global error level setting
    if [[ -z $LOG_LEVEL ]]; then
        LOG_LEVEL=INFO
    fi;

    local level=${1?}
    shift
    local code= line="[$(date '+%F %T')] $level: $*"
    if [[ -t 2 ]]; then
        case "$level" in
            DEBUG)
                code=30
                ;;
            INFO)
                code=36
                ;;
            WARN)
                code=33
                ;;
            ERROR)
                code=31
                ;;
            *)
                code=37
                ;;
        esac;
        if [[ $(get_lvl_nb $level) -ge $(get_lvl_nb $LOG_LEVEL) ]]; then
            echo -e "\e[${code}m${line}\e[0m"
        fi;
    else
        if [[ $(get_lvl_nb $level) -ge $(get_lvl_nb $LOG_LEVEL) ]]; then
            echo "$line"
        fi;
    fi >&2
}
