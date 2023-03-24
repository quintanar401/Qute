## Gateway module

`gw` is fully async and accepts both sync and async calls. It supports the following protocol:

* Clients publish their API and connection info on a specific channel (via `gwclient` for example).
* `gw` subscribes to this channel and adds processes to its routing table.
* `gw` maintains a direct connection to each client (inactive clients can be turned off optionally).
* On a user request it selects matching clients and sends an async request to them. If the incoming connection is sync the reply will be delayed.
* The clients send back (async) their responses.
* `gw` collects all responses, merges them and sends to the user.

`gw` process id: `gw.GWTYPE.INSTANCE`. GWTYPE is used to load configuration files:
* \[GWTYPE/\]subdef.json - description of params in `validator` format.
* \[GWTYPE/\]sub.json - params themselves.
* \[GWTYPE/\]ipc.json - IPC params to open client connections (`ipc.newconn`).

`sub.json` may contain additional subscription settings to select a subset of clients.

By default `gw` subscribes to the following messages:
* apiInfo - supported API functions.
* pid - symbol, process id. `pid` + `primary` is expected to be unique.
* pgroup - symbol, processes in one group are interchangeable, `gw` can/will send a request to any (but only one) of them. HDB replicas for example.
* cid - long, client ID to match requests/responses.
* host - symbol, client's host.
* port - int, client's port.
* user - symbol, optional, client's user.
* primary - bool, for DR. Non primary clients will be used only if primary is not available.
 
`apiInfo` is a table with columns:
* name - symbol, function's name.
* basicFilter - dict, argNames->consts, preliminary filter by data source, db name and etc.
* check - symbol, optional name of a module with `check` function, that does a preliminary check and update of args after basicFilter is applied.
* timeFilter - symbol, optional time filter
* filter - symbol, optional name of a module with `filter` function, that does the final asset specific filtering.
* tz - client's timezone


`gw` request fields:
* `reqId - long, id of this particular request.
* `gwId - long, reqId in the first gw that got the user request (to find out all related requests if more than one gw is involved).
* `user - the request is executed on behalf of this user.
* `gwUser - the original user.
* `realUser - the real user, for debug purposes.



sub gw msgs
