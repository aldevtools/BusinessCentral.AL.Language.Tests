// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed rows: ExecutionMode "The other members of ExecutionMode and every ordinal are not pinned"; ClientType "The member ClientType::ODataV4 exists ... its ordinal is not pinned" (probe batch 4)
// BC versions: 29 (27 and 28 by CI)

codeunit 71113 "LT PnC System Enums"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ExecutionMode_Members()
    var
        Observer: Codeunit "Probe Observer";
        Mode: ExecutionMode;
        i: Integer;
        ok: Boolean;
    begin
        Observer.Observe('standard.ordinal', Format(ExecutionMode::Standard, 0, 2));
        Observer.Observe('debug.ordinal', Format(ExecutionMode::Debug, 0, 2));
        Observer.Observe('standard.name', Format(ExecutionMode::Standard));
        Observer.Observe('debug.name', Format(ExecutionMode::Debug));
        Observer.Observe('current', Format(Session.CurrentExecutionMode()));
        for i := 0 to 12 do begin
            ok := Evaluate(Mode, Format(i), 9);
            if ok then
                Observer.Observe('ordinal' + Format(i), Format(Mode) + '|' + Format(Mode, 0, 2))
            else
                Observer.Observe('ordinal' + Format(i), 'no');
        end;
        Observer.Expect('standard.ordinal', '0');
        Observer.Expect('debug.ordinal', '1');
        Observer.Expect('standard.name', 'Standard');
        Observer.Expect('debug.name', 'Debug');
        Observer.Expect('current', 'Standard');
        Observer.Expect('ordinal0', 'Standard|0');
        Observer.Expect('ordinal1', 'Debug|1');
        Observer.Expect('ordinal2', 'no');
        Observer.Expect('ordinal3', 'no');
        Observer.Expect('ordinal4', 'no');
        Observer.Expect('ordinal5', 'no');
        Observer.Expect('ordinal6', 'no');
        Observer.Expect('ordinal7', 'no');
        Observer.Expect('ordinal8', 'no');
        Observer.Expect('ordinal9', 'no');
        Observer.Expect('ordinal10', 'no');
        Observer.Expect('ordinal11', 'no');
        Observer.Expect('ordinal12', 'no');
        Observer.Verify();
    end;

    [Test]
    procedure ClientType_Members()
    var
        Observer: Codeunit "Probe Observer";
        Ct: ClientType;
        i: Integer;
        ok: Boolean;
    begin
        Observer.Observe('odatav4.ordinal', Format(ClientType::ODataV4, 0, 2));
        Observer.Observe('odatav4.name', Format(ClientType::ODataV4));
        Observer.Observe('default.ordinal', Format(ClientType::Default, 0, 2));
        Observer.Observe('web.ordinal', Format(ClientType::Web, 0, 2));
        Observer.Observe('childsession.ordinal', Format(ClientType::ChildSession, 0, 2));
        for i := 0 to 17 do begin
            ok := Evaluate(Ct, Format(i), 9);
            if ok then
                Observer.Observe('ordinal' + Format(i), Format(Ct))
            else
                Observer.Observe('ordinal' + Format(i), 'no');
        end;
        Observer.Expect('odatav4.ordinal', '13');
        Observer.Expect('odatav4.name', 'ODataV4');
        Observer.Expect('default.ordinal', '1');
        Observer.Expect('web.ordinal', '3');
        Observer.Expect('childsession.ordinal', '15');
        Observer.Expect('ordinal0', 'Current');
        Observer.Expect('ordinal1', 'Default');
        Observer.Expect('ordinal2', 'Windows');
        Observer.Expect('ordinal3', 'Web');
        Observer.Expect('ordinal4', 'SOAP');
        Observer.Expect('ordinal5', 'OData');
        Observer.Expect('ordinal6', 'NAS');
        Observer.Expect('ordinal7', 'Background');
        Observer.Expect('ordinal8', 'Management');
        Observer.Expect('ordinal9', 'Tablet');
        Observer.Expect('ordinal10', 'Phone');
        Observer.Expect('ordinal11', 'Desktop');
        Observer.Expect('ordinal12', 'Teams');
        Observer.Expect('ordinal13', 'ODataV4');
        Observer.Expect('ordinal14', 'Api');
        Observer.Expect('ordinal15', 'ChildSession');
        Observer.Expect('ordinal16', 'no');
        Observer.Expect('ordinal17', 'no');
        Observer.Verify();
    end;
}
