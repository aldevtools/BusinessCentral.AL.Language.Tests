// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-deleteall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 72420, log codeunit 72421 (SingleInstance, used by test codeunit 72422 only)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: DeleteAll(true) over three rows when the OnDelete of one row deletes another: rows left, OnDelete calls and order, with Delete(false) and Delete(true) inside; DeleteAll(false) for contrast.
// BC versions: 29 (27 and 28 by CI)

table 72420 "LT DelAll Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Note; Text[20]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnDelete()
    var
        Other: Record "LT DelAll Row";
    begin
        Log.Hit(Id);
        if (Log.GetVictim() <> 0) and (Id = Log.GetKiller()) then
            if Other.Get(Log.GetVictim()) then
                Other.Delete(Log.GetRunTrigger());
    end;

    var
        Log: Codeunit "LT DelAll Log";
}

codeunit 72421 "LT DelAll Log"
{
    SingleInstance = true;

    var
        Calls: Text;
        CallCount: Integer;

    procedure Reset(KillerId: Integer; VictimId: Integer; WithTrigger: Boolean)
    begin
        Calls := '';
        CallCount := 0;
        Killer := KillerId;
        Victim := VictimId;
        RunTrigger := WithTrigger;
    end;

    procedure Hit(RowId: Integer)
    begin
        CallCount += 1;
        Calls += Format(RowId) + ';';
    end;

    procedure GetCalls(): Text
    begin
        exit(Calls);
    end;

    procedure GetKiller(): Integer
    begin
        exit(Killer);
    end;

    procedure GetVictim(): Integer
    begin
        exit(Victim);
    end;

    procedure GetRunTrigger(): Boolean
    begin
        exit(RunTrigger);
    end;

    procedure GetCount(): Integer
    begin
        exit(CallCount);
    end;

    var
        Killer: Integer;
        Victim: Integer;
        RunTrigger: Boolean;
}

codeunit 72422 "LT DelAll Skips Deleted"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT DelAll Row";
        i: Integer;
    begin
        R.DeleteAll();
        for i := 1 to 3 do begin
            R.Init();
            R.Id := i;
            R.Insert();
        end;
    end;

    local procedure ReportRows(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        R: Record "LT DelAll Row";
    begin
        Observer.Observe(Prefix + '_rows_left', Format(R.Count()));
        if R.FindSet() then
            repeat
                Observer.Observe(Prefix + '_left_' + Format(R.Id), 'yes');
            until R.Next() = 0;
    end;

    [Test]
    procedure DeleteAllTrue_FirstDeletesNext_NoTriggerInside()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT DelAll Log";
        R: Record "LT DelAll Row";
    begin
        Seed();
        Log.Reset(1, 2, false);
        R.DeleteAll(true);
        Observer.Observe('calls', Log.GetCalls());
        Observer.Observe('call_count', Format(Log.GetCount()));
        ReportRows(Observer, 'r');
        Observer.Expect('calls', '1;3;');
        Observer.Expect('call_count', '2');
        Observer.Expect('r_rows_left', '0');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteAllTrue_FirstDeletesNext_TriggerInside()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT DelAll Log";
        R: Record "LT DelAll Row";
    begin
        Seed();
        Log.Reset(1, 2, true);
        R.DeleteAll(true);
        Observer.Observe('calls', Log.GetCalls());
        Observer.Observe('call_count', Format(Log.GetCount()));
        ReportRows(Observer, 'r');
        Observer.Expect('calls', '1;2;3;');
        Observer.Expect('call_count', '3');
        Observer.Expect('r_rows_left', '0');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteAllTrue_FirstDeletesLast_NoTriggerInside()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT DelAll Log";
        R: Record "LT DelAll Row";
    begin
        Seed();
        Log.Reset(1, 3, false);
        R.DeleteAll(true);
        Observer.Observe('calls', Log.GetCalls());
        Observer.Observe('call_count', Format(Log.GetCount()));
        ReportRows(Observer, 'r');
        Observer.Expect('calls', '1;2;');
        Observer.Expect('call_count', '2');
        Observer.Expect('r_rows_left', '0');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteAllTrue_SecondDeletesThird()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT DelAll Log";
        R: Record "LT DelAll Row";
    begin
        Seed();
        Log.Reset(2, 3, false);
        R.DeleteAll(true);
        Observer.Observe('calls', Log.GetCalls());
        Observer.Observe('call_count', Format(Log.GetCount()));
        ReportRows(Observer, 'r');
        Observer.Expect('calls', '1;2;');
        Observer.Expect('call_count', '2');
        Observer.Expect('r_rows_left', '0');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteAllTrue_FirstDeletesAnEarlierSibling_NoneEarlier()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT DelAll Log";
        R: Record "LT DelAll Row";
    begin
        Seed();
        Log.Reset(3, 1, false);
        R.DeleteAll(true);
        Observer.Observe('calls', Log.GetCalls());
        Observer.Observe('call_count', Format(Log.GetCount()));
        ReportRows(Observer, 'r');
        Observer.Expect('calls', '1;2;3;');
        Observer.Expect('call_count', '3');
        Observer.Expect('r_rows_left', '0');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteAllTrue_NoVictim_AllVisited()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT DelAll Log";
        R: Record "LT DelAll Row";
    begin
        Seed();
        Log.Reset(0, 0, false);
        R.DeleteAll(true);
        Observer.Observe('calls', Log.GetCalls());
        Observer.Observe('call_count', Format(Log.GetCount()));
        ReportRows(Observer, 'r');
        Observer.Expect('calls', '1;2;3;');
        Observer.Expect('call_count', '3');
        Observer.Expect('r_rows_left', '0');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteAllFalse_NoTriggersRun()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT DelAll Log";
        R: Record "LT DelAll Row";
    begin
        Seed();
        Log.Reset(1, 2, false);
        R.DeleteAll(false);
        Observer.Observe('calls', Log.GetCalls());
        Observer.Observe('call_count', Format(Log.GetCount()));
        ReportRows(Observer, 'r');
        Observer.Expect('calls', '');
        Observer.Expect('call_count', '0');
        Observer.Expect('r_rows_left', '0');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteAllTrue_FilteredRange_VictimOutsideFilter()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT DelAll Log";
        R: Record "LT DelAll Row";
    begin
        Seed();
        Log.Reset(1, 3, false);
        R.SetFilter(Id, '1..2');
        R.DeleteAll(true);
        R.Reset();
        Observer.Observe('calls', Log.GetCalls());
        Observer.Observe('call_count', Format(Log.GetCount()));
        ReportRows(Observer, 'r');
        Observer.Expect('calls', '1;2;');
        Observer.Expect('call_count', '2');
        Observer.Expect('r_rows_left', '0');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteAllTrue_VictimDeletedWithTrigger_FilteredToTwo()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT DelAll Log";
        R: Record "LT DelAll Row";
    begin
        Seed();
        Log.Reset(1, 2, true);
        R.SetFilter(Id, '1..2');
        R.DeleteAll(true);
        R.Reset();
        Observer.Observe('calls', Log.GetCalls());
        Observer.Observe('call_count', Format(Log.GetCount()));
        ReportRows(Observer, 'r');
        Observer.Expect('calls', '1;2;');
        Observer.Expect('call_count', '2');
        Observer.Expect('r_rows_left', '1');
        Observer.Expect('r_left_3', 'yes');
        Observer.Verify();
    end;
}
