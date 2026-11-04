// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al (own tables, Log and Helper codeunits)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

report 72122 "LT P121 RP CaptionClass"
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
                    CaptionClass = '3,P121 dynamic caption';
                }
            }
        }
    }

    var
        FldVar: Text[30];
}

codeunit 72123 "LT P121 RP CaptionClass Test"
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
        Report.Run(Report::"LT P121 RP CaptionClass");
        Observer.Expect('caption', 'P121 dynamic caption');
        Observer.Expect('value', '');
        Observer.Expect('value_after_set', 'abc');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure RequestHandler(var RP: TestRequestPage "LT P121 RP CaptionClass")
    begin
        Observer.Observe('caption', RP.Fld.Caption());
        Observer.Observe('value', RP.Fld.Value());
        RP.Fld.SetValue('abc');
        Observer.Observe('value_after_set', RP.Fld.Value());
        RP.OK().Invoke();
    end;
}
