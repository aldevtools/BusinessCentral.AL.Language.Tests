// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-getrangemin-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P99 Row (70400) from P99Fixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: GetRangeMin / GetRangeMax across filter groups: a range set in group 2 is not seen from group 0 and vice versa; with no filter at all

codeunit 70410 "LT P99 RangeGroups"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P99 Row";
    begin
        Row.DeleteAll();
        Row.Id := 'R1';
        Row.F := 'A';
        Row.Qty := 1;
        Row.Insert();
        Row.Id := 'R2';
        Row.F := 'B';
        Row.Qty := 2;
        Row.Insert();
        Row.Id := 'R3';
        Row.F := 'T';
        Row.Qty := 3;
        Row.Insert();
    end;

    local procedure TryMin(var Row: Record "LT P99 Row"; var Result: Text)
    begin
        Result := Format(Row.GetRangeMin(F));
    end;

    [TryFunction]
    local procedure TryMax(var Row: Record "LT P99 Row"; var Res: Text)
    begin
        Res := Row.GetRangeMax(F);
    end;

    [TryFunction]
    local procedure TryMaxQty(var Row: Record "LT P99 Row"; var Res: Text)
    begin
        Res := Format(Row.GetRangeMax(Qty));
    end;

    [TryFunction]
    local procedure TryMinQty(var Row: Record "LT P99 Row"; var Res: Text)
    begin
        Res := Format(Row.GetRangeMin(Qty));
    end;

    [TryFunction]
    local procedure TryMaxId(var Row: Record "LT P99 Row"; var Res: Text)
    begin
        Res := Format(Row.GetRangeMax(Id));
    end;

    [TryFunction]
    local procedure TryMinF(var Row: Record "LT P99 Row"; var Res: Text)
    begin
        Res := Row.GetRangeMin(F);
    end;

    [TryFunction]
    local procedure TryCount(var Row: Record "LT P99 Row"; var Res: Text)
    begin
        Res := Format(Row.Count());
    end;

    [TryFunction]
    local procedure TryFilters(var Row: Record "LT P99 Row"; var Res: Text)
    begin
        Res := Row.GetFilters();
    end;

    local procedure Show(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean; Res: Text)
    begin
        if Ok then
            Observer.Observe(Name, 'ok:[' + Res + ']')
        else begin
            Observer.Observe(Name, 'err:' + GetLastErrorText());
            ClearLastError();
        end;
    end;

    [Test]
    procedure P99_NoFilterAtAll()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P99 Row";
        Res: Text;
    begin
        Seed();
        asserterror Observer.Observe('min-F', '[' + Format(Row.GetRangeMin(F)) + ']');
        Observer.ObserveError('af44');
        asserterror Observer.Observe('max-F', '[' + Format(Row.GetRangeMax(F)) + ']');
        Observer.ObserveError('af46');
        asserterror Observer.Observe('min-Id', '[' + Format(Row.GetRangeMin(Id)) + ']');
        Observer.ObserveError('af48');
        Show(Observer, 'max-Id', TryMaxId(Row, Res), Res);
        Show(Observer, 'min-Qty', TryMinQty(Row, Res), Res);
        Show(Observer, 'max-Qty', TryMaxQty(Row, Res), Res);
        Observer.Observe('group', Format(Row.FilterGroup()));
        Observer.Observe('has-filter', Format(Row.HasFilter()));
        Row.FilterGroup(2);
        Show(Observer, 'g2-min-F', TryMinF(Row, Res), Res);
        Show(Observer, 'g2-max-F', TryMax(Row, Res), Res);
        Show(Observer, 'g2-min-Qty', TryMinQty(Row, Res), Res);
        Show(Observer, 'g2-max-Qty', TryMaxQty(Row, Res), Res);
        Row.FilterGroup(0);
        Observer.Observe('back-group', Format(Row.FilterGroup()));
        Observer.Expect('af44|text', 'Specify a filter for the F field in the LT P99 Row table.');
        Observer.Expect('af44|code', 'DB:NoFilter');
        Observer.Expect('af46|text', 'Specify a filter for the F field in the LT P99 Row table.');
        Observer.Expect('af46|code', 'DB:NoFilter');
        Observer.Expect('af48|text', 'Specify a filter for the Id field in the LT P99 Row table.');
        Observer.Expect('af48|code', 'DB:NoFilter');
        Observer.Expect('max-Id', 'err:Specify a filter for the Id field in the LT P99 Row table.');
        Observer.Expect('min-Qty', 'err:Specify a filter for the Qty field in the LT P99 Row table.');
        Observer.Expect('max-Qty', 'err:Specify a filter for the Qty field in the LT P99 Row table.');
        Observer.Expect('group', '0');
        Observer.Expect('has-filter', 'No');
        Observer.Expect('g2-min-F', 'err:Specify a filter for the F field in the LT P99 Row table.');
        Observer.Expect('g2-max-F', 'err:Specify a filter for the F field in the LT P99 Row table.');
        Observer.Expect('g2-min-Qty', 'err:Specify a filter for the Qty field in the LT P99 Row table.');
        Observer.Expect('g2-max-Qty', 'err:Specify a filter for the Qty field in the LT P99 Row table.');
        Observer.Expect('back-group', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P99_RangeOnlyInGroup2()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P99 Row";
        Res: Text;
    begin
        Seed();
        Row.FilterGroup(2);
        Row.SetRange(F, 'T');
        Observer.Observe('g2-min', Row.GetRangeMin(F));
        Observer.Observe('g2-max', Row.GetRangeMax(F));
        Observer.Observe('g2-filter', Row.GetFilter(F));
        Row.FilterGroup(0);
        Observer.Observe('g0-group', Format(Row.FilterGroup()));
        Observer.Observe('g0-min', '[' + Format(Row.GetRangeMin(F)) + ']');
        Observer.Observe('g0-max', '[' + Format(Row.GetRangeMax(F)) + ']');
        Observer.Observe('g0-filter', '[' + Row.GetFilter(F) + ']');
        Observer.Observe('g0-filters', '[' + Row.GetFilters() + ']');
        Observer.Observe('g0-hasfilter', Format(Row.HasFilter()));
        Observer.Observe('g0-count', Format(Row.Count()));
        Observer.Observe('g0-findfirst', Format(Row.FindFirst()));
        Observer.Observe('g0-first-id', Row.Id);
        Row.FilterGroup(2);
        Observer.Observe('g2-count', Format(Row.Count()));
        Observer.Observe('g2-hasfilter', Format(Row.HasFilter()));
        Observer.Observe('g2-filters', Row.GetFilters());
        Row.FilterGroup(0);
        TryMin(Row, Res);
        Observer.Observe('try-min-g0', '[' + Res + ']');
        Observer.Expect('g2-min', 'T');
        Observer.Expect('g2-max', 'T');
        Observer.Expect('g2-filter', 'T');
        Observer.Expect('g0-group', '0');
        Observer.Expect('g0-min', '[T]');
        Observer.Expect('g0-max', '[T]');
        Observer.Expect('g0-filter', '[]');
        Observer.Expect('g0-filters', '[]');
        Observer.Expect('g0-hasfilter', 'No');
        Observer.Expect('g0-count', '1');
        Observer.Expect('g0-findfirst', 'Yes');
        Observer.Expect('g0-first-id', 'R3');
        Observer.Expect('g2-count', '1');
        Observer.Expect('g2-hasfilter', 'Yes');
        Observer.Expect('g2-filters', 'F: T');
        Observer.Expect('try-min-g0', '[T]');
        Observer.Verify();
    end;

    [Test]
    procedure P99_RangeOnlyInGroup0()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P99 Row";
    begin
        Seed();
        Row.SetRange(F, 'A');
        Observer.Observe('g0-min', Row.GetRangeMin(F));
        Observer.Observe('g0-max', Row.GetRangeMax(F));
        Row.FilterGroup(2);
        Observer.Observe('g2-min', '[' + Format(Row.GetRangeMin(F)) + ']');
        Observer.Observe('g2-max', '[' + Format(Row.GetRangeMax(F)) + ']');
        Observer.Observe('g2-filter', '[' + Row.GetFilter(F) + ']');
        Observer.Observe('g2-count', Format(Row.Count()));
        Row.FilterGroup(0);
        Observer.Observe('g0-count', Format(Row.Count()));
        Observer.Expect('g0-min', 'A');
        Observer.Expect('g0-max', 'A');
        Observer.Expect('g2-min', '[A]');
        Observer.Expect('g2-max', '[A]');
        Observer.Expect('g2-filter', '[]');
        Observer.Expect('g2-count', '1');
        Observer.Expect('g0-count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P99_DifferentValuesInGroups()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P99 Row";
        Res: Text;
    begin
        Seed();
        Row.SetRange(F, 'A');
        Row.FilterGroup(2);
        Row.SetRange(F, 'T');
        asserterror Observer.Observe('g2-min', Row.GetRangeMin(F));
        Observer.ObserveError('af126');
        asserterror Observer.Observe('g2-max', Row.GetRangeMax(F));
        Observer.ObserveError('af129');
        Show(Observer, 'g2-count', TryCount(Row, Res), Res);
        Row.FilterGroup(0);
        Show(Observer, 'g0-max', TryMax(Row, Res), Res);
        Show(Observer, 'g0-count', TryCount(Row, Res), Res);
        Show(Observer, 'g0-filters', TryFilters(Row, Res), Res);
        Row.FilterGroup(4);
        Show(Observer, 'g4-min', TryMinF(Row, Res), Res);
        Show(Observer, 'g4-max', TryMax(Row, Res), Res);
        Observer.Observe('g4-group', Format(Row.FilterGroup()));
        Row.FilterGroup(0);
        Observer.Expect('af126|text', 'The filter expression "<><>" applied to the field F in the LT P99 Row table results in empty set.');
        Observer.Expect('af126|code', 'DB:NotIntervalFilter');
        Observer.Expect('af129|text', 'The filter expression "<><>" applied to the field F in the LT P99 Row table results in empty set.');
        Observer.Expect('af129|code', 'DB:NotIntervalFilter');
        Observer.Expect('g2-count', 'ok:[0]');
        Observer.Expect('g0-max', 'err:The filter expression "<><>" applied to the field F in the LT P99 Row table results in empty set.');
        Observer.Expect('g0-count', 'ok:[0]');
        Observer.Expect('g0-filters', 'ok:[F: A]');
        Observer.Expect('g4-min', 'err:The filter expression "<><>" applied to the field F in the LT P99 Row table results in empty set.');
        Observer.Expect('g4-max', 'err:The filter expression "<><>" applied to the field F in the LT P99 Row table results in empty set.');
        Observer.Expect('g4-group', '4');
        Observer.Verify();
    end;

    [Test]
    procedure P99_SameValueInBothGroups()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P99 Row";
    begin
        Seed();
        Row.SetRange(F, 'B');
        Row.FilterGroup(2);
        Row.SetRange(F, 'B');
        Observer.Observe('g2-count', Format(Row.Count()));
        Row.FilterGroup(0);
        Observer.Observe('g0-count', Format(Row.Count()));
        Observer.Observe('g0-min', Row.GetRangeMin(F));
        Observer.Observe('g0-max', Row.GetRangeMax(F));
        Row.FilterGroup(2);
        Row.SetRange(F);
        Observer.Observe('cleared-g2-min', '[' + Format(Row.GetRangeMin(F)) + ']');
        Row.FilterGroup(0);
        Observer.Observe('g0-after-clear-g2', Row.GetRangeMin(F));
        Observer.Observe('g0-after-clear-count', Format(Row.Count()));
        Observer.Expect('g2-count', '1');
        Observer.Expect('g0-count', '1');
        Observer.Expect('g0-min', 'B');
        Observer.Expect('g0-max', 'B');
        Observer.Expect('cleared-g2-min', '[B]');
        Observer.Expect('g0-after-clear-g2', 'B');
        Observer.Expect('g0-after-clear-count', '1');
        Observer.Verify();
    end;
}
