## Module Message Bus Server

Message Bus Server module can be used to connect several Q processes and pass messages between them. Servers connect to each other and it is expected that there is only one server per host (or host+cluster, host+dev user and etc) to reduce the number of connections. MBus clients can be used to connect Q processes to servers. Clients can then use channels to pass messages between themselves. Servers connect to each other and clients form a star with a server in the center.

MBus should not be used to pass realtime tick data but it can be used to find the data source/consumer.

Startup example:
```bash
q core/loader.q -main mbus_server -mservers 3010 -t 100 -p 3010
# client
q core/loader.q -main mbus -mbus 3010 -t 100 -p 3001
```

A publisher calls one of `send`, `post`, `pin` functions to publish a message.
* send - just sends a message.
* post - message will be saved on the servers while the client is alive and sent to all new subscribers.
* pin - like post but the message will never be deleted (it can be updated).

The publisher must provide at least one address field. These fields can contain any data. Subscribers use these fields to select specific messages. An MBus client/server can be configured with default address fields (like region, host), they will be added to each message. Names that start with "." are reserved.

A subscriber must also specify an address. It can be inexact, the following rules apply:
* if a field contains a string that contains a "*", then the field is treated as a pattern.
* if a field contains a list of atoms/strings and the incoming message has an atom/string in this field then "in" is used.
* if a field contains a function, the function is called with the incoming value and must return a bool to indicate match/no match.
* if a field contains (::), then the field must be present in the incoming message, its value is irrelevant.

For example:
```Rust
// publisher, set asset,proc as default fields
mbus: .sys.use[`mbus;`asset`proc!(`stock;`hdb)];
mbus: .sys.use[`mbus;`asset`proc!(`fx;`hstat)];
...
mbus.send `msg`event!(::;`hdb.reload);
// subscriber - collect reloads from all hdbs
mbus.sub `event`asset`proc`cb!(`hdb.reload;::;"h*";{..});
mbus.sub `event`asset`proc`cb!(`hdb.reload;::;{x in `hdb`hstat};{..});
mbus.sub `event`asset`proc`cb!(`hdb.reload;::;`hdb`hstat;{..});
```

If the subscriber provided fewer fields than the publisher, then extra fields will be ignored. A subscriber can use `.extra` field (function) to change this behaviour. The function will be called with the message and a list of extra fields and must return a bool value - match/no match:
```Rust
// allow only instance field, any other is probably an error
mbus.sub `event`asset`proc`.extra`cb!(`hdb.reload;::;"h*";{y~(),`instance};{..});
```

There are special system fields: `.id` (sender's uid), `.ts` (timestamp). They are ignored by default but the subscriber can add a filter on them if it wants so (select messages from a specific process for example).

`msg` field is also ignored because it contains the message's data. Again the subscriber may add a filter for this field if it wants.

`.notify` - inform the subscriber (via `cb`) that the subscription is added and pending msgs (if any) are sent.

Server configuration:
* a list of other servers (may include the server itself)
* optional default address fields (region, host and etc)
* optional connect/reconnect timeout and other IPC connection settings

MBus Server list can be passed (by priority):
* as a parameter in `.sys.use`.
* in a command line: -mbus srv1:p1,srv2:p2,p3
* in a config file: servers.json

servers.json format:
```
[
    {
        "name": "srv1",
        "enabled": true,
        "address": {
            "region": "emea",
            "host": "..."
        },
        "connection": {
            "host": "host",
            "port": port,
            "reconnectSchedule": "0D00:01",
            ... and other IPC new connect settings ...
        }
    },
    ....
]
```