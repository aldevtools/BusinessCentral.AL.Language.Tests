// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setascending-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 70701, 70703
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SetAscending / GetAscending / Ascending on a multi-field key, on a field outside the key, and after Reset
// BC versions: 29 (27 and 28 by CI)

codeunit 70723 "LT P68 Ascending"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySetAsc(var R: Record "LT P68 Comp"; Asc: Boolean)
    begin
        R.SetAscending(Val, Asc);
    end;

    [TryFunction]
    local procedure TryGetAsc(var R: Record "LT P68 Comp"; var Res: Text)
    begin
        Res := Format(R.GetAscending(Val));
    end;

    local procedure SeedComp(var R: Record "LT P68 Comp")
    var
        g: Integer;
        s: Integer;
    begin
        R.DeleteAll();
        for g := 1 to 2 do
            for s := 1 to 2 do begin
                R.Init();
                R.Grp := g;
                R.Sub := s;
                R.Val := CopyStr('V' + Format(3 - s), 1, 30);
                R.Insert();
            end;
        R.Reset();
    end;

    local procedure Walk(var R: Record "LT P68 Comp"): Text
    var
        T: Text;
    begin
        if R.FindSet() then
            repeat
                T += Format(R.Grp) + '/' + Format(R.Sub) + ' ';
            until R.Next() = 0;
        exit(T);
    end;

    [Test]
    procedure Composite_Key_Default()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Comp";
    begin
        SeedComp(R);
        R.SetCurrentKey(Grp, Sub);
        Observer.Observe('asc-grp', Format(R.GetAscending(Grp)));
        Observer.Observe('asc-sub', Format(R.GetAscending(Sub)));
        Observer.Observe('walk', Walk(R));
        asserterror Observer.Observe('asc-val-default', Format(R.GetAscending(Val)));
        Observer.ObserveError('af64');
        Observer.Expect('asc-grp', 'Yes');
        Observer.Expect('asc-sub', 'Yes');
        Observer.Expect('walk', '1/1 1/2 2/1 2/2 ');
        Observer.Expect('af64|text', 'Cannot call GetAscending on field Val because it is not part of the current sorting.');
        Observer.Expect('af64|code', 'DB:Ok');
        Observer.Verify();
    end;

    [Test]
    procedure Composite_Key_First_Descending()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Comp";
    begin
        SeedComp(R);
        R.SetCurrentKey(Grp, Sub);
        R.SetAscending(Grp, false);
        Observer.Observe('asc-grp', Format(R.GetAscending(Grp)));
        Observer.Observe('asc-sub', Format(R.GetAscending(Sub)));
        Observer.Observe('walk', Walk(R));
        R.FindFirst();
        Observer.Observe('first', Format(R.Grp) + '/' + Format(R.Sub));
        R.FindLast();
        Observer.Observe('last', Format(R.Grp) + '/' + Format(R.Sub));
        Observer.Expect('asc-grp', 'No');
        Observer.Expect('asc-sub', 'Yes');
        Observer.Expect('walk', '2/1 2/2 1/1 1/2 ');
        Observer.Expect('first', '2/1');
        Observer.Expect('last', '1/2');
        Observer.Verify();
    end;

    [Test]
    procedure Composite_Key_Second_Descending()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Comp";
    begin
        SeedComp(R);
        R.SetCurrentKey(Grp, Sub);
        R.SetAscending(Sub, false);
        Observer.Observe('asc-grp', Format(R.GetAscending(Grp)));
        Observer.Observe('asc-sub', Format(R.GetAscending(Sub)));
        Observer.Observe('walk', Walk(R));
        R.SetAscending(Sub, true);
        Observer.Observe('walk-back', Walk(R));
        Observer.Expect('asc-grp', 'Yes');
        Observer.Expect('asc-sub', 'No');
        Observer.Expect('walk', '1/2 1/1 2/2 2/1 ');
        Observer.Expect('walk-back', '1/1 1/2 2/1 2/2 ');
        Observer.Verify();
    end;

    [Test]
    procedure Composite_Key_Both_Descending()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Comp";
    begin
        SeedComp(R);
        R.SetCurrentKey(Grp, Sub);
        R.SetAscending(Grp, false);
        R.SetAscending(Sub, false);
        Observer.Observe('walk', Walk(R));
        R.Ascending(true);
        Observer.Observe('ascending-true-walk', Walk(R));
        Observer.Observe('asc-grp-after', Format(R.GetAscending(Grp)));
        Observer.Observe('asc-sub-after', Format(R.GetAscending(Sub)));
        R.Ascending(false);
        Observer.Observe('ascending-false-walk', Walk(R));
        Observer.Observe('ascending-getter', Format(R.Ascending()));
        Observer.Expect('walk', '2/2 2/1 1/2 1/1 ');
        Observer.Expect('ascending-true-walk', '1/1 1/2 2/1 2/2 ');
        Observer.Expect('asc-grp-after', 'Yes');
        Observer.Expect('asc-sub-after', 'Yes');
        Observer.Expect('ascending-false-walk', '2/2 2/1 1/2 1/1 ');
        Observer.Expect('ascending-getter', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Field_Not_In_Key()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Comp";
        Res: Text;
    begin
        SeedComp(R);
        R.SetCurrentKey(Grp, Sub);
        Observer.Observe('set-val-false', Format(TrySetAsc(R, false)));
        Observer.Observe('set-val-false-error', GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Observer.Observe('walk-after', Walk(R));
        Observer.Observe('get-val', Format(TryGetAsc(R, Res)));
        Observer.Observe('get-val-result', Res);
        Observer.Observe('get-val-error', GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Observer.Expect('set-val-false', 'No');
        Observer.Expect('set-val-false-error', 'Cannot call SetAscending on field Val because it is not part of the current sorting.|DB:Ok');
        Observer.Expect('walk-after', '1/1 1/2 2/1 2/2 ');
        Observer.Expect('get-val', 'No');
        Observer.Expect('get-val-result', '');
        Observer.Expect('get-val-error', 'Cannot call GetAscending on field Val because it is not part of the current sorting.|DB:Ok');
        Observer.Verify();
    end;

    [Test]
    procedure Reset_And_SetCurrentKey_Reset_Direction()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Comp";
    begin
        SeedComp(R);
        R.SetCurrentKey(Grp, Sub);
        R.SetAscending(Grp, false);
        R.Reset();
        Observer.Observe('after-reset-walk', Walk(R));
        Observer.Observe('after-reset-asc', Format(R.GetAscending(Grp)));
        R.SetCurrentKey(Grp, Sub);
        R.SetAscending(Grp, false);
        R.SetCurrentKey(Grp, Sub);
        Observer.Observe('after-setkey-walk', Walk(R));
        Observer.Observe('after-setkey-asc', Format(R.GetAscending(Grp)));
        R.SetAscending(Grp, false);
        R.SetCurrentKey(Sub);
        Observer.Observe('other-key-walk', Walk(R));
        Observer.Observe('other-key-asc-grp', Format(R.GetAscending(Grp)));
        Observer.Expect('after-reset-walk', '1/1 1/2 2/1 2/2 ');
        Observer.Expect('after-reset-asc', 'Yes');
        Observer.Expect('after-setkey-walk', '2/1 2/2 1/1 1/2 ');
        Observer.Expect('after-setkey-asc', 'No');
        Observer.Expect('other-key-walk', '1/1 2/1 1/2 2/2 ');
        Observer.Expect('other-key-asc-grp', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Secondary_Key_Descending()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Comp";
    begin
        SeedComp(R);
        R.SetCurrentKey(Val);
        Observer.Observe('walk-asc', Walk(R));
        R.SetAscending(Val, false);
        Observer.Observe('walk-desc', Walk(R));
        R.FindFirst();
        Observer.Observe('first-desc', Format(R.Grp) + '/' + Format(R.Sub));
        Observer.Expect('walk-asc', '1/2 2/2 1/1 2/1 ');
        Observer.Expect('walk-desc', '1/1 2/1 1/2 2/2 ');
        Observer.Expect('first-desc', '1/1');
        Observer.Verify();
    end;

    [Test]
    procedure Text_Key_Descending_With_Filter()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Flt";
        T: Text;
        i: Integer;
    begin
        R.DeleteAll();
        for i := 1 to 4 do begin
            R.Init();
            R."No." := i;
            R.Txt := CopyStr('K' + Format(5 - i), 1, 30);
            R.Insert();
        end;
        R.SetCurrentKey(Txt);
        R.SetAscending(Txt, false);
        if R.FindSet() then
            repeat
                T += R.Txt + ' ';
            until R.Next() = 0;
        Observer.Observe('desc', T);
        R.SetFilter(Txt, '<>K2');
        T := '';
        if R.FindSet() then
            repeat
                T += R.Txt + ' ';
            until R.Next() = 0;
        Observer.Observe('desc-filtered', T);
        R.FindFirst();
        Observer.Observe('first', R.Txt);
        R.FindLast();
        Observer.Observe('last', R.Txt);
        Observer.Expect('desc', 'K4 K3 K2 K1 ');
        Observer.Expect('desc-filtered', 'K4 K3 K1 ');
        Observer.Expect('first', 'K4');
        Observer.Expect('last', 'K1');
        Observer.Verify();
    end;
}
