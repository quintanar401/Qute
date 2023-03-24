.help.log: .sys.use[`log;`HELP];

.help.mInit:{`help};

.help.dropBlanks:{x where 0<sums count each x};

.help.extract:{[txt;name] if[0=count r:.help.dropBlanks 1_ txt first where (txt[;0] like "##*")&txt[;0] like "*",name,"*"; r:enlist "Not available"]; r};

.help.extractApi:{[txt;n]
  r: .help.dropBlanks 1_txt first where (txt[;0] like "###*")&txt[;0] like "*.",string[n],"*";
  if[0=count r; :("Not available";enlist "Not available")];
  l:$[null i:first ss[r 0;". "];r 0;(i+1)#r 0];
  :(l;r);
 };

/ Load README.md if available.
.help.loadMod:{[m]
  if[not m[`path] like ":*"; :(1#`)!enlist enlist "Not available"];
  if[not -11=type key p:` sv m[`path],`README.md; :(1#`)!enlist enlist "Not available"];
  .help.log.info "Loading help for ",string[m`name]," from ",string p;
  txt:@[read0;p;{.help.log.err "Couldn't load ",strong[x],": ",y; 'y}p];
  txt:(where (not txt like "####*")&txt like "##*")_txt;
  hlp:`description`minit`iinit!(.help.extract[txt;"Module"];
        ("Module parameters";.help.extract[txt;"Configuration"]);("Instance parameters";.help.extract[txt;"Init"]));
  a:m`api;
  if[not `inited=m`status; // do our best to find help
    a:`${(-1+count x)_y first where (y:" "vs y)like x}[p] each t where (t:txt[;0]) like "* ",p:string[m[`name]^$[`ns in m`settings;`$m[`settings]`ns;`]],".*"
  ];
  hlp,:a!.help.extractApi[txt] each a:a,$[`smartHelp in key ns:m`namespace;key ns`smartHelp;()];
  :hlp;
 };

.help.map:(1#-1)!();
.help.uninited:0#0;

.help.findMod:{[n]
  m:exec i from .sys.modules where name=n, status=`inited;
  if[0=count m; m: exec i from .sys.modules where name=n, version=max version];
  if[0=count m; '"module ",string[n]," doesn't exist"];
  mm:.sys.modules m: last m;
  if[(isI:`inited=mm`status)&m in .help.uninited; .help.uninited:.help.uninited except m; .help.map:m _ .help.map];
  if[not m in key .help.map; .help.map[m]: .help.loadMod mm];
  if[not isI; .help.uninited,:m];
  : m;
 };

.help.help:{[n]
  if[n~(::); :enlist["Available modules:"],"  ",/:string asc distinct .sys.modules`name];
  if[-11=type n; n:string n];
  if[not "." in n;
    m: .help.findMod `$n;
    h: .help.map m; m: .sys.modules m;
    res:enlist["Module ",n],h`description;
    if[`minit in key h; res,:enlist "Module parameters: ",n,".cfg"];
    if[`iinit in key h; res,:enlist "Instance parameters: ",n,".init"];
    res,:("";"API:");
    res,:("  ",n,"."),/:{string[x],": ",y 0}'[k;h k:key[h] except`description`minit`iinit];
    : res;
  ];
  e:`$(1+i:n?".")_n; n:i#n;
  m: .help.findMod `$n;
  h: .help.map m; m: .sys.modules m; e1: first ` vs e;
  if[e1 in $[`smartHelp in key ns:m`namespace;key sh:ns`smartHelp;`$()];
    if[null e2:first 1_ ` vs e; : sh[e1][`helpg][]];
    if[not e2=`raw; : sh[e1][`helps] e2];
    e: e1;
  ];
  if[e=`cfg; : ("Module parameters";""),$[`minit in key h;h[`minit]1;enlist "Not available"]];
  if[e=`init; : ("Instance parameters";""),$[`iinit in key h;h[`iinit]1;enlist "Not available"]];
  if[not e in key h; :enlist "Unknown name: ",string e];
  : (string e;""),h[e]1;
 };
