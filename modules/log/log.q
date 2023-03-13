.log.level:`normal;
.log.handle:-1;
.log.ehandle:-2;
.log.name:`; // module name

.log.mInit:{[cfg] `info`err`dbg`dbg2`warn`setLevel};

.log.iInit:{[cfg]
    // possible init arguments
    // .sys.use`log; // as is
    // .sys.use[`log;`name] or .sys.use[`log;"name"]; // name can be used to make msgs more distinct: HDB, RDB, TIMER and etc
    // .sys.use[`log;`name`handler!(`x;{...})]; // generic init, params: `handle`ehandle`handler`ehandler`name
    if[99=t:type cfg;@[.log.ns;n;:;cfg n:`handle`ehandle`handler`ehandler`name inter key cfg]];
    if[-11=t; .log.name:cfg];
    if[10=t; .log.name:`$cfg];
    if[system "e"; .log.level:`debug];
    f:{if[`name in key y; if[not .log.name=y`name;:()]]; x y`data};
    .sys.logs.on[`setLevel;f .log.setLevel];
    .sys.logs.on[`setHandle;f {.log.handle:x}];
    .sys.logs.on[`setEHandle;f {.log.ehandle:x}];
    .log.sname:10$"[",string[.log.name],"]"
 };

.log.handler:{[name;prefix;caller;msg] string[.sys.P[]],prefix,name,msg," [",caller,"]" };

.log.ehandler:.log.handler;

.log.info:{[msg]
    // Log a message to the log channel.
    // @param msg string Message.
    .log.handle .log.handler[.log.sname;" INFO ";.log.caller[];msg]
 };

.log.err:{[msg]
    // Log a message to the error log channel.
    // @param msg string Message.
    .log.ehandle .log.ehandler[.log.sname;" ERR  ";.log.caller[];msg]
 };

.log.dbg:{[msg]
    // Log a message to the log channel if in debug mode.
    // @param msg string Message.
    if[.log.level=`debug; .log.handle .log.handler[.log.sname;" DBG  ";.log.caller[];msg]]
 };

.log.dbg2:{[fn;lst]
    // Construct a message and log it to the log channel if in debug mode. Can be used to avoid construction of complex messages.
    // @param fn func Constructor function.
    // @param lst list Arguments for fn.
    if[.log.level=`debug; .log.handle .log.handler[.log.sname;" DBG  ";.log.caller[];fn . (),lst]]
 };

.log.warn:{[msg]
    // Log a message to the log channel.
    // @param msg string Message.
    .log.handle[.log.sname;" WARN "; .log.handle .log.caller[];msg]
 };

.log.setLevel:{[lvl]
    // Set log level.
    // @param lvl symbol Possible values: `normal,`debug.
    if[not lvl in `normal`debug; '"wrong log level"];
    .log.level: lvl
 };

.log.caller:{ (.Q.btx .Q.Ll`)[2;1;0] };
