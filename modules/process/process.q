.proc.log:.sys.use[`log;`PROC];

.proc.mInit:{ .proc.init[]; `$()};

.proc.init:{
    if[not all `pmanager`pid in key .sys.opt; '"bad config"];
    .proc.id:`$first .sys.opt`pid;
    .proc.pmanager:`$first .sys.opt`pmanager;
    .proc.log.info "Init process ",string[.proc.id]," from ",string .proc.pmanager;
    .proc.mbus:.sys.use`mbus;
    .proc.mbus.sub `pmanager`process`cmd`cb!(.proc.pmanager;.proc.id;::;`.proc.upd);
    // pmanager will send us cfg
    .proc.mbus.post `pmanager`process`event!(.proc.pmanager;.proc.id;`started);
    .proc.isInited: 0b;
 };


.proc.upd:{[msg]
    0N!msg;
 }