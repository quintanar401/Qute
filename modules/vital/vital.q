.vital.master:(0#`)!();
.vital.mInit:{`$()};
.vital.log:.sys.use[`log;`VITAL];
.vital.iInit:{[conn]
    if[99<>type conn; conn:enlist[`port]!enlist conn];
    i:(.sys.use`ipc)[`new] .vital.master,conn,`logError`onConnect!(0b;`.vital.onConnect);
    // at this time host & port are ok
    if[not `name in key conn; i:i[`name;`$"vital:",string[i`host],":",string i`port]];
    if[i`exists; .vital.log.info "vital connection already exists"; :()];
    if[.sys.port=i`port; .vital.log.info "vital is ignored - the same process"];
    .vital.log.info "vital connection is added: ",string i`name;
    @[i;`open;{.vital.log.err "can't open the connection - ",x,", exiting..."; .sys.exit 0}];
 };

.vital.onConnect:{if[not x`status; .vital.log.info "disconnect, exiting ..."; .sys.exit 0]};