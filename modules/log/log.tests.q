.test.log: .sys.useTest`log;

.tst.handler:{
    r: .test.log.ns[`handler]["name ";" prefix ";"caller";"msg"];
    assert_like[r;"* name *"];
    assert_like[r;"* prefix *"];
    assert_like[r;"* ?caller?"];
    assert_like[r;"* msg *"];
 };

.tst.setLevel:{
    .test.log.setLevel`debug;
    assert_eqv[.test.log.ns`level;`debug];
    .test.log.setLevel`normal;
    assert_eqv[.test.log.ns`level;`normal];
    assert_exc[{.test.log.setLevel`error};"wrong log level"];
 };
