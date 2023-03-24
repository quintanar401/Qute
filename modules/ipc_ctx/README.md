## IPC Context Module

`IPC Context` sets some context variables in `.z.pg`, `.z.ps` that can be obtained via `env` call:
* sync - bool, sync/async call.
* msg - original message.
* msg0 - msg passed to 0 handle from within another call.
* realUser - the user who initiated the request but wants to execute it under another username (for test purposes for example).
* user - the user under which the request is executed. It should be used in ACL, logs, etc.
* appUser - can be used by applications. `origUser` is then the app's user name and `user` is the actual user.
* quser - "raw" user (.z.u).
* host - hostname.
* handle - handle.
* reqContext - optional request context, see below.
Variables are set in `ipc_ctx.start` handler. Handlers defined after it can access the context. The context is removed in `ipc_ctx.end.res` handler to avoid unintended usage.
For 0 handle `msg0` field is added, other fields remain the same.

The module supports the following service message in `.z.ps` and `.z.pg` (`ipc_ctx.start` handler):
```
(`ipc_ctx.request;ipcDict;request)
```
It updates the context with ipcDict (supported fields are realUser, user, appUser), also ipcDict is saved in reqContext field. `msg` is set to `request`. `request` can be another IPC message.
```q
.sys.ctx:.sys.use`ipc_ctx;
.acl.check[.sys.ctx.env[]`user;req];
// exec a req on another srv as the current user, add an additional context parameter
h[`send;(`ipc_ctx.request;update someData:10 from `user`appUser#.sys.ctx.env[];"1+1")]
```
