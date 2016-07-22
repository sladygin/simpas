# simpas - SIMPle Asynchronous Scheduler

## Description

Simpas is as simple asynchronous scheduler which lets execute a chain of jobs under given conditions and / or at a given date and time.

Simpas is released under GNU GENERAL PUBLIC LICENSE, Version 3. Please, see _license.txt_ for details.

## Requirements
Simpas needs Bash 4 or later to work.

## Installation and configuration
Copy _simpas.sh_, _setenv.sh_ and _logging.sh_ to a directory.

Define the variables in _setenv.sh_, according to your environment and your needs:

* **SCH\_LOOP_DELAY** - in seconds
	
	Delay between the loops which check if conditions are met. By default set to 30 seconds.
	
	> **Note** that setting this value to 60 seconds or more makes that there will be no guarantee that a job will execute exactly at given hour and minute.

* **SCH_TEMP** - temporary directory

* **SCH_LOG** - log directory  

* **SCH_TABLES** - the directory where the tables of jobs are saved

## Defining jobs
All jobs must be defined in a table of jobs. One table of jobs represents a chain. When simpas starts a chain, every job will be executed exactly once. The periodic jobs are not supported at this time.

Every table must be in a separated file. The table of jobs is a simple semicolon separated text.

The file must be placed in the directory defined by SCH_TABLES variable. The file extention must be _"tbl"_.

###The structure of the table
* **ID** - MANDATORY - job number in sequence, defines the order of execution.
* **Process code** - MANDATORY - the job code - free text, only letters and "_" are allowed.
* **Process name** - MANDATORY - the job name - free text.
* **Process executable** - MANDATORY - the command to be executed by the job _without_ its parameters.
* **Process options** - MANDATORY - the parameters of the command.
* **Year** - OPTIONAL - the year in which the job should be executed. Leave empty if the jub must be executed every year.
* **Month** - OPTIONAL - the month in which the job should be executed. Leave empty if the jub must be executed every month.
* **Day** - OPTIONAL - the day of month in which the job should be executed, optional. Leave empty if the jub must be executed every day.
* **Hour** - OPTIONAL - the hour at which the job should be executed. 
	* If set, the job will execute at any time during the given hour
* **Minute** - OPTIONAL - the minute at which the job should be executed. 
	* If set, the job will execute at any hour and at given minute

	If both **Hour** and **Minute** are set, the job will be executed at that exact time.
 
* **Periodicity** - OPTIONAL - not operationnal yet, IGNORED (see TODO list).
* **Start condition** - OPTIONAL - the condition that must be met in order to start the job. Even if **Hour** and **Minute** is reached, the job will not start untill this condition is met. If left empty, the job will start as soon as:
	* **Hour** and **Minute** is reached (if set), or
	*  the simpas is started (if no other condition is defined)
* **Output condition** - MANDATORY - the condition that will be set when the job terminates correctly.
* **Exit code** - MANDATORY - the code that the command is expected to return if terminates correctly.
* **Log file** - OPTIONAL - if set, the output of the command will be redirected to this file.

###Example
The file _tables.tbl_ is an example of a simple chain of jobs. You may run it executing:

> simpas.sh -t tables.tbl 

1. First, the JOB\_1 will start. The command is

	> sleep 30

	and is expected to return 0 and to set the condition JOB\_1_OK when executed correctly.

2. The second job JOB_2 hasn't any start condition, but it has a time condition. Due to this constraint, it will start at 20:30 independently from any other jobs. The command is:

	> test.sh

	When executed correctly, it will return the code 255 and it will set the condition JOB\_2_OK.

3. The third job

	> sleep 30

	will start as soon as the JOB_1 terminates without errors and the condition JOB_1_OK is set. There is no time restriction.

	When executed correctly, it will return the code 0 and will set the condition JOB\_3_OK.


## Running jobs
Usage: simpas.sh [options]

Options are:

**-t** <scheduler table\> - MANDATORY - table of jobs to run, it is the filename without the extension, for example _-t tables_ if the file is _tables.tbl_

**-f** <process name\> - OPTIONAL - force given process to run from the given chain

> This option may be useful when one of the jobs didn't set a condition thus blocking the execution of other jobs and the chain to be finished.   

**-v** - verbose - OPTIONAL - all messages will be shown on the console instead of the log file

**-s** - simulate - OPTIONAL - simulates the scheduler run, no command will be executed

When all jobs are terminated simpas exists with code 0.

> _Simpas is not a daemon_ that turns until it gets killed. It terminates as soon as all jobs from the chain are executed.

> **Note** that it is possible that it will not terminate if one or more jobs cannot be executed because some of start conditions are not met.

Many instances of simpas may be run at the same time only if the jobs tables are different. 

### Examples
**simpas.sh -t tables** - runs the chain defined in _tables.tbl_ file

**simpas.sh -t tables -s** - runs the chain defined in _tables.tbl_ file in the simulation mode, no command will be really executed

**simpas.sh -t tables -f JOB_2** - forces the JOB\_2 to run disregarding if the run conditions are met or not 

## Known issues and TODO list
### Known Issues
1. Sometimes simpas doesn't terminate after all jobs are completed

### TODO
1. Add multiple start conditions
2. Make the periodic jobs working
