.utest.log: .sys.use[`log;`UTEST];

assert:{[a] if[a; :()]; .utest.exc:("assert";a); '"utest_fail"};
assert_not:{[a] if[not a; :()]; .utest.exc:("assert_not";a); '"utest_fail"};
assert_like:{[a;b] if[.[{x like y};(a;b);0b]; :()]; .utest.exc:("assert_like";a;b); '"utest_fail"};
assert_eqv:{[a;b] if[a~b; :()]; .utest.exc:("assert_eqv";a;b); '"utest_fail"};
assert_eq:{[a;b] if[.[=;(a;b);0b]; :()]; .utest.exc:("assert_eq";a;b); '"utest_fail"};
assert_exc:{[a;b] if[first r:@[{x[]; (0b;"no exception")};a;{(x~y;y)}b]; :()]; .utest.exc:("assert_exc";b;r 1); '"utest_fail"};
assert_no_exc:{[a] if[first r:@[{x[]; (1b;"no exception")};a;{(0b;x)}]; :()]; .utest.exc:("assert_no_exc";r 1); '"utest_fail"};

.utest.testModule:{[m]
  .utest.log.info "Testing module ",string m;
  m: .sys.getModule enlist[`name]!enlist m;
  if[0=count m; .utest.log.err "Module not found"];
  .utest.testPath each m;
 };

.utest.testPath:{[m]
  .utest.log.info "Testing path ",string m`path;
  {
    t:type each key each p:` sv/:x,/:f:key x;
    .utest.runTests each p where (t=-11)&f like "*.tests.q";
    .z.s each p where 11=t;
  } m`path;
 };

.utest.runTests:{[p]
  .utest.log.info "Running tests from ",string p;
  .tst: (1#`)!1#(::);
  .test: (1#`)!1#(::);
  if[@[{system "l ",1_string x; 0b};p;{.utest.log.err "Couldn't load the file: ",x; 1b}]; :()];
  if[`beforeAll in key .tst; .Q.trp[.tst.beforeAll;::;{.utest.log.err "beforeAll fn failed with ",x,"\n",.Q.sbt y}]];
  .utest.runTest each (1_key .tst) except`after`before`afterAll`beforeAll;
  if[`afterAll in key .tst; .Q.trp[.tst.afterAll;::;{.utest.log.err "afterAll fn failed with ",x,"\n",.Q.sbt y}]];
 };

.utest.runTest:{[n]
  .utest.log.info "Running test ",string n;
  if[`before in key .tst; .Q.trp[.tst.before;::;{.utest.log.err "before fn failed with ",x,"\n",.Q.sbt y}]];
  if[first res: .Q.trp[{(1b;.tst[x][])};n;{(0b;x;.Q.sbt {(first where {$[10=type x;x like "*.runTest@";0b]} each x[;1;0])#x} y)}];
    if[`after in key .tst; .Q.trp[.tst.after;::;{.utest.log.err "after fn failed with ",x,"\n",.Q.sbt y}]];
    : ();
  ];
  if[f:res[1]~"utest_fail";
    .utest.log.err "FAILED, fn: ",.utest.exc[0]," args: (",(";" sv .Q.s1 each 1_.utest.exc),")";
  ];
  if[not f; .utest.log.err "FAILED, exception: ",res 1];
  .utest.log.err "Stacktrace:\n",res 2;
 };

.utest.mInit:{[c]
  if[`test_module in key .sys.opt;
    .utest.testModule each `$"," vs first .sys.opt`test_module;
    // exit 0;
  ];
  :`$();
 };
