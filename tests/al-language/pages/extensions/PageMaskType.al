// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: shared table 72313, page 72333, codeunit 72334
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

page 72333 "LT P123 Mask List"
{
    PageType = List;
    SourceTable = "LT P123 PRow";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Secret; Rec.Secret) { ApplicationArea = All; MaskType = Concealed; }
                field(Name; Rec.Name) { ApplicationArea = All; MaskType = None; }
            }
        }
    }
}

codeunit 72334 "LT P123 Mask Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P123_MaskTypeValues()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P123 PRow";
        P: TestPage "LT P123 Mask List";
    begin
        R.DeleteAll();
        R.Init(); R.Id := 1; R.Name := 'One'; R.Secret := 'topsecret'; R.Insert();
        P.OpenEdit();
        P.First();
        Observer.Observe('secret value', P.Secret.Value());
        Observer.Observe('name value', P.Name.Value());
        Observer.Observe('secret editable', Format(P.Secret.Editable()));
        P.Secret.SetValue('changed');
        Observer.Observe('secret after set', P.Secret.Value());
        P.Close();
        R.Get(1);
        Observer.Observe('stored secret', R.Secret);
        Observer.Expect('secret value', 'topsecret');
        Observer.Expect('name value', 'One');
        Observer.Expect('secret editable', 'Yes');
        Observer.Expect('secret after set', 'changed');
        Observer.Expect('stored secret', 'changed');
        Observer.Verify();
    end;
}
