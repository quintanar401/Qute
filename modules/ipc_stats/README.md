## Module IPC Stats

An add-on for the module IPC. Provides the following stats in .ipc.outbound/.ipc.inbound tables:
* lastIn - time of the last incoming message.
* lastOut - time of the last outcoming message.
* numIn - total number of incoming messages.
* numOut - total number of outcoming messages.
* sizeIn - total size of incoming messages.
* sizeOut - total size of outcoming messages.

Requires IPC, Resource Manager modules, adds handlers to .z.ps, .z.pg, .z.ws, outbound.send, outbound.asend, outbound.wssend. To enable:
```
.sys.use`ipc_stats;
```