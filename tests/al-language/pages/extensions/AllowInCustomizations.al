// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: own table 72279, page 72280, codeunit 72281
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 72279 "LT P123 AIC"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; FAlways; Text[30]) { AllowInCustomizations = Always; }
        field(3; FNever; Text[30]) { AllowInCustomizations = Never; }
        field(4; FReadOnly; Text[30]) { AllowInCustomizations = AsReadOnly; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 72280 "LT P123 AIC Page"
{
    PageType = Card;
    SourceTable = "LT P123 AIC";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(FAlways; Rec.FAlways) { ApplicationArea = All; }
            field(FNever; Rec.FNever) { ApplicationArea = All; }
            field(FReadOnly; Rec.FReadOnly) { ApplicationArea = All; }
        }
    }
}

codeunit 72281 "LT P123 AIC Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P123_AllowInCustomizationsDeclared()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT P123 AIC";
        P: TestPage "LT P123 AIC Page";
    begin
        T.DeleteAll();
        T.Init(); T.Id := 1; T.FAlways := 'a'; T.FNever := 'n'; T.FReadOnly := 'r'; T.Insert();
        P.OpenEdit();
        Observer.Observe('always', P.FAlways.Value());
        Observer.Observe('never', P.FNever.Value());
        Observer.Observe('readonly', P.FReadOnly.Value());
        Observer.Observe('always editable', Format(P.FAlways.Editable()));
        Observer.Observe('never editable', Format(P.FNever.Editable()));
        Observer.Observe('readonly editable', Format(P.FReadOnly.Editable()));
        P.FNever.SetValue('changed');
        P.Close();
        T.Get(1);
        Observer.Observe('never after set', T.FNever);
        Observer.Expect('always', 'a');
        Observer.Expect('never', 'n');
        Observer.Expect('readonly', 'r');
        Observer.Expect('always editable', 'Yes');
        Observer.Expect('never editable', 'Yes');
        Observer.Expect('readonly editable', 'Yes');
        Observer.Expect('never after set', 'changed');
        Observer.Verify();
    end;
}
