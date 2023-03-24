.ipc.context.handle:0i;

.ipc.setDefaultCtx:{[isSync;msg]
    if[(0=w:.sys.w[])&not 0=.ipc.context.handle; .ipc.context[`msg0]: msg; :()];
    .ipc.context:`sync`msg`realUser`user`appUser`qUser`host`handle`reqContext!(isSync;msg;u;u;u;u:.sys.u[];.ipc.rman.host .sys.a[];w;());
 };
.ipc.psHandler:{.ipc.setDefaultCtx[0b;x]; .ipc.pxHandler x};
.ipc.pgHandler:{.ipc.setDefaultCtx[1b;x]; .ipc.pxHandler x};
.ipc.pxHandler:{[msg]
    if[`ipc.request~first msg;
        // (`ipc.request;ipcParams;request)
        .ipc.context[k]:m k:`realUser`user`appUser inter key m:msg 1;
        if[10b~`appUser`realUser in key m; if[.ipc.context[`qUser]=.ipc.context`realUser; .ipc.context[`realUser]: m`appUser]]; // real can't be .z.u if app is changed
        .ipc.context[`msg`reqContext]:(msg:msg 2;.ipc.context[`reqContext],m);
        :.ipc.pxHandler msg;
    ];
    msg
 };

.ipc.mInit:{
    .ipc.rman: rman: .sys.use`rmanager;
    rman[`setHandlerAt][`.z.ps;`before`start;`ipc_ctx.start;.ipc.psHandler];
    rman[`setHandlerAt][`.z.pg;`before`start;`ipc_ctx.start;.ipc.pgHandler];
    rman[`setHandlerAt][;`after`end;`ipc_ctx.end.res;{if[not .sys.w[]=0; .ipc.context:``handle!(::;-1i)]}] each `.z.pg`.z.ps;
    :(),`env;
 };

.ipc.env:{.ipc.context};