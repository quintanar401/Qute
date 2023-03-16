.timer.newSmart:();
.timer.jobSmart:();
.timer.jobs:([] id:(),0; name:`; grp:`; sTime:0Wp; eTime:0Wp; interval:0Wn; active:0b; cfg:(::); cancelled:0b);
.timer.status:([] id:(),0; name:`; grp:`; sTime:0Wp; eTime:0Wp; err:0b; info:(::));
.timer.jID:0;
.timer.log: .sys.use[`log;`TIMER];

.timer.mInit:{[]
    if[not all `newjob`job in key .timer.cfg; '"invalid cfg"];
    .timer.newSmart: .sys.use[`smart;`newjob;.timer.cfg.newjob];
    .timer.jobSmart: .sys.use[`smart;`job;.timer.cfg.job];
    rman: .sys.use`rmanager;
    rman[`setHandler][`.z.ts;`timer;.timer.exec];
    :`new`get`tryGet;
 };

.timer.new:{ .timer.newSmart.new enlist[`id]!(),"j"$.z.P };

.timer.getByID:{exec first i from .timer.jobs where id=x, not cancelled};

.timer.tryGet:{
    if[-11=t:type x;
        if[null r: exec first id from .timer.jobs where name=x, i>0, not cancelled; :(::)];
        : .timer.jobSmart.new enlist[`id]!(),"j"$r;
    ];
    if[t in -6 -7h;
        if[(x=0)|not any (x:"j"$x) in exec id from .timer.jobs where not cancelled; :(::)];
        : .timer.jobSmart.new enlist[`id]!(),x;
    ];
    if[x~(::); : select from .timer.jobs where not cancelled];
    '"type"
 };

.timer.get:{ if[(::)~r: .timer.tryGet x; '"Not found"]; r};

.timer.start:{[cfg]
    if[all f:`delay`sTime in key cfg; '"You can't use delay and sTime together"];
    if[(not`interval in key cfg)&not any f; '"Provide sTime or delay for one time jobs"];
    // sTime/eTime
    sTime: $[f 0;.sys.P[]+cfg`delay;f 1;cfg`sTime;.sys.P[]+cfg`interval];
    if[not -12=type sTime; sTime:.sys.D[]+sTime];
    eTime: {$[-12=type x;x;.z.D+x]} cfg`eTime;
    // jID
    id: .timer.jID+:1;
    // name/grp
    name: cfg`name; grp: cfg`group;
    if[not null name; if[name in exec name from .timer.jobs where not cancelled; '"Job with name ",string[name]," already exists"]];
    // interval
    int: $[`interval in key cfg;cfg`interval;0Nn];
    // check strict vs regular
    if[cfg[`strict]&(sTime<.sys.P[]-0D00:01);
        if[null int;
            .timer.log.warn "Job is scheduled to start before the current time with strict=1b:\n",.Q.s cfg;
            : ();
        ];
        sTime: $[cfg`relativeInt;.sys.P[];int+t-((t:.sys.P[])-sTime) mod "j"$int];
    ];
    `.timer.jobs upsert (id;name;grp;sTime;eTime;int;1b;cfg;0b);
    id
 };

.timer.updateStatus:{[j;tm;err;inf]
    if[j[`cfg]`logStatus;
        `.timer.status upsert (j`id`name`grp),(tm;.sys.P[];err;inf);
        if[100000<count .timer.status; .timer.status: -50000#.timer.status];
    ];
 };

.timer.errByName:(0#`)!0#.z.P;
.timer.logErr:{[id;tm;exc;bt]
    j: .timer.jobs id;
    // do not log errors too often
    if[0D00:01>1D^(p:.sys.P[])-.timer.errByName n:j`name; :(0b;exc)];
    .timer.errByName[n]:p;
    .timer.log.err "Job with id=",string[id]," failed with ",exc,"\n",.Q.s j;
    .timer.log.err "Backtrace:\n",bt:.Q.sbt bt;
    (0b;exc,"\n",bt)
 };

.timer.exec:{
    if[0=count jobs: exec i from .timer.jobs where .sys.P[]>sTime, active, not cancelled; :()];
    {.Q.trp[.timer.execJob x;t;.timer.logErr[x;t:.sys.P[]]]} each jobs;
    delete from `.timer.jobs where cancelled;
 };

.timer.execJob:{[jid]
    j: .timer.jobs jid; c: j`cfg; tm: .sys.P[];
    if[j`cancelled; :()];
    // remove one time jobs at the start to allow rescheduling
    add: not null int:j`interval;
    if[not add; .timer.jobs[jid;`cancelled]:1b];
    r:.Q.trp[{(1b;x[`fn] . (),x`args)};c;.timer.logErr[jid;tm]];
    // reload params - they could have been changed, the job could have been cancelled
    j: .timer.jobs jid; c: j`cfg;
    add: add&not j`cancelled;
    if[add;
        if[j[`eTime]>=sTime: $[j`relativeInt;.sys.P[];j`sTime] + int;
            add: $[`until in key c; r[0]&not r[1]~c`until; 1b];
            if[add; .timer.jobs[jid;`sTime]: sTime];
        ];
    ];
    if[not add; .timer.jobs[jid;`cancelled]:1b];
    .timer.updateStatus[j;tm;r 0;$[r 0;"";r 1]];
 };

.timer.getJob:{[id] if[null j:.timer.getByID id; '"Job has finished"]; j};

// Return a new newjob ptr using the current params
.timer.clone:{[cfg]
    j: .timer.getJob cfg`id;
    : .timer.newSmart.new ` _ .timer.jobs[j;`cfg],enlist[`id]!(),"j"$.z.P;
 };

.timer.suspend:{[cfg]
    j: .timer.getJob cfg`id;
    .timer.jobs[j;`active]: 0b;
 };

.timer.resume:{[cfg]
    j: .timer.getJob cfg`id;
    .timer.jobs[j;`active]: 1b;
 };

.timer.stop:{[c] update cancelled:1b from `.timer.jobs where id=c`id };

.timer.run:{[cfg]
    .timer.execJob[.timer.getJob cfg`id;.sys.P[]]
 };

.timer.runOnce:{[cfg]
    j:.timer.getJob cfg`id; c: .timer.jobs[j;`cfg];
    c[`fn] . (),c`args
 };