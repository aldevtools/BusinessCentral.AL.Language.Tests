// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-testpermissions-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT BA TP Probe (80751)
// Corpus issue 658, one TestPermissions variant: TestPermissions = Disabled on the codeunit.
// Probe: observed values; every literal asserted below is what the BC tier produced under Microsoft's test runner (see BaTpHelper.al).
// BC versions: 27, 28, 29
// LINUX SUSPECT (corpus issue 658): observed on BC 28.5 and 29.0 (runs 39181445217, 39181485301) under runner 130450: every
// variant has full permissions (own table, Customer, Access Control: read and write Yes; the insert succeeds). That contradicts
// MsDyn365Bc.On.Linux issue 64 (Restrictive refused an insert into an own table on BC 28.4). Not asserted until the Windows
// nightly confirms it: the codeunit compiles only with the symbol LTBA_TESTPERMISSIONS_PROBE, which no CI leg defines.
#if LTBA_TESTPERMISSIONS_PROBE
codeunit 80753 "LT BA TP Disabled"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [HandlerFunctions('BaTpMsg')]
    procedure BaTpDisabled_Permissions()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BA TP Probe";
    begin
        Message('LT BA');
        Probe.ObservePermissions(Observer);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('BaTpMsg')]
    procedure BaTpDisabled_Insert()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BA TP Probe";
    begin
        Message('LT BA');
        asserterror Probe.InsertThenFail();
        Observer.ObserveError('ins');
        Observer.Finish();
    end;

    [MessageHandler]
    procedure BaTpMsg(Msg: Text[1024])
    begin
    end;
}
#endif
