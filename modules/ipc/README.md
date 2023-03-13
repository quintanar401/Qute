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
```Rust
ev:(.sys.use`ipc)[`events][];
ev.on[`outbound.connect;`myhandler;{[ev] ... ev`data ...}]; / and other 'event' functions
```

Specific event handlers:
* onConnect option in new connect smart pointer.

Also you can setup a generic handler via rmanager API. IPC adds `.ipc.open` to .z.po/.z.wo, `.ipc.close` to .z.pc/.z.wc, `.ipc.exec` to .z.ps, .z.pg before the generic `exec` handler. You can setup you handler for specific outbound/inbound handles using connect smart pointer:
```Rust
i:.sys.get`ipc;
p:i.get`current; // get a smart ptr for the current handle (.z.w)
p[`onExec;{[isSync;ptr;msg] ... }];
```

IPC plugins:
* ipc_stats - number of in/out requests, in/out size for inbound/outbound connections.
* ipc_reconnect - automatic connect/reconnect on disconnect.
* ipc_disconnect - automatic disconnect after a timeout.
```Rust
.sys.use`ipc_stats; / inits ipc automatically
```

### ipc.new

Create a new connection. Returns a newconn smart pointer.
```Rust
p: ipc.new[];
h: p[`name;`myConn][`host;`xxx][`port;1010]`open;
// set params rightaway
p: ipc.new `name`host`port!(`myConn;`xxx;1010);
```

### ipc.events

Get IPC event manager.
```Rust
ev:ipc.events[]
ev.on[`outbound.disconnect;`myhandler;{[ev] ...}];
```

### ipc.addPlugin

Add an IPC plugin. See ipc_stats code as an example.

### ipc.newconn settings

New connection smart pointer settings.

#### name

Optional name for the connection. Type: symbol. By default it is "host:port\[:user\]".
```Rust
conn: conn[`name;`hdb];
```

#### host

Optional host name (localhost by default). Type: symbol.
```Rust
conn: conn[`host;`some.srv];
```

#### port

Port number. Type: int, long.
```Rust
conn: conn[`port;2001];
```

#### user

Optional user name. Type: symbol.
```Rust
conn: conn[`user;`kdbprod];
```

#### password

Optional password. Type: string.
```Rust
conn: conn[`password;"12345"];
```

#### connectionTimeout

Connection timeout in ms. Type: int, long, time. Optional. The default value is taken from connectionTimeout config variable (60 sec).
```Rust
conn: conn[`connectionTimeout;00:00:01.000];
```

#### requestTimeout

The default timeout in ms for this connection on sync requests. Type: int, log, time. Optional. The global default value is taken from requestTimeout config variable.
```Rust
conn: conn[`requestTimeout;1000];
```

#### unix

Use unix domain sockets. Type: bool. Optional. `host` is expected to be `localhost`. The default value is taken from unix config variable (1b).
```Rust
conn: conn[`unix;0b];
```

#### ssl

Use a secure connection. Type: bool. Optional. False by default.
```Rust
conn: conn[`ssl;1b];
```

#### unique

How to handle a name conflict. Type: symbol. Optional, \`no by default. Other values: \`yes.
* no - overwrite. Disconnect if needed and reconnect if any of the following fields differ: host, user, password, ssl, unix. Return the existing handle otherwise.
* yes - throw an exception if this name already exists.
  
```Rust
conn: conn[`unique;`yes];
```

#### onConnect

Handler to run on each connect/disconnect. Type: symbol or function. Optional. The handler will get a dictionary with `name` (connection name) and `status` (bool, 1b on connect) fields.
```Rust
conn:conn[`onConnect;`.mymod.onConnect];
.mymod.onConnect:{if[x`status; .. connected ..]};
```

#### add

Add a new connection. Just add a new conection, do not connect (unless requested). Returns a connection smart pointer.
```Rust
conn: conn`add;
conn: conn`connect; / can be used to connect explicitly
```

#### is0

Check if host:port point to the caller. 0 outbound handles are not allowed.

### ipc.conn settings

#### name id handle

Readonly fields. Name is set for an outbound connection, handle and id for inbound.

#### connect

Start to connect. Not applicable to inbound connections.

#### disconnect

Disconnect an inbound/outbound connection. The inbound connection is checked for validity, stale handles will be ignored.

#### send asend trySend tryASend

Execute a sync/async query. Inbound connections are checked for validity to avoid stale handles. Try means return 0b if the conenction is disconnected.

#### setHandler

Set an execution handler for the specific handle.
```Rust
.my.handler:{[isSync;ptr;msg] $[isSync;ptr[`result;count msg];ptr[`asend;count msg]]}; 
conn[`setHandler;`.my.handler] // or conn[`setHandler;.my.handler]
```