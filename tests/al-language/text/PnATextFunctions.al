// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: Text: IndexOf/LastIndexOf of an empty text with a start index, Substring, DelStr/InsStr, IncStr, ConvertStr outside the text
// Facts: Text.IndexOf, LastIndexOf, Substring and DelStr, InsStr, IncStr, ConvertStr with edge arguments
// BC versions: 29 (27 and 28 by CI)

codeunit 70098 "LT PnA Text Functions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        T: Text;
        Res: Text;

    [TryFunction]
    local procedure TryOp(Op: Integer)
    begin
        T := 'abc';
        Res := '';
        case Op of
            1:
                Res := Format(T.IndexOf('', 2));
            2:
                Res := Format(T.IndexOf('', 0));
            3:
                Res := Format(T.IndexOf('', 10));
            4:
                Res := Format(T.IndexOf('b', 10));
            5:
                Res := Format(T.IndexOf('b', 0));
            6:
                Res := Format(T.IndexOf('b', -1));
            7:
                Res := Format(T.IndexOf('b', 2));
            8:
                Res := Format(T.IndexOf('b', 3));
            9:
                Res := Format(T.LastIndexOf('', 2));
            10:
                Res := Format(T.LastIndexOf('b', 10));
            11:
                Res := Format(T.LastIndexOf('b', 0));
            12:
                Res := Format(T.LastIndexOf('b', 1));
            13:
                Res := Format(T.LastIndexOf('b', 2));
            14:
                Res := Format(T.LastIndexOf('b', 3));
            15:
                Res := T.Substring(0);
            16:
                Res := T.Substring(1, -1);
            17:
                Res := T.Substring(4);
            18:
                Res := T.Substring(5);
            19:
                Res := T.Substring(2, 10);
            20:
                Res := T.Substring(1, 0);
            21:
                Res := T.Substring(-1);
            22:
                Res := DelStr('abc', 0);
            23:
                Res := DelStr('abc', -1);
            24:
                Res := DelStr('abc', 2, 10);
            25:
                Res := DelStr('abc', 4);
            26:
                Res := DelStr('abc', 4, 1);
            27:
                Res := DelStr('abc', 1, 0);
            28:
                Res := DelStr('abc', 1, -1);
            29:
                Res := InsStr('abc', 'x', 0);
            30:
                Res := InsStr('abc', 'x', 5);
            31:
                Res := InsStr('abc', 'x', 4);
            32:
                Res := InsStr('abc', 'x', -1);
            33:
                Res := IncStr('A9');
            34:
                Res := IncStr('');
            35:
                Res := IncStr('9');
            36:
                Res := IncStr('abc');
            37:
                Res := IncStr('A-9');
            38:
                Res := ConvertStr('abc', 'ab', 'xy');
            39:
                Res := ConvertStr('abc', 'abc', 'x');
            40:
                Res := ConvertStr('abc', '', '');
            41:
                Res := ConvertStr('abc', 'ab', 'xyz');
            42:
                Res := ConvertStr('abc', 'aa', 'xy');
        end;
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Op: Integer)
    begin
        Observer.Observe('op' + Format(Op), Format(TryOp(Op)) + '|' + Res);
        Observer.ObserveError('op' + Format(Op));
    end;

    [Test]
    procedure IndexOf_Cases()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 1 to 8 do
            Probe(Observer, i);
        Observer.Expect('op1', 'Yes|2');
        Observer.Expect('op1|text', '');
        Observer.Expect('op1|code', '');
        Observer.Expect('op2', 'No|');
        Observer.Expect('op2|text', 'Index was out of range. Must be non-negative and less than or equal to the size of the collection. (Parameter ''startIndex'')');
        Observer.Expect('op2|code', 'ArgumentOutOfRange');
        Observer.Expect('op3', 'No|');
        Observer.Expect('op3|text', 'Index was out of range. Must be non-negative and less than or equal to the size of the collection. (Parameter ''startIndex'')');
        Observer.Expect('op3|code', 'ArgumentOutOfRange');
        Observer.Expect('op4', 'No|');
        Observer.Expect('op4|text', 'Index was out of range. Must be non-negative and less than or equal to the size of the collection. (Parameter ''startIndex'')');
        Observer.Expect('op4|code', 'ArgumentOutOfRange');
        Observer.Expect('op5', 'No|');
        Observer.Expect('op5|text', 'Index was out of range. Must be non-negative and less than or equal to the size of the collection. (Parameter ''startIndex'')');
        Observer.Expect('op5|code', 'ArgumentOutOfRange');
        Observer.Expect('op6', 'No|');
        Observer.Expect('op6|text', 'Index was out of range. Must be non-negative and less than or equal to the size of the collection. (Parameter ''startIndex'')');
        Observer.Expect('op6|code', 'ArgumentOutOfRange');
        Observer.Expect('op7', 'Yes|2');
        Observer.Expect('op7|text', '');
        Observer.Expect('op7|code', '');
        Observer.Expect('op8', 'Yes|0');
        Observer.Expect('op8|text', '');
        Observer.Expect('op8|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure LastIndexOf_Cases()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 9 to 14 do
            Probe(Observer, i);
        Observer.Expect('op9', 'Yes|3');
        Observer.Expect('op9|text', '');
        Observer.Expect('op9|code', '');
        Observer.Expect('op10', 'No|');
        Observer.Expect('op10|text', 'Index was out of range. Must be non-negative and less than the size of the collection. (Parameter ''startIndex'')');
        Observer.Expect('op10|code', 'ArgumentOutOfRange');
        Observer.Expect('op11', 'No|');
        Observer.Expect('op11|text', 'Index was out of range. Must be non-negative and less than the size of the collection. (Parameter ''startIndex'')');
        Observer.Expect('op11|code', 'ArgumentOutOfRange');
        Observer.Expect('op12', 'Yes|0');
        Observer.Expect('op12|text', '');
        Observer.Expect('op12|code', '');
        Observer.Expect('op13', 'Yes|2');
        Observer.Expect('op13|text', '');
        Observer.Expect('op13|code', '');
        Observer.Expect('op14', 'Yes|2');
        Observer.Expect('op14|text', '');
        Observer.Expect('op14|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure Substring_Cases()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 15 to 21 do
            Probe(Observer, i);
        Observer.Expect('op15', 'No|');
        Observer.Expect('op15|text', 'startIndex (''-1'') must be a non-negative value. (Parameter ''startIndex'')\Actual value was -1.');
        Observer.Expect('op15|code', 'ArgumentOutOfRange');
        Observer.Expect('op16', 'No|');
        Observer.Expect('op16|text', 'length (''-1'') must be a non-negative value. (Parameter ''length'')\Actual value was -1.');
        Observer.Expect('op16|code', 'ArgumentOutOfRange');
        Observer.Expect('op17', 'Yes|');
        Observer.Expect('op17|text', '');
        Observer.Expect('op17|code', '');
        Observer.Expect('op18', 'No|');
        Observer.Expect('op18|text', 'startIndex cannot be larger than length of string. (Parameter ''startIndex'')');
        Observer.Expect('op18|code', 'ArgumentOutOfRange');
        Observer.Expect('op19', 'Yes|bc');
        Observer.Expect('op19|text', '');
        Observer.Expect('op19|code', '');
        Observer.Expect('op20', 'Yes|');
        Observer.Expect('op20|text', '');
        Observer.Expect('op20|code', '');
        Observer.Expect('op21', 'No|');
        Observer.Expect('op21|text', 'startIndex (''-2'') must be a non-negative value. (Parameter ''startIndex'')\Actual value was -2.');
        Observer.Expect('op21|code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;

    [Test]
    procedure DelStr_Cases()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 22 to 28 do
            Probe(Observer, i);
        Observer.Expect('op22', 'No|');
        Observer.Expect('op22|text', 'The value of DELSTR parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2048.');
        Observer.Expect('op22|code', 'OutsidePermittedRange');
        Observer.Expect('op23', 'No|');
        Observer.Expect('op23|text', 'The value of DELSTR parameter 2 is outside of the permitted range. The current value is: -1. The permitted range is: from 1 to 2048.');
        Observer.Expect('op23|code', 'OutsidePermittedRange');
        Observer.Expect('op24', 'Yes|a');
        Observer.Expect('op24|text', '');
        Observer.Expect('op24|code', '');
        Observer.Expect('op25', 'Yes|abc');
        Observer.Expect('op25|text', '');
        Observer.Expect('op25|code', '');
        Observer.Expect('op26', 'Yes|abc');
        Observer.Expect('op26|text', '');
        Observer.Expect('op26|code', '');
        Observer.Expect('op27', 'Yes|abc');
        Observer.Expect('op27|text', '');
        Observer.Expect('op27|code', '');
        Observer.Expect('op28', 'No|');
        Observer.Expect('op28|text', 'The value of DELSTR parameter 3 is outside of the permitted range. The current value is: -1. The permitted range is: from 0 to 2,147,483,647.');
        Observer.Expect('op28|code', 'OutsidePermittedRange');
        Observer.Verify();
    end;

    [Test]
    procedure InsStr_Cases()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 29 to 32 do
            Probe(Observer, i);
        Observer.Expect('op29', 'No|');
        Observer.Expect('op29|text', 'The value of INSSTR parameter 3 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647.');
        Observer.Expect('op29|code', 'OutsidePermittedRange');
        Observer.Expect('op30', 'Yes|abcx');
        Observer.Expect('op30|text', '');
        Observer.Expect('op30|code', '');
        Observer.Expect('op31', 'Yes|abcx');
        Observer.Expect('op31|text', '');
        Observer.Expect('op31|code', '');
        Observer.Expect('op32', 'No|');
        Observer.Expect('op32|text', 'The value of INSSTR parameter 3 is outside of the permitted range. The current value is: -1. The permitted range is: from 1 to 2,147,483,647.');
        Observer.Expect('op32|code', 'OutsidePermittedRange');
        Observer.Verify();
    end;

    [Test]
    procedure IncStr_Cases()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 33 to 37 do
            Probe(Observer, i);
        Observer.Expect('op33', 'Yes|A10');
        Observer.Expect('op33|text', '');
        Observer.Expect('op33|code', '');
        Observer.Expect('op34', 'Yes|');
        Observer.Expect('op34|text', '');
        Observer.Expect('op34|code', '');
        Observer.Expect('op35', 'Yes|10');
        Observer.Expect('op35|text', '');
        Observer.Expect('op35|code', '');
        Observer.Expect('op36', 'Yes|');
        Observer.Expect('op36|text', '');
        Observer.Expect('op36|code', '');
        Observer.Expect('op37', 'Yes|A-10');
        Observer.Expect('op37|text', '');
        Observer.Expect('op37|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure ConvertStr_Cases()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 38 to 42 do
            Probe(Observer, i);
        Observer.Expect('op38', 'Yes|xyc');
        Observer.Expect('op38|text', '');
        Observer.Expect('op38|code', '');
        Observer.Expect('op39', 'No|');
        Observer.Expect('op39|text', 'ALConvertStr expects 2 strings in the conversion to be of equal length: Converting from abc to x.');
        Observer.Expect('op39|code', 'InvalidStringFormat');
        Observer.Expect('op40', 'Yes|abc');
        Observer.Expect('op40|text', '');
        Observer.Expect('op40|code', '');
        Observer.Expect('op41', 'No|');
        Observer.Expect('op41|text', 'ALConvertStr expects 2 strings in the conversion to be of equal length: Converting from ab to xyz.');
        Observer.Expect('op41|code', 'InvalidStringFormat');
        Observer.Expect('op42', 'Yes|xbc');
        Observer.Expect('op42|text', '');
        Observer.Expect('op42|code', '');
        Observer.Verify();
    end;
}
