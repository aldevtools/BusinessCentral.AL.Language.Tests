// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// LowerCase and UpperCase.
// BC versions: 29 (27 and 28 by CI)

codeunit 70509 "LT TxB CaseConv"
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
    procedure LowerUpperBasic()
    begin
        Obs.Observe('a1', Format(LowerCase('ABC')));
        Obs.Observe('a2', Format(LowerCase('abc')));
        Obs.Observe('a3', Format(LowerCase('AbC123')));
        Obs.Observe('a4', Format(LowerCase('')));
        Obs.Observe('a5', Format(LowerCase(' A ')));
        Obs.Observe('a6', Format(LowerCase('ÄÖÜ')));
        Obs.Observe('a7', Format(LowerCase('ß')));
        Obs.Observe('a8', Format(LowerCase('ÀÉÎ')));
        Obs.Observe('a9', Format(LowerCase('İ')));
        Obs.Observe('a10', Format(LowerCase('Ωμέγα')));
        Obs.Observe('a11', Format(LowerCase('日本')));
        Obs.Observe('a12', Format(LowerCase('Σ')));
        Obs.Observe('a13', Format(LowerCase('ǅ')));
        Obs.Observe('b1', Format(UpperCase('abc')));
        Obs.Observe('b2', Format(UpperCase('ABC')));
        Obs.Observe('b3', Format(UpperCase('aBc123')));
        Obs.Observe('b4', Format(UpperCase('')));
        Obs.Observe('b5', Format(UpperCase(' a ')));
        Obs.Observe('b6', Format(UpperCase('äöü')));
        Obs.Observe('b7', Format(UpperCase('ß')));
        Obs.Observe('b8', Format(UpperCase('àéî')));
        Obs.Observe('b9', Format(UpperCase('ı')));
        Obs.Observe('b10', Format(UpperCase('ωμέγα')));
        Obs.Observe('b11', Format(UpperCase('日本')));
        Obs.Observe('b12', Format(UpperCase('ς')));
        Obs.Observe('b13', Format(UpperCase('ǆ')));
        Obs.Observe('b14', Format(UpperCase('ÿ')));
        Obs.Observe('b15', Format(UpperCase('µ')));
        Obs.Expect('a1', 'abc');
        Obs.Expect('a2', 'abc');
        Obs.Expect('a3', 'abc123');
        Obs.Expect('a4', '');
        Obs.Expect('a5', ' a ');
        Obs.Expect('a6', 'äöü');
        Obs.Expect('a7', 'ß');
        Obs.Expect('a8', 'àéî');
        Obs.Expect('a9', 'i');
        Obs.Expect('a10', 'ωμέγα');
        Obs.Expect('a11', '日本');
        Obs.Expect('a12', 'σ');
        Obs.Expect('a13', 'ǆ');
        Obs.Expect('b1', 'ABC');
        Obs.Expect('b2', 'ABC');
        Obs.Expect('b3', 'ABC123');
        Obs.Expect('b4', '');
        Obs.Expect('b5', ' A ');
        Obs.Expect('b6', 'ÄÖÜ');
        Obs.Expect('b7', 'ß');
        Obs.Expect('b8', 'ÀÉÎ');
        Obs.Expect('b9', 'I');
        Obs.Expect('b10', 'ΩΜΈΓΑ');
        Obs.Expect('b11', '日本');
        Obs.Expect('b12', 'Σ');
        Obs.Expect('b13', 'Ǆ');
        Obs.Expect('b14', 'Ÿ');
        Obs.Expect('b15', 'Μ');
        Obs.Verify();
    end;

    [Test]
    procedure LowerUpperLengthsAndTargets()
    begin
        T := 'MiXeD';
        Obs.Observe('l', Format(LowerCase(T)));
        Obs.Observe('u', Format(UpperCase(T)));
        Obs.Observe('lenl', Format(StrLen(LowerCase(T))));
        Obs.Observe('lenu', Format(StrLen(UpperCase('ß'))));
        T5 := LowerCase('ABCDE');
        Obs.Observe('t5', Format(T5));
        asserterror T5 := UpperCase('abcdef');
        Obs.ObserveError('t5over');
        C5 := LowerCase('abc');
        Obs.Observe('c5', Format(C5));
        C5 := UpperCase('a b');
        Obs.Observe('c5sp', Format(C5));
        Obs.Observe('eqlower', Format(LowerCase('ABC') = 'abc'));
        Obs.Observe('label', Format(UpperCase(TLabel)));
        Obs.Observe('labelc', Format(UpperCase(CLabel)));
        Obs.Observe('double', Format(LowerCase(UpperCase('aB'))));
        Obs.Expect('l', 'mixed');
        Obs.Expect('u', 'MIXED');
        Obs.Expect('lenl', '5');
        Obs.Expect('lenu', '1');
        Obs.Expect('t5', 'abcde');
        Obs.Expect('t5over|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: ABCDEF');
        Obs.Expect('t5over|code', 'StringLengthExceeded');
        Obs.Expect('c5', 'ABC');
        Obs.Expect('c5sp', 'A B');
        Obs.Expect('eqlower', 'Yes');
        Obs.Expect('label', 'HELLO WORLD');
        Obs.Expect('labelc', 'ABC');
        Obs.Expect('double', 'ab');
        Obs.Verify();
    end;

    // Corpus issue 672 (odd AL behavior leads, part G), item 54: Learn says LowerCase and UpperCase follow the culture while
    // Text.ToLower and ToUpper do not. With GlobalLanguage set to Turkish (1055) and Greek (1032): the Turkish I and i,
    // the Greek final sigma, and the German sharp s. GlobalLanguage is restored at the end.
    [Test]
    procedure LT_BU_CaseConv_TurkishGreekLanguage()
    var
        Observer: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        ObserveCases(Observer, 'default');
        ClearLastError();
        if TrySetLanguage(1055) then
            ObserveCases(Observer, 'tr')
        else
            Observer.Observe('tr', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TrySetLanguage(1032) then
            ObserveCases(Observer, 'el')
        else
            Observer.Observe('el', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        GlobalLanguage(Saved);
        Observer.Expect('default language', '1033');
        Observer.Expect('default LowerCase I', 'i');
        Observer.Expect('default ToLower I', 'i');
        Observer.Expect('default UpperCase i', 'I');
        Observer.Expect('default ToUpper i', 'I');
        Observer.Expect('default LowerCase dotted I', 'i');
        Observer.Expect('default UpperCase dotless i', 'I');
        Observer.Expect('default LowerCase ΑΣ', 'ασ');
        Observer.Expect('default ToLower ΑΣ', 'ασ');
        Observer.Expect('default UpperCase ας', 'ΑΣ');
        Observer.Expect('default UpperCase ß', 'ß');
        Observer.Expect('default ToUpper ß', 'ß');
        Observer.Expect('tr language', '1055');
        Observer.Expect('tr LowerCase I', 'ı');
        Observer.Expect('tr ToLower I', 'i');
        Observer.Expect('tr UpperCase i', 'İ');
        Observer.Expect('tr ToUpper i', 'I');
        Observer.Expect('tr LowerCase dotted I', 'i');
        Observer.Expect('tr UpperCase dotless i', 'I');
        Observer.Expect('tr LowerCase ΑΣ', 'ασ');
        Observer.Expect('tr ToLower ΑΣ', 'ασ');
        Observer.Expect('tr UpperCase ας', 'ΑΣ');
        Observer.Expect('tr UpperCase ß', 'ß');
        Observer.Expect('tr ToUpper ß', 'ß');
        Observer.Expect('el language', '1032');
        Observer.Expect('el LowerCase I', 'i');
        Observer.Expect('el ToLower I', 'i');
        Observer.Expect('el UpperCase i', 'I');
        Observer.Expect('el ToUpper i', 'I');
        Observer.Expect('el LowerCase dotted I', 'i');
        Observer.Expect('el UpperCase dotless i', 'I');
        Observer.Expect('el LowerCase ΑΣ', 'ασ');
        Observer.Expect('el ToLower ΑΣ', 'ασ');
        Observer.Expect('el UpperCase ας', 'ΑΣ');
        Observer.Expect('el UpperCase ß', 'ß');
        Observer.Expect('el ToUpper ß', 'ß');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySetLanguage(Language: Integer)
    begin
        GlobalLanguage(Language);
    end;

    local procedure ObserveCases(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    begin
        Observer.Observe(Prefix + ' language', Format(GlobalLanguage()));
        Observer.Observe(Prefix + ' LowerCase I', LowerCase('I'));
        Observer.Observe(Prefix + ' ToLower I', TextToLower('I'));
        Observer.Observe(Prefix + ' UpperCase i', UpperCase('i'));
        Observer.Observe(Prefix + ' ToUpper i', TextToUpper('i'));
        Observer.Observe(Prefix + ' LowerCase dotted I', LowerCase('İ'));
        Observer.Observe(Prefix + ' UpperCase dotless i', UpperCase('ı'));
        Observer.Observe(Prefix + ' LowerCase ΑΣ', LowerCase('ΑΣ'));
        Observer.Observe(Prefix + ' ToLower ΑΣ', TextToLower('ΑΣ'));
        Observer.Observe(Prefix + ' UpperCase ας', UpperCase('ας'));
        Observer.Observe(Prefix + ' UpperCase ß', UpperCase('ß'));
        Observer.Observe(Prefix + ' ToUpper ß', TextToUpper('ß'));
    end;

    local procedure TextToLower(Value: Text): Text
    begin
        exit(Value.ToLower());
    end;

    local procedure TextToUpper(Value: Text): Text
    begin
        exit(Value.ToUpper());
    end;
    // Writer PY-C (al-runtime-rs PR 341, probes-needed "LowerCase and UpperCase in other languages"): Azerbaijani (1068), German (1031) and
    // Lithuanian (1063) with the same cases, and the upper-casing of a Code assignment, a Code parameter and a Code compare under Turkish (1055).
    [Test]
    procedure PYC_CaseConv_OtherLanguages()
    var
        Observer: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        ClearLastError();
        if TrySetLanguage(1068) then
            ObserveCases(Observer, 'az')
        else
            Observer.Observe('az', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TrySetLanguage(1031) then
            ObserveCases(Observer, 'de')
        else
            Observer.Observe('de', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TrySetLanguage(1063) then
            ObserveCases(Observer, 'lt')
        else
            Observer.Observe('lt', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        GlobalLanguage(Saved);
        Observer.Expect('az language', '1068');
        Observer.Expect('az LowerCase I', 'ı');
        Observer.Expect('az ToLower I', 'i');
        Observer.Expect('az UpperCase i', 'İ');
        Observer.Expect('az ToUpper i', 'I');
        Observer.Expect('az LowerCase dotted I', 'i');
        Observer.Expect('az UpperCase dotless i', 'I');
        Observer.Expect('az LowerCase ΑΣ', 'ασ');
        Observer.Expect('az ToLower ΑΣ', 'ασ');
        Observer.Expect('az UpperCase ας', 'ΑΣ');
        Observer.Expect('az UpperCase ß', 'ß');
        Observer.Expect('az ToUpper ß', 'ß');
        Observer.Expect('de language', '1031');
        Observer.Expect('de LowerCase I', 'i');
        Observer.Expect('de ToLower I', 'i');
        Observer.Expect('de UpperCase i', 'I');
        Observer.Expect('de ToUpper i', 'I');
        Observer.Expect('de LowerCase dotted I', 'i');
        Observer.Expect('de UpperCase dotless i', 'I');
        Observer.Expect('de LowerCase ΑΣ', 'ασ');
        Observer.Expect('de ToLower ΑΣ', 'ασ');
        Observer.Expect('de UpperCase ας', 'ΑΣ');
        Observer.Expect('de UpperCase ß', 'ß');
        Observer.Expect('de ToUpper ß', 'ß');
        Observer.Expect('lt language', '1063');
        Observer.Expect('lt LowerCase I', 'i');
        Observer.Expect('lt ToLower I', 'i');
        Observer.Expect('lt UpperCase i', 'I');
        Observer.Expect('lt ToUpper i', 'I');
        Observer.Expect('lt LowerCase dotted I', 'i');
        Observer.Expect('lt UpperCase dotless i', 'I');
        Observer.Expect('lt LowerCase ΑΣ', 'ασ');
        Observer.Expect('lt ToLower ΑΣ', 'ασ');
        Observer.Expect('lt UpperCase ας', 'ΑΣ');
        Observer.Expect('lt UpperCase ß', 'ß');
        Observer.Expect('lt ToUpper ß', 'ß');
        Observer.Verify();
    end;

    [Test]
    procedure PYC_CodeAssign_Turkish()
    var
        Observer: Codeunit "Probe Observer";
        Saved: Integer;
        C: Code[10];
        T: Text;
    begin
        Saved := GlobalLanguage();
        ClearLastError();
        if TrySetLanguage(1055) then begin
            Observer.Observe('language', Format(GlobalLanguage()));
            C := 'iı';
            Observer.Observe('code := i dotless-i', C);
            T := 'istanbul';
            C := T;
            Observer.Observe('code := text istanbul', C);
            Observer.Observe('code param', TakeCode('iz'));
            Observer.Observe('code = I literal', PYC_YesNo(C = 'ISTANBUL'));
            Observer.Observe('code = dotted literal', PYC_YesNo(C = 'İSTANBUL'));
            C := 'İ';
            Observer.Observe('code := dotted I', C);
            Observer.Observe('UpperCase i', UpperCase('i'));
        end else
            Observer.Observe('tr', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        GlobalLanguage(Saved);
        Observer.Expect('language', '1055');
        Observer.Expect('code := i dotless-i', 'İI');
        Observer.Expect('code := text istanbul', 'İSTANBUL');
        Observer.Expect('code param', 'İZ');
        Observer.Expect('code = I literal', 'No');
        Observer.Expect('code = dotted literal', 'Yes');
        Observer.Expect('code := dotted I', 'İ');
        Observer.Expect('UpperCase i', 'İ');
        Observer.Verify();
    end;

    // Format(Boolean) follows the session language (Turkish gives Evet/Hayir), so the compare results are written in English here.
    local procedure PYC_YesNo(Value: Boolean): Text
    begin
        if Value then
            exit('Yes');
        exit('No');
    end;

    local procedure TakeCode(Value: Code[10]): Text
    begin
        exit(Value);
    end;
}
