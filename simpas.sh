#!/bin/bash
# Bash 4 or later only
#
#    Simpas - SIMPle Asynchronous Scheduler
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
#Usage: $0 [options]"
#Options are:"
#  -c <file>            - configuration file
#  -t <scheduler table> - mandatory - table of process
#  -f <process name>    - force given process to run
#  -v - verbose         - all messages will show on console instead of the log file
#  -s - simulate        - simulating scheduler run, no command will be executed
#


# loading environment variables
_dir=$(dirname "$(readlink -f "$0")")
_config=("/etc/simpas/simpasrc" \
         "/usr/local/etc/simpas/simpasrc" \
         "${_dir}/conf/simpasrc" \
         "${_dir}/simpasrc" \
         "~/.config/simpasrc" \
         "~/.simpasrc")
for (( i=0; i<${#_config[@]}; i++ )); do
    if [[ -f ${_config[$i]} ]]; then
        source ${_config[$i]}
    fi;
done;

# libraries
source ${_dir}/utils/logging.sh

# by default redirect output to stderr:
exec >&2

#-------------------
# --- Functions ---
#-------------------
function usage()
{
    echo ""
    echo "Help documentation for ${BOLD}${0##*/}.${NORM}"
    echo ""
    echo "${REV}Basic usage:${NORM} ${BOLD}${0##*/} -t <scheduler table> [options]${NORM}"
    echo ""
    echo "  <scheduler table> - is the name of the table of process to run"
    echo ""
    echo "Optional arguments:"
    echo "  -c <file>            - configuration file"
    echo "  -f <process name>    - force given process to run"
    echo "  -s - simulate        - simulating scheduler run, no command will be executed"
    echo "  -v - verbose         - all messages will be shown on the console instead"
    echo "                         of being sent to the log file"
    echo ""
}

# reading scheduler table
function read_table() {
    local proc=$1


    if [[ ! -f $SCH_TABLES/$scheduler_table.tbl ]]; then
        log ERROR "Could not find the process table '$scheduler_table'. Exiting."
        cleanup
        exit 1;
    else
        log INFO "Reading the process table..."
        readarray -t -s 1 p_id_arr < <(cut -d';' -f1 $SCH_TABLES/$scheduler_table.tbl)
        readarray -t -s 1 p_code_arr < <(cut -d';' -f2 $SCH_TABLES/$scheduler_table.tbl)
        readarray -t -s 1 p_name_arr < <(cut -d';' -f3 $SCH_TABLES/$scheduler_table.tbl)
        readarray -t -s 1 p_cmd_arr < <(cut -d';' -f4 $SCH_TABLES/$scheduler_table.tbl)
        readarray -t -s 1 p_opt_arr < <(cut -d';' -f5 $SCH_TABLES/$scheduler_table.tbl)
        readarray -t -s 1 p_year_arr < <(cut -d';' -f6 $SCH_TABLES/$scheduler_table.tbl)
        readarray -t -s 1 p_month_arr < <(cut -d';' -f7 $SCH_TABLES/$scheduler_table.tbl)
        readarray -t -s 1 p_day_arr < <(cut -d';' -f8 $SCH_TABLES/$scheduler_table.tbl)
        readarray -t -s 1 p_dow_arr < <(cut -d';' -f9 $SCH_TABLES/$scheduler_table.tbl)
        readarray -t -s 1 p_hour_arr < <(cut -d';' -f10 $SCH_TABLES/$scheduler_table.tbl)
        readarray -t -s 1 p_min_arr < <(cut -d';' -f11 $SCH_TABLES/$scheduler_table.tbl)
        readarray -t -s 1 p_per_arr < <(cut -d';' -f12 $SCH_TABLES/$scheduler_table.tbl)
        readarray -t -s 1 p_incond_arr < <(cut -d';' -f13 $SCH_TABLES/$scheduler_table.tbl)
        readarray -t -s 1 p_outcond_arr < <(cut -d';' -f14 $SCH_TABLES/$scheduler_table.tbl)
        readarray -t -s 1 p_exitcode_arr < <(cut -d';' -f15 $SCH_TABLES/$scheduler_table.tbl)
        readarray -t -s 1 p_logfile_arr < <(cut -d';' -f16 $SCH_TABLES/$scheduler_table.tbl)
        for (( i=0; i<${#p_id_arr[@]}; i++ )); do
            p_done_arr[$i]=0
            p_pid_arr[$i]=0
        done

        if [[ -n "$proc" ]]; then
            # info if one process forced
            log INFO "Done. 1 forced process to run:"
            for (( i=0; i<${#p_code_arr[@]}; i++ )); do
                if [[ "${p_code_arr[$i]}" = "$proc" ]]; then
                    log INFO "${p_id_arr[$i]} - ${p_code_arr[$i]} - ${p_name_arr[$i]} - command: ${p_cmd_arr[$i]} ${p_opt_arr[$i]}"
                    log INFO "Execution conditions:"
                    log INFO "- Date: ${p_year_arr[$i]}/${p_month_arr[$i]}/${p_day_arr[$i]}"
                    log INFO "- Day of Week: ${p_dow_arr[$i]}"
                    log INFO "- Time: ${p_hour_arr[$i]}:${p_min_arr[$i]}"
                    log INFO "- Frequency: ${p_per_arr[$i]}"
                    log INFO "- Start condition: ${p_incond_arr[$i]}"
                    log INFO "- Condition to set: ${p_outcond_arr[$i]}"
                    log INFO "- Log file: ${p_logfile_arr[$i]}"
                    log INFO "================================="
                fi;
            done;
        else
            # info if all process will be run
            log INFO "Done. ${#p_id_arr[@]} process to run:"
            for (( i=0; i<${#p_code_arr[@]}; i++ )); do
                log INFO "${p_id_arr[$i]} - ${p_code_arr[$i]} - ${p_name_arr[$i]} - command: ${p_cmd_arr[$i]} ${p_opt_arr[$i]}"
                log INFO "Execution conditions:"
                log INFO "- Date: ${p_year_arr[$i]}/${p_month_arr[$i]}/${p_day_arr[$i]}"
                log INFO "- Day of Week: ${p_dow_arr[$i]}"
                log INFO "- Time: ${p_hour_arr[$i]}:${p_min_arr[$i]}"
                log INFO "- Frequency: ${p_per_arr[$i]}"
                log INFO "- Start condition: ${p_incond_arr[$i]}"
                log INFO "- Condition to set: ${p_outcond_arr[$i]}"
                log INFO "- Log file: ${p_logfile_arr[$i]}"
                log INFO "================================="
            done;
        fi;
    fi;
}

# check if condition is met
# Returns True (0) or False (1)
function check_condition() {
    # process ID
    proc=$1
    local current_date=$(date "+%Y%m%d %H%M")

    #log DEBUG "(check)${p_code_arr[$proc]}-${p_name_arr[$proc]} - Checking conditions"

    # if there is not any condition set in the process table to comply with
    # in order to run a command, then we set it so that the check were OK
    if [[ -z ${p_year_arr[$proc]} ]]; then
        #log DEBUG "${p_id_arr[$proc]} - ${p_code_arr[$proc]}: Year not given. Assuming today"
        p_year_arr[$proc]=$(date -d "${current_date}" +%Y)
    fi;
    if [[ -z ${p_month_arr[$proc]} ]]; then
        #log DEBUG "${p_id_arr[$proc]} - ${p_code_arr[$proc]}: Month not given. Assuming today"
        p_month_arr[$proc]=$(date -d "${current_date}" +%m)
    fi;
    if [[ -z ${p_day_arr[$proc]} ]]; then
        #log DEBUG "${p_id_arr[$proc]} - ${p_code_arr[$proc]}: Day not given. Assuming today"
        p_day_arr[$proc]=$(date -d "${current_date}" +%d)
    fi;
    if [[ -z ${p_dow_arr[$proc]} ]]; then
        #log DEBUG "${p_id_arr[$proc]} - ${p_code_arr[$proc]}: Day of week not given. Assuming today"
        p_dow_arr[$proc]=$(date -d "${current_date}" +%u)
    fi;
    if [[ -z ${p_hour_arr[$proc]} ]]; then
        #log DEBUG "${p_id_arr[$proc]} - ${p_code_arr[$proc]}: Hour not given. Assuming now"
        p_hour_arr[$proc]=$(date -d "${current_date}" +%H)
    fi;
    if [[ -z ${p_min_arr[$proc]} ]]; then
        #log DEBUG "${p_id_arr[$proc]} - ${p_code_arr[$proc]}: Minutes not given. Assuming now"
        p_min_arr[$proc]=$(date -d "${current_date}" +%M)
    fi;

    # determining the full format of the condition date and time
    local cond_date="${p_year_arr[$proc]}${p_month_arr[$proc]}${p_day_arr[$proc]}"
    local cond_dow="${p_dow_arr[$proc]}"
    local cond_time="${p_hour_arr[$proc]}${p_min_arr[$proc]}"

    # checking date condition
    if [[ ${cond_date} -eq $(date -d "${current_date}" +%Y%m%d) ]]; then
        local date_ok=0
    else
        log INFO "(check)${p_code_arr[$proc]}-${p_name_arr[$proc]} - Not scheduled for today - job ignored."
        echo 255
        return
    fi;

    # checking day of week condition
    if [[ -n "$(echo ${cond_dow} | grep -e "$(date -d "${current_date}" +%u)")" ]]; then
        local dow_ok=0
    else
        log INFO "(check)${p_code_arr[$proc]}-${p_name_arr[$proc]} - Not scheduled for today - job ignored."
        echo 255
        return
    fi;

    # checking time condition
    if [[ ${cond_time} -le $(date -d "${current_date}" +%H%M) ]]; then
        local time_ok=0
    fi;

    if [[ -z "${p_incond_arr[$proc]}" ]]; then
        # no start condition is defined - OK to run
        log DEBUG "(check)${p_code_arr[$proc]}-${p_name_arr[$proc]} - No input condition."
        local incond_ok=0
    else
        # a start condition is defined
        # searching if the given condition has already been set by a previous job
        if [[ -n "$(cat $WRK_TBL | grep ${p_incond_arr[$proc]})" ]]; then
            log DEBUG "(check)${p_code_arr[$proc]}-${p_name_arr[$proc]} - Input condition: ${p_incond_arr[$proc]} is met"
            local incond_ok=0
        else
            log DEBUG "(check)${p_code_arr[$proc]}-${p_name_arr[$proc]} - Input condition: ${p_incond_arr[$proc]} is not met"
        fi;
    fi;

    # determining if all given conditions are fullfilled
    if [[ $date_ok ]] && [[ $dow_ok ]] && [[ $time_ok ]] && [[ $incond_ok ]]; then
        log INFO "(check)${p_code_arr[$proc]}-${p_name_arr[$proc]} - GO"
        echo 0
    else
        echo 1
    fi;
}

# run the process
function run_process() {
    # process ID
    local proc=$1
    local dummy=$2
    local logfile=$3

    # execute the command with given options
    local command="${p_cmd_arr[$proc]} ${p_opt_arr[$proc]}"

    # if scheduler is running in mode 'dummy' then the command is showed only
    if [[ -n "$dummy" ]]; then
        log INFO "(run)${p_code_arr[$proc]}-${p_name_arr[$proc]} - SIMULATING COMMAND: $command"
        local ret=0
    else
        # if not - then the real command is called
        log INFO "(run)${p_code_arr[$proc]}-${p_name_arr[$proc]} - COMMAND: $command"
        # exit to the log file
        if [[ -n "$logfile" ]]; then
            $command &>>"$logfile"
        else
            $command
        fi;
        local ret=$?
    fi

    # veryfing if the command returned the expected return code
    if [[ "$ret" = "${p_exitcode_arr[$proc]}" ]]; then
        log INFO "(run)${p_code_arr[$proc]}-${p_name_arr[$proc]} - TERMINATED, return code: ${p_exitcode_arr[$proc]}"
    else
        log ERROR "(run)${p_code_arr[$proc]}-${p_name_arr[$proc]} - FAILED, return code: $ret"
    fi;
    echo $ret
}

# set the out contition
function set_condition() {
    local proc=$1
    local condition=$2
    local ret=$3

    if [[ "$ret" = "${p_exitcode_arr[$proc]}" ]]; then
        log INFO "(run)${p_code_arr[$proc]}-${p_name_arr[$proc]} - Setting ${p_outcond_arr[$proc]}"
        echo "$condition" >> $WRK_TBL
    fi;
}

# run all process from a table
function run_all() {
    # start and continue until all processes are done
    proc_to_run=${#p_id_arr[@]}
    while [[ $proc_to_run -gt 0 ]]; do
        #log DEBUG "process to run: $proc_to_run"
        for (( i=0; i<${#p_id_arr[@]}; i++ )); do
            # if process is not started yet (element of p_done_arr=0)
            if [[ $((${p_done_arr[$i]})) -eq 0 ]]; then
                # check if process may be run, if so then run it and set condition if OK
                local chk=$(check_condition $i)
                # if the process was set as not scheduled (check_condition returned 255),
                # it is set as done and its PID is set to -1
                if [[ ${chk} -eq 255 ]]; then
                    p_done_arr[$i]=1
                    p_pid_arr[$i]=-1
                    ((proc_to_run--));
                elif [[ ${chk} -eq 0 ]]; then
                    p_done_arr[$i]=1
                    # running the process in a subshell
                    $(outcond=$(run_process $i "$simulate" ${p_logfile_arr[$i]}); set_condition $i ${p_outcond_arr[$i]} $outcond) &
                    p_pid_arr[$i]=$!
                    log DEBUG "(run) PID: ${p_pid_arr[$i]}"
                    # one process less to run
                    ((proc_to_run--));
                fi;
            fi;
        done;
        sleep 5;
    done;
}

# run (force) one process (given by -f parameter)
function force_process() {
    # force given process
    for (( i=0; i<${#p_id_arr[@]}; i++ )); do
        if [[ "${p_code_arr[$i]}" = "$process_name" ]]; then
            local found="yes"
            p_done_arr[$i]=1
            # running the process in a subshell
            $(outcond=$(run_process $i $simulate ${p_logfile_arr[$i]}); set_condition $i ${p_outcond_arr[$i]} $outcond) &
            p_pid_arr[$i]=$!
        fi;
    done;
    if [[ -z $found ]]; then
        log ERROR "Process $process_name not found in the table $scheduler_table."
        exit 1
    fi
}

# wait for all running process to terminate
function wait() {
    local all=$1

    # checking if all started process are terminated
    if [[ "$all" = "all" ]]; then
        proc_run=${#p_pid_arr[@]}
    else
        proc_run=1
    fi;
    while [[ $proc_run -gt 0 ]]; do
        for (( j=0; j<${#p_pid_arr[@]}; j++ )); do
            # waiting for the process to finish
            # ignoring not schedlet jobs (PID = -1)
            if [[ ${p_pid_arr[$j]} -gt 0 ]]; then
                pid=$(ps -x | sed -e "s/^[ ]*//" | cut -d" " -f1 | grep "^${p_pid_arr[$j]}$")
                if [ -z "$pid" ]; then
                    log DEBUG "PID Process $j: ${p_pid_arr[$j]} TERMINATING"
                    p_pid_arr[$j]=0
                    ((proc_run--))
                else
                    log DEBUG "PID Process $j: ${p_pid_arr[$j]} STILL RUNNING"
                fi;
            elif [[ ${p_pid_arr[$j]} -eq 0 ]]; then
                # this process has already terminated, nothing to do
                log DEBUG "PID Process $j: ${p_pid_arr[$j]} TERMINATED"
            elif [[ ${p_pid_arr[$j]} -eq -1 ]]; then
                # if the process was set as not scheduled (check_condition returned 255),
                # and its PID was set to -1, then no need to wait for it
                # we mark it as terminated
                log DEBUG "PID Process $j: ${p_pid_arr[$j]} NOT SCHEDULED - IGNORED"
                p_pid_arr[$j]=0
                ((proc_run--))
            else
                log ERROR "PID Process $j: ${p_pid_arr[$j]} UNKNOWN PROCESS STATE"
            fi;
        done
        sleep 5
        log DEBUG "Running process: $proc_run"
    done
}

# cleanup before exit scheduler
function cleanup() {

    # removing the PID file
    #log DEBUG "rm -f $PIDFILE"
    rm -f $PIDFILE;

    # removing the work file
    #log DEBUG "rm -f $WRK_TBL"
    rm -f $WRK_TBL;
}

# run if user hits control-c
function _control_c() {
  log WARN "*** Exiting on user request ***"
  cleanup
  exit $?
}

# run if user hits control-c
function _terminate() {
  log WARN "*** Exiting on TERM signal ***"
  cleanup
  exit $?
}

#--------------
# --- Main ---
#--------------
# trap keyboard interrupt (control-c)
trap _control_c SIGINT
trap _terminate SIGTERM

#Check the number of arguments. If none is passed, print help and exit.
NUMARGS=$#
if [ $NUMARGS -eq 0 ]; then
  usage;
  cleanup;
  exit 1;
fi

# check options
while getopts ":t:f:svh" opt; do
    case $opt in
    c)  # load configuration file
        source ${OPTARG}
        ;;
    f)  # force given process
        force="yes"
        process_name=${OPTARG}
        ;;
    o)  # run simpas only once per day
        onceperday="yes"
        ;;
    s)  # simulate
        simulate="yes"
        ;;
    t)  # process table
        scheduler_table=${OPTARG}
        ;;
    v)  # exit to stdout
        verbose="yes"
        ;;
    h)  # show help and exit
        usage
        cleanup
        exit 0
        ;;
    :)  #
        echo "Option -${OPTARG} requires an argument"
        usage
        cleanup
        exit 1
        ;;
    \?)  # unrecognized option - show help and exit
        echo "-${OPTARG} - invalid option"
        usage
        cleanup
        exit 1
    esac;
done;

# After getopts is done, shift all processed options away with
shift $((OPTIND-1))

# determining the unique part of scheduler work file (dat)
# as a timestamp
SCHUID=$(date +%Y%m%d%H%M%S%z)

# PID file
PIDFILE=$SCH_TEMP/scheduler_${scheduler_table}.pid

#work file
WRK_TBL=$SCH_TEMP/${scheduler_table}_$SCHUID.dat

# if verbose (-v) is not set, redirect to the log file
if [[ -z $verbose ]]; then
    exec &>>$SCH_LOG/scheduler_${scheduler_table}.log;
fi;

log INFO "Starting scheduler for the process table '$scheduler_table'."
log INFO "UID: $SCHUID"
today=$(date +%Y%m%d);
if [[ "${onceperday}" = "yes" ]]; then
    lastdate=$(cat ${SCH_DATA}/last_${scheduler_table}.txt)
    if [[ ${today} -eq ${lastdate}} ]]; then
        log INFO "The scheduler for the process table '$scheduler_table' has already run today. Exiting"
        exit 0;
    fi;
fi;

if [[ -z $force ]]; then
    # all process to run
    if [[ -f $PIDFILE ]]; then
        # checking if scheduler is already running
        log ERROR "Another scheduler is running for the same table ($scheduler_table). Exiting."
        exit 1;
    else
        # create the PID file
        touch $PIDFILE

        # create work file
        touch $WRK_TBL

        # reading scheduler table
        read_table

        # running all process from table
        run_all

        # wait for terminate all
        wait "all"

        log INFO "All process are terminated. Exiting"
        cleanup
    fi;
else
    # one process to force
    if [[ -z $process_name ]]; then
        # check if the process's name is given (with -f parameter)
        log ERROR "No process given"
        exit 1
    else
        log INFO "Forcing $process_name"

        # reading scheduler table
        read_table $process_name

        # force process
        force_process

        # wait for terminate the forced process
        wait

        log INFO "Process $process_name terminated. Exiting"
    fi;
fi;

# setting last run date
echo ${today} > ${SCH_DATA}/last_${scheduler_table}.txt;

exit 0;
