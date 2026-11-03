// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Format(Decimal, 0, '<Precision,2:2><Standard Format,N>') for N = 0 to 9 (N = 0 and 9 are the asked ones) on 1, -1.5 and 1234567.891, session language de-DE (1031, set explicitly).
// 0 is pinned in LT P175 Prec Std En/De (types/lt-format-precision-standard). The language is restored on all paths.
// BC versions: 29 (27 and 28 by CI)

codeunit 71703 "LT Fmt Prec Std De"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFmt(Value: Decimal; Spec: Text; var Result: Text)
    begin
        Result := Format(Value, 0, Spec);
    end;

    local procedure Fmt(Value: Decimal; Spec: Text): Text
    var
        Result: Text;
    begin
        if TryFmt(Value, Spec, Result) then
            exit('[' + Result + ']');
        exit('err|' + CopyStr(GetLastErrorText(), 1, 150) + '|' + GetLastErrorCode());
    end;

    local procedure ObserveStd(var Observer: Codeunit "Probe Observer"; Value: Decimal)
    var
        N: Integer;
    begin
        for N := 0 to 9 do
            Observer.Observe('prec22 std' + Format(N), Fmt(Value, '<Precision,2:2><Standard Format,' + Format(N) + '>'));
    end;

    [Test]
    procedure PrecStd_One()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        ObserveStd(Observer, 1);
        GlobalLanguage(Orig);
        Observer.Expect('prec22 std0', '[1.00]');
        Observer.Expect('prec22 std1', '[1.00]');
        Observer.Expect('prec22 std2', '[1.00]');
        Observer.Expect('prec22 std3', '[1.00 ]');
        Observer.Expect('prec22 std4', '[1.00 ]');
        Observer.Expect('prec22 std5', 'err|Die Standardformatnummer 5 ist für den Typ ''Decimal'' nicht vorhanden.|InvalidStandardFormat');
        Observer.Expect('prec22 std6', 'err|Die Standardformatnummer 6 ist für den Typ ''Decimal'' nicht vorhanden.|InvalidStandardFormat');
        Observer.Expect('prec22 std7', 'err|Die Standardformatnummer 7 ist für den Typ ''Decimal'' nicht vorhanden.|InvalidStandardFormat');
        Observer.Expect('prec22 std8', 'err|Die Standardformatnummer 8 ist für den Typ ''Decimal'' nicht vorhanden.|InvalidStandardFormat');
        Observer.Expect('prec22 std9', '[1.00]');
        Observer.Verify();
    end;

    [Test]
    procedure PrecStd_MinusOneAndHalf()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        ObserveStd(Observer, -1.5);
        GlobalLanguage(Orig);
        Observer.Expect('prec22 std0', '[-1.50]');
        Observer.Expect('prec22 std1', '[-1.50]');
        Observer.Expect('prec22 std2', '[-1.50]');
        Observer.Expect('prec22 std3', '[1.50-]');
        Observer.Expect('prec22 std4', '[1.50-]');
        Observer.Expect('prec22 std5', 'err|Die Standardformatnummer 5 ist für den Typ ''Decimal'' nicht vorhanden.|InvalidStandardFormat');
        Observer.Expect('prec22 std6', 'err|Die Standardformatnummer 6 ist für den Typ ''Decimal'' nicht vorhanden.|InvalidStandardFormat');
        Observer.Expect('prec22 std7', 'err|Die Standardformatnummer 7 ist für den Typ ''Decimal'' nicht vorhanden.|InvalidStandardFormat');
        Observer.Expect('prec22 std8', 'err|Die Standardformatnummer 8 ist für den Typ ''Decimal'' nicht vorhanden.|InvalidStandardFormat');
        Observer.Expect('prec22 std9', '[-1.50]');
        Observer.Verify();
    end;

    [Test]
    procedure PrecStd_Millions()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        ObserveStd(Observer, 1234567.891);
        GlobalLanguage(Orig);
        Observer.Expect('prec22 std0', '[1,234,567.89]');
        Observer.Expect('prec22 std1', '[1234567.89]');
        Observer.Expect('prec22 std2', '[1234567.89]');
        Observer.Expect('prec22 std3', '[1,234,567.89 ]');
        Observer.Expect('prec22 std4', '[1234567.89 ]');
        Observer.Expect('prec22 std5', 'err|Die Standardformatnummer 5 ist für den Typ ''Decimal'' nicht vorhanden.|InvalidStandardFormat');
        Observer.Expect('prec22 std6', 'err|Die Standardformatnummer 6 ist für den Typ ''Decimal'' nicht vorhanden.|InvalidStandardFormat');
        Observer.Expect('prec22 std7', 'err|Die Standardformatnummer 7 ist für den Typ ''Decimal'' nicht vorhanden.|InvalidStandardFormat');
        Observer.Expect('prec22 std8', 'err|Die Standardformatnummer 8 ist für den Typ ''Decimal'' nicht vorhanden.|InvalidStandardFormat');
        Observer.Expect('prec22 std9', '[1234567.89]');
        Observer.Verify();
    end;

    [Test]
    procedure PrecStd9And0_OtherPrecisionForms()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        Observer.Observe('p0:0 s9 1234567.891', Fmt(1234567.891, '<Precision,0:0><Standard Format,9>'));
        Observer.Observe('p0:0 s0 1234567.891', Fmt(1234567.891, '<Precision,0:0><Standard Format,0>'));
        Observer.Observe('p2:2 s9 0', Fmt(0, '<Precision,2:2><Standard Format,9>'));
        Observer.Observe('p2:2 s0 0', Fmt(0, '<Precision,2:2><Standard Format,0>'));
        Observer.Observe('std9 then prec 1', Fmt(-1.5, '<Standard Format,9><Precision,2:2>'));
        Observer.Observe('std0 then prec 1', Fmt(-1.5, '<Standard Format,0><Precision,2:2>'));
        Observer.Observe('p3:3 s9 1', Fmt(1, '<Precision,3:3><Standard Format,9>'));
        Observer.Observe('p3:3 s0 1', Fmt(1, '<Precision,3:3><Standard Format,0>'));
        GlobalLanguage(Orig);
        Observer.Expect('p0:0 s9 1234567.891', '[1234568]');
        Observer.Expect('p0:0 s0 1234567.891', '[1,234,568]');
        Observer.Expect('p2:2 s9 0', '[0.00]');
        Observer.Expect('p2:2 s0 0', '[0.00]');
        Observer.Expect('std9 then prec 1', '[-1.5]');
        Observer.Expect('std0 then prec 1', '[-1.5]');
        Observer.Expect('p3:3 s9 1', '[1.000]');
        Observer.Expect('p3:3 s0 1', '[1.000]');
        Observer.Verify();
    end;
}
