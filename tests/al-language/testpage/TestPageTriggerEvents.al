// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-trigger-events
// Scope: in-scope
// Fixtures used: ALT Page Evt Row (60631), ALT Page Evt Rows (60632),
//                 ALT Page Evt Sub (60633), ALT Page Evt Manual Sub (60634),
//                 ALT Page Evt Veto Sub (60635), ALT Trigger Log (60003)
//
// The PAGE half of BC's platform trigger events. A table publishes OnBeforeInsertEvent /
// OnAfterModifyEvent and friends; a page publishes its own fixed set — OnOpenPageEvent,
// OnQueryClosePageEvent, OnClosePageEvent, OnAfterGetCurrRecordEvent, OnNewRecordEvent,
// OnInsertRecordEvent, OnModifyRecordEvent — subscribed with
// [EventSubscriber(ObjectType::Page, Page::"…", '<name>', '', false, false)].
//
// These are NOT the manually-declared [IntegrationEvent]s a page's own AL raises (those are
// TestManualObjectIntegrationEvent.al's subject). They are published by the platform from the
// page's lifecycle, alongside — and after — the page's own trigger of the same name.
//
// What each test pins: that the event fires at all, its ORDER relative to the page's own
// trigger, the values its Rec/xRec parameters carry, and that its Allow… var parameter is a
// real veto rather than an ignored out-parameter.
codeunit 60636 "Test Page Trigger Events"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ---------------------------------------------------------------- OnModifyRecordEvent

    [Test]
    procedure ModifyRecordEvent_PageDrivenSave_FiresOnceWithRecAndXRec()
    var
        Row: Record "ALT Page Evt Row";
        TrigLog: Record "ALT Trigger Log";
        Rows: TestPage "ALT Page Evt Rows";
    begin
        // [GIVEN] one existing row, and a page open on it
        Initialize();
        InsertRow('L1', 'BEFORE');
        Rows.OpenEdit();
        Rows.GoToKey('L1');

        // [WHEN] an action edits the current row and asks the page to save it
        Rows.DirectSave.Invoke();
        Rows.Close();

        // [THEN] the platform event fired exactly once
        TrigLog.SetRange(TriggerName, 'PageModifyEvt');
        Assert.RecordCount(TrigLog, 1);

        // [THEN] Rec carries the POST-edit value and xRec the PRE-edit value
        TrigLog.FindFirst();
        Assert.AreEqual('DIRECT', TrigLog.NewValue, 'Rec."Value" seen by OnModifyRecordEvent');
        Assert.AreEqual('BEFORE', TrigLog.OldValue, 'xRec."Value" seen by OnModifyRecordEvent');

        // [THEN] the row really was written
        Row.Get('L1');
        Assert.AreEqual('DIRECT', Row."Value", 'the row after a page-driven save');
    end;

    [Test]
    procedure ModifyRecordEvent_RunsAfterThePagesOwnOnModifyRecordTrigger()
    var
        TrigLog: Record "ALT Trigger Log";
        Rows: TestPage "ALT Page Evt Rows";
        TriggerEntryNo: Integer;
        EventEntryNo: Integer;
    begin
        // [GIVEN] a page whose own OnModifyRecord trigger logs, and a subscriber that logs
        Initialize();
        InsertRow('L1', 'BEFORE');
        Rows.OpenEdit();
        Rows.GoToKey('L1');

        // [WHEN] the row is saved through the page
        Rows.DirectSave.Invoke();
        Rows.Close();

        // [THEN] both ran
        TrigLog.SetRange(TriggerName, 'PageOnModifyTrig');
        Assert.IsTrue(TrigLog.FindFirst(), 'the page''s own OnModifyRecord trigger must run');
        TriggerEntryNo := TrigLog."Entry No.";

        TrigLog.SetRange(TriggerName, 'PageModifyEvt');
        Assert.IsTrue(TrigLog.FindFirst(), 'OnModifyRecordEvent must run');
        EventEntryNo := TrigLog."Entry No.";

        // [THEN] the page's own trigger ran FIRST — the event is the platform's last word
        Assert.IsTrue(TriggerEntryNo < EventEntryNo,
          'the page''s own OnModifyRecord trigger must run before OnModifyRecordEvent');
    end;

    [Test]
    procedure ModifyRecordEvent_CurrPageUpdateTrue_AlsoFires()
    var
        Row: Record "ALT Page Evt Row";
        TrigLog: Record "ALT Trigger Log";
        Rows: TestPage "ALT Page Evt Rows";
    begin
        // [GIVEN] a page open on an existing row
        Initialize();
        InsertRow('L1', 'BEFORE');
        Rows.OpenEdit();
        Rows.GoToKey('L1');

        // [WHEN] the action saves through CurrPage.Update(true) instead of CurrPage.SaveRecord()
        Rows.UpdateSave.Invoke();
        Rows.Close();

        // [THEN] the same event fired, with the same argument contract
        TrigLog.SetRange(TriggerName, 'PageModifyEvt');
        Assert.RecordCount(TrigLog, 1);
        TrigLog.FindFirst();
        Assert.AreEqual('UPDATED', TrigLog.NewValue, 'Rec."Value" seen by OnModifyRecordEvent');
        Assert.AreEqual('BEFORE', TrigLog.OldValue, 'xRec."Value" seen by OnModifyRecordEvent');

        Row.Get('L1');
        Assert.AreEqual('UPDATED', Row."Value", 'the row after CurrPage.Update(true)');
    end;

    [Test]
    procedure ModifyRecordEvent_ValueTypedIntoAControl_FiresOnSave()
    var
        Row: Record "ALT Page Evt Row";
        TrigLog: Record "ALT Trigger Log";
        Rows: TestPage "ALT Page Evt Rows";
    begin
        // [GIVEN] a page open on an existing row
        Initialize();
        InsertRow('L1', 'BEFORE');
        Rows.OpenEdit();
        Rows.GoToKey('L1');

        // [WHEN] a value is typed into a control and the page is closed (implicit save)
        Rows."Value".SetValue('TYPED');
        Rows.Close();

        // [THEN] the event fired for the write the close flushed
        TrigLog.SetRange(TriggerName, 'PageModifyEvt');
        Assert.RecordCount(TrigLog, 1);
        TrigLog.FindFirst();
        Assert.AreEqual('TYPED', TrigLog.NewValue, 'Rec."Value" seen by OnModifyRecordEvent');

        Row.Get('L1');
        Assert.AreEqual('TYPED', Row."Value", 'the row after a control write plus close');
    end;

    [Test]
    procedure ModifyRecordEvent_ManuallyBoundSubscriber_FiresOnlyWhileBound()
    var
        ManualSub: Codeunit "ALT Page Evt Manual Sub";
        TrigLog: Record "ALT Trigger Log";
        Rows: TestPage "ALT Page Evt Rows";
    begin
        // [GIVEN] an unbound Manual subscriber and a first page-driven save
        Initialize();
        InsertRow('L1', 'BEFORE');
        Rows.OpenEdit();
        Rows.GoToKey('L1');
        Rows.DirectSave.Invoke();

        // [THEN] the Manual subscriber did not see it
        TrigLog.SetRange(TriggerName, 'ManualPageModifyEvt');
        Assert.RecordIsEmpty(TrigLog);

        // [WHEN] it is bound and a second page-driven save happens
        BindSubscription(ManualSub);
        Rows."Value".SetValue('SECOND');
        Rows.Close();
        UnbindSubscription(ManualSub);

        // [THEN] the Manual subscriber saw exactly the second one
        TrigLog.SetRange(TriggerName, 'ManualPageModifyEvt');
        Assert.RecordCount(TrigLog, 1);
        TrigLog.FindFirst();
        Assert.AreEqual('SECOND', TrigLog.NewValue, 'Rec."Value" seen by the manually bound subscriber');
        Assert.AreEqual('DIRECT', TrigLog.OldValue, 'xRec."Value" seen by the manually bound subscriber');
    end;

    [Test]
    procedure ModifyRecordEvent_AllowModifyFalse_LeavesTheRowUnwritten()
    var
        VetoSub: Codeunit "ALT Page Evt Veto Sub";
        Row: Record "ALT Page Evt Row";
        TrigLog: Record "ALT Trigger Log";
        Rows: TestPage "ALT Page Evt Rows";
    begin
        // [GIVEN] a bound subscriber that answers AllowModify := false
        Initialize();
        InsertRow('L1', 'BEFORE');
        BindSubscription(VetoSub);
        Rows.OpenEdit();
        Rows.GoToKey('L1');

        // [WHEN] the page is asked to save the current row
        Rows.DirectSave.Invoke();
        Rows.Close();
        UnbindSubscription(VetoSub);

        // [THEN] the subscriber ran
        TrigLog.SetRange(TriggerName, 'VetoPageModifyEvt');
        Assert.RecordCount(TrigLog, 1);

        // [THEN] and the write did not happen — AllowModify is a veto, not an out-parameter
        Row.Get('L1');
        Assert.AreEqual('BEFORE', Row."Value", 'the row must be unchanged after AllowModify := false');
    end;

    // ---------------------------------------------------- OnNewRecordEvent / OnInsertRecordEvent

    [Test]
    procedure NewAndInsertRecordEvents_PageDrivenInsert_FireForTheKeyOnly()
    var
        Row: Record "ALT Page Evt Row";
        TrigLog: Record "ALT Trigger Log";
        Rows: TestPage "ALT Page Evt Rows";
    begin
        // [GIVEN] an empty page
        Initialize();
        Rows.OpenNew();

        // [WHEN] a new row's key is typed, then a second control, then the page is closed
        Rows."Code".SetValue('N1');
        Rows."Value".SetValue('NEW');
        Rows.Close();

        // [THEN] OnNewRecordEvent fired
        TrigLog.SetRange(TriggerName, 'PageNewEvt');
        Assert.RecordIsNotEmpty(TrigLog);

        // [THEN] OnInsertRecordEvent fired exactly once, and it saw the row as it stood when
        // the KEY was committed — the key set, the later control still blank. The insert is
        // not deferred until the row is finished.
        TrigLog.SetRange(TriggerName, 'PageInsertEvt');
        Assert.RecordCount(TrigLog, 1);
        TrigLog.FindFirst();
        Assert.AreEqual('N1', TrigLog.OldValue, 'Rec."Code" seen by OnInsertRecordEvent');
        Assert.AreEqual('', TrigLog.NewValue, 'Rec."Value" seen by OnInsertRecordEvent');

        // [THEN] the write to the second control is therefore a MODIFY, not part of the insert
        TrigLog.SetRange(TriggerName, 'PageModifyEvt');
        Assert.RecordCount(TrigLog, 1);
        TrigLog.FindFirst();
        Assert.AreEqual('NEW', TrigLog.NewValue, 'Rec."Value" seen by OnModifyRecordEvent');

        // [THEN] the finished row is on disk
        Assert.IsTrue(Row.Get('N1'), 'the page-driven insert must have written the row');
        Assert.AreEqual('NEW', Row."Value", 'the inserted row''s value');
    end;

    // ------------------------------------------- OnOpenPageEvent / OnQueryClosePageEvent /
    //                                             OnClosePageEvent / OnAfterGetCurrRecordEvent

    [Test]
    procedure OpenAndCloseEvents_FireAroundThePagesOwnLifecycleTriggers()
    var
        TrigLog: Record "ALT Trigger Log";
        Rows: TestPage "ALT Page Evt Rows";
        OpenTrigNo: Integer;
        OpenEvtNo: Integer;
        QueryCloseEvtNo: Integer;
        CloseEvtNo: Integer;
    begin
        // [GIVEN] one row so the page has a current record
        Initialize();
        InsertRow('L1', 'BEFORE');

        // [WHEN] the page is opened and closed, doing nothing else
        Rows.OpenEdit();
        Rows.GoToKey('L1');
        Rows.Close();

        // [THEN] OnOpenPageEvent fired, after the page's own OnOpenPage trigger
        TrigLog.SetRange(TriggerName, 'PageOnOpenTrig');
        Assert.IsTrue(TrigLog.FindFirst(), 'the page''s own OnOpenPage trigger must run');
        OpenTrigNo := TrigLog."Entry No.";
        TrigLog.SetRange(TriggerName, 'PageOpenEvt');
        Assert.IsTrue(TrigLog.FindFirst(), 'OnOpenPageEvent must run');
        OpenEvtNo := TrigLog."Entry No.";
        Assert.IsTrue(OpenTrigNo < OpenEvtNo,
          'the page''s own OnOpenPage trigger must run before OnOpenPageEvent');

        // [THEN] OnQueryClosePageEvent fired, and before OnClosePageEvent
        TrigLog.SetRange(TriggerName, 'PageQueryCloseEvt');
        Assert.IsTrue(TrigLog.FindFirst(), 'OnQueryClosePageEvent must run');
        QueryCloseEvtNo := TrigLog."Entry No.";
        TrigLog.SetRange(TriggerName, 'PageCloseEvt');
        Assert.IsTrue(TrigLog.FindFirst(), 'OnClosePageEvent must run');
        CloseEvtNo := TrigLog."Entry No.";
        Assert.IsTrue(QueryCloseEvtNo < CloseEvtNo,
          'OnQueryClosePageEvent must run before OnClosePageEvent');

        // [THEN] the open event came before both close events
        Assert.IsTrue(OpenEvtNo < QueryCloseEvtNo, 'OnOpenPageEvent must precede the close events');
    end;

    [Test]
    procedure AfterGetCurrRecordEvent_FiresAndNamesTheCurrentRow()
    var
        TrigLog: Record "ALT Trigger Log";
        Rows: TestPage "ALT Page Evt Rows";
    begin
        // [GIVEN] two rows
        Initialize();
        InsertRow('L1', 'ONE');
        InsertRow('L2', 'TWO');

        // [WHEN] the page is opened and navigated to the second row
        Rows.OpenEdit();
        Rows.GoToKey('L2');
        Rows.Close();

        // [THEN] OnAfterGetCurrRecordEvent fired naming that row
        TrigLog.SetRange(TriggerName, 'PageAfterGetCurrEvt');
        TrigLog.SetRange(NewValue, 'L2');
        Assert.RecordIsNotEmpty(TrigLog);
    end;

    // ---------------------------------------------------------------------------- helpers

    local procedure Initialize()
    var
        Row: Record "ALT Page Evt Row";
    begin
        Cleanup.Initialize();
        Row.DeleteAll(false);
        Commit();
    end;

    local procedure InsertRow(RowCode: Code[20]; RowValue: Text[50])
    var
        Row: Record "ALT Page Evt Row";
    begin
        Row.Init();
        Row."Code" := RowCode;
        Row."Value" := RowValue;
        Row.Insert(false);
        Commit();
    end;
}
