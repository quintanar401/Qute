### Process module

Works along `Process Manager` to start up processes. Also provides some basic services.

`PM`  will start a new `q` process with `-main process`. It then will get its configuration (provided by `PM`) and run the user module(s).

The user configuration params can be defined in `PM` config files, they will be passed to the user module as a parameter.

`process` also documents its progress by sending `status` updates via `pmanager:pmid,process:pid,event:status` messages (`PM` subscribes to them):
* started - when process:init is called.
* configured - when setCfg message with the process cfg is recieved from `PM`. 
* inited - when the user module init returns.
* failed - if the user module init fails (exit is called).

`process` can also process some generic cmds to update its settings (can be sent via mbus as `pmanager:pmid,process:pid,cmd:command,data:value`):
* setTimer - change the timer interval.
* setTimeout - change the default timeout.
* exit - stop the process.

`process` requires `PM` for its configuration (it pins it on startup) but then it can be started manually and it doesn't require `PM` to be alive.

A `process` can be started manually in test mode, just do not provide the correct port argument (`-p xxxx`) or add `-test 1` argument. It will not
then report its status to `PM` and also will set `.sys.test` to `1b`. The user modules can use `.sys.test` to run quitely.