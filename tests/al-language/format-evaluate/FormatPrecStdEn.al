// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Format(Decimal, 0, '<Precision,2:2><Standard Format,N>') for N = 0 to 9 on 1234.5, -0.5, 0, 0.0000001 and 123456789.123456 (session language en-US (set explicitly to 1033)), and
// <Standard Format,9> under other Precision codes. The session language is restored on all paths.
// BC versions: 29 (27 and 28 by CI)

codeunit 71576 "LT P175 Prec Std En"
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
    procedure P175_PrecStd_Pos()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        ObserveStd(Observer, 1234.5);
        GlobalLanguage(Orig);
        Observer.Expect('prec22 std0', '[1,234.50]');
        Observer.Expect('prec22 std1', '[1234.50]');
        Observer.Expect('prec22 std2', '[1234.50]');
        Observer.Expect('prec22 std3', '[1,234.50 ]');
        Observer.Expect('prec22 std4', '[1234.50 ]');
        Observer.Expect('prec22 std5', 'err|Standard format number 5 does not exist for the type ''Decimal''.|InvalidStandardFormat');
        Observer.Expect('prec22 std6', 'err|Standard format number 6 does not exist for the type ''Decimal''.|InvalidStandardFormat');
        Observer.Expect('prec22 std7', 'err|Standard format number 7 does not exist for the type ''Decimal''.|InvalidStandardFormat');
        Observer.Expect('prec22 std8', 'err|Standard format number 8 does not exist for the type ''Decimal''.|InvalidStandardFormat');
        Observer.Expect('prec22 std9', '[1234.50]');
        Observer.Verify();
    end;

    [Test]
    procedure P175_PrecStd_Neg()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        ObserveStd(Observer, -0.5);
        GlobalLanguage(Orig);
        Observer.Expect('prec22 std0', '[-0.50]');
        Observer.Expect('prec22 std1', '[-0.50]');
        Observer.Expect('prec22 std2', '[-0.50]');
        Observer.Expect('prec22 std3', '[0.50-]');
        Observer.Expect('prec22 std4', '[0.50-]');
        Observer.Expect('prec22 std5', 'err|Standard format number 5 does not exist for the type ''Decimal''.|InvalidStandardFormat');
        Observer.Expect('prec22 std6', 'err|Standard format number 6 does not exist for the type ''Decimal''.|InvalidStandardFormat');
        Observer.Expect('prec22 std7', 'err|Standard format number 7 does not exist for the type ''Decimal''.|InvalidStandardFormat');
        Observer.Expect('prec22 std8', 'err|Standard format number 8 does not exist for the type ''Decimal''.|InvalidStandardFormat');
        Observer.Expect('prec22 std9', '[-0.50]');
        Observer.Verify();
    end;

    [Test]
    procedure P175_PrecStd_Zero()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        ObserveStd(Observer, 0);
        GlobalLanguage(Orig);
        Observer.Expect('prec22 std0', '[0.00]');
        Observer.Expect('prec22 std1', '[0.00]');
        Observer.Expect('prec22 std2', '[0.00]');
        Observer.Expect('prec22 std3', '[0.00 ]');
        Observer.Expect('prec22 std4', '[0.00 ]');
        Observer.Expect('prec22 std5', 'err|Standard format number 5 does not exist for the type ''Decimal''.|InvalidStandardFormat');
        Observer.Expect('prec22 std6', 'err|Standard format number 6 does not exist for the type ''Decimal''.|InvalidStandardFormat');
        Observer.Expect('prec22 std7', 'err|Standard format number 7 does not exist for the type ''Decimal''.|InvalidStandardFormat');
        Observer.Expect('prec22 std8', 'err|Standard format number 8 does not exist for the type ''Decimal''.|InvalidStandardFormat');
        Observer.Expect('prec22 std9', '[0.00]');
        Observer.Verify();
    end;

    [Test]
    procedure P175_PrecStd_Tiny()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        ObserveStd(Observer, 0.0000001);
        GlobalLanguage(Orig);
        Observer.Expect('prec22 std0', '[0.00]');
        Observer.Expect('prec22 std1', '[0.00]');
        Observer.Expect('prec22 std2', '[0.00]');
        Observer.Expect('prec22 std3', '[0.00 ]');
        Observer.Expect('prec22 std4', '[0.00 ]');
        Observer.Expect('prec22 std5', 'err|Standard format number 5 does not exist for the type ''Decimal''.|InvalidStandardFormat');
        Observer.Expect('prec22 std6', 'err|Standard format number 6 does not exist for the type ''Decimal''.|InvalidStandardFormat');
        Observer.Expect('prec22 std7', 'err|Standard format number 7 does not exist for the type ''Decimal''.|InvalidStandardFormat');
        Observer.Expect('prec22 std8', 'err|Standard format number 8 does not exist for the type ''Decimal''.|InvalidStandardFormat');
        Observer.Expect('prec22 std9', '[0.00]');
        Observer.Verify();
    end;

    [Test]
    procedure P175_PrecStd_Big()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        ObserveStd(Observer, 123456789.123456);
        GlobalLanguage(Orig);
        Observer.Expect('prec22 std0', '[123,456,789.12]');
        Observer.Expect('prec22 std1', '[123456789.12]');
        Observer.Expect('prec22 std2', '[123456789.12]');
        Observer.Expect('prec22 std3', '[123,456,789.12 ]');
        Observer.Expect('prec22 std4', '[123456789.12 ]');
        Observer.Expect('prec22 std5', 'err|Standard format number 5 does not exist for the type ''Decimal''.|InvalidStandardFormat');
        Observer.Expect('prec22 std6', 'err|Standard format number 6 does not exist for the type ''Decimal''.|InvalidStandardFormat');
        Observer.Expect('prec22 std7', 'err|Standard format number 7 does not exist for the type ''Decimal''.|InvalidStandardFormat');
        Observer.Expect('prec22 std8', 'err|Standard format number 8 does not exist for the type ''Decimal''.|InvalidStandardFormat');
        Observer.Expect('prec22 std9', '[123456789.12]');
        Observer.Verify();
    end;

    [Test]
    procedure P175_PrecStd9_OtherPrecisions()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        Observer.Observe('1234.5 0:0', Fmt(1234.5, '<Precision,0:0><Standard Format,9>'));
        Observer.Observe('1234.5 2:5', Fmt(1234.5, '<Precision,2:5><Standard Format,9>'));
        Observer.Observe('1234.5 3', Fmt(1234.5, '<Precision,3><Standard Format,9>'));
        Observer.Observe('1234.5 0:3', Fmt(1234.5, '<Precision,0:3><Standard Format,9>'));
        Observer.Observe('1234.5 2:2 rev', Fmt(1234.5, '<Standard Format,9><Precision,2:2>'));
        Observer.Observe('0.0000001 2:2', Fmt(0.0000001, '<Precision,2:2><Standard Format,9>'));
        Observer.Observe('0.0000001 7:7', Fmt(0.0000001, '<Precision,7:7><Standard Format,9>'));
        Observer.Observe('-0.5 0:0', Fmt(-0.5, '<Precision,0:0><Standard Format,9>'));
        Observer.Observe('-0.5 1:1', Fmt(-0.5, '<Precision,1:1><Standard Format,9>'));
        Observer.Observe('0 3:3', Fmt(0, '<Precision,3:3><Standard Format,9>'));
        Observer.Observe('big 6:6', Fmt(123456789.123456, '<Precision,6:6><Standard Format,9>'));
        Observer.Observe('big 1:1', Fmt(123456789.123456, '<Precision,1:1><Standard Format,9>'));
        Observer.Observe('plain 1234.5 std9', Fmt(1234.5, '<Standard Format,9>'));
        Observer.Observe('format arg 9', Format(1234.5, 0, 9));
        Observer.Observe('format arg 9 big', Format(123456789.123456, 0, 9));
        GlobalLanguage(Orig);
        Observer.Expect('1234.5 0:0', '[1235]');
        Observer.Expect('1234.5 2:5', '[1234.50]');
        Observer.Expect('1234.5 3', '[1234.500]');
        Observer.Expect('1234.5 0:3', '[1234.5]');
        Observer.Expect('1234.5 2:2 rev', '[1234.5]');
        Observer.Expect('0.0000001 2:2', '[0.00]');
        Observer.Expect('0.0000001 7:7', '[0.0000001]');
        Observer.Expect('-0.5 0:0', '[-1]');
        Observer.Expect('-0.5 1:1', '[-0.5]');
        Observer.Expect('0 3:3', '[0.000]');
        Observer.Expect('big 6:6', '[123456789.123456]');
        Observer.Expect('big 1:1', '[123456789.1]');
        Observer.Expect('plain 1234.5 std9', '[1234.5]');
        Observer.Expect('format arg 9', '1234.5');
        Observer.Expect('format arg 9 big', '123456789.123456');
        Observer.Verify();
    end;
}
