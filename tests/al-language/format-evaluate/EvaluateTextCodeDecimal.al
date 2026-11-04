// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); codeunit 74889
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: Evaluate into a Text and a Code[n] with and without a format number (0, 1, 2, 9): the stored value and its length for leading and trailing blanks,
//   text longer than the variable, lower case; Evaluate into a Decimal for mixed letter and digit text ('attributeValue1', 'uri1', 'EU1', '12D', '1E3', '1,5', ...):
//   which are rejected, the error text and code (read from the same Evaluate with the result left unused, because a used result sets no error), and the value left in the variable; the same with format number 9.
// BC versions: all (CI)

codeunit 74889 "LT EVT Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure EvText(var Observer: Codeunit "Probe Observer"; Tag: Text; Input: Text; Format2: Integer)
    var
        T: Text;
        Ok: Boolean;
    begin
        T := 'before';
        Ok := Evaluate(T, Input, Format2);
        Observer.Observe(Tag + 'Ok', Format(Ok));
        if Ok then
            Observer.Observe(Tag + 'Value', '[' + T + '] len=' + Format(StrLen(T)))
        else begin
            Observer.ObserveError(Tag + 'Err');
            Observer.Observe(Tag + 'Kept', '[' + T + ']');
        end;
    end;

    local procedure EvCode(var Observer: Codeunit "Probe Observer"; Tag: Text; Input: Text; Format2: Integer)
    var
        C: Code[5];
        Ok: Boolean;
    begin
        C := 'BEF';
        Ok := Evaluate(C, Input, Format2);
        Observer.Observe(Tag + 'Ok', Format(Ok));
        if Ok then
            Observer.Observe(Tag + 'Value', '[' + C + '] len=' + Format(StrLen(C)))
        else begin
            Observer.ObserveError(Tag + 'Err');
            Observer.Observe(Tag + 'Kept', '[' + C + ']');
        end;
    end;

    [TryFunction]
    local procedure TryEvalDec(Input: Text; Format2: Integer)
    var
        D: Decimal;
    begin
        if Format2 < 0 then
            Evaluate(D, Input)
        else
            Evaluate(D, Input, Format2);
    end;

    local procedure EvDec(var Observer: Codeunit "Probe Observer"; Tag: Text; Input: Text; Format2: Integer)
    var
        D: Decimal;
        Ok: Boolean;
    begin
        D := 7;
        if Format2 < 0 then
            Ok := Evaluate(D, Input)
        else
            Ok := Evaluate(D, Input, Format2);
        Observer.Observe(Tag + 'Ok', Format(Ok));
        if Ok then
            Observer.Observe(Tag + 'Value', Format(D, 0, 9))
        else begin
            if not TryEvalDec(Input, Format2) then
                Observer.ObserveError(Tag + 'Err');
            Observer.Observe(Tag + 'Kept', Format(D, 0, 9));
        end;
    end;

    [Test]
    procedure Text_FormatNumbers()
    var
        Observer: Codeunit "Probe Observer";
        n: Integer;
    begin
        for n := 0 to 2 do begin
            EvText(Observer, 'plain' + Format(n), 'abc', n);
            EvText(Observer, 'lead' + Format(n), '  abc', n);
            EvText(Observer, 'trail' + Format(n), 'abc  ', n);
            EvText(Observer, 'empty' + Format(n), '', n);
            EvText(Observer, 'blank' + Format(n), '   ', n);
        end;
        EvText(Observer, 'plain9', 'abc', 9);
        EvText(Observer, 'lead9', '  abc', 9);
        EvText(Observer, 'trail9', 'abc  ', 9);
        EvText(Observer, 'amp9', 'a&amp;b', 9);
        Observer.Expect('plain0Ok', 'Yes');
        Observer.Expect('plain0Value', '[abc] len=3');
        Observer.Expect('lead0Ok', 'Yes');
        Observer.Expect('lead0Value', '[  abc] len=5');
        Observer.Expect('trail0Ok', 'Yes');
        Observer.Expect('trail0Value', '[abc  ] len=5');
        Observer.Expect('empty0Ok', 'Yes');
        Observer.Expect('empty0Value', '[] len=0');
        Observer.Expect('blank0Ok', 'Yes');
        Observer.Expect('blank0Value', '[   ] len=3');
        Observer.Expect('plain1Ok', 'Yes');
        Observer.Expect('plain1Value', '[abc] len=3');
        Observer.Expect('lead1Ok', 'Yes');
        Observer.Expect('lead1Value', '[  abc] len=5');
        Observer.Expect('trail1Ok', 'Yes');
        Observer.Expect('trail1Value', '[abc  ] len=5');
        Observer.Expect('empty1Ok', 'Yes');
        Observer.Expect('empty1Value', '[] len=0');
        Observer.Expect('blank1Ok', 'Yes');
        Observer.Expect('blank1Value', '[   ] len=3');
        Observer.Expect('plain2Ok', 'Yes');
        Observer.Expect('plain2Value', '[abc] len=3');
        Observer.Expect('lead2Ok', 'Yes');
        Observer.Expect('lead2Value', '[  abc] len=5');
        Observer.Expect('trail2Ok', 'Yes');
        Observer.Expect('trail2Value', '[abc  ] len=5');
        Observer.Expect('empty2Ok', 'Yes');
        Observer.Expect('empty2Value', '[] len=0');
        Observer.Expect('blank2Ok', 'Yes');
        Observer.Expect('blank2Value', '[   ] len=3');
        Observer.Expect('plain9Ok', 'Yes');
        Observer.Expect('plain9Value', '[abc] len=3');
        Observer.Expect('lead9Ok', 'Yes');
        Observer.Expect('lead9Value', '[  abc] len=5');
        Observer.Expect('trail9Ok', 'Yes');
        Observer.Expect('trail9Value', '[abc  ] len=5');
        Observer.Expect('amp9Ok', 'Yes');
        Observer.Expect('amp9Value', '[a&amp;b] len=7');
        Observer.Verify();
    end;

    [Test]
    procedure Code_FormatNumbers()
    var
        Observer: Codeunit "Probe Observer";
        n: Integer;
    begin
        for n := 0 to 2 do begin
            EvCode(Observer, 'lower' + Format(n), 'abc', n);
            EvCode(Observer, 'exact' + Format(n), 'abcde', n);
            EvCode(Observer, 'trailFits' + Format(n), 'abcde   ', n);
            EvCode(Observer, 'tooLong' + Format(n), 'abcdef', n);
            EvCode(Observer, 'leadBlank' + Format(n), '  abc', n);
            EvCode(Observer, 'leadFull' + Format(n), ' abcde', n);
            EvCode(Observer, 'blank' + Format(n), '   ', n);
        end;
        EvCode(Observer, 'lower9', 'abc', 9);
        EvCode(Observer, 'trailFits9', 'abcde   ', 9);
        EvCode(Observer, 'tooLong9', 'abcdef', 9);
        Observer.Expect('lower0Ok', 'Yes');
        Observer.Expect('lower0Value', '[ABC] len=3');
        Observer.Expect('exact0Ok', 'Yes');
        Observer.Expect('exact0Value', '[ABCDE] len=5');
        Observer.Expect('trailFits0Ok', 'Yes');
        Observer.Expect('trailFits0Value', '[ABCDE] len=5');
        Observer.Expect('tooLong0Ok', 'No');
        Observer.Expect('tooLong0Err|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: abcdef');
        Observer.Expect('tooLong0Err|code', 'StringLengthExceeded');
        Observer.Expect('tooLong0Kept', '[BEF]');
        Observer.Expect('leadBlank0Ok', 'Yes');
        Observer.Expect('leadBlank0Value', '[ABC] len=3');
        Observer.Expect('leadFull0Ok', 'Yes');
        Observer.Expect('leadFull0Value', '[ABCDE] len=5');
        Observer.Expect('blank0Ok', 'Yes');
        Observer.Expect('blank0Value', '[] len=0');
        Observer.Expect('lower1Ok', 'Yes');
        Observer.Expect('lower1Value', '[ABC] len=3');
        Observer.Expect('exact1Ok', 'Yes');
        Observer.Expect('exact1Value', '[ABCDE] len=5');
        Observer.Expect('trailFits1Ok', 'Yes');
        Observer.Expect('trailFits1Value', '[ABCDE] len=5');
        Observer.Expect('tooLong1Ok', 'No');
        Observer.Expect('tooLong1Err|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: abcdef');
        Observer.Expect('tooLong1Err|code', 'StringLengthExceeded');
        Observer.Expect('tooLong1Kept', '[BEF]');
        Observer.Expect('leadBlank1Ok', 'Yes');
        Observer.Expect('leadBlank1Value', '[ABC] len=3');
        Observer.Expect('leadFull1Ok', 'Yes');
        Observer.Expect('leadFull1Value', '[ABCDE] len=5');
        Observer.Expect('blank1Ok', 'Yes');
        Observer.Expect('blank1Value', '[] len=0');
        Observer.Expect('lower2Ok', 'Yes');
        Observer.Expect('lower2Value', '[ABC] len=3');
        Observer.Expect('exact2Ok', 'Yes');
        Observer.Expect('exact2Value', '[ABCDE] len=5');
        Observer.Expect('trailFits2Ok', 'Yes');
        Observer.Expect('trailFits2Value', '[ABCDE] len=5');
        Observer.Expect('tooLong2Ok', 'No');
        Observer.Expect('tooLong2Err|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: abcdef');
        Observer.Expect('tooLong2Err|code', 'StringLengthExceeded');
        Observer.Expect('tooLong2Kept', '[BEF]');
        Observer.Expect('leadBlank2Ok', 'Yes');
        Observer.Expect('leadBlank2Value', '[ABC] len=3');
        Observer.Expect('leadFull2Ok', 'Yes');
        Observer.Expect('leadFull2Value', '[ABCDE] len=5');
        Observer.Expect('blank2Ok', 'Yes');
        Observer.Expect('blank2Value', '[] len=0');
        Observer.Expect('lower9Ok', 'Yes');
        Observer.Expect('lower9Value', '[ABC] len=3');
        Observer.Expect('trailFits9Ok', 'Yes');
        Observer.Expect('trailFits9Value', '[ABCDE] len=5');
        Observer.Expect('tooLong9Ok', 'No');
        Observer.Expect('tooLong9Err|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: abcdef');
        Observer.Expect('tooLong9Err|code', 'StringLengthExceeded');
        Observer.Expect('tooLong9Kept', '[BEF]');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_MixedLetterDigit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvDec(Observer, 'attributeValue1', 'attributeValue1', -1);
        EvDec(Observer, 'uri1', 'uri1', -1);
        EvDec(Observer, 'EU1', 'EU1', -1);
        EvDec(Observer, 'd12', '12D', -1);
        EvDec(Observer, 'lowerd12', '12d', -1);
        EvDec(Observer, 'e1e3', '1E3', -1);
        EvDec(Observer, 'lowere1e3', '1e3', -1);
        EvDec(Observer, 'comma15', '1,5', -1);
        EvDec(Observer, 'e5', 'E5', -1);
        EvDec(Observer, 'x1', 'x1', -1);
        EvDec(Observer, 'onex', '1x', -1);
        Observer.Expect('attributeValue1Ok', 'No');
        Observer.Expect('attributeValue1Err|text', 'The value "attributeValue1" can''t be evaluated into type Decimal.');
        Observer.Expect('attributeValue1Err|code', 'Evaluate');
        Observer.Expect('attributeValue1Kept', '7');
        Observer.Expect('uri1Ok', 'No');
        Observer.Expect('uri1Err|text', 'The value "uri1" can''t be evaluated into type Decimal.');
        Observer.Expect('uri1Err|code', 'Evaluate');
        Observer.Expect('uri1Kept', '7');
        Observer.Expect('EU1Ok', 'No');
        Observer.Expect('EU1Err|text', 'The value "EU1" can''t be evaluated into type Decimal.');
        Observer.Expect('EU1Err|code', 'Evaluate');
        Observer.Expect('EU1Kept', '7');
        Observer.Expect('d12Ok', 'No');
        Observer.Expect('d12Err|text', 'The value "12D" can''t be evaluated into type Decimal.');
        Observer.Expect('d12Err|code', 'Evaluate');
        Observer.Expect('d12Kept', '7');
        Observer.Expect('lowerd12Ok', 'No');
        Observer.Expect('lowerd12Err|text', 'The value "12d" can''t be evaluated into type Decimal.');
        Observer.Expect('lowerd12Err|code', 'Evaluate');
        Observer.Expect('lowerd12Kept', '7');
        Observer.Expect('e1e3Ok', 'Yes');
        Observer.Expect('e1e3Value', '1000');
        Observer.Expect('lowere1e3Ok', 'Yes');
        Observer.Expect('lowere1e3Value', '1000');
        Observer.Expect('comma15Ok', 'Yes');
        Observer.Expect('comma15Value', '15');
        Observer.Expect('e5Ok', 'No');
        Observer.Expect('e5Err|text', 'The value "E5" can''t be evaluated into type Decimal.');
        Observer.Expect('e5Err|code', 'Evaluate');
        Observer.Expect('e5Kept', '7');
        Observer.Expect('x1Ok', 'No');
        Observer.Expect('x1Err|text', 'The value "x1" can''t be evaluated into type Decimal.');
        Observer.Expect('x1Err|code', 'Evaluate');
        Observer.Expect('x1Kept', '7');
        Observer.Expect('onexOk', 'No');
        Observer.Expect('onexErr|text', 'The value "1x" can''t be evaluated into type Decimal.');
        Observer.Expect('onexErr|code', 'Evaluate');
        Observer.Expect('onexKept', '7');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_OtherInputs()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvDec(Observer, 'e', '1E', -1);
        EvDec(Observer, 'eMinus', '1E-2', -1);
        EvDec(Observer, 'ePlus', '1E+2', -1);
        EvDec(Observer, 'frac', '1.5E2', -1);
        EvDec(Observer, 'dFrac', '1.5D', -1);
        EvDec(Observer, 'dd', '1D2', -1);
        EvDec(Observer, 'onlyD', 'D', -1);
        EvDec(Observer, 'plus', '+5', -1);
        EvDec(Observer, 'dash', '-', -1);
        EvDec(Observer, 'dot', '.5', -1);
        EvDec(Observer, 'trailDot', '5.', -1);
        EvDec(Observer, 'hex', '0x10', -1);
        EvDec(Observer, 'inner', '1 2', -1);
        EvDec(Observer, 'padded', ' 12 ', -1);
        EvDec(Observer, 'thousands', '1,000.5', -1);
        EvDec(Observer, 'percent', '5%', -1);
        EvDec(Observer, 'empty', '', -1);
        Observer.Expect('eOk', 'No');
        Observer.Expect('eErr|text', 'The value "1E" can''t be evaluated into type Decimal.');
        Observer.Expect('eErr|code', 'Evaluate');
        Observer.Expect('eKept', '7');
        Observer.Expect('eMinusOk', 'Yes');
        Observer.Expect('eMinusValue', '0.01');
        Observer.Expect('ePlusOk', 'Yes');
        Observer.Expect('ePlusValue', '100');
        Observer.Expect('fracOk', 'Yes');
        Observer.Expect('fracValue', '150');
        Observer.Expect('dFracOk', 'No');
        Observer.Expect('dFracErr|text', 'The value "1.5D" can''t be evaluated into type Decimal.');
        Observer.Expect('dFracErr|code', 'Evaluate');
        Observer.Expect('dFracKept', '7');
        Observer.Expect('ddOk', 'No');
        Observer.Expect('ddErr|text', 'The value "1D2" can''t be evaluated into type Decimal.');
        Observer.Expect('ddErr|code', 'Evaluate');
        Observer.Expect('ddKept', '7');
        Observer.Expect('onlyDOk', 'No');
        Observer.Expect('onlyDErr|text', 'The value "D" can''t be evaluated into type Decimal.');
        Observer.Expect('onlyDErr|code', 'Evaluate');
        Observer.Expect('onlyDKept', '7');
        Observer.Expect('plusOk', 'Yes');
        Observer.Expect('plusValue', '5');
        Observer.Expect('dashOk', 'No');
        Observer.Expect('dashErr|text', 'The value "-" can''t be evaluated into type Decimal.');
        Observer.Expect('dashErr|code', 'Evaluate');
        Observer.Expect('dashKept', '7');
        Observer.Expect('dotOk', 'Yes');
        Observer.Expect('dotValue', '0.5');
        Observer.Expect('trailDotOk', 'Yes');
        Observer.Expect('trailDotValue', '5');
        Observer.Expect('hexOk', 'No');
        Observer.Expect('hexErr|text', 'The value "0x10" can''t be evaluated into type Decimal.');
        Observer.Expect('hexErr|code', 'Evaluate');
        Observer.Expect('hexKept', '7');
        Observer.Expect('innerOk', 'No');
        Observer.Expect('innerErr|text', 'The value "1 2" can''t be evaluated into type Decimal.');
        Observer.Expect('innerErr|code', 'Evaluate');
        Observer.Expect('innerKept', '7');
        Observer.Expect('paddedOk', 'Yes');
        Observer.Expect('paddedValue', '12');
        Observer.Expect('thousandsOk', 'Yes');
        Observer.Expect('thousandsValue', '1000.5');
        Observer.Expect('percentOk', 'No');
        Observer.Expect('percentErr|text', 'The value "5%" can''t be evaluated into type Decimal.');
        Observer.Expect('percentErr|code', 'Evaluate');
        Observer.Expect('percentKept', '7');
        Observer.Expect('emptyOk', 'No');
        Observer.Expect('emptyErr|text', 'The value "" can''t be evaluated into type Decimal.');
        Observer.Expect('emptyErr|code', 'Evaluate');
        Observer.Expect('emptyKept', '7');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_MixedLetterDigit_Format9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvDec(Observer, 'attributeValue1', 'attributeValue1', 9);
        EvDec(Observer, 'uri1', 'uri1', 9);
        EvDec(Observer, 'EU1', 'EU1', 9);
        EvDec(Observer, 'd12', '12D', 9);
        EvDec(Observer, 'e1e3', '1E3', 9);
        EvDec(Observer, 'lowere1e3', '1e3', 9);
        EvDec(Observer, 'comma15', '1,5', 9);
        EvDec(Observer, 'dot15', '1.5', 9);
        Observer.Expect('attributeValue1Ok', 'No');
        Observer.Expect('attributeValue1Err|text', 'The value "attributeValue1" can''t be evaluated into type Decimal.');
        Observer.Expect('attributeValue1Err|code', 'Evaluate');
        Observer.Expect('attributeValue1Kept', '7');
        Observer.Expect('uri1Ok', 'No');
        Observer.Expect('uri1Err|text', 'The value "uri1" can''t be evaluated into type Decimal.');
        Observer.Expect('uri1Err|code', 'Evaluate');
        Observer.Expect('uri1Kept', '7');
        Observer.Expect('EU1Ok', 'No');
        Observer.Expect('EU1Err|text', 'The value "EU1" can''t be evaluated into type Decimal.');
        Observer.Expect('EU1Err|code', 'Evaluate');
        Observer.Expect('EU1Kept', '7');
        Observer.Expect('d12Ok', 'No');
        Observer.Expect('d12Err|text', 'The value "12D" can''t be evaluated into type Decimal.');
        Observer.Expect('d12Err|code', 'Evaluate');
        Observer.Expect('d12Kept', '7');
        Observer.Expect('e1e3Ok', 'Yes');
        Observer.Expect('e1e3Value', '1000');
        Observer.Expect('lowere1e3Ok', 'Yes');
        Observer.Expect('lowere1e3Value', '1000');
        Observer.Expect('comma15Ok', 'No');
        Observer.Expect('comma15Err|text', 'The value "1,5" can''t be evaluated into type Decimal.');
        Observer.Expect('comma15Err|code', 'Evaluate');
        Observer.Expect('comma15Kept', '7');
        Observer.Expect('dot15Ok', 'Yes');
        Observer.Expect('dot15Value', '1.5');
        Observer.Verify();
    end;
}
