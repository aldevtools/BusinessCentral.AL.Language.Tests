// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-handling-errors
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), tables 70064
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: runtime error codes
// BC versions: 29 (27 and 28 by CI)

codeunit 70072 "LT ErT Runtime Errors"
{
    Subtype = Test;
    TestPermissions = Disabled;

#if BC28PLUS
    [Test]
    procedure RecordNotFoundAndExists()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT ErT Rec";
    begin
        Rec.DeleteAll();
        asserterror Rec.Get(1);
        Observer.ObserveError('getMissing');
        asserterror Rec.Get('x');
        Observer.Observe('getWrongType|raised', Format(GetLastErrorText() <> ''));
        ClearLastError();
        Rec.Id := 1;
        Rec.Insert();
        Rec.Id := 1;
        Rec.Insert();
        Observer.Observe('duplicate', 'no error');
        Rec.Id := 2;
        asserterror Rec.Modify();
        Observer.ObserveError('modifyMissing');
        asserterror Rec.Delete();
        Observer.ObserveError('deleteMissing');
        Rec.Reset();
        Observer.Observe('findFirstExists', Format(Rec.FindFirst()));
        Rec.DeleteAll();
        asserterror Rec.FindFirst();
        Observer.ObserveError('findFirstEmpty');
        asserterror Rec.FindLast();
        Observer.ObserveError('findLastEmpty');
        asserterror Rec.FindSet();
        Observer.ObserveError('findSetEmpty');
        Observer.Expect('getMissing|text', 'The LT ErT Rec does not exist. Identification fields and values: Id=''1''');
        Observer.Expect('getMissing|code', 'DB:RecordNotFound');
        Observer.Expect('getWrongType|raised', 'Yes');
        Observer.Expect('duplicate', 'no error');
        Observer.Expect('modifyMissing|text', 'The record in table LT ErT Rec already exists. Identification fields and values: Id=''1''');
        Observer.Expect('modifyMissing|code', 'DB:RecordExists');
        Observer.Expect('deleteMissing|text', 'The LT ErT Rec does not exist. Identification fields and values: Id=''2''');
        Observer.Expect('deleteMissing|code', 'DB:RecordNotFound');
        Observer.Expect('findFirstExists', 'No');
        Observer.Expect('findFirstEmpty|text', 'The LT ErT Rec table is empty.');
        Observer.Expect('findFirstEmpty|code', 'DB:TableIsEmpty');
        Observer.Expect('findLastEmpty|text', 'The LT ErT Rec table is empty.');
        Observer.Expect('findLastEmpty|code', 'DB:TableIsEmpty');
        Observer.Expect('findSetEmpty|text', 'The LT ErT Rec table is empty.');
        Observer.Expect('findSetEmpty|code', 'DB:TableIsEmpty');
        Observer.Verify();
    end;
#endif

    [Test]
    procedure ArithmeticErrors()
    var
        Observer: Codeunit "Probe Observer";
        a: Integer;
        b: Integer;
        d: Decimal;
        big: BigInteger;
    begin
        a := 5;
        asserterror b := a div b;
        Observer.ObserveError('intDivZero');
        asserterror b := a mod b;
        Observer.ObserveError('intModZero');
        asserterror d := a / b;
        Observer.ObserveError('decDivZero');
        a := 2147483647;
        asserterror b := a + 1;
        Observer.ObserveError('intOverflowAdd');
        asserterror b := a * 2;
        Observer.ObserveError('intOverflowMul');
        a := -2147483647;
        asserterror b := a - 2;
        Observer.ObserveError('intOverflowSub');
        big := 9223372036854775807L;
        asserterror big := big + 1;
        Observer.ObserveError('bigOverflow');
        Observer.Expect('intDivZero|text', 'Attempted to divide by zero.');
        Observer.Expect('intDivZero|code', 'AL:DivideByZero');
        Observer.Expect('intModZero|text', 'Attempted to divide by zero.');
        Observer.Expect('intModZero|code', 'AL:DivideByZero');
        Observer.Expect('decDivZero|text', 'Attempted to divide by zero.');
        Observer.Expect('decDivZero|code', 'AL:DivideByZero');
        Observer.Expect('intOverflowAdd|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('intOverflowAdd|code', 'AL:Overflow');
        Observer.Expect('intOverflowMul|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('intOverflowMul|code', 'AL:Overflow');
        Observer.Expect('intOverflowSub|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('intOverflowSub|code', 'AL:Overflow');
        Observer.Expect('bigOverflow|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('bigOverflow|code', 'AL:Overflow');
        Observer.Verify();
    end;

    [Test]
    procedure ConversionErrors()
    var
        Observer: Codeunit "Probe Observer";
        a: Integer;
        d: Decimal;
        dt: Date;
        t: Time;
        g: Guid;
        c: Code[3];
        txt: Text[3];
    begin
        Observer.Observe('evalFalse', Format(Evaluate(a, 'abc')));
        Observer.Observe('evalInt', Format(Evaluate(a, '12')));
        Observer.Observe('evalIntBad', Format(Evaluate(a, '1.5')));
        Observer.Observe('evalDec', Format(Evaluate(d, '1,5')));
        Observer.Observe('evalDate', Format(Evaluate(dt, '99/99/99')));
        Observer.Observe('evalTime', Format(Evaluate(t, '99:99')));
        Observer.Observe('evalGuid', Format(Evaluate(g, 'nonsense')));
        asserterror c := 'abcdef';
        Observer.ObserveError('codeTooLong');
        asserterror txt := 'abcdef';
        Observer.ObserveError('textTooLong');
        Observer.Expect('evalFalse', 'No');
        Observer.Expect('evalInt', 'Yes');
        Observer.Expect('evalIntBad', 'No');
        Observer.Expect('evalDec', 'Yes');
        Observer.Expect('evalDate', 'No');
        Observer.Expect('evalTime', 'No');
        Observer.Expect('evalGuid', 'No');
        Observer.Expect('codeTooLong|text', 'The length of the string is 6, but it must be less than or equal to 3 characters. Value: abcdef');
        Observer.Expect('codeTooLong|code', 'StringLengthExceeded');
        Observer.Expect('textTooLong|text', 'The length of the string is 6, but it must be less than or equal to 3 characters. Value: abcdef');
        Observer.Expect('textTooLong|code', 'StringLengthExceeded');
        Observer.Verify();
    end;

    [Test]
    procedure IndexAndRangeErrors()
    var
        Observer: Codeunit "Probe Observer";
        Arr: array[3] of Integer;
        L: List of [Integer];
        D: Dictionary of [Text, Integer];
        Txt: Text;
        Idx: Integer;
        Ch: Char;
    begin
        Idx := 4;
        asserterror Arr[Idx] := 1;
        Observer.ObserveError('arrayHigh');
        Idx := 0;
        asserterror Arr[Idx] := 1;
        Observer.ObserveError('arrayZero');
        Idx := -1;
        asserterror Arr[Idx] := 1;
        Observer.ObserveError('arrayNegative');
        asserterror Idx := L.Get(1);
        Observer.ObserveError('listEmptyGet');
        L.Add(1);
        asserterror Idx := L.Get(2);
        Observer.ObserveError('listHigh');
        asserterror Idx := L.Get(0);
        Observer.ObserveError('listZero');
        asserterror Idx := D.Get('k');
        Observer.ObserveError('dictMissing');
        Txt := 'abc';
        Ch := Txt[4];
        Observer.Observe('textIndexHigh', 'no error');
        asserterror Ch := Txt[0];
        Observer.ObserveError('textIndexZero');
        Observer.Expect('arrayHigh|text', 'Index out of bounds.');
        Observer.Expect('arrayHigh|code', 'IndexOutOfBounds');
        Observer.Expect('arrayZero|text', 'Index out of bounds.');
        Observer.Expect('arrayZero|code', 'IndexOutOfBounds');
        Observer.Expect('arrayNegative|text', 'Index out of bounds.');
        Observer.Expect('arrayNegative|code', 'IndexOutOfBounds');
        Observer.Expect('listEmptyGet|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('listEmptyGet|code', 'ArgumentOutOfRange');
        Observer.Expect('listHigh|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('listHigh|code', 'ArgumentOutOfRange');
        Observer.Expect('listZero|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('listZero|code', 'ArgumentOutOfRange');
        Observer.Expect('dictMissing|text', 'The given key was not present in the dictionary.');
        Observer.Expect('dictMissing|code', 'KeyNotFound');
        Observer.Expect('textIndexHigh', 'no error');
        Observer.Expect('textIndexZero|text', 'The value of INDEXING parameter 1 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647.');
        Observer.Expect('textIndexZero|code', 'OutsidePermittedRange');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRangeAndFormatErrors()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT ErT Rec";
    begin
        Rec.Validate(Small, 0);
        Observer.Observe('belowMin', 'no error');
        Rec.Validate(Small, 11);
        Observer.Observe('aboveMax', 'no error');
        Rec.Validate(Small, 10);
        Observer.Observe('okMax', Format(Rec.Small));
        asserterror Rec.Validate(Code, 'ABCDEFGHIJK');
        Observer.ObserveError('codeTooLong');
        Observer.Expect('belowMin', 'no error');
        Observer.Expect('aboveMax', 'no error');
        Observer.Expect('okMax', '10');
        Observer.Expect('codeTooLong|text', 'The length of the string is 11, but it must be less than or equal to 10 characters. Value: ABCDEFGHIJK');
        Observer.Expect('codeTooLong|code', 'StringLengthExceeded');
        Observer.Verify();
    end;

    [Test]
    procedure CallOnUninitializedAndNull()
    var
        Observer: Codeunit "Probe Observer";
        Txt: Text;
        Idx: Integer;
    begin
        Txt := 'abc';
        asserterror Txt := CopyStr(Txt, -1, 2);
        Observer.ObserveError('copyStrNegative');
        asserterror Txt := PadStr(Txt, -1);
        Observer.ObserveError('padStrNegative');
        asserterror Txt := Txt.Substring(10);
        Observer.ObserveError('substringBeyond');
        asserterror Txt := Txt.Substring(0);
        Observer.ObserveError('substringZero');
        Observer.Expect('copyStrNegative|text', 'The value of COPYSTR parameter 2 is outside of the permitted range. The current value is: -1. The permitted range is: from 1 to 2,147,483,647.');
        Observer.Expect('copyStrNegative|code', 'OutsidePermittedRange');
        Observer.Expect('padStrNegative|text', 'The value of PADSTR parameter 2 is outside of the permitted range. The current value is: -1. The permitted range is: from 0 to 2,147,483,647.');
        Observer.Expect('padStrNegative|code', 'OutsidePermittedRange');
        Observer.Expect('substringBeyond|text', 'startIndex cannot be larger than length of string. (Parameter ''startIndex'')');
        Observer.Expect('substringBeyond|code', 'ArgumentOutOfRange');
        Observer.Expect('substringZero|text', 'startIndex (''-1'') must be a non-negative value. (Parameter ''startIndex'')\Actual value was -1.');
        Observer.Expect('substringZero|code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;
}
