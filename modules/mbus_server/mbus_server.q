.msrv.log: .sys.use[`log;`MSRV];
.sys.use`ipc_reconnect;
.msrv.ipc:.sys.use`ipc;

// mandatory server fields
.msrv.cfg.address:(0#`)!();

.msrv.clients:();

.msrv.subscribers:([] handle: (); filter:(); id:0#0Np);

// pinned msgs
.msrv.msgs:();

.msrv.mInit:{`$()};

/ Convert: port, host:port, host:port:user into a connection dict
.msrv.parseSrv:{
    pp:{`name`connection`address!(`$":"sv string x`host`port;x;(`$())!())};
    if[all x in .Q.n; :pp `host`port!(`localhost;"I"$x)];
    : pp (`host`port!(`$x 0;"I"$x 1)),$[3=count x:":" vs x;enlist[`user]!(),`$x 2;()]
 };

.msrv.validateSrv:{
    if[not `connection in key x;
        .msrv.log.err "connection field is missing: ",.sys.str x;
        '"bad config";
    ];
    if[not `port in key x`connection]
 };

.msrv.iInit:{[cfg]
    // default config
    if[99=type cfg;
        .msrv.cfg: .msrv.cfg,cfg;
    ];
    // override from the command line
    if[`mservers in key .sys.opt;
        .msrv.cfg[`servers]: .msrv.parseSrv each "," vs first .sys.opt`mservers;
    ];
    if[0=count cfg:.msrv.cfg`servers;
        .msrv.log.err "Settings are not found";
        '"settings not found";
    ];
    // check cfg
    v:.sys.use[`validator;(`name`value_type`convert_to`default!("name";(),/:"sC";"s";`default);
                            `name`value_type!("connection";"dict");
                            `name`value_type`optional!("address";"dict";1b))];
    cfg:v[`validate] each cfg;
    .msrv.cfg[`servers]:cfg:{
        y[`connection]:x[`new][][`cfg;y`connection]`validate;
        if[not `address in key y; y[`address]:(0#`)!()];
        y}[ipc:.msrv.ipc] each cfg;
    // which one is myself? The first with the same hostname.
    .msrv.name:`;
    self: ();
    // if -mbus parameter is provided, try get the name from it
    if[`mbus in key .sys.opt; .msrv.name: `${$[3=count x:":" vs x;x 0;""]} first .sys.opt`mbus];
    if[not nn:null .msrv.name; self:cfg first where .msrv.name=cfg@\:`name];
    if[nn; self:cfg first where {(x[`connection]`host) in .sys.host,`localhost} each cfg];
    if[not 99=type .msrv.self:self;
        .msrv.log.err "Can't find self settings";
        '"settings not found";
    ];
    .msrv.name: .sys.sym self`name;
    // connect to other servers
    .msrv.servers:{
        if[.msrv.name=y`name; :()];
        mset: `name`unique`autoConnect`logError!(`$"mserver:",string y`name;`yes;1b;0b); // must have settings
        oset: `reconnectSchedule`connectionTimeout!(0D00:00:10 0D00:01;00:00:05.0); // optional setttings
        .msrv.log.info "Adding server ",string y[`name],y[`connection]`host`port;
        .msrv.log.info "Settings: ",.Q.s1 enlist[`password]_ cfg:oset,y[`connection],mset;
        :enlist x[`new][][`cfg;cfg]`open;
    }[ipc] each cfg;
    .msrv.name:` sv `mbus,.msrv.name;
    .msrv.log.info "mserver set to ",":"sv string .msrv.name,self[`connection]`host`port;
    // setup handler
    .sys.use[`rmanager][`setHandlerAt][`.z.ps;`before`exec;.msrv.name;`.msrv.handler];
    .sys.use[`rmanager][`setHandler][`.z.pc;.msrv.name;`.msrv.onClose];
 };

.msrv.handler:{
    if[not .msrv.name~n:first x; :x];
    cl: .msrv.ipc.get`current;
    if[`s_register=x 1;
        .msrv.log.info "Client: ",string x 2;
        cl[`setName;`$string[.msrv.name]," client: ",string x 2];
        // cl[`setHandler;.msrv.onClientRequest]; no need as we already monitor all handles
        cl[`asend;(.msrv.name;`register;1b)]; // akn register request
        .msrv.clients,:enlist cl; // store the client to send it msgs
    ];
    if[`s_upds=x 1; {$[`s_upd=y 0;.msrv.processUpd;`s_sub=y 0;.msrv.processSub;'"unexpected"][x;y 1]}[cl] each x 2];
    if[`s_sub=x 1; .msrv.processSub[cl;x 2]];
    if[`s_upd=x 1; .msrv.processUpd[cl;x 2]];
    :$[x[1] like "s_*";(`CANCEL;::);x]; // client & server can share the same .z.ps
 };

.msrv.processUpd:{[cl;msg]
    .msrv.log.dbg2[{"handle: ",string[x`handle],", upd msg: ",.Q.s1 y};(cl;msg)];
    msg:msg,.msrv.cfg.address; // add mandatory fields
    if[not `normal=msg`mtype; .msrv.updMsgs[cl`handle;msg]];
    {
        if[not y[`handle]`isAlive; :()];
        if[not @[y[`filter];x;0b]; :()];
        y[`handle][`asend;(.msrv.name;`upd;y`id;x)]
    }[msg] each .msrv.subscribers;
 };

.msrv.processSub:{[cl;msg]
    .msrv.log.info "subscription request";
    .msrv.log.dbg2[{"handle: ",string[x`handle],", msg: ",.Q.s1 y};(cl;msg)];
    .msrv.subscribers:.msrv.subscribers where {x`isAlive} each .msrv.subscribers`handle;
    if[msg[`.id]in .msrv.subscribers`id; .msrv.log.info "already subscribed"; :()];

    intro:{all x in key y}[k:key[msg] except `.extra`.id`cb`.notify]; // incoming msg has all fields
    flt:{$[10=type x;$[any "*?"in x;like[;x];x~];
       x~(::);{1b};
       99<type x;x;
       (all 10=type each x)&0=type x;in[;x];
       type[x] within 1 19h;in[;x];
       x~]} each msg k;
    flt:{all @[;;0b]'[y;z x]}[k;flt]; // filter by fields
    flt:{[i;f;m] if[not i m; :0b]; f m}[intro;flt];
    `.msrv.subscribers upsert (cl;flt;msg`.id);

    // send pinned msgs
    {x[`asend;(.msrv.name;`upd;y;z)]}[cl;msg`.id] each .msrv.msgs where {@[x;y 1;0b]}[flt] each .msrv.msgs;
    if[1b~msg`.notify; cl[`asend;(.msrv.name;`upd;msg`.id;1b)]];
 };

.msrv.updMsgs:{[h;msg]
    if[any i:{$[all (key y:y 1)in k:key x;(`data`.ts _x)~(k:k except `data`.ts)#y;0b]}[msg] each .msrv.msgs;
        .msrv.msgs:.msrv.msgs _ first where i;
    ];
    .msrv.msgs,:enlist ($[`pin=msg`mtype;h;-1i];msg);
 };

.msrv.onClose:{[h]
    delete from `.msrv.subscribers where h=handle@\:`handle;
    .msrv.msgs:.msrv.msgs where not .msrv.msgs[;0]=h;
 };