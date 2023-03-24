.sys.use`ipc;
.gw.ctx:.sys.use`ipc_ctx;

.gw.api:([pid:0#`] pgroup:0#`; );

.gw.mInit:{
    .gw.mbus: .sys.use`mbus;
    .gw.mbus.sub `apiInfo`pid`cb!(::;::;`.gw.onApiMsg);
 };

.gw.onApiMsg:{[msg]
    if[not all `apiInfo`pid`pgroup`cid`host`port in key msg; :()];
    / if[msg[`pid] in exec pid from .gw.processes; :()];
    {} each an:(a:msg`apiInfo)`name;
 };

.gw.exec:{[f;a]
    if[not 99=type a; '"argument must be a dictionary"];
    a:a,`.gwfn`!(f;::);
    p:select from .gw.api where fn=f, .gw.baseFilter[a] each bfilter, enabled;
    a:{y x}[a;distinct p`check];
 };

.gw.baseFilter:{[a;f]
    if[not all (k:key f) in key a; :0b];
    : all value[f]~'a k;
 };