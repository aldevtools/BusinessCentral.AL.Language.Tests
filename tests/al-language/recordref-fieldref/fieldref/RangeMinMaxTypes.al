// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-getrangemin-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 74069, enum 74070, test codeunit 74071
// Probe: written against BC; every literal asserted below is what BC produced (BC 27, 28 and 29 by the corpus CI matrix).
// Settles GitHub issue 216 item 2 (NP Retail blockers): Record.GetRangeMin/GetRangeMax and FieldRef.GetRangeMin/GetRangeMax on Integer, Code, Date, Option
// and Enum fields after SetRange(a, b), SetRange(a), SetFilter with a single value, a range, an open range ('..b', 'a..') and an OR filter:
// the value returned (Format with format 9) or the error text and code. Integer and Code closed ranges on a Record are pinned in
// record/lt-filters-keys-finds/P68B_RangeMinMax.al and record/lt-get-range-filter/GetRangeFilterGroups.al.
// BC versions: 27, 28, 29

enum 74070 "LT RMM Enum"
{
    Extensible = true;
    value(0; A) { }
    value(1; B) { }
    value(2; C) { }
    value(3; D) { }
}

table 74069 "LT RMM Rec"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Cd; Code[10]) { }
        field(3; Dt; Date) { }
        field(4; Opt; Option) { OptionMembers = A,B,C,D; }
        field(5; En; Enum "LT RMM Enum") { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 74071 "LT RMM Range MinMax Types"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Show(Ok: Boolean; Res: Text): Text
    begin
        if Ok then
            exit('ok:' + Res);
        exit('err:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryMinInt(var R: Record "LT RMM Rec"; var Res: Text)
    begin
        Res := Format(R.GetRangeMin(Id), 0, 9);
    end;

    [TryFunction]
    local procedure TryMaxInt(var R: Record "LT RMM Rec"; var Res: Text)
    begin
        Res := Format(R.GetRangeMax(Id), 0, 9);
    end;

    [TryFunction]
    local procedure TryMinCode(var R: Record "LT RMM Rec"; var Res: Text)
    begin
        Res := Format(R.GetRangeMin(Cd), 0, 9);
    end;

    [TryFunction]
    local procedure TryMaxCode(var R: Record "LT RMM Rec"; var Res: Text)
    begin
        Res := Format(R.GetRangeMax(Cd), 0, 9);
    end;

    [TryFunction]
    local procedure TryMinDate(var R: Record "LT RMM Rec"; var Res: Text)
    begin
        Res := Format(R.GetRangeMin(Dt), 0, 9);
    end;

    [TryFunction]
    local procedure TryMaxDate(var R: Record "LT RMM Rec"; var Res: Text)
    begin
        Res := Format(R.GetRangeMax(Dt), 0, 9);
    end;

    [TryFunction]
    local procedure TryMinOpt(var R: Record "LT RMM Rec"; var Res: Text)
    begin
        Res := Format(R.GetRangeMin(Opt), 0, 9);
    end;

    [TryFunction]
    local procedure TryMaxOpt(var R: Record "LT RMM Rec"; var Res: Text)
    begin
        Res := Format(R.GetRangeMax(Opt), 0, 9);
    end;

    [TryFunction]
    local procedure TryMinEnum(var R: Record "LT RMM Rec"; var Res: Text)
    begin
        Res := Format(R.GetRangeMin(En), 0, 9);
    end;

    [TryFunction]
    local procedure TryMaxEnum(var R: Record "LT RMM Rec"; var Res: Text)
    begin
        Res := Format(R.GetRangeMax(En), 0, 9);
    end;

    [TryFunction]
    local procedure TryRefMin(var F: FieldRef; var Res: Text)
    begin
        Res := Format(F.GetRangeMin(), 0, 9);
    end;

    [TryFunction]
    local procedure TryRefMax(var F: FieldRef; var Res: Text)
    begin
        Res := Format(F.GetRangeMax(), 0, 9);
    end;

    [Test]
    procedure GetRange_Int_FieldRef_Closed()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT RMM Rec";
        RR: RecordRef;
        F: FieldRef;
        Res: Text;
    begin
        RR.Open(Database::"LT RMM Rec");
        F := RR.Field(R.FieldNo(Id));
        RR.Reset();
        F.SetRange(2, 4);
        Res := '';
        Observer.Observe('setrange_a_b_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('setrange_a_b_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        F.SetRange(2);
        Res := '';
        Observer.Observe('setrange_a_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('setrange_a_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        F.SetFilter('2');
        Res := '';
        Observer.Observe('filter_a_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('filter_a_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        F.SetFilter('2..4');
        Res := '';
        Observer.Observe('filter_a_b_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('filter_a_b_max', Show(TryRefMax(F, Res), Res));
        Observer.Expect('setrange_a_b_min', 'ok:2');
        Observer.Expect('setrange_a_b_max', 'ok:4');
        Observer.Expect('setrange_a_min', 'ok:2');
        Observer.Expect('setrange_a_max', 'ok:2');
        Observer.Expect('filter_a_min', 'ok:2');
        Observer.Expect('filter_a_max', 'ok:2');
        Observer.Expect('filter_a_b_min', 'ok:2');
        Observer.Expect('filter_a_b_max', 'ok:4');
        Observer.Verify();
    end;

    [Test]
    procedure GetRange_Int_Record_Open()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT RMM Rec";
        RR: RecordRef;
        F: FieldRef;
        Res: Text;
    begin
        R.Reset();
        R.SetFilter(Id, '..4');
        Res := '';
        Observer.Observe('filter_open_hi_min', Show(TryMinInt(R, Res), Res));
        Res := '';
        Observer.Observe('filter_open_hi_max', Show(TryMaxInt(R, Res), Res));
        R.Reset();
        R.SetFilter(Id, '2..');
        Res := '';
        Observer.Observe('filter_open_lo_min', Show(TryMinInt(R, Res), Res));
        Res := '';
        Observer.Observe('filter_open_lo_max', Show(TryMaxInt(R, Res), Res));
        R.Reset();
        R.SetFilter(Id, '2|4');
        Res := '';
        Observer.Observe('filter_or_min', Show(TryMinInt(R, Res), Res));
        Res := '';
        Observer.Observe('filter_or_max', Show(TryMaxInt(R, Res), Res));
        R.Reset();
        Res := '';
        Observer.Observe('nofilter_min', Show(TryMinInt(R, Res), Res));
        Res := '';
        Observer.Observe('nofilter_max', Show(TryMaxInt(R, Res), Res));
        Observer.Expect('filter_open_hi_min', 'err:The filter "..4" on the Id field in the LT RMM Rec table has no lower bound.|DB:Ok');
        Observer.Expect('filter_open_hi_max', 'ok:4');
        Observer.Expect('filter_open_lo_min', 'ok:2');
        Observer.Expect('filter_open_lo_max', 'err:The filter "2.." on the Id field in the LT RMM Rec table has no upper bound.|DB:Ok');
        Observer.Expect('filter_or_min', 'err:The filter expression "2|4" applied to the field Id in the LT RMM Rec table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('filter_or_max', 'err:The filter expression "2|4" applied to the field Id in the LT RMM Rec table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('nofilter_min', 'err:Specify a filter for the Id field in the LT RMM Rec table.|DB:NoFilter');
        Observer.Expect('nofilter_max', 'err:Specify a filter for the Id field in the LT RMM Rec table.|DB:NoFilter');
        Observer.Verify();
    end;

    [Test]
    procedure GetRange_Int_FieldRef_Open()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT RMM Rec";
        RR: RecordRef;
        F: FieldRef;
        Res: Text;
    begin
        RR.Open(Database::"LT RMM Rec");
        F := RR.Field(R.FieldNo(Id));
        RR.Reset();
        F.SetFilter('..4');
        Res := '';
        Observer.Observe('filter_open_hi_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('filter_open_hi_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        F.SetFilter('2..');
        Res := '';
        Observer.Observe('filter_open_lo_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('filter_open_lo_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        F.SetFilter('2|4');
        Res := '';
        Observer.Observe('filter_or_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('filter_or_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        Res := '';
        Observer.Observe('nofilter_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('nofilter_max', Show(TryRefMax(F, Res), Res));
        Observer.Expect('filter_open_hi_min', 'err:The filter "..4" on the Id field in the LT RMM Rec table has no lower bound.|DB:Ok');
        Observer.Expect('filter_open_hi_max', 'ok:4');
        Observer.Expect('filter_open_lo_min', 'ok:2');
        Observer.Expect('filter_open_lo_max', 'err:The filter "2.." on the Id field in the LT RMM Rec table has no upper bound.|DB:Ok');
        Observer.Expect('filter_or_min', 'err:The filter expression "2|4" applied to the field Id in the LT RMM Rec table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('filter_or_max', 'err:The filter expression "2|4" applied to the field Id in the LT RMM Rec table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('nofilter_min', 'err:Specify a filter for the Id field in the LT RMM Rec table.|DB:NoFilter');
        Observer.Expect('nofilter_max', 'err:Specify a filter for the Id field in the LT RMM Rec table.|DB:NoFilter');
        Observer.Verify();
    end;

    [Test]
    procedure GetRange_Code_FieldRef_Closed()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT RMM Rec";
        RR: RecordRef;
        F: FieldRef;
        Res: Text;
    begin
        RR.Open(Database::"LT RMM Rec");
        F := RR.Field(R.FieldNo(Cd));
        RR.Reset();
        F.SetRange('B', 'D');
        Res := '';
        Observer.Observe('setrange_a_b_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('setrange_a_b_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        F.SetRange('B');
        Res := '';
        Observer.Observe('setrange_a_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('setrange_a_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        F.SetFilter('B');
        Res := '';
        Observer.Observe('filter_a_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('filter_a_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        F.SetFilter('B..D');
        Res := '';
        Observer.Observe('filter_a_b_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('filter_a_b_max', Show(TryRefMax(F, Res), Res));
        Observer.Expect('setrange_a_b_min', 'ok:B');
        Observer.Expect('setrange_a_b_max', 'ok:D');
        Observer.Expect('setrange_a_min', 'ok:B');
        Observer.Expect('setrange_a_max', 'ok:B');
        Observer.Expect('filter_a_min', 'ok:B');
        Observer.Expect('filter_a_max', 'ok:B');
        Observer.Expect('filter_a_b_min', 'ok:B');
        Observer.Expect('filter_a_b_max', 'ok:D');
        Observer.Verify();
    end;

    [Test]
    procedure GetRange_Code_Record_Open()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT RMM Rec";
        RR: RecordRef;
        F: FieldRef;
        Res: Text;
    begin
        R.Reset();
        R.SetFilter(Cd, '..D');
        Res := '';
        Observer.Observe('filter_open_hi_min', Show(TryMinCode(R, Res), Res));
        Res := '';
        Observer.Observe('filter_open_hi_max', Show(TryMaxCode(R, Res), Res));
        R.Reset();
        R.SetFilter(Cd, 'B..');
        Res := '';
        Observer.Observe('filter_open_lo_min', Show(TryMinCode(R, Res), Res));
        Res := '';
        Observer.Observe('filter_open_lo_max', Show(TryMaxCode(R, Res), Res));
        R.Reset();
        R.SetFilter(Cd, 'B|D');
        Res := '';
        Observer.Observe('filter_or_min', Show(TryMinCode(R, Res), Res));
        Res := '';
        Observer.Observe('filter_or_max', Show(TryMaxCode(R, Res), Res));
        R.Reset();
        Res := '';
        Observer.Observe('nofilter_min', Show(TryMinCode(R, Res), Res));
        Res := '';
        Observer.Observe('nofilter_max', Show(TryMaxCode(R, Res), Res));
        Observer.Expect('filter_open_hi_min', 'err:The filter "..D" on the Cd field in the LT RMM Rec table has no lower bound.|DB:Ok');
        Observer.Expect('filter_open_hi_max', 'ok:D');
        Observer.Expect('filter_open_lo_min', 'ok:B');
        Observer.Expect('filter_open_lo_max', 'err:The filter "B.." on the Cd field in the LT RMM Rec table has no upper bound.|DB:Ok');
        Observer.Expect('filter_or_min', 'err:The filter expression "B|D" applied to the field Cd in the LT RMM Rec table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('filter_or_max', 'err:The filter expression "B|D" applied to the field Cd in the LT RMM Rec table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('nofilter_min', 'err:Specify a filter for the Cd field in the LT RMM Rec table.|DB:NoFilter');
        Observer.Expect('nofilter_max', 'err:Specify a filter for the Cd field in the LT RMM Rec table.|DB:NoFilter');
        Observer.Verify();
    end;

    [Test]
    procedure GetRange_Code_FieldRef_Open()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT RMM Rec";
        RR: RecordRef;
        F: FieldRef;
        Res: Text;
    begin
        RR.Open(Database::"LT RMM Rec");
        F := RR.Field(R.FieldNo(Cd));
        RR.Reset();
        F.SetFilter('..D');
        Res := '';
        Observer.Observe('filter_open_hi_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('filter_open_hi_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        F.SetFilter('B..');
        Res := '';
        Observer.Observe('filter_open_lo_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('filter_open_lo_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        F.SetFilter('B|D');
        Res := '';
        Observer.Observe('filter_or_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('filter_or_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        Res := '';
        Observer.Observe('nofilter_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('nofilter_max', Show(TryRefMax(F, Res), Res));
        Observer.Expect('filter_open_hi_min', 'err:The filter "..D" on the Cd field in the LT RMM Rec table has no lower bound.|DB:Ok');
        Observer.Expect('filter_open_hi_max', 'ok:D');
        Observer.Expect('filter_open_lo_min', 'ok:B');
        Observer.Expect('filter_open_lo_max', 'err:The filter "B.." on the Cd field in the LT RMM Rec table has no upper bound.|DB:Ok');
        Observer.Expect('filter_or_min', 'err:The filter expression "B|D" applied to the field Cd in the LT RMM Rec table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('filter_or_max', 'err:The filter expression "B|D" applied to the field Cd in the LT RMM Rec table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('nofilter_min', 'err:Specify a filter for the Cd field in the LT RMM Rec table.|DB:NoFilter');
        Observer.Expect('nofilter_max', 'err:Specify a filter for the Cd field in the LT RMM Rec table.|DB:NoFilter');
        Observer.Verify();
    end;

    [Test]
    procedure GetRange_Date_Record_Closed()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT RMM Rec";
        RR: RecordRef;
        F: FieldRef;
        Res: Text;
    begin
        R.Reset();
        R.SetRange(Dt, DMY2Date(2,1,2026), DMY2Date(4,1,2026));
        Res := '';
        Observer.Observe('setrange_a_b_min', Show(TryMinDate(R, Res), Res));
        Res := '';
        Observer.Observe('setrange_a_b_max', Show(TryMaxDate(R, Res), Res));
        R.Reset();
        R.SetRange(Dt, DMY2Date(2,1,2026));
        Res := '';
        Observer.Observe('setrange_a_min', Show(TryMinDate(R, Res), Res));
        Res := '';
        Observer.Observe('setrange_a_max', Show(TryMaxDate(R, Res), Res));
        R.Reset();
        R.SetFilter(Dt, '020126');
        Res := '';
        Observer.Observe('filter_a_min', Show(TryMinDate(R, Res), Res));
        Res := '';
        Observer.Observe('filter_a_max', Show(TryMaxDate(R, Res), Res));
        R.Reset();
        R.SetFilter(Dt, '020126..040126');
        Res := '';
        Observer.Observe('filter_a_b_min', Show(TryMinDate(R, Res), Res));
        Res := '';
        Observer.Observe('filter_a_b_max', Show(TryMaxDate(R, Res), Res));
        Observer.Expect('setrange_a_b_min', 'ok:2026-01-02');
        Observer.Expect('setrange_a_b_max', 'ok:2026-01-04');
        Observer.Expect('setrange_a_min', 'ok:2026-01-02');
        Observer.Expect('setrange_a_max', 'ok:2026-01-02');
        Observer.Expect('filter_a_min', 'ok:2026-02-01');
        Observer.Expect('filter_a_max', 'ok:2026-02-01');
        Observer.Expect('filter_a_b_min', 'ok:2026-02-01');
        Observer.Expect('filter_a_b_max', 'ok:2026-04-01');
        Observer.Verify();
    end;

    [Test]
    procedure GetRange_Date_FieldRef_Closed()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT RMM Rec";
        RR: RecordRef;
        F: FieldRef;
        Res: Text;
    begin
        RR.Open(Database::"LT RMM Rec");
        F := RR.Field(R.FieldNo(Dt));
        RR.Reset();
        F.SetRange(DMY2Date(2,1,2026), DMY2Date(4,1,2026));
        Res := '';
        Observer.Observe('setrange_a_b_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('setrange_a_b_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        F.SetRange(DMY2Date(2,1,2026));
        Res := '';
        Observer.Observe('setrange_a_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('setrange_a_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        F.SetFilter('020126');
        Res := '';
        Observer.Observe('filter_a_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('filter_a_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        F.SetFilter('020126..040126');
        Res := '';
        Observer.Observe('filter_a_b_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('filter_a_b_max', Show(TryRefMax(F, Res), Res));
        Observer.Expect('setrange_a_b_min', 'ok:2026-01-02');
        Observer.Expect('setrange_a_b_max', 'ok:2026-01-04');
        Observer.Expect('setrange_a_min', 'ok:2026-01-02');
        Observer.Expect('setrange_a_max', 'ok:2026-01-02');
        Observer.Expect('filter_a_min', 'ok:2026-02-01');
        Observer.Expect('filter_a_max', 'ok:2026-02-01');
        Observer.Expect('filter_a_b_min', 'ok:2026-02-01');
        Observer.Expect('filter_a_b_max', 'ok:2026-04-01');
        Observer.Verify();
    end;

    [Test]
    procedure GetRange_Date_Record_Open()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT RMM Rec";
        RR: RecordRef;
        F: FieldRef;
        Res: Text;
    begin
        R.Reset();
        R.SetFilter(Dt, '..040126');
        Res := '';
        Observer.Observe('filter_open_hi_min', Show(TryMinDate(R, Res), Res));
        Res := '';
        Observer.Observe('filter_open_hi_max', Show(TryMaxDate(R, Res), Res));
        R.Reset();
        R.SetFilter(Dt, '020126..');
        Res := '';
        Observer.Observe('filter_open_lo_min', Show(TryMinDate(R, Res), Res));
        Res := '';
        Observer.Observe('filter_open_lo_max', Show(TryMaxDate(R, Res), Res));
        R.Reset();
        R.SetFilter(Dt, '020126|040126');
        Res := '';
        Observer.Observe('filter_or_min', Show(TryMinDate(R, Res), Res));
        Res := '';
        Observer.Observe('filter_or_max', Show(TryMaxDate(R, Res), Res));
        R.Reset();
        Res := '';
        Observer.Observe('nofilter_min', Show(TryMinDate(R, Res), Res));
        Res := '';
        Observer.Observe('nofilter_max', Show(TryMaxDate(R, Res), Res));
        Observer.Expect('filter_open_hi_min', 'err:The filter "..04/01/26" on the Dt field in the LT RMM Rec table has no lower bound.|DB:Ok');
        Observer.Expect('filter_open_hi_max', 'ok:2026-04-01');
        Observer.Expect('filter_open_lo_min', 'ok:2026-02-01');
        Observer.Expect('filter_open_lo_max', 'err:The filter "02/01/26.." on the Dt field in the LT RMM Rec table has no upper bound.|DB:Ok');
        Observer.Expect('filter_or_min', 'err:The filter expression "02/01/26|04/01/26" applied to the field Dt in the LT RMM Rec table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('filter_or_max', 'err:The filter expression "02/01/26|04/01/26" applied to the field Dt in the LT RMM Rec table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('nofilter_min', 'err:Specify a filter for the Dt field in the LT RMM Rec table.|DB:NoFilter');
        Observer.Expect('nofilter_max', 'err:Specify a filter for the Dt field in the LT RMM Rec table.|DB:NoFilter');
        Observer.Verify();
    end;

    [Test]
    procedure GetRange_Date_FieldRef_Open()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT RMM Rec";
        RR: RecordRef;
        F: FieldRef;
        Res: Text;
    begin
        RR.Open(Database::"LT RMM Rec");
        F := RR.Field(R.FieldNo(Dt));
        RR.Reset();
        F.SetFilter('..040126');
        Res := '';
        Observer.Observe('filter_open_hi_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('filter_open_hi_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        F.SetFilter('020126..');
        Res := '';
        Observer.Observe('filter_open_lo_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('filter_open_lo_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        F.SetFilter('020126|040126');
        Res := '';
        Observer.Observe('filter_or_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('filter_or_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        Res := '';
        Observer.Observe('nofilter_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('nofilter_max', Show(TryRefMax(F, Res), Res));
        Observer.Expect('filter_open_hi_min', 'err:The filter "..04/01/26" on the Dt field in the LT RMM Rec table has no lower bound.|DB:Ok');
        Observer.Expect('filter_open_hi_max', 'ok:2026-04-01');
        Observer.Expect('filter_open_lo_min', 'ok:2026-02-01');
        Observer.Expect('filter_open_lo_max', 'err:The filter "02/01/26.." on the Dt field in the LT RMM Rec table has no upper bound.|DB:Ok');
        Observer.Expect('filter_or_min', 'err:The filter expression "02/01/26|04/01/26" applied to the field Dt in the LT RMM Rec table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('filter_or_max', 'err:The filter expression "02/01/26|04/01/26" applied to the field Dt in the LT RMM Rec table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('nofilter_min', 'err:Specify a filter for the Dt field in the LT RMM Rec table.|DB:NoFilter');
        Observer.Expect('nofilter_max', 'err:Specify a filter for the Dt field in the LT RMM Rec table.|DB:NoFilter');
        Observer.Verify();
    end;

    [Test]
    procedure GetRange_Opt_Record_Closed()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT RMM Rec";
        RR: RecordRef;
        F: FieldRef;
        Res: Text;
    begin
        R.Reset();
        R.SetRange(Opt, R.Opt::B, R.Opt::D);
        Res := '';
        Observer.Observe('setrange_a_b_min', Show(TryMinOpt(R, Res), Res));
        Res := '';
        Observer.Observe('setrange_a_b_max', Show(TryMaxOpt(R, Res), Res));
        R.Reset();
        R.SetRange(Opt, R.Opt::B);
        Res := '';
        Observer.Observe('setrange_a_min', Show(TryMinOpt(R, Res), Res));
        Res := '';
        Observer.Observe('setrange_a_max', Show(TryMaxOpt(R, Res), Res));
        R.Reset();
        R.SetFilter(Opt, 'B');
        Res := '';
        Observer.Observe('filter_a_min', Show(TryMinOpt(R, Res), Res));
        Res := '';
        Observer.Observe('filter_a_max', Show(TryMaxOpt(R, Res), Res));
        R.Reset();
        R.SetFilter(Opt, 'B..D');
        Res := '';
        Observer.Observe('filter_a_b_min', Show(TryMinOpt(R, Res), Res));
        Res := '';
        Observer.Observe('filter_a_b_max', Show(TryMaxOpt(R, Res), Res));
        Observer.Expect('setrange_a_b_min', 'ok:1');
        Observer.Expect('setrange_a_b_max', 'ok:3');
        Observer.Expect('setrange_a_min', 'ok:1');
        Observer.Expect('setrange_a_max', 'ok:1');
        Observer.Expect('filter_a_min', 'ok:1');
        Observer.Expect('filter_a_max', 'ok:1');
        Observer.Expect('filter_a_b_min', 'ok:1');
        Observer.Expect('filter_a_b_max', 'ok:3');
        Observer.Verify();
    end;

    [Test]
    procedure GetRange_Opt_FieldRef_Closed()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT RMM Rec";
        RR: RecordRef;
        F: FieldRef;
        Res: Text;
    begin
        RR.Open(Database::"LT RMM Rec");
        F := RR.Field(R.FieldNo(Opt));
        RR.Reset();
        F.SetRange(R.Opt::B, R.Opt::D);
        Res := '';
        Observer.Observe('setrange_a_b_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('setrange_a_b_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        F.SetRange(R.Opt::B);
        Res := '';
        Observer.Observe('setrange_a_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('setrange_a_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        F.SetFilter('B');
        Res := '';
        Observer.Observe('filter_a_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('filter_a_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        F.SetFilter('B..D');
        Res := '';
        Observer.Observe('filter_a_b_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('filter_a_b_max', Show(TryRefMax(F, Res), Res));
        Observer.Expect('setrange_a_b_min', 'ok:1');
        Observer.Expect('setrange_a_b_max', 'ok:3');
        Observer.Expect('setrange_a_min', 'ok:1');
        Observer.Expect('setrange_a_max', 'ok:1');
        Observer.Expect('filter_a_min', 'ok:1');
        Observer.Expect('filter_a_max', 'ok:1');
        Observer.Expect('filter_a_b_min', 'ok:1');
        Observer.Expect('filter_a_b_max', 'ok:3');
        Observer.Verify();
    end;

    [Test]
    procedure GetRange_Opt_Record_Open()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT RMM Rec";
        RR: RecordRef;
        F: FieldRef;
        Res: Text;
    begin
        R.Reset();
        R.SetFilter(Opt, '..D');
        Res := '';
        Observer.Observe('filter_open_hi_min', Show(TryMinOpt(R, Res), Res));
        Res := '';
        Observer.Observe('filter_open_hi_max', Show(TryMaxOpt(R, Res), Res));
        R.Reset();
        R.SetFilter(Opt, 'B..');
        Res := '';
        Observer.Observe('filter_open_lo_min', Show(TryMinOpt(R, Res), Res));
        Res := '';
        Observer.Observe('filter_open_lo_max', Show(TryMaxOpt(R, Res), Res));
        R.Reset();
        R.SetFilter(Opt, 'B|D');
        Res := '';
        Observer.Observe('filter_or_min', Show(TryMinOpt(R, Res), Res));
        Res := '';
        Observer.Observe('filter_or_max', Show(TryMaxOpt(R, Res), Res));
        R.Reset();
        Res := '';
        Observer.Observe('nofilter_min', Show(TryMinOpt(R, Res), Res));
        Res := '';
        Observer.Observe('nofilter_max', Show(TryMaxOpt(R, Res), Res));
        Observer.Expect('filter_open_hi_min', 'err:The filter "..D" on the Opt field in the LT RMM Rec table has no lower bound.|DB:Ok');
        Observer.Expect('filter_open_hi_max', 'ok:3');
        Observer.Expect('filter_open_lo_min', 'ok:1');
        Observer.Expect('filter_open_lo_max', 'err:The filter "B.." on the Opt field in the LT RMM Rec table has no upper bound.|DB:Ok');
        Observer.Expect('filter_or_min', 'err:The filter expression "B|D" applied to the field Opt in the LT RMM Rec table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('filter_or_max', 'err:The filter expression "B|D" applied to the field Opt in the LT RMM Rec table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('nofilter_min', 'err:Specify a filter for the Opt field in the LT RMM Rec table.|DB:NoFilter');
        Observer.Expect('nofilter_max', 'err:Specify a filter for the Opt field in the LT RMM Rec table.|DB:NoFilter');
        Observer.Verify();
    end;

    [Test]
    procedure GetRange_Opt_FieldRef_Open()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT RMM Rec";
        RR: RecordRef;
        F: FieldRef;
        Res: Text;
    begin
        RR.Open(Database::"LT RMM Rec");
        F := RR.Field(R.FieldNo(Opt));
        RR.Reset();
        F.SetFilter('..D');
        Res := '';
        Observer.Observe('filter_open_hi_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('filter_open_hi_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        F.SetFilter('B..');
        Res := '';
        Observer.Observe('filter_open_lo_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('filter_open_lo_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        F.SetFilter('B|D');
        Res := '';
        Observer.Observe('filter_or_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('filter_or_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        Res := '';
        Observer.Observe('nofilter_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('nofilter_max', Show(TryRefMax(F, Res), Res));
        Observer.Expect('filter_open_hi_min', 'err:The filter "..D" on the Opt field in the LT RMM Rec table has no lower bound.|DB:Ok');
        Observer.Expect('filter_open_hi_max', 'ok:3');
        Observer.Expect('filter_open_lo_min', 'ok:1');
        Observer.Expect('filter_open_lo_max', 'err:The filter "B.." on the Opt field in the LT RMM Rec table has no upper bound.|DB:Ok');
        Observer.Expect('filter_or_min', 'err:The filter expression "B|D" applied to the field Opt in the LT RMM Rec table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('filter_or_max', 'err:The filter expression "B|D" applied to the field Opt in the LT RMM Rec table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('nofilter_min', 'err:Specify a filter for the Opt field in the LT RMM Rec table.|DB:NoFilter');
        Observer.Expect('nofilter_max', 'err:Specify a filter for the Opt field in the LT RMM Rec table.|DB:NoFilter');
        Observer.Verify();
    end;

    [Test]
    procedure GetRange_Enum_Record_Closed()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT RMM Rec";
        RR: RecordRef;
        F: FieldRef;
        Res: Text;
    begin
        R.Reset();
        R.SetRange(En, "LT RMM Enum"::B, "LT RMM Enum"::D);
        Res := '';
        Observer.Observe('setrange_a_b_min', Show(TryMinEnum(R, Res), Res));
        Res := '';
        Observer.Observe('setrange_a_b_max', Show(TryMaxEnum(R, Res), Res));
        R.Reset();
        R.SetRange(En, "LT RMM Enum"::B);
        Res := '';
        Observer.Observe('setrange_a_min', Show(TryMinEnum(R, Res), Res));
        Res := '';
        Observer.Observe('setrange_a_max', Show(TryMaxEnum(R, Res), Res));
        R.Reset();
        R.SetFilter(En, 'B');
        Res := '';
        Observer.Observe('filter_a_min', Show(TryMinEnum(R, Res), Res));
        Res := '';
        Observer.Observe('filter_a_max', Show(TryMaxEnum(R, Res), Res));
        R.Reset();
        R.SetFilter(En, 'B..D');
        Res := '';
        Observer.Observe('filter_a_b_min', Show(TryMinEnum(R, Res), Res));
        Res := '';
        Observer.Observe('filter_a_b_max', Show(TryMaxEnum(R, Res), Res));
        Observer.Expect('setrange_a_b_min', 'ok:1');
        Observer.Expect('setrange_a_b_max', 'ok:3');
        Observer.Expect('setrange_a_min', 'ok:1');
        Observer.Expect('setrange_a_max', 'ok:1');
        Observer.Expect('filter_a_min', 'ok:1');
        Observer.Expect('filter_a_max', 'ok:1');
        Observer.Expect('filter_a_b_min', 'ok:1');
        Observer.Expect('filter_a_b_max', 'ok:3');
        Observer.Verify();
    end;

    [Test]
    procedure GetRange_Enum_FieldRef_Closed()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT RMM Rec";
        RR: RecordRef;
        F: FieldRef;
        Res: Text;
    begin
        RR.Open(Database::"LT RMM Rec");
        F := RR.Field(R.FieldNo(En));
        RR.Reset();
        F.SetRange("LT RMM Enum"::B, "LT RMM Enum"::D);
        Res := '';
        Observer.Observe('setrange_a_b_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('setrange_a_b_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        F.SetRange("LT RMM Enum"::B);
        Res := '';
        Observer.Observe('setrange_a_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('setrange_a_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        F.SetFilter('B');
        Res := '';
        Observer.Observe('filter_a_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('filter_a_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        F.SetFilter('B..D');
        Res := '';
        Observer.Observe('filter_a_b_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('filter_a_b_max', Show(TryRefMax(F, Res), Res));
        Observer.Expect('setrange_a_b_min', 'ok:1');
        Observer.Expect('setrange_a_b_max', 'ok:3');
        Observer.Expect('setrange_a_min', 'ok:1');
        Observer.Expect('setrange_a_max', 'ok:1');
        Observer.Expect('filter_a_min', 'ok:1');
        Observer.Expect('filter_a_max', 'ok:1');
        Observer.Expect('filter_a_b_min', 'ok:1');
        Observer.Expect('filter_a_b_max', 'ok:3');
        Observer.Verify();
    end;

    [Test]
    procedure GetRange_Enum_Record_Open()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT RMM Rec";
        RR: RecordRef;
        F: FieldRef;
        Res: Text;
    begin
        R.Reset();
        R.SetFilter(En, '..D');
        Res := '';
        Observer.Observe('filter_open_hi_min', Show(TryMinEnum(R, Res), Res));
        Res := '';
        Observer.Observe('filter_open_hi_max', Show(TryMaxEnum(R, Res), Res));
        R.Reset();
        R.SetFilter(En, 'B..');
        Res := '';
        Observer.Observe('filter_open_lo_min', Show(TryMinEnum(R, Res), Res));
        Res := '';
        Observer.Observe('filter_open_lo_max', Show(TryMaxEnum(R, Res), Res));
        R.Reset();
        R.SetFilter(En, 'B|D');
        Res := '';
        Observer.Observe('filter_or_min', Show(TryMinEnum(R, Res), Res));
        Res := '';
        Observer.Observe('filter_or_max', Show(TryMaxEnum(R, Res), Res));
        R.Reset();
        Res := '';
        Observer.Observe('nofilter_min', Show(TryMinEnum(R, Res), Res));
        Res := '';
        Observer.Observe('nofilter_max', Show(TryMaxEnum(R, Res), Res));
        Observer.Expect('filter_open_hi_min', 'err:The filter "..D" on the En field in the LT RMM Rec table has no lower bound.|DB:Ok');
        Observer.Expect('filter_open_hi_max', 'ok:3');
        Observer.Expect('filter_open_lo_min', 'ok:1');
        Observer.Expect('filter_open_lo_max', 'err:The filter "B.." on the En field in the LT RMM Rec table has no upper bound.|DB:Ok');
        Observer.Expect('filter_or_min', 'err:The filter expression "B|D" applied to the field En in the LT RMM Rec table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('filter_or_max', 'err:The filter expression "B|D" applied to the field En in the LT RMM Rec table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('nofilter_min', 'err:Specify a filter for the En field in the LT RMM Rec table.|DB:NoFilter');
        Observer.Expect('nofilter_max', 'err:Specify a filter for the En field in the LT RMM Rec table.|DB:NoFilter');
        Observer.Verify();
    end;

    [Test]
    procedure GetRange_Enum_FieldRef_Open()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT RMM Rec";
        RR: RecordRef;
        F: FieldRef;
        Res: Text;
    begin
        RR.Open(Database::"LT RMM Rec");
        F := RR.Field(R.FieldNo(En));
        RR.Reset();
        F.SetFilter('..D');
        Res := '';
        Observer.Observe('filter_open_hi_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('filter_open_hi_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        F.SetFilter('B..');
        Res := '';
        Observer.Observe('filter_open_lo_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('filter_open_lo_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        F.SetFilter('B|D');
        Res := '';
        Observer.Observe('filter_or_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('filter_or_max', Show(TryRefMax(F, Res), Res));
        RR.Reset();
        Res := '';
        Observer.Observe('nofilter_min', Show(TryRefMin(F, Res), Res));
        Res := '';
        Observer.Observe('nofilter_max', Show(TryRefMax(F, Res), Res));
        Observer.Expect('filter_open_hi_min', 'err:The filter "..D" on the En field in the LT RMM Rec table has no lower bound.|DB:Ok');
        Observer.Expect('filter_open_hi_max', 'ok:3');
        Observer.Expect('filter_open_lo_min', 'ok:1');
        Observer.Expect('filter_open_lo_max', 'err:The filter "B.." on the En field in the LT RMM Rec table has no upper bound.|DB:Ok');
        Observer.Expect('filter_or_min', 'err:The filter expression "B|D" applied to the field En in the LT RMM Rec table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('filter_or_max', 'err:The filter expression "B|D" applied to the field En in the LT RMM Rec table results in more than one range.|DB:NotIntervalFilter');
        Observer.Expect('nofilter_min', 'err:Specify a filter for the En field in the LT RMM Rec table.|DB:NoFilter');
        Observer.Expect('nofilter_max', 'err:Specify a filter for the En field in the LT RMM Rec table.|DB:NoFilter');
        Observer.Verify();
    end;
}
