.mod.mInit:{
    ipc: .sys.use`ipc;
    ipc[`addPlugin]`.mod.pInit;
    `$()
 };

.mod.pInit:{[ns]
    .mod.outbound: ` sv ns,`outbound;
    .mod.inbound: ` sv ns,`inbound;
    .mod.smartHelp: enlist[`newconn]!(),` sv ns,`newConn;
    .mod.ipc: ns;
    / add columns
    @[ns;`outbound;{![x;();0b;(1#`disconnectTimeout)!1#0Nn]}];
    @[ns;`inbound;{![x;();0b;(1#`disconnectTimeout)!1#0Nn]}];
    / add timer job
    .sys.timer.new[][`name;`ipc.disconnect][`fn;`.mod.checkDisconnect][`interval;0D00:01]`start;
    ns[`newConn][`extend][.mod.__mod__.name;.mod.cfg.newconn];
 };

.ipc.checkDisconnect:{
    .mod.ipc[`outboundDisconnect] each exec name from .ipc.outbound where .sys.P[]<-0Wp^lastConnect+disconnectTimeout, not null handle;
    .mod.ipc[`inboundDisconnect] each exec name from .ipc.inbound where alive, .sys.P[]<-0Wp^lastConnect+disconnectTimeout;
 };