.sys.use`ipc;
.gw.ctx:.sys.use`ipc_ctx;
.gw.log:.sys.use[`log;`GW];

.gw.cfg.connectDelay:0D00:05;
.gw.cfg.defaultTimeout:0D00:00:30;

.gw.api:([] pid:0#`; pgroup:0#`; );
.gw.checks:(0#`)!();
.gw.lastConnect:(0#`)!0#.z.P;
.gw.requests:([reqId:0#0] start:0#.z.P; stop:0#.z.P; active:0#1b; ctx:(); rnum:0#0; results:(); servers:(); handle:());
.gw.postProc: .sys.use[`hmanager;0b];

.gw.mInit:{
    .gw.mbus: .sys.use`mbus;
    .gw.mbus.sub `apiInfo`pid`cb!(::;::;`.gw.onApiMsg);
 };

.gw.onApiMsg:{[msg]
    if[not all `apiInfo`pid`pgroup`cid`host`port in key msg; :()];
    .gw.lastConnect[msg`pgroup]: 0Np; // some process is online
    / if[msg[`pid] in exec pid from .gw.processes; :()];
    {} each an:(a:msg`apiInfo)`name;

    ... h[`setHandler;`.gw.onResult]
    ... .gw.postProc.add[func;`exec;`.gw.postProcFn]
    ... .z.pc - cancel requests
 };

.gw.execUser:{[f;a]
    if[not 99=type a; '"argument must be a dictionary"];
    a:`.gwfn`.gwreqid`.reqid _ a; // remove internal args
    : .gw.exec[f;a];
 };

.gw.exec:{[f;a] .[.gw.execTrp;(f;a);.gw.startExc]};
.gw.execTrp:{[f;a]
    ctx:.gw.ctx.env[];
    .gw.log.dbg "processing request ",string[ctx`reqId];
    a:a,`.gwfn`!(f;::);
    // basic set of targets
    p:select from .gw.api where fn=f, .gw.baseFilter[a] each bfilter, enabled;
    // adjust/check arguments
    a:{y x}/[a;.gw.checks distinct p`check];
    // final filter
    p:select from p where (.gw.filters filter)@\:a;
    // check availability
    srv:exec .gw.getSrv[h;dr_h;first pgroup] by pgroup from p;
    if[not all i:value[srv][;0];
        '"servers offline: ",","string key[srv] where not i;
    ];
    // we can proceed with the request
    gwid: $[`ggwReqId in key rctx:env`reqContext;rctx`ggwReqId;ctx`reqId]; // first gw
    pgwid: $[`gwReqId in key rctx:env`reqContext;rctx`gwReqId;ctx`reqId]; // previous gw
    // defer
    if[ctx`sync; .sys.ipc.defer[]];
    // execute within 'user' context + provide ids
    .sys.ipc.broadcast[h:value[srv][;1];(`ipc_ctx.request;rctx:((`user`appUser)#ctx),`ggwReqId`gwReqId!(gid;ctx`reqId);(`gw.request;(f;a)))];
    .gw.requests[id]: (.z.P;.gw.cfg.defaultTimeout;1b;rctx,`f`a`sync`pgwReqId!(f;a;ctx`sync;pgwid);count srv;();h@\:`name;.gw.ctx.env[]`handle);
    .gw.log.dbg2[{r:.gw.requests id; "request is dispached to ",","sv string r`servers};id];
 };
// an exception happened before the request was processed
.gw.startExc:{[exc]
    c:.gw.ctx.env[];
    .gw.log.err "request ",string[c`reqId]," failed with ",exc;
    if[c`sync; 'exc]; // sync call
    h:.sys.ipc.get`current; // we still in the initial context
    // if it is a gw request - report the result
    $[`gwReqId in key c:c`reqContext;
        h[`asend;(`gw.result;`reqId`status`result!(c`gwReqId;0b;exc))];
        h[`asend;(`EXCEPTION;exc)
    ];
 };
.gw.resultExc:{[req;exc]
    c:req`ctx;
    .gw.log.err "request ",string[c`gwReqId]," failed with ",exc;
    hh:.sys.ipc.get req`handle; // it is alive - .z.pc is handled
    res:$[c[`pgwReqId]=c`gwReqId;(`EXCEPTION;exc);`reqId`status`result!(c`pgwReqId;0b;exc)];
    $[req[`ctx]`sync; hh[`deferSend;1b;exc];hh[`asend;res]];
 };
// result
.gw.onResult:{[msg]
    .gw.log.db2[{"got result for ",string[x`reqId],", status: ",string x`status};msg];
    if[not (r:.gw.requests[msg`reqId])`active; :()]; // ignore
    if[msg`status; :@[.gw.onResultTrp r;msg;.gw.resultExc r]];
    .gw.resultExc[r;msg`result];
 };
.gw.onResultTrp:{[r;msg]
    if[not r[`rnum]=count res:.gw.requests[id:msg`reqId;`results],:enlist msg`result; :()];
    .gw.requests[id;`active`results`stop]:(0b;();.z.P);
    .gw.log.dbg "request is done";
    res: .gw.postProc.run[ctx`f;((ctx:r`ctx)`a;res)];
    hh:.sys.ipc.get r`handle; // it is alive - .z.pc is handled
    res:$[ctx[`pgwReqId]=ctx`gwReqId;res;`reqId`status`result!(ctx`pgwReqId;1b;res)];
    $[r[`ctx]`sync; hh[`sendDefered;0b;res];hh[`asend;res]];
    :();
 };

.gw.baseFilter:{[a;f]
    if[not all (k:key f) in key a; :0b];
    : all value[f]~'a k;
 };

.gw.postProcFn:({[a;res]
    if[()~res:raze res; :res];
    if[`gwSortBy in key a; res: a[`gwSortBy] xasc res];
    res
 }.);

// Get one alive srv within a group.
// dr_h can be {0b} if dr is not available
.gw.getSrv:{[h;dr_h;grp] if[0b=first r:.gw.getSrv2[h;grp]; if[0b=first r:.gw.getSrv2[dr_h;grp]; .gw.lastConnect[grp]:.z.P]; r};
.gw.getSrv2:{[h;grp]
    if[any hh:h@\:`isAlive
        :(1b;first 1?h where hh); // random 
    ];
    // all disconnected, try to reconnect considering .gw.cfg.connectDelay
    // delay - avoid constant connect attempts to offline srvs
    if[.gw.lastConnect<.z.P-.gw.cfg.connectDelay; :(0b;grp)];
    if[any h@\:`connect;
        :.gw.getSrv2[h;grp];
    ];
    :(0b;grp);
 };