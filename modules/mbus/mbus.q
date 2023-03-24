// mbus client
// Mbus server connection:
//   -mbus name:host:port | host:port | name::port | port
//   or the same value in the init params .sys.use[`mbus;`...]

.sys.use`ipc_reconnect;
.mbus.log:.sys.use[`log;`MBUS];

// mandatory fields
.mbus.cfg.address:(0#`)!();
// additional ipc connect settings
.mbus.cfg.mbus:(0#`)!();
// mbus server name
.mbus.name:`;
// queue in case mbus server is not on
.mbus.queue:();
// use only 1 instance per mbus
.state.mbus:(0#`)!();
// subscribers
.mbus.subscribers:(0#.z.P)!();

.mbus.mInit:{`send`sub`pin`post};

// opt: `mbus + `address
// address: `field1!val1 - always add these fields to outbound messages
// mbus - [host:]port with an optional name, port is hardcoded, other ports can be discovered via mbus
.mbus.iInit:{[opt]
    // find out the server details
    n:`;
    if[`port in key .mbus.cfg.mbus; 
        n:`$":" sv .sys.str each $[`host in key .mbus.cfg.mbus;.mbus.cfg.mbus`host;`localhost],enlist .mbus.cfg.mbus`port;
    ];
    if[`mbus in key .sys.opt; n:`$first .sys.opt`mbus];
    if[opt~(::); opt:(0#`)!()];
    if[`mbus in key opt; n: .sys.sym opt`mbus];
    if[null n; '"invalid mbus server"];
    nm:":" vs string n;
    nm:$[1=c:count nm;(`;`localhost;"J"$nm 0);2=c;(`;`$x 0;"J"$x 1);3=c;(`$x 0;`localhost^`$x 1;"J"$x 2);'"invalid mbus name"];
    .mbus.cfg.mbus[`host`port]: nm 1 2;
    .mbus.name:` sv `mbus,`default^nm 0;
    // if it was inited just redirect to the main instance
    if[.mbus.name in key .state.mbus; st:.state.mbus .mbus.name; @[.mbus.ns;key st;:;value st]; :()];
    .mbus.log.info "connecting to mbus server: ",nm:":"sv string .mbus.name,.mbus.cfg.mbus[`host`port];
    // not unique: can be used by any module within the same process
    mset: `name`unique`autoConnect`onConnect`logError!(`$nm;`no;1b;`.mbus.onConnect;0b); // must have settings
    oset: `reconnectSchedule`connectionTimeout!(0D00:00:10 0D00:01;00:00:05.0); // optional setttings
    i:(ipc:.sys.use[`ipc])[`new] oset,.mbus.cfg.mbus,mset;
    .mbus.handle: $[is0:i`is0;ipc[`get]`current;i`add]; // do not connect right away
    .state.mbus[.mbus.name]:`send`sub`pin`post#get .mbus.ns; // copy API for other instances
    if[is0; .mbus.onConnect enlist[`status]!enlist 1b]; // force 0 handle
 };

.mbus.send:{[msg] .mbus.send0 msg}; // to be able to redirect to another instance
.mbus.send0:{[msg]
    msg:(`data`mtype!(::;`normal)),
        $[99=type msg; msg,enlist[`]!enlist (::); msg:``data!(::;msg)],
        .mbus.cfg.address,`.ts`.id!(.sys.P[];.sys.uid);
    if[not msg[`mtype] in `normal`post`pin; '"wrong message type: ",string msg`mtype];

    .mbus.log.dbg2[{"sending msg ",.Q.s1 y};(::;msg)];
    if[(isN:`normal=msg`mtype)&not res:.mbus.handle[`tryASend;(.mbus.name;`s_upd;msg)];
        .mbus.log.dbg "not connected: store in queue";
        .mbus.queue,:enlist (`s_upd;msg);
        : res;
    ];
    if[not isN; .mbus.updQueue msg];
    : res;
 };
.mbus.pin:{.mbus.send $[99=type x; x,`mtype`!(`post;::); ``data`mtype!(::;x;`post)]};
.mbus.post:{.mbus.send $[99=type x; x,`mtype`!(`post;::); ``data`mtype!(::;x;`post)]};

.mbus.sub:{[msg] .mbus.sub0 msg}; // to be able to redirect to another instance
.mbus.sub0:{[msg]
    if[not 99=type msg; '"format"];
    if[not `cb in key msg; '"callback required"];
    .mbus.subscribers[id:.sys.P[]]: msg`cb;
    msg:msg,`.id`cb!(id;());
    .mbus.log.info["sending sub msg ",.Q.s1 msg];
    if[not res:.mbus.handle[`tryASend;(.mbus.name;`s_sub;msg)];
        .mbus.log.dbg "not connected: store in queue";
    ];
    .mbus.queue,:enlist (`s_sub;msg);
    : res;
 };

// update static messages: all fields except data are the same
.mbus.updQueue:{[msg]
    if[any i:{if[`s_sub=y 0;:0b]; $[all (key y:y 1)in k:key x;(`data`.ts _x)~(k:k except `data`.ts)#y;0b]}[msg] each .mbus.queue;
        .mbus.queue:.mbus.queue _ first where i;
    ];
    .mbus.queue,:enlist (`s_upd;msg);
 };

.mbus.onConnect:{
    if[not x`status; :()]; // disconnect
    .mbus.log.info "register with the server";
    // register
    $[0=.mbus.handle`getHandle;
        .sys.use[`rmanager][`setHandlerAt][`.z.ps;`before`exec;.mbus.name;`.mbus.onMsg0];
        .mbus.handle[`setHandler;`.mbus.onMsg]]; // unique in each instance
    // react if there is no response from the server
    .sys.timer.new[][`delay;00:01][`name;`.mbus.name][`fn;`.mbus.registerTO]`start;
    .mbus.handle[`asend;(.mbus.name;`s_register;`$":"sv string .sys`host`port)];
 };

.mbus.registerTO:{
    .mbus.log.err "No response from the server: disconnect";
    if[not 0=.mbus.handle`handle; .mbus.handle`disconnect];
 };

.mbus.onMsg0:{.mbus.onMsg[.sys.ipc.get`current;x]};
.mbus.onMsg:{[h;msg]
    if[not .mbus.name~first msg; :msg];
    // the server confirms subscription, send pending msgs
    if[`register~msg 1;
        .mbus.log.info "registered";
        .sys.timer.get[`.mbus.name]`stop;
        if[count .mbus.queue;
            .mbus.log.info "Sending pending messages";
            .mbus.handle[`asend;(.mbus.name;`s_upds;.mbus.queue)];
            .mbus.queue:.mbus.queue where not {$[`s_sub=x 0;0b;`normal=x[1]`mtype]} each .mbus.queue;
        ];
    ];
    if[`upd~msg 1;
        if[(id:msg 2) in key .mbus.subscribers; // TODO: unsubscribe
            .mbus.log.dbg2[{"got msg for ",string[x],": ",.Q.s1 y 3};(id;msg)];
            .Q.trp[.mbus.subscribers id;msg 3;
                {.mbus.log.err "Callback failed for ",string[x]," with ",y,": ",.Q.sbt z}[id]];
        ];
    ];
    :$[msg[1] like "s_*";msg;(`CANCEL;::)]; // client & server can share the same .z.ps
 };