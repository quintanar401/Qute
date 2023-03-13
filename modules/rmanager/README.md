## Module Resource Manager

One place to manage all ipc, timer and etc system handlers. It is a singleton module.

Supported handlers: .z.po, .z.pc, .z.wo, .z.wc, .z.pg, .z.ps, .z.pp, .z.ph, .z.ws, .z.ts.

There are `start`, `exec` and `end` default handlers for .z.pg, .z.ps, .z.pp, .z.ph, .z.ws. Start and end handlers do nothing and can be redefined/used as relative names for other handlers. pg, ps exec handlers call value on the input, pp, ph, ws raise an exception.

.z.ts handler is defined but does nothing (timer module can be used to manage timer jobs). Other handlers are undefined - you need to redefine .z functions to use them:
```Rust
.z.xxx:{.rman.handlers.run[`.z.xxx;x]};
```

### setHandler

Call this function to add a new handler:
```Rust
rman[`setHandler;handlerName;relativePosition;function]
rman[`setHandler;`.z.pg;`before`start;{[v] ... }]
```

* handlerName (symbol) - name of the handler.
* relativePosition - one of \`first, \`last, (\`before\`name), (\`after\`name).
* function (function or symbol) - function.