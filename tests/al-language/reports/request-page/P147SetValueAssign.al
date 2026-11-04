// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-setvalue-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 70255, page 70256, test codeunit 70257 (log is a SingleInstance codeunit 70258 declared above its single user)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// If it compiles, observe whether the value is set and whether the field's OnValidate ran. The method-call form is in P147SetValueCall.al for comparison.
// BC versions: 29 (27 and 28 by CI)

table 70255 "LT P147 SetValue Row"
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

codeunit 70258 "LT P147 SetValue Log"
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

page 70256 "LT P147 SetValue Card"
{
    PageType = Card;
    SourceTable = "LT P147 SetValue Row";
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
                    Log: Codeunit "LT P147 SetValue Log";
                begin
                    Log.Add('OnValidate ' + Format(Rec.Amount));
                end;
            }
        }
    }
}

codeunit 70257 "LT P147 SetValue Assign"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P147_SetValue_AssignmentForm()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P147 SetValue Log";
        Row: Record "LT P147 SetValue Row";
        Card: TestPage "LT P147 SetValue Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Log.Clear();
        Card.OpenEdit();
        Card.Amount.SetValue := 42;
        Observer.Observe('value after assignment form', Card.Amount.Value());
        Observer.Observe('log', Log.Get());
        Card.Close();
        Observer.Expect('value after assignment form', '42');
        Observer.Expect('log', 'OnValidate 42;');
        Observer.Verify();
    end;
}
