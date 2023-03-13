## Module timer

Allows you to create new timer jobs and manipulate the existing jobs. The module is a singleton. By default it is loaded into `.sys.timer` variable. The module itself doesn't start the q timer or change its interval.

### timer.new

Get a fresh newjob smart pointer.
```Rust
timer.new[][`delay;00:01][`fn;{...}]`start
```

### timer.get timer.tryGet

Get an existing timer job. Returns a timer job smart pointer or throws an exception/returns (::) if the target doesn't exist (get vs tryGet).

Accepts one argument:
* long/int - job's unique ID.
* symbol - job's unique name.
* (::) - return all jobs.

### newjob settings

To get a new job:
```
tm:.sys.use`timer;

jobCfg: tm.new[]; // blank new
jobCfg: tm.get[`name]`clone; // get by name and clone
jobCfg: tm.get[jID]`clone; // get by ID and clone
```

Types of jobs:
* Once. You should set at least `fn`, `delay` or `sTime`.
* Regular. You should set at least `fn`, `delay` or `sTime`, `interval`. Other usefull params: `eTime`, `relativeInt`, `strict`.
* Until. The job is executed until it returns some specific value. Similar to regular but can stop before `eTime`.

You can provide additional params:
* args - list of arguments.
* name - unique name for audit or if you want to make changes to a running job.
* group - non unique name to group jobs together.

To start a job (if timer is enabled):
```
job: jobCfg`start; // a handle to the job will be returned
job`id; // it can be used to get its id, stop/suspend it and etc
```

#### fn

Type: function or symbol. Function to execute.
```
jobCfg: jobCfg[`fn;{1+1}];
jobCfg: jobCfg[`fn;`.some.fn];
```

#### delay

Type: timespan, time. Optional. Delay before `fn` is executed the first time. `sTime` is used if not specified.
```
jobCfg: jobCfg[`delay;0D00:10];
```

#### interval

Type: timespan, time. Opional. Interval between runs. The first time is taken from `sTime`, `delay`, `interval`.
```
jobCfg: jobCfg[`interval;0D00:10];
```

#### sTime

Type: time, timespan, date, datetime. Optonal. Start date + time for the job. Date is today by default, time is 00:00 by default.
```
jobCfg: jobCfg[`sTime;2020.10.10D10:10];
```

#### eTime

Type: time, timespan, date, datetime. Optonal. End date + time for the job. Date is today by default, time is 00:00 by default.
```
jobCfg: jobCfg[`eTime;2020.10.10D10:10];
```

#### args

Type: list. Optional, Arguments for `fn`.
```
jobCfg: jobCfg[`args;(10:00;`.L)];
```

#### until

Type: any object. Optional. Run the job until it returns the provided value (or `eTime`).
```
jobCfg: jobCfg[`until;1b];
```

#### relativeInt

Type: bool. Optional. If true(default) schedule the next run relative to the current time. Use the start time otherwise.
```
jobCfg: jobCfg[`relativeInt;0b];
```

#### strict

Type: bool. Optional. By default if `sTime` is less than now the job will be executed immediately. Set to true to prevent this. The tolerance interval is 1 second.
```
jobCfg: jobCfg[`strict;1b];
```

#### id

Type: long. Readonly. The unique ID of the job.
```
id: jobCfg`id;
```

#### name

Type: string, symbol. Optional. You can assign a readable unique name to the job.
```
jobCfg: jobCfg[`name;`calculate_open_prices_OQ];
```

#### group

Type: string, symbol. Optional. You can group jobs together.
```
jobCfg: jobCfg[`group;`calculate_open_prices];
```

#### cb

Type: function, symbol. Optional. Callback to call when the job is done.
```
jobCfg: jobCfg[`cb;.mod.startSomethingElse];
```

#### start

Action. Add the job to the queue. It doesn't enable the timer.

### job settings

You can get a handle for a job by using its name, group or id and use it to control it.
```
tm: .sys.use`timer;
tm.get[`my_job]`stop;
```

#### start

Action. Start the job after it was suspended.
```
job`start;
```

#### stop

Action. Stop the job permanently, remove it from the queue.
```
job`stop
```

#### suspend

Action. Suspend the job. It can be started again using `start`.
```
job`suspend
```

#### clone

Action. Copies the job's config params and returns a new new job handle. The config is saved at the moment when the job handle is created so all later changes are lost.
```
cfg:job`clone;
```

#### run

Action. Run the job right now. If it is a regular/until job it will be rescheduled relative to this time.
```
job`run;
```

#### runOnce

Action. Run the job right now out of order. The job will not be rescheduled even if it is a once job.
```
job`runOnce;
```