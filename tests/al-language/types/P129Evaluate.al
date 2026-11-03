// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained enum 73252 and codeunit 73251
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Evaluate of an empty text, a garbage text and texts with embedded blanks into Integer, BigInteger, Decimal, Boolean, Guid, Date, Time, DateTime, Duration, DateFormula, Option and Enum
// with the result UNUSED (a statement), run inside a TryFunction so that both outcomes are observed: the value left in the variable, the error text and the error code.
// BC versions: 29 (27 and 28 by CI)

enum 73252 "LT P129 Color"
{
    Extensible = true;

    value(0; Red) { }
    value(1; "Dark Blue") { }
}

codeunit 73251 "LT P129 Evaluate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure EvInt(Txt: Text; var V: Integer)
    begin
        Evaluate(V, Txt);
    end;

    [TryFunction]
    local procedure EvBig(Txt: Text; var V: BigInteger)
    begin
        Evaluate(V, Txt);
    end;

    [TryFunction]
    local procedure EvDec(Txt: Text; var V: Decimal)
    begin
        Evaluate(V, Txt);
    end;

    [TryFunction]
    local procedure EvDec9(Txt: Text; var V: Decimal)
    begin
        Evaluate(V, Txt, 9);
    end;

    [TryFunction]
    local procedure EvBool(Txt: Text; var V: Boolean)
    begin
        Evaluate(V, Txt);
    end;

    [TryFunction]
    local procedure EvGuid(Txt: Text; var V: Guid)
    begin
        Evaluate(V, Txt);
    end;

    [TryFunction]
    local procedure EvDate(Txt: Text; var V: Date)
    begin
        Evaluate(V, Txt);
    end;

    [TryFunction]
    local procedure EvTime(Txt: Text; var V: Time)
    begin
        Evaluate(V, Txt);
    end;

    [TryFunction]
    local procedure EvDateTime(Txt: Text; var V: DateTime)
    begin
        Evaluate(V, Txt);
    end;

    [TryFunction]
    local procedure EvDuration(Txt: Text; var V: Duration)
    begin
        Evaluate(V, Txt);
    end;

    [TryFunction]
    local procedure EvFormula(Txt: Text; var V: DateFormula)
    begin
        Evaluate(V, Txt);
    end;

    [TryFunction]
    local procedure EvOption(Txt: Text; var V: Option Alpha,"Beta Two",Gamma)
    begin
        Evaluate(V, Txt);
    end;

    [TryFunction]
    local procedure EvEnum(Txt: Text; var V: Enum "LT P129 Color")
    begin
        Evaluate(V, Txt);
    end;

    local procedure Res(Ok: Boolean; ValueText: Text): Text
    begin
        if Ok then
            exit('ok|' + ValueText);
        exit('err|' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure OfInt(Txt: Text): Text
    var
        V: Integer;
    begin
        V := 99;
        ClearLastError();
        exit(Res(EvInt(Txt, V), Format(V)));
    end;

    local procedure OfBig(Txt: Text): Text
    var
        V: BigInteger;
    begin
        V := 99;
        ClearLastError();
        exit(Res(EvBig(Txt, V), Format(V)));
    end;

    local procedure OfDec(Txt: Text): Text
    var
        V: Decimal;
    begin
        V := 99;
        ClearLastError();
        exit(Res(EvDec(Txt, V), Format(V, 0, 9)));
    end;

    local procedure OfDec9(Txt: Text): Text
    var
        V: Decimal;
    begin
        V := 99;
        ClearLastError();
        exit(Res(EvDec9(Txt, V), Format(V, 0, 9)));
    end;

    local procedure OfBool(Txt: Text): Text
    var
        V: Boolean;
    begin
        V := true;
        ClearLastError();
        exit(Res(EvBool(Txt, V), Format(V)));
    end;

    local procedure OfGuid(Txt: Text): Text
    var
        V: Guid;
    begin
        ClearLastError();
        exit(Res(EvGuid(Txt, V), Format(V)));
    end;

    local procedure OfDate(Txt: Text): Text
    var
        V: Date;
    begin
        V := 20240305D;
        ClearLastError();
        exit(Res(EvDate(Txt, V), Format(V, 0, 9)));
    end;

    local procedure OfTime(Txt: Text): Text
    var
        V: Time;
    begin
        V := 134506T;
        ClearLastError();
        exit(Res(EvTime(Txt, V), Format(V, 0, 9)));
    end;

    local procedure OfDateTime(Txt: Text): Text
    var
        V: DateTime;
    begin
        V := CreateDateTime(20240305D, 134506T);
        ClearLastError();
        exit(Res(EvDateTime(Txt, V), Format(V, 0, 9)));
    end;

    local procedure OfDuration(Txt: Text): Text
    var
        V: Duration;
    begin
        V := 5000;
        ClearLastError();
        exit(Res(EvDuration(Txt, V), Format(V, 0, 9)));
    end;

    local procedure OfFormula(Txt: Text): Text
    var
        V: DateFormula;
    begin
        Evaluate(V, '<1M>');
        ClearLastError();
        exit(Res(EvFormula(Txt, V), Format(V)));
    end;

    local procedure OfOption(Txt: Text): Text
    var
        V: Option Alpha,"Beta Two",Gamma;
    begin
        V := V::Gamma;
        ClearLastError();
        exit(Res(EvOption(Txt, V), Format(V) + '|' + Format(V, 0, 2)));
    end;

    local procedure OfEnum(Txt: Text): Text
    var
        V: Enum "LT P129 Color";
    begin
        V := V::"Dark Blue";
        ClearLastError();
        exit(Res(EvEnum(Txt, V), Format(V) + '|' + Format(V.AsInteger())));
    end;

    [Test]
    procedure P129_Evaluate_EmptyAndGarbage_Numbers_ResultUnused()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('int empty', OfInt(''));
        Observer.Observe('int x', OfInt('x'));
        Observer.Observe('big empty', OfBig(''));
        Observer.Observe('big x', OfBig('x'));
        Observer.Observe('dec empty', OfDec(''));
        Observer.Observe('dec x', OfDec('x'));
        Observer.Observe('dec9 empty', OfDec9(''));
        Observer.Observe('bool empty', OfBool(''));
        Observer.Observe('bool x', OfBool('x'));
        Observer.Observe('guid empty', OfGuid(''));
        Observer.Observe('guid x', OfGuid('x'));
        Observer.Expect('int empty', 'err|The value "" can''t be evaluated into type Integer.|Evaluate');
        Observer.Expect('int x', 'err|The value "x" can''t be evaluated into type Integer.|Evaluate');
        Observer.Expect('big empty', 'err|The value "" can''t be evaluated into type BigInteger.|Evaluate');
        Observer.Expect('big x', 'err|The value "x" can''t be evaluated into type BigInteger.|Evaluate');
        Observer.Expect('dec empty', 'err|The value "" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('dec x', 'err|The value "x" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('dec9 empty', 'err|The value "" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('bool empty', 'err|The value "" can''t be evaluated into type Boolean.|Evaluate');
        Observer.Expect('bool x', 'err|The value "x" can''t be evaluated into type Boolean.|Evaluate');
        Observer.Expect('guid empty', 'err|Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|InvalidGuidFormat');
        Observer.Expect('guid x', 'err|Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|InvalidGuidFormat');
        Observer.Verify();
    end;

    [Test]
    procedure P129_Evaluate_EmptyAndGarbage_TemporalAndOther_ResultUnused()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('date empty', OfDate(''));
        Observer.Observe('date x', OfDate('x'));
        Observer.Observe('time empty', OfTime(''));
        Observer.Observe('time x', OfTime('x'));
        Observer.Observe('datetime empty', OfDateTime(''));
        Observer.Observe('datetime x', OfDateTime('x'));
        Observer.Observe('duration empty', OfDuration(''));
        Observer.Observe('duration x', OfDuration('x'));
        Observer.Observe('formula empty', OfFormula(''));
        Observer.Observe('formula x', OfFormula('x'));
        Observer.Observe('option empty', OfOption(''));
        Observer.Observe('option x', OfOption('x'));
        Observer.Observe('enum empty', OfEnum(''));
        Observer.Observe('enum x', OfEnum('x'));
        Observer.Expect('date empty', 'ok|');
        Observer.Expect('date x', 'err|The format of the Date ''x'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Evaluate');
        Observer.Expect('time empty', 'ok|');
        Observer.Expect('time x', 'err|The value "x" can''t be evaluated into type Time.|Evaluate');
        Observer.Expect('datetime empty', 'ok|');
        Observer.Expect('datetime x', 'err|The value "x" can''t be evaluated into type DateTime.|Evaluate');
        Observer.Expect('duration empty', 'ok|P0DT0H0M0.0S');
        Observer.Expect('duration x', 'err|The value "x" can''t be evaluated into type Duration.|Evaluate');
        Observer.Expect('formula empty', 'ok|');
        Observer.Expect('formula x', 'err|The date formula ''X'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.|Evaluate');
        Observer.Expect('option empty', 'err|'''' is not an option. The existing options are: Alpha,Beta Two,Gamma|InvalidOptionString');
        Observer.Expect('option x', 'err|''x'' is not an option. The existing options are: Alpha,Beta Two,Gamma|InvalidOptionString');
        Observer.Expect('enum empty', 'err|'''' is not an option. The existing options are: Red,Dark Blue|InvalidOptionString');
        Observer.Expect('enum x', 'err|''x'' is not an option. The existing options are: Red,Dark Blue|InvalidOptionString');
        Observer.Verify();
    end;

    [Test]
    procedure P129_Evaluate_Decimal_BlanksAndOddForms()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
        Txt: Text;
    begin
        Texts.Add('1 3');
        Texts.Add('1  3');
        Texts.Add(' 1');
        Texts.Add('1 ');
        Texts.Add(' 1 ');
        Texts.Add(' ');
        Texts.Add('+1.5');
        Texts.Add('1,2,3');
        Texts.Add('1,23');
        Texts.Add('1.2.3');
        Texts.Add('--1');
        Texts.Add('- 1');
        Texts.Add('1 .5');
        Texts.Add('1. 5');
        Texts.Add('0x10');
        Texts.Add('1_000');
        Texts.Add('1.5 ');
        Texts.Add('NaN');
        Texts.Add('1e');
        Texts.Add('1e+2');
        Texts.Add('1E-2');
        Texts.Add('00012');
        Texts.Add('-0');
        foreach Txt in Texts do
            Observer.Observe('dec[' + Txt + ']', OfDec(Txt));
        Observer.Expect('dec[1 3]', 'err|The value "1 3" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('dec[1  3]', 'err|The value "1  3" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('dec[ 1]', 'ok|1');
        Observer.Expect('dec[1 ]', 'ok|1');
        Observer.Expect('dec[ 1 ]', 'ok|1');
        Observer.Expect('dec[ ]', 'err|The value " " can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('dec[+1.5]', 'ok|1.5');
        Observer.Expect('dec[1,2,3]', 'ok|123');
        Observer.Expect('dec[1,23]', 'ok|123');
        Observer.Expect('dec[1.2.3]', 'err|The value "1.2.3" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('dec[--1]', 'err|The value "--1" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('dec[- 1]', 'err|The value "- 1" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('dec[1 .5]', 'err|The value "1 .5" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('dec[1. 5]', 'err|The value "1. 5" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('dec[0x10]', 'err|The value "0x10" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('dec[1_000]', 'err|The value "1_000" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('dec[1.5 ]', 'ok|1.5');
        Observer.Expect('dec[NaN]', 'err|The value "NaN" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('dec[1e]', 'err|The value "1e" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('dec[1e+2]', 'ok|100');
        Observer.Expect('dec[1E-2]', 'ok|0.01');
        Observer.Expect('dec[00012]', 'ok|12');
        Observer.Expect('dec[-0]', 'ok|0');
        Observer.Verify();
    end;

    [Test]
    procedure P129_Evaluate_Decimal_Format9_BlanksAndOddForms()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
        Txt: Text;
    begin
        Texts.Add('1 3');
        Texts.Add(' 1');
        Texts.Add('1 ');
        Texts.Add('+1.5');
        Texts.Add('1,5');
        Texts.Add('1e3');
        Texts.Add('.5');
        Texts.Add('5.');
        Texts.Add('-');
        Texts.Add('1.2.3');
        Texts.Add('00012');
        Texts.Add('1 000.5');
        foreach Txt in Texts do
            Observer.Observe('dec9[' + Txt + ']', OfDec9(Txt));
        Observer.Expect('dec9[1 3]', 'err|The value "1 3" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('dec9[ 1]', 'ok|1');
        Observer.Expect('dec9[1 ]', 'ok|1');
        Observer.Expect('dec9[+1.5]', 'ok|1.5');
        Observer.Expect('dec9[1,5]', 'err|The value "1,5" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('dec9[1e3]', 'ok|1000');
        Observer.Expect('dec9[.5]', 'ok|0.5');
        Observer.Expect('dec9[5.]', 'ok|5');
        Observer.Expect('dec9[-]', 'err|The value "-" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('dec9[1.2.3]', 'err|The value "1.2.3" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('dec9[00012]', 'ok|12');
        Observer.Expect('dec9[1 000.5]', 'err|The value "1 000.5" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure P129_Evaluate_IntegerAndBigInteger_BlanksAndOddForms()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
        Txt: Text;
    begin
        Texts.Add('1 3');
        Texts.Add('1  3');
        Texts.Add(' 12');
        Texts.Add('12 ');
        Texts.Add(' ');
        Texts.Add('1_000');
        Texts.Add('1,000');
        Texts.Add('1,00');
        Texts.Add('+ 7');
        Texts.Add('007');
        Texts.Add('-0');
        Texts.Add('12.0');
        foreach Txt in Texts do begin
            Observer.Observe('int[' + Txt + ']', OfInt(Txt));
            Observer.Observe('big[' + Txt + ']', OfBig(Txt));
        end;
        Observer.Expect('int[1 3]', 'err|The value "1 3" can''t be evaluated into type Integer.|Evaluate');
        Observer.Expect('big[1 3]', 'err|The value "1 3" can''t be evaluated into type BigInteger.|Evaluate');
        Observer.Expect('int[1  3]', 'err|The value "1  3" can''t be evaluated into type Integer.|Evaluate');
        Observer.Expect('big[1  3]', 'err|The value "1  3" can''t be evaluated into type BigInteger.|Evaluate');
        Observer.Expect('int[ 12]', 'ok|12');
        Observer.Expect('big[ 12]', 'ok|12');
        Observer.Expect('int[12 ]', 'ok|12');
        Observer.Expect('big[12 ]', 'ok|12');
        Observer.Expect('int[ ]', 'err|The value " " can''t be evaluated into type Integer.|Evaluate');
        Observer.Expect('big[ ]', 'err|The value " " can''t be evaluated into type BigInteger.|Evaluate');
        Observer.Expect('int[1_000]', 'err|The value "1_000" can''t be evaluated into type Integer.|Evaluate');
        Observer.Expect('big[1_000]', 'err|The value "1_000" can''t be evaluated into type BigInteger.|Evaluate');
        Observer.Expect('int[1,000]', 'ok|1000');
        Observer.Expect('big[1,000]', 'ok|1000');
        Observer.Expect('int[1,00]', 'ok|100');
        Observer.Expect('big[1,00]', 'ok|100');
        Observer.Expect('int[+ 7]', 'err|The value "+ 7" can''t be evaluated into type Integer.|Evaluate');
        Observer.Expect('big[+ 7]', 'ok|7');
        Observer.Expect('int[007]', 'ok|7');
        Observer.Expect('big[007]', 'ok|7');
        Observer.Expect('int[-0]', 'ok|0');
        Observer.Expect('big[-0]', 'ok|0');
        Observer.Expect('int[12.0]', 'ok|12');
        Observer.Expect('big[12.0]', 'ok|12');
        Observer.Verify();
    end;
}
