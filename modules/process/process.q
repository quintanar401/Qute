.proc.log:.sys.use[`log;`PROC];

.proc.mInit:{ .proc.init[]; `$()};

.proc.init:{
    if[not all `pmanager`pid in key .sys.opt; '"bad config"];
    if[.sys.tinterval=0; .proc.log.err "timer is required"; '"timer"];
    .proc.id:`$first .sys.opt`pid;
    .proc.pmanager:`$first .sys.opt`pmanager;
    .proc.log.info "Init process ",string[.proc.id]," from ",string .proc.pmanager;
    .proc.mbus:.sys.use`mbus;
    // pmanager will send us cfg
    .proc.mbus.sub `pmanager`process`cmd`cb!(.proc.pmanager;.proc.id;::;`.proc.upd);
    .proc.mbus.post `pmanager`process`event`port!(.proc.pmanager;.proc.id;`started;.sys.port); // send port for PM to detect correct processes
    .sys.timer.new[][`name;`.proc.timeout][`fn;`.proc.timeout][`delay;0D00:05]`start;
    .proc.isInited: 0b;
 };


.proc.upd:{[msg]
    if[`setCfg=c:msg`cmd;
        if[.proc.isInited; :.proc.log.info "ignore setCfg cmd"];
        .proc.config: (msg`data),`pid`pmanager!(.proc.id;.proc.pmanager);
        .proc.log.info "executing setCfg cmd";
        if[.sys.port<>.proc.config`port; .sys.test:1b];
        if[not .sys.test;.proc.mbus.post `pmanager`process`event!(.proc.pmanager;.proc.id;`configured)];
        // do not initiate start up inside .z.ps handler
        :.sys.timer.new[][`name;`.proc.start][`fn;`.proc.startUp][`delay;0D00:00:00.1]`start;
    ];
    // setTimeout, setTimer, stop
 };

.proc.startUp:{
    // main is a mandatory param
    eh:{[ex;st]
        .proc.log.err "init failed with ",ex,", stack:\n",.Q.sbt st;
        if[not .sys.test;
            .proc.mbus.post `pmanager`process`event!(.proc.pmanager;.proc.id;`failed);
            .proc.log.err "exiting...";
            :.sys.exit -1;
        ];
    };
    .Q.trp[{.sys.use[;.proc.config] each .proc.config`main};::;eh];
    if[not .sys.test; .proc.mbus.post `pmanager`process`event!(.proc.pmanager;.proc.id;`inited)];
    .sys.timer.get[`.proc.timeout]`stop;
 };

.proc.timeout:{.proc.log.err "the process was not started properly, exiting..."; .sys.exit 1};