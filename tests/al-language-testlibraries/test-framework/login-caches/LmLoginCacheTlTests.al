// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-global-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (69160) and the reader "LT LM Cache Reader" (75886) of the corpus app
//   (tests/al-language/events/platform-triggers/LmLoginCacheTests.al, which describes the cells); XApp A
//   tests/al-language-xapp-a/LmXaLoginCaches.al.
// Probe (al-runner issue 8945): the cells L1, G3, E1, M1-M4 of LmLoginCacheTests.al in the job that installs Tests-TestLibraries. There
//   codeunit 130011 "Backup Management" sets all four flags of every table's trigger setup, so every write raises the database events:
//   Change Log Management loads in OnDatabaseInsert (LogInsertion -> IsLogActive) instead of in the setup ask, and the L1 memo loads on
//   the session's first write event.
// BC versions: 27 - 29

codeunit 81597 "LT LM Login Cache TL Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure L1Memo_AfterLogin()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LM Cache Reader";
    begin
        Reader.ObserveL1(Observer, '');
        Observer.Expect('L1 checked', 'Yes');
        Observer.Expect('L1 activated', 'No');
        Observer.Expect('L1 loaded', 'Yes');
        Observer.Expect('L1 setup rows', '0');
        Observer.Expect('L1 setup filters', '');
        Observer.Expect('L1 setup key', '0');
        Observer.Expect('L1 setup key is the load table', 'No');
        Observer.Expect('L1 setup note', '');
        Observer.Expect('L1 sub rows', '0');
        Observer.Expect('L1 sub rows in view', '0');
        Observer.Expect('L1 sub filters', 'Company Name: ''''');
        Observer.Expect('L1 sub key', '|');
        Observer.Expect('L1 written', '');
        Observer.Verify();
    end;

    [Test]
    procedure G3Memo_AfterLogin()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LM Cache Reader";
    begin
        Reader.ObserveG3(Observer, '');
        Observer.Expect('G3 A state', 'checked Yes, activated No, loaded Yes, disabled No; setup rows 0, filters [], key 0, note []; sub rows 0, in view 0, filters [Company Name: ''''], key [|]');
        Observer.Expect('G3 B state', 'checked Yes, activated No, loaded Yes, disabled No; setup rows 0, filters [], key 0, note []; sub rows 0, in view 0, filters [Company Name: ''''], key [|]');
        Observer.Expect('G3 B state equals A state', 'Yes');
        Observer.Expect('G3 B loaded by', 'I');
        Observer.Expect('G3 B guard steps', 'start B No;handled No;disabled No;temporary No;');
        Observer.Expect('G3 asks seen', 'Yes');
        Observer.Expect('G3 ask saw an empty company name', 'No');
        Observer.Expect('G3 ask saw no read permission', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure EnvInfo_AfterLogin()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LM Cache Reader";
    begin
        Reader.ObserveEnv(Observer, '');
        Observer.Expect('E1 sandbox kept by the first subscriber', 'Yes');
        Observer.Expect('E1 saas kept by the second subscriber', 'Yes');
        Observer.Expect('E1 IsSandbox equals the login value', 'Yes');
        Observer.Expect('E1 IsSaaS equals the login value', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AppAreas_AfterLogin()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LM Cache Reader";
    begin
        Reader.ObserveAreas(Observer, '');
        Reader.AreasChange(Observer);
        Observer.Expect('M1 areas equal the login value', 'Yes');
        Observer.Expect('M1 change rolled back', 'LT LM rollback');
        Observer.Expect('M1 read after the change differs from the login value', 'Yes');
        Observer.Expect('M1 read after the change', '#Basic');
        Observer.Expect('M1 read after the rollback equals the login value', 'No');
        Observer.Expect('M1 read after the clear equals the login value', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Profile_AfterLogin()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LM Cache Reader";
    begin
        Reader.ObserveProfile(Observer, '');
        Reader.ProfileChange(Observer);
        Observer.Expect('M2 profile equals the login value', 'Yes');
        Observer.Expect('M2 found equals the login value', 'Yes');
        Observer.Expect('M2 another profile exists', 'Yes');
        Observer.Expect('M2 change rolled back', 'LT LM rollback');
        Observer.Expect('M2 read after the change equals the login value', 'Yes');
        Observer.Expect('M2 read after the change is the other profile', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ChangeLog_AfterLogin()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LM Cache Reader";
    begin
        Reader.ObserveChangeLog(Observer);
        Observer.Expect('M3 change with triggers rolled back', 'LT LM rollback');
        Observer.Expect('M3 change rolled back', 'LT LM rollback');
        Observer.Expect('M3 setup after the rollbacks equals the setup before', 'Yes');
        Observer.Expect('M3 entries with triggers without InitChangeLog', '0');
        Observer.Expect('M3 entries without InitChangeLog', '0');
        Observer.Expect('M3 entries after InitChangeLog', '2');
        Observer.Verify();
    end;

    [Test]
    procedure ApiCache_CountingSubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LM Cache Reader";
    begin
        Reader.ObserveApi(Observer, '', false);
        Observer.Expect('M4 asks on the first insert', '0');
        Observer.Expect('M4 asks on the second insert', '0');
        Observer.Expect('M4 asks on the insert after Reset', '1');
        Observer.Expect('M4 asks on the next insert', '0');
        Observer.Verify();
    end;

    [Test]
    procedure ApiCache_AnsweringSubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LM Cache Reader";
    begin
        Reader.ObserveApi(Observer, '', true);
        Observer.Expect('M4 asks on the first insert', '0');
        Observer.Expect('M4 asks on the second insert', '0');
        Observer.Expect('M4 asks on the insert after Reset', '1');
        Observer.Expect('M4 asks on the next insert', '0');
        Observer.Verify();
    end;

    [Test]
    procedure L1Memo_TestAddsSetupRow()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LM Cache Reader";
    begin
        Reader.L1AddSetupAndWrite(Observer);
        Observer.Expect('after setup row: L1 checked', 'Yes');
        Observer.Expect('after setup row: L1 activated', 'No');
        Observer.Expect('after setup row: L1 loaded', 'Yes');
        Observer.Expect('after setup row: L1 setup rows', '0');
        Observer.Expect('after setup row: L1 setup filters', '');
        Observer.Expect('after setup row: L1 setup key', '0');
        Observer.Expect('after setup row: L1 setup key is the load table', 'No');
        Observer.Expect('after setup row: L1 setup note', '');
        Observer.Expect('after setup row: L1 sub rows', '0');
        Observer.Expect('after setup row: L1 sub rows in view', '0');
        Observer.Expect('after setup row: L1 sub filters', 'Company Name: ''''');
        Observer.Expect('after setup row: L1 sub key', '|');
        Observer.Expect('after setup row: L1 written', '');
        Observer.Verify();
    end;
}

codeunit 81598 "LT LM Login Cache TL Tests B"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AllCaches_SecondCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LM Cache Reader";
    begin
        Reader.ObserveL1(Observer, 'B: ');
        Reader.ObserveEnv(Observer, 'B: ');
        Reader.ObserveAreas(Observer, 'B: ');
        Reader.ObserveProfile(Observer, 'B: ');
        Reader.ObserveG3(Observer, 'B: ');
        Observer.Expect('B: L1 checked', 'Yes');
        Observer.Expect('B: L1 activated', 'No');
        Observer.Expect('B: L1 loaded', 'Yes');
        Observer.Expect('B: L1 setup rows', '0');
        Observer.Expect('B: L1 setup filters', '');
        Observer.Expect('B: L1 setup key', '0');
        Observer.Expect('B: L1 setup key is the load table', 'No');
        Observer.Expect('B: L1 setup note', '');
        Observer.Expect('B: L1 sub rows', '0');
        Observer.Expect('B: L1 sub rows in view', '0');
        Observer.Expect('B: L1 sub filters', 'Company Name: ''''');
        Observer.Expect('B: L1 sub key', '|');
        Observer.Expect('B: L1 written', '');
        Observer.Expect('B: E1 sandbox kept by the first subscriber', 'Yes');
        Observer.Expect('B: E1 saas kept by the second subscriber', 'Yes');
        Observer.Expect('B: E1 IsSandbox equals the login value', 'Yes');
        Observer.Expect('B: E1 IsSaaS equals the login value', 'Yes');
        Observer.Expect('B: M1 areas equal the login value', 'Yes');
        Observer.Expect('B: M2 profile equals the login value', 'Yes');
        Observer.Expect('B: M2 found equals the login value', 'Yes');
        Observer.Expect('B: G3 A state', 'checked Yes, activated No, loaded Yes, disabled No; setup rows 0, filters [], key 0, note []; sub rows 0, in view 0, filters [Company Name: ''''], key [|]');
        Observer.Expect('B: G3 B state', 'checked Yes, activated No, loaded Yes, disabled No; setup rows 0, filters [], key 0, note []; sub rows 0, in view 0, filters [Company Name: ''''], key [|]');
        Observer.Expect('B: G3 B state equals A state', 'Yes');
        Observer.Expect('B: G3 B loaded by', 'I');
        Observer.Expect('B: G3 B guard steps', 'start B No;handled No;disabled No;temporary No;');
        Observer.Expect('B: G3 asks seen', 'Yes');
        Observer.Expect('B: G3 ask saw an empty company name', 'No');
        Observer.Expect('B: G3 ask saw no read permission', 'No');
        Observer.Verify();
    end;
}
