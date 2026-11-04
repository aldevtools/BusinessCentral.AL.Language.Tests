// Batch 7 probes: query variables, OnBeforeOpen with statements, DataAccessIntent, AboutTitle and AboutText on a query. Observe only.
codeunit 68513 "W7 Query Procedures"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeedFour()
    var
        Seed: Codeunit "W7 Q Seed";
    begin
        Seed.Clear();
        Seed.Row(1, 10, 'T1', 1, 'A');
        Seed.Row(2, 20, 'T2', 2, 'A');
        Seed.Row(3, 30, 'T3', 3, 'B');
        Seed.Row(4, 40, 'T4', 4, 'B');
    end;

    local procedure Drain(var Q: Query "W7 Q Vars"): Text
    var
        Result: Text;
    begin
        while Q.Read() do
            Result += Format(Q.Entry) + ',';
        exit(Result);
    end;

    [Test]
    procedure QueryVariables_LiveAsLongAsTheQueryVariable()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "W7 Q Vars";
        Other: Query "W7 Q Vars";
    begin
        Observer.Observe('first bump', Format(Q.Bump()));
        Observer.Observe('second bump', Format(Q.Bump()));
        Observer.Observe('other variable bump', Format(Other.Bump()));
        Clear(Q);
        Observer.Observe('bump after clear', Format(Q.Bump()));
        Observer.Observe('bump again', Format(Q.Bump()));
        Observer.Expect('first bump', '1');
        Observer.Expect('second bump', '2');
        Observer.Expect('other variable bump', '1');
        Observer.Expect('bump after clear', '1');
        Observer.Expect('bump again', '2');
        Observer.Verify();
    end;

    [Test]
    procedure QueryVariables_AcrossOpenAndClose()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "W7 Q Vars";
    begin
        SeedFour();
        Observer.Observe('bump before open', Format(Q.Bump()));
        Q.Open();
        Observer.Observe('bump while open', Format(Q.Bump()));
        Observer.Observe('rows', Drain(Q));
        Q.Close();
        Observer.Observe('bump after close', Format(Q.Bump()));
        Q.Open();
        Observer.Observe('bump after second open', Format(Q.Bump()));
        Q.Close();
        Observer.Observe('runs of OnBeforeOpen', Format(Q.Runs()));
        Observer.Expect('bump before open', '1');
        Observer.Expect('bump while open', '2');
        Observer.Expect('rows', '1,2,3,4,');
        Observer.Expect('bump after close', '3');
        Observer.Expect('bump after second open', '4');
        Observer.Expect('runs of OnBeforeOpen', '2');
        Observer.Verify();
    end;

    [Test]
    procedure OnBeforeOpen_RunsInsideOpen_AfterTheFiltersSoFar()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "W7 Q Vars";
    begin
        SeedFour();
        Observer.Observe('runs before open', Format(Q.Runs()));
        Q.Open();
        Observer.Observe('runs right after open', Format(Q.Runs()));
        Observer.Observe('rows without a filter', Drain(Q));
        Q.Close();
        Observer.Observe('runs after close', Format(Q.Runs()));

        Clear(Q);
        Q.SetFilterInTrigger(true);
        Q.Open();
        Observer.Observe('runs after open with trigger filter', Format(Q.Runs()));
        Observer.Observe('rows with the filter set by the trigger', Drain(Q));
        Observer.Observe('get filters', Q.GetFilters());
        Q.Close();

        Clear(Q);
        Q.SetFilterInTrigger(true);
        Q.SetRange(Entry, 3, 4);
        Q.Open();
        Observer.Observe('rows with caller range 3..4 and trigger range 2', Drain(Q));
        Observer.Observe('get filters then', Q.GetFilters());
        Q.Close();
        Q.Open();
        Observer.Observe('rows after close and open', Drain(Q));
        Observer.Observe('runs', Format(Q.Runs()));
        Q.Close();
        Observer.Expect('runs before open', '0');
        Observer.Expect('runs right after open', '1');
        Observer.Expect('rows without a filter', '1,2,3,4,');
        Observer.Expect('runs after close', '1');
        Observer.Expect('runs after open with trigger filter', '1');
        Observer.Expect('rows with the filter set by the trigger', '2,');
        Observer.Expect('get filters', 'Entry: 2');
        Observer.Expect('rows with caller range 3..4 and trigger range 2', '2,');
        Observer.Expect('get filters then', 'Entry: 2');
        Observer.Expect('rows after close and open', '2,');
        Observer.Expect('runs', '2');
        Observer.Verify();
    end;

    [Test]
    procedure QueryProperties_AboutTitleAndAboutText_RowsAreTheSame()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "W7 Q About";
        Result: Text;
    begin
        SeedFour();
        Q.Open();
        while Q.Read() do
            Result += Format(Q.Entry) + ':' + Q.Txt + ' ';
        Q.Close();
        Observer.Observe('rows', Result);
        Observer.Expect('rows', '1:T1 2:T2 3:T3 4:T4 ');
        Observer.Verify();
    end;
}
