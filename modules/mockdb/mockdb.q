.mockdb.mInit:{`$()};

.mockdb.ipc:.sys.use`ipc;
.mockdb.log:.sys.use[`log;`MOCKDB];

.mockdb.iInit:{[cfg]
    .mockdb.log.info "Starting mockdb:",string cfg`pid;
    .mockdb.mbus: .sys.use`mbus;
    // ensure the process dies with its manager
    show cfg;
    .sys.use[`vital;cfg`pmanager_port];
    if[`tp=cfg`procType;
        .mockdb.log.info "notify subscribers";
        .mockdb.mbus.post (`pmanager`procType`source#cfg`pmanager),`host`port`subid!(.sys.host;.sys.port;`.mockdb.sub);
        .sys.use[`rmanager][`setHandlerAt][`.z.ps;`before`exec;`.mockdb.sub;`.mockdb.onSub];
        .sys.timer.new[][`interval;0D00:00:10][`fn;`.mockdb.pub]; // pub every 10 sec
        .mockdb.subs:();
    ];
 };

.mockdb.onSub:{
    if[not `.mockdb.sub~first x; :x];
    // (`.mockdb.sub;`sub_id)
    .mockdb.log.info "adding subscriber ",string x 1;
    .mockdb.subs,:enlist(.mockdb.ipc.get`current;x 1);
    :(`CANCEL;::);
 };