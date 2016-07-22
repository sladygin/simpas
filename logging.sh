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

log() {
    local level=${1?}
    shift
    local code= line="[$(date '+%F %T')] $level: $*"
    if [ -t 2 ]; then
        case "$level" in
            INFO)
                code=36
                ;;
            DEBUG)
                code=30
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
        esac
        echo -e "\e[${code}m${line}\e[0m"
    else
        echo "$line"
    fi >&2
}
