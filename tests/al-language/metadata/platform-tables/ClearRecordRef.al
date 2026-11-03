// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74011
// Probe: written against BC 29 (P95 draft; observation only, the lead measures the facts)
// Facts: Clear on RecordRef and FieldRef: state afterwards and errors on use
// BC versions: 29
// Tag: P95

codeunit 74011 "LT P95 Clear RecordRef"
{
    Subtype = Test;
    TestPermissions = Disabled;


    [TryFunction]
    local procedure TryN(var RR: RecordRef; var R: Text)
    begin
        R := Format(RR.Number());
    end;

    [TryFunction]
    local procedure TryE(var RR: RecordRef; var R: Text)
    begin
        R := Format(RR.IsEmpty());
    end;

    [TryFunction]
    local procedure TryF(var FR: FieldRef; var R: Text)
    begin
        R := Format(FR.Number());
    end;

    local procedure TryNumber(var RR: RecordRef): Text
    var
        R: Text;
    begin
        if TryN(RR, R) then
            exit('ok|' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure TryEmpty(var RR: RecordRef): Text
    var
        R: Text;
    begin
        if TryE(RR, R) then
            exit('ok|' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure TryFieldNo(var FR: FieldRef): Text
    var
        R: Text;
    begin
        if TryF(FR, R) then
            exit('ok|' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure ClearRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        FR: FieldRef;
    begin
        RR.Open(2000000038);
        Observer.Observe('opened', Format(RR.Number()));
        Clear(RR);
        Observer.Observe('after_clear_try', TryNumber(RR));
        Observer.Observe('after_clear_isempty_try', TryEmpty(RR));
        RR.Open(2000000038);
        FR := RR.Field(1);
        Observer.Observe('field_before', Format(FR.Number()));
        Clear(FR);
        Observer.Observe('field_after_try', TryFieldNo(FR));
        Clear(RR);
        Clear(RR);
        Observer.Observe('double_clear_try', TryNumber(RR));

        Observer.Expect('opened', '2000000038');
        Observer.Expect('after_clear_try', 'ok|0');
        Observer.Expect('after_clear_isempty_try', 'error:The record is not open.|RecordNotOpened');
        Observer.Expect('field_before', '1');
        Observer.Expect('field_after_try', 'error:Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.|NotInitialized');
        Observer.Expect('double_clear_try', 'ok|0');
        Observer.Verify();
    end;

}
