// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-setvalue-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own enums 75860 and 75861, tables 75860 and 75861, pages 75860 and 75861, test codeunit 75869
// local object: the enums whose value 0 has the caption ' ' and the ListPart over them are the thing under test (standing rule 2)
// Probe: al-runner issue 7380 (follow-up). The reporter's shape: an enum with THREE members whose value 0 has Caption = ' ' (Locked), on the
//   ListPart of a Card opened with OpenNew; the test moves the part to its new-row line (Last, Next) and types Format of the blank member.
// Area: a text typed into an Enum control whose value 0 has a blank caption, on the new-row line of a ListPart.
//   Enums: Action3 (Empty ' ', Replace, Append) and Action2 (Empty ' ', Replace), both fields on the same line.
//   Openings of the host Card: OpenNew then the header No. set to H1; OpenNew with no header field set; OpenEdit on head H1 with one line.
//   Positions: the new-row line after Last and Next; the same after Descr of the line was set first (the issue's order); the existing line
//   (OpenEdit only).
//   Inputs: Value(Format(the blank member)), Value(''), SetValue(''), SetValue(the blank member), and Value(Format(the last member)) for a
//   non-blank member of the same control.
//   Per case, on a freshly opened page: the control's Value before, how far it came (stage input: the input raised; close: Close raised;
//   done), the error text ('no error' when nothing raised) and, when something raised, its code, the control's Value after, and the stored heads and lines after Close
//   (head no. / line no.: Action3 ordinal / Action2 ordinal / Descr).
// Neighbours (not repeated here): EnumBlankCaptionListRows.al (a two-member enum on a List and on the ListPart of a Card opened with OpenEdit),
//   BeEnumSetValueBlank.al (the same inputs on a Card).
// What BC did (27.5, 28.5 and 29.0 alike, both enums): Value(Format(blank member)) and SetValue(blank member) are accepted on the new-row
//   line and on the existing line; the control then shows ' '. A new-row line where only the enum was typed is not inserted; after Descr
//   was typed it is inserted with ordinal 0. Value('') and SetValue('') raise the TestValidation error "Your entry of '' is not an
//   acceptable value for '<field>'.", after which the control's Value is the ordinal ('0', or '1' on the existing Replace line).
// BC versions: 27, 28, 29 (corpus CI)

enum 75860 "EBN Action3"
{
    Extensible = false;

    value(0; Empty) { Caption = ' ', Locked = true; }
    value(1; Replace) { Caption = 'Replace'; }
    value(2; Append) { Caption = 'Append'; }
}

enum 75861 "EBN Action2"
{
    Extensible = false;

    value(0; Empty) { Caption = ' ', Locked = true; }
    value(1; Replace) { Caption = 'Replace'; }
}

table 75860 "EBN Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Descr; Text[30]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 75861 "EBN Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Head No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Descr; Text[30]) { }
        field(4; "Action3"; Enum "EBN Action3") { }
        field(5; "Action2"; Enum "EBN Action2") { }
    }

    keys { key(PK; "Head No.", "Line No.") { Clustered = true; } }
}

page 75860 "EBN Line Part"
{
    PageType = ListPart;
    SourceTable = "EBN Line";
    AutoSplitKey = true;
    DelayedInsert = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
                field(Action3Ctl; Rec."Action3") { ApplicationArea = All; }
                field(Action2Ctl; Rec."Action2") { ApplicationArea = All; }
            }
        }
    }
}

page 75861 "EBN Head Card"
{
    PageType = Card;
    SourceTable = "EBN Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(HeadDescrCtl; Rec.Descr) { ApplicationArea = All; }
            part(Lines; "EBN Line Part")
            {
                ApplicationArea = All;
                SubPageLink = "Head No." = field("No.");
            }
        }
    }
}

codeunit 75869 "EBN Enum Blank OpenNew Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Opening Edit needs head H1 with line 10000 (Descr one, Action3 Replace, Action2 Replace); the other openings start with no rows.
    local procedure Seed(WithHead: Boolean)
    var
        Head: Record "EBN Head";
        Line: Record "EBN Line";
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        if not WithHead then
            exit;
        Head."No." := 'H1';
        Head.Insert();
        Line."Head No." := 'H1';
        Line."Line No." := 10000;
        Line.Descr := 'one';
        Line."Action3" := Line."Action3"::Replace;
        Line."Action2" := Line."Action2"::Replace;
        Line.Insert();
    end;

    local procedure Stored(): Text
    var
        Head: Record "EBN Head";
        Line: Record "EBN Line";
        Result: Text;
    begin
        Result := 'heads=' + Format(Head.Count());
        if Head.FindSet() then
            repeat
                Result += ' [' + Head."No." + ']';
            until Head.Next() = 0;
        Result += ' lines=' + Format(Line.Count());
        if Line.FindSet() then
            repeat
                Result += ' [' + Line."Head No." + ']/' + Format(Line."Line No.") + ':' + Format(Line."Action3".AsInteger()) + '/' + Format(Line."Action2".AsInteger()) + '/' + Line.Descr;
            until Line.Next() = 0;
        exit(Result);
    end;

    local procedure InputName(Input: Integer): Text
    begin
        case Input of
            1:
                exit('Value Format of the blank member');
            2:
                exit('Value empty text');
            3:
                exit('SetValue empty text');
            4:
                exit('SetValue blank member');
            5:
                exit('Value Format of the last member');
        end;
    end;

    local procedure ControlValue(var Host: TestPage "EBN Head Card"; Three: Boolean): Text
    begin
        if Three then
            exit(Host.Lines.Action3Ctl.Value());
        exit(Host.Lines.Action2Ctl.Value());
    end;

    local procedure TypeInput(var Host: TestPage "EBN Head Card"; Three: Boolean; Input: Integer)
    var
        TextInput: Text;
    begin
        TextInput := '';
        case Input of
            1:
                if Three then
                    Host.Lines.Action3Ctl.Value(Format(Enum::"EBN Action3"::Empty))
                else
                    Host.Lines.Action2Ctl.Value(Format(Enum::"EBN Action2"::Empty));
            2:
                if Three then
                    Host.Lines.Action3Ctl.Value(TextInput)
                else
                    Host.Lines.Action2Ctl.Value(TextInput);
            3:
                if Three then
                    Host.Lines.Action3Ctl.SetValue(TextInput)
                else
                    Host.Lines.Action2Ctl.SetValue(TextInput);
            4:
                if Three then
                    Host.Lines.Action3Ctl.SetValue(Enum::"EBN Action3"::Empty)
                else
                    Host.Lines.Action2Ctl.SetValue(Enum::"EBN Action2"::Empty);
            5:
                if Three then
                    Host.Lines.Action3Ctl.Value(Format(Enum::"EBN Action3"::Append))
                else
                    Host.Lines.Action2Ctl.Value(Format(Enum::"EBN Action2"::Replace));
        end;
    end;

    // Opening: NewHeader (OpenNew, No. set to H1), NewBare (OpenNew, no header field set) or Edit (OpenEdit on H1).
    // Position: N the new-row line after Last and Next, D the same after Descr was set to typed, E the existing line (First).
    // The navigation, the input, the read of the value and the Close run inside one asserterror block that ends with the error 'no error'
    // (the containers refuse a write inside a TryFunction). Stage says how far the block came. The stored rows are read inside the block,
    // before the asserterror rolls the test's writes back.
    local procedure RunCase(var Observer: Codeunit "Probe Observer"; Three: Boolean; Opening: Text; Position: Text; Input: Integer)
    var
        Host: TestPage "EBN Head Card";
        Got: Text;
        Stage: Text;
        After: Text;
        StoredRows: Text;
    begin
        Seed(Opening = 'Edit');
        ClearLastError();
        Stage := 'open';
        asserterror begin
            if Opening = 'Edit' then
                Host.OpenEdit()
            else begin
                Host.OpenNew();
                if Opening = 'NewHeader' then
                    Host.NoCtl.SetValue('H1');
            end;
            Stage := 'navigate';
            if Position = 'E' then
                Host.Lines.First()
            else begin
                Host.Lines.Last();
                Host.Lines.Next();
            end;
            if Position = 'D' then
                Host.Lines.DescrCtl.SetValue('typed');
            Got := 'before=[' + ControlValue(Host, Three) + '] ';
            Stage := 'input';
            TypeInput(Host, Three, Input);
            Stage := 'value';
            After := ControlValue(Host, Three);
            Stage := 'close';
            Host.Close();
            Stage := 'done';
            StoredRows := Stored();
            Error('no error');
        end;
        Got += 'stage=' + Stage + ' error=' + GetLastErrorText();
        if Stage <> 'done' then
            Got += ' {' + GetLastErrorCode() + '}';
        if Stage = 'input' then begin
            ClearLastError();
            asserterror begin
                After := ControlValue(Host, Three);
                Error('no error');
            end;
            if GetLastErrorText() <> 'no error' then
                After := 'error: ' + GetLastErrorText();
        end;
        Got += ' after=[' + After + ']';
        if Stage = 'done' then
            Got += ' ' + StoredRows;
        ClearLastError();
        Observer.Observe(InputName(Input), Got);
    end;

    local procedure RunInputs(var Observer: Codeunit "Probe Observer"; Three: Boolean; Opening: Text; Position: Text)
    var
        Input: Integer;
    begin
        for Input := 1 to 5 do
            RunCase(Observer, Three, Opening, Position, Input);
    end;

    [Test]
    procedure EnumBlankOpenNew_Three_NewHeader_NewRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunInputs(Observer, true, 'NewHeader', 'N');
        Observer.Expect('Value Format of the blank member', 'before=[ ] stage=done error=no error after=[ ] heads=1 [H1] lines=0');
        Observer.Expect('Value empty text', 'before=[ ] stage=input error=Validation error for Field: Action3Ctl,  Message = ''Your entry of '''' is not an acceptable value for ''Action3''.'' {TestValidation} after=[0]');
        Observer.Expect('SetValue empty text', 'before=[ ] stage=input error=Validation error for Field: Action3Ctl,  Message = ''Your entry of '''' is not an acceptable value for ''Action3''.'' {TestValidation} after=[0]');
        Observer.Expect('SetValue blank member', 'before=[ ] stage=done error=no error after=[ ] heads=1 [H1] lines=0');
        Observer.Expect('Value Format of the last member', 'before=[ ] stage=done error=no error after=[Append] heads=1 [H1] lines=1 [H1]/10000:2/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlankOpenNew_Three_NewHeader_NewRowAfterDescr()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunInputs(Observer, true, 'NewHeader', 'D');
        Observer.Expect('Value Format of the blank member', 'before=[ ] stage=done error=no error after=[ ] heads=1 [H1] lines=1 [H1]/10000:0/0/typed');
        Observer.Expect('Value empty text', 'before=[ ] stage=input error=Validation error for Field: Action3Ctl,  Message = ''Your entry of '''' is not an acceptable value for ''Action3''.'' {TestValidation} after=[0]');
        Observer.Expect('SetValue empty text', 'before=[ ] stage=input error=Validation error for Field: Action3Ctl,  Message = ''Your entry of '''' is not an acceptable value for ''Action3''.'' {TestValidation} after=[0]');
        Observer.Expect('SetValue blank member', 'before=[ ] stage=done error=no error after=[ ] heads=1 [H1] lines=1 [H1]/10000:0/0/typed');
        Observer.Expect('Value Format of the last member', 'before=[ ] stage=done error=no error after=[Append] heads=1 [H1] lines=1 [H1]/10000:2/0/typed');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlankOpenNew_Three_NewBare_NewRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunInputs(Observer, true, 'NewBare', 'N');
        Observer.Expect('Value Format of the blank member', 'before=[ ] stage=done error=no error after=[ ] heads=1 [] lines=0');
        Observer.Expect('Value empty text', 'before=[ ] stage=input error=Validation error for Field: Action3Ctl,  Message = ''Your entry of '''' is not an acceptable value for ''Action3''.'' {TestValidation} after=[0]');
        Observer.Expect('SetValue empty text', 'before=[ ] stage=input error=Validation error for Field: Action3Ctl,  Message = ''Your entry of '''' is not an acceptable value for ''Action3''.'' {TestValidation} after=[0]');
        Observer.Expect('SetValue blank member', 'before=[ ] stage=done error=no error after=[ ] heads=1 [] lines=0');
        Observer.Expect('Value Format of the last member', 'before=[ ] stage=done error=no error after=[Append] heads=1 [] lines=1 []/10000:2/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlankOpenNew_Three_NewBare_NewRowAfterDescr()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunInputs(Observer, true, 'NewBare', 'D');
        Observer.Expect('Value Format of the blank member', 'before=[ ] stage=done error=no error after=[ ] heads=1 [] lines=1 []/10000:0/0/typed');
        Observer.Expect('Value empty text', 'before=[ ] stage=input error=Validation error for Field: Action3Ctl,  Message = ''Your entry of '''' is not an acceptable value for ''Action3''.'' {TestValidation} after=[0]');
        Observer.Expect('SetValue empty text', 'before=[ ] stage=input error=Validation error for Field: Action3Ctl,  Message = ''Your entry of '''' is not an acceptable value for ''Action3''.'' {TestValidation} after=[0]');
        Observer.Expect('SetValue blank member', 'before=[ ] stage=done error=no error after=[ ] heads=1 [] lines=1 []/10000:0/0/typed');
        Observer.Expect('Value Format of the last member', 'before=[ ] stage=done error=no error after=[Append] heads=1 [] lines=1 []/10000:2/0/typed');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlankOpenNew_Three_OpenEdit_NewRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunInputs(Observer, true, 'Edit', 'N');
        Observer.Expect('Value Format of the blank member', 'before=[ ] stage=done error=no error after=[ ] heads=1 [H1] lines=1 [H1]/10000:1/1/one');
        Observer.Expect('Value empty text', 'before=[ ] stage=input error=Validation error for Field: Action3Ctl,  Message = ''Your entry of '''' is not an acceptable value for ''Action3''.'' {TestValidation} after=[0]');
        Observer.Expect('SetValue empty text', 'before=[ ] stage=input error=Validation error for Field: Action3Ctl,  Message = ''Your entry of '''' is not an acceptable value for ''Action3''.'' {TestValidation} after=[0]');
        Observer.Expect('SetValue blank member', 'before=[ ] stage=done error=no error after=[ ] heads=1 [H1] lines=1 [H1]/10000:1/1/one');
        Observer.Expect('Value Format of the last member', 'before=[ ] stage=done error=no error after=[Append] heads=1 [H1] lines=2 [H1]/10000:1/1/one [H1]/20000:2/0/');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlankOpenNew_Three_OpenEdit_ExistingRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunInputs(Observer, true, 'Edit', 'E');
        Observer.Expect('Value Format of the blank member', 'before=[Replace] stage=done error=no error after=[ ] heads=1 [H1] lines=1 [H1]/10000:0/1/one');
        Observer.Expect('Value empty text', 'before=[Replace] stage=input error=Validation error for Field: Action3Ctl,  Message = ''Your entry of '''' is not an acceptable value for ''Action3''.'' {TestValidation} after=[1]');
        Observer.Expect('SetValue empty text', 'before=[Replace] stage=input error=Validation error for Field: Action3Ctl,  Message = ''Your entry of '''' is not an acceptable value for ''Action3''.'' {TestValidation} after=[1]');
        Observer.Expect('SetValue blank member', 'before=[Replace] stage=done error=no error after=[ ] heads=1 [H1] lines=1 [H1]/10000:0/1/one');
        Observer.Expect('Value Format of the last member', 'before=[Replace] stage=done error=no error after=[Append] heads=1 [H1] lines=1 [H1]/10000:2/1/one');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlankOpenNew_Two_NewHeader_NewRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunInputs(Observer, false, 'NewHeader', 'N');
        Observer.Expect('Value Format of the blank member', 'before=[ ] stage=done error=no error after=[ ] heads=1 [H1] lines=0');
        Observer.Expect('Value empty text', 'before=[ ] stage=input error=Validation error for Field: Action2Ctl,  Message = ''Your entry of '''' is not an acceptable value for ''Action2''.'' {TestValidation} after=[0]');
        Observer.Expect('SetValue empty text', 'before=[ ] stage=input error=Validation error for Field: Action2Ctl,  Message = ''Your entry of '''' is not an acceptable value for ''Action2''.'' {TestValidation} after=[0]');
        Observer.Expect('SetValue blank member', 'before=[ ] stage=done error=no error after=[ ] heads=1 [H1] lines=0');
        Observer.Expect('Value Format of the last member', 'before=[ ] stage=done error=no error after=[Replace] heads=1 [H1] lines=1 [H1]/10000:0/1/');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlankOpenNew_Two_NewHeader_NewRowAfterDescr()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunInputs(Observer, false, 'NewHeader', 'D');
        Observer.Expect('Value Format of the blank member', 'before=[ ] stage=done error=no error after=[ ] heads=1 [H1] lines=1 [H1]/10000:0/0/typed');
        Observer.Expect('Value empty text', 'before=[ ] stage=input error=Validation error for Field: Action2Ctl,  Message = ''Your entry of '''' is not an acceptable value for ''Action2''.'' {TestValidation} after=[0]');
        Observer.Expect('SetValue empty text', 'before=[ ] stage=input error=Validation error for Field: Action2Ctl,  Message = ''Your entry of '''' is not an acceptable value for ''Action2''.'' {TestValidation} after=[0]');
        Observer.Expect('SetValue blank member', 'before=[ ] stage=done error=no error after=[ ] heads=1 [H1] lines=1 [H1]/10000:0/0/typed');
        Observer.Expect('Value Format of the last member', 'before=[ ] stage=done error=no error after=[Replace] heads=1 [H1] lines=1 [H1]/10000:0/1/typed');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlankOpenNew_Two_NewBare_NewRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunInputs(Observer, false, 'NewBare', 'N');
        Observer.Expect('Value Format of the blank member', 'before=[ ] stage=done error=no error after=[ ] heads=1 [] lines=0');
        Observer.Expect('Value empty text', 'before=[ ] stage=input error=Validation error for Field: Action2Ctl,  Message = ''Your entry of '''' is not an acceptable value for ''Action2''.'' {TestValidation} after=[0]');
        Observer.Expect('SetValue empty text', 'before=[ ] stage=input error=Validation error for Field: Action2Ctl,  Message = ''Your entry of '''' is not an acceptable value for ''Action2''.'' {TestValidation} after=[0]');
        Observer.Expect('SetValue blank member', 'before=[ ] stage=done error=no error after=[ ] heads=1 [] lines=0');
        Observer.Expect('Value Format of the last member', 'before=[ ] stage=done error=no error after=[Replace] heads=1 [] lines=1 []/10000:0/1/');
        Observer.Verify();
    end;
}
