// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-code-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P145 Key (74900)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: comparison operators on Code variables, Code/Text mixes, StrCmp and Code fields holding digits, with the No. Series pair 109002 / 1010999
// BC versions: 29 (final facts are added after the measurement)

codeunit 74901 "LT P145 Code Compare"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Cmp(var Observer: Codeunit "Probe Observer"; Name: Text; A: Code[20]; B: Code[20])
    begin
        Observer.Observe(Name, 'gt=' + Format(A > B) + ' lt=' + Format(A < B) + ' eq=' + Format(A = B) + ' ne=' + Format(A <> B) + ' ge=' + Format(A >= B) + ' le=' + Format(A <= B));
    end;

    local procedure CmpTT(var Observer: Codeunit "Probe Observer"; Name: Text; A: Text; B: Text)
    begin
        Observer.Observe(Name, 'gt=' + Format(A > B) + ' lt=' + Format(A < B) + ' eq=' + Format(A = B) + ' ne=' + Format(A <> B));
    end;

    local procedure CmpTC(var Observer: Codeunit "Probe Observer"; Name: Text; A: Text; B: Code[20])
    begin
        Observer.Observe(Name, 'gt=' + Format(A > B) + ' lt=' + Format(A < B) + ' eq=' + Format(A = B) + ' ne=' + Format(A <> B));
    end;

    local procedure CmpCT(var Observer: Codeunit "Probe Observer"; Name: Text; A: Code[20]; B: Text)
    begin
        Observer.Observe(Name, 'gt=' + Format(A > B) + ' lt=' + Format(A < B) + ' eq=' + Format(A = B) + ' ne=' + Format(A <> B));
    end;

    [Test]
    procedure P145_CodeVars_NumberSeriesPair()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cmp(Observer, 'last-vs-ending', '109002', '1010999');
        Cmp(Observer, 'ending-vs-last', '1010999', '109002');
        Cmp(Observer, 'start-vs-last', '109001', '109002');
        Cmp(Observer, 'start-vs-ending', '109001', '1010999');
        Cmp(Observer, 'ending-vs-ending', '1010999', '1010999');
        Cmp(Observer, 'last-vs-start', '109002', '109001');
        Observer.Expect('last-vs-ending', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('ending-vs-last', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('start-vs-last', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('start-vs-ending', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('ending-vs-ending', 'gt=No lt=No eq=Yes ne=No ge=Yes le=Yes');
        Observer.Expect('last-vs-start', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Verify();
    end;

    [Test]
    procedure P145_CodeVars_DigitsOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cmp(Observer, '9-10', '9', '10');
        Cmp(Observer, '10-9', '10', '9');
        Cmp(Observer, '2-10', '2', '10');
        Cmp(Observer, '0010-10', '0010', '10');
        Cmp(Observer, '010-10', '010', '10');
        Cmp(Observer, '10-010', '10', '010');
        Cmp(Observer, '00-0', '00', '0');
        Cmp(Observer, '1-01', '1', '01');
        Cmp(Observer, '100-99', '100', '99');
        Cmp(Observer, '0-empty', '0', '');
        Cmp(Observer, 'empty-empty', '', '');
        Cmp(Observer, '9-0010', '9', '0010');
        Cmp(Observer, '0010-9', '0010', '9');
        Cmp(Observer, '0009-10', '0009', '10');
        Cmp(Observer, '20digits-9', '99999999999999999999', '9');
        Cmp(Observer, '20digits-20digits', '12345678901234567890', '12345678901234567891');
        Cmp(Observer, '1.5-10', '1.5', '10');
        Cmp(Observer, 'minus1-1', '-1', '1');
        Cmp(Observer, '1e3-999', '1E3', '999');
        Cmp(Observer, 'space9-10', ' 9', '10');
        Cmp(Observer, '9space-9', '9 ', '9');
        Observer.Expect('9-10', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('10-9', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('2-10', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('0010-10', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('010-10', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('10-010', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('00-0', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('1-01', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('100-99', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('0-empty', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('empty-empty', 'gt=No lt=No eq=Yes ne=No ge=Yes le=Yes');
        Observer.Expect('9-0010', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('0010-9', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('0009-10', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('20digits-9', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('20digits-20digits', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('1.5-10', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('minus1-1', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('1e3-999', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('space9-10', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('9space-9', 'gt=No lt=No eq=Yes ne=No ge=Yes le=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P145_CodeVars_WithLetters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cmp(Observer, 'A9-A10', 'A9', 'A10');
        Cmp(Observer, 'A10-A9', 'A10', 'A9');
        Cmp(Observer, 'A09-A9', 'A09', 'A9');
        Cmp(Observer, 'a9-A9', 'a9', 'A9');
        Cmp(Observer, '9A-10A', '9A', '10A');
        Cmp(Observer, 'A-9', 'A', '9');
        Cmp(Observer, 'A-a', 'A', 'a');
        Cmp(Observer, 'T-RCPT1-T-RCPT10', 'T-RCPT1', 'T-RCPT10');
        Cmp(Observer, 'T-RCPT9-T-RCPT10', 'T-RCPT9', 'T-RCPT10');
        Cmp(Observer, 'X0001-X1', 'X0001', 'X1');
        Cmp(Observer, 'X-X0', 'X', 'X0');
        Cmp(Observer, 'B-A99999', 'B', 'A99999');
        Observer.Expect('A9-A10', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('A10-A9', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('A09-A9', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('a9-A9', 'gt=No lt=No eq=Yes ne=No ge=Yes le=Yes');
        Observer.Expect('9A-10A', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('A-9', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('A-a', 'gt=No lt=No eq=Yes ne=No ge=Yes le=Yes');
        Observer.Expect('T-RCPT1-T-RCPT10', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('T-RCPT9-T-RCPT10', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('X0001-X1', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('X-X0', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('B-A99999', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Verify();
    end;

    [Test]
    procedure P145_TextVsText_DigitStrings()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CmpTT(Observer, '9-10', '9', '10');
        CmpTT(Observer, '109002-1010999', '109002', '1010999');
        CmpTT(Observer, '0010-10', '0010', '10');
        CmpTT(Observer, '010-10', '010', '10');
        CmpTT(Observer, 'A9-A10', 'A9', 'A10');
        CmpTT(Observer, 'a9-A9', 'a9', 'A9');
        CmpTT(Observer, '10-10space', '10', '10 ');
        CmpTT(Observer, '2-10', '2', '10');
        CmpTT(Observer, '00-0', '00', '0');
        Observer.Expect('9-10', 'gt=Yes lt=No eq=No ne=Yes');
        Observer.Expect('109002-1010999', 'gt=Yes lt=No eq=No ne=Yes');
        Observer.Expect('0010-10', 'gt=No lt=Yes eq=No ne=Yes');
        Observer.Expect('010-10', 'gt=No lt=Yes eq=No ne=Yes');
        Observer.Expect('A9-A10', 'gt=Yes lt=No eq=No ne=Yes');
        Observer.Expect('a9-A9', 'gt=No lt=Yes eq=No ne=Yes');
        Observer.Expect('10-10space', 'gt=No lt=Yes eq=No ne=Yes');
        Observer.Expect('2-10', 'gt=Yes lt=No eq=No ne=Yes');
        Observer.Expect('00-0', 'gt=Yes lt=No eq=No ne=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P145_TextVsCode_Mixed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CmpTC(Observer, 'text9-code10', '9', '10');
        CmpTC(Observer, 'text109002-code1010999', '109002', '1010999');
        CmpTC(Observer, 'text0010-code10', '0010', '10');
        CmpTC(Observer, 'text010-code10', '010', '10');
        CmpTC(Observer, 'textA9-codeA10', 'A9', 'A10');
        CmpTC(Observer, 'texta9-codeA9', 'a9', 'A9');
        CmpTC(Observer, 'text10space-code10', '10 ', '10');
        CmpCT(Observer, 'code9-text10', '9', '10');
        CmpCT(Observer, 'code109002-text1010999', '109002', '1010999');
        CmpCT(Observer, 'code0010-text10', '0010', '10');
        CmpCT(Observer, 'code010-text10', '010', '10');
        CmpCT(Observer, 'codeA9-textA10', 'A9', 'A10');
        CmpCT(Observer, 'codeA9-texta9', 'A9', 'a9');
        CmpCT(Observer, 'code10-text10space', '10', '10 ');
        Observer.Expect('text9-code10', 'gt=Yes lt=No eq=No ne=Yes');
        Observer.Expect('text109002-code1010999', 'gt=Yes lt=No eq=No ne=Yes');
        Observer.Expect('text0010-code10', 'gt=No lt=Yes eq=No ne=Yes');
        Observer.Expect('text010-code10', 'gt=No lt=Yes eq=No ne=Yes');
        Observer.Expect('textA9-codeA10', 'gt=Yes lt=No eq=No ne=Yes');
        Observer.Expect('texta9-codeA9', 'gt=No lt=Yes eq=No ne=Yes');
        Observer.Expect('text10space-code10', 'gt=Yes lt=No eq=No ne=Yes');
        Observer.Expect('code9-text10', 'gt=Yes lt=No eq=No ne=Yes');
        Observer.Expect('code109002-text1010999', 'gt=Yes lt=No eq=No ne=Yes');
        Observer.Expect('code0010-text10', 'gt=No lt=Yes eq=No ne=Yes');
        Observer.Expect('code010-text10', 'gt=No lt=Yes eq=No ne=Yes');
        Observer.Expect('codeA9-textA10', 'gt=Yes lt=No eq=No ne=Yes');
        Observer.Expect('codeA9-texta9', 'gt=Yes lt=No eq=No ne=Yes');
        Observer.Expect('code10-text10space', 'gt=No lt=Yes eq=No ne=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P145_CodeFields_Compared()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P145 Key";
        Other: Record "LT P145 Key";
        Var1: Code[20];
        Var2: Text[20];
    begin
        Rec."Code" := '109002';
        Rec.Alt := '1010999';
        Observer.Observe('field-pair-gt', Format(Rec."Code" > Rec.Alt));
        Observer.Observe('field-pair-lt', Format(Rec."Code" < Rec.Alt));
        Rec."Code" := '0010';
        Rec.Alt := '10';
        Observer.Observe('field-0010-10-eq', Format(Rec."Code" = Rec.Alt));
        Observer.Observe('field-0010-10-lt', Format(Rec."Code" < Rec.Alt));
        Observer.Observe('field-0010-10-gt', Format(Rec."Code" > Rec.Alt));
        Rec."Code" := '9';
        Rec.Alt := '10';
        Observer.Observe('field-9-10-lt', Format(Rec."Code" < Rec.Alt));
        Observer.Observe('field-9-10-gt', Format(Rec."Code" > Rec.Alt));
        Rec."Code" := 'A9';
        Rec.Alt := 'A10';
        Observer.Observe('field-A9-A10-lt', Format(Rec."Code" < Rec.Alt));
        Observer.Observe('field-A9-A10-gt', Format(Rec."Code" > Rec.Alt));
        Var1 := '10';
        Rec."Code" := '0010';
        Observer.Observe('field-vs-var-eq', Format(Rec."Code" = Var1));
        Observer.Observe('field-vs-var-lt', Format(Rec."Code" < Var1));
        Rec."Code" := '9';
        Observer.Observe('field9-var10-lt', Format(Rec."Code" < Var1));
        Rec.Txt := '9';
        Rec."Code" := '10';
        Observer.Observe('textfield9-codefield10-lt', Format(Rec.Txt < Rec."Code"));
        Observer.Observe('textfield9-codefield10-gt', Format(Rec.Txt > Rec."Code"));
        Rec.Txt := '0010';
        Observer.Observe('textfield0010-codefield10-eq', Format(Rec.Txt = Rec."Code"));
        Rec.Txt := '109002';
        Rec.Alt := '1010999';
        Observer.Observe('textfield-pair-gt', Format(Rec.Txt > Rec.Alt));
        Rec."Code" := '109002';
        Other."Code" := '1010999';
        Observer.Observe('two-recs-pair-gt', Format(Rec."Code" > Other."Code"));
        Var2 := '9';
        Rec."Code" := '10';
        Observer.Observe('codefield10-textvar9-gt', Format(Rec."Code" > Var2));
        Observer.Expect('field-pair-gt', 'No');
        Observer.Expect('field-pair-lt', 'Yes');
        Observer.Expect('field-0010-10-eq', 'No');
        Observer.Expect('field-0010-10-lt', 'No');
        Observer.Expect('field-0010-10-gt', 'Yes');
        Observer.Expect('field-9-10-lt', 'Yes');
        Observer.Expect('field-9-10-gt', 'No');
        Observer.Expect('field-A9-A10-lt', 'No');
        Observer.Expect('field-A9-A10-gt', 'Yes');
        Observer.Expect('field-vs-var-eq', 'No');
        Observer.Expect('field-vs-var-lt', 'No');
        Observer.Expect('field9-var10-lt', 'Yes');
        Observer.Expect('textfield9-codefield10-lt', 'No');
        Observer.Expect('textfield9-codefield10-gt', 'Yes');
        Observer.Expect('textfield0010-codefield10-eq', 'No');
        Observer.Expect('textfield-pair-gt', 'Yes');
        Observer.Expect('two-recs-pair-gt', 'No');
        Observer.Expect('codefield10-textvar9-gt', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P145_Lengths_CodeVariablesOfDifferentSize()
    var
        Observer: Codeunit "Probe Observer";
        C10: Code[10];
        C20: Code[20];
        C2: Code[2];
    begin
        C10 := '9';
        C20 := '10';
        Observer.Observe('c10-9-vs-c20-10-lt', Format(C10 < C20));
        C10 := '109002';
        C20 := '1010999';
        Observer.Observe('c10-pair-gt', Format(C10 > C20));
        C10 := '0010';
        C20 := '10';
        Observer.Observe('c10-0010-vs-c20-10-eq', Format(C10 = C20));
        C2 := '10';
        C20 := '0010';
        Observer.Observe('c2-10-vs-c20-0010-eq', Format(C2 = C20));
        Observer.Observe('c2-10-vs-c20-0010-lt', Format(C2 < C20));
        Observer.Observe('format-c20-0010', Format(C20));
        Observer.Observe('len-c20-0010', Format(StrLen(C20)));
        Observer.Observe('copystr-c20-0010', CopyStr(C20, 2));
        Observer.Expect('c10-9-vs-c20-10-lt', 'Yes');
        Observer.Expect('c10-pair-gt', 'No');
        Observer.Expect('c10-0010-vs-c20-10-eq', 'No');
        Observer.Expect('c2-10-vs-c20-0010-eq', 'No');
        Observer.Expect('c2-10-vs-c20-0010-lt', 'Yes');
        Observer.Expect('format-c20-0010', '0010');
        Observer.Expect('len-c20-0010', '4');
        Observer.Expect('copystr-c20-0010', '010');
        Observer.Verify();
    end;
}
