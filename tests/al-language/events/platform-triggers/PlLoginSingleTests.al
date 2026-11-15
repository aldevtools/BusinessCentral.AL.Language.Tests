// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); XApp A tests/al-language-xapp-a/PlXaLoginSingles.al (SingleInstance codeunit 98486, subscriber
//   98487 of "System Initialization".OnAfterLogin); main app SingleInstance codeunit 98481 below (subscriber of "Company Triggers".OnCompanyOpenCompleted).
// Probe (al-runner issue 8115, cell s09), observe form: what the test session sees of the SingleInstance state a dependency app's OnAfterLogin
//   subscriber sets (Cnt := 10, one List.Add, Txt += 'L', a call counter). Cells: first read in test 1 of codeunit A; test 2 of A after test 1 did
//   Cnt += 1; first read in a second test codeunit B (fresh session per codeunit or the same instance); and a copy that the main app's
//   OnCompanyOpenCompleted subscriber made of the XApp A single (what it saw, and how often it ran).
// BC versions: 27 - 29
// singleinstance-shared-on-purpose: both test codeunits read the same XApp A instance and the same copy; that is the probe.

codeunit 98481 "LT PL Main Copy"
{
    SingleInstance = true;

    var
        Calls: Integer;
        SeenCnt: Integer;
        SeenNames: Integer;
        SeenTxt: Text;
        SeenLogins: Integer;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpenCompleted', '', false, false)]
    local procedure OnCompanyOpenCompleted()
    var
        Singles: Codeunit "LT PL XA Singles";
    begin
        Calls += 1;
        SeenCnt := Singles.GetCnt();
        SeenNames := Singles.NameCount();
        SeenTxt := Singles.GetTxt();
        SeenLogins := Singles.GetLoginCalls();
    end;

    procedure Report(Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('copy calls', Format(Calls));
        Observer.Observe('copy cnt', Format(SeenCnt));
        Observer.Observe('copy names', Format(SeenNames));
        Observer.Observe('copy txt', SeenTxt);
        Observer.Observe('copy logins', Format(SeenLogins));
    end;
}

codeunit 98483 "LT PL Login Singles A"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ReadAll(IncAfterRead: Boolean)
    var
        Observer: Codeunit "Probe Observer";
        Singles: Codeunit "LT PL XA Singles";
        Copy: Codeunit "LT PL Main Copy";
    begin
        Observer.Observe('cnt', Format(Singles.GetCnt()));
        Observer.Observe('names', Format(Singles.NameCount()));
        Observer.Observe('txt', Singles.GetTxt());
        Observer.Observe('login calls', Format(Singles.GetLoginCalls()));
        Copy.Report(Observer);
        if IncAfterRead then
            Singles.IncCnt();
        Observer.Finish();
    end;

    [Test]
    procedure PlA_T1_FirstRead_ThenCntPlusOne()
    begin
        ReadAll(true);
    end;

    [Test]
    procedure PlA_T2_AfterCntPlusOne()
    begin
        ReadAll(false);
    end;
}

codeunit 98484 "LT PL Login Singles B"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PlB_T1_FirstRead_SecondCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Singles: Codeunit "LT PL XA Singles";
        Copy: Codeunit "LT PL Main Copy";
    begin
        Observer.Observe('cnt', Format(Singles.GetCnt()));
        Observer.Observe('names', Format(Singles.NameCount()));
        Observer.Observe('txt', Singles.GetTxt());
        Observer.Observe('login calls', Format(Singles.GetLoginCalls()));
        Copy.Report(Observer);
        Observer.Finish();
    end;
}
