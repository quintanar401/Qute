## Module Help

Can be used to show help for other modules. It parses README.md that must have the following structure:
```
 ## Module <name>

 .. generic description ..

 ### Configuration

 .. optional description of configuration files (csv, json ) ..

 ### Init

 .. optional descritpion of instance params in `.sys.use` ..

 ### mname.fun [mname.fun2]

 .. help on API functions

 ### mname.smartID

 .. help on smart cfg ..

 #### smart_field

 .. help on a smart field (see `smart` module)
```

### help.help

Returns a list of strings with the help on the requested topic.
```Rust
h:.sys.use`help;
-1 h.help`some_module;
-1 h.help`some_module.api_fn;
-1 h.help`some_module.smart_ptr.field;
```