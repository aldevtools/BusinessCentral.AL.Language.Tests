// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-enum-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 97900-97910 (LT ECR ...)
// Probe: from al-runner issue 6924 (waldo) follow-up: enum values with CaptionML, read through every reader other than Format and Evaluate
//   (those are pinned in EvalLanguageBoolean.al): TestPage enum control (Value, SetValue, ValidateValue), GetFilter, GetFilters, GetView, SetFilter with
//   the caption, the name and the other language's caption, TableRelation and CalcFormula filters, FieldRef OptionCaption and OptionMembers,
//   TestField and FieldError texts, key values (RecordId, GetPosition, KeyRef), list page columns. Under GlobalLanguage 1033 and 2067, for an enum
//   with CaptionML on every value, an enum that mixes CaptionML, Caption and no caption, and an enum with an ENU-only CaptionML.
// Facts (measured on BC 27.5, 28.5 and 29.0; the only version difference is the FieldRef.Value := text error text, see #if BC28PLUS):
//   Every reader shows the caption of the GlobalLanguage (CaptionML; the plain Caption of a value that has no CaptionML; the name when a value has neither).
//   An ENU-only CaptionML shows its ENU text under 2067 as well. GetFilter, GetFilters, GetView, TestPage values, TestField, FieldError, RecordId and
//   key values use the caption; GetPosition and SetPosition use the name. SetFilter, SetView, SetPosition and FieldRef.SetFilter accept the name and
//   the caption of the current language (and the ordinal) but not the other language's caption; FieldRef.Value := text accepts only the ordinal.
//   TestPage SetValue accepts only the caption of the current language; a TestPage list filter by a text that is not the caption is ignored.
// BC versions: 27+ (tested by the corpus CI matrix)

enum 97900 "LT ECR Ml"
{
    Extensible = true;

    value(0; Open)
    {
        CaptionML = ENU = 'Open cap', NLB = 'Open BE';
    }
    value(1; Closed)
    {
        CaptionML = ENU = 'Closed cap', NLB = 'Gesloten BE';
    }
}

enum 97901 "LT ECR Mixed"
{
    Extensible = true;

    value(0; Alpha)
    {
        CaptionML = ENU = 'Alpha cap', NLB = 'Alpha BE';
    }
    value(1; Beta)
    {
        Caption = 'Beta plain';
    }
    value(2; Gamma)
    {
    }
}

enum 97902 "LT ECR EnuOnly"
{
    Extensible = true;

    value(0; Red)
    {
        CaptionML = ENU = 'Red cap';
    }
    value(1; Green)
    {
        CaptionML = ENU = 'Green cap';
    }
}

table 97903 "LT ECR Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Status; Enum "LT ECR Ml") { }
        field(3; Mixed; Enum "LT ECR Mixed") { }
        field(4; Enu; Enum "LT ECR EnuOnly") { }
        field(5; StatusFilter; Enum "LT ECR Ml")
        {
            FieldClass = FlowFilter;
        }
        field(6; ClosedCount; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT ECR Row" where(Status = const(Closed)));
        }
        field(7; MatchCount; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT ECR Row" where(Status = field(StatusFilter)));
        }
        field(8; OpenOrClosedCount; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT ECR Row" where(Status = filter(Open | Closed)));
        }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 97904 "LT ECR Rel"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ClosedRef; Integer)
        {
            TableRelation = "LT ECR Row".Id where(Status = const(Closed));
        }
        field(3; AnyRef; Integer)
        {
            TableRelation = "LT ECR Row".Id where(Status = filter(Open | Closed));
        }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 97905 "LT ECR Keyed"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Status; Enum "LT ECR Ml") { }
        field(2; Enu; Enum "LT ECR EnuOnly") { }
        field(3; Note; Text[30]) { }
    }

    keys { key(PK; Status, Enu) { Clustered = true; } }
}

page 97906 "LT ECR Card"
{
    PageType = Card;
    SourceTable = "LT ECR Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Id; Rec.Id) { }
                field(Status; Rec.Status) { }
                field(Mixed; Rec.Mixed) { }
                field(Enu; Rec.Enu) { }
            }
        }
    }
}

page 97907 "LT ECR List"
{
    PageType = List;
    SourceTable = "LT ECR Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { }
                field(Status; Rec.Status) { }
                field(Mixed; Rec.Mixed) { }
                field(Enu; Rec.Enu) { }
            }
        }
    }
}

codeunit 97909 "LT ECR Tools"
{
    [TryFunction]
    procedure FilterStatus(var Row: Record "LT ECR Row"; Word: Text)
    begin
        Row.SetFilter(Status, Word);
    end;

    [TryFunction]
    procedure FilterMixed(var Row: Record "LT ECR Row"; Word: Text)
    begin
        Row.SetFilter(Mixed, Word);
    end;

    [TryFunction]
    procedure FilterEnu(var Row: Record "LT ECR Row"; Word: Text)
    begin
        Row.SetFilter(Enu, Word);
    end;

    [TryFunction]
    procedure FilterFlow(var Row: Record "LT ECR Row"; Word: Text)
    begin
        Row.SetFilter(StatusFilter, Word);
    end;

    [TryFunction]
    procedure SetCard(var Card: TestPage "LT ECR Card"; Which: Integer; Word: Text)
    begin
        case Which of
            1:
                Card.Status.SetValue(Word);
            2:
                Card.Mixed.SetValue(Word);
            3:
                Card.Enu.SetValue(Word);
        end;
    end;

    [TryFunction]
    procedure ValidateCard(var Card: TestPage "LT ECR Card"; Which: Integer; Word: Text)
    begin
        case Which of
            1:
                Card.Status.AssertEquals(Word);
            2:
                Card.Mixed.AssertEquals(Word);
            3:
                Card.Enu.AssertEquals(Word);
        end;
    end;

    [TryFunction]
    procedure SetRefValue(var Ref: FieldRef; Word: Text)
    begin
        Ref.Value := Word;
    end;

    [TryFunction]
    procedure FilterRef(var Ref: FieldRef; Word: Text)
    begin
        Ref.SetFilter(Word);
    end;

    [TryFunction]
    procedure SetPos(var RecRef: RecordRef; Pos: Text)
    begin
        RecRef.SetPosition(Pos);
    end;

    [TryFunction]
    procedure SetViewText(var Row: Record "LT ECR Row"; ViewText: Text)
    begin
        Row.SetView(ViewText);
    end;
}

codeunit 97910 "LT ECR Enum Readers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT ECR Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Status := Row.Status::Closed;
        Row.Mixed := Row.Mixed::Alpha;
        Row.Enu := Row.Enu::Green;
        Row.Insert();
        Row.Init();
        Row.Id := 2;
        Row.Status := Row.Status::Open;
        Row.Mixed := Row.Mixed::Beta;
        Row.Enu := Row.Enu::Red;
        Row.Insert();
        Row.Init();
        Row.Id := 3;
        Row.Status := Row.Status::Open;
        Row.Mixed := Row.Mixed::Gamma;
        Row.Enu := Row.Enu::Green;
        Row.Insert();
    end;

    // ---- 1. TestPage enum control: Value read
    local procedure CardValue(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Row: Record "LT ECR Row";
        Card: TestPage "LT ECR Card";
        i: Integer;
    begin
        Seed();
        GlobalLanguage(Lang);
        Card.OpenView();
        for i := 1 to 3 do begin
            Row.Get(i);
            Card.GoToRecord(Row);
            Observer.Observe('card' + Format(i) + ' status', Card.Status.Value());
            Observer.Observe('card' + Format(i) + ' mixed', Card.Mixed.Value());
            Observer.Observe('card' + Format(i) + ' enu', Card.Enu.Value());
        end;
        Card.Close();
        GlobalLanguage(1033);
    end;

    [Test]
    procedure ECR_CardValue_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CardValue(Observer, 1033);
        Observer.Expect('card1 status', 'Closed cap');
        Observer.Expect('card1 mixed', 'Alpha cap');
        Observer.Expect('card1 enu', 'Green cap');
        Observer.Expect('card2 status', 'Open cap');
        Observer.Expect('card2 mixed', 'Beta plain');
        Observer.Expect('card2 enu', 'Red cap');
        Observer.Expect('card3 status', 'Open cap');
        Observer.Expect('card3 mixed', 'Gamma');
        Observer.Expect('card3 enu', 'Green cap');
        Observer.Verify();
    end;

    [Test]
    procedure ECR_CardValue_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CardValue(Observer, 2067);
        Observer.Expect('card1 status', 'Gesloten BE');
        Observer.Expect('card1 mixed', 'Alpha BE');
        Observer.Expect('card1 enu', 'Green cap');
        Observer.Expect('card2 status', 'Open BE');
        Observer.Expect('card2 mixed', 'Beta plain');
        Observer.Expect('card2 enu', 'Red cap');
        Observer.Expect('card3 status', 'Open BE');
        Observer.Expect('card3 mixed', 'Gamma');
        Observer.Expect('card3 enu', 'Green cap');
        Observer.Verify();
    end;

    // ---- 1. TestPage SetValue / ValidateValue by words
    local procedure CardSet(var Observer: Codeunit "Probe Observer"; Lang: Integer; Which: Integer; Validate: Boolean; Words: Text)
    var
        Row: Record "LT ECR Row";
        Tools: Codeunit "LT ECR Tools";
        Card: TestPage "LT ECR Card";
        WordList: List of [Text];
        Word: Text;
        Ok: Boolean;
        Current: Text;
    begin
        WordList := Words.Split('|');
        foreach Word in WordList do begin
            Seed();
            GlobalLanguage(Lang);
            Card.OpenEdit();
            Row.Get(2);
            Card.GoToRecord(Row);
            ClearLastError();
            if Validate then
                Ok := Tools.ValidateCard(Card, Which, Word)
            else
                Ok := Tools.SetCard(Card, Which, Word);
            case Which of
                1:
                    Current := Card.Status.Value();
                2:
                    Current := Card.Mixed.Value();
                3:
                    Current := Card.Enu.Value();
            end;
            if Ok then
                Observer.Observe('w ' + Word, 'ok|' + Current)
            else begin
                Observer.Observe('w ' + Word, 'err|' + Current);
                Observer.ObserveError('w ' + Word);
            end;
            Card.Close();
        end;
        GlobalLanguage(1033);
    end;

    [Test]
    procedure ECR_CardSetStatus_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CardSet(Observer, 1033, 1, false, 'Open|Closed|closed|Closed cap|closed cap|Gesloten BE|Open BE|1');
        Observer.Expect('w Open', 'err|0');
        Observer.Expect('w Open|text', 'Validation error for Field: Status,  Message = ''Your entry of ''Open'' is not an acceptable value for ''Status''. (Select Refresh to discard errors)''');
        Observer.Expect('w Open|code', 'TestValidation');
        Observer.Expect('w Closed', 'err|0');
        Observer.Expect('w Closed|text', 'Validation error for Field: Status,  Message = ''Your entry of ''Closed'' is not an acceptable value for ''Status''. (Select Refresh to discard errors)''');
        Observer.Expect('w Closed|code', 'TestValidation');
        Observer.Expect('w closed', 'err|0');
        Observer.Expect('w closed|text', 'Validation error for Field: Status,  Message = ''Your entry of ''closed'' is not an acceptable value for ''Status''. (Select Refresh to discard errors)''');
        Observer.Expect('w closed|code', 'TestValidation');
        Observer.Expect('w Closed cap', 'ok|Closed cap');
        Observer.Expect('w closed cap', 'ok|Closed cap');
        Observer.Expect('w Gesloten BE', 'err|0');
        Observer.Expect('w Gesloten BE|text', 'Validation error for Field: Status,  Message = ''Your entry of ''Gesloten BE'' is not an acceptable value for ''Status''. (Select Refresh to discard errors)''');
        Observer.Expect('w Gesloten BE|code', 'TestValidation');
        Observer.Expect('w Open BE', 'err|0');
        Observer.Expect('w Open BE|text', 'Validation error for Field: Status,  Message = ''Your entry of ''Open BE'' is not an acceptable value for ''Status''. (Select Refresh to discard errors)''');
        Observer.Expect('w Open BE|code', 'TestValidation');
        Observer.Expect('w 1', 'err|0');
        Observer.Expect('w 1|text', 'Validation error for Field: Status,  Message = ''Your entry of ''1'' is not an acceptable value for ''Status''. (Select Refresh to discard errors)''');
        Observer.Expect('w 1|code', 'TestValidation');
        Observer.Verify();
    end;

    [Test]
    procedure ECR_CardSetStatus_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CardSet(Observer, 2067, 1, false, 'Open|Closed|closed|Closed cap|Gesloten BE|gesloten be|Open BE|1');
        Observer.Expect('w Open', 'err|0');
        Observer.Expect('w Open|text', 'Validatiefout voor veld: Status, bericht = ''Your entry of ''Open'' is not an acceptable value for ''Status''. (Selecteer Vernieuwen om fouten te verwijderen)''');
        Observer.Expect('w Open|code', 'TestValidation');
        Observer.Expect('w Closed', 'err|0');
        Observer.Expect('w Closed|text', 'Validatiefout voor veld: Status, bericht = ''Your entry of ''Closed'' is not an acceptable value for ''Status''. (Selecteer Vernieuwen om fouten te verwijderen)''');
        Observer.Expect('w Closed|code', 'TestValidation');
        Observer.Expect('w closed', 'err|0');
        Observer.Expect('w closed|text', 'Validatiefout voor veld: Status, bericht = ''Your entry of ''closed'' is not an acceptable value for ''Status''. (Selecteer Vernieuwen om fouten te verwijderen)''');
        Observer.Expect('w closed|code', 'TestValidation');
        Observer.Expect('w Closed cap', 'err|0');
        Observer.Expect('w Closed cap|text', 'Validatiefout voor veld: Status, bericht = ''Your entry of ''Closed cap'' is not an acceptable value for ''Status''. (Selecteer Vernieuwen om fouten te verwijderen)''');
        Observer.Expect('w Closed cap|code', 'TestValidation');
        Observer.Expect('w Gesloten BE', 'ok|Gesloten BE');
        Observer.Expect('w gesloten be', 'ok|Gesloten BE');
        Observer.Expect('w Open BE', 'ok|Open BE');
        Observer.Expect('w 1', 'err|0');
        Observer.Expect('w 1|text', 'Validatiefout voor veld: Status, bericht = ''Your entry of ''1'' is not an acceptable value for ''Status''. (Selecteer Vernieuwen om fouten te verwijderen)''');
        Observer.Expect('w 1|code', 'TestValidation');
        Observer.Verify();
    end;

    [Test]
    procedure ECR_CardAssertStatus_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CardSet(Observer, 1033, 1, true, 'Closed|Closed cap|Gesloten BE|1');
        Observer.Expect('w Closed', 'err|Open cap');
        Observer.Expect('w Closed|text', 'AssertEquals for Field: Status Expected = ''Closed'', Actual = ''Open cap''');
        Observer.Expect('w Closed|code', 'TestAssertEquals');
        Observer.Expect('w Closed cap', 'err|Open cap');
        Observer.Expect('w Closed cap|text', 'AssertEquals for Field: Status Expected = ''Closed cap'', Actual = ''Open cap''');
        Observer.Expect('w Closed cap|code', 'TestAssertEquals');
        Observer.Expect('w Gesloten BE', 'err|Open cap');
        Observer.Expect('w Gesloten BE|text', 'AssertEquals for Field: Status Expected = ''Gesloten BE'', Actual = ''Open cap''');
        Observer.Expect('w Gesloten BE|code', 'TestAssertEquals');
        Observer.Expect('w 1', 'err|Open cap');
        Observer.Expect('w 1|text', 'AssertEquals for Field: Status Expected = ''1'', Actual = ''Open cap''');
        Observer.Expect('w 1|code', 'TestAssertEquals');
        Observer.Verify();
    end;

    [Test]
    procedure ECR_CardAssertStatus_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CardSet(Observer, 2067, 1, true, 'Closed|Closed cap|Gesloten BE|1');
        Observer.Expect('w Closed', 'err|Open BE');
        Observer.Expect('w Closed|text', 'AssertEquals voor veld: Status Verwacht = ''Closed'', Werkelijk = ''Open BE''');
        Observer.Expect('w Closed|code', 'TestAssertEquals');
        Observer.Expect('w Closed cap', 'err|Open BE');
        Observer.Expect('w Closed cap|text', 'AssertEquals voor veld: Status Verwacht = ''Closed cap'', Werkelijk = ''Open BE''');
        Observer.Expect('w Closed cap|code', 'TestAssertEquals');
        Observer.Expect('w Gesloten BE', 'err|Open BE');
        Observer.Expect('w Gesloten BE|text', 'AssertEquals voor veld: Status Verwacht = ''Gesloten BE'', Werkelijk = ''Open BE''');
        Observer.Expect('w Gesloten BE|code', 'TestAssertEquals');
        Observer.Expect('w 1', 'err|Open BE');
        Observer.Expect('w 1|text', 'AssertEquals voor veld: Status Verwacht = ''1'', Werkelijk = ''Open BE''');
        Observer.Expect('w 1|code', 'TestAssertEquals');
        Observer.Verify();
    end;

    [Test]
    procedure ECR_CardSetMixed_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CardSet(Observer, 1033, 2, false, 'Alpha|Alpha cap|Alpha BE|Beta|Beta plain|Gamma|0|2');
        Observer.Expect('w Alpha', 'err|1');
        Observer.Expect('w Alpha|text', 'Validation error for Field: Mixed,  Message = ''Your entry of ''Alpha'' is not an acceptable value for ''Mixed''. (Select Refresh to discard errors)''');
        Observer.Expect('w Alpha|code', 'TestValidation');
        Observer.Expect('w Alpha cap', 'ok|Alpha cap');
        Observer.Expect('w Alpha BE', 'err|1');
        Observer.Expect('w Alpha BE|text', 'Validation error for Field: Mixed,  Message = ''Your entry of ''Alpha BE'' is not an acceptable value for ''Mixed''. (Select Refresh to discard errors)''');
        Observer.Expect('w Alpha BE|code', 'TestValidation');
        Observer.Expect('w Beta', 'err|1');
        Observer.Expect('w Beta|text', 'Validation error for Field: Mixed,  Message = ''Your entry of ''Beta'' is not an acceptable value for ''Mixed''. (Select Refresh to discard errors)''');
        Observer.Expect('w Beta|code', 'TestValidation');
        Observer.Expect('w Beta plain', 'ok|Beta plain');
        Observer.Expect('w Gamma', 'ok|Gamma');
        Observer.Expect('w 0', 'err|1');
        Observer.Expect('w 0|text', 'Validation error for Field: Mixed,  Message = ''Your entry of ''0'' is not an acceptable value for ''Mixed''. (Select Refresh to discard errors)''');
        Observer.Expect('w 0|code', 'TestValidation');
        Observer.Expect('w 2', 'err|1');
        Observer.Expect('w 2|text', 'Validation error for Field: Mixed,  Message = ''Your entry of ''2'' is not an acceptable value for ''Mixed''. (Select Refresh to discard errors)''');
        Observer.Expect('w 2|code', 'TestValidation');
        Observer.Verify();
    end;

    [Test]
    procedure ECR_CardSetMixed_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CardSet(Observer, 2067, 2, false, 'Alpha|Alpha cap|Alpha BE|Beta|Beta plain|Gamma|0|2');
        Observer.Expect('w Alpha', 'err|1');
        Observer.Expect('w Alpha|text', 'Validatiefout voor veld: Mixed, bericht = ''Your entry of ''Alpha'' is not an acceptable value for ''Mixed''. (Selecteer Vernieuwen om fouten te verwijderen)''');
        Observer.Expect('w Alpha|code', 'TestValidation');
        Observer.Expect('w Alpha cap', 'err|1');
        Observer.Expect('w Alpha cap|text', 'Validatiefout voor veld: Mixed, bericht = ''Your entry of ''Alpha cap'' is not an acceptable value for ''Mixed''. (Selecteer Vernieuwen om fouten te verwijderen)''');
        Observer.Expect('w Alpha cap|code', 'TestValidation');
        Observer.Expect('w Alpha BE', 'ok|Alpha BE');
        Observer.Expect('w Beta', 'err|1');
        Observer.Expect('w Beta|text', 'Validatiefout voor veld: Mixed, bericht = ''Your entry of ''Beta'' is not an acceptable value for ''Mixed''. (Selecteer Vernieuwen om fouten te verwijderen)''');
        Observer.Expect('w Beta|code', 'TestValidation');
        Observer.Expect('w Beta plain', 'ok|Beta plain');
        Observer.Expect('w Gamma', 'ok|Gamma');
        Observer.Expect('w 0', 'err|1');
        Observer.Expect('w 0|text', 'Validatiefout voor veld: Mixed, bericht = ''Your entry of ''0'' is not an acceptable value for ''Mixed''. (Selecteer Vernieuwen om fouten te verwijderen)''');
        Observer.Expect('w 0|code', 'TestValidation');
        Observer.Expect('w 2', 'err|1');
        Observer.Expect('w 2|text', 'Validatiefout voor veld: Mixed, bericht = ''Your entry of ''2'' is not an acceptable value for ''Mixed''. (Selecteer Vernieuwen om fouten te verwijderen)''');
        Observer.Expect('w 2|code', 'TestValidation');
        Observer.Verify();
    end;

    [Test]
    procedure ECR_CardSetEnuOnly_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CardSet(Observer, 1033, 3, false, 'Red|Green|Green cap|green cap|1');
        Observer.Expect('w Red', 'err|0');
        Observer.Expect('w Red|text', 'Validation error for Field: Enu,  Message = ''Your entry of ''Red'' is not an acceptable value for ''Enu''. (Select Refresh to discard errors)''');
        Observer.Expect('w Red|code', 'TestValidation');
        Observer.Expect('w Green', 'err|0');
        Observer.Expect('w Green|text', 'Validation error for Field: Enu,  Message = ''Your entry of ''Green'' is not an acceptable value for ''Enu''. (Select Refresh to discard errors)''');
        Observer.Expect('w Green|code', 'TestValidation');
        Observer.Expect('w Green cap', 'ok|Green cap');
        Observer.Expect('w green cap', 'ok|Green cap');
        Observer.Expect('w 1', 'err|0');
        Observer.Expect('w 1|text', 'Validation error for Field: Enu,  Message = ''Your entry of ''1'' is not an acceptable value for ''Enu''. (Select Refresh to discard errors)''');
        Observer.Expect('w 1|code', 'TestValidation');
        Observer.Verify();
    end;

    [Test]
    procedure ECR_CardSetEnuOnly_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CardSet(Observer, 2067, 3, false, 'Red|Green|Green cap|green cap|1');
        Observer.Expect('w Red', 'err|0');
        Observer.Expect('w Red|text', 'Validatiefout voor veld: Enu, bericht = ''Your entry of ''Red'' is not an acceptable value for ''Enu''. (Selecteer Vernieuwen om fouten te verwijderen)''');
        Observer.Expect('w Red|code', 'TestValidation');
        Observer.Expect('w Green', 'err|0');
        Observer.Expect('w Green|text', 'Validatiefout voor veld: Enu, bericht = ''Your entry of ''Green'' is not an acceptable value for ''Enu''. (Selecteer Vernieuwen om fouten te verwijderen)''');
        Observer.Expect('w Green|code', 'TestValidation');
        Observer.Expect('w Green cap', 'ok|Green cap');
        Observer.Expect('w green cap', 'ok|Green cap');
        Observer.Expect('w 1', 'err|0');
        Observer.Expect('w 1|text', 'Validatiefout voor veld: Enu, bericht = ''Your entry of ''1'' is not an acceptable value for ''Enu''. (Selecteer Vernieuwen om fouten te verwijderen)''');
        Observer.Expect('w 1|code', 'TestValidation');
        Observer.Verify();
    end;

    // ---- 2. GetFilter, GetFilters, GetView after SetRange / SetFilter
    local procedure FilterTexts(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Row: Record "LT ECR Row";
    begin
        Seed();
        GlobalLanguage(Lang);
        Row.SetRange(Status, Row.Status::Closed);
        Observer.Observe('range Closed GetFilter', Row.GetFilter(Status));
        Observer.Observe('range Closed GetFilters', Row.GetFilters());
        Observer.Observe('range Closed GetView', Row.GetView());
        Observer.Observe('range Closed GetView false', Row.GetView(false));
        Observer.Observe('range Closed Count', Format(Row.Count()));
        Row.SetRange(Status, Row.Status::Open, Row.Status::Closed);
        Observer.Observe('range Open..Closed GetFilter', Row.GetFilter(Status));
        Observer.Observe('range Open..Closed Count', Format(Row.Count()));
        Row.SetFilter(Status, '%1|%2', Row.Status::Open, Row.Status::Closed);
        Observer.Observe('filter %1|%2 GetFilter', Row.GetFilter(Status));
        Row.SetFilter(Status, '<>%1', Row.Status::Closed);
        Observer.Observe('filter <>%1 GetFilter', Row.GetFilter(Status));
        Observer.Observe('filter <>%1 GetFilters', Row.GetFilters());
        Observer.Observe('filter <>%1 Count', Format(Row.Count()));
        Row.Reset();
        Row.SetRange(Mixed, Row.Mixed::Alpha);
        Row.SetFilter(Enu, '%1', Row.Enu::Green);
        Observer.Observe('mixed enu GetFilters', Row.GetFilters());
        Observer.Observe('mixed enu GetView', Row.GetView());
        Row.SetRange(Mixed, Row.Mixed::Beta);
        Observer.Observe('mixed Beta GetFilter', Row.GetFilter(Mixed));
        Row.SetRange(Mixed, Row.Mixed::Gamma);
        Observer.Observe('mixed Gamma GetFilter', Row.GetFilter(Mixed));
        Row.SetRange(Enu, Row.Enu::Red);
        Observer.Observe('enu Red GetFilter', Row.GetFilter(Enu));
        Row.SetRange(StatusFilter, Row.Status::Closed);
        Observer.Observe('flowfilter GetFilter', Row.GetFilter(StatusFilter));
        Observer.Observe('flowfilter GetFilters', Row.GetFilters());
        GlobalLanguage(1033);
    end;

    [Test]
    procedure ECR_FilterTexts_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FilterTexts(Observer, 1033);
        Observer.Expect('range Closed GetFilter', 'Closed cap');
        Observer.Expect('range Closed GetFilters', 'Status: Closed cap');
        Observer.Expect('range Closed GetView', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Closed cap))');
        Observer.Expect('range Closed GetView false', 'VERSION(1) SORTING(Field1) WHERE(Field2=1(1))');
        Observer.Expect('range Closed Count', '1');
        Observer.Expect('range Open..Closed GetFilter', 'Open cap..Closed cap');
        Observer.Expect('range Open..Closed Count', '3');
        Observer.Expect('filter %1|%2 GetFilter', 'Open cap|Closed cap');
        Observer.Expect('filter <>%1 GetFilter', '<>Closed cap');
        Observer.Expect('filter <>%1 GetFilters', 'Status: <>Closed cap');
        Observer.Expect('filter <>%1 Count', '2');
        Observer.Expect('mixed enu GetFilters', 'Mixed: Alpha cap, Enu: Green cap');
        Observer.Expect('mixed enu GetView', 'VERSION(1) SORTING(Id) WHERE(Mixed=FILTER(Alpha cap),Enu=FILTER(Green cap))');
        Observer.Expect('mixed Beta GetFilter', 'Beta plain');
        Observer.Expect('mixed Gamma GetFilter', 'Gamma');
        Observer.Expect('enu Red GetFilter', 'Red cap');
        Observer.Expect('flowfilter GetFilter', 'Closed cap');
        Observer.Expect('flowfilter GetFilters', 'Mixed: Gamma, Enu: Red cap, StatusFilter: Closed cap');
        Observer.Verify();
    end;

    [Test]
    procedure ECR_FilterTexts_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FilterTexts(Observer, 2067);
        Observer.Expect('range Closed GetFilter', 'Gesloten BE');
        Observer.Expect('range Closed GetFilters', 'Status: Gesloten BE');
        Observer.Expect('range Closed GetView', 'VERSION(1) SORTING(Id) WHERE(Status=FILTER(Gesloten BE))');
        Observer.Expect('range Closed GetView false', 'VERSION(1) SORTING(Field1) WHERE(Field2=1(1))');
        Observer.Expect('range Closed Count', '1');
        Observer.Expect('range Open..Closed GetFilter', 'Open BE..Gesloten BE');
        Observer.Expect('range Open..Closed Count', '3');
        Observer.Expect('filter %1|%2 GetFilter', 'Open BE|Gesloten BE');
        Observer.Expect('filter <>%1 GetFilter', '<>Gesloten BE');
        Observer.Expect('filter <>%1 GetFilters', 'Status: <>Gesloten BE');
        Observer.Expect('filter <>%1 Count', '2');
        Observer.Expect('mixed enu GetFilters', 'Mixed: Alpha BE, Enu: Green cap');
        Observer.Expect('mixed enu GetView', 'VERSION(1) SORTING(Id) WHERE(Mixed=FILTER(Alpha BE),Enu=FILTER(Green cap))');
        Observer.Expect('mixed Beta GetFilter', 'Beta plain');
        Observer.Expect('mixed Gamma GetFilter', 'Gamma');
        Observer.Expect('enu Red GetFilter', 'Red cap');
        Observer.Expect('flowfilter GetFilter', 'Gesloten BE');
        Observer.Expect('flowfilter GetFilters', 'Mixed: Gamma, Enu: Red cap, StatusFilter: Gesloten BE');
        Observer.Verify();
    end;

    // ---- 2/3. SetFilter and SetView with words
    local procedure FilterWords(var Observer: Codeunit "Probe Observer"; Lang: Integer; Which: Integer; Words: Text)
    var
        Row: Record "LT ECR Row";
        Tools: Codeunit "LT ECR Tools";
        WordList: List of [Text];
        Word: Text;
        Ok: Boolean;
    begin
        Seed();
        GlobalLanguage(Lang);
        WordList := Words.Split('#');
        foreach Word in WordList do begin
            Row.Reset();
            ClearLastError();
            case Which of
                1:
                    Ok := Tools.FilterStatus(Row, Word);
                2:
                    Ok := Tools.FilterMixed(Row, Word);
                3:
                    Ok := Tools.FilterEnu(Row, Word);
            end;
            if Ok then begin
                case Which of
                    1:
                        Observer.Observe('f ' + Word, 'ok|' + Row.GetFilter(Status) + '|' + Format(Row.Count()));
                    2:
                        Observer.Observe('f ' + Word, 'ok|' + Row.GetFilter(Mixed) + '|' + Format(Row.Count()));
                    3:
                        Observer.Observe('f ' + Word, 'ok|' + Row.GetFilter(Enu) + '|' + Format(Row.Count()));
                end;
            end else begin
                Observer.Observe('f ' + Word, 'err');
                Observer.ObserveError('f ' + Word);
            end;
        end;
        GlobalLanguage(1033);
    end;

    [Test]
    procedure ECR_FilterWordsStatus_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FilterWords(Observer, 1033, 1, 'Open#Closed#closed#Closed cap#closed cap#Gesloten BE#Open BE#1#Closed cap|Open cap#Closed|Open#*cap#Clo*#Closed cap..Open cap#<>Closed cap#>Open');
        Observer.Expect('f Open', 'ok|Open cap|2');
        Observer.Expect('f Closed', 'ok|Closed cap|1');
        Observer.Expect('f closed', 'ok|Closed cap|1');
        Observer.Expect('f Closed cap', 'ok|Closed cap|1');
        Observer.Expect('f closed cap', 'ok|Closed cap|1');
        Observer.Expect('f Gesloten BE', 'err');
        Observer.Expect('f Gesloten BE|text', 'The filter "Gesloten BE" is not valid for the Status field on the LT ECR Row table. ''Gesloten BE'' is not an option. The existing options are: Open cap,Closed cap');
        Observer.Expect('f Gesloten BE|code', 'Filter:CSide');
        Observer.Expect('f Open BE', 'err');
        Observer.Expect('f Open BE|text', 'The filter "Open BE" is not valid for the Status field on the LT ECR Row table. ''Open BE'' is not an option. The existing options are: Open cap,Closed cap');
        Observer.Expect('f Open BE|code', 'Filter:CSide');
        Observer.Expect('f 1', 'ok|Closed cap|1');
        Observer.Expect('f Closed cap|Open cap', 'ok|Closed cap|Open cap|3');
        Observer.Expect('f Closed|Open', 'ok|Closed cap|Open cap|3');
        Observer.Expect('f *cap', 'err');
        Observer.Expect('f *cap|text', 'The filter "*cap" is not valid for the Status field on the LT ECR Row table. ''*cap'' is not an option. The existing options are: Open cap,Closed cap');
        Observer.Expect('f *cap|code', 'Filter:CSide');
        Observer.Expect('f Clo*', 'err');
        Observer.Expect('f Clo*|text', 'The filter "Clo*" is not valid for the Status field on the LT ECR Row table. ''Clo*'' is not an option. The existing options are: Open cap,Closed cap');
        Observer.Expect('f Clo*|code', 'Filter:CSide');
        Observer.Expect('f Closed cap..Open cap', 'ok|Closed cap..Open cap|0');
        Observer.Expect('f <>Closed cap', 'ok|<>Closed cap|2');
        Observer.Expect('f >Open', 'ok|>Open cap|1');
        Observer.Verify();
    end;

    [Test]
    procedure ECR_FilterWordsStatus_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FilterWords(Observer, 2067, 1, 'Open#Closed#closed#Closed cap#Gesloten BE#gesloten be#Open BE#1#Gesloten BE|Open BE#Closed|Open#*BE#Ges*#Open BE..Gesloten BE#<>Gesloten BE#>Open');
        Observer.Expect('f Open', 'ok|Open BE|2');
        Observer.Expect('f Closed', 'ok|Gesloten BE|1');
        Observer.Expect('f closed', 'ok|Gesloten BE|1');
        Observer.Expect('f Closed cap', 'err');
        Observer.Expect('f Closed cap|text', 'Het filter "Closed cap" is niet geldig voor het veld Status in de tabel LT ECR Row. ''Closed cap'' is geen optie. De bestaande opties zijn: Open BE,Gesloten BE');
        Observer.Expect('f Closed cap|code', 'Filter:CSide');
        Observer.Expect('f Gesloten BE', 'ok|Gesloten BE|1');
        Observer.Expect('f gesloten be', 'ok|Gesloten BE|1');
        Observer.Expect('f Open BE', 'ok|Open BE|2');
        Observer.Expect('f 1', 'ok|Gesloten BE|1');
        Observer.Expect('f Gesloten BE|Open BE', 'ok|Gesloten BE|Open BE|3');
        Observer.Expect('f Closed|Open', 'ok|Gesloten BE|Open BE|3');
        Observer.Expect('f *BE', 'err');
        Observer.Expect('f *BE|text', 'Het filter "*BE" is niet geldig voor het veld Status in de tabel LT ECR Row. ''*BE'' is geen optie. De bestaande opties zijn: Open BE,Gesloten BE');
        Observer.Expect('f *BE|code', 'Filter:CSide');
        Observer.Expect('f Ges*', 'err');
        Observer.Expect('f Ges*|text', 'Het filter "Ges*" is niet geldig voor het veld Status in de tabel LT ECR Row. ''Ges*'' is geen optie. De bestaande opties zijn: Open BE,Gesloten BE');
        Observer.Expect('f Ges*|code', 'Filter:CSide');
        Observer.Expect('f Open BE..Gesloten BE', 'ok|Open BE..Gesloten BE|3');
        Observer.Expect('f <>Gesloten BE', 'ok|<>Gesloten BE|2');
        Observer.Expect('f >Open', 'ok|>Open BE|1');
        Observer.Verify();
    end;

    [Test]
    procedure ECR_FilterWordsMixed_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FilterWords(Observer, 1033, 2, 'Alpha#Alpha cap#Alpha BE#Beta#Beta plain#Gamma#Alpha cap|Beta plain#Alpha|Gamma#*plain#0');
        Observer.Expect('f Alpha', 'ok|Alpha cap|1');
        Observer.Expect('f Alpha cap', 'ok|Alpha cap|1');
        Observer.Expect('f Alpha BE', 'err');
        Observer.Expect('f Alpha BE|text', 'The filter "Alpha BE" is not valid for the Mixed field on the LT ECR Row table. ''Alpha BE'' is not an option. The existing options are: Alpha cap,Beta plain,Gamma');
        Observer.Expect('f Alpha BE|code', 'Filter:CSide');
        Observer.Expect('f Beta', 'ok|Beta plain|1');
        Observer.Expect('f Beta plain', 'ok|Beta plain|1');
        Observer.Expect('f Gamma', 'ok|Gamma|1');
        Observer.Expect('f Alpha cap|Beta plain', 'ok|Alpha cap|Beta plain|2');
        Observer.Expect('f Alpha|Gamma', 'ok|Alpha cap|Gamma|2');
        Observer.Expect('f *plain', 'err');
        Observer.Expect('f *plain|text', 'The filter "*plain" is not valid for the Mixed field on the LT ECR Row table. ''*plain'' is not an option. The existing options are: Alpha cap,Beta plain,Gamma');
        Observer.Expect('f *plain|code', 'Filter:CSide');
        Observer.Expect('f 0', 'ok|Alpha cap|1');
        Observer.Verify();
    end;

    [Test]
    procedure ECR_FilterWordsMixed_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FilterWords(Observer, 2067, 2, 'Alpha#Alpha cap#Alpha BE#Beta#Beta plain#Gamma#Alpha BE|Beta plain#Alpha|Gamma#*plain#0');
        Observer.Expect('f Alpha', 'ok|Alpha BE|1');
        Observer.Expect('f Alpha cap', 'err');
        Observer.Expect('f Alpha cap|text', 'Het filter "Alpha cap" is niet geldig voor het veld Mixed in de tabel LT ECR Row. ''Alpha cap'' is geen optie. De bestaande opties zijn: Alpha BE,Beta plain,Gamma');
        Observer.Expect('f Alpha cap|code', 'Filter:CSide');
        Observer.Expect('f Alpha BE', 'ok|Alpha BE|1');
        Observer.Expect('f Beta', 'ok|Beta plain|1');
        Observer.Expect('f Beta plain', 'ok|Beta plain|1');
        Observer.Expect('f Gamma', 'ok|Gamma|1');
        Observer.Expect('f Alpha BE|Beta plain', 'ok|Alpha BE|Beta plain|2');
        Observer.Expect('f Alpha|Gamma', 'ok|Alpha BE|Gamma|2');
        Observer.Expect('f *plain', 'err');
        Observer.Expect('f *plain|text', 'Het filter "*plain" is niet geldig voor het veld Mixed in de tabel LT ECR Row. ''*plain'' is geen optie. De bestaande opties zijn: Alpha BE,Beta plain,Gamma');
        Observer.Expect('f *plain|code', 'Filter:CSide');
        Observer.Expect('f 0', 'ok|Alpha BE|1');
        Observer.Verify();
    end;

    [Test]
    procedure ECR_FilterWordsEnuOnly_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FilterWords(Observer, 1033, 3, 'Red#Green#Red cap#Green cap#green cap#Red cap|Green cap#Red|Green#*cap#1');
        Observer.Expect('f Red', 'ok|Red cap|1');
        Observer.Expect('f Green', 'ok|Green cap|2');
        Observer.Expect('f Red cap', 'ok|Red cap|1');
        Observer.Expect('f Green cap', 'ok|Green cap|2');
        Observer.Expect('f green cap', 'ok|Green cap|2');
        Observer.Expect('f Red cap|Green cap', 'ok|Red cap|Green cap|3');
        Observer.Expect('f Red|Green', 'ok|Red cap|Green cap|3');
        Observer.Expect('f *cap', 'err');
        Observer.Expect('f *cap|text', 'The filter "*cap" is not valid for the Enu field on the LT ECR Row table. ''*cap'' is not an option. The existing options are: Red cap,Green cap');
        Observer.Expect('f *cap|code', 'Filter:CSide');
        Observer.Expect('f 1', 'ok|Green cap|2');
        Observer.Verify();
    end;

    [Test]
    procedure ECR_FilterWordsEnuOnly_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FilterWords(Observer, 2067, 3, 'Red#Green#Red cap#Green cap#green cap#Red cap|Green cap#Red|Green#*cap#1');
        Observer.Expect('f Red', 'ok|Red cap|1');
        Observer.Expect('f Green', 'ok|Green cap|2');
        Observer.Expect('f Red cap', 'ok|Red cap|1');
        Observer.Expect('f Green cap', 'ok|Green cap|2');
        Observer.Expect('f green cap', 'ok|Green cap|2');
        Observer.Expect('f Red cap|Green cap', 'ok|Red cap|Green cap|3');
        Observer.Expect('f Red|Green', 'ok|Red cap|Green cap|3');
        Observer.Expect('f *cap', 'err');
        Observer.Expect('f *cap|text', 'Het filter "*cap" is niet geldig voor het veld Enu in de tabel LT ECR Row. ''*cap'' is geen optie. De bestaande opties zijn: Red cap,Green cap');
        Observer.Expect('f *cap|code', 'Filter:CSide');
        Observer.Expect('f 1', 'ok|Green cap|2');
        Observer.Verify();
    end;

    local procedure ViewWords(var Observer: Codeunit "Probe Observer"; Lang: Integer; Views: Text)
    var
        Row: Record "LT ECR Row";
        Tools: Codeunit "LT ECR Tools";
        WordList: List of [Text];
        Word: Text;
    begin
        Seed();
        GlobalLanguage(Lang);
        WordList := Views.Split('#');
        foreach Word in WordList do begin
            Row.Reset();
            ClearLastError();
            if Tools.SetViewText(Row, Word) then
                Observer.Observe('v ' + Word, 'ok|' + Row.GetFilters() + '|' + Format(Row.Count()))
            else begin
                Observer.Observe('v ' + Word, 'err');
                Observer.ObserveError('v ' + Word);
            end;
        end;
        GlobalLanguage(1033);
    end;

    [Test]
    procedure ECR_ViewWords_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ViewWords(Observer, 1033, 'WHERE(Status=FILTER(Closed))#WHERE(Status=FILTER(Closed cap))#WHERE(Status=FILTER(Gesloten BE))#WHERE(Status=CONST(Closed cap))#WHERE(Status=CONST(1))#WHERE(Mixed=FILTER(Beta plain))');
        Observer.Expect('v WHERE(Status=FILTER(Closed))', 'ok|Status: Closed cap|1');
        Observer.Expect('v WHERE(Status=FILTER(Closed cap))', 'ok|Status: Closed cap|1');
        Observer.Expect('v WHERE(Status=FILTER(Gesloten BE))', 'err');
        Observer.Expect('v WHERE(Status=FILTER(Gesloten BE))|text', '''Gesloten BE'' is not an option. The existing options are: Open cap,Closed cap');
        Observer.Expect('v WHERE(Status=FILTER(Gesloten BE))|code', 'InvalidFilterExpression:InvalidOptionString');
        Observer.Expect('v WHERE(Status=CONST(Closed cap))', 'ok|Status: Closed cap|1');
        Observer.Expect('v WHERE(Status=CONST(1))', 'ok|Status: Closed cap|1');
        Observer.Expect('v WHERE(Mixed=FILTER(Beta plain))', 'ok|Mixed: Beta plain|1');
        Observer.Verify();
    end;

    [Test]
    procedure ECR_ViewWords_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ViewWords(Observer, 2067, 'WHERE(Status=FILTER(Closed))#WHERE(Status=FILTER(Closed cap))#WHERE(Status=FILTER(Gesloten BE))#WHERE(Status=CONST(Gesloten BE))#WHERE(Status=CONST(1))#WHERE(Mixed=FILTER(Alpha BE))');
        Observer.Expect('v WHERE(Status=FILTER(Closed))', 'ok|Status: Gesloten BE|1');
        Observer.Expect('v WHERE(Status=FILTER(Closed cap))', 'err');
        Observer.Expect('v WHERE(Status=FILTER(Closed cap))|text', '''Closed cap'' is geen optie. De bestaande opties zijn: Open BE,Gesloten BE');
        Observer.Expect('v WHERE(Status=FILTER(Closed cap))|code', 'InvalidFilterExpression:InvalidOptionString');
        Observer.Expect('v WHERE(Status=FILTER(Gesloten BE))', 'ok|Status: Gesloten BE|1');
        Observer.Expect('v WHERE(Status=CONST(Gesloten BE))', 'ok|Status: Gesloten BE|1');
        Observer.Expect('v WHERE(Status=CONST(1))', 'ok|Status: Gesloten BE|1');
        Observer.Expect('v WHERE(Mixed=FILTER(Alpha BE))', 'ok|Mixed: Alpha BE|1');
        Observer.Verify();
    end;

    // ---- 4. TableRelation and CalcFormula
    local procedure Relations(var Observer: Codeunit "Probe Observer"; Lang: Integer; Words: Text)
    var
        Row: Record "LT ECR Row";
        Rel: Record "LT ECR Rel";
        Tools: Codeunit "LT ECR Tools";
        WordList: List of [Text];
        Word: Text;
    begin
        Seed();
        Commit();
        GlobalLanguage(Lang);
        Row.CalcFields(ClosedCount, OpenOrClosedCount);
        Observer.Observe('const Closed count', Format(Row.ClosedCount));
        Observer.Observe('filter Open|Closed count', Format(Row.OpenOrClosedCount));
        Rel.DeleteAll();
        Rel.Init();
        Rel.Id := 1;
        Rel.Insert();
        Commit();
        Rel.Validate(ClosedRef, 1);
        asserterror Rel.Validate(ClosedRef, 2);
        Observer.ObserveError('relation Closed row 2');
        asserterror Rel.Validate(AnyRef, 4);
        Observer.ObserveError('relation Any row 4');
        WordList := Words.Split('#');
        foreach Word in WordList do begin
            Row.Reset();
            ClearLastError();
            if Tools.FilterFlow(Row, Word) then begin
                Row.CalcFields(MatchCount);
                Observer.Observe('flow ' + Word, 'ok|' + Row.GetFilter(StatusFilter) + '|' + Format(Row.MatchCount));
            end else begin
                Observer.Observe('flow ' + Word, 'err');
                Observer.ObserveError('flow ' + Word);
            end;
        end;
        GlobalLanguage(1033);
    end;

    [Test]
    procedure ECR_Relations_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Relations(Observer, 1033, 'Closed#Closed cap#Gesloten BE#Open cap|Closed cap#1');
        Observer.Expect('const Closed count', '1');
        Observer.Expect('filter Open|Closed count', '3');
        Observer.Expect('relation Closed row 2|text', 'The field ClosedRef of table LT ECR Rel contains a value (2) that cannot be found in the related table (LT ECR Row).');
        Observer.Expect('relation Closed row 2|code', 'DB:NothingInsideFilter');
        Observer.Expect('relation Any row 4|text', 'The field AnyRef of table LT ECR Rel contains a value (4) that cannot be found in the related table (LT ECR Row).');
        Observer.Expect('relation Any row 4|code', 'DB:NothingInsideFilter');
        Observer.Expect('flow Closed', 'ok|Closed cap|1');
        Observer.Expect('flow Closed cap', 'ok|Closed cap|1');
        Observer.Expect('flow Gesloten BE', 'err');
        Observer.Expect('flow Gesloten BE|text', 'The filter "Gesloten BE" is not valid for the StatusFilter field on the LT ECR Row table. ''Gesloten BE'' is not an option. The existing options are: Open cap,Closed cap');
        Observer.Expect('flow Gesloten BE|code', 'Filter:CSide');
        Observer.Expect('flow Open cap|Closed cap', 'ok|Open cap|Closed cap|3');
        Observer.Expect('flow 1', 'ok|Closed cap|1');
        Observer.Verify();
    end;

    [Test]
    procedure ECR_Relations_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Relations(Observer, 2067, 'Closed#Closed cap#Gesloten BE#Open BE|Gesloten BE#1');
        Observer.Expect('const Closed count', '1');
        Observer.Expect('filter Open|Closed count', '3');
        Observer.Expect('relation Closed row 2|text', 'Het veld ClosedRef van tabel LT ECR Rel bevat een waarde (2) die niet is gevonden in de gerelateerde tabel (LT ECR Row).');
        Observer.Expect('relation Closed row 2|code', 'DB:NothingInsideFilter');
        Observer.Expect('relation Any row 4|text', 'Het veld AnyRef van tabel LT ECR Rel bevat een waarde (4) die niet is gevonden in de gerelateerde tabel (LT ECR Row).');
        Observer.Expect('relation Any row 4|code', 'DB:NothingInsideFilter');
        Observer.Expect('flow Closed', 'ok|Gesloten BE|1');
        Observer.Expect('flow Closed cap', 'err');
        Observer.Expect('flow Closed cap|text', 'Het filter "Closed cap" is niet geldig voor het veld StatusFilter in de tabel LT ECR Row. ''Closed cap'' is geen optie. De bestaande opties zijn: Open BE,Gesloten BE');
        Observer.Expect('flow Closed cap|code', 'Filter:CSide');
        Observer.Expect('flow Gesloten BE', 'ok|Gesloten BE|1');
        Observer.Expect('flow Open BE|Gesloten BE', 'ok|Open BE|Gesloten BE|3');
        Observer.Expect('flow 1', 'ok|Gesloten BE|1');
        Observer.Verify();
    end;

    // ---- 5. FieldRef OptionCaption, OptionMembers
    local procedure FieldRefs(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        RecRef: RecordRef;
        Ref: FieldRef;
        Tools: Codeunit "LT ECR Tools";
        i: Integer;
        Names: List of [Text];
        Word: Text;
    begin
        Seed();
        GlobalLanguage(Lang);
        RecRef.Open(Database::"LT ECR Row");
        RecRef.FindFirst();
        for i := 2 to 4 do begin
            Ref := RecRef.Field(i);
            Observer.Observe('f' + Format(i) + ' Type', Format(Ref.Type()));
            Observer.Observe('f' + Format(i) + ' OptionCaption', Ref.OptionCaption());
            Observer.Observe('f' + Format(i) + ' OptionMembers', Ref.OptionMembers());
            Observer.Observe('f' + Format(i) + ' Value', Format(Ref.Value()));
            Observer.Observe('f' + Format(i) + ' Value int', Format(Ref.Value(), 0, 2));
            Observer.Observe('f' + Format(i) + ' Caption', Ref.Caption());
        end;
        Ref := RecRef.Field(2);
        Ref.SetRange(Ref.Value());
        Observer.Observe('SetRange GetFilter', Ref.GetFilter());
        Names.AddRange('Closed', 'Closed cap', 'Gesloten BE');
        foreach Word in Names do begin
            ClearLastError();
            if Tools.FilterRef(Ref, Word) then
                Observer.Observe('FieldRef.SetFilter ' + Word, 'ok|' + Ref.GetFilter() + '|' + Format(RecRef.Count()))
            else begin
                Observer.Observe('FieldRef.SetFilter ' + Word, 'err');
                Observer.ObserveError('FieldRef.SetFilter ' + Word);
            end;
        end;
        RecRef.Close();
        GlobalLanguage(1033);
    end;

    [Test]
    procedure ECR_FieldRefs_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FieldRefs(Observer, 1033);
        Observer.Expect('f2 Type', 'Option');
        Observer.Expect('f2 OptionCaption', 'Open cap,Closed cap');
        Observer.Expect('f2 OptionMembers', 'Open,Closed');
        Observer.Expect('f2 Value', 'Closed cap');
        Observer.Expect('f2 Value int', '1');
        Observer.Expect('f2 Caption', 'Status');
        Observer.Expect('f3 Type', 'Option');
        Observer.Expect('f3 OptionCaption', 'Alpha cap,Beta plain,Gamma');
        Observer.Expect('f3 OptionMembers', 'Alpha,Beta,Gamma');
        Observer.Expect('f3 Value', 'Alpha cap');
        Observer.Expect('f3 Value int', '0');
        Observer.Expect('f3 Caption', 'Mixed');
        Observer.Expect('f4 Type', 'Option');
        Observer.Expect('f4 OptionCaption', 'Red cap,Green cap');
        Observer.Expect('f4 OptionMembers', 'Red,Green');
        Observer.Expect('f4 Value', 'Green cap');
        Observer.Expect('f4 Value int', '1');
        Observer.Expect('f4 Caption', 'Enu');
        Observer.Expect('SetRange GetFilter', 'Closed cap');
        Observer.Expect('FieldRef.SetFilter Closed', 'ok|Closed cap|1');
        Observer.Expect('FieldRef.SetFilter Closed cap', 'ok|Closed cap|1');
        Observer.Expect('FieldRef.SetFilter Gesloten BE', 'err');
        Observer.Expect('FieldRef.SetFilter Gesloten BE|text', 'The filter "Gesloten BE" is not valid for the Status field on the LT ECR Row table. ''Gesloten BE'' is not an option. The existing options are: Open cap,Closed cap');
        Observer.Expect('FieldRef.SetFilter Gesloten BE|code', 'Filter:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure ECR_FieldRefs_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FieldRefs(Observer, 2067);
        Observer.Expect('f2 Type', 'Option');
        Observer.Expect('f2 OptionCaption', 'Open BE,Gesloten BE');
        Observer.Expect('f2 OptionMembers', 'Open,Closed');
        Observer.Expect('f2 Value', 'Gesloten BE');
        Observer.Expect('f2 Value int', '1');
        Observer.Expect('f2 Caption', 'Status');
        Observer.Expect('f3 Type', 'Option');
        Observer.Expect('f3 OptionCaption', 'Alpha BE,Beta plain,Gamma');
        Observer.Expect('f3 OptionMembers', 'Alpha,Beta,Gamma');
        Observer.Expect('f3 Value', 'Alpha BE');
        Observer.Expect('f3 Value int', '0');
        Observer.Expect('f3 Caption', 'Mixed');
        Observer.Expect('f4 Type', 'Option');
        Observer.Expect('f4 OptionCaption', 'Red cap,Green cap');
        Observer.Expect('f4 OptionMembers', 'Red,Green');
        Observer.Expect('f4 Value', 'Green cap');
        Observer.Expect('f4 Value int', '1');
        Observer.Expect('f4 Caption', 'Enu');
        Observer.Expect('SetRange GetFilter', 'Gesloten BE');
        Observer.Expect('FieldRef.SetFilter Closed', 'ok|Gesloten BE|1');
        Observer.Expect('FieldRef.SetFilter Closed cap', 'err');
        Observer.Expect('FieldRef.SetFilter Closed cap|text', 'Het filter "Closed cap" is niet geldig voor het veld Status in de tabel LT ECR Row. ''Closed cap'' is geen optie. De bestaande opties zijn: Open BE,Gesloten BE');
        Observer.Expect('FieldRef.SetFilter Closed cap|code', 'Filter:CSide');
        Observer.Expect('FieldRef.SetFilter Gesloten BE', 'ok|Gesloten BE|1');
        Observer.Verify();
    end;

    local procedure FieldRefValue(var Observer: Codeunit "Probe Observer"; Lang: Integer; Words: Text)
    var
        RecRef: RecordRef;
        Ref: FieldRef;
        Tools: Codeunit "LT ECR Tools";
        WordList: List of [Text];
        Word: Text;
    begin
        Seed();
        GlobalLanguage(Lang);
        RecRef.Open(Database::"LT ECR Row");
        RecRef.FindFirst();
        Ref := RecRef.Field(2);
        WordList := Words.Split('#');
        foreach Word in WordList do begin
            ClearLastError();
            if Tools.SetRefValue(Ref, Word) then
                Observer.Observe('FieldRef.Value := ' + Word, 'ok|' + Format(Ref.Value(), 0, 2))
            else begin
                Observer.Observe('FieldRef.Value := ' + Word, 'err');
                Observer.ObserveError('FieldRef.Value := ' + Word);
            end;
            Ref.Value := 0;
        end;
        RecRef.Close();
        GlobalLanguage(1033);
    end;

    [Test]
    procedure ECR_FieldRefValue_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FieldRefValue(Observer, 1033, 'Closed#Closed cap#Gesloten BE#1');
        Observer.Expect('FieldRef.Value := Closed', 'err');
#if BC28PLUS
        Observer.Expect('FieldRef.Value := Closed|text', 'The value "Closed" can''t be evaluated into type Option.');
#else
        // BC 27.5 names the internal type instead (measured on the corpus CI 27.5 leg).
        Observer.Expect('FieldRef.Value := Closed|text', 'The type NavOption is unknown.');
#endif
        Observer.Expect('FieldRef.Value := Closed|code', 'Evaluate:Format');
        Observer.Expect('FieldRef.Value := Closed cap', 'err');
#if BC28PLUS
        Observer.Expect('FieldRef.Value := Closed cap|text', 'The value "Closed cap" can''t be evaluated into type Option.');
#else
        // BC 27.5 names the internal type instead (measured on the corpus CI 27.5 leg).
        Observer.Expect('FieldRef.Value := Closed cap|text', 'The type NavOption is unknown.');
#endif
        Observer.Expect('FieldRef.Value := Closed cap|code', 'Evaluate:Format');
        Observer.Expect('FieldRef.Value := Gesloten BE', 'err');
#if BC28PLUS
        Observer.Expect('FieldRef.Value := Gesloten BE|text', 'The value "Gesloten BE" can''t be evaluated into type Option.');
#else
        // BC 27.5 names the internal type instead (measured on the corpus CI 27.5 leg).
        Observer.Expect('FieldRef.Value := Gesloten BE|text', 'The type NavOption is unknown.');
#endif
        Observer.Expect('FieldRef.Value := Gesloten BE|code', 'Evaluate:Format');
        Observer.Expect('FieldRef.Value := 1', 'ok|1');
        Observer.Verify();
    end;

    [Test]
    procedure ECR_FieldRefValue_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FieldRefValue(Observer, 2067, 'Closed#Closed cap#Gesloten BE#1');
        Observer.Expect('FieldRef.Value := Closed', 'err');
#if BC28PLUS
        Observer.Expect('FieldRef.Value := Closed|text', 'De waarde "Closed" kan niet worden geëvalueerd tot type Option.');
#else
        // BC 27.5 names the internal type instead (measured on the corpus CI 27.5 leg).
        Observer.Expect('FieldRef.Value := Closed|text', 'Het type NavOption is onbekend.');
#endif
        Observer.Expect('FieldRef.Value := Closed|code', 'Evaluate:Format');
        Observer.Expect('FieldRef.Value := Closed cap', 'err');
#if BC28PLUS
        Observer.Expect('FieldRef.Value := Closed cap|text', 'De waarde "Closed cap" kan niet worden geëvalueerd tot type Option.');
#else
        // BC 27.5 names the internal type instead (measured on the corpus CI 27.5 leg).
        Observer.Expect('FieldRef.Value := Closed cap|text', 'Het type NavOption is onbekend.');
#endif
        Observer.Expect('FieldRef.Value := Closed cap|code', 'Evaluate:Format');
        Observer.Expect('FieldRef.Value := Gesloten BE', 'err');
#if BC28PLUS
        Observer.Expect('FieldRef.Value := Gesloten BE|text', 'De waarde "Gesloten BE" kan niet worden geëvalueerd tot type Option.');
#else
        // BC 27.5 names the internal type instead (measured on the corpus CI 27.5 leg).
        Observer.Expect('FieldRef.Value := Gesloten BE|text', 'Het type NavOption is onbekend.');
#endif
        Observer.Expect('FieldRef.Value := Gesloten BE|code', 'Evaluate:Format');
        Observer.Expect('FieldRef.Value := 1', 'ok|1');
        Observer.Verify();
    end;

    // ---- 6. TestField and FieldError texts
    local procedure TestFields(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Row: Record "LT ECR Row";
    begin
        Seed();
        Commit();
        GlobalLanguage(Lang);
        Row.Get(2);
        asserterror Row.TestField(Status, Row.Status::Closed);
        Observer.ObserveError('TestField Status Closed on Open');
        asserterror Row.TestField(Status);
        Observer.ObserveError('TestField Status blank');
        asserterror Row.TestField(Mixed, Row.Mixed::Alpha);
        Observer.ObserveError('TestField Mixed Alpha on Beta');
        asserterror Row.TestField(Enu, Row.Enu::Green);
        Observer.ObserveError('TestField Enu Green on Red');
        Row.Get(3);
        asserterror Row.TestField(Mixed, Row.Mixed::Alpha);
        Observer.ObserveError('TestField Mixed Alpha on Gamma');
        asserterror Row.FieldError(Status);
        Observer.ObserveError('FieldError Status');
        asserterror Row.FieldError(Status, 'custom');
        Observer.ObserveError('FieldError Status custom');
        asserterror Row.FieldError(Enu);
        Observer.ObserveError('FieldError Enu');
        Row.Get(1);
        asserterror Row.TestField(Status, Row.Status::Open);
        Observer.ObserveError('TestField Status Open on Closed');
        asserterror Row.TestField(Enu, Row.Enu::Red);
        Observer.ObserveError('TestField Enu Red on Green');
        GlobalLanguage(1033);
    end;

    [Test]
    procedure ECR_TestFields_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TestFields(Observer, 1033);
        Observer.Expect('TestField Status Closed on Open|text', 'Status must be equal to ''Closed cap''  in LT ECR Row: Id=2. Current value is ''Open cap''.');
        Observer.Expect('TestField Status Closed on Open|code', 'TestField');
        Observer.Expect('TestField Status blank|text', 'Status must not be Open cap in LT ECR Row: Id=2');
        Observer.Expect('TestField Status blank|code', 'TestField');
        Observer.Expect('TestField Mixed Alpha on Beta|text', 'Mixed must be equal to ''Alpha cap''  in LT ECR Row: Id=2. Current value is ''Beta plain''.');
        Observer.Expect('TestField Mixed Alpha on Beta|code', 'TestField');
        Observer.Expect('TestField Enu Green on Red|text', 'Enu must be equal to ''Green cap''  in LT ECR Row: Id=2. Current value is ''Red cap''.');
        Observer.Expect('TestField Enu Green on Red|code', 'TestField');
        Observer.Expect('TestField Mixed Alpha on Gamma|text', 'Mixed must be equal to ''Alpha cap''  in LT ECR Row: Id=3. Current value is ''Gamma''.');
        Observer.Expect('TestField Mixed Alpha on Gamma|code', 'TestField');
        Observer.Expect('FieldError Status|text', 'Status must not be Open cap in LT ECR Row Id=''3''.');
        Observer.Expect('FieldError Status|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('FieldError Status custom|text', 'Status custom in LT ECR Row Id=''3''.');
        Observer.Expect('FieldError Status custom|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('FieldError Enu|text', 'Enu must not be Green cap in LT ECR Row Id=''3''.');
        Observer.Expect('FieldError Enu|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('TestField Status Open on Closed|text', 'Status must be equal to ''Open cap''  in LT ECR Row: Id=1. Current value is ''Closed cap''.');
        Observer.Expect('TestField Status Open on Closed|code', 'TestField');
        Observer.Expect('TestField Enu Red on Green|text', 'Enu must be equal to ''Red cap''  in LT ECR Row: Id=1. Current value is ''Green cap''.');
        Observer.Expect('TestField Enu Red on Green|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure ECR_TestFields_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TestFields(Observer, 2067);
        Observer.Expect('TestField Status Closed on Open|text', 'Status moet gelijk zijn aan Gesloten BE in LT ECR Row: Id=2. De huidige waarde is Open BE.');
        Observer.Expect('TestField Status Closed on Open|code', 'TestField');
        Observer.Expect('TestField Status blank|text', 'Status mag niet Open BE zijn in LT ECR Row: Id=2');
        Observer.Expect('TestField Status blank|code', 'TestField');
        Observer.Expect('TestField Mixed Alpha on Beta|text', 'Mixed moet gelijk zijn aan Alpha BE in LT ECR Row: Id=2. De huidige waarde is Beta plain.');
        Observer.Expect('TestField Mixed Alpha on Beta|code', 'TestField');
        Observer.Expect('TestField Enu Green on Red|text', 'Enu moet gelijk zijn aan Green cap in LT ECR Row: Id=2. De huidige waarde is Red cap.');
        Observer.Expect('TestField Enu Green on Red|code', 'TestField');
        Observer.Expect('TestField Mixed Alpha on Gamma|text', 'Mixed moet gelijk zijn aan Alpha BE in LT ECR Row: Id=3. De huidige waarde is Gamma.');
        Observer.Expect('TestField Mixed Alpha on Gamma|code', 'TestField');
        Observer.Expect('FieldError Status|text', 'Status mag niet Open BE zijn in LT ECR Row Id=''3''.');
        Observer.Expect('FieldError Status|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('FieldError Status custom|text', 'Status custom in LT ECR Row Id=''3''.');
        Observer.Expect('FieldError Status custom|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('FieldError Enu|text', 'Enu mag niet Green cap zijn in LT ECR Row Id=''3''.');
        Observer.Expect('FieldError Enu|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('TestField Status Open on Closed|text', 'Status moet gelijk zijn aan Open BE in LT ECR Row: Id=1. De huidige waarde is Gesloten BE.');
        Observer.Expect('TestField Status Open on Closed|code', 'TestField');
        Observer.Expect('TestField Enu Red on Green|text', 'Enu moet gelijk zijn aan Red cap in LT ECR Row: Id=1. De huidige waarde is Green cap.');
        Observer.Expect('TestField Enu Red on Green|code', 'TestField');
        Observer.Verify();
    end;

    // ---- 7. key values of an enum key
    local procedure KeyValues(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Keyed: Record "LT ECR Keyed";
        RecRef: RecordRef;
        KeyRef: KeyRef;
        Ref: FieldRef;
        Tools: Codeunit "LT ECR Tools";
        Pos: Text;
        Words: List of [Text];
        Word: Text;
    begin
        GlobalLanguage(1033);
        Keyed.DeleteAll();
        GlobalLanguage(Lang);
        Keyed.Init();
        Keyed.Status := Keyed.Status::Closed;
        Keyed.Enu := Keyed.Enu::Green;
        Keyed.Insert();
        Observer.Observe('RecordId', Format(Keyed.RecordId()));
        Observer.Observe('GetPosition', Keyed.GetPosition());
        Observer.Observe('GetPosition false', Keyed.GetPosition(false));
        Observer.Observe('Rec text', Format(Keyed));
        RecRef.GetTable(Keyed);
        Observer.Observe('RecRef GetPosition', RecRef.GetPosition());
        KeyRef := RecRef.KeyIndex(1);
        Observer.Observe('KeyRef count', Format(KeyRef.FieldCount()));
        Ref := KeyRef.FieldIndex(1);
        Observer.Observe('KeyRef 1 Value', Format(Ref.Value()));
        Observer.Observe('KeyRef 1 Value 2', Format(Ref.Value(), 0, 2));
        Observer.Observe('KeyRef 1 Name', Ref.Name());
        Ref := KeyRef.FieldIndex(2);
        Observer.Observe('KeyRef 2 Value', Format(Ref.Value()));
        Observer.Observe('Key text', Keyed.CurrentKey());
        Pos := RecRef.GetPosition();
        Words.AddRange(Pos, 'Status=CONST(Closed),Enu=CONST(Green)', 'Status=CONST(Closed cap),Enu=CONST(Green cap)', 'Status=CONST(Gesloten BE),Enu=CONST(Green cap)', 'Status=CONST(1),Enu=CONST(1)');
        foreach Word in Words do begin
            ClearLastError();
            Clear(RecRef);
            RecRef.Open(Database::"LT ECR Keyed");
            if Tools.SetPos(RecRef, Word) then begin
                Observer.Observe('SetPosition ' + Word, 'ok|' + RecRef.GetPosition());
                Observer.Observe('SetPosition ' + Word + ' Get', Format(RecRef.Get(RecRef.RecordId()), 0, 9));
            end else begin
                Observer.Observe('SetPosition ' + Word, 'err');
                Observer.ObserveError('SetPosition ' + Word);
            end;
        end;
        GlobalLanguage(1033);
    end;

    [Test]
    procedure ECR_KeyValues_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        KeyValues(Observer, 1033);
        Observer.Expect('RecordId', 'LT ECR Keyed: Closed cap,Green cap');
        Observer.Expect('GetPosition', 'Status=CONST(Closed),Enu=CONST(Green)');
        Observer.Expect('GetPosition false', 'Field1=0(1),Field2=0(1)');
        Observer.Expect('Rec text', 'Closed cap\tGreen cap\t');
        Observer.Expect('RecRef GetPosition', 'Status=CONST(Closed),Enu=CONST(Green)');
        Observer.Expect('KeyRef count', '2');
        Observer.Expect('KeyRef 1 Value', 'Closed cap');
        Observer.Expect('KeyRef 1 Value 2', '1');
        Observer.Expect('KeyRef 1 Name', 'Status');
        Observer.Expect('KeyRef 2 Value', 'Green cap');
        Observer.Expect('Key text', 'Status,Enu');
        Observer.Expect('SetPosition Status=CONST(Closed),Enu=CONST(Green)', 'ok|Status=CONST(Closed),Enu=CONST(Green)');
        Observer.Expect('SetPosition Status=CONST(Closed),Enu=CONST(Green) Get', 'true');
        Observer.Expect('SetPosition Status=CONST(Closed),Enu=CONST(Green)', 'ok|Status=CONST(Closed),Enu=CONST(Green)');
        Observer.Expect('SetPosition Status=CONST(Closed),Enu=CONST(Green) Get', 'true');
        Observer.Expect('SetPosition Status=CONST(Closed cap),Enu=CONST(Green cap)', 'ok|Status=CONST(Closed),Enu=CONST(Green)');
        Observer.Expect('SetPosition Status=CONST(Closed cap),Enu=CONST(Green cap) Get', 'true');
        Observer.Expect('SetPosition Status=CONST(Gesloten BE),Enu=CONST(Green cap)', 'err');
        Observer.Expect('SetPosition Status=CONST(Gesloten BE),Enu=CONST(Green cap)|text', '''Gesloten BE'' is not an option. The existing options are: Open cap,Closed cap');
        Observer.Expect('SetPosition Status=CONST(Gesloten BE),Enu=CONST(Green cap)|code', 'InvalidOptionString');
        Observer.Expect('SetPosition Status=CONST(1),Enu=CONST(1)', 'ok|Status=CONST(Closed),Enu=CONST(Green)');
        Observer.Expect('SetPosition Status=CONST(1),Enu=CONST(1) Get', 'true');
        Observer.Verify();
    end;

    [Test]
    procedure ECR_KeyValues_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        KeyValues(Observer, 2067);
        Observer.Expect('RecordId', 'LT ECR Keyed: Gesloten BE,Green cap');
        Observer.Expect('GetPosition', 'Status=CONST(Closed),Enu=CONST(Green)');
        Observer.Expect('GetPosition false', 'Field1=0(1),Field2=0(1)');
        Observer.Expect('Rec text', 'Gesloten BE\tGreen cap\t');
        Observer.Expect('RecRef GetPosition', 'Status=CONST(Closed),Enu=CONST(Green)');
        Observer.Expect('KeyRef count', '2');
        Observer.Expect('KeyRef 1 Value', 'Gesloten BE');
        Observer.Expect('KeyRef 1 Value 2', '1');
        Observer.Expect('KeyRef 1 Name', 'Status');
        Observer.Expect('KeyRef 2 Value', 'Green cap');
        Observer.Expect('Key text', 'Status,Enu');
        Observer.Expect('SetPosition Status=CONST(Closed),Enu=CONST(Green)', 'ok|Status=CONST(Closed),Enu=CONST(Green)');
        Observer.Expect('SetPosition Status=CONST(Closed),Enu=CONST(Green) Get', 'true');
        Observer.Expect('SetPosition Status=CONST(Closed),Enu=CONST(Green)', 'ok|Status=CONST(Closed),Enu=CONST(Green)');
        Observer.Expect('SetPosition Status=CONST(Closed),Enu=CONST(Green) Get', 'true');
        Observer.Expect('SetPosition Status=CONST(Closed cap),Enu=CONST(Green cap)', 'err');
        Observer.Expect('SetPosition Status=CONST(Closed cap),Enu=CONST(Green cap)|text', '''Closed cap'' is geen optie. De bestaande opties zijn: Open BE,Gesloten BE');
        Observer.Expect('SetPosition Status=CONST(Closed cap),Enu=CONST(Green cap)|code', 'InvalidOptionString');
        Observer.Expect('SetPosition Status=CONST(Gesloten BE),Enu=CONST(Green cap)', 'ok|Status=CONST(Closed),Enu=CONST(Green)');
        Observer.Expect('SetPosition Status=CONST(Gesloten BE),Enu=CONST(Green cap) Get', 'true');
        Observer.Expect('SetPosition Status=CONST(1),Enu=CONST(1)', 'ok|Status=CONST(Closed),Enu=CONST(Green)');
        Observer.Expect('SetPosition Status=CONST(1),Enu=CONST(1) Get', 'true');
        Observer.Verify();
    end;

    // ---- 8. list page column
    local procedure ListValues(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        List: TestPage "LT ECR List";
        Count: Integer;
    begin
        Seed();
        GlobalLanguage(Lang);
        List.OpenView();
        if List.First() then
            repeat
                Count += 1;
                Observer.Observe('row' + Format(Count), List.Id.Value() + '|' + List.Status.Value() + '|' + List.Mixed.Value() + '|' + List.Enu.Value());
            until not List.Next();
        List.Close();
        List.OpenView();
        List.Filter.SetFilter(Status, 'Closed');
        Observer.Observe('Filter Closed first', List.Id.Value());
        Observer.Observe('Filter Closed next', Format(List.Next(), 0, 9));
        List.Close();
        GlobalLanguage(1033);
    end;

    local procedure ListFilter(var Observer: Codeunit "Probe Observer"; Lang: Integer; Words: Text)
    var
        List: TestPage "LT ECR List";
        WordList: List of [Text];
        Word: Text;
        Rows: Integer;
    begin
        Seed();
        GlobalLanguage(Lang);
        WordList := Words.Split('#');
        foreach Word in WordList do begin
            List.OpenView();
            ClearLastError();
            Rows := 0;
            if ListFilterTry(List, Word) then begin
                if List.First() then
                    repeat
                        Rows += 1;
                    until not List.Next();
                Observer.Observe('list filter ' + Word, 'ok|' + Format(Rows));
            end else begin
                Observer.Observe('list filter ' + Word, 'err');
                Observer.ObserveError('list filter ' + Word);
            end;
            List.Close();
        end;
        GlobalLanguage(1033);
    end;

    [TryFunction]
    local procedure ListFilterTry(var List: TestPage "LT ECR List"; Word: Text)
    begin
        List.Filter.SetFilter(Status, Word);
    end;

    [Test]
    procedure ECR_ListValues_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ListValues(Observer, 1033);
        Observer.Expect('row1', '1|Closed cap|Alpha cap|Green cap');
        Observer.Expect('row2', '2|Open cap|Beta plain|Red cap');
        Observer.Expect('row3', '3|Open cap|Gamma|Green cap');
        Observer.Expect('Filter Closed first', '1');
        Observer.Expect('Filter Closed next', 'true');
        Observer.Verify();
    end;

    [Test]
    procedure ECR_ListValues_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ListValues(Observer, 2067);
        Observer.Expect('row1', '1|Gesloten BE|Alpha BE|Green cap');
        Observer.Expect('row2', '2|Open BE|Beta plain|Red cap');
        Observer.Expect('row3', '3|Open BE|Gamma|Green cap');
        Observer.Expect('Filter Closed first', '1');
        Observer.Expect('Filter Closed next', 'true');
        Observer.Verify();
    end;

    [Test]
    procedure ECR_ListFilter_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ListFilter(Observer, 1033, 'Closed#Closed cap#Gesloten BE#Open cap|Closed cap');
        Observer.Expect('list filter Closed', 'ok|3');
        Observer.Expect('list filter Closed cap', 'ok|1');
        Observer.Expect('list filter Gesloten BE', 'ok|3');
        Observer.Expect('list filter Open cap|Closed cap', 'ok|3');
        Observer.Verify();
    end;

    [Test]
    procedure ECR_ListFilter_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ListFilter(Observer, 2067, 'Closed#Closed cap#Gesloten BE#Open BE|Gesloten BE');
        Observer.Expect('list filter Closed', 'ok|3');
        Observer.Expect('list filter Closed cap', 'ok|3');
        Observer.Expect('list filter Gesloten BE', 'ok|1');
        Observer.Expect('list filter Open BE|Gesloten BE', 'ok|3');
        Observer.Verify();
    end;
}
