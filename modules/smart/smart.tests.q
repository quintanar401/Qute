.test.mod:.sys.useTest[`smart;([] name: (),`test1)];

.tst.testCfgTable:{
    m:.sys.useTest[`smart;([] name: (),`test; typ:`action)];
    assert_eq[count c:m[`ns]`conf;3];
    assert_eq[last c`name;`test];
    assert_eq[last c`typ;`action];

    m2:.sys.useTest[`smart;t1:([] name: (),`test2; optional:1b; default: 100; value_type:enlist `t`n; convert_to:`n; getter:`get; setter:`set)];
    c:m2[`ns]`conf;
    assert_eq[last c`name;`test2];
    assert_eqv[last c`default;100];
    assert_eqv[last c`optional;1b];
    assert_eqv[last c`value_type;`t`n];
    assert_eqv[last c`convert_to;`n];
    assert_eq[last c`setter;`set];
    assert_eq[last c`getter;`get];
    assert_eqv[(m2[`ns]`def)`test2;100];

    m3:.sys.useTest[`smart;t1,update name:`test3 from t1];
    c3:m3[`ns]`conf;
    assert_eq[count c3;4];
    assert_eqv[delete tfn from -2#c3;delete tfn from (-1#c),update name:`test3 from -1#c]; 
 };

.tst.testCfgJson:{
    m:.sys.useTest[`smart;.j.k .j.j t1:([] name: (),`test; typ:`action)];
    assert_eq[count c:m[`ns]`conf;3];
    assert_eq[last c`name;`test];
    assert_eq[last c`typ;`action];

    m2:.sys.useTest[`smart;.j.k .j.j t2:([] name: (),`test2; optional:1b; default: 100; value_type:enlist `t`n; convert_to:`n; getter:`tst_get; setter:`tst_set)];
    c:m2[`ns]`conf;
    assert_eq[last c`name;`test2];
    assert_eqv[last c`default;100f];
    assert_eqv[last c`optional;1b];
    assert_eqv[last c`value_type;`t`n];
    assert_eqv[last c`convert_to;`n];
    assert_eq[last c`setter;`tst_set];
    assert_eq[last c`getter;`tst_get];
    assert_eqv[(m2[`ns]`def)`test2;100f];

    t3: .j.k "[",((.j.j first t1),",",.j.j first t2),"]";
    m3:.sys.useTest[`smart;t3];
    c3:m3[`ns]`conf;
    assert_eq[count c3;4];
 };

.tst.testSetParam:{
    f:.test.mod.ns`setParam;
    // param - raw
    c: f[(1#`)!();`name`setter`typ`tfn!(`n;::;`param;::);100];
    assert_eqv[c;``n!(();100)];
    // param - set
    c: f[``n!(();100);`name`setter`typ`tfn!(`n;{[c;v] v+c`n};`param;::);100];
    assert_eqv[c;``n!(();200)];
    // param - tfn
    c: f[(1#`)!();`name`setter`typ`tfn!(`n;::;`param;{"J"$x});"100"];
    assert_eqv[c;``n!(();100)];
    // param - set, tfn
    c: f[``n!(();100);`name`setter`typ`tfn!(`n;{[c;v] v+c`n};`param;{"J"$x});"100"];
    assert_eqv[c;``n!(();200)];

    // global - raw
    c: f[``n2!(();100);`name`setter`typ`tfn!(`n;{[c;v] .test.setparam: v+c`n2};`global;::);100];
    assert_not[`n in key c];
    assert_eqv[get `.test.setparam;200];
    // global tfn
    c: f[``n2!(();100);`name`setter`typ`tfn!(`n;{[c;v] .test.setparam2: v+c`n2};`global;{"J"$x});"100"];
    assert_not[`n in key c];
    assert_eqv[get `.test.setparam2;200];
 };

.tst.testSetCfg:{
    m:.sys.useTest[`smart;t1:([] name: `test1`test2`test3`test4`test5; typ: `action`param`param`global`action; optional:1b;
        default: 100; value_type:(();();();();()); convert_to:(();();();();()); getter:`get; setter:(::;::;{[cfg;x] cfg[`test3]+x};{[cfg;x] .test.setcfg:x};::))];
    f:m[`ns]`setCfg;
    // exceptions
    assert_exc[{y;x[()!();`test2`bad!(100;100)]} f;"smart: invalid command(s): bad"];
    assert_exc[{y;x[()!();`test2`bad`bad2!(100;100;100)]} f;"smart: invalid command(s): bad, bad2"];
    assert_exc[{y;x[()!();`test2`test1!(100;100)]} f;"smart: action can't be set: test1"];
    assert_exc[{y;x[()!();`test1`test5!(100;100)]} f;"smart: action can't be set: test1, test5"];
    // updates
    r:f[`a`test3!(::;100);`test2`test3`test4!(10;20;30)];
    assert_eqv[key r;`a`test3`test2];
    assert_eq[r`test2;10];
    assert_eq[r`test3;120];
    assert_eq[.test.setcfg;30];
 };

.tst.testCfgConversionParams:{
    // valid types
    assert_no_exc[{.sys.useTest[`smart;t1:([] name: (),`test; value_type:enlist `dict`fn`table,upper[t],t:`$string "bxhijeftuvdpnsc")]}];
    // invalid types
    assert_exc[{.sys.useTest[`smart;t1:([] name: (),`test; value_type:enlist `dict`fn1)]};"invalid value/convert type(s) in parameter test: fn1"];
    assert_exc[{.sys.useTest[`smart;t1:([] name: (),`test; value_type:enlist `fn1`fn2)]};"invalid value/convert type(s) in parameter test: fn1, fn2"];
    // expect correct type check
    m:.sys.useTest[`smart;([] name: `test_b`test_x`test_h`test_i`test_j`test_e`test_f`test_t`test_u`test_v`test_d`test_p`test_n`test_s`test_c;
        value_type:`b`x`h`i`j`e`f`t`u`v`d`p`n`s`c)];
    c:exec name!tfn from m[`ns]`conf;
    f1:{[c;x] (c[`test_b] 1b; c[`test_x] 0x10; c[`test_h] 1h; c[`test_i] 10i; c[`test_j] 10; c[`test_e] 10e; c[`test_f] 10f; c[`test_s] `s; c[`test_c] "a")};
    assert_no_exc[f1 c];
    assert_eqv[f1[c;0];(1b;0x10;1h;10i;10;10e;10f;`s;"a")];
    f2:{[c;x] (c[`test_t] 10t; c[`test_u] 10:10; c[`test_v] 10:10:10; c[`test_d] .z.D; c[`test_p] 2022.03.27D11:03:54.841789000; c[`test_n] 0D11:03:54.841789000)};
    assert_no_exc[f2 c];
    assert_eqv[f2[c;0];(10t; 10:10; 10:10:10; .z.D; 2022.03.27D11:03:54.841789000; 0D11:03:54.841789000)];
    assert_exc[{[c;x] c[`test_b] 10}c;"invalid type, allowed types: boolean"];
    assert_exc[{[c;x] c[`test_x] 10}c;"invalid type, allowed types: byte"];
    assert_exc[{[c;x] c[`test_h] 10}c;"invalid type, allowed types: short"];
    assert_exc[{[c;x] c[`test_i] 10}c;"invalid type, allowed types: int"];
    assert_exc[{[c;x] c[`test_j] 10i}c;"invalid type, allowed types: long"];
    assert_exc[{[c;x] c[`test_e] 10}c;"invalid type, allowed types: real"];
    assert_exc[{[c;x] c[`test_f] 10}c;"invalid type, allowed types: float"];
    assert_exc[{[c;x] c[`test_t] 10}c;"invalid type, allowed types: time"];
    assert_exc[{[c;x] c[`test_u] 10}c;"invalid type, allowed types: minute"];
    assert_exc[{[c;x] c[`test_v] 10}c;"invalid type, allowed types: second"];
    assert_exc[{[c;x] c[`test_d] 10}c;"invalid type, allowed types: date"];
    assert_exc[{[c;x] c[`test_p] 10}c;"invalid type, allowed types: timestamp"];
    assert_exc[{[c;x] c[`test_n] 10}c;"invalid type, allowed types: timespan"];
    assert_exc[{[c;x] c[`test_s] 10}c;"invalid type, allowed types: symbol"];
    assert_exc[{[c;x] c[`test_c] 10}c;"invalid type, allowed types: char"];
    // lists
    m:.sys.useTest[`smart;([] name: `test_b`test_x`test_h`test_i`test_j`test_e`test_f`test_t`test_u`test_v`test_d`test_p`test_n`test_s`test_c;
        value_type:`B`X`H`I`J`E`F`T`U`V`D`P`N`S`C)];
    c:exec name!tfn from m[`ns]`conf;
    assert_no_exc[{[c;x] c[`test_b] 10b; c[`test_x] 0x1011; c[`test_h] 1 2h; c[`test_i] 10 1i; c[`test_j] 10 1; c[`test_e] 10 1e; c[`test_f] 10 1f; c[`test_s]`s`m; c[`test_c]"aa"}c];
    assert_no_exc[{[c;x] c[`test_t] 10 20t; c[`test_u] (),10:10; c[`test_v] (),10:10:10; c[`test_d] (),.z.D; c[`test_p] (),.z.P; c[`test_n] (),.z.N;}c];
    assert_exc[{[c;x] c[`test_b] 10}c;"invalid type, allowed types: boolean list"];
    assert_exc[{[c;x] c[`test_x] 10}c;"invalid type, allowed types: byte list"];
    assert_exc[{[c;x] c[`test_h] 10}c;"invalid type, allowed types: short list"];
    assert_exc[{[c;x] c[`test_i] 10}c;"invalid type, allowed types: int list"];
    assert_exc[{[c;x] c[`test_j] 10i}c;"invalid type, allowed types: long list"];
    assert_exc[{[c;x] c[`test_e] 10}c;"invalid type, allowed types: real list"];
    assert_exc[{[c;x] c[`test_f] 10}c;"invalid type, allowed types: float list"];
    assert_exc[{[c;x] c[`test_t] 10}c;"invalid type, allowed types: time list"];
    assert_exc[{[c;x] c[`test_u] 10}c;"invalid type, allowed types: minute list"];
    assert_exc[{[c;x] c[`test_v] 10}c;"invalid type, allowed types: second list"];
    assert_exc[{[c;x] c[`test_d] 10}c;"invalid type, allowed types: date list"];
    assert_exc[{[c;x] c[`test_p] 10}c;"invalid type, allowed types: timestamp list"];
    assert_exc[{[c;x] c[`test_n] 10}c;"invalid type, allowed types: timespan list"];
    assert_exc[{[c;x] c[`test_s] 10}c;"invalid type, allowed types: symbol list"];
    assert_exc[{[c;x] c[`test_c] 10}c;"invalid type, allowed types: string"];
    // other
    m:.sys.useTest[`smart;([] name:`test_mix`test_dict`test_fn`test_table`test_mixfn; value_type:(`i`j;`dict;`fn;`table;`i`fn`j))];
    c:exec name!tfn from m[`ns]`conf;
    f:{[c] (c[`test_mix] 10i; c[`test_mix] 10; c[`test_dict] ()!(); c[`test_fn] {x}; c[`test_fn] (neg); c[`test_fn] (+); c[`test_fn] {y}1;
        c[`test_fn] (/); c[`test_fn] (')[{x};{x}]; c[`test_fn] ({y}/); c[`test_fn] ({x}\); c[`test_fn] ({x}'); c[`test_fn] ({x}:'); c[`test_fn] ({x}/:);
        c[`test_fn] ({x}\:); c[`test_mixfn] 10; c[`test_mixfn] 10i; c[`test_mixfn] {x}; c[`test_table] ([] a:1 2))};
    assert_no_exc[f c];
    assert_exc[{[c;x] c[`test_mix] 1h}c;"invalid type, allowed types: int, long"];
    assert_exc[{[c;x] c[`test_dict] 1h}c;"invalid type, allowed types: dictionary"];
    assert_exc[{[c;x] c[`test_fn] 1h}c;"invalid type, allowed types: function"];
    assert_exc[{[c;x] c[`test_table] 1h}c;"invalid type, allowed types: table"];
    assert_exc[{[c;x] c[`test_mixfn] 1h}c;"invalid type, allowed types: int, long, function"];
    // simple conversion
    m:.sys.useTest[`smart;([] name: `test_b`test_x`test_h`test_i`test_j`test_e`test_f`test_t`test_u`test_v`test_d`test_p`test_n`test_s`test_c;
        value_type:`b`x`h`i`j`e`f`t`u`v`d`p`n`s`c;
        convert_to:`b`x`h`i`j`e`f`t`u`v`d`p`n`s`c)];
    c:exec name!tfn from m[`ns]`conf;
    assert_eqv[f1[c;0];(1b;0x10;1h;10i;10;10e;10f;`s;"a")];
    assert_eqv[f2[c;0];(10t; 10:10; 10:10:10; .z.D; 2022.03.27D11:03:54.841789000; 0D11:03:54.841789000)];
    m:.sys.useTest[`smart;([] name: `test_b`test_x`test_h`test_i`test_j`test_e`test_f`test_t`test_u`test_v`test_d`test_p`test_n`test_s`test_c;
        value_type:`B`X`H`I`J`E`F`T`U`V`D`P`N`S`C;
        convert_to:`B`X`H`I`J`E`F`T`U`V`D`P`N`S`C)];
    c:exec name!tfn from m[`ns]`conf;
    g1:{[c;x] (c[`test_b] 10b; c[`test_x] 0x1011; c[`test_h] 1 2h; c[`test_i] 10 1i; c[`test_j] 10 1; c[`test_e] 10 1e; c[`test_f] 10 1f; c[`test_s]`s`m; c[`test_c]"ab")};
    assert_eqv[g1[c;1];(10b; 0x1011; 1 2h; 10 1i; 10 1; 10 1e; 10 1f;`s`m;"ab")];
    g2:{[c;x] (c[`test_t] 10 20t; c[`test_u] (),10:10; c[`test_v] (),10:10:10; c[`test_d] (),.z.D; c[`test_p] (),2022.03.27D11:03:54.841789000; c[`test_n] (),0D11:03:54.841789000)};
    assert_eqv[g2[c;1];(10 20t; (),10:10; (),10:10:10; (),.z.D; (),2022.03.27D11:03:54.841789000; (),0D11:03:54.841789000)];
    m:.sys.useTest[`smart;([] name: `test_b`test_x`test_h`test_i`test_j`test_e`test_f`test_t`test_u`test_v`test_d`test_p`test_n`test_s`test_c;
        value_type:`b`x`h`i`j`e`f`t`u`v`d`p`n`s`c;
        convert_to:`B`X`H`I`J`E`F`T`U`V`D`P`N`S`C)];
    c:exec name!tfn from m[`ns]`conf;
    assert_eqv[f1[c;0];enlist each (1b;0x10;1h;10i;10;10e;10f;`s;"a")];
    assert_eqv[f2[c;0];enlist each (10t; 10:10; 10:10:10; .z.D; 2022.03.27D11:03:54.841789000; 0D11:03:54.841789000)];
    // other
    m:.sys.useTest[`smart;([] name: `test_dict`test_fn`test_table; value_type:`dict`fn`table; convert_to:`dict`fn`table)];
    c:exec name!tfn from m[`ns]`conf;
    assert_eqv[(c[`test_dict] ()!();c[`test_fn] {x};c[`test_table]([]a:1 2));(()!();{x};([]a:1 2))];
    // mixed
    m:.sys.useTest[`smart;([] name: `test_tn`test_un`test_vn`test_ij`test_nt`test_ut`test_vt`test_dp`test_TN`test_UN`test_VN`test_IJ`test_NT`test_UT`test_VT,
            `test_DP`test_tN`test_uN`test_vN`test_iJ`test_nT`test_uT`test_vT`test_dP`test_Cs;
        value_type:`t`u`v`i`n`u`v`d`T`U`V`I`N`U`V`D`t`u`v`i`n`u`v`d`C;
        convert_to:`n`n`n`j`t`t`t`p`N`N`N`J`T`T`T`P`N`N`N`J`T`T`T`P`s)];
    c:exec name!tfn from m[`ns]`conf;
    assert_eqv[c[`test_tn] 10:10t; 0D10:10]; assert_eqv[c[`test_TN] 10:10 10:20t; 0D10:10 0D10:20]; assert_eqv[c[`test_tN] 10:10t; (),0D10:10];
    assert_eqv[c[`test_un] 10:10u; 0D10:10]; assert_eqv[c[`test_UN] 10:10 10:20u; 0D10:10 0D10:20]; assert_eqv[c[`test_uN] 10:10u; (),0D10:10];
    assert_eqv[c[`test_vn] 10:10v; 0D10:10]; assert_eqv[c[`test_VN] 10:10 10:20v; 0D10:10 0D10:20]; assert_eqv[c[`test_vN] 10:10v; (),0D10:10];
    assert_eqv[c[`test_nt] 0D10:10; 10:10t]; assert_eqv[c[`test_NT] 0D10:10 0D10:20; 10:10 10:20t]; assert_eqv[c[`test_nT] 0D10:10; (),10:10t];
    assert_eqv[c[`test_ut] 10:10u; 10:10t]; assert_eqv[c[`test_UT] 10:10 10:20u; 10:10 10:20t]; assert_eqv[c[`test_uT] 10:10u; (),10:10t];
    assert_eqv[c[`test_vt] 10:10v; 10:10t]; assert_eqv[c[`test_VT] 10:10 10:20v; 10:10 10:20t]; assert_eqv[c[`test_vT] 10:10v; (),10:10t];
    assert_eqv[c[`test_ij] 10i; 10]; assert_eqv[c[`test_IJ] 10 20i; 10 20]; assert_eqv[c[`test_iJ] 10i; (),10];
    assert_eqv[c[`test_dp] 2020.10.10; 2020.10.10D]; assert_eqv[c[`test_DP] 2020.10.10 2020.10.20; 2020.10.10D 2020.10.20D]; assert_eqv[c[`test_dP] 2020.10.10; (),2020.10.10D];
    assert_eqv[c[`test_Cs] "abc"; `abc];
    // exc
    assert_exc[{.sys.useTest[`smart;([] name: (),`test; value_type:`t; convert_to:`s)]};"invalid conversion(s): time->symbol"];
    assert_exc[{.sys.useTest[`smart;([] name: (),`test; value_type:enlist`t`t`t; convert_to:enlist`t`s`c)]};"invalid conversion(s): time->symbol, time->char"];
    assert_exc[{.sys.useTest[`smart;([] name: (),`test; value_type:`t; convert_to:`y)]};"invalid value/convert type(s) in parameter test: y"];
    // fn
    m:.sys.useTest[`smart;([] name: (),`test; value_type:enlist `t`fn`s; convert_to:enlist `t`fn`s)];
    c:exec name!tfn from m[`ns]`conf;
    assert_eqv[c[`test] 10:10t; 10:10t];
    assert_eqv[c[`test] `s; `s];
    assert_eqv[c[`test] {x}; {x}];
 };

.tst.testNew:{
    m:.sys.useTest[`smart;([] name: `test1`test2; typ:`action`param; getter:({.test.newaction:1b};::); setter:(::;::))];
    c:m[`new][];
    assert_exc[{y; x`test2}c;"parameter test2 is not set"];
    assert_exc[{y; x`xxx}c;"smart: invalid command: `xxx"];
 };