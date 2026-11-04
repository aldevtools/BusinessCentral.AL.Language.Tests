// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-editable-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT AB Row" (77000), ABGroupFixtures.al
// Probe: written against a BC service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 27 to 29 (CI matrix)
// Facts: CuegroupLayout = Wide (also in lower case) on a cue group and GridLayout = Rows and Columns on a grid compile and the fields inside stay readable from a TestPage.
// Other CuegroupLayout and GridLayout values and the same properties on the other container kinds are refused: must-not-compile 0921, 0926 to 0928, 0931, 0933, 0939, 0944.

page 77040 "LT AB Layout Card"
{
    PageType = Card;
    SourceTable = "LT AB Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            cuegroup(CgWide)
            {
                CuegroupLayout = Wide;
                field(CgWideF; Rec.Name) { ApplicationArea = All; }
            }
            cuegroup(CgWideLower)
            {
                CuegroupLayout = wide;
                field(CgWideLowerF; Rec.Name) { ApplicationArea = All; }
            }
            grid(GrRows)
            {
                GridLayout = Rows;
                field(GrRowsF; Rec.Name) { ApplicationArea = All; }
            }
            grid(GrColumns)
            {
                GridLayout = Columns;
                field(GrColumnsF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 77041 "LT AB Layout Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure LayoutValuesCompileAndFieldsRead()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AB Row";
        Card: TestPage "LT AB Layout Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'Layout';
        Row.Insert();
        Card.OpenView();
        Observer.Observe('wide-value', Card.CgWideF.Value());
        Observer.Observe('wide-visible', Format(Card.CgWideF.Visible()));
        Observer.Observe('wide-lower-value', Card.CgWideLowerF.Value());
        Observer.Observe('rows-value', Card.GrRowsF.Value());
        Observer.Observe('rows-visible', Format(Card.GrRowsF.Visible()));
        Observer.Observe('columns-value', Card.GrColumnsF.Value());
        Observer.Observe('columns-visible', Format(Card.GrColumnsF.Visible()));
        Card.Close();
        Observer.Expect('wide-value', '0');
        Observer.Expect('wide-visible', 'Yes');
        Observer.Expect('wide-lower-value', '0');
        Observer.Expect('rows-value', 'Layout');
        Observer.Expect('rows-visible', 'Yes');
        Observer.Expect('columns-value', 'Layout');
        Observer.Expect('columns-visible', 'Yes');
        Observer.Verify();
    end;
}
