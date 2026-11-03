// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Facts: Evaluate into a Time from digit-only texts and from '8:56' (with and without format 9); Evaluate of Integer and BigInteger texts
//   with a lower-case exponent, BigInteger texts with commas under format 9, Decimal texts with a currency sign other than $;
//   a Variant holding a Date assigned to a Text; a Boolean assigned to a Text and a Code; Get(true) on a table with a Code[10] key.
// BC versions: 27.5+

table 80401 "LT AX Code Key"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; KeyCode; Code[10]) { }
        field(2; Info; Text[30]) { }
    }

    keys
    {
        key(PK; KeyCode) { Clustered = true; }
    }
}

codeunit 80421 "LT AX Evaluate Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure EvT(Txt: Text; Fmt: Integer): Text
    var
        T: Time;
        Ok: Boolean;
    begin
        T := 101010T;
        if Fmt < 0 then
            Ok := Evaluate(T, Txt)
        else
            Ok := Evaluate(T, Txt, Fmt);
        exit(Format(Ok) + '|' + Format(T, 0, 9));
    end;

    [Test]
    procedure Evaluate_Time_DigitTexts_NoFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('085606', EvT('085606', -1));
        Observer.Observe('23', EvT('23', -1));
        Observer.Observe('5', EvT('5', -1));
        Observer.Observe('246000', EvT('246000', -1));
        Observer.Observe('24', EvT('24', -1));
        Observer.Observe('0856', EvT('0856', -1));
        Observer.Observe('8:56', EvT('8:56', -1));
        Observer.Expect('085606', 'Yes|08:56:06');
        Observer.Expect('23', 'Yes|23:00:00');
        Observer.Expect('5', 'Yes|05:00:00');
        Observer.Expect('246000', 'No|10:10:10');
        Observer.Expect('24', 'No|10:10:10');
        Observer.Expect('0856', 'Yes|08:56:00');
        Observer.Expect('8:56', 'Yes|08:56:00');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_Time_DigitTexts_Format9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('085606', EvT('085606', 9));
        Observer.Observe('23', EvT('23', 9));
        Observer.Observe('5', EvT('5', 9));
        Observer.Observe('246000', EvT('246000', 9));
        Observer.Observe('24', EvT('24', 9));
        Observer.Observe('0856', EvT('0856', 9));
        Observer.Observe('8:56', EvT('8:56', 9));
        Observer.Expect('085606', 'No|10:10:10');
        Observer.Expect('23', 'No|10:10:10');
        Observer.Expect('5', 'No|10:10:10');
        Observer.Expect('246000', 'No|10:10:10');
        Observer.Expect('24', 'No|10:10:10');
        Observer.Expect('0856', 'No|10:10:10');
        Observer.Expect('8:56', 'No|10:10:10');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryEvalTime(Txt: Text; var T: Time)
    begin
        Evaluate(T, Txt);
    end;

    [Test]
    procedure Evaluate_Time_Invalid_StatementForm()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
    begin
        T := 101010T;
        if TryEvalTime('246000', T) then
            Observer.Observe('246000', 'no error|' + Format(T, 0, 9))
        else begin
            Observer.ObserveError('246000');
            Observer.Observe('246000 after', Format(T, 0, 9));
        end;
        T := 101010T;
        if TryEvalTime('24', T) then
            Observer.Observe('24', 'no error|' + Format(T, 0, 9))
        else
            Observer.ObserveError('24');
        Observer.Expect('246000|text', 'The value "246000" can''t be evaluated into type Time.');
        Observer.Expect('246000|code', 'Evaluate');
        Observer.Expect('246000 after', '10:10:10');
        Observer.Expect('24|text', 'The value "24" can''t be evaluated into type Time.');
        Observer.Expect('24|code', 'Evaluate');
        Observer.Verify();
    end;

    local procedure EvI(Txt: Text): Text
    var
        I: Integer;
        Ok: Boolean;
    begin
        I := 99;
        Ok := Evaluate(I, Txt);
        exit(Format(Ok) + '|' + Format(I, 0, 9));
    end;

    local procedure EvB(Txt: Text; Fmt: Integer): Text
    var
        B: BigInteger;
        Ok: Boolean;
    begin
        B := 99;
        if Fmt < 0 then
            Ok := Evaluate(B, Txt)
        else
            Ok := Evaluate(B, Txt, Fmt);
        exit(Format(Ok) + '|' + Format(B, 0, 9));
    end;

    local procedure EvD(Txt: Text): Text
    var
        D: Decimal;
        Ok: Boolean;
    begin
        D := 99;
        Ok := Evaluate(D, Txt);
        exit(Format(Ok) + '|' + Format(D, 0, 9));
    end;

    [Test]
    procedure Evaluate_Integer_LowerCaseExponent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('int 1e3', EvI('1e3'));
        Observer.Observe('int 2e2', EvI('2e2'));
        Observer.Observe('int -1e2', EvI('-1e2'));
        Observer.Observe('int 1e-1', EvI('1e-1'));
        Observer.Observe('big 1e3', EvB('1e3', -1));
        Observer.Observe('big 1E3', EvB('1E3', -1));
        Observer.Observe('big 1e15', EvB('1e15', -1));
        Observer.Observe('big 1e3 f9', EvB('1e3', 9));
        Observer.Expect('int 1e3', 'Yes|1000');
        Observer.Expect('int 2e2', 'Yes|200');
        Observer.Expect('int -1e2', 'Yes|-100');
        Observer.Expect('int 1e-1', 'No|99');
        Observer.Expect('big 1e3', 'Yes|1000');
        Observer.Expect('big 1E3', 'Yes|1000');
        Observer.Expect('big 1e15', 'Yes|1000000000000000');
        Observer.Expect('big 1e3 f9', 'No|99');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_BigInteger_Commas()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1,000 f9', EvB('1,000', 9));
        Observer.Observe('1,000,000 f9', EvB('1,000,000', 9));
        Observer.Observe('1000 f9', EvB('1000', 9));
        Observer.Observe('1,000', EvB('1,000', -1));
        Observer.Observe('1,000,000', EvB('1,000,000', -1));
        Observer.Observe('1,5', EvB('1,5', -1));
        Observer.Expect('1,000 f9', 'No|99');
        Observer.Expect('1,000,000 f9', 'No|99');
        Observer.Expect('1000 f9', 'Yes|1000');
        Observer.Expect('1,000', 'Yes|1000');
        Observer.Expect('1,000,000', 'Yes|1000000');
        Observer.Expect('1,5', 'Yes|15');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_Decimal_CurrencySigns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('$5', EvD('$5'));
        Observer.Observe('5$', EvD('5$'));
        Observer.Observe('€5', EvD('€5'));
        Observer.Observe('5€', EvD('5€'));
        Observer.Observe('£5', EvD('£5'));
        Observer.Observe('¥5', EvD('¥5'));
        Observer.Observe('EUR5', EvD('EUR5'));
        Observer.Observe('-$5.5', EvD('-$5.5'));
        Observer.Expect('$5', 'Yes|5');
        Observer.Expect('5$', 'Yes|5');
        Observer.Expect('€5', 'No|99');
        Observer.Expect('5€', 'No|99');
        Observer.Expect('£5', 'No|99');
        Observer.Expect('¥5', 'No|99');
        Observer.Expect('EUR5', 'No|99');
        Observer.Expect('-$5.5', 'Yes|-5.5');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryVariantToText(V: Variant; var Txt: Text)
    begin
        Txt := V;
    end;

    [Test]
    procedure VariantDate_ToText()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        D: Date;
        D2: Date;
        Txt: Text;
        Ok: Boolean;
    begin
        D := DMY2Date(15, 3, 2024);
        V := D;
        if TryVariantToText(V, Txt) then begin
            Observer.Observe('text', '[' + Txt + ']');
            Observer.Observe('equals Format(D)', Format(Txt = Format(D)));
            Ok := Evaluate(D2, Txt);
            Observer.Observe('evaluate back', Format(Ok) + '|' + Format(D2, 0, 9));
        end else
            Observer.ObserveError('assign');
        V := 0D;
        Txt := 'x';
        if TryVariantToText(V, Txt) then
            Observer.Observe('blank text', '[' + Txt + ']')
        else
            Observer.ObserveError('blank assign');
        Observer.Expect('assign|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('assign|code', 'TypeConversion');
        Observer.Expect('blank assign|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('blank assign|code', 'TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure Boolean_ToText_ToCode()
    var
        Observer: Codeunit "Probe Observer";
        B: Boolean;
        Txt: Text;
        C: Code[10];
        V: Variant;
    begin
        B := true;
        V := B;
        if TryVariantToText(V, Txt) then
            Observer.Observe('variant true->text', '[' + Txt + ']')
        else
            Observer.ObserveError('variant true->text');
        B := false;
        V := B;
        if TryVariantToText(V, Txt) then
            Observer.Observe('variant false->text', '[' + Txt + ']')
        else
            Observer.ObserveError('variant false->text');
        C := Format(true);
        Observer.Observe('code Format(true)', C);
        Observer.Expect('variant true->text|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('variant true->text|code', 'TypeConversion');
        Observer.Expect('variant false->text|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('variant false->text|code', 'TypeConversion');
        Observer.Expect('code Format(true)', 'YES');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryVariantToLocalText(V: Variant; var Txt: Text)
    var
        LocalTxt: Text;
    begin
        LocalTxt := V;
        Txt := LocalTxt;
    end;

    [Test]
    procedure Variant_ToLocalText_DateBooleanText()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        Txt: Text;
    begin
        V := DMY2Date(15, 3, 2024);
        if TryVariantToLocalText(V, Txt) then
            Observer.Observe('date', '[' + Txt + ']')
        else
            Observer.ObserveError('date');
        V := true;
        if TryVariantToLocalText(V, Txt) then
            Observer.Observe('boolean', '[' + Txt + ']')
        else
            Observer.ObserveError('boolean');
        V := 'abc';
        if TryVariantToLocalText(V, Txt) then
            Observer.Observe('text', '[' + Txt + ']')
        else
            Observer.ObserveError('text');
        Observer.Expect('date|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('date|code', 'TypeConversion');
        Observer.Expect('boolean|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('boolean|code', 'TypeConversion');
        Observer.Expect('text', '[abc]');
        Observer.Verify();
    end;

    local procedure GetTrue(): Text
    var
        R: Record "LT AX Code Key";
    begin
        if R.Get(true) then
            exit('found ' + R.KeyCode);
        exit('not found');
    end;

    local procedure Seed(K: Code[10])
    var
        R: Record "LT AX Code Key";
    begin
        R.Init();
        R.KeyCode := K;
        R.Info := K;
        R.Insert();
    end;

    [Test]
    procedure GetTrue_CodeKey_Yes()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT AX Code Key";
    begin
        R.DeleteAll();
        Seed('Yes');
        Observer.Observe('Yes', GetTrue());
        R.DeleteAll();
        Seed('1');
        Observer.Observe('1', GetTrue());
        R.DeleteAll();
        Seed('TRUE');
        Observer.Observe('TRUE', GetTrue());
        Seed('YES');
        Observer.Observe('TRUE+YES', GetTrue());
        R.DeleteAll();
        Observer.Expect('Yes', 'found YES');
        Observer.Expect('1', 'not found');
        Observer.Expect('TRUE', 'not found');
        Observer.Expect('TRUE+YES', 'found YES');
        Observer.Verify();
    end;
}
