// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT P119 Row" (71625, P119Table.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: report column property OptionCaption on a data item column. A column is no TestRequestPage member: declared only, not observable; the report runs with a request page that is cancelled
// (the handler observes a request page field). RISKY: OptionCaption on a column may not compile.

report 71685 "LT P119 Rep Column"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Rows; "LT P119 Row")
        {
            column(IdCol; Id) { }
            column(OptCol; Opt)
            {
                OptionCaption = 'Alpha,Beta,Gamma';
            }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(TxtCtl; TxtVar)
                {
                    ApplicationArea = All;
                    Caption = 'Txt Ctl';
                }
            }
        }
    }

    var
        TxtVar: Text[30];
}

codeunit 71686 "LT P119 RepColumn Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Facts: List of [Text];

    [Test]
    [HandlerFunctions('ColumnHandler')]
    procedure P119_ReportWithOptionColumn()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Opt := Row.Opt::Second;
        Row.Insert();
        Commit();
        Clear(Facts);
        Report.Run(Report::"LT P119 Rep Column");
        Observer.Observe('txt-visible', Facts.Get(1));
        Observer.Observe('txt-caption', Facts.Get(2));
        Observer.Expect('txt-visible', 'Yes');
        Observer.Expect('txt-caption', 'Txt Ctl');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure ColumnHandler(var RP: TestRequestPage "LT P119 Rep Column")
    begin
        Facts.Add(Format(RP.TxtCtl.Visible()));
        Facts.Add(RP.TxtCtl.Caption());
        RP.Cancel().Invoke();
    end;
}
