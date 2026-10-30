// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-execute-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects 90730-90733
// Probe: written against al-runner issue 6306 (Report.Execute with a request page parameters XML); every value asserted below is what the BC service tier produced.
// Facts: Execute(Parameters) with <Options><Field name=...> values for a Text, Boolean and Integer control reaches the request page field before OnPreReport;
//        an unknown field name; an empty Execute(''); a parameters text that is not XML.
// BC versions: 27, 28, 29

report 90730 "LT WD Execute Params"
{
    ProcessingOnly = true;
    UseRequestPage = true;

    dataset
    {
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(NewName; NewName) { ApplicationArea = All; }
                field(Flag; Flag) { ApplicationArea = All; }
                field(Number; Number) { ApplicationArea = All; }
            }
        }
    }

    trigger OnPreReport()
    begin
        Result := 'name=' + NewName + ';flag=' + Format(Flag) + ';number=' + Format(Number);
    end;

    procedure GetResult(): Text
    begin
        exit(Result);
    end;

    var
        NewName: Text[50];
        Flag: Boolean;
        Number: Integer;
        Result: Text;
}

codeunit 90733 "LT WD Report Execute Params"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Params(Fields: Text): Text
    begin
        exit('<?xml version="1.0" standalone="yes"?><ReportParameters name="LT WD Execute Params" id="90730"><Options>' + Fields + '</Options></ReportParameters>');
    end;

    [Test]
    procedure WD_ReportExecute_OptionsFields()
    var
        Observer: Codeunit "Probe Observer";
        R: Report "LT WD Execute Params";
    begin
        R.Execute(Params('<Field name="NewName">Second</Field>'));
        Observer.Observe('text only', R.GetResult());
        Clear(R);
        R.Execute(Params('<Field name="NewName">Third</Field><Field name="Flag">true</Field><Field name="Number">42</Field>'));
        Observer.Observe('text, boolean, integer', R.GetResult());
        Clear(R);
        R.Execute('');
        Observer.Observe('empty parameters', R.GetResult());
        Observer.Finish();
    end;

    [Test]
    procedure WD_ReportExecute_OddParameters()
    var
        Observer: Codeunit "Probe Observer";
        R: Report "LT WD Execute Params";
    begin
        R.Execute(Params('<Field name="NoSuchField">x</Field><Field name="NewName">Kept</Field>'));
        Observer.Observe('unknown field name', R.GetResult());
        Clear(R);
        asserterror R.Execute('not xml');
        Observer.ObserveError('not xml');
        Clear(R);
        R.Execute(Params('<Field name="Number">oops</Field>'));
        Observer.Observe('integer field with text', R.GetResult());
        Observer.Finish();
    end;
}
