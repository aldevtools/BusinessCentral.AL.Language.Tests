// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-filtergroup-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 70701
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: RecordRef.FilterGroup assigned as a property setter and read back; filters per group; Record.FilterGroup for comparison
// BC versions: 29 (27 and 28 by CI)

codeunit 70725 "LT P68 FilterGroup Set"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySetRR(var RR: RecordRef; N: Integer)
    begin
        RR.FilterGroup := N;
    end;

    [TryFunction]
    local procedure TrySetRec(var R: Record "LT P68 Flt"; N: Integer)
    begin
        R.FilterGroup := N;
    end;

    local procedure Outcome(Ok: Boolean): Text
    begin
        if Ok then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Seed()
    var
        R: Record "LT P68 Flt";
        i: Integer;
    begin
        R.DeleteAll();
        for i := 1 to 4 do begin
            R.Init();
            R."No." := i;
            R.Int := i;
            R.Txt := CopyStr('T' + Format(i), 1, 30);
            R.Insert();
        end;
    end;

    [Test]
    procedure RecordRef_Setter_ReadBack()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Values: List of [Integer];
        N: Integer;
    begin
        Seed();
        RR.Open(Database::"LT P68 Flt");
        Observer.Observe('initial', Format(RR.FilterGroup));
        Values.Add(0);
        Values.Add(1);
        Values.Add(2);
        Values.Add(3);
        Values.Add(4);
        Values.Add(5);
        Values.Add(6);
        Values.Add(10);
        Values.Add(100);
        Values.Add(1000);
        foreach N in Values do begin
            Observer.Observe('set' + Format(N), Outcome(TrySetRR(RR, N)));
            Observer.Observe('read' + Format(N), Format(RR.FilterGroup));
        end;
        Observer.Expect('initial', '0');
        Observer.Expect('set0', 'ok');
        Observer.Expect('read0', '0');
        Observer.Expect('set1', 'ok');
        Observer.Expect('read1', '1');
        Observer.Expect('set2', 'ok');
        Observer.Expect('read2', '2');
        Observer.Expect('set3', 'ok');
        Observer.Expect('read3', '3');
        Observer.Expect('set4', 'ok');
        Observer.Expect('read4', '4');
        Observer.Expect('set5', 'ok');
        Observer.Expect('read5', '5');
        Observer.Expect('set6', 'ok');
        Observer.Expect('read6', '6');
        Observer.Expect('set10', 'ok');
        Observer.Expect('read10', '10');
        Observer.Expect('set100', 'ok');
        Observer.Expect('read100', '100');
        Observer.Expect('set1000', 'ok');
        Observer.Expect('read1000', '1000');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_Setter_Negative_And_Large()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        Seed();
        RR.Open(Database::"LT P68 Flt");
        RR.FilterGroup := 3;
        Observer.Observe('set-minus-1', Outcome(TrySetRR(RR, -1)));
        Observer.Observe('read-after-minus-1', Format(RR.FilterGroup));
        Observer.Observe('set-minus-100', Outcome(TrySetRR(RR, -100)));
        Observer.Observe('read-after-minus-100', Format(RR.FilterGroup));
        Observer.Observe('set-max-int', Outcome(TrySetRR(RR, 2147483647)));
        Observer.Observe('read-after-max-int', Format(RR.FilterGroup));
        Observer.Observe('set-min-int', Outcome(TrySetRR(RR, -2147483647)));
        Observer.Observe('read-after-min-int', Format(RR.FilterGroup));
        Observer.Expect('set-minus-1', 'ok');
        Observer.Expect('read-after-minus-1', '-1');
        Observer.Expect('set-minus-100', 'ok');
        Observer.Expect('read-after-minus-100', '-100');
        Observer.Expect('set-max-int', 'ok');
        Observer.Expect('read-after-max-int', '2147483647');
        Observer.Expect('set-min-int', 'ok');
        Observer.Expect('read-after-min-int', '-2147483647');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_Filters_Per_Group()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        F: FieldRef;
    begin
        Seed();
        RR.Open(Database::"LT P68 Flt");
        F := RR.Field(4);
        F.SetFilter('>=2');
        RR.FilterGroup := 5;
        Observer.Observe('g5-view', RR.GetView());
        Observer.Observe('g5-count', Format(RR.Count()));
        F := RR.Field(4);
        F.SetFilter('<=3');
        Observer.Observe('g5-view-after', RR.GetView());
        Observer.Observe('g5-count-after', Format(RR.Count()));
        RR.FilterGroup := 0;
        Observer.Observe('g0-view', RR.GetView());
        Observer.Observe('g0-count', Format(RR.Count()));
        RR.FilterGroup := 7;
        Observer.Observe('g7-view', RR.GetView());
        Observer.Observe('g7-count', Format(RR.Count()));
        RR.FilterGroup := 0;
        RR.Reset();
        Observer.Observe('reset-g0-view', RR.GetView());
        Observer.Observe('reset-g0-group', Format(RR.FilterGroup));
        RR.FilterGroup := 5;
        Observer.Observe('reset-g5-view', RR.GetView());
        Observer.Expect('g5-view', 'VERSION(1) SORTING(No.)');
        Observer.Expect('g5-count', '3');
        Observer.Expect('g5-view-after', 'VERSION(1) SORTING(No.) WHERE(Int=FILTER(<=3))');
        Observer.Expect('g5-count-after', '2');
        Observer.Expect('g0-view', 'VERSION(1) SORTING(No.) WHERE(Int=FILTER(>=2))');
        Observer.Expect('g0-count', '2');
        Observer.Expect('g7-view', 'VERSION(1) SORTING(No.)');
        Observer.Expect('g7-count', '2');
        Observer.Expect('reset-g0-view', 'VERSION(1) SORTING(No.)');
        Observer.Expect('reset-g0-group', '0');
        Observer.Expect('reset-g5-view', 'VERSION(1) SORTING(No.)');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_Call_Form_Returns_Previous()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Prev: Integer;
    begin
        Seed();
        RR.Open(Database::"LT P68 Flt");
        RR.FilterGroup := 4;
        Prev := RR.FilterGroup(6);
        Observer.Observe('call-returns', Format(Prev));
        Observer.Observe('read-after-call', Format(RR.FilterGroup));
        Prev := RR.FilterGroup(0);
        Observer.Observe('call2-returns', Format(Prev));
        Observer.Observe('read-after-call2', Format(RR.FilterGroup));
        Observer.Expect('call-returns', '6');
        Observer.Expect('read-after-call', '6');
        Observer.Expect('call2-returns', '0');
        Observer.Expect('read-after-call2', '0');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_Group_Survives_Copy_And_Close()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        RR2: RecordRef;
        F: FieldRef;
    begin
        Seed();
        RR.Open(Database::"LT P68 Flt");
        F := RR.Field(4);
        RR.FilterGroup := 5;
        F := RR.Field(4);
        F.SetRange(2);
        RR2 := RR.Duplicate();
        Observer.Observe('dup-group', Format(RR2.FilterGroup));
        Observer.Observe('dup-view', RR2.GetView());
        RR.Close();
        RR.Open(Database::"LT P68 Flt");
        Observer.Observe('reopen-group', Format(RR.FilterGroup));
        Observer.Observe('reopen-view', RR.GetView());
        Observer.Expect('dup-group', '5');
        Observer.Expect('dup-view', 'VERSION(1) SORTING(No.) WHERE(Int=FILTER(2))');
        Observer.Expect('reopen-group', '0');
        Observer.Expect('reopen-view', 'VERSION(1) SORTING(No.)');
        Observer.Verify();
    end;

    [Test]
    procedure Record_Setter_ReadBack()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Flt";
        Values: List of [Integer];
        N: Integer;
    begin
        Seed();
        Observer.Observe('initial', Format(R.FilterGroup));
        Values.Add(0);
        Values.Add(2);
        Values.Add(4);
        Values.Add(5);
        Values.Add(100);
        Values.Add(-1);
        foreach N in Values do begin
            Observer.Observe('set' + Format(N), Outcome(TrySetRec(R, N)));
            Observer.Observe('read' + Format(N), Format(R.FilterGroup));
        end;
        Observer.Expect('initial', '0');
        Observer.Expect('set0', 'ok');
        Observer.Expect('read0', '0');
        Observer.Expect('set2', 'ok');
        Observer.Expect('read2', '2');
        Observer.Expect('set4', 'ok');
        Observer.Expect('read4', '4');
        Observer.Expect('set5', 'ok');
        Observer.Expect('read5', '5');
        Observer.Expect('set100', 'ok');
        Observer.Expect('read100', '100');
        Observer.Expect('set-1', 'ok');
        Observer.Expect('read-1', '-1');
        Observer.Verify();
    end;
}
