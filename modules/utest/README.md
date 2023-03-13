## Module utest

Run unit tests for modules.

```
q core/loader.q -main utest -test_module log
q core/loader.q -main utest -test_module "log,log_ctl"
```

Test structure:
```
.test.mod:.sys.useTest`mod; // like .sys.use but saves the mod's namespace in .test.mod.ns variable
.test.var:... // tmp variables
.tst.testXXX:{...} // tests

// special functions
.tst.beforeAll:{..}
.tst.before:{..}
.tst.after:{..}
.tst.afterAll:{..}
```

Tests must be put into files like xxx.tests.q or xxx.test.q. Utest resets test and tst namespaces before running tests in each file.

Use .test.mod.ns to access the internal state:
```
.test.mod:.sys.useTest`log;

.tst.testLevel:{
    assert_eqv[.test.mod.ns`level;`normal];
 };
```

Available checks:
```
assert x; // x=1b
assert_not x; // x=0b
assert_like[x;"patt*"]; // string/symbol like a pattern
assert_eqv[x;val]; // x~val
assert_eq[x;val]; // x=val
assert_exc[{...};"exception"]; // exact exception
assert_no_exc[{}]; // must be no exception
```