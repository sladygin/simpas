#!/bin/bash
#
#    Simpas - SIMPle Asynchronous Scheduler
#    Logging utility
#    
#    Copyright (C) 2016  Slawomir Ladygin
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
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
    LOG_LVL=DEBUG

    local level=${1?}
    shift
    local code= line="[$(date '+%F %T')] $level: $*"
    if [ -t 2 ]; then
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
        if [ $(get_lvl_nb $level) -ge $(get_lvl_nb $LOG_LVL) ]; then
            echo -e "\e[${code}m${line}\e[0m"
        fi;
    else
        if [ $(get_lvl_nb $level) -ge $(get_lvl_nb $LOG_LVL) ]; then
            echo "$line"
        fi;
    fi >&2
}
