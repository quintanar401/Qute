## Module Message Bus

Send/get messages from other processes.

The default configuration (as an `IPC` new connection settings) can be put into `mbus.json` file.

To override:
* add -mbus \[name:\]\[host:\]port parameter to the process.
* call `sys.use` with a dictionary with `mbus` field with the the same format:
```Rust
m:.sys.use[`mbus;`mbus`address!(IPC settings;address)];
```

### Configuration

IPC settings in `mbus.json` file.