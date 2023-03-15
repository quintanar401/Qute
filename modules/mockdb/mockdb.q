.mockdb.mInit:{`$()};

.mockdb.log:.sys.use[`log;`MOCKDB];

.mockdb.iInit:{[cfg]
    .mockdb.log.info "Starting mockdb:",string cfg`pid;
    // ensure the process dies with its manager
    show cfg;
    .sys.use[`vital;cfg`pmanager_port];
 };