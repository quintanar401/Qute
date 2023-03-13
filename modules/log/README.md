## Module log

Module 'log' can be used to log messages to stdout/stderr/file/etc. You can redefine functions that form the final message, handlers to which messages are sent, set the log level to debug.
```Rust
// Basic usage
log: .sys.use[`log;`hdb];
log.err "all failed";
log.setLevel`debug;
log.dbg2[{.Q.s1[x],", ",.Q.s1 y};(table;dict)];

// Use .sys.logs to change handle/level for all/subset of loggers
.sys.logs.fireExt[`setLevel;`name`data!(`test;`normal)]; // specific name
.sys.logs.fire[`setHandle;{.file.h x}]; // all logs, normal, debug, warning msgs
.sys.logs.fire[`setEHandle;{.file.h x}]; // all logs, error msgs
```

### Init

Pass a dictionary with the following keys to set the corresponding variables: handle, ehandle, handler, ehandler, name. Or pass only `name` as a symbol or string.
```Rust
.mod.log: .sys.use[`log;`handler`name!({[n;p;c;m] -1 m};`hdb)];
.mod.log: .sys.use[`log;`hdb];
.mod.log: .sys.use`log; // name is not set
```

Handle and ehandle are functions that must accept a string and send it to a normal/error channel. The simplest example is `-1` or `-2`.

Handler and EHandler are functions that must construct a string from parts + any environment variables.
```
/ name is the module's name as "[NAME]"
/ prefix - one of " INFO ", " ERR  ", " WARN ", " DBG  "
/ caller - name of the function that called .log.xxx, not always available
/ msg - message itself
handler:{[name;prefix;caller;msg] string[.z.p],prefix,"[called from: ",caller,"] ",msg}
```

`log` will register event handlers - setHander, setEHandler, setLevel - with `.sys.logs`.

### log.info log.err log.warn log.dbg

Core functions that log messages with prefixes INFO, ERR, WARN and DBG. `log.error` logs them to `log.ehandle` (stderr by default), other functions to `log.handle` (stdout). `log.dbg` logs them only if `log.level` is `debug`. They have only one argument:
* msg(string) - message.

```Rust
log.info "Processing...";
```

### log.dbg2

Use this function to log complex debug messages. `fn` will be called only if `log.level` is `debug`.
* fn(function) - function that must create and return a string message.
* args(list) - list of arguments for `fn`.

```Rust
log.dbg2[{.Q.s1[x],", ",.Q.s1 y};(table;dict)];
```

### log.setLevel

Turn on/off debug messages.
* lvl(symbol) - One of: normal(default), debug.

```Rust
log.setLevel`debug;
```
