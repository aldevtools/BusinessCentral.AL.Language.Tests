// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-getrangemin-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 70701
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: GetRangeMin / GetRangeMax with no filter and with filters that are not a single range
// BC versions: 29 (27 and 28 by CI)

codeunit 70721 "LT P68 Range MinMax"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryMinInt(var R: Record "LT P68 Flt"; var Res: Text)
    begin
        Res := Format(R.GetRangeMin(Int));
    end;

    [TryFunction]
    local procedure TryMaxInt(var R: Record "LT P68 Flt"; var Res: Text)
    begin
        Res := Format(R.GetRangeMax(Int));
    end;

    [TryFunction]
    local procedure TryMinTxt(var R: Record "LT P68 Flt"; var Res: Text)
    begin
        Res := Format(R.GetRangeMin(Txt));
    end;

    [TryFunction]
    local procedure TryMaxTxt(var R: Record "LT P68 Flt"; var Res: Text)
    begin
        Res := Format(R.GetRangeMax(Txt));
    end;

    [TryFunction]
    local procedure TryMinDt(var R: Record "LT P68 Flt"; var Res: Text)
    begin
        Res := Format(R.GetRangeMin(Dt), 0, 9);
    end;

    [TryFunction]
    local procedure TryMaxDt(var R: Record "LT P68 Flt"; var Res: Text)
    begin
        Res := Format(R.GetRangeMax(Dt), 0, 9);
    end;

    local procedure MinInt(var R: Record "LT P68 Flt"): Text
    var
        Res: Text;
    begin
        ClearLastError();
        if TryMinInt(R, Res) then
            exit(Res);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure MaxInt(var R: Record "LT P68 Flt"): Text
    var
        Res: Text;
    begin
        ClearLastError();
        if TryMaxInt(R, Res) then
            exit(Res);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure MinTxt(var R: Record "LT P68 Flt"): Text
    var
        Res: Text;
    begin
        ClearLastError();
        if TryMinTxt(R, Res) then
            exit(Res);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure MaxTxt(var R: Record "LT P68 Flt"): Text
    var
        Res: Text;
    begin
        ClearLastError();
        if TryMaxTxt(R, Res) then
            exit(Res);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure MinDt(var R: Record "LT P68 Flt"): Text
    var
        Res: Text;
    begin
        ClearLastError();
        if TryMinDt(R, Res) then
            exit(Res);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure MaxDt(var R: Record "LT P68 Flt"): Text
    var
        Res: Text;
    begin
        ClearLastError();
        if TryMaxDt(R, Res) then
            exit(Res);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Seed(var R: Record "LT P68 Flt")
    var
        i: Integer;
    begin
        R.DeleteAll();
        for i := 1 to 5 do begin
            R.Init();
            R."No." := i;
            R.Txt := CopyStr('T' + Format(i), 1, 30);
            R.Int := i;
            R.Dt := DMY2Date(i, 1, 2024);
            R.Insert();
        end;
        R.Reset();
    end;

    [Test]
    procedure NoFilter_Integer_Text_Date()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Flt";
    begin
        Seed(R);
        Observer.Observe('int-min', MinInt(R));
        Observer.Observe('int-max', MaxInt(R));
        Observer.Observe('txt-min', MinTxt(R));
        Observer.Observe('txt-max', MaxTxt(R));
        Observer.Observe('dt-min', MinDt(R));
        Observer.Observe('dt-max', MaxDt(R));
        R.DeleteAll();
        Observer.Observe('empty-int-min', MinInt(R));
        Observer.Observe('empty-int-max', MaxInt(R));
        Observer.Expect('int-min', 'error:Specify a filter for the Int field in the LT P68 Flt table.|DB:NoFilter');
        Observer.Expect('int-max', 'error:Specify a filter for the Int field in the LT P68 Flt table.|DB:NoFilter');
        Observer.Expect('txt-min', 'error:Specify a filter for the Txt field in the LT P68 Flt table.|DB:NoFilter');
        Observer.Expect('txt-max', 'error:Specify a filter for the Txt field in the LT P68 Flt table.|DB:NoFilter');
        Observer.Expect('dt-min', 'error:Specify a filter for the Dt field in the LT P68 Flt table.|DB:NoFilter');
        Observer.Expect('dt-max', 'error:Specify a filter for the Dt field in the LT P68 Flt table.|DB:NoFilter');
        Observer.Expect('empty-int-min', 'error:Specify a filter for the Int field in the LT P68 Flt table.|DB:NoFilter');
        Observer.Expect('empty-int-max', 'error:Specify a filter for the Int field in the LT P68 Flt table.|DB:NoFilter');
        Observer.Verify();
    end;

    [Test]
    procedure RangeFilters_Integer()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Flt";
    begin
        Seed(R);
        R.SetRange(Int, 2);
        Observer.Observe('single-min', MinInt(R));
        Observer.Observe('single-max', MaxInt(R));
        R.SetRange(Int, 2, 4);
        Observer.Observe('range-min', MinInt(R));
        Observer.Observe('range-max', MaxInt(R));
        R.SetRange(Int, 4, 2);
        Observer.Observe('reversed-min', MinInt(R));
        Observer.Observe('reversed-max', MaxInt(R));
        R.SetFilter(Int, '2..4');
        Observer.Observe('filter-range-min', MinInt(R));
        Observer.Observe('filter-range-max', MaxInt(R));
        R.SetFilter(Int, '3');
        Observer.Observe('filter-single-min', MinInt(R));
        Observer.Observe('filter-single-max', MaxInt(R));
        Observer.Expect('single-min', '2');
        Observer.Expect('single-max', '2');
        Observer.Expect('range-min', '2');
        Observer.Expect('range-max', '4');
        Observer.Expect('reversed-min', '4');
        Observer.Expect('reversed-max', '2');
        Observer.Expect('filter-range-min', '2');
        Observer.Expect('filter-range-max', '4');
        Observer.Expect('filter-single-min', '3');
        Observer.Expect('filter-single-max', '3');
        Observer.Verify();
    end;

    [Test]
    procedure NonRangeFilters_Integer()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Flt";
        Filters: List of [Text];
        F: Text;
    begin
        Seed(R);
        Filters.Add('<>5');
        Filters.Add('1|3');
        Filters.Add('>2');
        Filters.Add('<3');
        Filters.Add('>=2');
        Filters.Add('<=4');
        Filters.Add('1..2|4..5');
        Filters.Add('<2|>4');
        foreach F in Filters do begin
            R.SetFilter(Int, F);
            Observer.Observe('min:' + F, MinInt(R));
            Observer.Observe('max:' + F, MaxInt(R));
        end;
        Observer.Expect('min:<>5', 'error:The filter expression "<>5" applied to the field Int in the LT P68 Flt table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('max:<>5', 'error:The filter expression "<>5" applied to the field Int in the LT P68 Flt table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('min:1|3', 'error:The filter expression "1|3" applied to the field Int in the LT P68 Flt table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('max:1|3', 'error:The filter expression "1|3" applied to the field Int in the LT P68 Flt table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('min:>2', '2');
        Observer.Expect('max:>2', 'error:The filter ">2" on the Int field in the LT P68 Flt table has no upper bound.|DB:Ok');
        Observer.Expect('min:<3', 'error:The filter "<3" on the Int field in the LT P68 Flt table has no lower bound.|DB:Ok');
        Observer.Expect('max:<3', '3');
        Observer.Expect('min:>=2', '2');
        Observer.Expect('max:>=2', 'error:The filter ">=2" on the Int field in the LT P68 Flt table has no upper bound.|DB:Ok');
        Observer.Expect('min:<=4', 'error:The filter "<=4" on the Int field in the LT P68 Flt table has no lower bound.|DB:Ok');
        Observer.Expect('max:<=4', '4');
        Observer.Expect('min:1..2|4..5', 'error:The filter expression "1..2|4..5" applied to the field Int in the LT P68 Flt table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('max:1..2|4..5', 'error:The filter expression "1..2|4..5" applied to the field Int in the LT P68 Flt table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('min:<2|>4', 'error:The filter expression "<2|>4" applied to the field Int in the LT P68 Flt table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('max:<2|>4', 'error:The filter expression "<2|>4" applied to the field Int in the LT P68 Flt table results in more than one range.|DB:NotIntervalFilter');
        Observer.Verify();
    end;

    [Test]
    procedure NonRangeFilters_Text_Date()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Flt";
    begin
        Seed(R);
        R.SetFilter(Txt, '<>T5');
        Observer.Observe('txt-ne-min', MinTxt(R));
        Observer.Observe('txt-ne-max', MaxTxt(R));
        R.SetFilter(Txt, 'T1|T3');
        Observer.Observe('txt-or-min', MinTxt(R));
        Observer.Observe('txt-or-max', MaxTxt(R));
        R.SetFilter(Txt, 'T*');
        Observer.Observe('txt-wild-min', MinTxt(R));
        Observer.Observe('txt-wild-max', MaxTxt(R));
        R.SetFilter(Dt, '>%1', DMY2Date(2, 1, 2024));
        Observer.Observe('dt-gt-min', MinDt(R));
        Observer.Observe('dt-gt-max', MaxDt(R));
        R.SetFilter(Dt, '%1|%2', DMY2Date(1, 1, 2024), DMY2Date(3, 1, 2024));
        Observer.Observe('dt-or-min', MinDt(R));
        Observer.Observe('dt-or-max', MaxDt(R));
        Observer.Expect('txt-ne-min', 'error:The filter expression "<>T5" applied to the field Txt in the LT P68 Flt table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('txt-ne-max', 'error:The filter expression "<>T5" applied to the field Txt in the LT P68 Flt table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('txt-or-min', 'error:The filter expression "T1|T3" applied to the field Txt in the LT P68 Flt table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('txt-or-max', 'error:The filter expression "T1|T3" applied to the field Txt in the LT P68 Flt table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('txt-wild-min', 'error:The filter "T*" on the Txt field in the LT P68 Flt table has no lower bound.|DB:Ok');
        Observer.Expect('txt-wild-max', 'error:The filter "T*" on the Txt field in the LT P68 Flt table has no upper bound.|DB:Ok');
        Observer.Expect('dt-gt-min', '2024-01-02');
        Observer.Expect('dt-gt-max', 'error:The filter ">01/02/24" on the Dt field in the LT P68 Flt table has no upper bound.|DB:Ok');
        Observer.Expect('dt-or-min', 'error:The filter expression "01/01/24|01/03/24" applied to the field Dt in the LT P68 Flt table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('dt-or-max', 'error:The filter expression "01/01/24|01/03/24" applied to the field Dt in the LT P68 Flt table results in more than one range.|DB:NotIntervalFilter');
        Observer.Verify();
    end;

    [Test]
    procedure FilterOnOtherField()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Flt";
    begin
        Seed(R);
        R.SetRange(Txt, 'T2');
        Observer.Observe('other-int-min', MinInt(R));
        Observer.Observe('other-int-max', MaxInt(R));
        R.Reset();
        R.SetFilter(Int, '');
        Observer.Observe('blank-filter-min', MinInt(R));
        Observer.Observe('blank-filter-max', MaxInt(R));
        R.SetRange(Int, 2, 4);
        R.SetRange(Int);
        Observer.Observe('cleared-min', MinInt(R));
        Observer.Observe('cleared-max', MaxInt(R));
        Observer.Expect('other-int-min', 'error:Specify a filter for the Int field in the LT P68 Flt table.|DB:NoFilter');
        Observer.Expect('other-int-max', 'error:Specify a filter for the Int field in the LT P68 Flt table.|DB:NoFilter');
        Observer.Expect('blank-filter-min', 'error:Specify a filter for the Int field in the LT P68 Flt table.|DB:NoFilter');
        Observer.Expect('blank-filter-max', 'error:Specify a filter for the Int field in the LT P68 Flt table.|DB:NoFilter');
        Observer.Expect('cleared-min', 'error:Specify a filter for the Int field in the LT P68 Flt table.|DB:NoFilter');
        Observer.Expect('cleared-max', 'error:Specify a filter for the Int field in the LT P68 Flt table.|DB:NoFilter');
        Observer.Verify();
    end;
}
