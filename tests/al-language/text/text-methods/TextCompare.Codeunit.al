// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Text and Code comparison and concatenation.
// BC versions: 29 (27 and 28 by CI)

codeunit 70515 "LT TxB TextCompare"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";
        T: Text;
        T2: Text;
        T5: Text[5];
        C5: Code[5];
        C10: Code[10];
        I: Integer;
        D: Decimal;
        TLabel: Label 'Hello World', Locked = true;
        CLabel: Label 'abc', Locked = true, MaxLength = 10;

    [Test]
    procedure TextEquality()
    begin
        Obs.Observe('a1', Format('abc' = 'abc'));
        Obs.Observe('a2', Format('abc' = 'ABC'));
        Obs.Observe('a3', Format('abc' <> 'ABC'));
        Obs.Observe('a4', Format('abc' = 'abd'));
        Obs.Observe('a5', Format('abc' <> 'abd'));
        Obs.Observe('a6', Format('' = ''));
        Obs.Observe('a7', Format('' = ' '));
        Obs.Observe('a8', Format(' ' = ''));
        Obs.Observe('a9', Format('abc' = 'abc '));
        Obs.Observe('a10', Format('abc ' = 'abc'));
        Obs.Observe('a11', Format(' abc' = 'abc'));
        Obs.Observe('a12', Format('abc' <> 'abc '));
        Obs.Observe('a13', Format('ä' = 'Ä'));
        Obs.Observe('a14', Format('ß' = 'SS'));
        Obs.Observe('a15', Format('é' = 'É'));
        Obs.Observe('a16', Format('a' = 'á'));
        Obs.Observe('a17', Format('日' = '日'));
        Obs.Observe('a18', Format('İ' = 'i'));
        Obs.Observe('a19', Format('ı' = 'I'));
        Obs.Observe('a20', Format('ǆ' = 'ǅ'));
        Obs.Observe('a21', Format('µ' = 'Μ'));
        Obs.Observe('a22', Format('ς' = 'Σ'));
        Obs.Expect('a1', 'Yes');
        Obs.Expect('a2', 'No');
        Obs.Expect('a3', 'Yes');
        Obs.Expect('a4', 'No');
        Obs.Expect('a5', 'Yes');
        Obs.Expect('a6', 'Yes');
        Obs.Expect('a7', 'No');
        Obs.Expect('a8', 'No');
        Obs.Expect('a9', 'No');
        Obs.Expect('a10', 'No');
        Obs.Expect('a11', 'No');
        Obs.Expect('a12', 'Yes');
        Obs.Expect('a13', 'No');
        Obs.Expect('a14', 'No');
        Obs.Expect('a15', 'No');
        Obs.Expect('a16', 'No');
        Obs.Expect('a17', 'Yes');
        Obs.Expect('a18', 'No');
        Obs.Expect('a19', 'No');
        Obs.Expect('a20', 'No');
        Obs.Expect('a21', 'No');
        Obs.Expect('a22', 'No');
        Obs.Verify();
    end;

    [Test]
    procedure TextEqualityVariables()
    begin
        T := 'Hello';
        T2 := 'HELLO';
        C5 := 'hello';
        T5 := 'hello';
        Obs.Observe('tt', Format(T = T2));
        Obs.Observe('tc', Format(T = C5));
        Obs.Observe('ct', Format(C5 = T));
        Obs.Observe('t5c', Format(T5 = C5));
        Obs.Observe('t5t2', Format(T5 = T2));
        Obs.Observe('ne', Format(T <> T2));
        T := 'a ';
        C5 := 'a';
        Obs.Observe('trailing', Format(T = C5));
        Obs.Observe('trailing2', Format(C5 = T));
        T := '';
        Clear(C5);
        Obs.Observe('emptyc', Format(T = C5));
        T := ' ';
        Obs.Observe('blankc', Format(T = C5));
        Obs.Observe('literalvar', Format(C5 = ''));
        Obs.Observe('label', Format(TLabel = 'hello world'));
        Obs.Observe('labelc', Format(CLabel = 'ABC'));
        Obs.Observe('labelcc', Format(CLabel = C5));
        Obs.Expect('tt', 'No');
        Obs.Expect('tc', 'No');
        Obs.Expect('ct', 'No');
        Obs.Expect('t5c', 'No');
        Obs.Expect('t5t2', 'No');
        Obs.Expect('ne', 'Yes');
        Obs.Expect('trailing', 'No');
        Obs.Expect('trailing2', 'No');
        Obs.Expect('emptyc', 'Yes');
        Obs.Expect('blankc', 'No');
        Obs.Expect('literalvar', 'Yes');
        Obs.Expect('label', 'No');
        Obs.Expect('labelc', 'No');
        Obs.Expect('labelcc', 'No');
        Obs.Verify();
    end;

    [Test]
    procedure TextOrdering()
    begin
        Obs.Observe('a1', Format('a' < 'b'));
        Obs.Observe('a2', Format('b' < 'a'));
        Obs.Observe('a3', Format('a' < 'B'));
        Obs.Observe('a4', Format('B' < 'a'));
        Obs.Observe('a5', Format('A' < 'b'));
        Obs.Observe('a6', Format('a' < 'A'));
        Obs.Observe('a7', Format('A' < 'a'));
        Obs.Observe('a8', Format('a' <= 'A'));
        Obs.Observe('a9', Format('a' >= 'A'));
        Obs.Observe('a10', Format('a' > 'A'));
        Obs.Observe('a11', Format('abc' < 'abd'));
        Obs.Observe('a12', Format('abc' < 'abcd'));
        Obs.Observe('a13', Format('abcd' < 'abc'));
        Obs.Observe('a14', Format('' < 'a'));
        Obs.Observe('a15', Format('a' < ''));
        Obs.Observe('a16', Format('' < ' '));
        Obs.Observe('a17', Format(' ' < 'a'));
        Obs.Observe('a18', Format('a' < 'a '));
        Obs.Observe('a19', Format('a ' < 'a'));
        Obs.Observe('a20', Format('a ' <= 'a'));
        Obs.Observe('a21', Format('Z' < 'a'));
        Obs.Observe('a22', Format('z' < 'A'));
        Obs.Observe('a23', Format('1' < 'a'));
        Obs.Observe('a24', Format('a' < '1'));
        Obs.Observe('a25', Format('10' < '9'));
        Obs.Observe('a26', Format('9' < '10'));
        Obs.Observe('a27', Format('ä' < 'b'));
        Obs.Observe('a28', Format('z' < 'ä'));
        Obs.Observe('a29', Format('a' < 'ä'));
        Obs.Observe('a30', Format('ä' < 'a'));
        Obs.Observe('a31', Format('e' < 'é'));
        Obs.Observe('a32', Format('é' < 'f'));
        Obs.Observe('a33', Format('_' < 'a'));
        Obs.Observe('a34', Format('_' < '1'));
        Obs.Observe('a35', Format('-' < '_'));
        Obs.Observe('a36', Format(' ' < '_'));
        Obs.Observe('a37', Format('a' < '日'));
        Obs.Observe('a38', Format('日' < '本'));
        Obs.Observe('a39', Format('ß' < 'ss'));
        Obs.Observe('a40', Format('ss' < 'ß'));
        Obs.Expect('a1', 'Yes');
        Obs.Expect('a2', 'No');
        Obs.Expect('a3', 'Yes');
        Obs.Expect('a4', 'No');
        Obs.Expect('a5', 'Yes');
        Obs.Expect('a6', 'Yes');
        Obs.Expect('a7', 'No');
        Obs.Expect('a8', 'Yes');
        Obs.Expect('a9', 'No');
        Obs.Expect('a10', 'No');
        Obs.Expect('a11', 'Yes');
        Obs.Expect('a12', 'Yes');
        Obs.Expect('a13', 'No');
        Obs.Expect('a14', 'Yes');
        Obs.Expect('a15', 'No');
        Obs.Expect('a16', 'Yes');
        Obs.Expect('a17', 'Yes');
        Obs.Expect('a18', 'Yes');
        Obs.Expect('a19', 'No');
        Obs.Expect('a20', 'No');
        Obs.Expect('a21', 'No');
        Obs.Expect('a22', 'No');
        Obs.Expect('a23', 'Yes');
        Obs.Expect('a24', 'No');
        Obs.Expect('a25', 'Yes');
        Obs.Expect('a26', 'No');
        Obs.Expect('a27', 'Yes');
        Obs.Expect('a28', 'No');
        Obs.Expect('a29', 'Yes');
        Obs.Expect('a30', 'No');
        Obs.Expect('a31', 'Yes');
        Obs.Expect('a32', 'Yes');
        Obs.Expect('a33', 'Yes');
        Obs.Expect('a34', 'Yes');
        Obs.Expect('a35', 'No');
        Obs.Expect('a36', 'Yes');
        Obs.Expect('a37', 'Yes');
        Obs.Expect('a38', 'Yes');
        Obs.Expect('a39', 'No');
        Obs.Expect('a40', 'Yes');
        Obs.Verify();
    end;

    [Test]
    procedure CodeComparison()
    begin
        C5 := 'abc';
        C10 := 'ABC';
        Obs.Observe('eq', Format(C5 = C10));
        C10 := 'abd';
        Obs.Observe('lt', Format(C5 < C10));
        Obs.Observe('gt', Format(C5 > C10));
        Obs.Observe('le', Format(C5 <= C10));
        Obs.Observe('ge', Format(C5 >= C10));
        Obs.Observe('lit', Format(C5 = 'ABC'));
        Obs.Observe('litlt', Format(C5 < 'abd'));
        C5 := 'A';
        C10 := 'a';
        Obs.Observe('same', Format(C5 = C10));
        Obs.Observe('ltcase', Format(C5 < C10));
        C5 := 'B';
        C10 := 'a';
        Obs.Observe('blt', Format(C5 < C10));
        C5 := '1';
        C10 := 'A';
        Obs.Observe('numlt', Format(C5 < C10));
        C5 := '';
        C10 := 'A';
        Obs.Observe('emptylt', Format(C5 < C10));
        C5 := '10';
        C10 := '9';
        Obs.Observe('tenlt', Format(C5 < C10));
        Obs.Expect('eq', 'Yes');
        Obs.Expect('lt', 'Yes');
        Obs.Expect('gt', 'No');
        Obs.Expect('le', 'Yes');
        Obs.Expect('ge', 'No');
        Obs.Expect('lit', 'Yes');
        Obs.Expect('litlt', 'Yes');
        Obs.Expect('same', 'Yes');
        Obs.Expect('ltcase', 'No');
        Obs.Expect('blt', 'No');
        Obs.Expect('numlt', 'Yes');
        Obs.Expect('emptylt', 'Yes');
        Obs.Expect('tenlt', 'No');
        Obs.Verify();
    end;

    [Test]
    procedure Concatenation()
    begin
        T := 'ab';
        C5 := 'cd';
        T5 := 'ef';
        Obs.Observe('tt', Format(T + T));
        Obs.Observe('tc', Format(T + C5));
        Obs.Observe('ct', Format(C5 + T));
        Obs.Observe('cc', Format(C5 + C5));
        Obs.Observe('tt5', Format(T + T5));
        Obs.Observe('empty', Format(T + ''));
        Obs.Observe('emptyempty', Format('' + ''));
        Obs.Observe('emptylen', Format(StrLen('' + '')));
        Obs.Observe('blank', Format(T + ' ' + T));
        Obs.Observe('blankend', Format(StrLen(T + ' ')));
        Obs.Observe('blankc', Format(StrLen(C5 + ' ')));
        Obs.Observe('blankstart', Format(StrLen(' ' + C5)));
        Obs.Observe('literal', Format('a' + 'b' + 'c'));
        Obs.Observe('number', Format('a' + Format(1)));
        Obs.Observe('unicode', Format('ä' + 'ö'));
        Obs.Observe('label', Format(TLabel + '!'));
        Obs.Observe('labelc', Format(CLabel + C5));
        C10 := C5 + 'x';
        Obs.Observe('assign', Format(C10));
        T2 := C5 + C5 + C5;
        Obs.Observe('long', Format(StrLen(T2)));
        T2 := T2 + ' ';
        Obs.Observe('trail', Format(StrLen(T2)));
        Obs.Expect('tt', 'abab');
        Obs.Expect('tc', 'abCD');
        Obs.Expect('ct', 'CDab');
        Obs.Expect('cc', 'CDCD');
        Obs.Expect('tt5', 'abef');
        Obs.Expect('empty', 'ab');
        Obs.Expect('emptyempty', '');
        Obs.Expect('emptylen', '0');
        Obs.Expect('blank', 'ab ab');
        Obs.Expect('blankend', '3');
        Obs.Expect('blankc', '3');
        Obs.Expect('blankstart', '3');
        Obs.Expect('literal', 'abc');
        Obs.Expect('number', 'a1');
        Obs.Expect('unicode', 'äö');
        Obs.Expect('label', 'Hello World!');
        Obs.Expect('labelc', 'abcCD');
        Obs.Expect('assign', 'CDX');
        Obs.Expect('long', '6');
        Obs.Expect('trail', '7');
        Obs.Verify();
    end;

    [Test]
    procedure ConcatenationOverflow()
    begin
        T5 := 'abc';
        C5 := 'abc';
        asserterror T5 := T5 + 'def';
        Obs.ObserveError('t5over');
        Obs.Observe('t5keep', Format(T5));
        asserterror C5 := C5 + 'def';
        Obs.ObserveError('c5over');
        Obs.Observe('c5keep', Format(C5));
        T5 := T5 + 'de';
        Obs.Observe('t5exact', Format(T5));
        C5 := 'ab' + 'cde';
        Obs.Observe('c5exact', Format(C5));
        asserterror C5 := C5 + 'x';
        Obs.ObserveError('c5over2');
        T := PadStr('',100,'a');
        T2 := T + T;
        Obs.Observe('t2len', Format(StrLen(T2)));
        T5 := '';
        T5 := T5 + 'abcde';
        Obs.Observe('t5fromempty', Format(T5));
        asserterror T5 := T5 + ' ';
        Obs.ObserveError('blankover');
        C10 := 'abcde';
        C10 := C10 + '     ';
        Obs.Observe('c10trail', Format(StrLen(C10)));
        asserterror C10 := C10 + 'abcdef';
        Obs.ObserveError('c10over');
        Obs.Expect('t5over|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: abcdef');
        Obs.Expect('t5over|code', 'StringLengthExceeded');
        Obs.Expect('t5keep', 'abc');
        Obs.Expect('c5over|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: ABCdef');
        Obs.Expect('c5over|code', 'StringLengthExceeded');
        Obs.Expect('c5keep', 'ABC');
        Obs.Expect('t5exact', 'abcde');
        Obs.Expect('c5exact', 'ABCDE');
        Obs.Expect('c5over2|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: ABCDEx');
        Obs.Expect('c5over2|code', 'StringLengthExceeded');
        Obs.Expect('t2len', '200');
        Obs.Expect('t5fromempty', 'abcde');
        Obs.Expect('blankover|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: abcde ');
        Obs.Expect('blankover|code', 'StringLengthExceeded');
        Obs.Expect('c10trail', '5');
        Obs.Expect('c10over|text', 'The length of the string is 11, but it must be less than or equal to 10 characters. Value: ABCDEabcdef');
        Obs.Expect('c10over|code', 'StringLengthExceeded');
        Obs.Verify();
    end;
    // Writer PY-C (al-runtime-rs PR 341, "Case label of a Code selector": a plain Code = Text compare outside case). Variables: TextEqualityVariables
    // above (tc/ct: Code 'HELLO' and Text 'Hello' differ). Here: a Code against a text literal and a Text variable, and the order operators.
    [Test]
    procedure PYC_CodeAgainstTextLiteral()
    begin
        C5 := 'abc';
        T := 'abc';
        Obs.Observe('code = lower literal', Format(C5 = 'abc'));
        Obs.Observe('lower literal = code', Format('abc' = C5));
        Obs.Observe('code <> lower literal', Format(C5 <> 'abc'));
        Obs.Observe('code = upper literal', Format(C5 = 'ABC'));
        Obs.Observe('code = lower text var', Format(C5 = T));
        Obs.Observe('code < abd literal', Format(C5 < 'abd'));
        Obs.Observe('code > abd literal', Format(C5 > 'abd'));
        Obs.Observe('code = 8-char literal', Format(C5 = 'abcdefgh'));
        Obs.Observe('code in [lower literal]', Format(C5 in ['abc']));
        Obs.Observe('code in [lower text var]', Format(C5 in [T]));
        C10 := 'abc';
        Obs.Observe('code10 = code5', Format(C10 = C5));
        Obs.Expect('code = lower literal', 'No');
        Obs.Expect('lower literal = code', 'No');
        Obs.Expect('code <> lower literal', 'Yes');
        Obs.Expect('code = upper literal', 'Yes');
        Obs.Expect('code = lower text var', 'No');
        Obs.Expect('code < abd literal', 'Yes');
        Obs.Expect('code > abd literal', 'No');
        Obs.Expect('code = 8-char literal', 'No');
        Obs.Expect('code in [lower literal]', 'Yes');
        Obs.Expect('code in [lower text var]', 'Yes');
        Obs.Expect('code10 = code5', 'Yes');
        Obs.Verify();
    end;
}
