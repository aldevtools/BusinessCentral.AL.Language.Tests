// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 75147-75153 (LT OBC ...)
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
