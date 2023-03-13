## Module Handle Manager

Manages event handlers. It has two modes: call each handler with the event and call them in sequence passing the results along. Handlers must accept one argument, its type and meaning are not specified.

In the first mode (event mode) the handlers are independent and do not affect each other. In the second mode they depend on the result of the previous handler and can stop the processing. The second mode can be used for .z.XX handlers.

For efficiency reasons one Handle Manager instance can manage several handler groups.

### Init

Handle manager accepts one parameter - mode.
```
hman: .sys.use[`hmanager;1b]; / parallel (event) mode
hman: .sys.use[`hmanager;0b]; / sequencial (handler) mode
```

### hman.add

Add a handler (at the end) or update an existing handler. Arguments:
* hname(symbol) Group name (like hdb.reload, .z.pg).
* name(symbol) Optional handler name. can be \`.
* handler(symbol or function) Handler.

Example:
```
hman.add[`.z.po;`updatePOTable;{[data] ..}];
```

### hman.addAt

Add a new handler at a relative position vs other handlers. Arguments:
* hname(symbol) Group name (like hdb.reload, .z.pg).
* pos(symbol or symbol list) Relative positions: \`first, \`last, \`before\`name, \`after\`name. The relative name must exist.
* name(symbol) Optional handler name. can be \`.
* handler(symbol or function) Handler.

Throws an exception if 1) name or pos are not symbols 2) name already exists 3) the relative name in before/after doesn't exist 4) the relative postion is not in the allowed list.

Example:
```
hman.addAt[`.z.po;`before`updatePOTable;`logSomeInfo;{[data] ..}];
```

### hman.get

Get a handler by its name. Arguments:
* hname(symbol) Group name (like hdb.reload, .z.pg).
* name(symbol or general null) Handler name or (::).

It returns a dictionary with all handlers if name is null. If name is a symbol it returns the corresponding handler if it exists or (::) otherwise.

Example:
```
hman.get[`.z.po;::];
hman.get[`.z.po;`updatePOTable];
```

### hman.remove

Remove a named handler. Arguments:
* hname(symbol) Group name (like hdb.reload, .z.pg).
* name(symbol) Handler name.

It returns 1b if the handler was removed, 0b otherwise.

Example:
```
hman.remove[`.z.po;`updatePOTable]
```

### hman.run

Run handlers in parallel or sequencial order. In the sequencial order each handler must return either 1) a new result 2) () or (::) to reuse the input argument as the result 3) (\`CANCELL;result) to stop processing and return `result` or 4) (\`EXCEPTION;"exception") to stop processing with `exception`. Free exceptions are treated as errors and reported in log. Arguments:
* arg Input argument. Type is not specified.

Example:
```
hman.run[`.z.po;10]
```