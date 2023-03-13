.mod.mInit:{
    ipc: .sys.use`ipc;
    ipc[`addPlugin]`.mod.pInit;
    `$()
 };

.mod.pInit:{[ns]
    .mod.outbound: ` sv ns,`outbound;
    .mod.inbound: ` sv ns,`inbound;
    / add stats columns
    @[ns;`outbound;{![y;();0b;x]} sc:`lastIn`lastOut`numIn`numOut`sizeIn`sizeOut!(0Np;0Np;0;0;0;0)];
    @[ns;`inbound;{![y;();0b;x]}sc];
    / install handlers
    rman: .sys.use`rmanager;
    rman[`setHandlerAt][`.z.pg;`before`start;`ipcIn;.mod.onInMsg];
    rman[`setHandlerAt][`.z.ps;`before`start;`ipcIn;.mod.onInMsg];
    rman[`setHandlerAt][`.z.pg;`after`end;`ipcOut;.mod.onOutMsg];
    rman[`setHandlerAt][`.z.ws;`before`start;`ipcIn;.mod.onInMsg];
    / install as first before an attempt to send
    ns[`handlers][`addAt][`outbound.send;`first;`stats;.mod.onSend];
    ns[`handlers][`addAt][`outbound.asend;`first;`stats;.mod.onSend];
    ns[`handlers][`addAt][`outbound.wssend;`first;`stats;.mod.onSend];
    / update default
    @[ns;`defaultOutbound;{{[x;y] x[],`numIn`numOut`sizeIn`sizeOt!(0;0;0;0)}x}];
 };

.mod.onInMsg:{[x]
    sz: -22!msg`msg;
    update lastIn: .sys.P[], numIn+1, sizeIn+sz from .mod.outbound where handle=.z.w;
    update lastIn: .sys.P[], numIn+1, sizeIn+sz from .mod.inbound where handle=.z.w;
    x
 };
.mod.onOutMsg:{[x]
    sz: -22!msg`msg;
    update lastOut: .sys.P[], numOut+1, sizeOut+sz from .mod.outbound;
    update lastOut: .sys.P[], numOut+1, sizeOut+sz from .mod.inbound;
    x
 };
.mod.onSend:{[msg]
    sz: -22!msg`msg;
    update lastOut: .sys.P[], numOut+1, sizeOut+sz from .mod.outbound where handle=msg`handle;
    update lastOut: .sys.P[], numOut+1, sizeOut+sz from .mod.inbound where handle=msg`handle;
    msg
 };