// Record important events to simplify debugging

// Store stack traces when some important variable is changed
.state.lastUpd:(0#`)!();

// overwrite/append
.audit.append:0b;

.audit.recordStack:{[name]
    // Call this function to store the current stack trace.
    // To switch between recording all/the last update call .audit.setMode.
    // Updates are stored in a global variable and can be retrieved via .audit.getRecord.
    // @example .audit.recordStack `importantVarIsChanged
    st:.Q.sbt .Q.btx .Q.Ll`;
    $[.audit.append;.state.lastUpd[name],:enlist st;.state.lastUpd[name]:st]
 };

.audit.getRecord:{[name] .state.lastUpd name};

.audit.setMode:{[mode] .audit.append:"b"$mode};