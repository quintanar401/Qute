// Global obj counter, add a small random shift to make it unpredictable
.sys.cnt: "j"$.z.T mod 5;

// input params
.sys.opt: .Q.opt .z.x;

// is Win
.sys.isW: .z.o in `w32`w64;

// script working directory
.sys.swd: {sd:1 _string x; d:system "cd"; $[(sd like "[A-Z]:*")|"/"=first sd;x;"."=first sd;d,1_sd;d,"/",sd]} first ` vs hsym .z.f;

// qute dir
.sys.qute: {$[`qute in key .sys.opt;hsym`$first .sys.opt`qute;count p:getenv`QUTE;hsym`$p;first ` vs hsym`$.sys.swd]}[];

// qute core
.sys.core: ` sv .sys.qute,`core;

// module search paths
.sys.mpaths: (` sv .sys.qute,`modules),();

// config directory
.sys.config: $[`config in key .sys.opt; .sys.config:hsym`$","vs first .sys.opt`config;`$()];

// Does this process works as a module server
.sys.isModServer: $[`module_server in key .sys.opt;0=count first .sys.opt`module_server;0b];
.sys.modServer: $[`module_server in key .sys.opt;{$[all x in .Q.n;"J"$x;`$x]} first .sys.opt`module_server;0b];

// Load json, if there is an exception report the correct line/column.
.sys.loadJson:{[f]
    d: @[read1;f;{y;'"couldn't read file ",1_ string x}f]; // read file
    r: @[{(1b;.j.k x)};d;{(0b;x)}]; // try to parse it
    if[r 0; :r 1];
    idx: 1+count[r 1]-first ss[reverse r 1;"ta"]; // find  ".. at NNN"
    ln: count lidx:where "\n"=(pos:0^"J"$idx _r 1)#d; // line number
    '"couldn't load ",(1_ string f),": ",((idx-4)#r 1)," at ",string[ln+1],":",string pos-0^last lidx
 };

.sys.loadCsv:{[dir;cfg;n]
    p:` sv dir,n;
    // if there is a fmt just parse and return
    if[(base: first ` vs n) in key cfg;
        : .[0:;((cfg`base;enlist ",");p);{'"couldn't load config ",(1_string x),": ",y}p];
    ];
    // otherwise find out the number of columns
    d: @[read0;p;{y;'"couldn't read file ",1_ string x}p]; // read file
    if[0=count d;'"empty config file ",1_string p];
    if[0=cn:count "," vs d 0; '"empty header in config file ",1_string p];
    // parse as strings first
    cfg: .[0:;((cn#"*";enlist ",");d);{'"couldn't load config ",(1_string x),": ",y}p];
    // symbol (a-zA-Z0-9\-_=.), time(0-9.:), double(0-9e+-.), long(0-9), string
    parseCol:{[c]
        if[all (cc:raze c) in .Q.n; :"J"$c];
        if[all (cc:raze c) in .Q.n,"e+-."; :"F"$c];
        if[all (cc:raze c) in .Q.n,".:"; :"T"$c];
        if[all cc in .Q.an,"-=."; :`$c];
        c
    };
    : flip parseCol each flip cfg;
 };

// tmp bindings
if[`logfile in key .sys.opt; system "1 ",first .sys.opt`logfile];
.sys.log.info:{-1 "INFO ",x};
.sys.log.dbg:{-1 "DBG  ",x};
.sys.log.err:{-1 "ERROR ",x};

.sys.trp:{[f;a] .Q.trp};

// sym/str -> sym
.sys.sym:{$[10=type x;`$x;x]};
.sys.str:{$[10=type x;x;0>type x;string x;.Q.s1 x]};

// version -> string
.sys.v2str:{$[x=0W;"max";"."sv string -1+10000 vs 100010001+x]};

// available modules
.sys.modules: raze {flip `status`name`path!(`;n i;d i:where 11=type each key each d:` sv/:x,/:n:key x)} each .sys.mpaths;
update settings: {$[-11=type key p:` sv x,`settings.json;.sys.loadJson p;(0#`)!()]} each path from `.sys.modules;
update name:{$[`name in key y;`$y`name;x]}'[name;settings] from `.sys.modules;
update version:{$[`version in key x;sum 100000000 10000 1*"J"$"." vs x`version;0]} each settings from `.sys.modules;
update namespace:`, api:count[i]#enlist 0#` from `.sys.modules;

// Load all csv/json cfgs in a dir recursively
// Return them imitating the dir structure using the namespace fmt: ``a`b!(::;cfg;``d!(::;cfg))
// csv format must be defined in the module's settings.json file:
//   "csv_format": [{ "name": "cfg_full_name/pattern", "format": "SSS*ISS" }, ...]
// If there is no format it will be guessed from the content: symbol (a-zA-Z0-9\-_=.), time(0-9.:), double(0-9e+-.), long(0-9), string
.sys.loadCfgs:{[d;c]
    res: ();
    // cfg files
    cn: {x where (x like "*.csv")|x like "*.json"} dd:key d;
    cn: (` vs/:cn)[;0]!{$[z like "*.csv";.sys.loadCsv[x;y;z];.sys.loadJson ` sv x,z]}[d;$[`csv_format in key c;c`csv_format;(0#`)!()]] each cn;
    // sub dirs
    d:d i:where 11=type each key each d:` sv/:d,/:dd;
    cn,(dd i)!.sys.loadCfgs[;c] each d
 };

// substitute all fr -> to in obj recursively
.sys.subst:{[obj;fr;to]
    if[20>=abs t:type obj;
        if[t=-11; : `$ssr[string obj;fr;to]];
        if[t=11; : @[obj;where obj like "*",fr,"*";{`$ssr[string z;x;y]}[fr;to]]];
        if[t=10; : ssr[obj;fr;to]];
        if[t=0; : .z.s[;fr;to] each obj];
        : obj
    ];
    if[99=t; : .z.s[key obj;fr;to]!.z.s[value obj;fr;to]];
    if[98=t; : flip .z.s[;fr;to] each flip obj];
    if[t>99;
        if[100=t; : value ssr[string obj;fr;to]]; // user fn
        if[(103<t)&t<112; : value .z.s[;fr;to] each value obj]; // composition
    ];
    : obj
 };

// Load a module
// n: name
// v: version
.sys.loadMod:{[n;v1;v2]
    .sys.log.dbg "Loading module ",(sn:string n),", version range ",.sys.v2str[v1],"-",.sys.v2str v2;
    m: .sys.modules idx:exec last i from .sys.modules where version within (v1;v2), name = n;
    if[null idx; '"module not found: ",string n];
    if[not `=m`status; : idx]; // already loaded
    .sys.log.info "Module is found. Loading the code [",string[m`path],"] and config files...";
    txt: "c"$@[read1;p;{'"couldn't load module ",(1_string x),": ",y}p:` sv m[`path],` sv n,`q];
    // rename namespace
    mns: $[`ns in key m`settings;m[`settings]`ns;sn];
    ns: mns,"__",string .sys.cnt+:1; // rename .xxx into .xxx__NN
    txt: ssr[txt;fr:".",mns,".";to:".",ns,"."];
    // try to evaluate
    .Q.trp[value;txt;{.sys.log.err "couldn't evaluate module ",x,": ",y,"\n",.Q.sbt z;'y}sn];
    // load configuration files - 1) module's dir 2) config/module if available & there is no iInit
    .sys.modules[idx;`namespace`status]:(ns:`$".",ns;`loaded);
    cfg: .sys.loadCfgs[m`path;m`settings];
    lcfg:{[n;s;c;p]
        if[not 11=type key p:` sv p,n; :c];
        c,.sys.loadCfgs[p;s]
    };
    if[(not `iInit in key ns)&count .sys.config; cfg: lcfg[n;m`settings]/[cfg;.sys.config]];
    @[ns;`ns`cfg`__mod__;:;(ns;$[`cfg in key ns;ns`cfg;()],.sys.subst[cfg;fr;to];(enlist[`instances]!()),`name`version`path#m)];
    .sys.modules[idx;`status]:`configured;
    : idx;
 };

// Load a module from a namespace.
// n: name
// ns: namespace
.sys.loadModFrom:{[n;ns]
  .sys.log.info "Loading module ",(sn:string n)," from ",string ns;
  m: .sys.modules idx:exec last i from .sys.modules where name = n;
  if[not null idx; : idx]; // already there
  nns: sn,"__",string .sys.cnt+:1;
  if[not `cfg in key ns; @[ns;`cfg;:;(0#`)!()]];
  (nns:`$".",nns) set .sys.subst[get ns;string[ns],".";".",nns,"."];
  `.sys.modules upsert enlist .sys.modules[-1],`name`version`path`status`namespace`settings!(n;0;ns;`configured;nns;nns`cfg);
  @[nns;`ns`__mod__;:;(ns;`name`version`path!(n;0;ns))];
  : count[.sys.modules]-1;
 };

// Load a module as a singleton.
// load will return a valid index into .sys.modules or raise an exception.
.sys.loadI:{[n;v]
    // load first
    idx: .sys.loadMod[n;v;0W];
    if[`configured=.sys.modules[idx;`status];
        // try to execute mInit
        .sys.log.dbg "Calling ",string[n],".mInit function";
        if[not `mInit in key ns:.sys.modules[idx;`namespace]; : idx];
        .sys.modules[idx;`status]:`init_started;
        err:{[n;exc;st]
            .sys.log.err "Exception in mInit in module ",(n:string n),": ",exc;
            .sys.log.err "Stack trace: \n",.Q.sbt st;
            'n,":mInit"
        };
        if[not 11=type api:(),.Q.trp[ns`mInit;::;err n]; 'string[n],".mInit must return an API list"];
        .sys.modules[idx;`status`api]:(`inited;api);
    ];
    // if all is ok continue
    if[`inited=c:.sys.modules[idx;`status]; : idx];
    // something is wrong - maybe there is a loop
    if[c:c in ``loaded`configured`init_started; .sys.log.err "can't load module ",string[n],", probably there is a dependency loop. Check the stack trace:\n"];
    if[not c; .sys.log.err "can't load module ",string[n],", the reason is unknown. Check the stack trace:\n"];
    .sys.log.err "strace:\n",.Q.sbt .Q.btx .Q.Ll`;
    'string[n]":mInit"
 };

// Load an instance of a module
.sys.useI:{[args]
    m: .sys.modules idx: .sys.loadI[n:first args;0];
    if[`iInit in key ns:m`namespace;
        .sys.log.dbg "Calling ",string[n],".iInit function";
        nns: string[n],"__",string .sys.cnt+:1; // new namespace
        (nns:`$".",nns) set .sys.subst[get ns;string[ns],".";".",nns,"."];
        err:{[n;exc;st]
            .sys.log.err "Exception in iInit in module ",(n:string n),": ",exc;
            .sys.log.err "Stack trace: \n",.Q.sbt st;
            'n,":iInit"
        };
        .Q.trp[{x[0]. x 1};(nns[`iInit];$[1=count args;(),(::);1_args]);err n];
        .[ns;(`$"__mod__";`instances);,;nns];
        ns: nns;
    ];
    (ns;m`api)
 };

// Qute uses these fns instead of .z values to be able to use virtual time
.sys.P:{.z.P};
.sys.T:{.z.T};
.sys.D:{.z.D};
.sys.N:{.z.N};
.sys.p:{.z.p};
.sys.t:{.z.t};
.sys.d:{.z.d};
.sys.n:{.z.n};
.sys.exit:{exit x};

// system settings
.sys.host: .Q.host .z.a;
.sys.port: system "p";
.sys.timeout: system "T";
.sys.tinterval: system "t";
.sys.pid: .z.i;
.sys.uid: first 1?0Ng; // unique process id
// if 1b the process is started to test some functionality (maybe in PROD) - modules can use it
// to be more quiet - not send msgs, not create files and etc. It is added primarily to allow
// a user to start processes like rdb, tp and etc without them reporting their status, providing
// info to a gw and etc.
.sys.test:$[`test in key .sys.opt;"B"$first .sys.opt`test;0b];

// In normal case return just API functions, for tests we need the namespace too.
// useFrom - load the module from a namespace
.sys.use:(')[{r:.sys.useI x; r[1]!r[0] r 1};enlist];
.sys.xuse:(')[{@[{r:.sys.useI x; r[1]!r[0] r 1};x;{.sys.log.err ".sys.use failed with ",x; exit 1}]};enlist];
.sys.useFrom:(')[{.sys.loadModFrom[x 0;x 1]; r:.sys.useI enlist[x 0],2_x; r[1]!r[0] r 1};enlist];
.sys.useTest:(')[{r:.sys.useI x; (r[1],`ns)!(r[0] r 1),r 0};enlist];
.sys.getModule:{[p]
  if[not 99=type p; '"type"];
  w:$[`name in key p;enlist(=;`name;enlist p`name);()];
  if[`path in key p; w,:enlist(=;`path;enlist p`path)];
  if[`version in key p; w,:enlist(=;`version;p`version)];
  :?[.sys.modules;w;0b;()];
 };

.sys.help:{.sys.help: f:(.sys.use`help)`help; f x}; // defer module loading
.sys.logs.on:{.sys.logs_tmp,:enlist (x;y)}; // avoid a use loop
.sys.log:.sys.xuse[`log;`SYSTEM];
.sys.logs:.sys.xuse`event;
(.sys.logs.on .)each .sys.logs_tmp;
.sys.timer:.sys.xuse`timer;

if[`main in key .sys.opt;
  .sys.main: .sys.xuse each `$"," vs first .sys.opt`main;
 ];
