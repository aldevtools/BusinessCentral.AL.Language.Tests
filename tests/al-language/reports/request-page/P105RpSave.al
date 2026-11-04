// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-request-page
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: tables and helper of P105Fix.al; SingleInstance log 72245 is used only by test codeunit 72247; RISKY: SaveRecord on a request page without a source table
// Facts: RequestPage.SaveRecord called from a field OnValidate that the handler triggers with SetValue

codeunit 72245 "LT P105 RpSaveLog"
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

report 72246 "LT P105 RpSave"
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
                        RequestOptionsPage.SaveRecord();
                        L.Add('after save');
                    end;
                }
            }
        }
    }

    trigger OnPreReport()
    begin
        L.Add('pre int=' + Format(IntVal));
    end;

    var
        IntVal: Integer;
        L: Codeunit "LT P105 RpSaveLog";
}

codeunit 72247 "LT P105 RpSave Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT P105 RpSaveLog";
        Helper: Codeunit "LT P105 Helper";

    [Test]
    [HandlerFunctions('SaveHandler')]
    procedure P105_RequestPage_SaveRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        L.Take();
        Report.Run(Report::"LT P105 RpSave");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'validate 1;after save;pre int=1;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure SaveHandler(var RP: TestRequestPage "LT P105 RpSave")
    begin
        RP.IntCtl.SetValue(1);
        RP.OK().Invoke();
    end;
}
