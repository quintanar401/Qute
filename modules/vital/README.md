### Module Vital

Connects to a master process and exits if the connection gets disconnected.

Connection parameters in IPC new connection format can be passed via a `master.json` config file or in module's params.

`vital` will add a connection with name `vital:host:port` by default (name can be redefined in params).

```Rust
.sys.use[`vital;2020]; // connect to 2020 (optionally using master.json)
.sys.use[`vital;`host`port!(`a;2020)]; // any IPC params can be passed directly
```

`vital` will exit immediately if it can't open the connection.