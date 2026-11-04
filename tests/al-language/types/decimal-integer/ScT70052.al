// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 70052
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Format of Integer, BigInteger, Byte with format numbers and strings
// BC versions: 29 (27 and 28 by CI)

codeunit 70052 "LT ScT Fmt Integer"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryF(V: Variant; N: Integer; var R: Text)
    begin
        R := Format(V, 0, N);
    end;

    local procedure F(V: Variant; N: Integer): Text
    var
        R: Text;
    begin
        if TryF(V, N, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Integer_Numbers()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        n: Integer;
    begin
        I := 1234567;
        for n := 0 to 9 do
            Observer.Observe('n' + Format(n), F(I, n));
        Observer.Expect('n0', '1234567');
        Observer.Expect('n1', '1234567');
        Observer.Expect('n2', '1234567');
        Observer.Expect('n3', 'error:Standard format number 3 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n4', 'error:Standard format number 4 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n5', 'error:Standard format number 5 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n6', 'error:Standard format number 6 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n7', 'error:Standard format number 7 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n8', 'error:Standard format number 8 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n9', '1234567');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_NegativeNumbers()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        n: Integer;
    begin
        I := -1234567;
        for n := 0 to 9 do
            Observer.Observe('n' + Format(n), F(I, n));
        Observer.Expect('n0', '-1234567');
        Observer.Expect('n1', '-1234567');
        Observer.Expect('n2', '-1234567');
        Observer.Expect('n3', 'error:Standard format number 3 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n4', 'error:Standard format number 4 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n5', 'error:Standard format number 5 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n6', 'error:Standard format number 6 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n7', 'error:Standard format number 7 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n8', 'error:Standard format number 8 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n9', '-1234567');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_Strings()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        I := 1234567;
        Observer.Observe('int', Format(I, 0, '<Integer>'));
        Observer.Observe('thousand', Format(I, 0, '<Integer Thousand>'));
        Observer.Observe('pad', Format(I, 0, '<Integer,10><Filler Character,0>'));
        Observer.Observe('padspace', Format(I, 0, '<Integer,10><Filler Character, >'));
        asserterror Observer.Observe('dec', Format(I, 0, '<Integer><Decimals>'));
        Observer.ObserveError('af52');
        Observer.Observe('prec', Format(I, 0, '<Precision,2:2><Standard Format,0>'));
        Observer.Observe('std1', Format(I, 0, '<Standard Format,1>'));
        Observer.Observe('std2', Format(I, 0, '<Standard Format,2>'));
        Observer.Observe('sign', Format(-I, 0, '<Sign,1><Integer>'));
        Observer.Observe('signpost', Format(-I, 0, '<Integer><Sign,1>'));
        Observer.Expect('int', '1234567');
        Observer.Expect('thousand', '1,234,567');
        Observer.Expect('pad', '0001234567');
        Observer.Expect('padspace', '   1234567');
        Observer.Expect('af52|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\<Integer><Decimals>');
        Observer.Expect('af52|code', 'InvalidFormatString');
        Observer.Expect('prec', '1234567');
        Observer.Expect('std1', '1234567');
        Observer.Expect('std2', '1234567');
        Observer.Expect('sign', '-1234567');
        Observer.Expect('signpost', '1234567-');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_Extremes()
    var
        Observer: Codeunit "Probe Observer";
        Mx: Integer;
        Mn: Integer;
    begin
        Mx := 2147483647;
        Mn := -2147483647 - 1;
        Observer.Observe('max', Format(Mx));
        Observer.Observe('min', Format(Mn));
        Observer.Observe('max9', Format(Mx, 0, 9));
        Observer.Observe('min9', Format(Mn, 0, 9));
        Observer.Observe('max1', Format(Mx, 0, 1));
        Observer.Observe('min1', Format(Mn, 0, 1));
        Observer.Observe('maxlen5', Format(Mx, 5));
        Observer.Observe('zero', Format(0));
        Observer.Observe('zero9', Format(0, 0, 9));
        Observer.Expect('max', '2147483647');
        Observer.Expect('min', '-2147483648');
        Observer.Expect('max9', '2147483647');
        Observer.Expect('min9', '-2147483648');
        Observer.Expect('max1', '2147483647');
        Observer.Expect('min1', '-2147483648');
        Observer.Expect('maxlen5', '21474');
        Observer.Expect('zero', '0');
        Observer.Expect('zero9', '0');
        Observer.Verify();
    end;

    [Test]
    procedure BigInteger_Format()
    var
        Observer: Codeunit "Probe Observer";
        B: BigInteger;
        n: Integer;
    begin
        Evaluate(B, '9223372036854775807');
        Observer.Observe('max', Format(B));
        Evaluate(B, '-9223372036854775808');
        Observer.Observe('min', Format(B));
        Evaluate(B, '12345678901234');
        for n := 0 to 9 do
            Observer.Observe('n' + Format(n), F(B, n));
        Observer.Observe('thousand', Format(B, 0, '<Integer Thousand>'));
        Observer.Expect('max', '9223372036854775807');
        Observer.Expect('min', '-9223372036854775808');
        Observer.Expect('n0', '12345678901234');
        Observer.Expect('n1', '12345678901234');
        Observer.Expect('n2', '12345678901234');
        Observer.Expect('n3', 'error:Standard format number 3 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n4', 'error:Standard format number 4 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n5', 'error:Standard format number 5 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n6', 'error:Standard format number 6 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n7', 'error:Standard format number 7 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n8', 'error:Standard format number 8 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n9', '12345678901234');
        Observer.Expect('thousand', '12,345,678,901,234');
        Observer.Verify();
    end;

    [Test]
    procedure Byte_Format()
    var
        Observer: Codeunit "Probe Observer";
        B: Byte;
        n: Integer;
    begin
        B := 200;
        Observer.Observe('default', Format(B));
        for n := 0 to 9 do
            Observer.Observe('n' + Format(n), F(B, n));
        B := 0;
        Observer.Observe('zero', Format(B));
        B := 255;
        Observer.Observe('max', Format(B));
        asserterror Observer.Observe('pad', Format(B, 0, '<Integer,6><Filler Character,0>'));
        Observer.ObserveError('af129');
        Observer.Expect('default', '˜');
        Observer.Expect('n0', '˜');
        Observer.Expect('n1', '˜');
        Observer.Expect('n2', '˜');
        Observer.Expect('n3', 'error:Standard format number 3 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n4', 'error:Standard format number 4 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n5', 'error:Standard format number 5 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n6', 'error:Standard format number 6 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n7', 'error:Standard format number 7 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n8', 'error:Standard format number 8 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n9', '˜');
        Observer.Expect('zero', '\u0000');
        Observer.Expect('max', ' ');
        Observer.Expect('af129|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\<Integer,6><Filler Character,0>');
        Observer.Expect('af129|code', 'InvalidFormatString');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_ToText()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        T: Text;
    begin
        I := -17;
        Evaluate(B, '5000000000');
        D := 3.14;
        Observer.Observe('int', Format(I));
        Observer.Observe('big', Format(B));
        Observer.Observe('dec', Format(D));
        T := Format(I) + '|' + Format(B) + '|' + Format(D);
        Observer.Observe('concat', T);
        Observer.Observe('int_text_concat', 'x' + Format(I));
        Observer.Observe('lenint', Format(StrLen(Format(Mxi()))));
        Observer.Expect('int', '-17');
        Observer.Expect('big', '5000000000');
        Observer.Expect('dec', '3.14');
        Observer.Expect('concat', '-17|5000000000|3.14');
        Observer.Expect('int_text_concat', 'x-17');
        Observer.Expect('lenint', '10');
        Observer.Verify();
    end;

    local procedure Mxi(): Integer
    begin
        exit(2147483647);
    end;
}
