// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: shared table 72313, page 72379, pageextension 72380, codeunit 72381
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

page 72379 "LT P123 Locked Base"
{
    PageType = Card;
    SourceTable = "LT P123 PRow";
    ApplicationArea = All;
    Caption = 'P123 locked base';

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }
}

pageextension 72380 "LT P123 Locked Ext" extends "LT P123 Locked Base"
{
    layout
    {
        addlast(Content)
        {
            field(ExtName; Rec.Name)
            {
                ApplicationArea = All;
                Caption = 'Ext name locked', Locked = true;
            }
        }
    }
}

codeunit 72381 "LT P123 Locked Ext Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P123_LockedCaptionInExtension()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P123 PRow";
        P: TestPage "LT P123 Locked Base";
    begin
        R.DeleteAll();
        R.Init(); R.Id := 1; R.Name := 'One'; R.Insert();
        P.OpenView();
        Observer.Observe('ext caption', P.ExtName.Caption());
        Observer.Observe('ext value', P.ExtName.Value());
        Observer.Expect('ext caption', 'Ext name locked');
        Observer.Expect('ext value', 'One');
        Observer.Verify();
    end;
}
