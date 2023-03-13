## Module Process Manager

PM starts processes on a host using `process` module. It requires the following config files:
* parameters.json - an array or parameters in smart ptr format. Asset, region, timeout and etc.
* templates.json - a map from names to sets of parameters (hdb, rdb and etc).
* processes.json - an array of application process's definitions.
* aliases.json - environment depended constants.

Example:
```Rust
// parameters.json
[
    { "name": "source", "value_type": "sC", "convert_to": "s"},
    { "name": "instance", "value_type": "j", "default": 0},
    ...
]
// templates.json
{
    "hdb": {
        "id": "source.procType.dataType.instance",
        "params": ["timeout", "port"],
        "default": {"procType": "hdb", "host": "@HDB"}
    },
    ...
}
// processes.json
{ 
    "hdb:bloomberg..eq@DEV" : {
        "port": 2020, "timeout": 60
    },
    "rdb:bloomberg..eq.0-10" : {
        "port": 2030, "timeout": 60
    },
    ...
}
// aliases.json
{
    "HDB@US_PROD": "host1", "HDB@US_DEV": "host2",
    "cpuset": "!.proc.getCpuSet[]",
    ...
}
```

Parameters config describes possible basic configuration settings.

Templates config contains possible process types and their required/default settings. `host` is always added
to the set because it is used to find processes that need to be started. `id` is a required field, it contains the process id string that can be used with `ps` command for example to find a process instance. Its format is "param [delim param]*" where param is a parameter name (like source) and delim is "_" or ".". Use `params` and `default` to add additional process params.
Mandatory parameters:
* host - required by pmanager.
* autoStart, true by default. Start this process automatically. It can be set to false if it is a script for example.
* enabled, true by default. Disabled processes will not be started automatically.
Additional params:
* after, a list of process ids. Start after the listed processes are started.

Processes config defines process instances. Key's format: "templateID:partial_processID". In the processID fields with a default value can be omitted. Numerical params like instance can be ranges.

Aliases config contains a map from alias names to actual values. It allows you to use logical names instead of environment depended constants. Alias values can be constants or q expressions (start with !).

In all configs you can use the default filtering via "@" suffix.

```Rust
// pmanager will start processes if it is the main module
q loader.q -main pmanager
// otherwise call start function
p:.sys.use`pmanager;
p.start `all // all
p.start `proc_id1`proc_id2 // some
```