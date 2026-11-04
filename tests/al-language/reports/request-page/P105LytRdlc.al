// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: tables and helper of P105Fix.al; self-contained report 72259 and test codeunit 72260; RISKY: layout member
// Facts: Report.RdlcLayout on a variable and with the report id for a report without a RDLC layout: result and stream state; unknown id

report 72259 "LT P105 LytRdlc Rep"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P105 Row")
        {
            column(Id; Id) { }
            column(Name; Name) { }
        }
    }
}

codeunit 72260 "LT P105 LytRdlc Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT P105 Helper";

    [TryFunction]
    local procedure TryInst(var R: Text)
    var
        Rpt: Report "LT P105 LytRdlc Rep";
        InStr: InStream;
        Ok: Boolean;
    begin
        Ok := Rpt.RdlcLayout(InStr);
        R := Format(Ok) + ' eos=' + Format(InStr.EOS);
    end;

    [TryFunction]
    local procedure TryStatic(var R: Text)
    var
        InStr: InStream;
        Ok: Boolean;
    begin
        Ok := Report.RdlcLayout(Report::"LT P105 LytRdlc Rep", InStr);
        R := Format(Ok) + ' eos=' + Format(InStr.EOS);
    end;

    [TryFunction]
    local procedure TryUnknown(var R: Text)
    var
        InStr: InStream;
    begin
        R := Format(Report.RdlcLayout(72399, InStr));
    end;

    local procedure Failed(): Text
    begin
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure P105_RdlcLayout_Instance()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        Helper.Seed();
        if TryInst(R) then
            Observer.Observe('instance', 'ok ' + R)
        else
            Observer.Observe('instance', Failed());
        Observer.Expect('instance', 'error:Microsoft.Dynamics.Nav.Runtime.NavInStream variable not initialized.|NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure P105_RdlcLayout_Static()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        Helper.Seed();
        if TryStatic(R) then
            Observer.Observe('static', 'ok ' + R)
        else
            Observer.Observe('static', Failed());
        Observer.Expect('static', 'error:Microsoft.Dynamics.Nav.Runtime.NavInStream variable not initialized.|NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure P105_RdlcLayout_UnknownId()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        if TryUnknown(R) then
            Observer.Observe('unknown', 'ok ' + R)
        else
            Observer.Observe('unknown', Failed());
        Observer.Expect('unknown', 'ok No');
        Observer.Verify();
    end;
}
