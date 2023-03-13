.test.mod: .sys.useTest`timer;

.tst.beforeAll:{
    .test.jobs: .test.mod.ns`jobs;
    .test.status: .test.mod.ns`status;
    .test.P: .sys.P;
    .test.D: .sys.D;
 };

.tst.after:{
    @[.test.mod.ns;`jobs;:;.test.jobs];
    @[.test.mod.ns;`status;:;.test.status];
    .sys.P: .test.P;
    .sys.D: .test.D;
 }

.tst.testNewJobCfg:{
    j: .test.mod.new[];
    // default params
    assert_eqv[asc key j`cfg;`args`eTime`group`id`logStatus`name`relativeInt`strict];
    // id is unique
    assert[j[`id] within (.z.P-0D00:00:01;.z.P)];
    j2: .test.mod.new[];
    assert_not[j2[`id]=j`id];
    // delay
    j3: j[`delay;10t];
    assert_eqv[j3`delay;0D10];
    j3: j[`delay;10:10];
    assert_eqv[j3`delay;0D10:10];
    j3: j[`delay;10:10:10];
    assert_eqv[j3`delay;0D10:10:10];
    j3: j[`delay;0D20];
    assert_eqv[j3`delay;0D20];
    // fn
    j3: j[`fn;{x+y}];
    assert_eqv[j3`fn;{x+y}];
    j3: j[`fn;`test];
    assert_eqv[j3`fn;`test];
    // interval
    j3: j[`interval;10t];
    assert_eqv[j3`interval;0D10];
    j3: j[`interval;10:10];
    assert_eqv[j3`interval;0D10:10];
    j3: j[`interval;10:10:10];
    assert_eqv[j3`interval;0D10:10:10];
    j3: j[`interval;0D20];
    assert_eqv[j3`interval;0D20];
    // sTime/eTime
    assert_eqv[j3`eTime;0Wp];
    {[j;x] j3: j[x;10t];
        assert_eqv[j3 x;10t];
        j3: j[x;10:10];
        assert_eqv[j3 x;10:10t];
        j3: j[x;10:10:10];
        assert_eqv[j3 x;10:10:10t];
        j3: j[x;0D20];
        assert_eqv[j3 x;20t];
        j3: j[x;2020.10.10];
        assert_eqv[j3 x;2020.10.10D];
        j3: j[x;2020.10.10D10];
        assert_eqv[j3 x;2020.10.10D10]}[j] each `sTime`eTime;
    // args
    assert_eqv[j`args;0];
    j3: j[`args;(1;`s)];
    assert_eqv[j3`args;(1;`s)];
    // until
    j3: j[`until;(1;`s)];
    assert_eqv[j3`until;(1;`s)];
    // relativeInt
    assert_eqv[j`relativeInt;1b];
    j3: j[`relativeInt;0b];
    assert_eqv[j3`relativeInt;0b];
    // strict
    assert_eqv[j`strict;0b];
    j3: j[`strict;1b];
    assert_eqv[j3`strict;1b];
    // strict
    assert_eqv[j`logStatus;1b];
    j3: j[`logStatus;0b];
    assert_eqv[j3`logStatus;0b];
    // id
    assert_exc[{y; x[`id;100]}j;"readonly"];
    // name
    assert_eqv[j`name;`];
    j3: j[`name;`aa];
    assert_eqv[j3`name;`aa];
    j3: j[`name;"bb"];
    assert_eqv[j3`name;`bb];
    // group
    assert_eqv[j`group;`];
    j3: j[`group;`aa];
    assert_eqv[j3`group;`aa];
    j3: j[`group;"bb"];
    assert_eqv[j3`group;`bb];
    // cb
    j3: j[`cb;`aa];
    assert_eqv[j3`cb;`aa];
    j3: j[`cb;{x}];
    assert_eqv[j3`cb;{x}];
 };

.tst.testJobCfg:{
    ns: .test.mod.ns;

    jid: .test.mod.new[][`delay;0D11][`fn;`.test.test]`start;
    j: .test.mod.get jid;
    // default params
    assert_eqv[key j`cfg;(),`id];
    // clone
    c: j`clone;
    assert_eqv[asc key c`cfg;`args`delay`eTime`fn`group`id`logStatus`name`relativeInt`strict];
    assert_eqv[c`delay;0D11];
    // suspend
    j`suspend;
    assert[not exec first active from .test.mod.ns`jobs where id=jid];
    // resume
    j`resume;
    assert[exec first active from .test.mod.ns`jobs where id=jid];
    // run once
    .test.test:{.test.jobcfg:`runOnce};
    j`runOnce;
    assert_eqv[.test.jobcfg;`runOnce];
    assert jid in (.test.mod.ns`jobs)`id;
    // run - job will be deleted
    .test.test:{.test.jobcfg:`run};
    j`run;
    assert_eqv[.test.jobcfg;`run];
    assert not jid in (.test.mod.ns`jobs)`id;
    // stop
    jid: .test.mod.new[][`delay;0D11][`fn;`.test.test2]`start;
    j: .test.mod.get jid;
    j`stop;
    assert not jid in (.test.mod.ns`jobs)`id;
 };

.tst.testGetBy:{
    jid: .test.mod.new[][`delay;0D11][`fn;`.test.test_nofn]`start;
    assert_eqv[.test.mod.ns[`getByID] jid;1];
    assert_eqv[.test.mod.ns[`getByID] 10;0N];
    assert_eqv[.test.mod.ns[`getJob] jid;1];
    assert_exc[{.test.mod.ns[`getJob] 10};"Job has finished"];
 };

.tst.testGet:{
    jid: .test.mod.new[][`delay;0D11][`name;`testn][`fn;`.test.test_nofn]`start;
    j: .test.mod.get`testn;
    assert_eqv[j`id;jid];
    assert_exc[{.test.mod.get`testn2};"Not found"];
    j: .test.mod.get jid;
    assert_eqv[j`id;jid];
    assert_exc[{.test.mod.get -1};"Not found"];
    assert_eqv[.test.mod.ns`jobs;.test.mod.get[]];
    assert_exc[{.test.mod.get 1f};"type"];
 };

.tst.testStart:{
    .sys.P:{2010.10.10D10};
    .sys.D:{2010.10.10};
    // exceptions
    j: .test.mod.new[][`delay;0D11][`sTime;.z.T][`fn;`.test.test_nofn];
    assert_exc[{y; x`start}j;"You can't use delay and sTime together"];
    j: .test.mod.new[][`fn;`.test.test_nofn];
    assert_exc[{y; x`start}j;"Provide sTime or delay for one time jobs"];
    jid: .test.mod.new[][`delay;0D11][`name;`tst][`fn;`.test.test_nofn]`start;
    j: .test.mod.new[][`delay;0D11][`name;`tst][`fn;`.test.test_nofn];
    assert_exc[{y; x`start}j;"Job with name tst already exists"];
    // sTime
    jid: .test.mod.new[][`sTime;2200.01.01D10][`fn;`.test.test_nofn]`start;
    j:first select from (.test.mod.ns`jobs) where id=jid;
    assert_eqv[j`sTime;2200.01.01D10];
    assert_eqv[j`eTime;0Wp];
    assert_eqv[j`interval;0Nn];
    jid: .test.mod.new[][`sTime;10:00t][`fn;`.test.test_nofn]`start;
    j:first select from (.test.mod.ns`jobs) where id=jid;
    assert_eqv[j`sTime;2010.10.10+0D10];
    assert_eqv[j`eTime;0Wp];
    assert_eqv[j`interval;0Nn];
    jid: .test.mod.new[][`interval;0D10][`fn;`.test.test_nofn]`start;
    j:first select from (.test.mod.ns`jobs) where id=jid;
    assert_eqv[j`sTime;2010.10.10D10+0D10];
    assert_eqv[j`eTime;0Wp];
    assert_eqv[j`interval;0D10];
    jid: .test.mod.new[][`delay;10:00t][`fn;`.test.test_nofn]`start;
    j:first select from (.test.mod.ns`jobs) where id=jid;
    assert_eqv[j`sTime;2010.10.10+0D10];
    assert_eqv[j`eTime;0Wp];
    assert_eqv[j`interval;0Nn];
 };