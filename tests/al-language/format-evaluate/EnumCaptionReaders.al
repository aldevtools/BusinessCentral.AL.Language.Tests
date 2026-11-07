// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-enum-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 97900-97939 (LT ECR ...)
// Probe: from al-runner issue 6924 (waldo) follow-up: enum values with CaptionML, read through every reader other than Format and Evaluate
//   (those are pinned in EvalLanguageBoolean.al): TestPage enum control (Value, SetValue, ValidateValue), GetFilter, GetFilters, GetView, SetFilter with
//   the caption, the name and the other language's caption, TableRelation and CalcFormula filters, FieldRef OptionCaption and OptionMembers,
//   TestField and FieldError texts, key values (RecordId, GetPosition, KeyRef), list page columns. Under GlobalLanguage 1033 and 2067, for an enum
//   with CaptionML on every value, an enum that mixes CaptionML, Caption and no caption, and an enum with an ENU-only CaptionML.
// Facts: see the pinned values.
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

// Observe-only helper of this draft (same calls as Probe Observer).
codeunit 97908 "LT ECR Obs"
{
    var
        Pairs: Text;

    procedure Observe(ObservedName: Text; ObservedValue: Text)
    var
        Rs: Text[1];
        Us: Text[1];
        Cr: Text[1];
        Lf: Text[1];
        Tab: Text[1];
    begin
        Rs[1] := 9246;
        Us[1] := 9247;
        Cr[1] := 13;
        Lf[1] := 10;
        Tab[1] := 9;
        Pairs += ObservedName + Us + ObservedValue.Replace(Rs, '?').Replace(Us, '?').Replace(Cr, '\r').Replace(Lf, '\n').Replace(Tab, '\t') + Rs;
    end;

    procedure ObserveError(ObservedName: Text)
    begin
        Observe(ObservedName + '|text', GetLastErrorText());
        Observe(ObservedName + '|code', GetLastErrorCode());
        ClearLastError();
    end;

    procedure Finish()
    begin
        Error('OBSERVE:%1', Pairs);
    end;
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
    local procedure CardValue(var Observer: Codeunit "LT ECR Obs"; Lang: Integer)
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
        Observer: Codeunit "LT ECR Obs";
    begin
        CardValue(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure ECR_CardValue_2067()
    var
        Observer: Codeunit "LT ECR Obs";
    begin
        CardValue(Observer, 2067);
        Observer.Finish();
    end;

    // ---- 1. TestPage SetValue / ValidateValue by words
    local procedure CardSet(var Observer: Codeunit "LT ECR Obs"; Lang: Integer; Which: Integer; Validate: Boolean; Words: Text)
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
        Observer: Codeunit "LT ECR Obs";
    begin
        CardSet(Observer, 1033, 1, false, 'Open|Closed|closed|Closed cap|closed cap|Gesloten BE|Open BE|1');
        Observer.Finish();
    end;

    [Test]
    procedure ECR_CardSetStatus_2067()
    var
        Observer: Codeunit "LT ECR Obs";
    begin
        CardSet(Observer, 2067, 1, false, 'Open|Closed|closed|Closed cap|Gesloten BE|gesloten be|Open BE|1');
        Observer.Finish();
    end;

    [Test]
    procedure ECR_CardAssertStatus_1033()
    var
        Observer: Codeunit "LT ECR Obs";
    begin
        CardSet(Observer, 1033, 1, true, 'Closed|Closed cap|Gesloten BE|1');
        Observer.Finish();
    end;

    [Test]
    procedure ECR_CardAssertStatus_2067()
    var
        Observer: Codeunit "LT ECR Obs";
    begin
        CardSet(Observer, 2067, 1, true, 'Closed|Closed cap|Gesloten BE|1');
        Observer.Finish();
    end;

    [Test]
    procedure ECR_CardSetMixed_1033()
    var
        Observer: Codeunit "LT ECR Obs";
    begin
        CardSet(Observer, 1033, 2, false, 'Alpha|Alpha cap|Alpha BE|Beta|Beta plain|Gamma|0|2');
        Observer.Finish();
    end;

    [Test]
    procedure ECR_CardSetMixed_2067()
    var
        Observer: Codeunit "LT ECR Obs";
    begin
        CardSet(Observer, 2067, 2, false, 'Alpha|Alpha cap|Alpha BE|Beta|Beta plain|Gamma|0|2');
        Observer.Finish();
    end;

    [Test]
    procedure ECR_CardSetEnuOnly_1033()
    var
        Observer: Codeunit "LT ECR Obs";
    begin
        CardSet(Observer, 1033, 3, false, 'Red|Green|Green cap|green cap|1');
        Observer.Finish();
    end;

    [Test]
    procedure ECR_CardSetEnuOnly_2067()
    var
        Observer: Codeunit "LT ECR Obs";
    begin
        CardSet(Observer, 2067, 3, false, 'Red|Green|Green cap|green cap|1');
        Observer.Finish();
    end;

    // ---- 2. GetFilter, GetFilters, GetView after SetRange / SetFilter
    local procedure FilterTexts(var Observer: Codeunit "LT ECR Obs"; Lang: Integer)
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
        Observer: Codeunit "LT ECR Obs";
    begin
        FilterTexts(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure ECR_FilterTexts_2067()
    var
        Observer: Codeunit "LT ECR Obs";
    begin
        FilterTexts(Observer, 2067);
        Observer.Finish();
    end;

    // ---- 2/3. SetFilter and SetView with words
    local procedure FilterWords(var Observer: Codeunit "LT ECR Obs"; Lang: Integer; Which: Integer; Words: Text)
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
        Observer: Codeunit "LT ECR Obs";
    begin
        FilterWords(Observer, 1033, 1, 'Open#Closed#closed#Closed cap#closed cap#Gesloten BE#Open BE#1#Closed cap|Open cap#Closed|Open#*cap#Clo*#Closed cap..Open cap#<>Closed cap#>Open');
        Observer.Finish();
    end;

    [Test]
    procedure ECR_FilterWordsStatus_2067()
    var
        Observer: Codeunit "LT ECR Obs";
    begin
        FilterWords(Observer, 2067, 1, 'Open#Closed#closed#Closed cap#Gesloten BE#gesloten be#Open BE#1#Gesloten BE|Open BE#Closed|Open#*BE#Ges*#Open BE..Gesloten BE#<>Gesloten BE#>Open');
        Observer.Finish();
    end;

    [Test]
    procedure ECR_FilterWordsMixed_1033()
    var
        Observer: Codeunit "LT ECR Obs";
    begin
        FilterWords(Observer, 1033, 2, 'Alpha#Alpha cap#Alpha BE#Beta#Beta plain#Gamma#Alpha cap|Beta plain#Alpha|Gamma#*plain#0');
        Observer.Finish();
    end;

    [Test]
    procedure ECR_FilterWordsMixed_2067()
    var
        Observer: Codeunit "LT ECR Obs";
    begin
        FilterWords(Observer, 2067, 2, 'Alpha#Alpha cap#Alpha BE#Beta#Beta plain#Gamma#Alpha BE|Beta plain#Alpha|Gamma#*plain#0');
        Observer.Finish();
    end;

    [Test]
    procedure ECR_FilterWordsEnuOnly_1033()
    var
        Observer: Codeunit "LT ECR Obs";
    begin
        FilterWords(Observer, 1033, 3, 'Red#Green#Red cap#Green cap#green cap#Red cap|Green cap#Red|Green#*cap#1');
        Observer.Finish();
    end;

    [Test]
    procedure ECR_FilterWordsEnuOnly_2067()
    var
        Observer: Codeunit "LT ECR Obs";
    begin
        FilterWords(Observer, 2067, 3, 'Red#Green#Red cap#Green cap#green cap#Red cap|Green cap#Red|Green#*cap#1');
        Observer.Finish();
    end;

    local procedure ViewWords(var Observer: Codeunit "LT ECR Obs"; Lang: Integer; Views: Text)
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
        Observer: Codeunit "LT ECR Obs";
    begin
        ViewWords(Observer, 1033, 'WHERE(Status=FILTER(Closed))#WHERE(Status=FILTER(Closed cap))#WHERE(Status=FILTER(Gesloten BE))#WHERE(Status=CONST(Closed cap))#WHERE(Status=CONST(1))#WHERE(Mixed=FILTER(Beta plain))');
        Observer.Finish();
    end;

    [Test]
    procedure ECR_ViewWords_2067()
    var
        Observer: Codeunit "LT ECR Obs";
    begin
        ViewWords(Observer, 2067, 'WHERE(Status=FILTER(Closed))#WHERE(Status=FILTER(Closed cap))#WHERE(Status=FILTER(Gesloten BE))#WHERE(Status=CONST(Gesloten BE))#WHERE(Status=CONST(1))#WHERE(Mixed=FILTER(Alpha BE))');
        Observer.Finish();
    end;

    // ---- 4. TableRelation and CalcFormula
    local procedure Relations(var Observer: Codeunit "LT ECR Obs"; Lang: Integer; Words: Text)
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
        Observer: Codeunit "LT ECR Obs";
    begin
        Relations(Observer, 1033, 'Closed#Closed cap#Gesloten BE#Open cap|Closed cap#1');
        Observer.Finish();
    end;

    [Test]
    procedure ECR_Relations_2067()
    var
        Observer: Codeunit "LT ECR Obs";
    begin
        Relations(Observer, 2067, 'Closed#Closed cap#Gesloten BE#Open BE|Gesloten BE#1');
        Observer.Finish();
    end;

    // ---- 5. FieldRef OptionCaption, OptionMembers
    local procedure FieldRefs(var Observer: Codeunit "LT ECR Obs"; Lang: Integer)
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
        Observer: Codeunit "LT ECR Obs";
    begin
        FieldRefs(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure ECR_FieldRefs_2067()
    var
        Observer: Codeunit "LT ECR Obs";
    begin
        FieldRefs(Observer, 2067);
        Observer.Finish();
    end;

    local procedure FieldRefValue(var Observer: Codeunit "LT ECR Obs"; Lang: Integer; Words: Text)
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
        Observer: Codeunit "LT ECR Obs";
    begin
        FieldRefValue(Observer, 1033, 'Closed#Closed cap#Gesloten BE#1');
        Observer.Finish();
    end;

    [Test]
    procedure ECR_FieldRefValue_2067()
    var
        Observer: Codeunit "LT ECR Obs";
    begin
        FieldRefValue(Observer, 2067, 'Closed#Closed cap#Gesloten BE#1');
        Observer.Finish();
    end;

    // ---- 6. TestField and FieldError texts
    local procedure TestFields(var Observer: Codeunit "LT ECR Obs"; Lang: Integer)
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
        Observer: Codeunit "LT ECR Obs";
    begin
        TestFields(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure ECR_TestFields_2067()
    var
        Observer: Codeunit "LT ECR Obs";
    begin
        TestFields(Observer, 2067);
        Observer.Finish();
    end;

    // ---- 7. key values of an enum key
    local procedure KeyValues(var Observer: Codeunit "LT ECR Obs"; Lang: Integer)
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
        Observer: Codeunit "LT ECR Obs";
    begin
        KeyValues(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure ECR_KeyValues_2067()
    var
        Observer: Codeunit "LT ECR Obs";
    begin
        KeyValues(Observer, 2067);
        Observer.Finish();
    end;

    // ---- 8. list page column
    local procedure ListValues(var Observer: Codeunit "LT ECR Obs"; Lang: Integer)
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

    local procedure ListFilter(var Observer: Codeunit "LT ECR Obs"; Lang: Integer; Words: Text)
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
        Observer: Codeunit "LT ECR Obs";
    begin
        ListValues(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure ECR_ListValues_2067()
    var
        Observer: Codeunit "LT ECR Obs";
    begin
        ListValues(Observer, 2067);
        Observer.Finish();
    end;

    [Test]
    procedure ECR_ListFilter_1033()
    var
        Observer: Codeunit "LT ECR Obs";
    begin
        ListFilter(Observer, 1033, 'Closed#Closed cap#Gesloten BE#Open cap|Closed cap');
        Observer.Finish();
    end;

    [Test]
    procedure ECR_ListFilter_2067()
    var
        Observer: Codeunit "LT ECR Obs";
    begin
        ListFilter(Observer, 2067, 'Closed#Closed cap#Gesloten BE#Open BE|Gesloten BE');
        Observer.Finish();
    end;
}
