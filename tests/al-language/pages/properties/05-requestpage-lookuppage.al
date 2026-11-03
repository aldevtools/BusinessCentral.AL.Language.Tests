// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al (own tables, Log and Helper codeunits)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

page 72132 "LT P121 Lookup Page"
{
    PageType = List;
    SourceTable = "LT P121 Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Txt; Rec.Txt) { ApplicationArea = All; }
            }
        }
    }
}

report 72133 "LT P121 RP LookupPage"
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

        layout
        {
            area(Content)
            {
                field(Fld; FldVar)
                {
                    ApplicationArea = All;
                    Lookup = true;
                    LookupPageID = "LT P121 Lookup Page";
                }
            }
        }
    }

    var
        FldVar: Code[20];
}

codeunit 72134 "LT P121 RP LookupPage Test"
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
        Report.Run(Report::"LT P121 RP LookupPage");
        Observer.Expect('caption', 'Fld');
        Observer.Expect('value', 'AB1');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure RequestHandler(var RP: TestRequestPage "LT P121 RP LookupPage")
    begin
        Observer.Observe('caption', RP.Fld.Caption());
        RP.Fld.SetValue('ab1');
        Observer.Observe('value', RP.Fld.Value());
        RP.OK().Invoke();
    end;
}
