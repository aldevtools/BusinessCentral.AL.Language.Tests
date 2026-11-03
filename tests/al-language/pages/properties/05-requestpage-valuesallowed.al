// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al (own tables, Log and Helper codeunits)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

report 72135 "LT P121 RP ValuesAllowed"
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
                    ValuesAllowed = 1, 2, 3;
                }
            }
        }
    }

    var
        FldVar: Integer;
}

codeunit 72136 "LT P121 RP ValuesAllowed Test"
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
        Report.Run(Report::"LT P121 RP ValuesAllowed");
        Observer.Expect('value_2', '2');
        Observer.Expect('set_5|text', 'Validation error for Field: Fld,  Message = ''Value ''5'' is not a valid value. The following values can be used: 1;2;3.''');
        Observer.Expect('set_5|code', 'TestValidation');
        Observer.Expect('value_after_5', '2');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure RequestHandler(var RP: TestRequestPage "LT P121 RP ValuesAllowed")
    begin
        RP.Fld.SetValue(2);
        Observer.Observe('value_2', RP.Fld.Value());
        asserterror RP.Fld.SetValue(5);
        Observer.ObserveError('set_5');
        Observer.Observe('value_after_5', RP.Fld.Value());
        RP.OK().Invoke();
    end;
}
