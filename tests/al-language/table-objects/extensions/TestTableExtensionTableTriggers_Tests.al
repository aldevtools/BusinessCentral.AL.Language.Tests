// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
// Scope: in-scope
// Fixtures used: TXT Row (60428), TXT Log (60429), TXT Row Ext (60430), TXT Owned (60431),
//                TXT Owned Ext (60432), Assert (60021)
//
// What a tableextension's table triggers do on a real write through AL. "TXT Row" declares
// none of them, so every entry TXT Log holds came from the extension. Each arm asserts the
// whole ordered trace, so a trigger that runs twice, or in the wrong order, fails too.

codeunit 60433 "TXT Table Trigger Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure ClearLog()
    var
        LogRec: Record "TXT Log";
    begin
        LogRec.DeleteAll();
    end;

    local procedure Trace(): Text
    var
        LogRec: Record "TXT Log";
        Result: Text;
    begin
        if LogRec.FindSet() then
            repeat
                if Result <> '' then
                    Result += ',';
                Result += LogRec."Trigger Name";
            until LogRec.Next() = 0;
        exit(Result);
    end;

    // Positive: both insert triggers a tableextension declares run, in BC's order, on a base
    // table that declares no OnInsert of its own.
    [Test]
    procedure TableextensionInsertTriggersRunOnATableThatDeclaresNone()
    var
        Row: Record "TXT Row";
    begin
        Row.DeleteAll();
        ClearLog();

        Row.Init();
        Row."No." := 'A1';
        Row.Insert(true);

        Assert.AreEqual('OnBeforeInsert,OnAfterInsert', Trace(),
          'the tableextension''s OnBeforeInsert and OnAfterInsert must both run, in that order, on Insert(true)');
    end;

    // Positive: the modify pair, same shape.
    [Test]
    procedure TableextensionModifyTriggersRunOnATableThatDeclaresNone()
    var
        Row: Record "TXT Row";
    begin
        Row.DeleteAll();

        Row.Init();
        Row."No." := 'B1';
        Row.Insert(true);
        ClearLog();

        Row.Payload := 7;
        Row.Modify(true);

        Assert.AreEqual('OnBeforeModify,OnAfterModify', Trace(),
          'the tableextension''s OnBeforeModify and OnAfterModify must both run, in that order, on Modify(true)');
    end;

    // Positive: the delete pair, same shape.
    [Test]
    procedure TableextensionDeleteTriggersRunOnATableThatDeclaresNone()
    var
        Row: Record "TXT Row";
    begin
        Row.DeleteAll();

        Row.Init();
        Row."No." := 'C1';
        Row.Insert(true);
        ClearLog();

        Row.Delete(true);

        Assert.AreEqual('OnBeforeDelete,OnAfterDelete', Trace(),
          'the tableextension''s OnBeforeDelete and OnAfterDelete must both run, in that order, on Delete(true)');
    end;

    // Positive: the rename pair. Rename always runs the triggers; it takes no run-trigger flag.
    [Test]
    procedure TableextensionRenameTriggersRunOnATableThatDeclaresNone()
    var
        Row: Record "TXT Row";
    begin
        Row.DeleteAll();

        Row.Init();
        Row."No." := 'D1';
        Row.Insert(true);
        ClearLog();

        Row.Rename('D2');

        Assert.AreEqual('OnBeforeRename,OnAfterRename', Trace(),
          'the tableextension''s OnBeforeRename and OnAfterRename must both run, in that order, on Rename');
    end;

    // Positive on ORDER, which "it ran at some point" cannot see: the extension's
    // OnBeforeInsert precedes the base table's own OnInsert, and OnAfterInsert follows it.
    [Test]
    procedure TableextensionInsertTriggersBracketTheBaseTablesOwnOnInsert()
    var
        Owned: Record "TXT Owned";
    begin
        Owned.DeleteAll();
        ClearLog();

        Owned.Init();
        Owned."No." := 'E1';
        Owned.Insert(true);

        Assert.AreEqual('ExtOnBeforeInsert,BaseOnInsert,ExtOnAfterInsert', Trace(),
          'the tableextension''s OnBeforeInsert must run before the base table''s OnInsert and its OnAfterInsert after it');
    end;

    // Negative: Insert(false) asks for no triggers, so the extension gets none either. An
    // implementation that ran extension triggers unconditionally would pass every arm above
    // and fail this one.
    [Test]
    procedure TableextensionInsertTriggersDoNotRunWhenInsertSuppressesTriggers()
    var
        Row: Record "TXT Row";
    begin
        Row.DeleteAll();
        ClearLog();

        Row.Init();
        Row."No." := 'F1';
        Row.Insert(false);

        Assert.AreEqual('', Trace(),
          'Insert(false) must run no tableextension trigger at all');
    end;

    // ── Added by writer bs (corpus issue #668, item 98): objects in tableextension/lt-bs-tableext-leads/BsObjects.al ──

    [Test]
    procedure TableExt_Procedure_RecIsTheExtendedRow_PassedOnAndXRec()
    // CLAIM (issue #668 item 98): inside a procedure of a tableextension, Rec is the current row of the extended table: passing it to a
    // codeunit's var Record parameter shows that row's values, a var array parameter is filled from it, and in the extension's
    // OnAfterModify xRec holds the stored row and Rec the new values.
    var
        Observer: Codeunit "Probe Observer";
        Base: Record "LT BS Base";
        Log: Codeunit "LT BS Ext Log";
        Arr: array[3] of Text;
    begin
        Base.DeleteAll();
        Log.Take();
        Base.Init();
        Base.Id := 5;
        Base.Name := 'before';
        Base.E1 := 9;
        Base.Insert();
        Base.Name := 'unsaved';
        Observer.Observe('rec_to_codeunit', Base.BsRecToSink());
        Base.BsFillArray(Arr);
        Observer.Observe('var_array', Arr[1] + '|' + Arr[2] + '|' + Arr[3]);
        Base.Get(5);
        Base.Name := 'after';
        Base.Modify(true);
        Observer.Observe('xrec_in_ext_trigger', Log.Take());
        Base.DeleteAll();
        Observer.Expect('rec_to_codeunit', '5:unsaved:9');
        Observer.Expect('var_array', 'unsaved|5|base:5');
        Observer.Expect('xrec_in_ext_trigger', 'after modify xRec=after Rec=after');
        Observer.Verify();
    end;
}
