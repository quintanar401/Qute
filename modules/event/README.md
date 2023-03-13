## Module Event

Provides event interface: on, fire and etc. It is based on Handler Manager module.

```
evt: .sys.use`event;
/ setup a handler - it must have one arg (dict)
evt.on[`event;{[evt] evt`event`data}];
/ setup a named handler
evt.onExt[`event;name;{[evt] evt`event`data}];
/ remove a named handler
evt.remove[`event;name];
/ fire an event, argument will be `event`data!(..;..)
evt.fire[`event;data];
/ provide custom fields, data will be added anyway
evt.fireExt[`event;dict];
```

Handlers are expected to accept one dictionary argument. It will have at least event and data fields.

### event.on

Setup an event handler. Arguments:
* event(symbol) Event name.
* handler(symbol or function) Handler.

Example:
```
evt.on[`hdb.reload;`.hdb.reload];
```

### event.onExt

Setup a named event handler. If it already exists it will be overwritten. Arguments:
* event(symbol) Event name.
* name(symbol) Handler name.
* handler(symbol or function) Handler.

Example:
```
evt.onExt[`hdb.reload;`startStatGen;{..}];
```

### event.remove

Remove a named event handler. Arguments:
* event(symbol) Event name.
* name(symbol) Handler name.

Example:
```
evt.remove[`hdb.reload;`startStatGen];
```

### event.get

Get a named event handler. Returns the generic null if there is no such handler. With the generic null returns all handlers as a dictionary. Arguments:
* event(symbol) Event name.
* name(symbol or generic null) Handler name.

Example:
```
evt.get[`hdb.reload;`startStatGen];
```

### event.fire

Execute all event handlers. Arguments:
* event(symbol) Event name.
* data(anything) Content for `data` field.

All handlers will be executed immediately. If you want to delay the execution use timer module:
```
tm: .sys.use`timer;
tm.new[][`fn;evt.fire][`args;(`event;data)][`delay;0D00:01]`start;
```

Example:
```
evt.fire[`hdb.reload;date]
```

### event.fireExt

Execute all event handlers with a custom event dictionary. Arguments:
* event(symbol) Event name.
* data(dict) Event dictionary, it can contain additional event fields.

For info on delayed execution see event.fire.

Example:
```
evt.fireExt[`hdb.reload;`db`stack`data!(`batch;`stock;date)]
```