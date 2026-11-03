// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Evaluate of '%PDF-1.4', '1.4abc', '12 34' and '1,2.3' into Decimal, Integer and BigInteger with session language de-DE (1031, set explicitly): the answer (Yes/No), the value left in the variable (preset 77),
// error text start and code when Evaluate is a statement (TryFunction), for Decimal also with format number 9. Texts already pinned in LT Eval Decimal En/De (types/lt-evaluate-decimal-text) and P129Evaluate.al are not repeated.
// The session language is restored on all paths (no asserterror, the errors are caught by TryFunction).
// BC versions: 29 (27 and 28 by CI)

codeunit 71697 "LT Eval Mixed De"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryDec(Txt: Text; var V: Decimal)
    begin
        Evaluate(V, Txt);
    end;

    [TryFunction]
    local procedure TryDec9(Txt: Text; var V: Decimal)
    begin
        Evaluate(V, Txt, 9);
    end;

    [TryFunction]
    local procedure TryInt(Txt: Text; var V: Integer)
    begin
        Evaluate(V, Txt);
    end;

    [TryFunction]
    local procedure TryBig(Txt: Text; var V: BigInteger)
    begin
        Evaluate(V, Txt);
    end;

    local procedure ErrTail(): Text
    begin
        exit('err|' + CopyStr(GetLastErrorText(), 1, 150) + '|' + GetLastErrorCode());
    end;

    local procedure DecAnswer(Txt: Text): Text
    var
        V: Decimal;
        Ok: Boolean;
    begin
        V := 77;
        Ok := Evaluate(V, Txt);
        exit(Format(Ok) + '|' + Format(V));
    end;

    local procedure Dec9Answer(Txt: Text): Text
    var
        V: Decimal;
        Ok: Boolean;
    begin
        V := 77;
        Ok := Evaluate(V, Txt, 9);
        exit(Format(Ok) + '|' + Format(V));
    end;

    local procedure IntAnswer(Txt: Text): Text
    var
        V: Integer;
        Ok: Boolean;
    begin
        V := 77;
        Ok := Evaluate(V, Txt);
        exit(Format(Ok) + '|' + Format(V));
    end;

    local procedure BigAnswer(Txt: Text): Text
    var
        V: BigInteger;
        Ok: Boolean;
    begin
        V := 77;
        Ok := Evaluate(V, Txt);
        exit(Format(Ok) + '|' + Format(V));
    end;

    local procedure DecStm(Txt: Text): Text
    var
        V: Decimal;
    begin
        V := 77;
        if TryDec(Txt, V) then
            exit('ok|' + Format(V));
        exit(ErrTail() + '|' + Format(V));
    end;

    local procedure Dec9Stm(Txt: Text): Text
    var
        V: Decimal;
    begin
        V := 77;
        if TryDec9(Txt, V) then
            exit('ok|' + Format(V));
        exit(ErrTail() + '|' + Format(V));
    end;

    local procedure IntStm(Txt: Text): Text
    var
        V: Integer;
    begin
        V := 77;
        if TryInt(Txt, V) then
            exit('ok|' + Format(V));
        exit(ErrTail() + '|' + Format(V));
    end;

    local procedure BigStm(Txt: Text): Text
    var
        V: BigInteger;
    begin
        V := 77;
        if TryBig(Txt, V) then
            exit('ok|' + Format(V));
        exit(ErrTail() + '|' + Format(V));
    end;

    local procedure Texts(): List of [Text]
    var
        L: List of [Text];
    begin
        L.Add('%PDF-1.4');
        L.Add('1.4abc');
        L.Add('12 34');
        L.Add('1,2.3');
        exit(L);
    end;

    [Test]
    procedure Decimal_Answer_AndValueLeft()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
        Txt: Text;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        foreach Txt in Texts() do
            Observer.Observe('dec[' + Txt + ']', DecAnswer(Txt));
        GlobalLanguage(Orig);
        Observer.Expect('dec[%PDF-1.4]', 'Nein|77');
        Observer.Expect('dec[1.4abc]', 'Nein|77');
        Observer.Expect('dec[12 34]', 'Nein|77');
        Observer.Expect('dec[1,2.3]', 'Ja|12.3');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_StatementError_TextAndCode()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
        Txt: Text;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        foreach Txt in Texts() do
            Observer.Observe('decStm[' + Txt + ']', DecStm(Txt));
        GlobalLanguage(Orig);
        Observer.Expect('decStm[%PDF-1.4]', 'err|Der Wert „%PDF-1.4“ kann nicht in Typ Decimal ausgewertet werden.|Evaluate|77');
        Observer.Expect('decStm[1.4abc]', 'err|Der Wert „1.4abc“ kann nicht in Typ Decimal ausgewertet werden.|Evaluate|77');
        Observer.Expect('decStm[12 34]', 'err|Der Wert „12 34“ kann nicht in Typ Decimal ausgewertet werden.|Evaluate|77');
        Observer.Expect('decStm[1,2.3]', 'ok|12.3');
        Observer.Verify();
    end;

    [Test]
    procedure DecimalFormat9_Answer_AndValueLeft()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
        Txt: Text;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        foreach Txt in Texts() do
            Observer.Observe('dec9[' + Txt + ']', Dec9Answer(Txt));
        GlobalLanguage(Orig);
        Observer.Expect('dec9[%PDF-1.4]', 'Nein|77');
        Observer.Expect('dec9[1.4abc]', 'Nein|77');
        Observer.Expect('dec9[12 34]', 'Nein|77');
        Observer.Expect('dec9[1,2.3]', 'Nein|77');
        Observer.Verify();
    end;

    [Test]
    procedure DecimalFormat9_StatementError_TextAndCode()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
        Txt: Text;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        foreach Txt in Texts() do
            Observer.Observe('dec9Stm[' + Txt + ']', Dec9Stm(Txt));
        GlobalLanguage(Orig);
        Observer.Expect('dec9Stm[%PDF-1.4]', 'err|Der Wert „%PDF-1.4“ kann nicht in Typ Decimal ausgewertet werden.|Evaluate|77');
        Observer.Expect('dec9Stm[1.4abc]', 'err|Der Wert „1.4abc“ kann nicht in Typ Decimal ausgewertet werden.|Evaluate|77');
        Observer.Expect('dec9Stm[12 34]', 'err|Der Wert „12 34“ kann nicht in Typ Decimal ausgewertet werden.|Evaluate|77');
        Observer.Expect('dec9Stm[1,2.3]', 'err|Der Wert „1,2.3“ kann nicht in Typ Decimal ausgewertet werden.|Evaluate|77');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_Answer_AndValueLeft()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
        Txt: Text;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        foreach Txt in Texts() do
            Observer.Observe('int[' + Txt + ']', IntAnswer(Txt));
        GlobalLanguage(Orig);
        Observer.Expect('int[%PDF-1.4]', 'Nein|77');
        Observer.Expect('int[1.4abc]', 'Nein|77');
        Observer.Expect('int[12 34]', 'Nein|77');
        Observer.Expect('int[1,2.3]', 'Nein|77');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_StatementError_TextAndCode()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
        Txt: Text;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        foreach Txt in Texts() do
            Observer.Observe('intStm[' + Txt + ']', IntStm(Txt));
        GlobalLanguage(Orig);
        Observer.Expect('intStm[%PDF-1.4]', 'err|Der Wert „%PDF-1.4“ kann nicht in Typ Integer ausgewertet werden.|Evaluate|77');
        Observer.Expect('intStm[1.4abc]', 'err|Der Wert „1.4abc“ kann nicht in Typ Integer ausgewertet werden.|Evaluate|77');
        Observer.Expect('intStm[12 34]', 'err|Der Wert „12 34“ kann nicht in Typ Integer ausgewertet werden.|Evaluate|77');
        Observer.Expect('intStm[1,2.3]', 'err|Der Wert „1,2.3“ kann nicht in Typ Integer ausgewertet werden.|Evaluate|77');
        Observer.Verify();
    end;

    [Test]
    procedure BigInteger_Answer_AndValueLeft()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
        Txt: Text;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        foreach Txt in Texts() do
            Observer.Observe('big[' + Txt + ']', BigAnswer(Txt));
        GlobalLanguage(Orig);
        Observer.Expect('big[%PDF-1.4]', 'Nein|77');
        Observer.Expect('big[1.4abc]', 'Nein|77');
        Observer.Expect('big[12 34]', 'Nein|77');
        Observer.Expect('big[1,2.3]', 'Nein|77');
        Observer.Verify();
    end;

    [Test]
    procedure BigInteger_StatementError_TextAndCode()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
        Txt: Text;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        foreach Txt in Texts() do
            Observer.Observe('bigStm[' + Txt + ']', BigStm(Txt));
        GlobalLanguage(Orig);
        Observer.Expect('bigStm[%PDF-1.4]', 'err|Der Wert „%PDF-1.4“ kann nicht in Typ BigInteger ausgewertet werden.|Evaluate|77');
        Observer.Expect('bigStm[1.4abc]', 'err|Der Wert „1.4abc“ kann nicht in Typ BigInteger ausgewertet werden.|Evaluate|77');
        Observer.Expect('bigStm[12 34]', 'err|Der Wert „12 34“ kann nicht in Typ BigInteger ausgewertet werden.|Evaluate|77');
        Observer.Expect('bigStm[1,2.3]', 'err|Der Wert „1,2.3“ kann nicht in Typ BigInteger ausgewertet werden.|Evaluate|77');
        Observer.Verify();
    end;
}
