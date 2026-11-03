// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-testpermissions-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT BI TP Probe (81551)
// Corpus issue 658, one TestPermissions variant with Tests-TestLibraries installed: no TestPermissions property on the codeunit and no attribute on the method.
// Probe: observed values under Microsoft's test runner (see BiTpHelper.al); every literal asserted below is what the BC tier produced
// (corpus CI job test-testlibraries, run 39223234414 on BC 29.0; 27.5 and 28.5 by the CI matrix).
// BC versions: 27, 28, 29
codeunit 81553 "LT BI TP Default"
{
    Subtype = Test;

    [Test]
    [HandlerFunctions('BiTpMsg')]
    procedure BiTpDefault_Permissions()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BI TP Probe";
    begin
        Message('LT BI');
        Probe.ObservePermissions(Observer);
        Observer.Expect('own_r', 'No');
        Observer.Expect('own_w', 'No');
        Observer.Expect('cust_r', 'Yes');
        Observer.Expect('cust_w', 'Yes');
        Observer.Expect('gl_r', 'Yes');
        Observer.Expect('gl_w', 'No');
        Observer.Expect('ac_r', 'Yes');
        Observer.Expect('ac_w', 'Yes');
        Observer.Expect('runner', '130450,130454,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BiTpMsg')]
    procedure BiTpDefault_Insert()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BI TP Probe";
    begin
        Message('LT BI');
        asserterror Probe.InsertThenFail();
        Observer.ObserveError('ins');
        Observer.Expect('ins|text', 'Sorry, the current permissions prevented the action. (TableData 81550 LT BI TP Row Insert: AL Language Coverage Tests (Test Libraries))');
        Observer.Expect('ins|code', 'DB:ClientInsertDenied');
        Observer.Verify();
    end;

    [MessageHandler]
    procedure BiTpMsg(Msg: Text[1024])
    begin
    end;
}
