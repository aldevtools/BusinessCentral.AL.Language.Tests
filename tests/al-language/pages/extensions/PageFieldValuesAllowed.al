// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: own enum 72337, table 72338, page 72339, codeunit 72340
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

enum 72337 "LT P123 PKind"
{
    Extensible = false;
    value(0; Open) { }
    value(1; Released) { }
    value(2; Closed) { }
}

table 72338 "LT P123 PVA"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "LT P123 PKind") { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 72339 "LT P123 VA Card"
{
    PageType = Card;
    SourceTable = "LT P123 PVA";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Kind; Rec.Kind) { ApplicationArea = All; ValuesAllowed = Open, Released; }
        }
    }
}

codeunit 72340 "LT P123 PValuesAllowed Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P123_PageFieldValuesAllowed()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT P123 PVA";
        P: TestPage "LT P123 VA Card";
    begin
        T.DeleteAll();
        T.Init(); T.Id := 1; T.Insert();
        P.OpenEdit();
        Observer.Observe('initial', P.Kind.Value());
        P.Kind.SetValue('Released');
        Observer.Observe('allowed', P.Kind.Value());
        asserterror P.Kind.SetValue('Closed');
        Observer.ObserveError('disallowed');
        Observer.Observe('after disallowed', P.Kind.Value());
        Observer.Observe('options', P.Kind.GetOption(1));
        Observer.Expect('initial', 'Open');
        Observer.Expect('allowed', 'Released');
        Observer.Expect('disallowed|text', 'Validation error for Field: Kind,  Message = ''Your entry of ''Closed'' is not an acceptable value for ''Kind''. (Select Refresh to discard errors)''');
        Observer.Expect('disallowed|code', 'TestValidation');
        Observer.Expect('after disallowed', '1');
        Observer.Expect('options', 'Open');
        Observer.Verify();
    end;
}
