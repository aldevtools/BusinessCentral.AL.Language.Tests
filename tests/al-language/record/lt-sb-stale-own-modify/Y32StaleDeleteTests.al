// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-delete-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects in Y32StaleDeleteObjects.al; test codeunit 92335
// BC versions: 27+

/// <summary>
/// Writer Y32, AL Runner issue 6546 (follow-up to 6522, Y27StaleOtherVarTests.al, which pins the stale Modify). A stale Delete without
/// triggers or events follows the rule of a stale Modify (SbStaleOwnModify.al). Here the table has an OnDelete trigger and (when bound)
/// manual OnBeforeDeleteEvent and OnAfterDeleteEvent subscribers; the tests pin where the stale check falls among them.
/// The test inserts row A (Description Original, Quantity 100) through its own variable. N is the number of Commits since the Insert
/// (0 = no Commit at all; for N >= 2 the poster codeunit, another variable, lowers Quantity by 10 and commits N - 1 times). In the new
/// transaction the poster lowers Quantity by 5 once more (Other) or nothing happens (Nothing). Then the test calls Delete(true) or
/// Delete(false) on its own copy, with the subscribers bound (Sub) or not (NoSub); a Delete that fails runs under asserterror.
/// 'log' is the order in which the trigger and the events ran (kept in memory, an asserterror does not undo it); 'marks' the rows the
/// trigger and the subscribers inserted into the mark table (in the database), read after the Delete; 'stored' Description|Quantity of
/// row A read back, 'rows' the row count.
/// </summary>
codeunit 92335 "LT Y32 Stale Delete"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Poster: Codeunit "LT Y32 Stale Row Poster";
        DeleteLog: Codeunit "LT Y32 Delete Log";

    local procedure Y32InsertStale(var Row: Record "LT Y32 Stale Row"; Commits: Integer; OtherWrites: Boolean)
    var
        i: Integer;
    begin
        Y32Cleanup();
        Row.Init();
        Row."No." := 'A';
        Row.Description := 'Original';
        Row.Quantity := 100;
        Row.Insert(true);
        if Commits >= 1 then
            Commit();
        for i := 2 to Commits do
            Poster.PostAndCommit('A', 10);
        if OtherWrites then
            Poster.Post('A', 5);
        DeleteLog.Take();
    end;

    local procedure Y32ObserveAfter(var Observer: Codeunit "Probe Observer")
    var
        Stored: Record "LT Y32 Stale Row";
        DeleteMark: Record "LT Y32 Delete Mark";
        Marks: Text;
    begin
        Observer.Observe('log', DeleteLog.Take());
        if DeleteMark.FindSet() then
            repeat
                Marks += DeleteMark.What + ';';
            until DeleteMark.Next() = 0;
        Observer.Observe('marks', Marks);
        if Stored.Get('A') then
            Observer.Observe('stored', Stored.Description + '|' + Format(Stored.Quantity))
        else
            Observer.Observe('stored', 'missing');
        Observer.Observe('rows', Format(Stored.Count()));
        Y32Cleanup();
    end;

    local procedure Y32StaleDelete(var Row: Record "LT Y32 Stale Row"; RunTrigger: Boolean; Bound: Boolean; var Observer: Codeunit "Probe Observer")
    var
        Subscribers: Codeunit "LT Y32 Delete Subscribers";
    begin
        if Bound then
            BindSubscription(Subscribers);
        Row.Delete(RunTrigger);
        if Bound then
            UnbindSubscription(Subscribers);
        Observer.Observe('delete', 'ok');
        Y32ObserveAfter(Observer);
    end;

    local procedure Y32StaleDeleteError(var Row: Record "LT Y32 Stale Row"; RunTrigger: Boolean; Bound: Boolean; var Observer: Codeunit "Probe Observer")
    var
        Subscribers: Codeunit "LT Y32 Delete Subscribers";
    begin
        if Bound then
            BindSubscription(Subscribers);
        asserterror Row.Delete(RunTrigger);
        if Bound then
            UnbindSubscription(Subscribers);
        Observer.ObserveError('delete');
        Y32ObserveAfter(Observer);
    end;

    local procedure Y32Cleanup()
    var
        Rows: Record "LT Y32 Stale Row";
        DeleteMark: Record "LT Y32 Delete Mark";
    begin
        Rows.DeleteAll();
        DeleteMark.DeleteAll();
        Commit();
        DeleteLog.Take();
    end;

    [Test]
    procedure Y32_0C_Other_Sub_DeleteFalse()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 0, true);
        Y32StaleDelete(Row, false, true, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_0C_Other_Sub_DeleteTrue()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 0, true);
        Y32StaleDelete(Row, true, true, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_0C_Other_NoSub_DeleteFalse()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 0, true);
        Y32StaleDelete(Row, false, false, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_0C_Other_NoSub_DeleteTrue()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 0, true);
        Y32StaleDelete(Row, true, false, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_0C_Nothing_Sub_DeleteFalse()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 0, false);
        Y32StaleDelete(Row, false, true, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_0C_Nothing_Sub_DeleteTrue()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 0, false);
        Y32StaleDelete(Row, true, true, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_0C_Nothing_NoSub_DeleteFalse()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 0, false);
        Y32StaleDelete(Row, false, false, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_0C_Nothing_NoSub_DeleteTrue()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 0, false);
        Y32StaleDelete(Row, true, false, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_1C_Other_Sub_DeleteFalse()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 1, true);
        Y32StaleDelete(Row, false, true, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_1C_Other_Sub_DeleteTrue()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 1, true);
        Y32StaleDelete(Row, true, true, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_1C_Other_NoSub_DeleteFalse()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 1, true);
        Y32StaleDelete(Row, false, false, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_1C_Other_NoSub_DeleteTrue()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 1, true);
        Y32StaleDelete(Row, true, false, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_1C_Nothing_Sub_DeleteFalse()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 1, false);
        Y32StaleDeleteError(Row, false, true, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_1C_Nothing_Sub_DeleteTrue()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 1, false);
        Y32StaleDeleteError(Row, true, true, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_1C_Nothing_NoSub_DeleteFalse()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 1, false);
        Y32StaleDeleteError(Row, false, false, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_1C_Nothing_NoSub_DeleteTrue()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 1, false);
        Y32StaleDeleteError(Row, true, false, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_2C_Other_Sub_DeleteFalse()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 2, true);
        Y32StaleDelete(Row, false, true, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_2C_Other_Sub_DeleteTrue()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 2, true);
        Y32StaleDelete(Row, true, true, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_2C_Other_NoSub_DeleteFalse()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 2, true);
        Y32StaleDelete(Row, false, false, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_2C_Other_NoSub_DeleteTrue()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 2, true);
        Y32StaleDelete(Row, true, false, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_2C_Nothing_Sub_DeleteFalse()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 2, false);
        Y32StaleDeleteError(Row, false, true, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_2C_Nothing_Sub_DeleteTrue()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 2, false);
        Y32StaleDeleteError(Row, true, true, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_2C_Nothing_NoSub_DeleteFalse()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 2, false);
        Y32StaleDeleteError(Row, false, false, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_2C_Nothing_NoSub_DeleteTrue()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 2, false);
        Y32StaleDeleteError(Row, true, false, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_3C_Other_Sub_DeleteFalse()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 3, true);
        Y32StaleDelete(Row, false, true, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_3C_Other_Sub_DeleteTrue()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 3, true);
        Y32StaleDelete(Row, true, true, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_3C_Other_NoSub_DeleteFalse()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 3, true);
        Y32StaleDelete(Row, false, false, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_3C_Other_NoSub_DeleteTrue()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 3, true);
        Y32StaleDelete(Row, true, false, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_3C_Nothing_Sub_DeleteFalse()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 3, false);
        Y32StaleDeleteError(Row, false, true, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_3C_Nothing_Sub_DeleteTrue()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 3, false);
        Y32StaleDeleteError(Row, true, true, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_3C_Nothing_NoSub_DeleteFalse()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 3, false);
        Y32StaleDeleteError(Row, false, false, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y32_3C_Nothing_NoSub_DeleteTrue()
    var
        Row: Record "LT Y32 Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y32InsertStale(Row, 3, false);
        Y32StaleDeleteError(Row, true, false, Observer);
        Observer.Finish();
    end;
}
