// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Probe: written against BC 29 (observation only; the literals are measured later). Tag P91 (GitHub issue 91).
// BC versions: 29
// Fixtures used: tables and helper of P91Fix.al; self-contained reports 71597, 71598 and codeunit 71611
// Facts (stream SaveAs overloads are OnPrem only and not used): static Report layout members (DefaultLayout, RdlcLayout, WordLayout, ExcelLayout, WordXmlPart) on reports without a layout file, a ProcessingOnly report, 0 and an unknown id;
// stream overloads SaveAsPdf / SaveAsWord / SaveAsExcel / SaveAsHtml / SaveAsXml into an OutStream

report 71597 "LT P91 NoLayout"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P91 Row")
        {
            column(IdCol; Id) { }
            column(NameCol; Name) { }
        }
    }
}

report 71598 "LT P91 ProcOnly"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P91 Row")
        {
            column(IdCol; Id) { }
        }
    }
}

codeunit 71611 "LT P91 Static Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT P91 Helper";
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryDefaultLayout(Id: Integer; var R: Text)
    begin
        R := Format(Report.DefaultLayout(Id));
    end;

    local procedure DefaultLayoutOf(Id: Integer): Text
    var
        R: Text;
    begin
        if TryDefaultLayout(Id, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryLayoutStream(Kind: Integer; Id: Integer; var R: Text)
    var
        InS: InStream;
    begin
        case Kind of
            1:
                Report.RdlcLayout(Id, InS);
            2:
                Report.WordLayout(Id, InS);
            3:
                Report.ExcelLayout(Id, InS);
        end;
        R := 'eos=' + Format(InS.EOS());
    end;

    local procedure LayoutStreamOf(Kind: Integer; Id: Integer): Text
    var
        R: Text;
    begin
        if TryLayoutStream(Kind, Id, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryWordXmlPart(Id: Integer; var R: Text)
    begin
        R := 'len>0=' + Format(StrLen(Report.WordXmlPart(Id)) > 0);
    end;

    local procedure WordXmlPartOf(Id: Integer): Text
    var
        R: Text;
    begin
        if TryWordXmlPart(Id, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure DefaultLayout_Reports()
    begin
        Observer.Observe('nolayout', DefaultLayoutOf(Report::"LT P91 NoLayout"));
        Observer.Observe('proconly', DefaultLayoutOf(Report::"LT P91 ProcOnly"));
        Observer.Observe('zero', DefaultLayoutOf(0));
        Observer.Observe('unknown', DefaultLayoutOf(71999));
        Observer.Observe('negative', DefaultLayoutOf(-1));
        Observer.Expect('nolayout', 'RDLC');
        Observer.Expect('proconly', 'None');
        Observer.Expect('zero', 'error:You tried to invoke the Report object with the ID 0 from the object LT P91 Static Tests. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Expect('unknown', 'error:You tried to invoke the Report object with the ID 71999 from the object LT P91 Static Tests. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Expect('negative', 'error:You tried to invoke the Report object with the ID -1 from the object LT P91 Static Tests. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure RdlcLayout_Reports()
    begin
        Observer.Observe('nolayout', LayoutStreamOf(1, Report::"LT P91 NoLayout"));
        Observer.Observe('proconly', LayoutStreamOf(1, Report::"LT P91 ProcOnly"));
        Observer.Observe('zero', LayoutStreamOf(1, 0));
        Observer.Observe('unknown', LayoutStreamOf(1, 71999));
        Observer.Expect('nolayout', 'eos=Yes');
        Observer.Expect('proconly', 'error:Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLReportNoLayoutException'' was thrown.|ReportNoLayout');
        Observer.Expect('zero', 'error:You tried to invoke the Report object with the ID 0 from the object LT P91 Static Tests. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Expect('unknown', 'error:You tried to invoke the Report object with the ID 71999 from the object LT P91 Static Tests. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure WordLayout_Reports()
    begin
        Observer.Observe('nolayout', LayoutStreamOf(2, Report::"LT P91 NoLayout"));
        Observer.Observe('proconly', LayoutStreamOf(2, Report::"LT P91 ProcOnly"));
        Observer.Observe('zero', LayoutStreamOf(2, 0));
        Observer.Observe('unknown', LayoutStreamOf(2, 71999));
        Observer.Expect('nolayout', 'error:Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLReportNoLayoutException'' was thrown.|ReportNoLayout');
        Observer.Expect('proconly', 'error:Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLReportNoLayoutException'' was thrown.|ReportNoLayout');
        Observer.Expect('zero', 'error:You tried to invoke the Report object with the ID 0 from the object LT P91 Static Tests. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Expect('unknown', 'error:You tried to invoke the Report object with the ID 71999 from the object LT P91 Static Tests. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure ExcelLayout_Reports()
    begin
        Observer.Observe('nolayout', LayoutStreamOf(3, Report::"LT P91 NoLayout"));
        Observer.Observe('proconly', LayoutStreamOf(3, Report::"LT P91 ProcOnly"));
        Observer.Observe('zero', LayoutStreamOf(3, 0));
        Observer.Observe('unknown', LayoutStreamOf(3, 71999));
        Observer.Expect('nolayout', 'error:Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLReportNoLayoutException'' was thrown.|ReportNoLayout');
        Observer.Expect('proconly', 'error:Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLReportNoLayoutException'' was thrown.|ReportNoLayout');
        Observer.Expect('zero', 'error:You tried to invoke the Report object with the ID 0 from the object LT P91 Static Tests. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Expect('unknown', 'error:You tried to invoke the Report object with the ID 71999 from the object LT P91 Static Tests. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_Reports()
    begin
        Observer.Observe('nolayout', WordXmlPartOf(Report::"LT P91 NoLayout"));
        Observer.Observe('proconly', WordXmlPartOf(Report::"LT P91 ProcOnly"));
        Observer.Observe('zero', WordXmlPartOf(0));
        Observer.Observe('unknown', WordXmlPartOf(71999));
        Observer.Expect('nolayout', 'len>0=Yes');
        Observer.Expect('proconly', 'len>0=Yes');
        Observer.Expect('zero', 'error:You tried to invoke the Report object with the ID 0 from the object LT P91 Static Tests. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Expect('unknown', 'error:You tried to invoke the Report object with the ID 71999 from the object LT P91 Static Tests. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Verify();
    end;
}
