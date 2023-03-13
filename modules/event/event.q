.event.mInit:{`on`onExt`fire`fireExt`remove`get};
.event.iInit:{
    .event.hman: .sys.use`hmanager;
 };

.event.on:{[e;h] .event.hman.add[e;`;h]};
.event.onExt:{[e;n;h] .event.hman.add[e;n;h]};
.event.fire:{[e;d] .event.hman.run[e;`event`data!(e;d)]};
.event.fireExt:{[e;d] .event.hman.run[e;(`event`data!(e;())),d]};
.event.remove:{[e;n] .event.hman.remove[e;n]};
.event.get:{[e;n] .event.hman.get[e;n]};