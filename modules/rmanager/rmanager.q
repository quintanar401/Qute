.rman.mInit:{
    .rman.handlers: .sys.use[`hmanager;0b];
    .rman.events: .sys.use[`hmanager;1b];
    {.rman.handlers.add[x;`start;::]} each zz:`.z.pg`.z.ps`.z.pp`.z.ph`.z.ws;
    .rman.handlers.add[;`exec;value] each `.z.pg`.z.ps;
    / but switch off ws pp and ph
    .rman.handlers.add[;`exec;{(`EXCEPTION;"access")}] each `.z.ph`.z.pp`.z.ws;
    {.rman.handlers.add[x;`end;::]} each zz;
    / setup functions
    .z.pg:{.rman.handlers.run[`.z.pg;x]};
    .z.ps:{.rman.handlers.run[`.z.ps;x]};
    .z.pp:{.rman.handlers.run[`.z.pp;x]};
    .z.ph:{.rman.handlers.run[`.z.ph;x]};
    .z.ws:{.rman.handlers.run[`.z.ws;x]};
    .z.ts:{.rman.handlers.run[`.z.ts;::]};
    .z.po:{.rman.events.run[`.z.po;x]};
    .z.pc:{.rman.events.run[`.z.pc;x]};
    `setHandler`setHandlerAt`host
 };

.rman.checkHName:{if[not x in `.z.po`.z.pc`.z.wo`.z.wc`.z.pg`.z.ps`.z.pp`.z.ph`.z.ws`.z.ts; '"undefined handler name: ",string x]; x};
.rman.setHandler:{[hn;n;h] $[hn in `.z.po`.z.pc;.rman.events.add;.rman.handlers.add][.rman.checkHName hn;n;h]};
.rman.setHandlerAt:{[hn;n;p;h] $[hn in `.z.po`.z.pc;.rman.events.addAt;.rman.handlers.addAt][.rman.checkHName hn;n;p;h]};

.rman.ip2host:(0#0i)!0#`;
.rman.host:{if[null n:.rman.ip2host x; .rman.ip2host[x]: n: .Q.host x]; n};