.smart.conf:([] name:0#`; typ:0#`; optional:0#0b; default:(); value_type:(); convert_to:(); setter:(); getter:());
`.smart.conf upsert (`validate;`action;1b;::;`$();`$();`.smart.validate;`.smart.validate);
`.smart.conf upsert (`help;`action;1b;::;`$();`$();`.smart.helps2;`.smart.helpg);
`.smart.conf upsert (`cfg;`param;1b;::;1#`dict;`$();`.smart.setCfg;`.smart.getCfg);

.smart.defCols:cols .smart.conf;

.smart.helpData:();
.smart.plugins:`$();

.smart.dropBlanks:{x where 0<sums count each x};

.smart.helps2:{[cfg;n]
    if[(::)~n; : select name, typ, optional, value_type, convert_to, current_value: cfg name from .smart.conf];
    : .smart.helps n;
 };

.smart.helps:{[n]
    if[0=count .smart.helpData; .smart.loadHelp[]];
    if[not n in key .smart.helpData; :enlist "Unknown name"];
    : .smart.helpData[n] 1;
 };

.smart.helpg:{[cfg]
    if[0=count .smart.helpData; .smart.loadHelp[]];
    : {string[x],": ",y 0}'[key db;value db:.smart.helpData];
 };

.smart.loadHelp:{
    h: raze {{(0^first where x like "####*")_x} (.sys.use`help)[`help] ` sv x,`raw} each .smart.id,.smart.plugins;
    d:.smart.dropBlanks each 1_'n:(where h like "####*")_ h;
    n:`$(1+n?\:" ")_'n:first each n;
    dd:(1+dd?\:".")#'dd:d[;0];
    .smart.helpData:(sn!count[sn:.smart.conf`name]#enlist("Not available";"Not available")),n!(enlist each dd),'enlist each d;
 };

// set new values one by one using the correct setters
.smart.setCfg:{[cfg;dict]
    if[not all k:key[dict] in .smart.conf`name; '"smart: invalid field(s): ",", "sv string key[dict]where not k];
    t:select name, typ, setter, tfn from .smart.conf where name in key dict;
    if[`action in t`typ; '"smart: action can't be set: ",", "sv string t[`name] where `action=t`typ];
    : {.smart.setParam[y;z;x z`name]}[dict]/[cfg;t];
 };

// return all global and defined local params
.smart.getCfg:{[cfg] 
    r: exec name!getter@\:(::) from .smart.conf where typ=`global;
    r,exec name!getter@'cfg name from .smart.conf where name in key cfg
 };

.smart.new:{
    // new smart handle
    // .smart.new[] - default
    // .smart.new ()!() - with params
    (')[.smart.exec $[99=type x;.smart.setCfg[.smart.def;x];.smart.def];enlist]
 };

// Execute a cmd
.smart.exec:{[cfg;args]
    // check correctness
    if[$[-11=type cmd:first args;not cmd in .smart.conf`name;1b]; '"smart: invalid field: ",20 sublist .Q.s1 cmd];
    pcfg: .smart.conf .smart.conf[`name]?cmd;
    if[`=pcfg`name; "invalid parameter: ",string cmd];
    // action/get
    if[1=count args;
        if[(`param=pcfg`typ)&((::)~f:pcfg`getter)&not cmd in `cfg,key cfg; '"parameter ",string[cmd]," is not set"];
        : $[(::)~f;cfg cmd;f cfg];
    ];
    if[`action=pcfg`typ; :pcfg[`setter][cfg] . 1_ args];
    cfg: .smart.setParam[cfg;pcfg;args 1];
    // return a new handle
    (')[.smart.exec cfg;enlist]
 };

.smart.setParam:{[cfg;pcfg;arg]
    f:pcfg`setter;
    // check/conv type and update cfg
    a: pcfg[`tfn] arg;
    r: $[f~(::);a;f[cfg;a]];
    if[`param=pcfg`typ; $[`cfg=nm:pcfg`name;cfg: r;cfg[nm]: r]];
    cfg
 };

.smart.mInit:{[cfg] `new`validate`extend`helps`helpg};

// type -> type num
.smart.tMap:{{(k i)!value[x]i:where not `=k:key x} "h"$((`$upper q)!c),(`$q:(),/:q)!neg c:til count q:-1_.Q.t}[];
.smart.tMap[`dict]:99h;
.smart.tMap[`fn]:100h;
.smart.tMap[`table]:98h;
// type num -> str
.smart.tsMap: {((type each t)!`$string[k],\:" list"),(neg type each t)!k:key each t:"bxhijeftuvdpns"$\:()}[];
.smart.tsMap["h"$100+til 12]:`function;
.smart.tsMap[99 98 -10 10h]:`dictionary`table`char`string;
// converts from one type to another
// trivial: "b" -> "b"
// simple: "i" -> "j"
// other: "i" -> "n", to millis
.smart.typeConvMap:(!). flip
    (raze {((2#`$upper x;::);((`$x),`$upper x;enlist);(2#`$x;::))} each "bxhijeftuvdpnsc"),(
    (`dict`dict;::);
    (`fn`fn;::);
    (`table`table;::);
    (`t`n;"n"$);
    (`u`n;"n"$);
    (`v`n;"n"$);
    (`i`j;"j"$);
    (`n`t;"t"$);
    (`u`t;"t"$);
    (`v`t;"t"$);
    (`d`p;"p"$);
    (`T`N;"n"$);
    (`U`N;"n"$);
    (`V`N;"n"$);
    (`I`J;"j"$);
    (`N`T;"t"$);
    (`U`T;"t"$);
    (`V`T;"t"$);
    (`D`P;"p"$);
    (`t`N;{enlist "n"$x});
    (`u`N;{enlist "n"$x});
    (`v`N;{enlist "n"$x});
    (`i`J;{enlist "j"$x});
    (`n`T;{enlist "t"$x});
    (`u`T;{enlist "t"$x});
    (`v`T;{enlist "t"$x});
    (`d`P;{enlist "p"$x});
    (`t`j;"j"$);
    (`j`i;"i"$);
    (`C`s;`$)
 );
.smart.typeConvMap:(.smart.tMap key .smart.typeConvMap)!value .smart.typeConvMap;
.smart.typeConvMap[("h"$100+til 12),\:100h]:(::);

.smart.preprocCfg:{[cfg]
    if[$[98=type cfg;10=type first cfg`name;0b]|0=type cfg;
        // list of cfg entries from json -> convert to a table
        cfg:c#/:((c:.smart.defCols)!("";"param";0b;"::";();();"::";"::")),/:cfg;
        val:{
            if[any x~/:("getter";"setter"); if[all y in .Q.an,"."; :`$y]];
            $[10=type y;@[value;y;{'"couldn't parse value of name=",string[y],", option=",x,", with ",z}[x;z]];y]
        };
        f:{$[not 10=type x;x;x in ("dict";"fn";"table");x;(),/:x]};
        cfg:update `$((),/:name), `$typ, `$f each value_type, `$f each convert_to from cfg;
        cfg:update default:val["default"]'[default;name], getter:val["getter"]'[getter;name], setter:val["setter"]'[setter;name] from cfg;
    ];
    if[not all c in cols cfg; cfg:c#cfg,'count[cfg]#(c except cols cfg)#enlist c!(`;`param;0b;::;();();::;::)];
    : cfg;
 };

.smart.processCfg:{[cfg]
    // type check
    if[not all raze t1:(t2:cfg[`value_type],'cfg`convert_to) in key .smart.tMap;
        {if[all x; :()]; '"invalid value/convert type(s) in parameter ",string[z],": ",
            ", "sv string y where not x}'[t1;t2;cfg`name];
    ];
    // setup the type check and conversion
    ch:{
        if[not count y:(),y; :y];
        f:{
            if[(t:type z) in y; :z];
            // try to convert from string
            if[(t in 0 10h)&(t2:.Q.t abs yy:first y)in .Q.t except " gc";
                if[not 10=type z:@[upper[t2]$;z;::]; :$[yy<0;z;(),z]]; // conversion is succ
            ];
            // allow float -> int/long conversion too
            if[t in 9 -9h;$[any 6 7h in y;:(),("ij" 7h in y)$z;(t=-9)&any -6 -7h in y;:("ij" -7h in y)$z;::]];
            'string[x],": invalid type, allowed types: ",", " sv string distinct (),.smart.tsMap y;
            };
        if[`fn in y; v:{$[count y;value y;value[x],enlist ()]}[f x] .z.s[x;y except `fn]; :v[0][v 1;v[2],"h"$100+til 12]];
        f[x;.smart.tMap y]
        };
    chf:ch'[cfg`name;cfg`value_type];
    cv:{[ch;vt;conv]
        if[0=count ch; :(::)]; // do nothing
        if[0=count conv:(),conv; :ch]; // type check only
        if[count[vt]>i:(vt:(),vt)?`fn; conv:(conv where not vt=`fn),conv 12#i]; // adjust for fn
        ty:value[ch] 2; // allowed types
        if[not all e:(ty2:ty,'count[ty]#.smart.tMap conv)in key .smart.typeConvMap; '"invalid conversion(s): ",", "sv {x[0],"->",x 1} each string distinct .smart.tsMap ty2 where not e];
        {y[type z] x z}[ch;ty!.smart.typeConvMap ty2] // check type and convert
    };
    :update tfn:cv'[chf;value_type;convert_to] from cfg;
 };

// Possible cfg values:
// * (dict;dict;..) - list of options, expected to be read from a json cfg
// * table - options as a table
.smart.iInit:{[id;cfg]
    .smart.id: id;
    cfg: 0!select by name from .smart.conf,.smart.preprocCfg cfg;
    .smart.conf: .smart.processCfg cfg;
    // default cfg
    .smart.def: (enlist[`]!()),exec name!default from .smart.conf where typ=`param, not default~\:(::);
 };

.smart.validate:{[cfg]
    if[all i:(n:exec name from .smart.conf where not optional, typ=`param) in key cfg; :cfg];
    '"Missing required parameter(s): ",", "sv string n where not i;
 };

.smart.extend:{[src_ns;cfg]
    cfg: .smart.processCfg .smart.preprocCfg cfg;
    .smart.conf: 0!select by name from .smart.conf,cfg;
    .smart.def: (enlist[`]!()),exec name!default from .smart.conf where typ=`param, not default~\:(::);
    .smart.plugins,: ` sv src_ns,1_ ` vs .smart.id; / ipc.newconn -> ipc_plugin.newconn
    .smart.helpData: ();
 };