.hman.names:(0#`)!();
.hman.handlers:(0#`)!();
.hman.cfg.parallelMode:1b;
.hman.log: .sys.use[`log;`HMAN];

.hman.mInit:{`add`addAt`get`remove`run};

.hman.iInit:{[b] if[-1=type b; .hman.cfg.parallelMode: b]};

/ Add a handler (at the end) or update an existing handler.
/ @param hn symbol Group name.
/ @param n symbol Optional handler name.
/ @param h (symbol|function) Handler.
.hman.add:{[hn;n;h]
    if[h~(::); h:{x}];
    hh: $[hn in key .hman.handlers;.hman.handlers hn;()];
    if[count[nm]<>i:(nm:.hman.names hn)?n;
        .hman.log.dbg2[{"handler redefined: group ",string[x],", handler ",string `unnamed^y};(hn;n)];
        .hman.handlers[hn]: (i#hh),h,((i+1)_hh); // in case all handlers are syms and h is not
    ];
    .hman.log.dbg2[{"handler added: group ",string[x],", handler ",string `unnamed^y};(hn;n)];
    .hman.names[hn]:nm,n; .hman.handlers[hn]:hh,h;
 };

/ Add a new handler at a relative position.
/ @param hn symbol Group name.
/ @param pos (symbol|symbol list) Relative position: `first, `last, `before`name, `after`name.
/ @param n symbol Optional handler name.
/ @param h (symbol|function) Handler.
/ @throws If n or pos are not symbols. If n already exists. If the relative name in before/after doesn't exist. If the relative postion is not in the allowed list.
.hman.addAt:{[hn;pos;n;h]
    if[h~(::); h:{x}];
    if[not (-11=type n)&11=abs type pos; '"type"];
    if[count[nm]<>i:(nm:.hman.names hn)?n; '"Handler already exists: ",string n];
    hh: $[hn in key .hman.handlers;.hman.handlers hn;()];
    .hman.log.dbg2[{"handler added: group ",string[x],", handler ",string `unnamed^y};(hn;n)];
    if[pos~`first;
        .hman.names[hn]:n,nm;
        .hman.handlers[hn]:h,hh;
        :();
    ];
    if[pos~`last;
        .hman.names[hn]:nm,n;
        .hman.handlers[hn]:hh,h;
        :();
    ];
    if[count[nm]=i:nm?pos 1; '"Handler doesn't exist: ",string `null^pos 1];
    i:$[`before=p:first pos;i;`after=p;i+1;'"Unknown position: ",string `null^p];
    .hman.handlers[hn]: (i#hh),h,(i _hh);
    .hman.names[hn]: (i#nm),h,(i _nm);
 };

/ Get a handler by its name.
/ @param hn symbol Group name.
/ @param n (symbol|gnull) Handler name or (::).
/ @returns dict If n is null returns a dictionary with all handlers.
/ @returns (symbol|function) If n is a symbol returns the corresponding handler if it exists or (::) otherwise.
.hman.get:{[hn;n]
    if[not hn in key .hman.names; :(::)];
    if[n~(::); :.hman.names[hn]!.hman.handlers[hn]];
    if[null[n]|count[nm]=i:(nm:.hman.names hn)?n; :(::)];
    : .hman.handlers[hn] i;
 };

/ Remove a named handler.
/ @param hn symbol Group name.
/ @param n symbol Handler name.
/ @returns bool 1b if the handler was removed.
.hman.remove:{[hn;n]
    if[null[n]|count[nm]=i:(nm:.hman.names hn)?n; :0b];
    .hman.log.dbg2[{"handler removed: group ",string[x],", handler ",string `unnamed^y};(hn;n)];
    .hman.handlers[hn]: (i#hh),((i+1)_hh:.hman.handlers hn);
    .hman.names[hn]: (i#nm),((i+1)_nm);
    1b
 };

/ Run handlers in parallel or sequencial order. In sequencial order each handler must return either 1) a new result 2) () or (::) to reuse the input argument
/ 3) (`CANCEL;result) to stop processing and return this result or 4) (`EXCEPTION;"exception") to stop processing with "exception". Free exceptions are
/ treated as errors and reported in log.
.hman.run:{[hn;arg]
    if[not hn=`.z.ts; .hman.log.dbg2[{".hman.handlers: executing handler group ",string x};hn]];
    if[not hn in key .hman.names; .hman.log.dbg "no handlers"; :()];
    if[.hman.cfg.parallelMode;
        {[a;n;h]
            .hman.log.dbg2[{".hman.handlers: executing handler ",$[-11=type x;string `unnamed^x;.Q.s1 x]};n];
            .Q.trp[h;a;{.hman.log.err "handler failed with ",x,", stacktrace:\n",.Q.sbt y}];
        }[arg]'[.hman.names hn;.hman.handlers hn];
        :();
    ];
    r: {[a;n;h]
        if[not n~`timer;.hman.log.dbg2[{".hman.handlers: executing handler ",$[-11=type x;string `unnamed^x;.Q.s1 x]};n]];
        if[any first[a]~/:`CANCEL`EXCEPTION; if[not n like "*.res"; :a]];
        r: .Q.trp[h;a;{.hman.log.err "handler ",string[x]," failed with ",y,", stacktrace:\n",.Q.sbt z; (`EXCEPTION;"internal error")}n];
        : $[(()~r)|(::)~r;a;r];
    }/[arg;.hman.names hn;.hman.handlers hn];
    $[`CANCEL~first r; last r; `EXCEPTION~first r; 'last r; r]
 };