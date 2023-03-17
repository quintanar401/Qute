.mockdb.mInit:{`$()};

.mockdb.ipc:.sys.use`ipc;
.mockdb.log:.sys.use[`log;`MOCKDB];

.mockdb.iInit:{[cfg]
    .mockdb.log.info "Starting mockdb:",string cfg`pid;
    .mockdb.mbus: .sys.use`mbus;
    .mockdb.config: cfg;
    // ensure the process dies with its manager
    show cfg;
    .sys.use[`vital;cfg`pmanager_port];
    if[`tp=p:cfg`procType;
        .mockdb.log.info "notify subscribers";
        .mockdb.mbus.post (`pmanager`procType`source#cfg),`host`port`subid!(.sys.host;.sys.port;`.mockdb.sub);
        .sys.use[`rmanager][`setHandlerAt][`.z.ps;`before`exec;`.mockdb.sub;`.mockdb.onSub];
        .sys.timer.new[][`interval;0D00:00:10][`fn;`.mockdb.pub]`start; // pub every 10 sec
        .mockdb.subs:();
    ];
    if[p in `rdb`pdb;
        .mockdb.log.info "try to subscribe to tp";
        .mockdb.mbus.sub `pmanager`procType`source`cb!(cfg`pmanager;`tp;cfg`source;`.mockdb.trySub);
    ];
 };

// tp server
.mockdb.onSub:{
    if[not `.mockdb.sub~first x; :x];
    // (`.mockdb.sub;`sub_id;`name)
    .mockdb.log.info "adding subscriber ",string x 2;
    .mockdb.subs,:enlist(c:.mockdb.ipc.get`current;x 1;x 2);
    c[`onClose;`.mockdb.remSub];
    // send the current status
    c[`asend;(x 1;`start;10000)];
    :(`CANCEL;::);
 };
.mockdb.pub:{
    .mockdb.log.info "Publish data";
    {x[0][`asend;(x 1;`upd;::)]} each .mockdb.subs;
 };
.mockdb.remSub:{.mockdb.subs:.mockdb.subs where {x[0]`isAlive} each .mockdb.subs}; // once a day event

// tp client
.mockdb.tps:(0#`)!();
.mockdb.trySub:{[msg]
    .mockdb.log.info "Found tp: ",.Q.s1 msg;
    if[(id:msg`subid) in key .mockdb.tps; if[.mockdb.tps[id]`isAlive; .mockdb.log.info "already subscribed"; :()]];
    c:.mockdb.ipc.new update name:(`$"tpclient:",string id) from `host`port#msg;
    .mockdb.log.info "connect";
    .mockdb.tps[id]:c:c`open;
    c[`setHandler;`.mockdb.upd];
    .mockdb.log.info "subscribe";
    c[`asend;(id;`.mockdb.upd;.mockdb.config`pid)];
 };
.mockdb.upd:{[isS;ptr;msg]
    if[not `.mockdb.upd~first msg; :()];
    if[`start=msg 1; .mockdb.log.info "connected to tp"];
    if[`upd=msg 1; .mockdb.log.info "got data"];
 };