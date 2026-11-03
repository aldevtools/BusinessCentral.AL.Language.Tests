// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT P119 Row" (71625, P119Table.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: a grid with GridLayout and ShowCaption = false added by a page extension (page 71648 in P119Grid.al); the field inside the grid is observed.

pageextension 71650 "LT P119 Grid Ext" extends "LT P119 Grid Card"
{
    layout
    {
        addlast(Content)
        {
            grid(ExtGrid)
            {
                GridLayout = Columns;
                ShowCaption = false;
                group(ExtCol)
                {
                    ShowCaption = false;
                    field(ExtMail; Rec.Mail) { ApplicationArea = All; }
                }
            }
        }
    }
}

codeunit 71651 "LT P119 GridExt Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P119_GridExtensionField()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Grid Card";
        Row: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Mail := 'a@b.example';
        Row.Insert();
        TP.OpenEdit();
        Observer.Observe('extmail-visible', Format(TP.ExtMail.Visible()));
        Observer.Observe('extmail-value', TP.ExtMail.Value());
        Observer.Observe('extmail-caption', TP.ExtMail.Caption());
        TP.Close();
        Observer.Expect('extmail-visible', 'Yes');
        Observer.Expect('extmail-value', 'a@b.example');
        Observer.Expect('extmail-caption', 'Mail');
        Observer.Verify();
    end;
}
