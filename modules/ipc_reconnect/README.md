## Module IPC Reconnect

It is a plugin for IPC module. Adds automatic reconnect on open/add/disconnect. Adds additional parameters to the new connection: reconnectSchedule, autoConnect.

### ipc_reconnect.newconn settings

Additional settings for IPC new connection.

#### reconnectSchedule

A list of delays for each reconnect attempt. Type: timespan, timespan list. Optional. The last value will be used for all extra attempts. Null value means stop attempts.
```
conn: conn[`reconnectSchedule;(10#0D00:01),(10#0D00:10)];
conn: conn[`reconnectSchedule;0D00:01]; / reconnect until success every minute
conn: conn[`reconnectSchedule;0D00:01,0Nn]; / try once and stop
```

#### autoConnect

Initiate connect after the connection is added (see add action). Type: bool. Optional.
```
conn[`autoConnect;1b]`add;
```