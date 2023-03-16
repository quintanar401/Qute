// mappings from logical names to actual values (HDB -> hostname)
.pman.cfg.aliases:(0#`)!();
// possible process parameters (source, timeout, ..)
.pman.cfg.parameters:();
// process templates (hdb, rdb, ..)
.pman.cfg.templates:(0#`)!();
// process instances
.pman.cfg.processes:(0#`)!();

.pman.cfg.p2id:(0#`)!();

.pman.log:.sys.use[`log;`PMAN];
.pman.cfg.id:`default;

.pman.mInit:{.pman.init[]; :`$()};
.pman.init:{
    // make map: name->param
    if[0=count .pman.cfg.processes; .pman.log.info "there are no processes"; :()];
    .pman.log.info "processing process configuration";
    .pman.log.info "id: ",string .pman.cfg.id;
    .pman.cfg.parameters:({
        if[not `name in key x; .pman.log.err "no name in parameter ",.Q.s1 x; '"format"];
        `$x`name
    } each p)!p:.pman.cfg.parameters,.pman.cfg.def;
    // check and normalize templates
    .pman.cfg.templates:k!{.[.pman.procTemplates;(x;y);
        {'"exeption in template ",string[x],": ",y}x]}'[k:key t;value t:.pman.cfg.templates];
    // filter processes
    cfg:raze .pman.procProcesses'[key p;value p:.pman.cfg.processes];
    {
        .pman.log.info "process ",string[x 0],", auto: ",string[x[1]`autoStart],", enabled: ",string x[1]`enabled;
    } each cfg where {.sys.host=x[1]`host} each cfg;
    if[count i:where 1<count each group id:cfg[;0];
        .pman.log.err "duplicate processes: ",","sv string i;
        '"format";
    ];
    .pman.processes:([id] host:{x[1]`host} each cfg; config:cfg[;1]; status:`down;
        pinfo:count[cfg]#enlist (); lastEvent:0Np);
    update autoStart:config@\:`autoStart, mode:config@\:`mode, enabled:config@\:`enabled from `.pman.processes;
    // mbus
    .pman.log.info "connecting to MBUS";
    .pman.isInited:0b;
    .pman.mbus: .sys.use`mbus;
    // subscribe to process update events
    .pman.mbus.sub `pmanager`process`event`cb`.notify!(.pman.cfg.id;::;::;`.pman.upd;1b);
    // pin process params
    {.pman.mbus.pin  `pmanager`process`cmd`data!(.pman.cfg.id;x`id;`setCfg;
        (delete startCmd from x`config),`pmanager`pmanager_port!(.pman.cfg.id;.sys.port))} each 0!.pman.processes;
    // startProc will wait for sub akn to get all current proc data
 };

.pman.procTemplates:{
    if[not `id in key y; .pman.log.err "no id in template ",string x; '"format"];
    .pman.cfg.p2id[x]: ids:`$"." vs .sys.str y`id;
    if[`params in key y; ids,:`$y`params];
    if[hasD:`default in key y; ids,:d:key y`default];
    if[not all i:ids in key .pman.cfg.parameters;
        .pman.log.err "undefined parameters in template ",string[x],": ",","sv string ids where not i;
        '"format";
    ];
    p:.sys.use[`smart;`;.pman.cfg.def,(.pman.cfg.parameters ids)][`new][];
    if[hasD; p:p[`cfg;y`default]]; 
    p
 };

.pman.procProcesses:{
    if[not (tid:`$(i:x?":")#x:string x)in key .pman.cfg.templates;
        .pman.log.err "Invalid process ID: ",x;
        '"format";
    ];
    // get cfg
    cfg:(.pman.cfg.templates tid)[`cfg;y];
    // add id params: correct number of fields
    if[(count pid:.pman.cfg.p2id tid)<c:count id:"." vs (i+1)_x;
        .pman.log.err "Invalid process ID: ",x;
        '"format";
    ];
    // apply aliases
    cfg:{
        if[not "@"~first v:.sys.str x y; :x];
        if[not (v:`$1_(),v)in key .pman.cfg.aliases;
            .pman.log.err "bad alias ",string v;
            '"format";
        ];
        v:.pman.cfg.aliases v;
        if[not "!"~first v; :x[y;v]];
        :x[y;@[value;1_v;{.pman.log.err "can't evaluate alias ",x,": ",y}v]];
    }/[cfg;`host`taskset inter key cfg`cfg];
    // apply id params, process ranges
    cfg:{
        raze {
            if[0=count z; :enlist x]; // default value
            if[all z in .Q.n,"-"; // range
                if[not 2=count r:"-"vs z; .pman.log.err "bad range ",x; '"format"];
                if[r[0]>r 1|any null r:"J"$r; .pman.log.err "bad range ",x; '"format"];
                :{x:x[y;z]; if[`port in key c:x`cfg; x:x[`port;z+c`port]]; x}[x;y] each r[0]+til 1+r[1]-r 0;
            ];
            enlist x[y;z]
        }[;y;z] each x
    }/[enlist cfg;c#pid;id];
    // finish cfg
    :{
        cfg:@[z;`validate;{.pman.log.err "invalid process config ",x,": ",y; 'y}y];
        (`$"." sv .sys.str each cfg .pman.cfg.p2id x;cfg)
    }[tid;x] each cfg;
 };

.pman.upd:{[msg]
    show msg;
    if[1b~msg;
        if[.pman.isInited; :()];
        .pman.isInited:1b;
        :.sys.timer.new[][`name;`.pman.pmanager][`sTime;.z.P+0D00:00:01][`interval;0D00:01][`fn;`.pman.startProcs]`start;
    ];
    // ignore msgs from non configured processes
    if[not (id:msg`process) in (0!.pman.processes)`id; :()];
    if[`port in key msg; if[not msg[`port]=.pman.processes[id;`config]`port; :()]];
    .pman.log.info "Process ",string[id],": ",string ev:msg`event;
    .pman.processes[id;`status`lastEvent]: (ev;.sys.P[]);
 };

.pman.startProcs:{
    if[not .pman.isInited; :()];
    p:select from 0!.pman.processes where status=`down, autoStart, enabled, mode=`once;
    .pman.startProc each p;
 };

.pman.startProc:{
    .pman.log.info "Starting ",string x`id;
    c[`startCmd][x`id;c:x`config];
    .pman.processes[x`id;`status`lastEvent]:(`starting;.sys.P[]);
 };

.pman.startCmd:{[id;cfg]
    cmd: "q ",(1_string .sys.qute),"/core/loader.q -main process -mbus ",(first .sys.opt`mbus),
         " -pmanager ",string[.pman.cfg.id]," -pid ",string[id]," -logfile ./logs/",string[id],".log",$[0=cfg`timer;"";" -t ",string cfg`timer],
         $[0=cfg`timeout;"";" -T ",string cfg`timeout],$[0=cfg`port;"";" -p ",string cfg`port];
    cmd: $[.sys.isW;"start /b ",cmd," <nul";cmd," < /dev/null &"];
    .pman.log.info cmd;
    system cmd;
 };