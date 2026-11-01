// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-joker-method
// Scope: in-scope. Format(DateFormula, 0, N) for the standard formats 1 and 2 (and 3 to 8), under the global languages 1033, 1030 and 1031;
//   Evaluate of the text format 1 printed under 1030.
// Fixtures used: Probe Observer (69160); self-contained codeunit 93262
// Probe: gap cycle 6, spec G6-21 (writer Y62). Every literal asserted below is what BC produced (corpus CI 27.5, 28.5, 29.0; SaaS sandbox BC 29).
// Facts: each value is the formatted text in square brackets, or error:<text>|<code>. Every test sets GlobalLanguage back to 1033 before it
//   records anything.
// Results (same on 27.5, 28.5, 29.0 and the SaaS sandbox): format 1 prints the formula without brackets in the letters of the global language
//   (1030: -1U, -1Å, LM+1D; 1031: -1J, LM+1T), like format 0; format 2 prints the English letters in angle brackets (empty formula: <>), format 9
//   the English letters without brackets; formats 3 to 8 raise InvalidStandardFormat ('... for the type 'Duration''). The Danish text of format 1
//   evaluates back under 1030 only.
// BC versions: 27, 28, 29

codeunit 93262 "LT Y62 DateFormula Format"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFormat(F: DateFormula; Std: Integer; var Txt: Text)
    begin
        Txt := Format(F, 0, Std);
    end;

    local procedure Show(F: DateFormula; Std: Integer): Text
    var
        Txt: Text;
    begin
        ClearLastError();
        if TryFormat(F, Std, Txt) then
            exit('[' + Txt + ']');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Formula(Txt: Text) F: DateFormula
    begin
        if Txt <> '' then
            Evaluate(F, Txt);
    end;

    local procedure AllFormulas() Texts: List of [Text]
    begin
        Texts.Add('<-1W>');
        Texts.Add('<-1M>');
        Texts.Add('<-3M>');
        Texts.Add('<-6M>');
        Texts.Add('<-1Y>');
        Texts.Add('<-5Y>');
        Texts.Add('<CM+1D>');
        Texts.Add('<+CY-24M>');
        Texts.Add('<1D>');
        Texts.Add('1M+CM');
        Texts.Add('<-1W+1D>');
        Texts.Add('<WD1>');
        Texts.Add('<-1Q>');
        Texts.Add('<CW>');
        Texts.Add('');
    end;

    local procedure RetentionFormulas() Texts: List of [Text]
    begin
        Texts.Add('<-1W>');
        Texts.Add('<-1M>');
        Texts.Add('<-3M>');
        Texts.Add('<-6M>');
        Texts.Add('<-1Y>');
        Texts.Add('<-5Y>');
        Texts.Add('<CM+1D>');
        Texts.Add('<+CY-24M>');
        Texts.Add('');
    end;

    [Test]
    procedure DateFormulaFormat_Std1_English()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
        T: Text;
    begin
        GlobalLanguage(1033);
        Texts := AllFormulas();
        foreach T in Texts do
            Observer.Observe('1:' + T, Show(Formula(T), 1));
        Observer.Expect('1:<-1W>', '[-1W]');
        Observer.Expect('1:<-1M>', '[-1M]');
        Observer.Expect('1:<-3M>', '[-3M]');
        Observer.Expect('1:<-6M>', '[-6M]');
        Observer.Expect('1:<-1Y>', '[-1Y]');
        Observer.Expect('1:<-5Y>', '[-5Y]');
        Observer.Expect('1:<CM+1D>', '[CM+1D]');
        Observer.Expect('1:<+CY-24M>', '[+CY-24M]');
        Observer.Expect('1:<1D>', '[1D]');
        Observer.Expect('1:1M+CM', '[1M+CM]');
        Observer.Expect('1:<-1W+1D>', '[-1W+1D]');
        Observer.Expect('1:<WD1>', '[WD1]');
        Observer.Expect('1:<-1Q>', '[-1Q]');
        Observer.Expect('1:<CW>', '[CW]');
        Observer.Expect('1:', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure DateFormulaFormat_Std2_English()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
        T: Text;
    begin
        GlobalLanguage(1033);
        Texts := AllFormulas();
        foreach T in Texts do
            Observer.Observe('2:' + T, Show(Formula(T), 2));
        Observer.Expect('2:<-1W>', '[<-1W>]');
        Observer.Expect('2:<-1M>', '[<-1M>]');
        Observer.Expect('2:<-3M>', '[<-3M>]');
        Observer.Expect('2:<-6M>', '[<-6M>]');
        Observer.Expect('2:<-1Y>', '[<-1Y>]');
        Observer.Expect('2:<-5Y>', '[<-5Y>]');
        Observer.Expect('2:<CM+1D>', '[<CM+1D>]');
        Observer.Expect('2:<+CY-24M>', '[<+CY-24M>]');
        Observer.Expect('2:<1D>', '[<1D>]');
        Observer.Expect('2:1M+CM', '[<1M+CM>]');
        Observer.Expect('2:<-1W+1D>', '[<-1W+1D>]');
        Observer.Expect('2:<WD1>', '[<WD1>]');
        Observer.Expect('2:<-1Q>', '[<-1Q>]');
        Observer.Expect('2:<CW>', '[<CW>]');
        Observer.Expect('2:', '[<>]');
        Observer.Verify();
    end;

    [Test]
    procedure DateFormulaFormat_Std0And9_English()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
        T: Text;
    begin
        GlobalLanguage(1033);
        Texts := RetentionFormulas();
        foreach T in Texts do
            Observer.Observe('0/9:' + T, Show(Formula(T), 0) + Show(Formula(T), 9));
        Observer.Expect('0/9:<-1W>', '[-1W][-1W]');
        Observer.Expect('0/9:<-1M>', '[-1M][-1M]');
        Observer.Expect('0/9:<-3M>', '[-3M][-3M]');
        Observer.Expect('0/9:<-6M>', '[-6M][-6M]');
        Observer.Expect('0/9:<-1Y>', '[-1Y][-1Y]');
        Observer.Expect('0/9:<-5Y>', '[-5Y][-5Y]');
        Observer.Expect('0/9:<CM+1D>', '[CM+1D][CM+1D]');
        Observer.Expect('0/9:<+CY-24M>', '[+CY-24M][+CY-24M]');
        Observer.Expect('0/9:', '[][]');
        Observer.Verify();
    end;

    [Test]
    procedure DateFormulaFormat_Std1And2_Danish()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
        Results: List of [Text];
        T: Text;
        Lang: Integer;
        i: Integer;
    begin
        Texts := RetentionFormulas();
        GlobalLanguage(1030);
        Lang := GlobalLanguage();
        foreach T in Texts do
            Results.Add(Show(Formula(T), 1) + Show(Formula(T), 2) + Show(Formula(T), 0) + Show(Formula(T), 9));
        GlobalLanguage(1033);
        Observer.Observe('language', Format(Lang));
        for i := 1 to Texts.Count() do
            Observer.Observe('1/2/0/9:' + Texts.Get(i), Results.Get(i));
        Observer.Expect('language', '1030');
        Observer.Expect('1/2/0/9:<-1W>', '[-1U][<-1W>][-1U][-1W]');
        Observer.Expect('1/2/0/9:<-1M>', '[-1M][<-1M>][-1M][-1M]');
        Observer.Expect('1/2/0/9:<-3M>', '[-3M][<-3M>][-3M][-3M]');
        Observer.Expect('1/2/0/9:<-6M>', '[-6M][<-6M>][-6M][-6M]');
        Observer.Expect('1/2/0/9:<-1Y>', '[-1Å][<-1Y>][-1Å][-1Y]');
        Observer.Expect('1/2/0/9:<-5Y>', '[-5Å][<-5Y>][-5Å][-5Y]');
        Observer.Expect('1/2/0/9:<CM+1D>', '[LM+1D][<CM+1D>][LM+1D][CM+1D]');
        Observer.Expect('1/2/0/9:<+CY-24M>', '[+LÅ-24M][<+CY-24M>][+LÅ-24M][+CY-24M]');
        Observer.Expect('1/2/0/9:', '[][<>][][]');
        Observer.Verify();
    end;

    [Test]
    procedure DateFormulaFormat_OtherStandards_English()
    var
        Observer: Codeunit "Probe Observer";
        Std: Integer;
    begin
        GlobalLanguage(1033);
        for Std := 3 to 8 do begin
            Observer.Observe(Format(Std) + ':<-1W>', Show(Formula('<-1W>'), Std));
            Observer.Observe(Format(Std) + ':<CM+1D>', Show(Formula('<CM+1D>'), Std));
        end;
        Observer.Expect('3:<-1W>', 'error:Standard format number 3 does not exist for the type ''Duration''.|InvalidStandardFormat');
        Observer.Expect('3:<CM+1D>', 'error:Standard format number 3 does not exist for the type ''Duration''.|InvalidStandardFormat');
        Observer.Expect('4:<-1W>', 'error:Standard format number 4 does not exist for the type ''Duration''.|InvalidStandardFormat');
        Observer.Expect('4:<CM+1D>', 'error:Standard format number 4 does not exist for the type ''Duration''.|InvalidStandardFormat');
        Observer.Expect('5:<-1W>', 'error:Standard format number 5 does not exist for the type ''Duration''.|InvalidStandardFormat');
        Observer.Expect('5:<CM+1D>', 'error:Standard format number 5 does not exist for the type ''Duration''.|InvalidStandardFormat');
        Observer.Expect('6:<-1W>', 'error:Standard format number 6 does not exist for the type ''Duration''.|InvalidStandardFormat');
        Observer.Expect('6:<CM+1D>', 'error:Standard format number 6 does not exist for the type ''Duration''.|InvalidStandardFormat');
        Observer.Expect('7:<-1W>', 'error:Standard format number 7 does not exist for the type ''Duration''.|InvalidStandardFormat');
        Observer.Expect('7:<CM+1D>', 'error:Standard format number 7 does not exist for the type ''Duration''.|InvalidStandardFormat');
        Observer.Expect('8:<-1W>', 'error:Standard format number 8 does not exist for the type ''Duration''.|InvalidStandardFormat');
        Observer.Expect('8:<CM+1D>', 'error:Standard format number 8 does not exist for the type ''Duration''.|InvalidStandardFormat');
        Observer.Verify();
    end;

    [Test]
    procedure DateFormulaFormat_Std1_German()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
        Results: List of [Text];
        T: Text;
        i: Integer;
    begin
        Texts.Add('<-1W>');
        Texts.Add('<-1M>');
        Texts.Add('<-1Y>');
        Texts.Add('<CM+1D>');
        GlobalLanguage(1031);
        foreach T in Texts do
            Results.Add(Show(Formula(T), 1) + Show(Formula(T), 2));
        GlobalLanguage(1033);
        for i := 1 to Texts.Count() do
            Observer.Observe('1/2:' + Texts.Get(i), Results.Get(i));
        Observer.Expect('1/2:<-1W>', '[-1W][<-1W>]');
        Observer.Expect('1/2:<-1M>', '[-1M][<-1M>]');
        Observer.Expect('1/2:<-1Y>', '[-1J][<-1Y>]');
        Observer.Expect('1/2:<CM+1D>', '[LM+1T][<CM+1D>]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryEvaluate(Txt: Text; var G: DateFormula; var Ok: Boolean)
    begin
        Ok := Evaluate(G, Txt);
    end;

    local procedure EvalText(Txt: Text): Text
    var
        G: DateFormula;
        Ok: Boolean;
    begin
        ClearLastError();
        if TryEvaluate(Txt, G, Ok) then
            exit(Format(Ok) + '|' + Format(G, 0, 9));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure DateFormulaFormat_Std1_Danish_EvaluateBack()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
        Printed: List of [Text];
        Danish: List of [Text];
        English: List of [Text];
        T: Text;
        P: Text;
        i: Integer;
    begin
        Texts.Add('<-1W>');
        Texts.Add('<-1M>');
        Texts.Add('<-1Y>');
        Texts.Add('<CM+1D>');
        GlobalLanguage(1030);
        foreach T in Texts do
            if TryFormat(Formula(T), 1, P) then
                Printed.Add(P)
            else
                Printed.Add('format error');
        for i := 1 to Texts.Count() do
            Danish.Add(EvalText(Printed.Get(i)));
        GlobalLanguage(1033);
        for i := 1 to Texts.Count() do
            English.Add(EvalText(Printed.Get(i)));
        for i := 1 to Texts.Count() do
            Observer.Observe(Texts.Get(i), '[' + Printed.Get(i) + '] da:' + Danish.Get(i) + ' en:' + English.Get(i));
        Observer.Expect('<-1W>', '[-1U] da:Ja|-1W en:No|');
        Observer.Expect('<-1M>', '[-1M] da:Ja|-1M en:Yes|-1M');
        Observer.Expect('<-1Y>', '[-1Å] da:Ja|-1Y en:No|');
        Observer.Expect('<CM+1D>', '[LM+1D] da:Ja|CM+1D en:No|');
        Observer.Verify();
    end;
}
