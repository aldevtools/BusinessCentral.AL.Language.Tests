// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Evaluate into a Decimal of texts that mix digits and other characters (session language en-US (set explicitly to 1033)): return value and the value left in the variable (initial 77),
// error text start and code when Evaluate is a statement (in a TryFunction), and with format number 9. The session language is restored on all paths.
// BC versions: 29 (27 and 28 by CI)

codeunit 71570 "LT P175 Eval Dec En"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryEv(Txt: Text; var V: Decimal)
    begin
        Evaluate(V, Txt);
    end;

    [TryFunction]
    local procedure TryEv9(Txt: Text; var V: Decimal)
    begin
        Evaluate(V, Txt, 9);
    end;

    local procedure Ret(Txt: Text): Text
    var
        V: Decimal;
        Ok: Boolean;
    begin
        V := 77;
        Ok := Evaluate(V, Txt);
        exit(Format(Ok) + '|' + Format(V));
    end;

    local procedure Ret9(Txt: Text): Text
    var
        V: Decimal;
        Ok: Boolean;
    begin
        V := 77;
        Ok := Evaluate(V, Txt, 9);
        exit(Format(Ok) + '|' + Format(V));
    end;

    local procedure Stm(Txt: Text): Text
    var
        V: Decimal;
    begin
        V := 77;
        if TryEv(Txt, V) then
            exit('ok|' + Format(V));
        exit('err|' + CopyStr(GetLastErrorText(), 1, 150) + '|' + GetLastErrorCode() + '|' + Format(V));
    end;

    local procedure Stm9(Txt: Text): Text
    var
        V: Decimal;
    begin
        V := 77;
        if TryEv9(Txt, V) then
            exit('ok|' + Format(V));
        exit('err|' + CopyStr(GetLastErrorText(), 1, 150) + '|' + GetLastErrorCode() + '|' + Format(V));
    end;

    local procedure Texts(): List of [Text]
    var
        L: List of [Text];
    begin
        L.Add('12.5pt');
        L.Add('12,5');
        L.Add('1e3');
        L.Add(' 12 ');
        L.Add('12.');
        L.Add('.5');
        L.Add('-0');
        L.Add('1,234.5');
        L.Add('12abc');
        L.Add('');
        L.Add('1.234,5');
        L.Add('12,5.5');
        exit(L);
    end;

    [Test]
    procedure P175_En_ReturnValueAndLeftBehind()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
        Txt: Text;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        foreach Txt in Texts() do
            Observer.Observe('ret[' + Txt + ']', Ret(Txt));
        GlobalLanguage(Orig);
        Observer.Expect('ret[12.5pt]', 'No|77');
        Observer.Expect('ret[12,5]', 'Yes|125');
        Observer.Expect('ret[1e3]', 'Yes|1,000');
        Observer.Expect('ret[ 12 ]', 'Yes|12');
        Observer.Expect('ret[12.]', 'Yes|12');
        Observer.Expect('ret[.5]', 'Yes|0.5');
        Observer.Expect('ret[-0]', 'Yes|0');
        Observer.Expect('ret[1,234.5]', 'Yes|1,234.5');
        Observer.Expect('ret[12abc]', 'No|77');
        Observer.Expect('ret[]', 'No|77');
        Observer.Expect('ret[1.234,5]', 'No|77');
        Observer.Expect('ret[12,5.5]', 'Yes|125.5');
        Observer.Verify();
    end;

    [Test]
    procedure P175_En_StatementErrorText()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
        Txt: Text;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        foreach Txt in Texts() do
            Observer.Observe('stm[' + Txt + ']', Stm(Txt));
        GlobalLanguage(Orig);
        Observer.Expect('stm[12.5pt]', 'err|The value "12.5pt" can''t be evaluated into type Decimal.|Evaluate|77');
        Observer.Expect('stm[12,5]', 'ok|125');
        Observer.Expect('stm[1e3]', 'ok|1,000');
        Observer.Expect('stm[ 12 ]', 'ok|12');
        Observer.Expect('stm[12.]', 'ok|12');
        Observer.Expect('stm[.5]', 'ok|0.5');
        Observer.Expect('stm[-0]', 'ok|0');
        Observer.Expect('stm[1,234.5]', 'ok|1,234.5');
        Observer.Expect('stm[12abc]', 'err|The value "12abc" can''t be evaluated into type Decimal.|Evaluate|77');
        Observer.Expect('stm[]', 'err|The value "" can''t be evaluated into type Decimal.|Evaluate|77');
        Observer.Expect('stm[1.234,5]', 'err|The value "1.234,5" can''t be evaluated into type Decimal.|Evaluate|77');
        Observer.Expect('stm[12,5.5]', 'ok|125.5');
        Observer.Verify();
    end;

    [Test]
    procedure P175_En_Format9ReturnValue()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
        Txt: Text;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        foreach Txt in Texts() do
            Observer.Observe('ret9[' + Txt + ']', Ret9(Txt));
        GlobalLanguage(Orig);
        Observer.Expect('ret9[12.5pt]', 'No|77');
        Observer.Expect('ret9[12,5]', 'No|77');
        Observer.Expect('ret9[1e3]', 'Yes|1,000');
        Observer.Expect('ret9[ 12 ]', 'Yes|12');
        Observer.Expect('ret9[12.]', 'Yes|12');
        Observer.Expect('ret9[.5]', 'Yes|0.5');
        Observer.Expect('ret9[-0]', 'Yes|0');
        Observer.Expect('ret9[1,234.5]', 'No|77');
        Observer.Expect('ret9[12abc]', 'No|77');
        Observer.Expect('ret9[]', 'No|77');
        Observer.Expect('ret9[1.234,5]', 'No|77');
        Observer.Expect('ret9[12,5.5]', 'No|77');
        Observer.Verify();
    end;

    [Test]
    procedure P175_En_Format9StatementErrorText()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
        Txt: Text;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        foreach Txt in Texts() do
            Observer.Observe('stm9[' + Txt + ']', Stm9(Txt));
        GlobalLanguage(Orig);
        Observer.Expect('stm9[12.5pt]', 'err|The value "12.5pt" can''t be evaluated into type Decimal.|Evaluate|77');
        Observer.Expect('stm9[12,5]', 'err|The value "12,5" can''t be evaluated into type Decimal.|Evaluate|77');
        Observer.Expect('stm9[1e3]', 'ok|1,000');
        Observer.Expect('stm9[ 12 ]', 'ok|12');
        Observer.Expect('stm9[12.]', 'ok|12');
        Observer.Expect('stm9[.5]', 'ok|0.5');
        Observer.Expect('stm9[-0]', 'ok|0');
        Observer.Expect('stm9[1,234.5]', 'err|The value "1,234.5" can''t be evaluated into type Decimal.|Evaluate|77');
        Observer.Expect('stm9[12abc]', 'err|The value "12abc" can''t be evaluated into type Decimal.|Evaluate|77');
        Observer.Expect('stm9[]', 'err|The value "" can''t be evaluated into type Decimal.|Evaluate|77');
        Observer.Expect('stm9[1.234,5]', 'err|The value "1.234,5" can''t be evaluated into type Decimal.|Evaluate|77');
        Observer.Expect('stm9[12,5.5]', 'err|The value "12,5.5" can''t be evaluated into type Decimal.|Evaluate|77');
        Observer.Verify();
    end;

    [Test]
    procedure P175_En_FormatOfSameValues()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        Observer.Observe('f1', Format(12.5));
        Observer.Observe('f2', Format(1234.5));
        Observer.Observe('f3', Format(1000));
        Observer.Observe('f4', Format(-0.5));
        Observer.Observe('f5', Format(1000, 0, 9));
        GlobalLanguage(Orig);
        Observer.Expect('f1', '12.5');
        Observer.Expect('f2', '1,234.5');
        Observer.Expect('f3', '1000');
        Observer.Expect('f4', '-0.5');
        Observer.Expect('f5', '1000');
        Observer.Verify();
    end;
}
