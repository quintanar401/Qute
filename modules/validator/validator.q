.val.fields:`name`value_type`convert_to`optional;

.val.mInit:{`validate};

.val.iInit:{[tmpl]  .val.data:.val.fromTemplate tmpl; };

.val.fromTemplate:{[t]
    // create a smart obj - filter specific fields
    sp: .sys.use[`smart;`;{(.val.fields inter key x)#x} each t];
    // post process fns: recursive check, defaults
    pp:raze {
        if[`default in key x;
            :.val.default[.sys.sym x`name;{$[10=abs type x;value (),x;x]} x`default];
        ];
        if[`check in key x;
            :.val.check[.sys.sym x`name;.val.fromTemplate x`check];
        ];
        if[`post in key x;
            :.val.post[.sys.sym x`name;{$[10=abs type x;value (),x;x]} x`post];
        ];
        :();
    } each t;
    :(sp;pp);
 };

.val.default:{[n;val;obj]
    if[99<type val; obj[n]: @[val;obj;{'string[x],": ",y}n]; :obj];
    obj[n]: val;
    : obj
 };

.val.check:{[n;t;obj] obj[n]: .[.val.exec;(t 0;t 1;obj n);{'string[x],": ",y}n] };

.val.exec:{[sp;pp;d]
    p:(sp`new)[];
    p:p[`cfg;d]`validate;
    :enlist[`]_ {y x}/[p;pp];
 };

.val.post:{[n;f;obj] obj[n]: @[f;obj;{'string[x],": ",y}n]; obj };

.val.validate:{[d] .val.exec[.val.data 0;.val.data 1;d] };