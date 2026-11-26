// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 75147-75155 (LT OBC ...)
// Probe: from al-runner issues 8354, 8355 and 8356 (outside reporter, measured on BC 28.4 and 29.0). Evaluate of a blank text into an Option field whose
//   OptionCaption has blank entries, of an ordinal past the members or a negative one into an Option field with an OptionCaption, and of a blank text into an
//   Enum whose member has a name and a blank Caption. The pinned blank members are named " " (P131EvalOption.al, FMOptionBlankField.al) or are the first
//   member named None (EvalNamedBlankCaption.al); this file measures the other blank shapes:
//   - Option fields: members "" with caption '' (the reporter's field, members in the middle), a first member "" with caption '', a member "" with a caption
//     that is not blank, a member " " with caption '', a named member with caption '' and with caption ' ' in the middle, a member "" with caption ' ';
//   - Option field Alpha,Beta with OptionCaption 'Alpha,Beta': '2', '99', '-1', '+2', '2147483647', '2147483648', and with the result unused;
//   - Enums: a last member named Blank with Caption '' (the reporter's enum), a middle member named None with Caption ' ', two members with blank captions,
//     a middle member with Caption '' in an extensible enum, and an Enum field of the reporter's enum.
//   Each blank cell reads '', ' ', two blanks and a TAB, with the result used, and '' with the result unused. The start value is the last member, so a kept
//   value shows.
// Facts: see the Expect lines (measured by the corpus CI matrix).
// BC versions: 27+ (tested by the corpus CI matrix)

table 75147 "LT OBC Option Row"
{
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Reporter; Option)
        {
            OptionMembers = First,Second,Third,,,Skip;
            OptionCaption = 'First one,Second one,Third one,,,Skip it';
        }
        field(3; FirstEmpty; Option)
        {
            OptionMembers = "",A,B;
            OptionCaption = ',A cap,B cap';
        }
        field(4; EmptyNamedCap; Option)
        {
            OptionMembers = "",A,B;
            OptionCaption = 'Blank0,A cap,B cap';
        }
        field(5; SpaceEmptyCap; Option)
        {
            OptionMembers = " ",A,B;
            OptionCaption = ',A cap,B cap';
        }
        field(6; NamedEmptyCap; Option)
        {
            OptionMembers = None,A,B;
            OptionCaption = ',A cap,B cap';
        }
        field(7; NamedSpaceCapMid; Option)
        {
            OptionMembers = A,None,B;
            OptionCaption = 'A cap, ,B cap';
        }
        field(8; EmptySpaceCapMid; Option)
        {
            OptionMembers = A,"",B;
            OptionCaption = 'A cap, ,B cap';
        }
        field(9; Pair; Option)
        {
            OptionMembers = Alpha,Beta;
            OptionCaption = 'Alpha,Beta';
        }
        field(10; Kind; Enum "LT OBC Enum Last") { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

enum 75148 "LT OBC Enum Last"
{
    Extensible = false;

    value(0; Alpha) { Caption = 'Alpha cap'; }
    value(5; Beta) { Caption = 'Beta cap'; }
    value(10; Blank) { Caption = ''; }
}

enum 75149 "LT OBC Enum Space Mid"
{
    Extensible = false;

    value(0; Alpha) { Caption = 'Alpha cap'; }
    value(1; None) { Caption = ' '; }
    value(2; Beta) { Caption = 'Beta cap'; }
}

enum 75150 "LT OBC Enum Two Blank"
{
    Extensible = false;

    value(0; Alpha) { Caption = 'Alpha cap'; }
    value(1; N1) { Caption = ''; }
    value(2; N2) { Caption = ' '; }
    value(3; Beta) { Caption = 'Beta cap'; }
}

enum 75151 "LT OBC Enum Empty Mid"
{
    Extensible = true;

    value(0; Alpha) { Caption = 'Alpha cap'; }
    value(3; Blank) { Caption = ''; }
    value(7; Beta) { Caption = 'Beta cap'; }
}

codeunit 75152 "LT OBC Evaluate"
{
    Subtype = Test;

    local procedure Tab(): Text
    var
        T: Text[1];
    begin
        T[1] := 9;
        exit(T);
    end;

    // Evaluate into the Option field FieldNo of a row whose field starts at StartValue; ok|ordinal or rejected|ordinal.
    local procedure Opt(FieldNo: Integer; StartValue: Integer; Word: Text): Text
    var
        Row: Record "LT OBC Option Row" temporary;
        Ok: Boolean;
        Ord: Integer;
    begin
        case FieldNo of
            2:
                begin
                    Row.Reporter := StartValue;
                    Ok := Evaluate(Row.Reporter, Word);
                    Ord := Row.Reporter;
                end;
            3:
                begin
                    Row.FirstEmpty := StartValue;
                    Ok := Evaluate(Row.FirstEmpty, Word);
                    Ord := Row.FirstEmpty;
                end;
            4:
                begin
                    Row.EmptyNamedCap := StartValue;
                    Ok := Evaluate(Row.EmptyNamedCap, Word);
                    Ord := Row.EmptyNamedCap;
                end;
            5:
                begin
                    Row.SpaceEmptyCap := StartValue;
                    Ok := Evaluate(Row.SpaceEmptyCap, Word);
                    Ord := Row.SpaceEmptyCap;
                end;
            6:
                begin
                    Row.NamedEmptyCap := StartValue;
                    Ok := Evaluate(Row.NamedEmptyCap, Word);
                    Ord := Row.NamedEmptyCap;
                end;
            7:
                begin
                    Row.NamedSpaceCapMid := StartValue;
                    Ok := Evaluate(Row.NamedSpaceCapMid, Word);
                    Ord := Row.NamedSpaceCapMid;
                end;
            8:
                begin
                    Row.EmptySpaceCapMid := StartValue;
                    Ok := Evaluate(Row.EmptySpaceCapMid, Word);
                    Ord := Row.EmptySpaceCapMid;
                end;
            9:
                begin
                    Row.Pair := StartValue;
                    Ok := Evaluate(Row.Pair, Word);
                    Ord := Row.Pair;
                end;
        end;
        if Ok then
            exit('ok|' + Format(Ord));
        exit('rejected|' + Format(Ord));
    end;

    // The same with the result unused: the value after the call, or the error.
    [TryFunction]
    local procedure TryOptStatement(FieldNo: Integer; StartValue: Integer; Word: Text; var Ord: Integer)
    var
        Row: Record "LT OBC Option Row" temporary;
    begin
        case FieldNo of
            2:
                begin
                    Row.Reporter := StartValue;
                    Evaluate(Row.Reporter, Word);
                    Ord := Row.Reporter;
                end;
            3:
                begin
                    Row.FirstEmpty := StartValue;
                    Evaluate(Row.FirstEmpty, Word);
                    Ord := Row.FirstEmpty;
                end;
            4:
                begin
                    Row.EmptyNamedCap := StartValue;
                    Evaluate(Row.EmptyNamedCap, Word);
                    Ord := Row.EmptyNamedCap;
                end;
            5:
                begin
                    Row.SpaceEmptyCap := StartValue;
                    Evaluate(Row.SpaceEmptyCap, Word);
                    Ord := Row.SpaceEmptyCap;
                end;
            6:
                begin
                    Row.NamedEmptyCap := StartValue;
                    Evaluate(Row.NamedEmptyCap, Word);
                    Ord := Row.NamedEmptyCap;
                end;
            7:
                begin
                    Row.NamedSpaceCapMid := StartValue;
                    Evaluate(Row.NamedSpaceCapMid, Word);
                    Ord := Row.NamedSpaceCapMid;
                end;
            8:
                begin
                    Row.EmptySpaceCapMid := StartValue;
                    Evaluate(Row.EmptySpaceCapMid, Word);
                    Ord := Row.EmptySpaceCapMid;
                end;
            9:
                begin
                    Row.Pair := StartValue;
                    Evaluate(Row.Pair, Word);
                    Ord := Row.Pair;
                end;
        end;
    end;

    local procedure ObserveStatement(var Observer: Codeunit "Probe Observer"; Name: Text; FieldNo: Integer; StartValue: Integer; Word: Text)
    var
        Ord: Integer;
    begin
        ClearLastError();
        if TryOptStatement(FieldNo, StartValue, Word, Ord) then
            Observer.Observe(Name, 'no error|' + Format(Ord))
        else
            Observer.ObserveError(Name);
    end;

    local procedure ObserveBlanks(var Observer: Codeunit "Probe Observer"; FieldNo: Integer; StartValue: Integer)
    begin
        Observer.Observe('empty', Opt(FieldNo, StartValue, ''));
        Observer.Observe('space', Opt(FieldNo, StartValue, ' '));
        Observer.Observe('two spaces', Opt(FieldNo, StartValue, '  '));
        Observer.Observe('tab', Opt(FieldNo, StartValue, Tab()));
        ObserveStatement(Observer, 'statement empty', FieldNo, StartValue, '');
    end;

    [Test]
    procedure OBC_Option_Reporter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // OptionMembers = First,Second,Third,,,Skip; OptionCaption = 'First one,Second one,Third one,,,Skip it'
        ObserveBlanks(Observer, 2, 0);
        Observer.Observe('empty from Skip', Opt(2, 5, ''));
        Observer.Observe('Skip it', Opt(2, 0, 'Skip it'));
        Observer.Observe('3', Opt(2, 0, '3'));
        Observer.Expect('empty', 'rejected|0');
        Observer.Expect('space', 'rejected|0');
        Observer.Expect('two spaces', 'rejected|0');
        Observer.Expect('tab', 'rejected|0');
        Observer.Expect('statement empty|text', ''''' is not an option. The existing options are: First one,Second one,Third one,,,Skip it');
        Observer.Expect('statement empty|code', 'InvalidOptionString');
        Observer.Expect('empty from Skip', 'rejected|5');
        Observer.Expect('Skip it', 'ok|5');
        Observer.Expect('3', 'ok|3');
        Observer.Verify();
    end;

    [Test]
    procedure OBC_Option_FirstEmpty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // OptionMembers = "",A,B; OptionCaption = ',A cap,B cap'
        ObserveBlanks(Observer, 3, 2);
        Observer.Expect('empty', 'rejected|2');
        Observer.Expect('space', 'rejected|2');
        Observer.Expect('two spaces', 'rejected|2');
        Observer.Expect('tab', 'rejected|2');
        Observer.Expect('statement empty|text', ''''' is not an option. The existing options are: ,A cap,B cap');
        Observer.Expect('statement empty|code', 'InvalidOptionString');
        Observer.Verify();
    end;

    [Test]
    procedure OBC_Option_EmptyNamedCap()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // OptionMembers = "",A,B; OptionCaption = 'Blank0,A cap,B cap'
        ObserveBlanks(Observer, 4, 2);
        Observer.Observe('Blank0', Opt(4, 2, 'Blank0'));
        Observer.Expect('empty', 'rejected|2');
        Observer.Expect('space', 'rejected|2');
        Observer.Expect('two spaces', 'rejected|2');
        Observer.Expect('tab', 'rejected|2');
        Observer.Expect('statement empty|text', ''''' is not an option. The existing options are: Blank0,A cap,B cap');
        Observer.Expect('statement empty|code', 'InvalidOptionString');
        Observer.Expect('Blank0', 'ok|0');
        Observer.Verify();
    end;

    [Test]
    procedure OBC_Option_SpaceEmptyCap()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // OptionMembers = " ",A,B; OptionCaption = ',A cap,B cap'
        ObserveBlanks(Observer, 5, 2);
        Observer.Expect('empty', 'ok|0');
        Observer.Expect('space', 'ok|0');
        Observer.Expect('two spaces', 'ok|0');
        Observer.Expect('tab', 'ok|0');
        Observer.Expect('statement empty', 'no error|0');
        Observer.Verify();
    end;

    [Test]
    procedure OBC_Option_NamedEmptyCap()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // OptionMembers = None,A,B; OptionCaption = ',A cap,B cap'
        ObserveBlanks(Observer, 6, 2);
        Observer.Observe('None', Opt(6, 2, 'None'));
        Observer.Expect('empty', 'rejected|2');
        Observer.Expect('space', 'rejected|2');
        Observer.Expect('two spaces', 'rejected|2');
        Observer.Expect('tab', 'rejected|2');
        Observer.Expect('statement empty|text', ''''' is not an option. The existing options are: None,A cap,B cap');
        Observer.Expect('statement empty|code', 'InvalidOptionString');
        Observer.Expect('None', 'ok|0');
        Observer.Verify();
    end;

    [Test]
    procedure OBC_Option_NamedSpaceCapMid()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // OptionMembers = A,None,B; OptionCaption = 'A cap, ,B cap'
        ObserveBlanks(Observer, 7, 2);
        Observer.Expect('empty', 'ok|1');
        Observer.Expect('space', 'ok|1');
        Observer.Expect('two spaces', 'ok|1');
        Observer.Expect('tab', 'ok|1');
        Observer.Expect('statement empty', 'no error|1');
        Observer.Verify();
    end;

    [Test]
    procedure OBC_Option_EmptySpaceCapMid()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // OptionMembers = A,"",B; OptionCaption = 'A cap, ,B cap'
        ObserveBlanks(Observer, 8, 2);
        Observer.Expect('empty', 'ok|1');
        Observer.Expect('space', 'ok|1');
        Observer.Expect('two spaces', 'ok|1');
        Observer.Expect('tab', 'ok|1');
        Observer.Expect('statement empty', 'no error|1');
        Observer.Verify();
    end;

    [Test]
    procedure OBC_Option_PairOrdinals()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // OptionMembers = Alpha,Beta; OptionCaption = 'Alpha,Beta'
        Observer.Observe('2', Opt(9, 0, '2'));
        Observer.Observe('99', Opt(9, 0, '99'));
        Observer.Observe('-1', Opt(9, 0, '-1'));
        Observer.Observe('-1 from Beta', Opt(9, 1, '-1'));
        Observer.Observe('+2', Opt(9, 0, '+2'));
        Observer.Observe('2147483647', Opt(9, 0, '2147483647'));
        Observer.Observe('2147483648', Opt(9, 0, '2147483648'));
        ObserveStatement(Observer, 'statement 99', 9, 0, '99');
        ObserveStatement(Observer, 'statement -1', 9, 1, '-1');
        Observer.Expect('2', 'ok|2');
        Observer.Expect('99', 'ok|99');
        Observer.Expect('-1', 'rejected|0');
        Observer.Expect('-1 from Beta', 'rejected|1');
        Observer.Expect('+2', 'ok|2');
        Observer.Expect('2147483647', 'ok|2147483647');
        Observer.Expect('2147483648', 'rejected|0');
        Observer.Expect('statement 99', 'no error|99');
        Observer.Expect('statement -1|text', '''-1'' is not an option. The existing options are: Alpha,Beta');
        Observer.Expect('statement -1|code', 'InvalidOptionString');
        Observer.Verify();
    end;

    local procedure EnumLast(Word: Text): Text
    var
        E: Enum "LT OBC Enum Last";
    begin
        E := E::Beta;
        if Evaluate(E, Word) then
            exit('ok|' + Format(E.AsInteger()));
        exit('rejected|' + Format(E.AsInteger()));
    end;

    local procedure EnumSpaceMid(Word: Text): Text
    var
        E: Enum "LT OBC Enum Space Mid";
    begin
        E := E::Beta;
        if Evaluate(E, Word) then
            exit('ok|' + Format(E.AsInteger()));
        exit('rejected|' + Format(E.AsInteger()));
    end;

    local procedure EnumTwoBlank(Word: Text): Text
    var
        E: Enum "LT OBC Enum Two Blank";
    begin
        E := E::Beta;
        if Evaluate(E, Word) then
            exit('ok|' + Format(E.AsInteger()));
        exit('rejected|' + Format(E.AsInteger()));
    end;

    local procedure EnumEmptyMid(Word: Text): Text
    var
        E: Enum "LT OBC Enum Empty Mid";
    begin
        E := E::Beta;
        if Evaluate(E, Word) then
            exit('ok|' + Format(E.AsInteger()));
        exit('rejected|' + Format(E.AsInteger()));
    end;

    local procedure EnumField(Word: Text): Text
    var
        Row: Record "LT OBC Option Row" temporary;
    begin
        Row.Kind := Row.Kind::Beta;
        if Evaluate(Row.Kind, Word) then
            exit('ok|' + Format(Row.Kind.AsInteger()));
        exit('rejected|' + Format(Row.Kind.AsInteger()));
    end;

    [TryFunction]
    local procedure TryEnumStatement(Which: Integer; Word: Text; var Ord: Integer)
    var
        Last: Enum "LT OBC Enum Last";
        SpaceMid: Enum "LT OBC Enum Space Mid";
        TwoBlank: Enum "LT OBC Enum Two Blank";
        EmptyMid: Enum "LT OBC Enum Empty Mid";
        Row: Record "LT OBC Option Row" temporary;
    begin
        case Which of
            1:
                begin
                    Last := Last::Beta;
                    Evaluate(Last, Word);
                    Ord := Last.AsInteger();
                end;
            2:
                begin
                    SpaceMid := SpaceMid::Beta;
                    Evaluate(SpaceMid, Word);
                    Ord := SpaceMid.AsInteger();
                end;
            3:
                begin
                    TwoBlank := TwoBlank::Beta;
                    Evaluate(TwoBlank, Word);
                    Ord := TwoBlank.AsInteger();
                end;
            4:
                begin
                    EmptyMid := EmptyMid::Beta;
                    Evaluate(EmptyMid, Word);
                    Ord := EmptyMid.AsInteger();
                end;
            5:
                begin
                    Row.Kind := Row.Kind::Beta;
                    Evaluate(Row.Kind, Word);
                    Ord := Row.Kind.AsInteger();
                end;
        end;
    end;

    local procedure ObserveEnumStatement(var Observer: Codeunit "Probe Observer"; Which: Integer)
    var
        Ord: Integer;
    begin
        ClearLastError();
        if TryEnumStatement(Which, '', Ord) then
            Observer.Observe('statement empty', 'no error|' + Format(Ord))
        else
            Observer.ObserveError('statement empty');
    end;

    [Test]
    procedure OBC_Enum_Last()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // value(0; Alpha) 'Alpha cap', value(5; Beta) 'Beta cap', value(10; Blank) { Caption = ''; }
        Observer.Observe('empty', EnumLast(''));
        Observer.Observe('space', EnumLast(' '));
        Observer.Observe('two spaces', EnumLast('  '));
        Observer.Observe('tab', EnumLast(Tab()));
        Observer.Observe('Blank', EnumLast('Blank'));
        ObserveEnumStatement(Observer, 1);
        Observer.Expect('empty', 'ok|10');
        Observer.Expect('space', 'ok|10');
        Observer.Expect('two spaces', 'ok|10');
        Observer.Expect('tab', 'ok|10');
        Observer.Expect('Blank', 'ok|10');
        Observer.Expect('statement empty', 'no error|10');
        Observer.Verify();
    end;

    [Test]
    procedure OBC_Enum_SpaceMid()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // value(0; Alpha) 'Alpha cap', value(1; None) { Caption = ' '; }, value(2; Beta) 'Beta cap'
        Observer.Observe('empty', EnumSpaceMid(''));
        Observer.Observe('space', EnumSpaceMid(' '));
        Observer.Observe('two spaces', EnumSpaceMid('  '));
        Observer.Observe('tab', EnumSpaceMid(Tab()));
        ObserveEnumStatement(Observer, 2);
        Observer.Expect('empty', 'ok|1');
        Observer.Expect('space', 'ok|1');
        Observer.Expect('two spaces', 'ok|1');
        Observer.Expect('tab', 'ok|1');
        Observer.Expect('statement empty', 'no error|1');
        Observer.Verify();
    end;

    [Test]
    procedure OBC_Enum_TwoBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // value(0; Alpha), value(1; N1) { Caption = ''; }, value(2; N2) { Caption = ' '; }, value(3; Beta)
        Observer.Observe('empty', EnumTwoBlank(''));
        Observer.Observe('space', EnumTwoBlank(' '));
        Observer.Observe('two spaces', EnumTwoBlank('  '));
        Observer.Observe('tab', EnumTwoBlank(Tab()));
        ObserveEnumStatement(Observer, 3);
        Observer.Expect('empty', 'ok|1');
        Observer.Expect('space', 'ok|1');
        Observer.Expect('two spaces', 'ok|1');
        Observer.Expect('tab', 'ok|1');
        Observer.Expect('statement empty', 'no error|1');
        Observer.Verify();
    end;

    [Test]
    procedure OBC_Enum_EmptyMid()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Extensible: value(0; Alpha), value(3; Blank) { Caption = ''; }, value(7; Beta)
        Observer.Observe('empty', EnumEmptyMid(''));
        Observer.Observe('space', EnumEmptyMid(' '));
        Observer.Observe('two spaces', EnumEmptyMid('  '));
        Observer.Observe('tab', EnumEmptyMid(Tab()));
        ObserveEnumStatement(Observer, 4);
        Observer.Expect('empty', 'ok|3');
        Observer.Expect('space', 'ok|3');
        Observer.Expect('two spaces', 'ok|3');
        Observer.Expect('tab', 'ok|3');
        Observer.Expect('statement empty', 'no error|3');
        Observer.Verify();
    end;

    [Test]
    procedure OBC_Enum_Field()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // An Enum field of "LT OBC Enum Last"
        Observer.Observe('empty', EnumField(''));
        Observer.Observe('space', EnumField(' '));
        Observer.Observe('two spaces', EnumField('  '));
        Observer.Observe('tab', EnumField(Tab()));
        ObserveEnumStatement(Observer, 5);
        Observer.Expect('empty', 'ok|10');
        Observer.Expect('space', 'ok|10');
        Observer.Expect('two spaces', 'ok|10');
        Observer.Expect('tab', 'ok|10');
        Observer.Expect('statement empty', 'no error|10');
        Observer.Verify();
    end;
}

table 75154 "LT OBC Option Row 2"
{
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; Id; Integer) { }
        field(2; OneTwo; Option)
        {
            OptionMembers = One,Two;
            OptionCaption = 'One,Two';
        }
        field(3; AB; Option)
        {
            OptionMembers = A,B;
            OptionCaption = 'A,B';
        }
        field(4; Trio; Option)
        {
            OptionMembers = Alpha,Beta,Gamma;
            OptionCaption = 'Alpha,Beta,Gamma';
        }
        field(5; MixNoneEmpty; Option)
        {
            OptionMembers = None,"",B;
            OptionCaption = ',Blank1,B cap';
        }
        field(6; MixEmptyNone; Option)
        {
            OptionMembers = "",None,B;
            OptionCaption = ',,B cap';
        }
        field(7; NamedEmptyCap; Option)
        {
            OptionMembers = None,A,B;
            OptionCaption = ',A cap,B cap';
        }
        field(8; NamedSpaceCapMid; Option)
        {
            OptionMembers = A,None,B;
            OptionCaption = 'A cap, ,B cap';
        }
        field(9; FirstEmpty; Option)
        {
            OptionMembers = "",A,B;
            OptionCaption = ',A cap,B cap';
        }
        field(10; Reporter; Option)
        {
            OptionMembers = First,Second,Third,,,Skip;
            OptionCaption = 'First one,Second one,Third one,,,Skip it';
        }
        field(11; ReporterML; Option)
        {
            OptionMembers = First,Second,Third,,,Skip;
            OptionCaptionML = ENU = 'First one,Second one,Third one,,,Skip it';
        }
        field(12; SpaceMidKind; Enum "LT OBC Enum Space Mid") { }
        field(13; TwoBlankKind; Enum "LT OBC Enum Two Blank") { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

// The shapes the first codeunit leaves open: other Option fields whose OptionCaption repeats the member names, Option fields that mix
// kinds of blank members, a text that is not blank as a statement into fields with blank captions, an OptionCaptionML field, a FieldRef,
// and Enum fields of enums with a middle blank caption or two blank captions.
codeunit 75155 "LT OBC Evaluate More"
{
    Subtype = Test;

    local procedure Tab(): Text
    var
        T: Text[1];
    begin
        T[1] := 9;
        exit(T);
    end;

    // Evaluate into field FieldNo of a row whose field starts at StartValue; with Statement the result is unused. Ord: the value after the call.
    local procedure Eval(FieldNo: Integer; StartValue: Integer; Word: Text; Statement: Boolean; var Ord: Integer): Boolean
    var
        Row: Record "LT OBC Option Row 2" temporary;
        Ok: Boolean;
    begin
        case FieldNo of
            2:
                begin
                    Row.OneTwo := StartValue;
                    if Statement then Evaluate(Row.OneTwo, Word) else Ok := Evaluate(Row.OneTwo, Word);
                    Ord := Row.OneTwo;
                end;
            3:
                begin
                    Row.AB := StartValue;
                    if Statement then Evaluate(Row.AB, Word) else Ok := Evaluate(Row.AB, Word);
                    Ord := Row.AB;
                end;
            4:
                begin
                    Row.Trio := StartValue;
                    if Statement then Evaluate(Row.Trio, Word) else Ok := Evaluate(Row.Trio, Word);
                    Ord := Row.Trio;
                end;
            5:
                begin
                    Row.MixNoneEmpty := StartValue;
                    if Statement then Evaluate(Row.MixNoneEmpty, Word) else Ok := Evaluate(Row.MixNoneEmpty, Word);
                    Ord := Row.MixNoneEmpty;
                end;
            6:
                begin
                    Row.MixEmptyNone := StartValue;
                    if Statement then Evaluate(Row.MixEmptyNone, Word) else Ok := Evaluate(Row.MixEmptyNone, Word);
                    Ord := Row.MixEmptyNone;
                end;
            7:
                begin
                    Row.NamedEmptyCap := StartValue;
                    if Statement then Evaluate(Row.NamedEmptyCap, Word) else Ok := Evaluate(Row.NamedEmptyCap, Word);
                    Ord := Row.NamedEmptyCap;
                end;
            8:
                begin
                    Row.NamedSpaceCapMid := StartValue;
                    if Statement then Evaluate(Row.NamedSpaceCapMid, Word) else Ok := Evaluate(Row.NamedSpaceCapMid, Word);
                    Ord := Row.NamedSpaceCapMid;
                end;
            9:
                begin
                    Row.FirstEmpty := StartValue;
                    if Statement then Evaluate(Row.FirstEmpty, Word) else Ok := Evaluate(Row.FirstEmpty, Word);
                    Ord := Row.FirstEmpty;
                end;
            10:
                begin
                    Row.Reporter := StartValue;
                    if Statement then Evaluate(Row.Reporter, Word) else Ok := Evaluate(Row.Reporter, Word);
                    Ord := Row.Reporter;
                end;
            11:
                begin
                    Row.ReporterML := StartValue;
                    if Statement then Evaluate(Row.ReporterML, Word) else Ok := Evaluate(Row.ReporterML, Word);
                    Ord := Row.ReporterML;
                end;
            12:
                begin
                    Row.SpaceMidKind := Enum::"LT OBC Enum Space Mid".FromInteger(StartValue);
                    if Statement then Evaluate(Row.SpaceMidKind, Word) else Ok := Evaluate(Row.SpaceMidKind, Word);
                    Ord := Row.SpaceMidKind.AsInteger();
                end;
            13:
                begin
                    Row.TwoBlankKind := Enum::"LT OBC Enum Two Blank".FromInteger(StartValue);
                    if Statement then Evaluate(Row.TwoBlankKind, Word) else Ok := Evaluate(Row.TwoBlankKind, Word);
                    Ord := Row.TwoBlankKind.AsInteger();
                end;
        end;
        exit(Ok);
    end;

    local procedure Opt(FieldNo: Integer; StartValue: Integer; Word: Text): Text
    var
        Ord: Integer;
    begin
        if Eval(FieldNo, StartValue, Word, false, Ord) then
            exit('ok|' + Format(Ord));
        exit('rejected|' + Format(Ord));
    end;

    [TryFunction]
    local procedure TryStatement(FieldNo: Integer; StartValue: Integer; Word: Text; var Ord: Integer)
    begin
        Eval(FieldNo, StartValue, Word, true, Ord);
    end;

    local procedure ObserveStatement(var Observer: Codeunit "Probe Observer"; Name: Text; FieldNo: Integer; StartValue: Integer; Word: Text)
    var
        Ord: Integer;
    begin
        ClearLastError();
        if TryStatement(FieldNo, StartValue, Word, Ord) then
            Observer.Observe(Name, 'no error|' + Format(Ord))
        else
            Observer.ObserveError(Name);
    end;

    local procedure ObserveOrdinals(var Observer: Codeunit "Probe Observer"; FieldNo: Integer)
    begin
        Observer.Observe('2', Opt(FieldNo, 0, '2'));
        Observer.Observe('3', Opt(FieldNo, 0, '3'));
        Observer.Observe('99', Opt(FieldNo, 0, '99'));
        Observer.Observe('-1', Opt(FieldNo, 0, '-1'));
        Observer.Observe('-1 from 1', Opt(FieldNo, 1, '-1'));
        Observer.Observe('+2', Opt(FieldNo, 0, '+2'));
        Observer.Observe('2147483647', Opt(FieldNo, 0, '2147483647'));
        Observer.Observe('2147483648', Opt(FieldNo, 0, '2147483648'));
        ObserveStatement(Observer, 'statement 99', FieldNo, 0, '99');
        ObserveStatement(Observer, 'statement -1', FieldNo, 1, '-1');
    end;

    local procedure ObserveBlanks(var Observer: Codeunit "Probe Observer"; FieldNo: Integer; StartValue: Integer)
    begin
        Observer.Observe('empty', Opt(FieldNo, StartValue, ''));
        Observer.Observe('space', Opt(FieldNo, StartValue, ' '));
        Observer.Observe('two spaces', Opt(FieldNo, StartValue, '  '));
        Observer.Observe('tab', Opt(FieldNo, StartValue, Tab()));
        ObserveStatement(Observer, 'statement empty', FieldNo, StartValue, '');
    end;

    [Test]
    procedure OBC_More_OneTwoOrdinals()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // OptionMembers = One,Two; OptionCaption = 'One,Two'
        ObserveOrdinals(Observer, 2);
        Observer.Expect('2', 'ok|2');
        Observer.Expect('3', 'ok|3');
        Observer.Expect('99', 'ok|99');
        Observer.Expect('-1', 'rejected|0');
        Observer.Expect('-1 from 1', 'rejected|1');
        Observer.Expect('+2', 'ok|2');
        Observer.Expect('2147483647', 'ok|2147483647');
        Observer.Expect('2147483648', 'rejected|0');
        Observer.Expect('statement 99', 'no error|99');
        Observer.Expect('statement -1|text', '''-1'' is not an option. The existing options are: One,Two');
        Observer.Expect('statement -1|code', 'InvalidOptionString');
        Observer.Verify();
    end;

    [Test]
    procedure OBC_More_ABOrdinals()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // OptionMembers = A,B; OptionCaption = 'A,B'
        ObserveOrdinals(Observer, 3);
        Observer.Expect('2', 'ok|2');
        Observer.Expect('3', 'ok|3');
        Observer.Expect('99', 'ok|99');
        Observer.Expect('-1', 'rejected|0');
        Observer.Expect('-1 from 1', 'rejected|1');
        Observer.Expect('+2', 'ok|2');
        Observer.Expect('2147483647', 'ok|2147483647');
        Observer.Expect('2147483648', 'rejected|0');
        Observer.Expect('statement 99', 'no error|99');
        Observer.Expect('statement -1|text', '''-1'' is not an option. The existing options are: A,B');
        Observer.Expect('statement -1|code', 'InvalidOptionString');
        Observer.Verify();
    end;

    [Test]
    procedure OBC_More_TrioOrdinals()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // OptionMembers = Alpha,Beta,Gamma; OptionCaption = 'Alpha,Beta,Gamma'
        ObserveOrdinals(Observer, 4);
        Observer.Expect('2', 'ok|2');
        Observer.Expect('3', 'ok|3');
        Observer.Expect('99', 'ok|99');
        Observer.Expect('-1', 'rejected|0');
        Observer.Expect('-1 from 1', 'rejected|1');
        Observer.Expect('+2', 'ok|2');
        Observer.Expect('2147483647', 'ok|2147483647');
        Observer.Expect('2147483648', 'rejected|0');
        Observer.Expect('statement 99', 'no error|99');
        Observer.Expect('statement -1|text', '''-1'' is not an option. The existing options are: Alpha,Beta,Gamma');
        Observer.Expect('statement -1|code', 'InvalidOptionString');
        Observer.Verify();
    end;

    [Test]
    procedure OBC_More_MixNoneEmpty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // OptionMembers = None,"",B; OptionCaption = ',Blank1,B cap'
        ObserveBlanks(Observer, 5, 2);
        Observer.Expect('empty', 'rejected|2');
        Observer.Expect('space', 'rejected|2');
        Observer.Expect('two spaces', 'rejected|2');
        Observer.Expect('tab', 'rejected|2');
        Observer.Expect('statement empty|text', ''''' is not an option. The existing options are: None,Blank1,B cap');
        Observer.Expect('statement empty|code', 'InvalidOptionString');
        Observer.Verify();
    end;

    [Test]
    procedure OBC_More_MixEmptyNone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // OptionMembers = "",None,B; OptionCaption = ',,B cap'
        ObserveBlanks(Observer, 6, 2);
        Observer.Expect('empty', 'rejected|2');
        Observer.Expect('space', 'rejected|2');
        Observer.Expect('two spaces', 'rejected|2');
        Observer.Expect('tab', 'rejected|2');
        Observer.Expect('statement empty|text', ''''' is not an option. The existing options are: ,None,B cap');
        Observer.Expect('statement empty|code', 'InvalidOptionString');
        Observer.Verify();
    end;

    [Test]
    procedure OBC_More_TextStatements()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // A text that is not blank, as a statement, into fields with blank captions
        ObserveStatement(Observer, 'NamedEmptyCap xyz', 7, 2, 'xyz');
        ObserveStatement(Observer, 'NamedSpaceCapMid xyz', 8, 2, 'xyz');
        ObserveStatement(Observer, 'FirstEmpty xyz', 9, 2, 'xyz');
        ObserveStatement(Observer, 'Reporter xyz', 10, 0, 'xyz');
        ObserveStatement(Observer, 'MixEmptyNone xyz', 6, 2, 'xyz');
        Observer.Expect('NamedEmptyCap xyz|text', '''xyz'' is not an option. The existing options are: None,A cap,B cap');
        Observer.Expect('NamedEmptyCap xyz|code', 'InvalidOptionString');
        Observer.Expect('NamedSpaceCapMid xyz|text', '''xyz'' is not an option. The existing options are: A cap, ,B cap');
        Observer.Expect('NamedSpaceCapMid xyz|code', 'InvalidOptionString');
        Observer.Expect('FirstEmpty xyz|text', '''xyz'' is not an option. The existing options are: ,A cap,B cap');
        Observer.Expect('FirstEmpty xyz|code', 'InvalidOptionString');
        Observer.Expect('Reporter xyz|text', '''xyz'' is not an option. The existing options are: First one,Second one,Third one,,,Skip it');
        Observer.Expect('Reporter xyz|code', 'InvalidOptionString');
        Observer.Expect('MixEmptyNone xyz|text', '''xyz'' is not an option. The existing options are: ,None,B cap');
        Observer.Expect('MixEmptyNone xyz|code', 'InvalidOptionString');
        Observer.Verify();
    end;

    [Test]
    procedure OBC_More_ReporterCaptionML()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // OptionMembers = First,Second,Third,,,Skip; OptionCaptionML = ENU = 'First one,Second one,Third one,,,Skip it'
        ObserveBlanks(Observer, 11, 0);
        Observer.Expect('empty', 'rejected|0');
        Observer.Expect('space', 'rejected|0');
        Observer.Expect('two spaces', 'rejected|0');
        Observer.Expect('tab', 'rejected|0');
        Observer.Expect('statement empty|text', ''''' is not an option. The existing options are: First one,Second one,Third one,,,Skip it');
        Observer.Expect('statement empty|code', 'InvalidOptionString');
        Observer.Verify();
    end;

    local procedure ViaFieldRef(Word: Text): Text
    var
        Row: Record "LT OBC Option Row 2" temporary;
        RecRef: RecordRef;
        FldRef: FieldRef;
        Ord: Integer;
        Ok: Boolean;
    begin
        RecRef.GetTable(Row);
        FldRef := RecRef.Field(10);
        FldRef.Value := 0;
        Ok := Evaluate(FldRef, Word);
        Ord := FldRef.Value;
        if Ok then
            exit('ok|' + Format(Ord));
        exit('rejected|' + Format(Ord));
    end;

    [Test]
    procedure OBC_More_ReporterFieldRef()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Evaluate through a FieldRef into the Reporter field, from First
        Observer.Observe('empty', ViaFieldRef(''));
        Observer.Observe('space', ViaFieldRef(' '));
        Observer.Observe('two spaces', ViaFieldRef('  '));
        Observer.Observe('tab', ViaFieldRef(Tab()));
        Observer.Expect('empty', 'rejected|0');
        Observer.Expect('space', 'rejected|0');
        Observer.Expect('two spaces', 'rejected|0');
        Observer.Expect('tab', 'rejected|0');
        Observer.Verify();
    end;

    [Test]
    procedure OBC_More_EnumFieldSpaceMid()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // An Enum field of "LT OBC Enum Space Mid", from Beta
        ObserveBlanks(Observer, 12, 2);
        Observer.Expect('empty', 'ok|1');
        Observer.Expect('space', 'ok|1');
        Observer.Expect('two spaces', 'ok|1');
        Observer.Expect('tab', 'ok|1');
        Observer.Expect('statement empty', 'no error|1');
        Observer.Verify();
    end;

    [Test]
    procedure OBC_More_EnumFieldTwoBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // An Enum field of "LT OBC Enum Two Blank", from Beta
        ObserveBlanks(Observer, 13, 3);
        Observer.Expect('empty', 'ok|1');
        Observer.Expect('space', 'ok|1');
        Observer.Expect('two spaces', 'ok|1');
        Observer.Expect('tab', 'ok|1');
        Observer.Expect('statement empty', 'no error|1');
        Observer.Verify();
    end;
}
