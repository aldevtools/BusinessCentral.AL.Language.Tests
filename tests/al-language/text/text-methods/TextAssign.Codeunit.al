// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Text[n] and Code[n] assignment truncation and overflow.
// BC versions: 29 (27 and 28 by CI)

codeunit 70513 "LT TxB TextAssign"
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
    procedure TextNAssign()
    begin
        T5 := 'abcde';
        Obs.Observe('exact', Format(T5));
        T5 := 'abc';
        Obs.Observe('short', Format(T5));
        T5 := '';
        Obs.Observe('empty', Format(T5));
        asserterror T5 := 'abcdef';
        Obs.ObserveError('over');
        Obs.Observe('keepsold', Format(T5));
        T5 := 'abcde';
        asserterror T5 := 'abcdefghij';
        Obs.ObserveError('over2');
        Obs.Observe('keepsold2', Format(T5));
        T5 := 'ab   ';
        Obs.Observe('blanks', Format(StrLen(T5)));
        asserterror T5 := 'abcd  ';
        Obs.ObserveError('blanksover');
        T5 := '     ';
        Obs.Observe('allblank', Format(StrLen(T5)));
        asserterror T5 := '      ';
        Obs.ObserveError('overblank');
        T5 := 'äöüßé';
        Obs.Observe('unicode', Format(T5));
        asserterror T5 := 'äöüßéa';
        Obs.ObserveError('unicodeover');
        T := 'abcdef';
        asserterror T5 := T;
        Obs.ObserveError('fromtext');
        T := 'abcde';
        T5 := T;
        Obs.Observe('fromtextok', Format(T5));
        Obs.Observe('labelfit', Format(StrLen(TLabel)));
        Obs.Expect('exact', 'abcde');
        Obs.Expect('short', 'abc');
        Obs.Expect('empty', '');
        Obs.Expect('over|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: abcdef');
        Obs.Expect('over|code', 'StringLengthExceeded');
        Obs.Expect('keepsold', '');
        Obs.Expect('over2|text', 'The length of the string is 10, but it must be less than or equal to 5 characters. Value: abcdefghij');
        Obs.Expect('over2|code', 'StringLengthExceeded');
        Obs.Expect('keepsold2', 'abcde');
        Obs.Expect('blanks', '5');
        Obs.Expect('blanksover|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: abcd  ');
        Obs.Expect('blanksover|code', 'StringLengthExceeded');
        Obs.Expect('allblank', '5');
        Obs.Expect('overblank|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value:       ');
        Obs.Expect('overblank|code', 'StringLengthExceeded');
        Obs.Expect('unicode', 'äöüßé');
        Obs.Expect('unicodeover|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: äöüßéa');
        Obs.Expect('unicodeover|code', 'StringLengthExceeded');
        Obs.Expect('fromtext|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: abcdef');
        Obs.Expect('fromtext|code', 'StringLengthExceeded');
        Obs.Expect('fromtextok', 'abcde');
        Obs.Expect('labelfit', '11');
        Obs.Verify();
    end;

    [Test]
    procedure CodeNAssign()
    begin
        C5 := 'abcde';
        Obs.Observe('exact', Format(C5));
        C5 := 'abc';
        Obs.Observe('upper', Format(C5));
        C5 := 'aBc';
        Obs.Observe('mixed', Format(C5));
        C5 := '';
        Obs.Observe('empty', Format(C5));
        asserterror C5 := 'abcdef';
        Obs.ObserveError('over');
        Obs.Observe('keepsold', Format(C5));
        C5 := 'abc';
        asserterror C5 := 'abcdefghij';
        Obs.ObserveError('over2');
        Obs.Observe('keepsold2', Format(C5));
        C5 := '  ab';
        Obs.Observe('leadblank', Format(C5));
        Obs.Observe('leadblanklen', Format(StrLen(C5)));
        C5 := 'ab  ';
        Obs.Observe('trailblank', Format(StrLen(C5)));
        C5 := '     ';
        Obs.Observe('allblank', Format(StrLen(C5)));
        Obs.Observe('allblankeq', Format(C5 = ''));
        C5 := '      ';
        Obs.Observe('overblank', 'no error');
        C5 := 'äöüßé';
        Obs.Observe('unicode', Format(C5));
        T := 'abcdef';
        asserterror C5 := T;
        Obs.ObserveError('fromtext');
        T := 'ab';
        C5 := T;
        Obs.Observe('fromtextok', Format(C5));
        Obs.Expect('exact', 'ABCDE');
        Obs.Expect('upper', 'ABC');
        Obs.Expect('mixed', 'ABC');
        Obs.Expect('empty', '');
        Obs.Expect('over|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: abcdef');
        Obs.Expect('over|code', 'StringLengthExceeded');
        Obs.Expect('keepsold', '');
        Obs.Expect('over2|text', 'The length of the string is 10, but it must be less than or equal to 5 characters. Value: abcdefghij');
        Obs.Expect('over2|code', 'StringLengthExceeded');
        Obs.Expect('keepsold2', 'ABC');
        Obs.Expect('leadblank', 'AB');
        Obs.Expect('leadblanklen', '2');
        Obs.Expect('trailblank', '2');
        Obs.Expect('allblank', '0');
        Obs.Expect('allblankeq', 'Yes');
        Obs.Expect('overblank', 'no error');
        Obs.Expect('unicode', 'ÄÖÜßÉ');
        Obs.Expect('fromtext|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: abcdef');
        Obs.Expect('fromtext|code', 'StringLengthExceeded');
        Obs.Expect('fromtextok', 'AB');
        Obs.Verify();
    end;

    [Test]
    procedure CodeTrimUpper()
    begin
        C10 := 'abc  ';
        Obs.Observe('a', Format(C10));
        Obs.Observe('alen', Format(StrLen(C10)));
        C10 := '  abc';
        Obs.Observe('b', Format(C10));
        Obs.Observe('blen', Format(StrLen(C10)));
        C10 := ' a b ';
        Obs.Observe('c', Format(C10));
        Obs.Observe('clen', Format(StrLen(C10)));
        C10 := 'a'+' ';
        Obs.Observe('d', Format(StrLen(C10)));
        T := '  x  ';
        C10 := T;
        Obs.Observe('ft', Format(C10));
        Obs.Observe('ftlen', Format(StrLen(C10)));
        C5 := C10;
        Obs.Observe('cc', Format(C5));
        T := C10;
        Obs.Observe('tfromc', Format(T));
        Obs.Observe('tfromclen', Format(StrLen(T)));
        C10 := 'ß';
        Obs.Observe('sz', Format(C10));
        C10 := 'ÿ';
        Obs.Observe('yuml', Format(C10));
        C10 := 'é';
        Obs.Observe('eacute', Format(C10));
        C10 := 'ǆ';
        Obs.Observe('dz', Format(C10));
        Obs.Expect('a', 'ABC');
        Obs.Expect('alen', '3');
        Obs.Expect('b', 'ABC');
        Obs.Expect('blen', '3');
        Obs.Expect('c', 'A B');
        Obs.Expect('clen', '3');
        Obs.Expect('d', '1');
        Obs.Expect('ft', 'X');
        Obs.Expect('ftlen', '1');
        Obs.Expect('cc', 'X');
        Obs.Expect('tfromc', 'X');
        Obs.Expect('tfromclen', '1');
        Obs.Expect('sz', 'ß');
        Obs.Expect('yuml', 'Ÿ');
        Obs.Expect('eacute', 'É');
        Obs.Expect('dz', 'Ǆ');
        Obs.Verify();
    end;

    [Test]
    procedure TextNtoCodeAndBack()
    begin
        T5 := 'ab';
        C5 := T5;
        Obs.Observe('t5toc5', Format(C5));
        C10 := 'XyZ';
        T := C10;
        Obs.Observe('ctot', Format(T));
        T5 := C10;
        Obs.Observe('ctot5', Format(T5));
        C10 := 'abcdefgh';
        asserterror T5 := C10;
        Obs.ObserveError('c10toT5');
        asserterror C5 := C10;
        Obs.ObserveError('c10toC5');
        C10 := 'abcde';
        C5 := C10;
        Obs.Observe('fit', Format(C5));
        Obs.Observe('textcompare', Format(T5 = 'ab'));
        asserterror C5 := T5 + 'cde';
        Obs.ObserveError('af156');
        Obs.Observe('concatfit', Format(C5));
        asserterror C5 := T5 + 'cdef';
        Obs.ObserveError('concatover');
        Obs.Expect('t5toc5', 'AB');
        Obs.Expect('ctot', 'XYZ');
        Obs.Expect('ctot5', 'XYZ');
        Obs.Expect('c10toT5|text', 'The length of the string is 8, but it must be less than or equal to 5 characters. Value: ABCDEFGH');
        Obs.Expect('c10toT5|code', 'StringLengthExceeded');
        Obs.Expect('c10toC5|text', 'The length of the string is 8, but it must be less than or equal to 5 characters. Value: ABCDEFGH');
        Obs.Expect('c10toC5|code', 'StringLengthExceeded');
        Obs.Expect('fit', 'ABCDE');
        Obs.Expect('textcompare', 'No');
        Obs.Expect('af156|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: XYZcde');
        Obs.Expect('af156|code', 'StringLengthExceeded');
        Obs.Expect('concatfit', 'ABCDE');
        Obs.Expect('concatover|text', 'The length of the string is 7, but it must be less than or equal to 5 characters. Value: XYZcdef');
        Obs.Expect('concatover|code', 'StringLengthExceeded');
        Obs.Verify();
    end;

    // Corpus issue 672 (odd AL behavior leads, part G), item 56: a Text[100] value longer than 20 characters passed to a
    // Code[20] value parameter, against assigning it to a Code[20] variable. Passing it to a var Code[20] parameter does not
    // compile (AL0133, tests/must-not-compile/cases/1539).
    [Test]
    procedure LT_BU_TextAssign_LongTextToCode20Parameter()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record Item;
        T100: Text[100];
        C20: Code[20];
        R: Text;
    begin
        Item.Description := 'abcdefghijklmnopqrstu';
        T100 := 'abcdefghijklmnopqrstu';
        ClearLastError();
        if TryTakeCode20(Item.Description, R) then
            Observer.Observe('field to code20 param', R)
        else
            Observer.Observe('field to code20 param', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TryTakeCode20(T100, R) then
            Observer.Observe('text100 to code20 param', R)
        else
            Observer.Observe('text100 to code20 param', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Item.Description := 'abcdefghijklmnopqrst';
        ClearLastError();
        if TryTakeCode20(Item.Description, R) then
            Observer.Observe('field 20 chars to code20 param', R)
        else
            Observer.Observe('field 20 chars to code20 param', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Item.Description := ' abcdefghijklmnopqrst ';
        ClearLastError();
        if TryTakeCode20(Item.Description, R) then
            Observer.Observe('field 20 chars with blanks to code20 param', R)
        else
            Observer.Observe('field 20 chars with blanks to code20 param', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        asserterror C20 := T100;
        Observer.ObserveError('text100 to code20 variable');
        Observer.Expect('field to code20 param', 'error:The length of the string is 21, but it must be less than or equal to 20 characters. Value: abcdefghijklmnopqrstu|StringLengthExceeded');
        Observer.Expect('text100 to code20 param', 'error:The length of the string is 21, but it must be less than or equal to 20 characters. Value: abcdefghijklmnopqrstu|StringLengthExceeded');
        Observer.Expect('field 20 chars to code20 param', 'ABCDEFGHIJKLMNOPQRST|20');
        Observer.Expect('field 20 chars with blanks to code20 param', 'ABCDEFGHIJKLMNOPQRST|20');
        Observer.Expect('text100 to code20 variable|text', 'The length of the string is 21, but it must be less than or equal to 20 characters. Value: abcdefghijklmnopqrstu');
        Observer.Expect('text100 to code20 variable|code', 'StringLengthExceeded');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryTakeCode20(Value: Code[20]; var R: Text)
    begin
        R := Value + '|' + Format(StrLen(Value));
    end;
    // Writer PY-C (al-runtime-rs PR 339, probes-needed "Ternary and call-argument conversion"): a by-value number argument of a TryFunction
    // whose conversion fails (Decimal 2.5 and BigInteger 3e9 into an Integer parameter): caught by the try or raised at the call. The call
    // stands inside a second TryFunction so an uncaught error is still observed; 'inner' says whether the inner try answered false.
    [Test]
    procedure PYC_TryFunction_NumberArgumentConversion()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
        B: BigInteger;
        Inner: Text;
    begin
        D := 2.5;
        ClearLastError();
        if OuterDecimal(D, Inner) then
            Observer.Observe('decimal 2.5', 'outer ok|' + Inner + '|' + GetLastErrorText() + '|' + GetLastErrorCode())
        else
            Observer.Observe('decimal 2.5', 'outer error|' + Inner + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        D := 3;
        ClearLastError();
        if OuterDecimal(D, Inner) then
            Observer.Observe('decimal 3', 'outer ok|' + Inner)
        else
            Observer.Observe('decimal 3', 'outer error|' + Inner + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        B := 3000000000L;
        ClearLastError();
        if OuterBig(B, Inner) then
            Observer.Observe('bigint 3e9', 'outer ok|' + Inner + '|' + GetLastErrorText() + '|' + GetLastErrorCode())
        else
            Observer.Observe('bigint 3e9', 'outer error|' + Inner + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        B := 7;
        ClearLastError();
        if OuterBig(B, Inner) then
            Observer.Observe('bigint 7', 'outer ok|' + Inner)
        else
            Observer.Observe('bigint 7', 'outer error|' + Inner + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('decimal 2.5', 'outer ok|inner false|Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.|ConversionCast');
        Observer.Expect('decimal 3', 'outer ok|inner ok 3');
        Observer.Expect('bigint 3e9', 'outer ok|inner false|Overflow under conversion of System.Int64 value 3000000000 to System.Int32.|ConversionCast');
        Observer.Expect('bigint 7', 'outer ok|inner ok 7');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure OuterDecimal(D: Decimal; var Inner: Text)
    var
        R: Text;
    begin
        Inner := 'not reached';
        if TryTakeInteger(D, R) then
            Inner := 'inner ok ' + R
        else
            Inner := 'inner false';
    end;

    [TryFunction]
    local procedure OuterBig(B: BigInteger; var Inner: Text)
    var
        R: Text;
    begin
        Inner := 'not reached';
        if TryTakeInteger(B, R) then
            Inner := 'inner ok ' + R
        else
            Inner := 'inner false';
    end;

    [TryFunction]
    local procedure TryTakeInteger(Value: Integer; var R: Text)
    begin
        R := Format(Value);
    end;
}
