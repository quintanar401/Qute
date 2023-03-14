### Overview

Q frameworks suffer from one problem - they rely on the global state too much. This leads to too many connections between different parts and this causes poor quality of code, tight coupling, low reuse and etc. To address these issues this framework introduces:
* Modules. Their code is hidden and they can be accessed only via API functions.
* Smart pointers to resources/configuration to avoid global variables and obscure dictionary parameters.
* Built-in help and test support.

#### Modules

The idea behind modules is to make it very difficult to share the global state. The framework will substitute all ".xyz." namespace substrings within a module with another namespace every time the module is loaded into another module. This means all instances are unique and can't share their local state. You need to make sure that ".xyz." substitutions don't break anything in your code, but it is easy. In return you get isolaton - only exposed functions can be called and it is (almost) impossible to change the module's state without its permission.

Q is designed to deal with big data so the global state is inevitable. You still can use other namespaces (or the global namespace) explicitly but Qute also provides ability to create and use a private global state - in this way you can isolate your global state from other modules:
```Rust
.state.var:1; // global state unique to the module, ".state." will be substituted with a unique namespace
.abc.var:2;   // local state, unique for each abc instance
```

Modules are not designed to be used as an OOP objects. You can't request them in a cycle - save references in the module's local/global variables:
```Rust
.some.fn_called_many_times:{m:.sys.use`xyz; .. m ..} // no!
.some.xyz:.sys.use`xyz;
.some.fn_called_many_times:{.. .some.xyz ..} // yes!
```

Isolation allows you to load the same module into several other modules and expect that they will be independent. For example the same "log" module can have different logging settings.

#### Smart pointers

A smart pointer is a function that has a configuration dictionary as a parameter and is able to update the config parameters, provide API functions to initiate actions, provide help on available options. It simplifies access to API:
```Rust
job: timer.new[][`delay;0D10][`interval;1D][`args;(1;2)]`start;
// later
timer.get[job]`stop;
```

Problems addressed by the smart pointers:
* Avoid obscure dictionary parameters with a lot of options. All smart pointers support "help" action that shows available options with their description.
* Avoid obscure configuration settings in modules - similar to above.
* Provide one point access to all functionality - timer related functions for example.

#### Help and tests

Qute is able to parse README.md files within modules if they have the right format. This information can be accessed then via 1) general "help" function, 2) module's help functions 3) smart pointer's help function. There is no need to search Wiki and etc for info, you can just call help on any Q process.

Qute also provides a basic unit test module that can be used to test other modules.

Help usage:
```Rust
-1 .sys.help`module[.function]; // default
h:.sys.use`help; -1 h.help `module; // explicit
i:.sys.use`ipc; p:i.new[]; -1 p`help; -1 p[`help;`open]; // smart pointer
```

### Usage

```bash
# basic
q core/loader.q
# load startup modules, provide cfg dirs
q $QUTE/core/loader.q -main mod1,mod2 -config /path/to/cfg1,/path/to/cfg2 -t 100 -p 2020
```

By default `qute` uses its own directory to load modules. Set it via `-qute` argument or QUTE env variable. Additional modules: `-mpath p1[,p2]*` option.
Additional configs: `-config p1[,p2]*` option.

`-main module1[,module2]*` option can be used to load startup modules.

### Module structure

```Rust
// all top level expressions will be executed once in the default instance
.mod.query: .sys.use `queryLib; // import another module, none can change its local state
// args can be passed to a module too
.mod.lib: .sys.use[`name;arg];
// Some variables will be set automatically
// .mod.cfg  -- contains module configs if there are any (json, csv)
// .mod.ns -- module's real namespace to access it via a reference
// .mod.__mod__ -- module info

// mInit will be executed once in the default instance when the module is first loaded
.mod.mInit:{[] ...; `fn1`fn2`fn3 }; // mInit inits the default first instance (state vars for example) and returns API functions

// iInit will be executed once per use of .sys.use
// if there is no iInit Qute assumes that the module is a singleton
.mod.iInit:{[...]
  // import local modules if needed
  .mod.query2: .sys.use `queryLib2;
 }; 

.state.var:1; // module global state/function
.mod.var:1;   // module local state/function
```

#### Module extention

Composition:
```Rust
.m2.m1:.sys.use`m1; // assume m1's API is fn
.m2.mInit:{...; `fn};
.m2.fn:{... .m2.m1.fn[] ...}
```

Inheritance:
```Rust
// inc will copy all m1 default content into m2
// version is required because major (or even minor updates) of m1 can
// potentially break m2
.sys.inc[`m1;`1.0];
```

Patching:
```Rust
// substitute all instances of .mod.fn with val
.sys.patch[`.mod.var;val];
```

#### Module resolution

Goals:
* Allow different versions in one process. A newer version can be incompatible with some modules.
* Allow different modules with the same name.

For example we may have `log` module that is used everywhere and logs msgs to stdout/err. We may want to add throttling, save to file, send to a log process and etc. We create a new module `log2`. We can't just change `log` to `log2` everywhere because we may not even have control over other modules. So there should be a way
to set `log2` as the default choice for `log` module.

### Configuration

Default format: json. Also supported: csv.

#### Default configuration

All `csv` and `json` files in the module's directory will be loaded. They may contain static info and default params.

```
module/
  cfg1.json
  cfg2.csv
  dir/
    cfg3.json
```

They will be saved in .mod.cfg dictionary as:
```
`cfg1`cfg2`dir.cfg3!(data;data;data)
```

Config names and directories can contain environment filters like EMEA, PROD, hostname and etc. Possible and current
values must be defined in settings.json or app settings. If a config name contains a current env value, this value will be removed:
```
// in US cfg_US.json will become cfg.json, in EMEA it will be cfg_EMEA.json
// values must be delimited with _ .
cfg_EMEA.json
cfg_US.json
// in EMEA it becomes file.csv
EMEA/file.csv
// several filters: if PROD and one of EMEA/US are set, it becomes cfg.csv
cfg_EMEA_US_PROD.csv
```

Special files:
* settings.json - module related settings.
* params.json - default values for variables.

settings.json contains info about the module. In particular:
* version as a string. Version must follow the usual rule: "x.y.z" where z - patches, y - small compatible changes, x - big, incompatible changes.
* name as a string - logical name.
* ns as a string - module's namespace if different from name.

Params file can be used to set default values for variables (they will be available as `.mod.cfg.name`). `params.json` must contain an array with entries having at least 2 fields - name and value:
```
[
    { "name": "some_var", "value": "1b" },
    { "name": "some_var2", "value": ["100","200"] },
    { "name@PROD": "some_var3", "value": 100 }
    { "name@!PROD": "some_var3", "value": 200 }
]
```
The value string will be evaluated. Sometimes it is more convenient to cast the value to a type, so "type" key can be used:
```
// ijt and etc, * - string. No need to use IJT.. cast from string is handled automatically
// int, long, time and etc are allowed too for clarity + string
{ "name": "abc", "value": 100, "type": "j" }
{ "name": "abc", "value": 100, "type": "long" }
// all other fields are ignored; "comment" can be used to provide some info
{ "name": "some_var", "value": "1b", "comment": "controls something" },
```

#### App configuration

If there is a default config directory(ies) all files from `$CONFIG/module_name` also will be loaded (duplicates will be overwritten). Be careful: `module_name` is the logical module name - there can be log1 and log2 that both are named log.

### Basic components

```
q loader.q -main main_module ...
```

* loader.q finds all modules in its default dir `$QUTE/lib` + user directory `$QAPP/lib`.
* stores args in .sys.args dictionary.
* module `main_module` is loaded via ".sys.use `main_module" - its mInit/iInit functions do initialization.

loader.q is extremely lightweight. Its purpose is to provide functions to load only required functionality.

Loader.q will not turn off .z handlers. Use `rmanager` module to do this.

#### Resource manager library

One access point to shared resources, primarily IPC.

Allows you to define a generic handler:
```Rust
rman.setHandler[`.z.pg;`myhandler;`fn];
```
For handle specific handlers see `ipc` module.