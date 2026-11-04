// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/boolean/boolean-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own codeunit 73943
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Boolean and BigInteger/Integer/Option through Evaluate and Format numbers 0-9 (direct conversions that do not compile are must-not-compile cases)
// BC versions: 29 (27 and 28 by CI)

codeunit 73943 "LT P79 Boolean Convert"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryBoolFormat(B: Boolean; N: Integer; var R: Text)
    begin
        R := Format(B, 0, N);
    end;

    local procedure BF(B: Boolean; N: Integer): Text
    var
        R: Text;
    begin
        if TryBoolFormat(B, N, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryEvalBool(Txt: Text; var R: Text)
    var
        B: Boolean;
    begin
        B := true;
        if Evaluate(B, Txt) then
            R := 'ok/' + Format(B, 0, 2)
        else
            R := 'false/' + Format(B, 0, 2);
    end;

    local procedure EB(Txt: Text): Text
    var
        R: Text;
    begin
        if TryEvalBool(Txt, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Boolean_FormatNumbers()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 0 to 9 do begin
            Observer.Observe('t' + Format(i), BF(true, i));
            Observer.Observe('f' + Format(i), BF(false, i));
        end;
        Observer.Expect('t0', 'Yes');
        Observer.Expect('f0', 'No');
        Observer.Expect('t1', 'Yes');
        Observer.Expect('f1', 'No');
        Observer.Expect('t2', '1');
        Observer.Expect('f2', '0');
        Observer.Expect('t3', 'error:Standard format number 3 does not exist for the type ''Char''.|InvalidStandardFormat');
        Observer.Expect('f3', 'error:Standard format number 3 does not exist for the type ''Char''.|InvalidStandardFormat');
        Observer.Expect('t4', 'error:Standard format number 4 does not exist for the type ''Char''.|InvalidStandardFormat');
        Observer.Expect('f4', 'error:Standard format number 4 does not exist for the type ''Char''.|InvalidStandardFormat');
        Observer.Expect('t5', 'error:Standard format number 5 does not exist for the type ''Char''.|InvalidStandardFormat');
        Observer.Expect('f5', 'error:Standard format number 5 does not exist for the type ''Char''.|InvalidStandardFormat');
        Observer.Expect('t6', 'error:Standard format number 6 does not exist for the type ''Char''.|InvalidStandardFormat');
        Observer.Expect('f6', 'error:Standard format number 6 does not exist for the type ''Char''.|InvalidStandardFormat');
        Observer.Expect('t7', 'error:Standard format number 7 does not exist for the type ''Char''.|InvalidStandardFormat');
        Observer.Expect('f7', 'error:Standard format number 7 does not exist for the type ''Char''.|InvalidStandardFormat');
        Observer.Expect('t8', 'error:Standard format number 8 does not exist for the type ''Char''.|InvalidStandardFormat');
        Observer.Expect('f8', 'error:Standard format number 8 does not exist for the type ''Char''.|InvalidStandardFormat');
        Observer.Expect('t9', 'true');
        Observer.Expect('f9', 'false');
        Observer.Verify();
    end;

    [Test]
    procedure Boolean_ToIntegerViaFormat()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        Ok: Boolean;
    begin
        Ok := Evaluate(I, Format(true, 0, 2));
        Observer.Observe('true-eval', Format(Ok) + '/' + Format(I));
        Ok := Evaluate(I, Format(false, 0, 2));
        Observer.Observe('false-eval', Format(Ok) + '/' + Format(I));
        Ok := Evaluate(I, Format(true, 0, 1));
        Observer.Observe('true-n1-eval', Format(Ok) + '/' + Format(I));
        Ok := Evaluate(I, Format(true));
        Observer.Observe('true-default-eval', Format(Ok));
        Observer.Expect('true-eval', 'Yes/1');
        Observer.Expect('false-eval', 'Yes/0');
        Observer.Expect('true-n1-eval', 'No/0');
        Observer.Expect('true-default-eval', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Boolean_EvaluateFromText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('0', EB('0'));
        Observer.Observe('1', EB('1'));
        Observer.Observe('2', EB('2'));
        Observer.Observe('-1', EB('-1'));
        Observer.Observe('true', EB('true'));
        Observer.Observe('TRUE', EB('TRUE'));
        Observer.Observe('false', EB('false'));
        Observer.Observe('yes', EB('yes'));
        Observer.Observe('no', EB('no'));
        Observer.Observe('Yes', EB('Yes'));
        Observer.Observe('Ja', EB('Ja'));
        Observer.Observe('empty', EB(''));
        Observer.Observe('space-1', EB(' 1'));
        Observer.Observe('big', EB('4294967296'));
        Observer.Observe('1.0', EB('1.0'));
        Observer.Observe('x', EB('x'));
        Observer.Expect('0', 'ok/0');
        Observer.Expect('1', 'ok/1');
        Observer.Expect('2', 'false/1');
        Observer.Expect('-1', 'false/1');
        Observer.Expect('true', 'ok/1');
        Observer.Expect('TRUE', 'ok/1');
        Observer.Expect('false', 'ok/0');
        Observer.Expect('yes', 'ok/1');
        Observer.Expect('no', 'ok/0');
        Observer.Expect('Yes', 'ok/1');
        Observer.Expect('Ja', 'false/1');
        Observer.Expect('empty', 'false/1');
        Observer.Expect('space-1', 'ok/1');
        Observer.Expect('big', 'false/1');
        Observer.Expect('1.0', 'ok/1');
        Observer.Expect('x', 'false/1');
        Observer.Verify();
    end;

    [Test]
    procedure Boolean_EvaluateFromBigIntegerText()
    var
        Observer: Codeunit "Probe Observer";
        Big: BigInteger;
    begin
        Evaluate(Big, '0');
        Observer.Observe('0', EB(Format(Big)));
        Evaluate(Big, '1');
        Observer.Observe('1', EB(Format(Big)));
        Evaluate(Big, '5');
        Observer.Observe('5', EB(Format(Big)));
        Evaluate(Big, '-1');
        Observer.Observe('-1', EB(Format(Big, 0, 2)));
        Evaluate(Big, '9223372036854775807');
        Observer.Observe('max', EB(Format(Big, 0, 2)));
        Observer.Expect('0', 'ok/0');
        Observer.Expect('1', 'ok/1');
        Observer.Expect('5', 'false/1');
        Observer.Expect('-1', 'false/1');
        Observer.Expect('max', 'false/1');
        Observer.Verify();
    end;

    [Test]
    procedure Boolean_FromVariantAndCompare()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        B: Boolean;
        Big: BigInteger;
    begin
        Big := 1;
        V := Big;
        Observer.Observe('big-var-isbigint', Format(V.IsBigInteger()));
        Observer.Observe('big-var-isbool', Format(V.IsBoolean()));
        V := true;
        Observer.Observe('bool-var-isbool', Format(V.IsBoolean()));
        Observer.Observe('bool-var-isint', Format(V.IsInteger()));
        B := V;
        Observer.Observe('bool-from-var', Format(B));
        V := 1;
        Observer.Observe('int-var-isint', Format(V.IsInteger()));
        Observer.Observe('int-var-isbool', Format(V.IsBoolean()));
        Observer.Expect('big-var-isbigint', 'Yes');
        Observer.Expect('big-var-isbool', 'No');
        Observer.Expect('bool-var-isbool', 'Yes');
        Observer.Expect('bool-var-isint', 'No');
        Observer.Expect('bool-from-var', 'Yes');
        Observer.Expect('int-var-isint', 'Yes');
        Observer.Expect('int-var-isbool', 'No');
        Observer.Verify();
    end;
}
