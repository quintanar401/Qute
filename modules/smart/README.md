## Module Smart Pointers

A smart pointer is a special function with a configuration dictionary. This function can be called to set/get parameters or call actions. It supports:
* Parameters/actions can be configured via a JSON file or directly via a table.
* Type check for params.
* Type conversion for params including automatic conversion from strings.
* Help for the params/actions.

It works like this:
```Rust
// create a new smart pointer from a cfg, `ipc.newconn is the pointer id and it is used to find help in README.md.
// .ipc.cfg.newconn is newconn.json within ipc module dir.
.ipc.newConn: .sys.use[`smart;`ipc.newconn;.ipc.cfg.newconn];

// add a function to return a smart pointer
.ipc.new:{.ipc.newConn.new[]};

// a client calls this fn to get a pointer
h:ipc.new[];

// and then uses it to set params/call actions
h:h[`port;100];
h:h[`host;`somehost];
h:h`open;
```

### Configuration

JSON file: array of objects with parameters. Supported fields:
* name - param's name.
* value_type - type or array of allowed types in Q format: "f", "F" and etc. Extra types: fn, dict, table, strings.
* convert_to - type or array of types to convert to. If there are several types then convert_to.len == value_type.len.
* default - default value, value function is called on this string.
* optional - bool, optional or not.
* typ - by default it is param but can be set to action for actions.
* getter - get function (including actions, optional).
* setter - set function (including actions, optional).
* internal - bool, optional. Internal field, do not show help for it.

Difference of setter vs getter for actions:
```Rust
h`open  // getter, open looks like {[cfg] use cfg to do the requested action }
h[`help;`open] // setter, help looks like {[cfg;arg] ...}, more than 1 arg is allowed.
```
The return value is whatever the called function returns.

For parameters both getter and setter can be set to (::) - default functions. Getter returns the param's value. Setter sets a new value and returns a new smart ptr to allow chain calls:
```Rust
h[`host;`a][`port;1010]`open
```
If you redefine a setter you must return the new value, the smart ptr is created by the lib.

You can set/get all params at once:
```Rust
h`cfg
h[`cfg;dict_with_params]
```

`validate` action can be called to check that all required params are set:
```Rust
h`validate
```

`help` can be called to get help on actions/params (it is taken from README.md):
```Rust
h`help
h[`help;`name]
```

### Init

```Rust
s:.sys.use[`smart;name;cfg];
```

For `cfg` - see `smart.cfg` help. `name` is used to find help within README.md files:

```Rust
// Add a section in the module's README.md: ### SmartID settings
 ### ipc.newconn settings

..generic help for the module..

// list all params/actions

 #### host

...help...

// map smart ids to actual variables that contain smart pointer imports, .module.smartHelp variable is used by help module to find help entries for the smart pointers used by the module.
.ipc.smartHelp:`newconn`conn!`.ipc.newConn`.ipc.conn;
```

### smart.new

Get a new smart pointer.
```Rust
p:sm.new[];
```

### smart.validate

Check that all required params are set and return the underlying dictionary. Throw an exception otherwise.
```Rust
p:p`validate;
```

### smart.helps smart.helpg

Required by `help` module.

### smart.extend

Can be used by plugins to add new functionality.
```Rust
// assuming ns is the module we want to extend that contains newConn smart pointer instance
// and .mod is the plugin's module and newconn is the additional functionality.
ns[`newConn][`extend][.mod.__mod__.name;.mod.cfg.newconn];
```