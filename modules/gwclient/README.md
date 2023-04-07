## Gateway Client module

A module that works with `gw` to execute `gw` requests. It does the following:
* informs `gw` that there is a client.
* processes `gw` requests.

`gwclient` can handle more than one client if needed.

`gwclient` can switch to timer mode if it detects that queries are taking too much time. In this mode all incoming async requests (`gw` queries) are saved in a queue and processed
via timer. This allows:
* `gwclient` can rearrange incoming queries and deprioritize users with long running queries.
* An admin is always able to access the process and execute queries.
* Queries can be cancelled.
* Other timer/external tasks can be run even if the process is overloaded (termination, heartbeats, etc).

A switch happens if there were more than 2 queries