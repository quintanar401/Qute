## Module IPC

Manages inbound and outbound socket connections. Instead of raw handles it provides connection objects that provide additional functionality - logging, stats, auto reconnect and etc. 

Depends on: Resource Manager, Handler Manager, Event modules.

Outbound connections support:
* unique names - minimize number of opened connections.
* auto disconnect - drop inactive handles.
* unix/ssl connections.
* IPC plugins with additional functionality.

Generic outbound events:
* outbound.connect, data argument: name - on the first connect.
* outbound.disconnect, data argument: name - on disconnect.
* outbound.reconnect, data argument: name - on each reconnect (each connect after the first one).
* outbound.connect_failed, data argument: name - user initiated connect failed.
* outbound.add, data argument: (name;newConnDict) - on add action.
```q
ev:(.sys.use`ipc)[`events][];
ev.on[`outbound.connect;`myhandler;{[ev] ... ev`data ...}]; / and other 'event' functions
```

Specific event handlers:
* onConnect option in new connect smart pointer.

You can setup a generic handlers via rmanager API:
```q
.sys.use[`rmanager][`setHandlerAt][`.z.ps;`before`exec;`some_name;`.some.handler];
.sys.use[`rmanager][`setHandler][`.z.pc;`some_name`;`.some.onClose];
.some.handler:{[v] returns either (`CANCEL;result) or v};
```
IPC adds `ipc.open` to .z.po/.z.wo, `ipc.close` to .z.pc/.z.wc, `ipc.exec` to .z.ps, .z.pg before the generic `exec` handler. 
You can setup you handler for specific outbound/inbound handles using a connection smart pointer:
```q
i:.sys.get`ipc;
p:i.get`current; // get a smart ptr for the current handle (.z.w)
p[`onExec;{[ptr;msg] ... }];
```

IPC plugins:
* ipc_stats - number of in/out requests, in/out size for inbound/outbound connections.
* ipc_reconnect - automatic connect/reconnect on disconnect.
* ipc_disconnect - automatic disconnect after a timeout.
```q
.sys.use`ipc_stats; / inits ipc automatically
```

### ipc.new

Create a new connection. Returns a newconn smart pointer.
```q
p: ipc.new[];
h: p[`name;`myConn][`host;`xxx][`port;1010]`open;
// set params rightaway
p: ipc.new `name`host`port!(`myConn;`xxx;1010);
```

### ipc.events

Get IPC event manager.
```q
ev:ipc.events[]
ev.on[`outbound.disconnect;`myhandler;{[ev] ...}];
```

### ipc.defer

Defer a sync response. Use `conn.deferSend` to send the reponse.
```q
.sys.ipc`defer;
...
h[`deferSend;isException;data];
```

### ipc.broadcast

Send a broadcast async message. Params: a list of `conn` smart handles and message. All input smart handles are expected to be outbound connections atm.
```
.sys.ipc.broadcast[(h1;h2);"1+1"];
```

### ipc.addPlugin

Add an IPC plugin. See ipc_stats code as an example.

### ipc.newconn settings

New connection smart pointer settings.

#### name

Optional name for the connection. Type: symbol. By default it is "host:port\[:user\]".
```q
conn: conn[`name;`hdb];
```

#### host

Optional host name (localhost by default). Type: symbol.
```q
conn: conn[`host;`some.srv];
```

#### port

Port number. Type: int, long.
```q
conn: conn[`port;2001];
```

#### user

Optional user name. Type: symbol.
```q
conn: conn[`user;`kdbprod];
```

#### password

Optional password. Type: string.
```q
conn: conn[`password;"12345"];
```

#### connectionTimeout

Connection timeout in ms. Type: int, long, time. Optional. The default value is taken from connectionTimeout config variable (60 sec).
```q
conn: conn[`connectionTimeout;00:00:01.000];
```

#### requestTimeout

The default timeout in ms for this connection on sync requests. Type: int, log, time. Optional. The global default value is taken from requestTimeout config variable.
```q
conn: conn[`requestTimeout;1000];
```

#### unix

Use unix domain sockets. Type: bool. Optional. `host` is expected to be `localhost`. The default value is taken from unix config variable (1b).
```q
conn: conn[`unix;0b];
```

#### ssl

Use a secure connection. Type: bool. Optional. False by default.
```q
conn: conn[`ssl;1b];
```

#### unique

How to handle a name conflict. Type: symbol. Optional, \`no by default. Other values: \`yes.
* no - overwrite. Disconnect if needed and reconnect if any of the following fields differ: host, user, password, ssl, unix. Return the existing handle otherwise.
* yes - throw an exception if this name already exists.
  
```q
conn: conn[`unique;`yes];
```

#### onConnect

Handler to run on each connect/disconnect. Type: symbol or function. Optional. The handler will get a dictionary with `name` (connection name) and `status` (bool, 1b on connect) fields.
```q
conn:conn[`onConnect;`.mymod.onConnect];
.mymod.onConnect:{if[x`status; .. connected ..]};
```

#### add

Add a new connection. Just add a new conection, do not connect (unless requested). Returns a connection smart pointer.
```q
conn: conn`add;
conn: conn`connect; / can be used to connect explicitly
```

#### is0

Check if host:port point to the caller. 0 outbound handles are not allowed.

### ipc.conn settings

Connection smart pointer settings.

#### connect

Start to connect. Not applicable to inbound connections. Returns 1b/0b (success/failure).

#### disconnect

Disconnect an inbound/outbound connection. The inbound connection is checked for validity, stale handles will be ignored.

#### send asend trySend tryASend

Execute a (a)sync query. Inbound connections are checked for validity to avoid stale handles. `try` means return 0b if the conenction is disconnected.

#### setHandler

Set an execution handler specific to this connection. `result` contains the result for the sync call.
```q
.my.handler:{[ptr;msg] $[.sys.ipc.env[]`sync;ptr[`result;count msg];ptr[`asend;count msg]]}; 
conn[`setHandler;`.my.handler] // or conn[`setHandler;.my.handler]
```

#### onClose

Set a handler to be called on close. For an inbound connection the handler will be called on close with a dictionary with `status` field set to `0b` and `handle` field set to the `q` handle.
For an outbound the result is similar to newconn.onConnect setting.

#### setName

Set a name for an inbound connection.
```q
(ipc.get`current)[`setName;`user]
```

#### timeout

N/A atm

#### result

Set/get the current sync call result. IPC handlers set via `setHandler` are called with 2 arguments: `conn` smart pointer and the incoming message. 
If the call is sync they can set/get its result:
```q
handler:{[ptr;msg] if[.sys.ipc.env[]`sync; ptr[`result;@[value;msg;{(`EXCEPTION;x)}]]]};
```
Unhandled exceptions are printed in the log, set the result to (`EXCEPTION;str) if it is not an unexpected exception.

#### isAlive

Check if the connection is alive.
```q
if[conn`isAlive; conn[`asend;"10"]];
```

#### getHandle

Get the underlying `q` handle. It can be null if the connection is disconnected.

#### deferSend

Send a response to a defered request. Use `ipc.defer` to defer the request.
```q
ipc`defer;
...
h[`deferSend;isException;data];
```

#### get

Get the value of a column in inbound/outbound table.
```q
h[`get;`lastConnect]
```