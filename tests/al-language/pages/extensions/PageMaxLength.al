// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: shared table 72313, page 72320, codeunit 72321
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

page 72320 "LT P123 MaxLen List"
{
    PageType = List;
    SourceTable = "LT P123 PRow";
    ApplicationArea = All;
    Caption = 'P123 max length list', MaxLength = 40;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 72321 "LT P123 MaxLen Page Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT P123 PRow";
    begin
        R.DeleteAll();
        R.Init(); R.Id := 1; R.Name := 'One'; R.Amount := 5; R.Secret := 's1'; R.Insert();
        R.Init(); R.Id := 2; R.Name := 'Two'; R.Amount := 15; R.Secret := 's2'; R.Insert();
        R.Init(); R.Id := 3; R.Name := 'Three'; R.Amount := 25; R.Secret := 's3'; R.Insert();
    end;

    [Test]
    procedure P123_PageMaxLength()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT P123 MaxLen List";
        Names: Text;
        Count: Integer;
    begin
        Seed();
        P.OpenView();
        Observer.Observe('caption', P.Caption());
        if P.First() then
            repeat
                Count += 1;
                Names += P.Name.Value() + ',';
            until not P.Next();
        Observer.Observe('rows', Format(Count));
        Observer.Observe('names', Names);
        Observer.Observe('name editable', Format(P.Name.Editable()));
        Observer.Observe('name visible', Format(P.Name.Visible()));
        Observer.Expect('caption', 'P123 max length list');
        Observer.Expect('rows', '3');
        Observer.Expect('names', 'One,Two,Three,');
        Observer.Expect('name editable', 'No');
        Observer.Expect('name visible', 'Yes');
        Observer.Verify();
    end;
}
