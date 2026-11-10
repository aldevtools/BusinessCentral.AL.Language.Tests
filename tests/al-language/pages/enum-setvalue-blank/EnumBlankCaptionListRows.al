// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-setvalue-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own enums 62430 and 62431, tables 62430 and 62431, pages 62430 to 62432, test codeunit 62439
// local object: the enum whose value 0 has the caption ' ' and the list pages over it are the thing under test (standing rule 2)
// Probe: al-runner issue 7380 (TestPart Value('') on an Enum control whose member has a blank caption, on the new-row line of a ListPart).
// Area: a text or number typed into an Enum control whose value 0 has Caption = ' ' (Locked), on the ROWS OF A LIST.
//   Page shapes: a ListPart (AutoSplitKey, DelayedInsert) on a Card with SubPageLink, and a List page (neither property).
//   Positions: an existing row that holds Replace, an existing row that holds the blank value, the new-row line after Last() and Next(), the
//   new-row line after another control of the line was set first (the shape of the issue), a part or list with no rows, and New().
//   Inputs: Value('') , Value(' '), Value(Format(the blank member)), SetValue(''), SetValue(' '), SetValue(0) and SetValue(the blank member).
//   Per case, on a freshly opened page: the control's Value before, how far the case came (stage input: the input raised; close: Close
//   raised; done), the error text and code ('no error' when nothing raised), the control's Value after, and the stored rows after Close
//   (head/line number:check type ordinal/action type ordinal).
// Neighbours (not repeated here): BeEnumSetValueBlank.al pins the same inputs on a CARD (table field and page variable, Enum and Option,
//   Variant, Text and Integer arguments) and a NotBlank enum on a List; pages/values-allowed-table-field/Y65ValuesAllowedTableField.al pins
//   ValuesAllowed.
// Observe form: every test ends with Finish(), which reports the observed values.
// BC versions: 27, 28, 29 (corpus CI)

enum 62430 "ENB Action Type"
{
    Extensible = false;

    value(0; Empty) { Caption = ' ', Locked = true; }
    value(1; Replace) { Caption = 'Replace'; }
}

enum 62431 "ENB Check Type"
{
    Extensible = false;

    value(0; Exists) { Caption = 'Exists'; }
    value(1; Missing) { Caption = 'Missing'; }
}

table 62430 "ENB Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 62431 "ENB Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Head No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; "Check Type"; Enum "ENB Check Type") { }
        field(4; "Action Type"; Enum "ENB Action Type") { }
        field(5; Descr; Text[30]) { }
    }

    keys { key(PK; "Head No.", "Line No.") { Clustered = true; } }
}

page 62430 "ENB Line List"
{
    PageType = List;
    SourceTable = "ENB Line";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CheckType; Rec."Check Type") { ApplicationArea = All; }
                field(ActionType; Rec."Action Type") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

page 62431 "ENB Line Part"
{
    PageType = ListPart;
    SourceTable = "ENB Line";
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CheckType; Rec."Check Type") { ApplicationArea = All; }
                field(ActionType; Rec."Action Type") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

page 62432 "ENB Head Card"
{
    PageType = Card;
    SourceTable = "ENB Head";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "ENB Line Part")
            {
                ApplicationArea = All;
                SubPageLink = "Head No." = field("No.");
            }
        }
    }
}

codeunit 62439 "ENB Enum Blank List Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // One head H1. With lines: line 10000 holds Exists and Replace, line 20000 holds Exists and the blank value.
    local procedure Seed(WithLines: Boolean)
    var
        Head: Record "ENB Head";
        Line: Record "ENB Line";
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        Head."No." := 'H1';
        Head.Insert();
        if not WithLines then
            exit;
        Line."Head No." := 'H1';
        Line."Line No." := 10000;
        Line."Action Type" := Line."Action Type"::Replace;
        Line.Descr := 'one';
        Line.Insert();
        Line."Line No." := 20000;
        Line."Action Type" := Line."Action Type"::Empty;
        Line.Descr := 'two';
        Line.Insert();
    end;

    local procedure Stored(): Text
    var
        Line: Record "ENB Line";
        Result: Text;
    begin
        Result := Format(Line.Count()) + ' rows';
        if Line.FindSet() then
            repeat
                Result += ' ' + Line."Head No." + '/' + Format(Line."Line No.") + ':' + Format(Line."Check Type".AsInteger()) + '/' + Format(Line."Action Type".AsInteger());
            until Line.Next() = 0;
        exit(Result);
    end;

    local procedure InputName(Input: Integer): Text
    begin
        case Input of
            1:
                exit('Value empty text');
            2:
                exit('Value space');
            3:
                exit('Value Format of the blank member');
            4:
                exit('SetValue empty text');
            5:
                exit('SetValue space');
            6:
                exit('SetValue 0');
            7:
                exit('SetValue blank member');
        end;
    end;

    local procedure PartInput(var Host: TestPage "ENB Head Card"; Input: Integer)
    var
        TextInput: Text;
        NumberInput: Integer;
    begin
        case Input of
            1:
                begin
                    TextInput := '';
                    Host.Lines.ActionType.Value(TextInput);
                end;
            2:
                begin
                    TextInput := ' ';
                    Host.Lines.ActionType.Value(TextInput);
                end;
            3:
                Host.Lines.ActionType.Value(Format(Enum::"ENB Action Type"::Empty));
            4:
                begin
                    TextInput := '';
                    Host.Lines.ActionType.SetValue(TextInput);
                end;
            5:
                begin
                    TextInput := ' ';
                    Host.Lines.ActionType.SetValue(TextInput);
                end;
            6:
                begin
                    NumberInput := 0;
                    Host.Lines.ActionType.SetValue(NumberInput);
                end;
            7:
                Host.Lines.ActionType.SetValue(Enum::"ENB Action Type"::Empty);
        end;
    end;

    // Position: A existing row with Replace, B existing row with the blank value, C the new-row line, D the new-row line after Check Type
    // was set, E no rows, F New().
    // The input, the read of the value and the Close run inside one asserterror block that ends with the error 'no error', because the
    // containers refuse a write inside a TryFunction. Stage says how far the block came: input (the input raised), value, close (Close
    // raised) or done. The stored rows are read inside the block, before the asserterror rolls the test's writes back.
    local procedure PartCase(var Observer: Codeunit "Probe Observer"; Position: Text; Input: Integer)
    var
        Host: TestPage "ENB Head Card";
        Got: Text;
        Stage: Text;
        After: Text;
        StoredRows: Text;
    begin
        Seed(Position <> 'E');
        ClearLastError();
        Host.OpenEdit();
        case Position of
            'A':
                Host.Lines.First();
            'B':
                begin
                    Host.Lines.First();
                    Host.Lines.Next();
                end;
            'C', 'D':
                begin
                    Host.Lines.Last();
                    Host.Lines.Next();
                end;
            'F':
                Host.Lines.New();
        end;
        if Position = 'D' then
            Host.Lines.CheckType.Value(Format(Enum::"ENB Check Type"::Missing));
        if Position <> 'E' then
            Got := 'before=[' + Host.Lines.ActionType.Value() + '] ';
        Stage := 'input';
        asserterror begin
            PartInput(Host, Input);
            Stage := 'value';
            After := Host.Lines.ActionType.Value();
            Stage := 'close';
            Host.Close();
            Stage := 'done';
            StoredRows := Stored();
            Error('no error');
        end;
        Got += 'stage=' + Stage + ' error=' + GetLastErrorText() + ' {' + GetLastErrorCode() + '}';
        if Stage = 'input' then begin
            ClearLastError();
            asserterror begin
                After := Host.Lines.ActionType.Value();
                Error('no error');
            end;
            if GetLastErrorText() <> 'no error' then
                After := 'error: ' + GetLastErrorText();
        end;
        Got += ' after=[' + After + ']';
        if Stage = 'done' then
            Got += ' stored=' + StoredRows;
        ClearLastError();
        Observer.Observe(InputName(Input), Got);
    end;

    local procedure ListInput(var List: TestPage "ENB Line List"; Input: Integer)
    var
        TextInput: Text;
        NumberInput: Integer;
    begin
        case Input of
            1:
                begin
                    TextInput := '';
                    List.ActionType.Value(TextInput);
                end;
            2:
                begin
                    TextInput := ' ';
                    List.ActionType.Value(TextInput);
                end;
            3:
                List.ActionType.Value(Format(Enum::"ENB Action Type"::Empty));
            4:
                begin
                    TextInput := '';
                    List.ActionType.SetValue(TextInput);
                end;
            5:
                begin
                    TextInput := ' ';
                    List.ActionType.SetValue(TextInput);
                end;
            6:
                begin
                    NumberInput := 0;
                    List.ActionType.SetValue(NumberInput);
                end;
            7:
                List.ActionType.SetValue(Enum::"ENB Action Type"::Empty);
        end;
    end;

    // Position: A existing row with Replace, B existing row with the blank value, C the new-row line, D the new-row line after Check Type
    // was set, E no rows, F New().
    // The input, the read of the value and the Close run inside one asserterror block that ends with the error 'no error', because the
    // containers refuse a write inside a TryFunction. Stage says how far the block came: input (the input raised), value, close (Close
    // raised) or done. The stored rows are read inside the block, before the asserterror rolls the test's writes back.
    local procedure ListCase(var Observer: Codeunit "Probe Observer"; Position: Text; Input: Integer)
    var
        List: TestPage "ENB Line List";
        Got: Text;
        Stage: Text;
        After: Text;
        StoredRows: Text;
    begin
        Seed(Position <> 'E');
        ClearLastError();
        List.OpenEdit();
        case Position of
            'A':
                List.First();
            'B':
                begin
                    List.First();
                    List.Next();
                end;
            'C', 'D':
                begin
                    List.Last();
                    List.Next();
                end;
            'F':
                List.New();
        end;
        if Position = 'D' then
            List.CheckType.Value(Format(Enum::"ENB Check Type"::Missing));
        if Position <> 'E' then
            Got := 'before=[' + List.ActionType.Value() + '] ';
        Stage := 'input';
        asserterror begin
            ListInput(List, Input);
            Stage := 'value';
            After := List.ActionType.Value();
            Stage := 'close';
            List.Close();
            Stage := 'done';
            StoredRows := Stored();
            Error('no error');
        end;
        Got += 'stage=' + Stage + ' error=' + GetLastErrorText() + ' {' + GetLastErrorCode() + '}';
        if Stage = 'input' then begin
            ClearLastError();
            asserterror begin
                After := List.ActionType.Value();
                Error('no error');
            end;
            if GetLastErrorText() <> 'no error' then
                After := 'error: ' + GetLastErrorText();
        end;
        Got += ' after=[' + After + ']';
        if Stage = 'done' then
            Got += ' stored=' + StoredRows;
        ClearLastError();
        Observer.Observe(InputName(Input), Got);
    end;

    [Test]
    procedure EnumBlank_FormatOfTheBlankMember()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "ENB Line";
    begin
        Seed(false);
        Observer.Observe('Format of the member', '[' + Format(Enum::"ENB Action Type"::Empty) + ']');
        Line."Action Type" := Line."Action Type"::Empty;
        Observer.Observe('Format of the field', '[' + Format(Line."Action Type") + ']');
        Observer.Observe('StrLen of Format', Format(StrLen(Format(Line."Action Type"))));
        Observer.Finish();
    end;

    [Test]
    procedure EnumBlank_Part_ExistingRowWithReplace_Value()
    var
        Observer: Codeunit "Probe Observer";
        Input: Integer;
    begin
        for Input := 1 to 3 do
            PartCase(Observer, 'A', Input);
        Observer.Finish();
    end;

    [Test]
    procedure EnumBlank_Part_ExistingRowWithReplace_SetValue()
    var
        Observer: Codeunit "Probe Observer";
        Input: Integer;
    begin
        for Input := 4 to 7 do
            PartCase(Observer, 'A', Input);
        Observer.Finish();
    end;

    [Test]
    procedure EnumBlank_Part_ExistingRowWithBlank_Value()
    var
        Observer: Codeunit "Probe Observer";
        Input: Integer;
    begin
        for Input := 1 to 3 do
            PartCase(Observer, 'B', Input);
        Observer.Finish();
    end;

    [Test]
    procedure EnumBlank_Part_ExistingRowWithBlank_SetValue()
    var
        Observer: Codeunit "Probe Observer";
        Input: Integer;
    begin
        for Input := 4 to 7 do
            PartCase(Observer, 'B', Input);
        Observer.Finish();
    end;

    [Test]
    procedure EnumBlank_Part_NewRowLine_Value()
    var
        Observer: Codeunit "Probe Observer";
        Input: Integer;
    begin
        for Input := 1 to 3 do
            PartCase(Observer, 'C', Input);
        Observer.Finish();
    end;

    [Test]
    procedure EnumBlank_Part_NewRowLine_SetValue()
    var
        Observer: Codeunit "Probe Observer";
        Input: Integer;
    begin
        for Input := 4 to 7 do
            PartCase(Observer, 'C', Input);
        Observer.Finish();
    end;

    [Test]
    procedure EnumBlank_Part_NewRowLineAfterOtherField_Value()
    var
        Observer: Codeunit "Probe Observer";
        Input: Integer;
    begin
        for Input := 1 to 3 do
            PartCase(Observer, 'D', Input);
        Observer.Finish();
    end;

    [Test]
    procedure EnumBlank_Part_NewRowLineAfterOtherField_SetValue()
    var
        Observer: Codeunit "Probe Observer";
        Input: Integer;
    begin
        for Input := 4 to 7 do
            PartCase(Observer, 'D', Input);
        Observer.Finish();
    end;

    [Test]
    procedure EnumBlank_Part_NoRows_Value()
    var
        Observer: Codeunit "Probe Observer";
        Input: Integer;
    begin
        for Input := 1 to 3 do
            PartCase(Observer, 'E', Input);
        Observer.Finish();
    end;

    [Test]
    procedure EnumBlank_Part_NoRows_SetValue()
    var
        Observer: Codeunit "Probe Observer";
        Input: Integer;
    begin
        for Input := 4 to 7 do
            PartCase(Observer, 'E', Input);
        Observer.Finish();
    end;

    [Test]
    procedure EnumBlank_Part_New_Value()
    var
        Observer: Codeunit "Probe Observer";
        Input: Integer;
    begin
        for Input := 1 to 3 do
            PartCase(Observer, 'F', Input);
        Observer.Finish();
    end;

    [Test]
    procedure EnumBlank_Part_New_SetValue()
    var
        Observer: Codeunit "Probe Observer";
        Input: Integer;
    begin
        for Input := 4 to 7 do
            PartCase(Observer, 'F', Input);
        Observer.Finish();
    end;

    [Test]
    procedure EnumBlank_List_ExistingRowWithReplace_Value()
    var
        Observer: Codeunit "Probe Observer";
        Input: Integer;
    begin
        for Input := 1 to 3 do
            ListCase(Observer, 'A', Input);
        Observer.Finish();
    end;

    [Test]
    procedure EnumBlank_List_ExistingRowWithReplace_SetValue()
    var
        Observer: Codeunit "Probe Observer";
        Input: Integer;
    begin
        for Input := 4 to 7 do
            ListCase(Observer, 'A', Input);
        Observer.Finish();
    end;

    [Test]
    procedure EnumBlank_List_ExistingRowWithBlank_Value()
    var
        Observer: Codeunit "Probe Observer";
        Input: Integer;
    begin
        for Input := 1 to 3 do
            ListCase(Observer, 'B', Input);
        Observer.Finish();
    end;

    [Test]
    procedure EnumBlank_List_ExistingRowWithBlank_SetValue()
    var
        Observer: Codeunit "Probe Observer";
        Input: Integer;
    begin
        for Input := 4 to 7 do
            ListCase(Observer, 'B', Input);
        Observer.Finish();
    end;

    [Test]
    procedure EnumBlank_List_NewRowLine_Value()
    var
        Observer: Codeunit "Probe Observer";
        Input: Integer;
    begin
        for Input := 1 to 3 do
            ListCase(Observer, 'C', Input);
        Observer.Finish();
    end;

    [Test]
    procedure EnumBlank_List_NewRowLine_SetValue()
    var
        Observer: Codeunit "Probe Observer";
        Input: Integer;
    begin
        for Input := 4 to 7 do
            ListCase(Observer, 'C', Input);
        Observer.Finish();
    end;

    [Test]
    procedure EnumBlank_List_NewRowLineAfterOtherField_Value()
    var
        Observer: Codeunit "Probe Observer";
        Input: Integer;
    begin
        for Input := 1 to 3 do
            ListCase(Observer, 'D', Input);
        Observer.Finish();
    end;

    [Test]
    procedure EnumBlank_List_NewRowLineAfterOtherField_SetValue()
    var
        Observer: Codeunit "Probe Observer";
        Input: Integer;
    begin
        for Input := 4 to 7 do
            ListCase(Observer, 'D', Input);
        Observer.Finish();
    end;

    [Test]
    procedure EnumBlank_List_NoRows_Value()
    var
        Observer: Codeunit "Probe Observer";
        Input: Integer;
    begin
        for Input := 1 to 3 do
            ListCase(Observer, 'E', Input);
        Observer.Finish();
    end;

    [Test]
    procedure EnumBlank_List_NoRows_SetValue()
    var
        Observer: Codeunit "Probe Observer";
        Input: Integer;
    begin
        for Input := 4 to 7 do
            ListCase(Observer, 'E', Input);
        Observer.Finish();
    end;

    [Test]
    procedure EnumBlank_List_New_Value()
    var
        Observer: Codeunit "Probe Observer";
        Input: Integer;
    begin
        for Input := 1 to 3 do
            ListCase(Observer, 'F', Input);
        Observer.Finish();
    end;

    [Test]
    procedure EnumBlank_List_New_SetValue()
    var
        Observer: Codeunit "Probe Observer";
        Input: Integer;
    begin
        for Input := 4 to 7 do
            ListCase(Observer, 'F', Input);
        Observer.Finish();
    end;
}
