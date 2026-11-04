// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73894, codeunit 73895
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "Stale Modify" (Tests-SCM round 2)
// Facts: Modify, Commit, Modify, asserterror (the transaction rolls back to the Commit), Modify through the same buffer: does it succeed, what is stored; with Modify(true),
//   without the second write, with a buffer older than another variable's committed change and with a buffer whose other variable's write was rolled back
//   (each uncertain outcome is a pair of tests, _Succeeds and _Raises: the one that fails is dropped after the observation)
// BC versions: 29 (27 and 28 by CI)

table 73894 "LT PnF Stale Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73895 "LT PnF Stale Modify"

{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Prepare()
    var
        Row: Record "LT PnF Stale Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'start';
        Row.Insert();
        Commit();
    end;

    local procedure Cleanup()
    var
        Row: Record "LT PnF Stale Row";
    begin
        Row.DeleteAll();
        Commit();
    end;

    local procedure Stored(): Text
    var
        Row: Record "LT PnF Stale Row";
    begin
        if Row.Get(1) then
            exit(Row.Name + '|' + Format(Row.Qty));
        exit('missing');
    end;

    // Modify, Commit, Modify, rollback by asserterror, Modify through the same buffer. The two tests of a pair are the same steps; the one whose last Modify does not
    // behave as its name says fails and is dropped after the observation.
    local procedure RolledBackBuffer(var Row: Record "LT PnF Stale Row"; RunTrigger: Boolean; WithSecondWrite: Boolean; var Observer: Codeunit "Probe Observer")
    begin
        Prepare();
        Row.Get(1);
        Row.Name := 'm1';
        Row.Modify(RunTrigger);
        Commit();
        if WithSecondWrite then begin
            Row.Name := 'm2';
            Row.Modify(RunTrigger);
        end;
        asserterror Error('boom');
        Observer.ObserveError('boom');
        Observer.Observe('stored_after_rollback', Stored());
        Row.Name := 'm3';
    end;

    [Test]
    procedure StaleModify_AfterRollback_Succeeds()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF Stale Row";
    begin
        RolledBackBuffer(Row, false, true, Observer);
        Row.Modify();
        Observer.Observe('modify', 'ok');
        Observer.Observe('stored_after_modify', Stored());
        Cleanup();
        Observer.Expect('boom|text', 'boom');
        Observer.Expect('boom|code', 'Dialog');
        Observer.Expect('stored_after_rollback', 'm1|0');
        Observer.Expect('modify', 'ok');
        Observer.Expect('stored_after_modify', 'm3|0');
        Observer.Verify();
    end;

    [Test]
    procedure StaleModify_AfterRollback_Raises()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF Stale Row";
    begin
        RolledBackBuffer(Row, false, true, Observer);
        Row.Modify();
        Observer.Observe('modify', 'no error');
        Observer.Observe('stored_after_modify', Stored());
        Cleanup();
        Observer.Expect('boom|text', 'boom');
        Observer.Expect('boom|code', 'Dialog');
        Observer.Expect('stored_after_rollback', 'm1|0');
        Observer.Expect('modify', 'no error');
        Observer.Expect('stored_after_modify', 'm3|0');
        Observer.Verify();
    end;

    [Test]
    procedure StaleModify_AfterRollback_RunTrigger_Succeeds()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF Stale Row";
    begin
        RolledBackBuffer(Row, true, true, Observer);
        Row.Modify(true);
        Observer.Observe('modify', 'ok');
        Observer.Observe('stored_after_modify', Stored());
        Cleanup();
        Observer.Expect('boom|text', 'boom');
        Observer.Expect('boom|code', 'Dialog');
        Observer.Expect('stored_after_rollback', 'm1|0');
        Observer.Expect('modify', 'ok');
        Observer.Expect('stored_after_modify', 'm3|0');
        Observer.Verify();
    end;

    [Test]
    procedure StaleModify_AfterRollback_RunTrigger_Raises()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF Stale Row";
    begin
        RolledBackBuffer(Row, true, true, Observer);
        Row.Modify(true);
        Observer.Observe('modify', 'no error');
        Observer.Observe('stored_after_modify', Stored());
        Cleanup();
        Observer.Expect('boom|text', 'boom');
        Observer.Expect('boom|code', 'Dialog');
        Observer.Expect('stored_after_rollback', 'm1|0');
        Observer.Expect('modify', 'no error');
        Observer.Expect('stored_after_modify', 'm3|0');
        Observer.Verify();
    end;

    [Test]
    procedure StaleModify_NoSecondWrite_Succeeds()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF Stale Row";
    begin
        RolledBackBuffer(Row, false, false, Observer);
        Row.Modify();
        Observer.Observe('modify', 'ok');
        Observer.Observe('stored_after_modify', Stored());
        Cleanup();
        Observer.Expect('boom|text', 'boom');
        Observer.Expect('boom|code', 'Dialog');
        Observer.Expect('stored_after_rollback', 'm1|0');
        Observer.Expect('modify', 'ok');
        Observer.Expect('stored_after_modify', 'm3|0');
        Observer.Verify();
    end;

    [Test]
    procedure StaleModify_NoSecondWrite_Raises()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF Stale Row";
    begin
        RolledBackBuffer(Row, false, false, Observer);
        Row.Modify();
        Observer.Observe('modify', 'no error');
        Observer.Observe('stored_after_modify', Stored());
        Cleanup();
        Observer.Expect('boom|text', 'boom');
        Observer.Expect('boom|code', 'Dialog');
        Observer.Expect('stored_after_rollback', 'm1|0');
        Observer.Expect('modify', 'no error');
        Observer.Expect('stored_after_modify', 'm3|0');
        Observer.Verify();
    end;

    [Test]
    procedure StaleModify_BufferOlderThanCommittedChange()
    var
        Observer: Codeunit "Probe Observer";
        Old: Record "LT PnF Stale Row";
        Other: Record "LT PnF Stale Row";
    begin
        Prepare();
        Old.Get(1);
        Other.Get(1);
        Other.Qty := 5;
        Other.Modify();
        Commit();
        Old.Name := 'older';
        asserterror Old.Modify();
        Observer.ObserveError('modify_older_buffer');
        Observer.Observe('stored', Stored());
        Cleanup();
        Observer.Expect('modify_older_buffer|text', 'The changes to the LT PnF Stale Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Id=''1''');
        Observer.Expect('modify_older_buffer|code', 'DB:RecordChanged');
        Observer.Expect('stored', 'start|5');
        Observer.Verify();
    end;

    [Test]
    procedure StaleModify_OtherVariableRolledBack_Succeeds()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT PnF Stale Row";
        B: Record "LT PnF Stale Row";
    begin
        Prepare();
        A.Get(1);
        B.Get(1);
        B.Qty := 7;
        B.Modify();
        asserterror Error('boom');
        Observer.ObserveError('boom');
        A.Name := 'after';
        A.Modify();
        Observer.Observe('modify_a', 'ok');
        Observer.Observe('stored', Stored());
        Cleanup();
        Observer.Expect('boom|text', 'boom');
        Observer.Expect('boom|code', 'Dialog');
        Observer.Expect('modify_a', 'ok');
        Observer.Expect('stored', 'after|0');
        Observer.Verify();
    end;

    [Test]
    procedure StaleModify_OtherVariableRolledBack_Raises()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT PnF Stale Row";
        B: Record "LT PnF Stale Row";
    begin
        Prepare();
        A.Get(1);
        B.Get(1);
        B.Qty := 7;
        B.Modify();
        asserterror Error('boom');
        Observer.ObserveError('boom');
        A.Name := 'after';
        A.Modify();
        Observer.Observe('modify_a', 'no error');
        Observer.Observe('stored', Stored());
        Cleanup();
        Observer.Expect('boom|text', 'boom');
        Observer.Expect('boom|code', 'Dialog');
        Observer.Expect('modify_a', 'no error');
        Observer.Expect('stored', 'after|0');
        Observer.Verify();
    end;
}
