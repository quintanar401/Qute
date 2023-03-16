.ipc.log: .sys.use[`log;`IPC];
.ipc.event: .sys.use`event; // generic events
.ipc.evOnConnect: .sys.use`event; // for handle based outbound events

.ipc.cfg.connectionTimeout:60000; / 60 sec, 
.ipc.cfg.requestTimeout:60000;
.ipc.cfg.logError:1b;
.ipc.cfg.unix:1b;

.ipc.smartHelp:`newconn`conn!`.ipc.newConn`.ipc.conn;

/ handle - handle
/ name: unique ID host:port by default
/ host, port, user, password - conn details
/ connectionTimeout - timeout for hopen (10000 by default)
/ unix - use unix sockets if possible
/ ssl - open a secure connection (prefered over unix)
/ lastConnect/lastDisconnect - last connect/disconnect time
/ cb - callback for async calls
/ logError - log an error on disconnect/failed connect, use outbound.disconnect for more functionality
/ auto::avoidDeadlock - try to avoid a deadlock if another process can try to connect to this one at the same time by spacing connect attempts using port numbers
.ipc.outbound:([name:0#`] handle:0#0i; host:0#`; port:0#0i; user:0#`; password:(); connectionTimeout:0#0; requestTimeout:0#0;
    unix:0#0b; ssl:0#0b; lastConnect:0#0p; lastDisconnect:0#0p; cb:(); logError:0#0b);

/ handle - handle
/ alive - connected or not
/ name - can be registered via ("ipc.register";name) async msg
/ host - handle's hostname
/ user - connected as user
/ ws - websocket or not
/ lastConnect/Disconnect - time of the event
/ logError - log or not an error on disconnect/failed connect
.ipc.inbound:([handle:0#0i] alive:0#0b; name:0#`; host:0#`; user:0#`; ws:0#0b; lastConnect:0#0p; lastDisconnect:0#0p;
    cb:(); cl:(); logError:0#0b);
.ipc.inbound[0i]:(1b;`default;`;`;0b;0Np;0Np;();0b); // 0 handle

/ ***************
/ newconn actions
/ ***************

.ipc.open:{[conn]
    / Add a new connection and try to connect. If autoConnect is 1b attempts will continue even if this function fails.
    / @returns smart Connection smart ptr on success.
    / @throws connectionFailed if fails.
    n: .ipc.initOutbound .ipc.newConn.validate conn;
    if[null h:.ipc.connectInt[nm;.ipc.outbound nm:n`name];
        .ipc.event.fire[`outbound.connect_failed;nm];
        '"connectionFailed";
    ];
    .ipc.onConnect[nm;h];
    :.ipc.conn.new enlist[`name]!enlist nm;
 };

.ipc.add:{[conn]
    / Add a new connection, do not connect right now. If autoConnect is 1b connect attempts will start according to the schedule.
    / @retuns smart Connection smart ptr.
    c: .ipc.initOutbound .ipc.newConn.validate conn;
    .ipc.event.fire[`outbound.add;c`name];
    c
 };

.ipc.connExists:{[conn]
    cfg:.ipc.updName .ipc.newConn.validate conn;
    (cfg`name) in (0!.ipc.outbound)`name
 };

.ipc.is0:{(x[`host]in`localhost,.sys.host)&.sys.port=x`port};

.ipc.defaultOutbound:{(first 0#.ipc.outbound),`logError`unix`connectionTimeout`requestTimeout`cb!(.ipc.cfg.logError;.ipc.cfg.unix;.ipc.cfg.connectionTimeout;.ipc.cfg.requestTimeout;())};
.ipc.updName:{[cfg] if[null cfg`name; cfg[`name]: `$string[cfg`host],":",string[cfg`port],$[null u:cfg`user;"";":",string u]]; cfg};
.ipc.initOutbound:{[cfg]
    cfg:.ipc.updName cfg;
    if[(n:cfg`name) in (0!.ipc.outbound)`name; '"connectionExists"];
    default: .ipc.defaultOutbound[];
    .ipc.outbound[n]: default,(key[default] inter key cfg)#cfg;
    if[`onConnect in key cfg; $[-11=type e:cfg`onConnect;.ipc.evOnConnect.onExt[n;e;e];.ipc.evOnConnect.onExt[n;`default;e]]];
    .ipc.conn.new enlist[`name]!(),n
 };

.ipc.connectInt:{[name;cfg]
    / Connect to a remote server with a timeout. Returns an int handle, null if there was an error.
    / Expects a dictionary with fields: host(symbol), port(number), user(symbol, can be null), password(string, can be empty)
    /   ssl(bool, 1b for secure connection), unix(bool, use unix domain sockets), connectionTimeout(long, timeout).
    conn:string[cfg`host],":",pconn:string[cfg`port],$[null u:cfg`user;"";":",string u];
    conn:$[cfg`ssl;":tcps://",conn;(cfg[`host]in``localhost)&cfg`unix;":unix://",pconn;":",conn];
    pwd:$[null u;"";$[count p:cfg`password;":",p;""]];
    sconn:conn,$[count pwd;":***";""];
    to:$[null to:cfg`connectionTimeout;.ipc.cfg.connectionTimeout;to];
    .ipc.log.info "Opening connection ",$[null name;sconn;string[name],"[",sconn,"]"]," with timeout ",string to;
    r:@[hopen;(conn,pwd;to);::];
    if[10=type r;
        $[cfg`logError;.ipc.log.err;.ipc.log.info] "Connection failed with ",r;
        :0Ni;
    ];
    if[r=0; '"0 handle"];
    .ipc.log.info "handle: ",string r;
    r
 };

/ Connect to a server directly. Returns a raw handle or null.
.ipc.connect:{[cfg] .ipc.connectInt[`] (`host`port`user`password`ssl`unix`connectionTimeout!(`localhost;0;`;"";0b;0b;.ipc.cfg.defaultTimeout)),cfg};

.ipc.startConnect:{[n]
    / do nothing, if handle is ok
    if[not null h:.ipc.outbound[n;`handle]; :h];
    / start reconnect attempts in case of an error
    if[null h:.ipc.connectInt[n;.ipc.outbound n];
        .ipc.event.fire[`outbound.connect_failed;n];
        :0Ni;
    ];
    .ipc.onConnect[n;h];
    : h;
 };

.ipc.onConnect:{[n;h]
    isFirst: null .ipc.outbound[n;`lastConnect];
    .ipc.outbound[n;`handle`lastConnect]: (h;.sys.P[]);
    .ipc.event.fire[`outbound.reconnect`outbound.connect isFirst;n];
    .ipc.evOnConnect.fireExt[n;`name`status!(n;1b)];
 };

.ipc.onOutboundDisconnect:{[n]
    .ipc.outbound[n;`handle`lastDisconnect]:(0Ni;.sys.P[]);
    .ipc.event.fire[`outbound.disconnect;n];
    .ipc.evOnConnect.fireExt[n;`name`status!(n;0b)];
 };

.ipc.onInboundDisconnect:{[h]
    .ipc.inbound[h;`alive`lastDisconnect`cb`cl]:(0b;.sys.P[];();());
    .ipc.event.fire[`inbound.disconnect;h];
 };

.ipc.outboundDisconnect:{[n]
    if[null h:.ipc.outbound[n;`handle]; :()];
    .ipc.log.info "Disconnecting ",string[n],"[",string[h],"]";
    @[hclose;h;{.ipc.log.err "Disconnect failed with ",x; 'x}];
    .ipc.onOutboundDisconnect n;
 };

.ipc.inboundDisconnect:{[h]
    if[not (hh:.ipc.inbound h)`alive; :()];
    .ipc.log.info "Disconnecting ",string[$[null n:hh`name;hh`host;n]],"[",string[h],"]";
    @[hclose;h;{.ipc.log.err "Disconnect failed with ",x;'x}];
    .ipc.onInboundDisconnect h;
 };

/ get a smart ptr for the current .z.w handle
.ipc.getCurr:{[]
    if[(h:.z.w) in (0!.ipc.inbound)`handle;
        :.ipc.conn.new `handle`id!(h;.ipc.inbound[h;`lastConnect]);
    ];
    if[not null n:exec first name from .ipc.outbound where handle=.z.w;
        :.ipc.conn.new enlist[`name]!enlist n;
    ];
    '"unexpected"
  };

/ ************
/ conn actions
/ ************
.ipc.connConnect:{[cfg]
    / Ensure the connection is alive, try to connect if not.
    / @returns bool 1b if it is alive
    if[not `name in key cfg; '"inbound connection"];
    null .ipc.startConnect cfg`name
 };
.ipc.connDisconnect:{[cfg]
    / Disconnect a connection if it is alive.
    if[`name in key cfg; :.ipc.outboundDisconnect cfg`name];
    if[(1b;cfg`id)~.ipc.inbound[h:cfg`handle]`alive`lastConnect;
        if[h=0; '"internal handle"];
        .ipc.inboundDisconnect h;
    ];
 };
.ipc.connIsAlive:{[cfg] $[`name in key cfg;not null .ipc.outbound[cfg`name;`handle];
                            (1b;cfg`id)~.ipc.inbound[cfg`handle]`alive`lastConnect]};
.ipc.connXSend:{[isS;cfg;msg]
    if[`name in key cfg;
        if[null h:.ipc.outbound[n:cfg`name;`handle];
            if[null h:.ipc.startConnect n; '"disconnected"];
        ];
        :$[isS;.ipc.handlers.run[`outbound.send;`name`handle`msg`timeout!(n;h;msg;cfg`timeout)];
            .ipc.handlers.run[`outbound.asend;`name`handle`msg!(n;h;msg)]];
    ];
    // be careful - handle could be disconnected/reconnected
    if[(1b;cfg`id)~.ipc.inbound[h:cfg`handle]`alive`lastConnect;
        :$[isS;.ipc.handlers.run[`inbound.send;`name`handle`msg`timeout!(n;h;msg;cfg`timeout)];
            .ipc.handlers.run[`inbound.asend;`name`handle`msg!(n;h;msg)]];
    ];
    '"disconnected"
 };
.ipc.connSend:{.ipc.connXSend[1b;x;y]};
.ipc.connASend:{.ipc.connXSend[0b;x;y]};
.ipc.connTryXSend:{[isS;cfg;msg]
    if[`name in key cfg;
        if[null h:.ipc.outbound[n:cfg`name;`handle]; :0b];
        $[isS;.ipc.handlers.run[`outbound.send;`name`handle`msg`timeout!(n;h;msg;cfg`timeout)];
            .ipc.handlers.run[`outbound.asend;`name`handle`msg!(n;h;msg)]];
        :1b;
    ];
    if[(1b;cfg`id)~.ipc.inbound[h:cfg`handle]`alive`lastConnect;
        $[isS;.ipc.handlers.run[`inbound.send;`name`handle`msg`timeout!(n;h;msg;cfg`timeout)];
            .ipc.handlers.run[`inbound.asend;`name`handle`msg!(n;h;msg)]];
        :1b;
    ];
    :0b;
 };
.ipc.connTrySend:{.ipc.connTryXSend[1b;x;y]};
.ipc.connTryASend:{.ipc.connTryXSend[0b;x;y]};

.ipc.setHandler:{[cfg;hl]
    if[`name in key cfg; : .ipc.outbound[n;`cb]: distinct .ipc.outbound[n:cfg`name;`cb],enlist hl];
    if[not (1b;cfg`id)~(c:.ipc.inbound[h:cfg`handle])`alive`lastConnect; '"disconnected"];
    .ipc.inbound[h;`cb]: distinct c[`cb],enlist hl; // avoid duplicates
 };

.ipc.setName:{[cfg;n]
    if[`name in key cfg; '"outbound connection"];
    if[not (1b;cfg`id)~(c:.ipc.inbound[h:cfg`handle])`alive`lastConnect; '"disconnected"];
    .ipc.inbound[h;`name]: n;
 };

.ipc.getHandle:{[cfg] $[`handle in key cfg; cfg`handle; .ipc.outbound[cfg`name;`handle]]};

.ipc.connOnClose:{[cfg;e]
    if[`name in key cfg;
        $[-11=type e;.ipc.evOnConnect.onExt[n;e;e];.ipc.evOnConnect.onExt[n;`default;e]];
        :1b;
    ];
    if[(1b;cfg`id)~.ipc.inbound[h:cfg`handle]`alive`lastConnect;
        update cl:{distinct x,enlist y}[e] each cl from `.ipc.inbound where handle=h;
        :1b;
    ];
    0b
 };
/ ***************
/ .z.xxx handlers
/ ***************

/ ws/tcp/unix inbound/outbound close
.ipc.onClose:{[h]
    if[h=0; :.ipc.log.info "spurious 0 handle close"];
    if[not null n:exec first name from .ipc.outbound where handle=h;
        $[.ipc.outbound[n;`logError];.ipc.log.err;.ipc.log.info] "outbound connection disconnected: ",string[n],"[",string[h],"]";
        : .ipc.onOutboundDisconnect n;
    ];
    if[(hh:.ipc.inbound[h])`alive;
        $[hh`logError;.ipc.log.err;.ipc.log.info] "inbound connection disconnected: ",string[$[null n:hh`name;hh`host;n]],"[",string[h],"]";
        .ipc.onInboundDisconnect h;
    ];
 };

/ tcp/unix open
.ipc.onOpen:{
    .ipc.inbound[x]: `alive`host`user`ws`lastConnect`cb!(1b;h:.ipc.rman.host x;.z.u;0b;.sys.P[];());
    .ipc.log.info "Incoming connection: ",string[h],":",string[.z.u],"=",string x;
    .ipc.event.fire[`inbound.connect;x];
 };

.ipc.onOpenWS:{
    .ipc.inbound[x]: `alive`host`user`ws`lastConnect`cb!(1b;.ipc.rman.host x;.z.u;1b;.sys.P[];());
    .ipc.log.info "Incoming connection: ",string[h],":",string[.z.u],"=",string x;
    .ipc.event.fire[`inbound.connect;x];
 };

.ipc.psHandler:{.ipc.pxHandler[0b;x]};
.ipc.pgHandler:{.ipc.pxHandler[1b;x]};
.ipc.pxHandler:{[isSync;msg]
    hh: .ipc.getCurr[];
    .ipc.result:(::);
    if[not count cb:$[`name in key c:hh`cfg; .ipc.outbound[c`name;`cb];.ipc.inbound[.z.w;`cb]]; :msg];
    {[s;h;m;f] .Q.trp[f[s;h];m;{.ipc.log.err "callback failed: ",x,", stack: ",.Q.sbt y}]}[isSync;hh;msg] each cb;
    : $[`EXCEPTION~first r:.ipc.result;r;(`CANCEL;r)];
 };

/ ***
/ API
/ ***
.ipc.new:{c:.ipc.newConn.new[]; $[99=type x;c[`cfg;x];c]};
.ipc.events:{.ipc.event};
.ipc.get:{$[`inbound~x;.ipc.inbound;`outbound~x;.ipc.outbound;`current~x;.ipc.getCurr[];'"domain"]};

.ipc.mInit:{
    / setup handlers
    .ipc.rman: rman: .sys.use`rmanager;
    .ipc.newConn: .sys.use[`smart;`ipc.newconn;.ipc.cfg.newconn];
    .ipc.conn: .sys.use[`smart;`ipc.conn;.ipc.cfg.conn];
    .ipc.handlers: .sys.use[`hmanager;0b];
    .ipc.handlers.add[`outbound.send;`exec;{@[x`handle;x`msg;{(`EXCEPTION;x)}]}];
    .ipc.handlers.add[`outbound.asend;`exec;{@[neg x`handle;x`msg;{(`EXCEPTION;x)}]}];
    .ipc.handlers.add[`inbound.wssend;`exec;{@[x`handle;x`msg;{(`EXCEPTION;x)}]}];
    .ipc.handlers.add[`inbound.send;`exec;{@[x`handle;x`msg;{(`EXCEPTION;x)}]}];
    .ipc.handlers.add[`inbound.asend;`exec;{@[neg x`handle;x`msg;{(`EXCEPTION;x)}]}];
    / open/close - update inbound/outbound
    rman[`setHandler][`.z.po;`ipc.open;.ipc.onOpen];
    rman[`setHandler][`.z.pc;`ipc.close;.ipc.onClose];
    rman[`setHandler][`.z.wo;`ipc.open;.ipc.onOpenWS];
    rman[`setHandler][`.z.wc;`ipc.close;.ipc.onClose];
    / handle exec events
    rman[`setHandlerAt][`.z.ps;`before`exec;`.ipc.exec;.ipc.psHandler];
    rman[`setHandlerAt][`.z.pg;`before`exec;`.ipc.exec;.ipc.pgHandler];
    / data in/out
    / rman[`setHandlerAt][`.z.ph;`before`start;`ipcIn;.ipc.onInMsgHTTP];
    / rman[`setHandlerAt][`.z.pp;`before`start;`ipcIn;.ipc.onInMsgHTTP];
    / rman[`setHandlerAt][`.z.ph;`after`end;`ipcOut;.ipc.onOutMsgHTTP];
    / rman[`setHandlerAt][`.z.pp;`after`end;`ipcOut;.ipc.onOutMsgHTTP];
    :`new`addPlugin`events`get;
 };

.ipc.addPlugin:{[ns]
    .ipc.log.info "Adding plugin ",string ns;
    ns .ipc.ns;
 }