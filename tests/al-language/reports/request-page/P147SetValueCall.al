// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-setvalue-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 70259, page 70260, test codeunit 70261, log codeunit 70262
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 70259 "LT P147 SetValue Row2"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Amount; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 70262 "LT P147 SetValue Log2"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Clear()
    begin
        Entries := '';
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Get(): Text
    begin
        exit(Entries);
    end;
}

page 70260 "LT P147 SetValue Card2"
{
    PageType = Card;
    SourceTable = "LT P147 SetValue Row2";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Amount; Rec.Amount)
            {
                ApplicationArea = All;

                trigger OnValidate()
                var
                    Log: Codeunit "LT P147 SetValue Log2";
                begin
                    Log.Add('OnValidate ' + Format(Rec.Amount));
                end;
            }
        }
    }
}

codeunit 70261 "LT P147 SetValue Call"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P147_SetValue_CallForm()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P147 SetValue Log2";
        Row: Record "LT P147 SetValue Row2";
        Card: TestPage "LT P147 SetValue Card2";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Log.Clear();
        Card.OpenEdit();
        Card.Amount.SetValue(42);
        Observer.Observe('value after call form', Card.Amount.Value());
        Observer.Observe('log', Log.Get());
        Card.Close();
        Observer.Expect('value after call form', '42');
        Observer.Expect('log', 'OnValidate 42;');
        Observer.Verify();
    end;
}
