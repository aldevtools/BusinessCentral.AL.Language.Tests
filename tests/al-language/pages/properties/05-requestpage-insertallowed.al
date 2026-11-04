// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al (own tables, Log and Helper codeunits)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

report 72128 "LT P121 RP InsertAllowed"
{
    ProcessingOnly = true;
    UseRequestPage = true;

    dataset
    {
        dataitem(Row; "LT P121 Row")
        {
        }
    }

    requestpage
    {
        InsertAllowed = false;

        layout
        {
            area(Content)
            {
                field(Fld; FldVar)
                {
                    ApplicationArea = All;

                }
            }
        }
    }

    var
        FldVar: Integer;
}

codeunit 72129 "LT P121 RP InsertAllowed Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    [HandlerFunctions('RequestHandler')]
    procedure P121_RequestPage()
    var
        Helper: Codeunit "LT P121 Helper";
    begin
        Helper.Seed();
        Commit();
        Report.Run(Report::"LT P121 RP InsertAllowed");
        Observer.Expect('caption', 'Fld');
        Observer.Expect('value', '3');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure RequestHandler(var RP: TestRequestPage "LT P121 RP InsertAllowed")
    begin
        Observer.Observe('caption', RP.Fld.Caption());
        RP.Fld.SetValue(3);
        Observer.Observe('value', RP.Fld.Value());
        RP.OK().Invoke();
    end;
}
