// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-request-page
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: tables and helper of P105Fix.al; SingleInstance log 72242 is used only by test codeunit 72244; RISKY: Close inside the request page
// Facts: RequestPage.Close called from a field OnValidate (the handler triggers it with SetValue and then leaves without touching the page again)

codeunit 72242 "LT P105 RpCloseLog"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

report 72243 "LT P105 RpClose"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "LT P105 Row")
        {
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(IntCtl; IntVal)
                {
                    ApplicationArea = All;
                    Caption = 'Integer Control';

                    trigger OnValidate()
                    begin
                        L.Add('validate ' + Format(IntVal));
                        RequestOptionsPage.Close();
                        L.Add('after close');
                    end;
                }
            }
        }
    }

    trigger OnPreReport()
    begin
        L.Add('pre');
    end;

    var
        IntVal: Integer;
        L: Codeunit "LT P105 RpCloseLog";
}

codeunit 72244 "LT P105 RpClose Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT P105 RpCloseLog";
        Helper: Codeunit "LT P105 Helper";

    [Test]
    [HandlerFunctions('CloseHandler')]
    procedure P105_RequestPage_Close()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        L.Take();
        asserterror Report.Run(Report::"LT P105 RpClose");
        Observer.ObserveError('af90');
        Observer.Observe('log', L.Take());
        Observer.Expect('af90|text', 'Server page is not open.');
        Observer.Expect('af90|code', 'ClientPageAbort:FormAbort');
        Observer.Expect('log', 'validate 1;after close;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure CloseHandler(var RP: TestRequestPage "LT P105 RpClose")
    begin
        RP.IntCtl.SetValue(1);
    end;
}
