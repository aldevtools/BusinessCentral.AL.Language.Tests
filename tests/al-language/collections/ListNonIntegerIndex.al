// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunit 97434
// Probe: from al-runner issue 7585 (List.Get with a Decimal index; Microsoft's page "Bank Statement File Wizard" calls
//   Get(Round(Count / 2, 1, '>'))).
// Area: the index and count arguments of the List methods (Get, the Get overload with a var value, Set, Insert, RemoveAt, GetRange,
//   RemoveRange) given a value that is not an Integer:
//   - a Decimal variable with a whole value (2), with a fraction (2.5, 2.4, 2.6), 0, 5 (count + 1), -1, 3000000000;
//   - a BigInteger variable (2, 0, 5, 3000000000);
//   - a Decimal expression written directly as the argument (Round(Count / 2, 1, '>'), Count / 2, 5 / 2, the literals 2.0 and 2.5,
//     IndexOf(...) * 1.0);
//   - a Char, an Option and a Byte variable;
//   - and, next to it, an array element read with a Decimal and a BigInteger index.
//   Each case reads the result and the list afterwards, or the error code and text. The calls run in a TryFunction (no database write).
// Already pinned elsewhere, not repeated: an Integer index out of range (ListErrors.al, Err_GetOutOfRange), a Decimal given to an Integer
//   parameter of an AL procedure (types/PRDecimalToInteger.al).
// Observation form: every test ends in Finish(); the values are what BC produced.
// BC versions: 27.5, 28.5, 29.0 (measured by the corpus CI)

codeunit 97434 "COL List Index Types"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Four(var L: List of [Text])
    begin
        Clear(L);
        L.Add('a');
        L.Add('b');
        L.Add('c');
        L.Add('d');
    end;

    local procedure Join(L: List of [Text]): Text
    var
        Item: Text;
        Result: Text;
    begin
        foreach Item in L do
            Result += Item + ',';
        exit(Result);
    end;

    [TryFunction]
    local procedure TryDec(Op: Text; var L: List of [Text]; D: Decimal; var R: Text)
    begin
        case Op of
            'get':
                R := L.Get(D);
            'get var':
                if L.Get(D, R) then
                    R := 'true:' + R
                else
                    R := 'false';
            'set':
                L.Set(D, 'X');
            'insert':
                L.Insert(D, 'X');
            'removeat':
                R := Format(L.RemoveAt(D));
            'getrange index':
                R := Join(L.GetRange(D, 2));
            'getrange count':
                R := Join(L.GetRange(2, D));
            'removerange index':
                R := Format(L.RemoveRange(D, 2));
            'removerange count':
                R := Format(L.RemoveRange(1, D));
        end;
    end;

    [TryFunction]
    local procedure TryBig(Op: Text; var L: List of [Text]; B: BigInteger; var R: Text)
    begin
        case Op of
            'get':
                R := L.Get(B);
            'get var':
                if L.Get(B, R) then
                    R := 'true:' + R
                else
                    R := 'false';
            'set':
                L.Set(B, 'X');
            'insert':
                L.Insert(B, 'X');
            'removeat':
                R := Format(L.RemoveAt(B));
            'getrange index':
                R := Join(L.GetRange(B, 2));
            'getrange count':
                R := Join(L.GetRange(2, B));
            'removerange index':
                R := Format(L.RemoveRange(B, 2));
            'removerange count':
                R := Format(L.RemoveRange(1, B));
        end;
    end;

    local procedure Dec(Op: Text; D: Decimal): Text
    var
        L: List of [Text];
        R: Text;
    begin
        Four(L);
        ClearLastError();
        if TryDec(Op, L, D, R) then
            exit('ok:' + R + '|list=' + Join(L));
        exit('error:' + GetLastErrorCode() + '|' + GetLastErrorText() + '|list=' + Join(L));
    end;

    local procedure Big(Op: Text; B: BigInteger): Text
    var
        L: List of [Text];
        R: Text;
    begin
        Four(L);
        ClearLastError();
        if TryBig(Op, L, B, R) then
            exit('ok:' + R + '|list=' + Join(L));
        exit('error:' + GetLastErrorCode() + '|' + GetLastErrorText() + '|list=' + Join(L));
    end;

    [TryFunction]
    local procedure TryDirect(Form: Text; var L: List of [Text]; var R: Text)
    begin
        case Form of
            'round up half count':
                R := L.Get(Round(L.Count() / 2, 1, '>'));
            'count / 2':
                R := L.Get(L.Count() / 2);
            '5 / 2':
                R := L.Get(5 / 2);
            'literal 2.0':
                R := L.Get(2.0);
            'literal 2.5':
                R := L.Get(2.5);
            'indexof * 1.0':
                R := L.Get(L.IndexOf('c') * 1.0);
            'round nearest 2.5':
                R := L.Get(Round(2.5, 1));
            'set round up half count':
                L.Set(Round(L.Count() / 2, 1, '>'), 'X');
            'insert count / 2':
                L.Insert(L.Count() / 2, 'X');
            'removeat literal 2.0':
                R := Format(L.RemoveAt(2.0));
        end;
    end;

    local procedure Direct(Form: Text): Text
    var
        L: List of [Text];
        R: Text;
    begin
        Four(L);
        ClearLastError();
        if TryDirect(Form, L, R) then
            exit('ok:' + R + '|list=' + Join(L));
        exit('error:' + GetLastErrorCode() + '|' + GetLastErrorText() + '|list=' + Join(L));
    end;

    [TryFunction]
    local procedure TryOther(Kind: Text; var L: List of [Text]; var R: Text)
    var
        C: Char;
        O: Option Zero,One,Two,Three;
        Y: Byte;
    begin
        C := 2;
        O := O::Two;
        Y := 2;
        case Kind of
            'char':
                R := L.Get(C);
            'option':
                R := L.Get(O);
            'byte':
                R := L.Get(Y);
        end;
    end;

    local procedure Other(Kind: Text): Text
    var
        L: List of [Text];
        R: Text;
    begin
        Four(L);
        ClearLastError();
        if TryOther(Kind, L, R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    [TryFunction]
    local procedure TryArrayDec(D: Decimal; var R: Text)
    var
        A: array[4] of Text;
    begin
        A[1] := 'a';
        A[2] := 'b';
        A[3] := 'c';
        A[4] := 'd';
        R := A[D];
    end;

    [TryFunction]
    local procedure TryArrayBig(B: BigInteger; var R: Text)
    var
        A: array[4] of Text;
    begin
        A[1] := 'a';
        A[2] := 'b';
        A[3] := 'c';
        A[4] := 'd';
        R := A[B];
    end;

    local procedure ArrayDec(D: Decimal): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryArrayDec(D, R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    local procedure ArrayBig(B: BigInteger): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryArrayBig(B, R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    [Test]
    procedure List_DecimalIndex_WholeValue_EveryMethod()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('get', Dec('get', 2));
        Observer.Observe('get var', Dec('get var', 2));
        Observer.Observe('set', Dec('set', 2));
        Observer.Observe('insert', Dec('insert', 2));
        Observer.Observe('removeat', Dec('removeat', 2));
        Observer.Observe('getrange index', Dec('getrange index', 2));
        Observer.Observe('getrange count', Dec('getrange count', 2));
        Observer.Observe('removerange index', Dec('removerange index', 2));
        Observer.Observe('removerange count', Dec('removerange count', 2));
        Observer.Expect('get', 'ok:b|list=a,b,c,d,');
        Observer.Expect('get var', 'ok:true:b|list=a,b,c,d,');
        Observer.Expect('set', 'ok:|list=a,X,c,d,');
        Observer.Expect('insert', 'ok:|list=a,X,b,c,d,');
        Observer.Expect('removeat', 'ok:Yes|list=a,c,d,');
        Observer.Expect('getrange index', 'ok:b,c,|list=a,b,c,d,');
        Observer.Expect('getrange count', 'ok:b,c,|list=a,b,c,d,');
        Observer.Expect('removerange index', 'ok:Yes|list=a,d,');
        Observer.Expect('removerange count', 'ok:Yes|list=c,d,');
        Observer.Verify();
    end;

    [Test]
    procedure List_DecimalIndex_Fraction_EveryMethod()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('get', Dec('get', 2.5));
        Observer.Observe('get var', Dec('get var', 2.5));
        Observer.Observe('set', Dec('set', 2.5));
        Observer.Observe('insert', Dec('insert', 2.5));
        Observer.Observe('removeat', Dec('removeat', 2.5));
        Observer.Observe('getrange index', Dec('getrange index', 2.5));
        Observer.Observe('getrange count', Dec('getrange count', 2.5));
        Observer.Observe('removerange index', Dec('removerange index', 2.5));
        Observer.Observe('removerange count', Dec('removerange count', 2.5));
        Observer.Expect('get', 'error:ConversionCast|Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.|list=a,b,c,d,');
        Observer.Expect('get var', 'error:ConversionCast|Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.|list=a,b,c,d,');
        Observer.Expect('set', 'error:ConversionCast|Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.|list=a,b,c,d,');
        Observer.Expect('insert', 'error:ConversionCast|Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.|list=a,b,c,d,');
        Observer.Expect('removeat', 'error:ConversionCast|Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.|list=a,b,c,d,');
        Observer.Expect('getrange index', 'error:ConversionCast|Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.|list=a,b,c,d,');
        Observer.Expect('getrange count', 'error:ConversionCast|Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.|list=a,b,c,d,');
        Observer.Expect('removerange index', 'error:ConversionCast|Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.|list=a,b,c,d,');
        Observer.Expect('removerange count', 'error:ConversionCast|Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.|list=a,b,c,d,');
        Observer.Verify();
    end;

    [Test]
    procedure List_DecimalIndex_Get_EdgeValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('2.4', Dec('get', 2.4));
        Observer.Observe('2.6', Dec('get', 2.6));
        Observer.Observe('1.5', Dec('get', 1.5));
        Observer.Observe('3.5', Dec('get', 3.5));
        Observer.Observe('0.4', Dec('get', 0.4));
        Observer.Observe('4.4', Dec('get', 4.4));
        Observer.Observe('4.5', Dec('get', 4.5));
        Observer.Observe('0', Dec('get', 0));
        Observer.Observe('5', Dec('get', 5));
        Observer.Observe('-1', Dec('get', -1));
        Observer.Observe('3000000000', Dec('get', 3000000000.0));
        Observer.Observe('2.0000000001', Dec('get', 2.0000000001));
        Observer.Expect('2.4', 'error:ConversionCast|Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.4 to System.Int32.|list=a,b,c,d,');
        Observer.Expect('2.6', 'error:ConversionCast|Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.6 to System.Int32.|list=a,b,c,d,');
        Observer.Expect('1.5', 'error:ConversionCast|Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.5 to System.Int32.|list=a,b,c,d,');
        Observer.Expect('3.5', 'error:ConversionCast|Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 3.5 to System.Int32.|list=a,b,c,d,');
        Observer.Expect('0.4', 'error:ConversionCast|Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.4 to System.Int32.|list=a,b,c,d,');
        Observer.Expect('4.4', 'error:ConversionCast|Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 4.4 to System.Int32.|list=a,b,c,d,');
        Observer.Expect('4.5', 'error:ConversionCast|Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 4.5 to System.Int32.|list=a,b,c,d,');
        Observer.Expect('0', 'error:ArgumentOutOfRange|An invalid argument was passed to a ''List'' data type method.|list=a,b,c,d,');
        Observer.Expect('5', 'error:ArgumentOutOfRange|An invalid argument was passed to a ''List'' data type method.|list=a,b,c,d,');
        Observer.Expect('-1', 'error:ArgumentOutOfRange|An invalid argument was passed to a ''List'' data type method.|list=a,b,c,d,');
        Observer.Expect('3000000000', 'error:ConversionCast|Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 3000000000.0 to System.Int32.|list=a,b,c,d,');
        Observer.Expect('2.0000000001', 'error:ConversionCast|Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.0000000001 to System.Int32.|list=a,b,c,d,');
        Observer.Verify();
    end;

    [Test]
    procedure List_BigIntegerIndex_EveryMethod()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('get', Big('get', 2));
        Observer.Observe('get var', Big('get var', 2));
        Observer.Observe('set', Big('set', 2));
        Observer.Observe('insert', Big('insert', 2));
        Observer.Observe('removeat', Big('removeat', 2));
        Observer.Observe('getrange index', Big('getrange index', 2));
        Observer.Observe('getrange count', Big('getrange count', 2));
        Observer.Observe('removerange index', Big('removerange index', 2));
        Observer.Observe('removerange count', Big('removerange count', 2));
        Observer.Expect('get', 'ok:b|list=a,b,c,d,');
        Observer.Expect('get var', 'ok:true:b|list=a,b,c,d,');
        Observer.Expect('set', 'ok:|list=a,X,c,d,');
        Observer.Expect('insert', 'ok:|list=a,X,b,c,d,');
        Observer.Expect('removeat', 'ok:Yes|list=a,c,d,');
        Observer.Expect('getrange index', 'ok:b,c,|list=a,b,c,d,');
        Observer.Expect('getrange count', 'ok:b,c,|list=a,b,c,d,');
        Observer.Expect('removerange index', 'ok:Yes|list=a,d,');
        Observer.Expect('removerange count', 'ok:Yes|list=c,d,');
        Observer.Verify();
    end;

    [Test]
    procedure List_BigIntegerIndex_Get_EdgeValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('0', Big('get', 0));
        Observer.Observe('5', Big('get', 5));
        Observer.Observe('-1', Big('get', -1));
        Observer.Observe('3000000000', Big('get', 3000000000L));
        Observer.Observe('get var 5', Big('get var', 5));
        Observer.Observe('get var 3000000000', Big('get var', 3000000000L));
        Observer.Expect('0', 'error:ArgumentOutOfRange|An invalid argument was passed to a ''List'' data type method.|list=a,b,c,d,');
        Observer.Expect('5', 'error:ArgumentOutOfRange|An invalid argument was passed to a ''List'' data type method.|list=a,b,c,d,');
        Observer.Expect('-1', 'error:ArgumentOutOfRange|An invalid argument was passed to a ''List'' data type method.|list=a,b,c,d,');
        Observer.Expect('3000000000', 'error:ConversionCast|Overflow under conversion of System.Int64 value 3000000000 to System.Int32.|list=a,b,c,d,');
        Observer.Expect('get var 5', 'ok:false|list=a,b,c,d,');
        Observer.Expect('get var 3000000000', 'error:ConversionCast|Overflow under conversion of System.Int64 value 3000000000 to System.Int32.|list=a,b,c,d,');
        Observer.Verify();
    end;

    [Test]
    procedure List_DecimalExpressionAsIndex()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('round up half count', Direct('round up half count'));
        Observer.Observe('count / 2', Direct('count / 2'));
        Observer.Observe('5 / 2', Direct('5 / 2'));
        Observer.Observe('literal 2.0', Direct('literal 2.0'));
        Observer.Observe('literal 2.5', Direct('literal 2.5'));
        Observer.Observe('indexof * 1.0', Direct('indexof * 1.0'));
        Observer.Observe('round nearest 2.5', Direct('round nearest 2.5'));
        Observer.Observe('set round up half count', Direct('set round up half count'));
        Observer.Observe('insert count / 2', Direct('insert count / 2'));
        Observer.Observe('removeat literal 2.0', Direct('removeat literal 2.0'));
        Observer.Expect('round up half count', 'ok:b|list=a,b,c,d,');
        Observer.Expect('count / 2', 'ok:b|list=a,b,c,d,');
        Observer.Expect('5 / 2', 'error:ConversionCast|Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.|list=a,b,c,d,');
        Observer.Expect('literal 2.0', 'ok:b|list=a,b,c,d,');
        Observer.Expect('literal 2.5', 'error:ConversionCast|Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.|list=a,b,c,d,');
        Observer.Expect('indexof * 1.0', 'ok:c|list=a,b,c,d,');
        Observer.Expect('round nearest 2.5', 'ok:c|list=a,b,c,d,');
        Observer.Expect('set round up half count', 'ok:|list=a,X,c,d,');
        Observer.Expect('insert count / 2', 'ok:|list=a,X,b,c,d,');
        Observer.Expect('removeat literal 2.0', 'ok:Yes|list=a,c,d,');
        Observer.Verify();
    end;

    [Test]
    procedure List_DecimalIndex_OutsideTryFunction()
    var
        Observer: Codeunit "Probe Observer";
        Lines: List of [Text];
        D: Decimal;
        I: Integer;
    begin
        // The three forms of the report, as plain statements in the test body.
        Four(Lines);
        D := 2;
        Observer.Observe('decimal variable', Lines.Get(D));
        Observer.Observe('round directly', Lines.Get(Round(Lines.Count() / 2, 1, '>')));
        I := Round(Lines.Count() / 2, 1, '>');
        Observer.Observe('round through integer', Lines.Get(I));
        Observer.Expect('decimal variable', 'b');
        Observer.Expect('round directly', 'b');
        Observer.Expect('round through integer', 'b');
        Observer.Verify();
    end;

    [Test]
    procedure List_CharOptionByteIndex()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('char', Other('char'));
        Observer.Observe('option', Other('option'));
        Observer.Observe('byte', Other('byte'));
        Observer.Expect('char', 'ok:b');
        Observer.Expect('option', 'ok:b');
        Observer.Expect('byte', 'ok:b');
        Observer.Verify();
    end;

    [Test]
    procedure Array_DecimalAndBigIntegerIndex()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('decimal 2', ArrayDec(2));
        Observer.Observe('decimal 2.5', ArrayDec(2.5));
        Observer.Observe('decimal 2.4', ArrayDec(2.4));
        Observer.Observe('decimal 5', ArrayDec(5));
        Observer.Observe('biginteger 2', ArrayBig(2));
        Observer.Observe('biginteger 5', ArrayBig(5));
        Observer.Observe('biginteger 3000000000', ArrayBig(3000000000L));
        Observer.Expect('decimal 2', 'ok:b');
        Observer.Expect('decimal 2.5', 'error:ConversionCast|Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.');
        Observer.Expect('decimal 2.4', 'error:ConversionCast|Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.4 to System.Int32.');
        Observer.Expect('decimal 5', 'error:IndexOutOfBounds|Index out of bounds.');
        Observer.Expect('biginteger 2', 'ok:b');
        Observer.Expect('biginteger 5', 'error:IndexOutOfBounds|Index out of bounds.');
        Observer.Expect('biginteger 3000000000', 'error:ConversionCast|Overflow under conversion of System.Int64 value 3000000000 to System.Int32.');
        Observer.Verify();
    end;
}
