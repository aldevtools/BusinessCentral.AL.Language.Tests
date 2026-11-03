// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-getrangemin-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: GetRangeMin / GetRangeMax when the filter on the field sits in another filter group than the current one (and when both groups have one, when none has); GetFilter, HasFilter and Count next to it; error text start and code when nothing is found.
// BC versions: 29 (27 and 28 by CI)

table 74821 "LT P168 Range Row"
{
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Qty; Integer) { }
    }
    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

codeunit 74822 "LT P168 GetRange Groups"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryMin(var Rec: Record "LT P168 Range Row"; var Result: Text)
    begin
        Result := Format(Rec.GetRangeMin(Rec.Code));
    end;

    [TryFunction]
    local procedure TryMax(var Rec: Record "LT P168 Range Row"; var Result: Text)
    begin
        Result := Format(Rec.GetRangeMax(Rec.Code));
    end;

    [TryFunction]
    local procedure TryQtyMin(var Rec: Record "LT P168 Range Row"; var Result: Text)
    begin
        Result := Format(Rec.GetRangeMin(Rec.Qty));
    end;

    local procedure MinOf(var Rec: Record "LT P168 Range Row"): Text
    var
        R: Text;
    begin
        if TryMin(Rec, R) then
            exit(R);
        exit('ERR:' + GetLastErrorCode() + ':' + CopyStr(GetLastErrorText(), 1, 140));
    end;

    local procedure MaxOf(var Rec: Record "LT P168 Range Row"): Text
    var
        R: Text;
    begin
        if TryMax(Rec, R) then
            exit(R);
        exit('ERR:' + GetLastErrorCode() + ':' + CopyStr(GetLastErrorText(), 1, 140));
    end;

    local procedure QtyMin(var Rec: Record "LT P168 Range Row"): Text
    var
        R: Text;
    begin
        if TryQtyMin(Rec, R) then
            exit(R);
        exit('ERR:' + GetLastErrorCode() + ':' + CopyStr(GetLastErrorText(), 1, 140));
    end;

    local procedure Seed()
    var
        Row: Record "LT P168 Range Row";
    begin
        Row.DeleteAll();
        Row.Code := 'S';
        Row.Insert();
        Row.Code := 'T';
        Row.Insert();
        Row.Code := 'U';
        Row.Insert();
    end;

    [Test]
    procedure P168_GetRange_FilterOnlyInGroup2()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P168 Range Row";
    begin
        Seed();
        Observer.Observe('none-min', MinOf(Rec));
        Observer.Observe('none-max', MaxOf(Rec));
        Rec.FilterGroup(2);
        Rec.SetRange(Rec.Code, 'T');
        Observer.Observe('g2-min', MinOf(Rec));
        Observer.Observe('g2-max', MaxOf(Rec));
        Rec.FilterGroup(0);
        Observer.Observe('g0-min', MinOf(Rec));
        Observer.Observe('g0-max', MaxOf(Rec));
        Observer.Observe('g0-count', Format(Rec.Count()));
        Observer.Observe('g0-hasfilter', Format(Rec.HasFilter()));
        Observer.Observe('g0-getfilter', '[' + Rec.GetFilter(Rec.Code) + ']');
        Rec.FilterGroup(2);
        Observer.Observe('g2-getfilter', '[' + Rec.GetFilter(Rec.Code) + ']');
        Observer.Observe('g2-count', Format(Rec.Count()));
        Observer.Expect('none-min', 'ERR:DB:NoFilter:Specify a filter for the Code field in the LT P168 Range Row table.');
        Observer.Expect('none-max', 'ERR:DB:NoFilter:Specify a filter for the Code field in the LT P168 Range Row table.');
        Observer.Expect('g2-min', 'T');
        Observer.Expect('g2-max', 'T');
        Observer.Expect('g0-min', 'T');
        Observer.Expect('g0-max', 'T');
        Observer.Expect('g0-count', '1');
        Observer.Expect('g0-hasfilter', 'No');
        Observer.Expect('g0-getfilter', '[]');
        Observer.Expect('g2-getfilter', '[T]');
        Observer.Expect('g2-count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P168_GetRange_RangeInGroup2()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P168 Range Row";
    begin
        Seed();
        Rec.FilterGroup(2);
        Rec.SetRange(Rec.Code, 'S', 'U');
        Rec.FilterGroup(0);
        Observer.Observe('range-min', MinOf(Rec));
        Observer.Observe('range-max', MaxOf(Rec));
        Rec.FilterGroup(2);
        Rec.SetFilter(Rec.Code, 'S|U');
        Rec.FilterGroup(0);
        Observer.Observe('or-min', MinOf(Rec));
        Observer.Observe('or-max', MaxOf(Rec));
        Rec.FilterGroup(2);
        Rec.SetFilter(Rec.Code, '>S');
        Rec.FilterGroup(0);
        Observer.Observe('gt-min', MinOf(Rec));
        Observer.Observe('gt-max', MaxOf(Rec));
        Observer.Expect('range-min', 'S');
        Observer.Expect('range-max', 'U');
        Observer.Expect('or-min', 'ERR:DB:NotIntervalFilter:The filter expression "S|U" applied to the field Code in the LT P168 Range Row table results in more than one range.');
        Observer.Expect('or-max', 'ERR:DB:NotIntervalFilter:The filter expression "S|U" applied to the field Code in the LT P168 Range Row table results in more than one range.');
        Observer.Expect('gt-min', 'S');
        Observer.Expect('gt-max', 'ERR:DB:Ok:The filter ">S" on the Code field in the LT P168 Range Row table has no upper bound.');
        Observer.Verify();
    end;

    [Test]
    procedure P168_GetRange_BothGroupsHaveAFilter()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P168 Range Row";
    begin
        Seed();
        Rec.FilterGroup(2);
        Rec.SetRange(Rec.Code, 'T');
        Rec.FilterGroup(0);
        Rec.SetRange(Rec.Code, 'S');
        Observer.Observe('g0-min', MinOf(Rec));
        Observer.Observe('g0-max', MaxOf(Rec));
        Rec.FilterGroup(2);
        Observer.Observe('g2-min', MinOf(Rec));
        Observer.Observe('g2-max', MaxOf(Rec));
        Rec.FilterGroup(0);
        Observer.Observe('count-both', Format(Rec.Count()));
        Observer.Expect('g0-min', 'ERR:DB:NotIntervalFilter:The filter expression "<><>" applied to the field Code in the LT P168 Range Row table results in empty set.');
        Observer.Expect('g0-max', 'ERR:DB:NotIntervalFilter:The filter expression "<><>" applied to the field Code in the LT P168 Range Row table results in empty set.');
        Observer.Expect('g2-min', 'ERR:DB:NotIntervalFilter:The filter expression "<><>" applied to the field Code in the LT P168 Range Row table results in empty set.');
        Observer.Expect('g2-max', 'ERR:DB:NotIntervalFilter:The filter expression "<><>" applied to the field Code in the LT P168 Range Row table results in empty set.');
        Observer.Expect('count-both', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P168_GetRange_FilterInGroup0ReadFromGroup2()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P168 Range Row";
    begin
        Seed();
        Rec.SetRange(Rec.Code, 'U');
        Rec.FilterGroup(2);
        Observer.Observe('g2-min', MinOf(Rec));
        Observer.Observe('g2-max', MaxOf(Rec));
        Rec.FilterGroup(4);
        Observer.Observe('g4-min', MinOf(Rec));
        Rec.FilterGroup(0);
        Observer.Observe('g0-min', MinOf(Rec));
        Observer.Expect('g2-min', 'U');
        Observer.Expect('g2-max', 'U');
        Observer.Expect('g4-min', 'U');
        Observer.Expect('g0-min', 'U');
        Observer.Verify();
    end;

    [Test]
    procedure P168_GetRange_OtherFieldAndReset()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P168 Range Row";
    begin
        Seed();
        Rec.FilterGroup(2);
        Rec.SetRange(Rec.Code, 'T');
        Rec.FilterGroup(0);
        Observer.Observe('qty-min', QtyMin(Rec));
        Rec.SetRange(Rec.Qty, 0);
        Observer.Observe('qty-min-set', QtyMin(Rec));
        Observer.Observe('code-min-with-qty', MinOf(Rec));
        Rec.Reset();
        Observer.Observe('after-reset-g0', MinOf(Rec));
        Rec.FilterGroup(2);
        Observer.Observe('after-reset-g2', MinOf(Rec));
        Observer.Observe('group-now', Format(Rec.FilterGroup()));
        Rec.FilterGroup(0);
        Observer.Observe('group-back', Format(Rec.FilterGroup()));
        Observer.Expect('qty-min', 'ERR:DB:NoFilter:Specify a filter for the Qty field in the LT P168 Range Row table.');
        Observer.Expect('qty-min-set', '0');
        Observer.Expect('code-min-with-qty', 'T');
        Observer.Expect('after-reset-g0', 'ERR:DB:NoFilter:Specify a filter for the Code field in the LT P168 Range Row table.');
        Observer.Expect('after-reset-g2', 'ERR:DB:NoFilter:Specify a filter for the Code field in the LT P168 Range Row table.');
        Observer.Expect('group-now', '2');
        Observer.Expect('group-back', '0');
        Observer.Verify();
    end;
}
