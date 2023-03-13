.mod.mInit:{
    ipc: .sys.use`ipc;
    ipc[`addPlugin]`.mod.pInit;
    `$()
 };

.mod.pInit:{[ns]
    .mod.outbound: ` sv ns,`outbound;
    .mod.ipc: ns;
    .mod.smartHelp: enlist[`newconn]!(),` sv ns,`newConn;
    / add columns
    @[ns;`outbound;{![x;();0b;`reconnectSchedule`reconnectAttempts!(();count[x]#0)]}];
    / install handlers
    on: ns[`event]`onExt;
    on[`outbound.disconnect;`ipc.reconnect;.mod.onStart];
    on[`outbound.connect_failed;`ipc.reconnect;.mod.onStart];
    on[`outbound.add;`ipc.reconnect;.mod.onAdd];
    / extend newconn
    ns[`newConn][`extend][.mod.__mod__.name;.mod.cfg.newconn];
 };

.mod.onAdd:{x:x`data; if[.mod.outbound[x;`autoConnect]; .mod.startReconnect x];};
.mod.onStart:{.mod.startReconnect x`data};

.mod.startReconnect:{[n]
    / do nothing, if handle is ok or there is no schedule.
    if[(0=count sch:.mod.outbound[n;`reconnectSchedule])|not null .mod.outbound[n;`handle]; :()];
    / if there is already a job just reset the counter
    .[.mod.outbound;(n;`reconnectAttempts);:;0];
    jname: `$"ipc.reconnect:",string n;
    if[not (::)~.sys.timer.tryGet jname; :()];
    / start attempts
    .sys.timer.new[][`name;jname][`group;`ipc.reconnect][`fn;`.mod.tryReconnect][`args;(n;jname)][`delay;sch 0]`start;
 };

.mod.tryReconnect:{[n;jname]
    / if handle is not null or someone changed the schedule return
    if[(0=count sch:.mod.outbound[n;`reconnectSchedule])|not null .mod.outbound[n;`handle]; :()];
    / try to reconnect
    if[null h:.mod.ipc[`connectInt][n;.mod.outbound n];
        / reschedule
        .[.mod.outbound;(n;`reconnectAttempts);1+];
        at: .mod.outbound[n;`reconnectAttempts];
        if[null del:sch at&count[sch]-1; :()]; / null interval = stop
        .sys.timer.new[][`name;jname][`group;`ipc.reconnect][`fn;`.mod.tryReconnect][`args;(n;jname)][`delay;del]`start;
        :();
    ];
    .mod.ipc[`onConnect][n;h];
 };