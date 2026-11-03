// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-testpermissions-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT BI TP Probe (81551)
// Corpus issue 658, one TestPermissions variant with Tests-TestLibraries installed: codeunit Disabled, method attribute InheritFromTestCodeunit.
// Probe: observed values under Microsoft's test runner (see BiTpHelper.al); every literal asserted below is what the BC tier produced
// (corpus CI job test-testlibraries, run 39223234414 on BC 29.0; 27.5 and 28.5 by the CI matrix).
// BC versions: 27, 28, 29
codeunit 81561 "LT BI TP DisMInherit"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [HandlerFunctions('BiTpMsg')]
    [TestPermissions(TestPermissions::InheritFromTestCodeunit)]
    procedure BiTpDisMInherit_Permissions()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BI TP Probe";
    begin
        Message('LT BI');
        Probe.ObservePermissions(Observer);
        Observer.Expect('own_r', 'Yes');
        Observer.Expect('own_w', 'Yes');
        Observer.Expect('cust_r', 'Yes');
        Observer.Expect('cust_w', 'Yes');
        Observer.Expect('gl_r', 'Yes');
        Observer.Expect('gl_w', 'Yes');
        Observer.Expect('ac_r', 'Yes');
        Observer.Expect('ac_w', 'Yes');
        Observer.Expect('runner', '130450,130454,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BiTpMsg')]
    [TestPermissions(TestPermissions::InheritFromTestCodeunit)]
    procedure BiTpDisMInherit_Insert()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BI TP Probe";
    begin
        Message('LT BI');
        asserterror Probe.InsertThenFail();
        Observer.ObserveError('ins');
        Observer.Expect('ins|text', 'LT BI inserted');
        Observer.Expect('ins|code', 'Dialog');
        Observer.Verify();
    end;

    [MessageHandler]
    procedure BiTpMsg(Msg: Text[1024])
    begin
    end;
}
