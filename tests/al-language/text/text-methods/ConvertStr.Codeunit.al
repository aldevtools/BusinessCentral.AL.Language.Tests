// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// ConvertStr forms and errors.
// BC versions: 29 (27 and 28 by CI)

codeunit 70507 "LT TxB ConvertStr"
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
    procedure ConvertStrBasic()
    begin
        Obs.Observe('a1', Format(ConvertStr('abc','a','x')));
        Obs.Observe('a2', Format(ConvertStr('abc','abc','xyz')));
        Obs.Observe('a3', Format(ConvertStr('abc','ac','ca')));
        Obs.Observe('a4', Format(ConvertStr('aaa','a','b')));
        Obs.Observe('a5', Format(ConvertStr('abc','','')));
        Obs.Observe('a6', Format(ConvertStr('','a','b')));
        Obs.Observe('a7', Format(ConvertStr('Hello','lo','01')));
        Obs.Observe('a8', Format(ConvertStr('Hello','el','ip')));
        Obs.Observe('a9', Format(ConvertStr('abc','A','x')));
        Obs.Observe('a10', Format(ConvertStr('ABC','a','x')));
        Obs.Observe('a11', Format(ConvertStr('abc','aa','xy')));
        Obs.Observe('a12', Format(ConvertStr('abc','aa','yx')));
        Obs.Observe('a13', Format(ConvertStr('a b c',' ','_')));
        Obs.Observe('a14', Format(ConvertStr('日本語','本','X')));
        Obs.Observe('a15', Format(ConvertStr('äöü','ö','o')));
        asserterror Obs.Observe('a16', Format(ConvertStr('abc','abc','x')));
        Obs.ObserveError('af43');
        asserterror Obs.Observe('a17', Format(ConvertStr('abc','abc','xy')));
        Obs.ObserveError('af45');
        asserterror Obs.Observe('a18', Format(ConvertStr('abc','abc','wxyz')));
        Obs.ObserveError('af47');
        asserterror Obs.Observe('a19', Format(ConvertStr('abc','a','xyz')));
        Obs.ObserveError('af49');
        asserterror Obs.Observe('a20', Format(ConvertStr('abc','ab','x')));
        Obs.ObserveError('af51');
        Obs.Expect('a1', 'xbc');
        Obs.Expect('a2', 'xyz');
        Obs.Expect('a3', 'cba');
        Obs.Expect('a4', 'bbb');
        Obs.Expect('a5', 'abc');
        Obs.Expect('a6', '');
        Obs.Expect('a7', 'He001');
        Obs.Expect('a8', 'Hippo');
        Obs.Expect('a9', 'abc');
        Obs.Expect('a10', 'ABC');
        Obs.Expect('a11', 'xbc');
        Obs.Expect('a12', 'ybc');
        Obs.Expect('a13', 'a_b_c');
        Obs.Expect('a14', '日X語');
        Obs.Expect('a15', 'äoü');
        Obs.Expect('af43|text', 'ALConvertStr expects 2 strings in the conversion to be of equal length: Converting from abc to x.');
        Obs.Expect('af43|code', 'InvalidStringFormat');
        Obs.Expect('af45|text', 'ALConvertStr expects 2 strings in the conversion to be of equal length: Converting from abc to xy.');
        Obs.Expect('af45|code', 'InvalidStringFormat');
        Obs.Expect('af47|text', 'ALConvertStr expects 2 strings in the conversion to be of equal length: Converting from abc to wxyz.');
        Obs.Expect('af47|code', 'InvalidStringFormat');
        Obs.Expect('af49|text', 'ALConvertStr expects 2 strings in the conversion to be of equal length: Converting from a to xyz.');
        Obs.Expect('af49|code', 'InvalidStringFormat');
        Obs.Expect('af51|text', 'ALConvertStr expects 2 strings in the conversion to be of equal length: Converting from ab to x.');
        Obs.Expect('af51|code', 'InvalidStringFormat');
        Obs.Verify();
    end;

    [Test]
    procedure ConvertStrErrors()
    begin
        asserterror T := ConvertStr('abc','ab','x');
        Obs.ObserveError('tooshort');
        asserterror T := ConvertStr('abc','a','');
        Obs.ObserveError('emptyto');
        asserterror T := ConvertStr('abc','','x');
        Obs.ObserveError('emptyfrom');
        asserterror T := ConvertStr('abc','abc','xy');
        Obs.ObserveError('shorterto2');
        asserterror Obs.Observe('longerto', Format(ConvertStr('abc','a','xyz')));
        Obs.ObserveError('af63');
        T := ConvertStr('abc','','');
        Obs.Observe('emptyboth', 'no error');
        Obs.Expect('tooshort|text', 'ALConvertStr expects 2 strings in the conversion to be of equal length: Converting from ab to x.');
        Obs.Expect('tooshort|code', 'InvalidStringFormat');
        Obs.Expect('emptyto|text', 'ALConvertStr expects 2 strings in the conversion to be of equal length: Converting from a to .');
        Obs.Expect('emptyto|code', 'InvalidStringFormat');
        Obs.Expect('emptyfrom|text', 'ALConvertStr expects 2 strings in the conversion to be of equal length: Converting from  to x.');
        Obs.Expect('emptyfrom|code', 'InvalidStringFormat');
        Obs.Expect('shorterto2|text', 'ALConvertStr expects 2 strings in the conversion to be of equal length: Converting from abc to xy.');
        Obs.Expect('shorterto2|code', 'InvalidStringFormat');
        Obs.Expect('af63|text', 'ALConvertStr expects 2 strings in the conversion to be of equal length: Converting from a to xyz.');
        Obs.Expect('af63|code', 'InvalidStringFormat');
        Obs.Expect('emptyboth', 'no error');
        Obs.Verify();
    end;

    [Test]
    procedure ConvertStrTargets()
    begin
        T := 'abcde';
        T5 := ConvertStr(T,'ae','xy');
        Obs.Observe('t5', Format(T5));
        C5 := ConvertStr(T,'ae','xy');
        Obs.Observe('c5', Format(C5));
        C5 := ConvertStr('ab cd',' ','_');
        Obs.Observe('c5sp', Format(C5));
        Obs.Observe('keepscase', Format(ConvertStr('aBc','b','x')));
        Obs.Observe('swap', Format(ConvertStr('ab','ab','ba')));
        asserterror T5 := ConvertStr('abcdef','a','x');
        Obs.ObserveError('t5over');
        Obs.Expect('t5', 'xbcdy');
        Obs.Expect('c5', 'XBCDY');
        Obs.Expect('c5sp', 'AB_CD');
        Obs.Expect('keepscase', 'aBc');
        Obs.Expect('swap', 'ba');
        Obs.Expect('t5over|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: xbcdef');
        Obs.Expect('t5over|code', 'StringLengthExceeded');
        Obs.Verify();
    end;

}
