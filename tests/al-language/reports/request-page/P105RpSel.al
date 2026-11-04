// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-request-page
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: tables and helper of P105Fix.al; SingleInstance log 72248 is used only by test codeunit 72250; RISKY: SetSelectionFilter on a request page without a source table
// Facts: RequestPage.SetSelectionFilter with a Row record variable from a field OnValidate that the handler triggers with SetValue

codeunit 72248 "LT P105 RpSelLog"
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

report 72249 "LT P105 RpSel"
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
                    var
                        Sel: Record "LT P105 Row";
                    begin
                        Sel.SetRange(Grp, 2);
                        RequestOptionsPage.SetSelectionFilter(Sel);
                        L.Add('count=' + Format(Sel.Count()) + ' filters=[' + Sel.GetFilters() + ']');
                    end;
                }
            }
        }
    }

    var
        IntVal: Integer;
        L: Codeunit "LT P105 RpSelLog";
}

codeunit 72250 "LT P105 RpSel Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT P105 RpSelLog";
        Helper: Codeunit "LT P105 Helper";

    [Test]
    [HandlerFunctions('SelHandler')]
    procedure P105_RequestPage_SetSelectionFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        L.Take();
        Report.Run(Report::"LT P105 RpSel");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'count=2 filters=[Grp: 2];');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure SelHandler(var RP: TestRequestPage "LT P105 RpSel")
    begin
        RP.IntCtl.SetValue(1);
        RP.Cancel().Invoke();
    end;
}
