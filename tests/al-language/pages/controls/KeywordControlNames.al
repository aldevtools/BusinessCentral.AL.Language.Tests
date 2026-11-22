// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-object
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 75610, page 75611, enum 75612, test codeunit 75613
// Probe (al-runner issue 8634): the names of page controls and enum values that are words of the AL language.
// Facts:
//   - Page field controls named If, Exit, Local and Keys, unquoted, compile, and a TestPage reads each through its quoted member
//     (Card."If"): the values of the row the page shows. The quoted control names "Key" and "Area" compile and read the same way.
//   - The quoted enum value names "Key" and "Area" compile; Format gives the name and AsInteger the ordinal.
//   - Not compiling (must-not-compile 3340 to 3408): the name of a page control, action, group, part, view, enum value, report or
//     query column or data item, query filter, xmlport element or attribute, request page field, table key or field group, in the
//     object or its extension, that is one of 24 words (Actions, Area, Begin, ChartPart, CueGroup, End, Event, Extends, False,
//     FieldAttribute, FieldElement, FieldGroups, Key, Of, PageExtension, Procedure, ProfileExtension, TableElement, TableExtension,
//     TextAttribute, TextElement, Trigger, True, Var), unquoted, with AL0107 at the name first.
// local object: the control and value names are under test.
// BC versions: 27, 28, 29 (by the corpus CI matrix)

table 75610 "PGC Keyword Control Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Amount; Integer) { }
        field(3; Quantity; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 75611 "PGC Keyword Control Card"
{
    PageType = Card;
    SourceTable = "PGC Keyword Control Row";

    layout
    {
        area(Content)
        {
            field(If; Rec.Amount) { ApplicationArea = All; }
            field(Exit; Rec.Quantity) { ApplicationArea = All; }
            field(Local; Rec.Id) { ApplicationArea = All; }
            field(Keys; Rec.Amount) { ApplicationArea = All; }
            field("Key"; Rec.Quantity) { ApplicationArea = All; }
            field("Area"; Rec.Id) { ApplicationArea = All; }
        }
    }
}

enum 75612 "PGC Keyword Value"
{
    value(0; "Key") { }
    value(1; "Area") { }
}

codeunit 75613 "PGC Keyword Control Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure KeywordControlNames_TestPage_ControlsReadRowValues()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PGC Keyword Control Row";
        Card: TestPage "PGC Keyword Control Card";
    begin
        Initialize();
        Row.Id := 1;
        Row.Amount := 7;
        Row.Quantity := 9;
        Row.Insert();
        Card.OpenView();
        Card.GoToRecord(Row);
        Observer.Observe('If', Card."If".Value);
        Observer.Observe('Exit', Card."Exit".Value);
        Observer.Observe('Local', Card."Local".Value);
        Observer.Observe('Keys', Card."Keys".Value);
        Observer.Observe('Key', Card."Key".Value);
        Observer.Observe('Area', Card."Area".Value);
        Card.Close();
        Observer.Expect('If', '7');
        Observer.Expect('Exit', '9');
        Observer.Expect('Local', '1');
        Observer.Expect('Keys', '7');
        Observer.Expect('Key', '9');
        Observer.Expect('Area', '1');
        Observer.Verify();
    end;

    [Test]
    procedure KeywordControlNames_Enum_QuotedValueNames()
    var
        Observer: Codeunit "Probe Observer";
        Value: Enum "PGC Keyword Value";
    begin
        Initialize();
        Value := Value::"Key";
        Observer.Observe('Key', Format(Value));
        Observer.Observe('Key ordinal', Format(Value.AsInteger()));
        Value := Value::"Area";
        Observer.Observe('Area', Format(Value));
        Observer.Observe('Area ordinal', Format(Value.AsInteger()));
        Observer.Expect('Key', 'Key');
        Observer.Expect('Key ordinal', '0');
        Observer.Expect('Area', 'Area');
        Observer.Expect('Area ordinal', '1');
        Observer.Verify();
    end;

    local procedure Initialize()
    var
        Row: Record "PGC Keyword Control Row";
    begin
        Row.DeleteAll();
    end;
}
