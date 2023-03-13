## Module IPC Disconnect

It is a plugin for IPC module. Adds automatic disconnect for outbound/inbound connections. Adds an additional parameter to the new connection: disconnectTimeout.

### ipc_disconnect.newconn settings

Additional settings for IPC new connection.

#### disconnectTimeout

Timeout for an outbound connection. Type: timespan, time. Optional. Null (default) means do not disconnect.
```
conn: conn[`disconnectTimeout;0D01];
```