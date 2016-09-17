# simpas - SIMPle Asynchronous Scheduler

## Description

Simpas is as simple asynchronous scheduler which executes a chain of jobs
under given conditions and / or at a given date and time.

Simpas is released under GNU GENERAL PUBLIC LICENSE, Version 3. Please,
see _license.txt_ for details.

## Requirements
Simpas needs Bash 4 or later to work.

## Installation and configuration
Copy _simpas.sh_, _setenv.sh_ and _logging.sh_ to a directory.

Define the variables in _setenv.sh_, according to your environment and your
needs:

* **SCH\_LOOP_DELAY** - in seconds

	Delay between the checks if conditions are met. Set to 30 seconds
	by default.

	> **Note** that setting this value to 60 seconds or more makes that there
	will be no guarantee that a job will be executed exactly at given hour
	and minute.

* **SCH_TEMP** - temporary directory

* **SCH_LOG** - log directory

* **SCH_TABLES** - the directory where the tables of jobs are kept

## Defining jobs
All jobs must be defined in a table of jobs. One table of jobs represents
a chain. When simpas starts a chain, every job will be executed exactly once.
Periodic jobs are not supported at this time.

Every table must be saved in a separated file. The table of jobs is a simple
semicolon separated text.

> **Note** that ";" semicolon is a special character used as separator.
It must not be used as a part of any parameter below.

The file must be placed in the directory defined by SCH_TABLES variable.
The file extention must be _"tbl"_.

###The structure of the table
* **ID** - MANDATORY - sequence job number in a chain, defines the order
of execution.
* **Process code** - MANDATORY - the job code - only letters and "_"
(undescore) are allowed.
* **Process name** - MANDATORY - the job name - free text.
* **Process executable** - MANDATORY - the command to be executed by the job
_without_ its parameters.
* **Process options** - MANDATORY - the parameters of the command.
* **Year** - OPTIONAL - the year in which the job should be executed. Leave
it empty if the jub should be executed at any time.
* **Month** - OPTIONAL - the month in which the job should be executed. Leave
empty if the jub should be executed at any time.
* **Day** - OPTIONAL - the day of month in which the job should be executed,
optional. Leave empty if the jub should be executed at any time.
* **Day of Week** - OPTIONAL - the day of week in which the job should be executed. Values range from 1 to 7, 1 is Monday. Leave empty if the jub should be executed at any day.
* **Hour** - OPTIONAL - the hour at which the job should be executed.
	* If set, the job will execute at any time during the given hour
* **Minute** - OPTIONAL - the minute at which the job should be executed.
	* If set, the job will execute at any hour and at given minute

	If both **Hour** and **Minute** are set, the job will be executed at that
	exact time.

* **Periodicity** - OPTIONAL - not supported yet, IGNORED (see TODO list).
* **Start condition** - OPTIONAL - the condition that must be met in order
to start the job. Even if **Hour** and **Minute** is reached, the job will not
start untill this condition is met. If left empty, the job will start as soon as:
	* **Hour** and **Minute** is reached (if set), or
	*  the simpas is started (if no other condition is defined)
* **Output condition** - MANDATORY - the condition that will be set when the job
terminates correctly.
* **Exit code** - MANDATORY - the code that the command is expected to return
if terminates correctly. If a command returns a different code, the job is
considered failed, the **Output condition** will not be set
* **Log file** - OPTIONAL - if set, the output of the command will be redirected to this file. If not set, the output will be redirected to the simpas' log.

###Example
The file _tables.tbl_ is an example of a simple chain of jobs. You may run it
executing:

> simpas.sh -t tables.tbl

1. First, the JOB\_1 will start. The command is

	> sleep 30

	It is expected to return 0 and to set the condition JOB\_1_OK when executed
	correctly.

2. The second job JOB_2 hasn't any start condition, but it has a time restriction.
Due to this constraint, it will start at 20:30 independently from any other jobs.
The command is:

	> test.sh

	When executed correctly, it will return the code 255 and it will set
	the condition JOB\_2_OK.

3. The third job

	> sleep 30

	will start as soon as the JOB_1 terminates without errors (the condition
	JOB_1_OK is set). There is no time restriction.

	When executed correctly, it will return the code 0 and will set
	the condition JOB\_3_OK.


## Running jobs
Usage: simpas.sh -t _table_ [options]

**-t** <scheduler table\> - MANDATORY - the table of jobs to run, it is
the filename without the extension, for example _-t tables_ if the file name
is _tables.tbl_

Options are:

**-f** <process name\> - OPTIONAL - force one process to run

> This option may be useful when one of the jobs didn't set a condition thus
blocking the execution of other jobs and the whole chain to be finished.

**-v** - verbose - OPTIONAL - all messages will be shown on the console instead
of saved in a log file

**-s** - simulate - OPTIONAL - simulates the scheduler run, no command will
be executed

When all jobs are terminated simpas exists with code 0.

> _Simpas is not a daemon_ that turns until it gets killed. It terminates
as soon as the last job from the chain is executed.

> **Note** that it is possible that a chain will not terminate if one or more jobs
cannot be executed because some of its start conditions are not met.

Many instances of simpas may be run at the same time with different job tables.

### Examples
**simpas.sh -t tables** - runs the chain defined in _tables.tbl_ file

**simpas.sh -t tables -s** - runs the chain defined in _tables.tbl_ file in the
simulation mode, no command will be really executed

**simpas.sh -t tables -f JOB_2** - forces the JOB\_2 to run no matter if its run
conditions are met or not

## Known issues and TODO list
### Known Issues
1. Sometimes simpas doesn't terminate after all jobs are completed

### TODO
1. Add multiple start conditions
2. Make the support for periodic jobs
