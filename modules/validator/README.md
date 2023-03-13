## Module validator

Validate parameters: check and convert types, check required fields, assign default values.
```json
[
    {
        "name": "param1",
        "value_type": "ij",
        "convert_to": "j",
        "optional": false
    },
    {
        "name": "dictparam",
        "value_type": "dict",
        "optional": true,
        "check": [
            ...recursive definition...
        ],
        "default": "{[obj] `a`b!(10;`xxx)}"
    }
]
```
```Rust
v:.sys.use[`validator;json_cfg_as_list];
p:v.validate `param1`dictparam!(10;..);
```

Validator uses `smart` module to check params.

Parameters:
* name - field name.
* value_type - allowed types, see `smart` module.
* convert_to - optional, convert into this type(s). See `smart` module.
* optional - false by default, can be set to true.
* default - if the field is missing assign this value. If it is a string, value fn will be called. If it is a function, it will be called with the current dictionary.
* check - optional, validate a subfield. A list of validation settings.
* post - optional, post process function.
  
Default and post process function example:
```Rust
[
    {
        "name": "host",
        "value_type": "s",
        "optional": true,
        "default": "`localhost"
    },
    {
        "name": "port",
        "value_type": "ij",
        "post": "{$[1000>x`port;'\"range\";x`port]}"
    },
    {
        "name": "name",
        "optional": true,
        "value_type": "s",
        "default": "{`$\":\"sv string x`host`port}"
    }
]
```

### validate

Validate the input dictionary. Throws an exception if a required field is missing or some field has an incorrect type. Also assigns default values.
```Rust
params: val.validate params;
```