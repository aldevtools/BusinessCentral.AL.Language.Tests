// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-bindsubscription-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); OVB Doc (table 75730, OptionVarMembersCallee.al); own objects 75740..75742
//   (OVB Manual Batch Mgt, OVB Manual Post Mgt, OVB Manual Batch Tests)
// local object: an Option carried through memberless var parameters and an integration event into a var parameter with
//   members, when the subscriber sits in a codeunit with EventSubscriberInstance = Manual, is what is under test.
// Probe (al-runner issue 8971): the batch shape of OptionVarMembersBatch.al, but with the document side in a codeunit with
//   EventSubscriberInstance = Manual, the way Base Application's batch posting of documents binds it. The batch entry
//   commits and calls Run on a fresh instance; its OnRun binds another fresh instance with BindSubscription, runs the batch
//   through it and unbinds it after. Event path: the bound subscriber gets the processor's local " ",Skip,Update through a
//   memberless var parameter, as in OptionVarMembersBatch.al. Queued path: one more integration event (no Option parameter);
//   its bound subscriber runs a loop that hands a memberless local per row to the same local procedure.
//   Neighbors: bound in a procedure without Run; bound by the test itself; bound and unbound again before the batch raises;
//   never bound; the queued loop called directly. Three rows; the first row is confirmed or declined.
// Facts: values are Format|ordinal. Run returns true. Every bound shape gives the same answers as the automatic subscriber of
//   OptionVarMembersBatch.al: event path Update|2 / Skip|1 at every hop, queued path 2|2 / 1|1. Unbound before the raise and
//   never bound: no subscriber runs; the processor's local stays at the blank member ( |0), the rows stay empty.
// BC versions: measured on 29.0 (local BC on Linux). 27.5 and 28.5: the corpus CI run of the pull request.
// The batch processor: the same shape as "OVB Batch Mgt" (75737), with its own events so that the automatic subscriber of
// "OVB Batch Post Mgt" (75738) does not run here. Event path: a local with the members " ",Skip,Update, handed per row to a
// memberless var parameter, which hands it on to an integration event (IncludeSender) with a memberless var parameter.
// Queued path: one integration event per batch without an Option parameter; its subscriber runs the queued loop.
codeunit 75740 "OVB Manual Batch Mgt"
{
    procedure RunBatch(Queued: Boolean): Text
    var
        RecRef: RecordRef;
        Choice: Option " ",Skip,Update;
        Log: Text;
    begin
        RecRef.Open(Database::"OVB Doc");
        if Queued then begin
            OnProcessInBackground(RecRef, Log);
            RecRef.Close();
            exit(Log);
        end;
        if RecRef.FindSet() then
            repeat
                Log += ProcessOne(RecRef, Choice) + ';';
            until RecRef.Next() = 0;
        RecRef.Close();
        exit(Log + 'end ' + Format(Choice) + '|' + Format(Choice, 0, 2));
    end;

    local procedure ProcessOne(var RecRef: RecordRef; var Choice: Option): Text
    begin
        OnBeforeProcessOne(RecRef, Choice);
        RecRef.Modify();
        exit(Format(Choice) + '|' + Format(Choice, 0, 2));
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeProcessOne(var RecRef: RecordRef; var Choice: Option)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnProcessInBackground(var RecRef: RecordRef; var Log: Text)
    begin
    end;
}

// The document side, with EventSubscriberInstance = Manual. OnRun binds a fresh instance of itself, runs the batch through
// that instance and unbinds it. The subscriber hands its memberless var parameter to a local procedure with a memberless var
// parameter, which calls the table procedure (parameter with members " ",Skip,Update). The queued subscriber runs RunQueued:
// a memberless local handed per row to the same local procedure.
codeunit 75741 "OVB Manual Post Mgt"
{
    EventSubscriberInstance = Manual;
    TableNo = "OVB Doc";

    trigger OnRun()
    var
        Bound: Codeunit "OVB Manual Post Mgt";
    begin
        BindSubscription(Bound);
        Bound.SetQueued(Queued);
        Bound.Code();
        RunLog := Bound.GetRunLog();
        UnbindSubscription(Bound);
    end;

    var
        BatchMgt: Codeunit "OVB Manual Batch Mgt";
        Queued: Boolean;
        RunLog: Text;

    procedure SetQueued(NewQueued: Boolean)
    begin
        Queued := NewQueued;
    end;

    procedure GetRunLog(): Text
    begin
        exit(RunLog);
    end;

    procedure "Code"()
    begin
        RunLog := BatchMgt.RunBatch(Queued);
    end;

    // The entry of the batch: Commit, then Run on a fresh instance (whose OnRun binds), with the result of Run.
    procedure RunBatchEntry(NewQueued: Boolean): Text
    var
        Doc: Record "OVB Doc";
        PostMgt: Codeunit "OVB Manual Post Mgt";
        Ok: Boolean;
    begin
        PostMgt.SetQueued(NewQueued);
        Commit();
        Ok := PostMgt.Run(Doc);
        exit(Format(Ok) + ' ' + PostMgt.GetRunLog());
    end;

    // Binds a fresh instance of itself in a procedure (no Run), runs the batch, unbinds.
    procedure RunBound(NewQueued: Boolean): Text
    var
        Bound: Codeunit "OVB Manual Post Mgt";
        Log: Text;
    begin
        BindSubscription(Bound);
        Log := BatchMgt.RunBatch(NewQueued);
        UnbindSubscription(Bound);
        exit(Log);
    end;

    // Binds a fresh instance of itself and unbinds it again before the batch raises its events.
    procedure RunUnbindBeforeRaise(NewQueued: Boolean): Text
    var
        Bound: Codeunit "OVB Manual Post Mgt";
    begin
        BindSubscription(Bound);
        UnbindSubscription(Bound);
        exit(BatchMgt.RunBatch(NewQueued));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"OVB Manual Batch Mgt", 'OnBeforeProcessOne', '', false, false)]
    local procedure PrepareOnBeforeProcessOne(var RecRef: RecordRef; var Choice: Option)
    var
        Doc: Record "OVB Doc";
    begin
        RecRef.SetTable(Doc);
        PrepareDoc(Doc, Choice);
        RecRef.GetTable(Doc);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"OVB Manual Batch Mgt", 'OnProcessInBackground', '', false, false)]
    local procedure QueueOnProcessInBackground(var RecRef: RecordRef; var Log: Text)
    begin
        Log := RunQueued();
    end;

    local procedure PrepareDoc(var Doc: Record "OVB Doc"; var Choice: Option)
    begin
        Doc.SeenText := CopyStr(Doc.ConfirmOnce(Choice), 1, MaxStrLen(Doc.SeenText));
        Doc.AfterText := CopyStr(Format(Choice) + '|' + Format(Choice, 0, 2), 1, MaxStrLen(Doc.AfterText));
    end;

    procedure RunQueued(): Text
    var
        Doc: Record "OVB Doc";
        Choice: Option;
    begin
        if Doc.FindSet() then
            repeat
                PrepareDoc(Doc, Choice);
                Doc.Modify();
            until Doc.Next() = 0;
        exit(Format(Choice) + '|' + Format(Choice, 0, 2));
    end;
}

codeunit 75742 "OVB Manual Batch Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ManualRun_Confirmed()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        BatchMgt: Codeunit "OVB Manual Batch Mgt";
        PostMgt: Codeunit "OVB Manual Post Mgt";
    begin
        Doc.DeleteAll();
        AddRow(1, true);
        AddRow(2, false);
        AddRow(3, false);
        Observer.Observe('run', PostMgt.RunBatchEntry(false));
        Doc.Get(1);
        Observer.Observe('row 1 inside', Doc.SeenText);
        Observer.Observe('row 1 after', Doc.AfterText);
        Doc.Get(2);
        Observer.Observe('row 2 inside', Doc.SeenText);
        Observer.Observe('row 2 after', Doc.AfterText);
        Doc.Get(3);
        Observer.Observe('row 3 inside', Doc.SeenText);
        Observer.Observe('row 3 after', Doc.AfterText);
        Observer.Expect('run', 'Yes Update|2;Update|2;Update|2;end Update|2');
        Observer.Expect('row 1 inside', 'blank');
        Observer.Expect('row 1 after', 'Update|2');
        Observer.Expect('row 2 inside', 'update');
        Observer.Expect('row 2 after', 'Update|2');
        Observer.Expect('row 3 inside', 'update');
        Observer.Expect('row 3 after', 'Update|2');
        Observer.Verify();
    end;

    [Test]
    procedure ManualRun_Declined()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        BatchMgt: Codeunit "OVB Manual Batch Mgt";
        PostMgt: Codeunit "OVB Manual Post Mgt";
    begin
        Doc.DeleteAll();
        AddRow(1, false);
        AddRow(2, false);
        AddRow(3, false);
        Observer.Observe('run', PostMgt.RunBatchEntry(false));
        Doc.Get(1);
        Observer.Observe('row 1 inside', Doc.SeenText);
        Observer.Observe('row 1 after', Doc.AfterText);
        Doc.Get(2);
        Observer.Observe('row 2 inside', Doc.SeenText);
        Observer.Observe('row 2 after', Doc.AfterText);
        Doc.Get(3);
        Observer.Observe('row 3 inside', Doc.SeenText);
        Observer.Observe('row 3 after', Doc.AfterText);
        Observer.Expect('run', 'Yes Skip|1;Skip|1;Skip|1;end Skip|1');
        Observer.Expect('row 1 inside', 'blank');
        Observer.Expect('row 1 after', 'Skip|1');
        Observer.Expect('row 2 inside', 'skip-exit');
        Observer.Expect('row 2 after', 'Skip|1');
        Observer.Expect('row 3 inside', 'skip-exit');
        Observer.Expect('row 3 after', 'Skip|1');
        Observer.Verify();
    end;

    [Test]
    procedure ManualRunQueued_Confirmed()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        BatchMgt: Codeunit "OVB Manual Batch Mgt";
        PostMgt: Codeunit "OVB Manual Post Mgt";
    begin
        Doc.DeleteAll();
        AddRow(1, true);
        AddRow(2, false);
        AddRow(3, false);
        Observer.Observe('run', PostMgt.RunBatchEntry(true));
        Doc.Get(1);
        Observer.Observe('row 1 inside', Doc.SeenText);
        Observer.Observe('row 1 after', Doc.AfterText);
        Doc.Get(2);
        Observer.Observe('row 2 inside', Doc.SeenText);
        Observer.Observe('row 2 after', Doc.AfterText);
        Doc.Get(3);
        Observer.Observe('row 3 inside', Doc.SeenText);
        Observer.Observe('row 3 after', Doc.AfterText);
        Observer.Expect('run', 'Yes 2|2');
        Observer.Expect('row 1 inside', 'blank');
        Observer.Expect('row 1 after', '2|2');
        Observer.Expect('row 2 inside', 'update');
        Observer.Expect('row 2 after', '2|2');
        Observer.Expect('row 3 inside', 'update');
        Observer.Expect('row 3 after', '2|2');
        Observer.Verify();
    end;

    [Test]
    procedure ManualRunQueued_Declined()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        BatchMgt: Codeunit "OVB Manual Batch Mgt";
        PostMgt: Codeunit "OVB Manual Post Mgt";
    begin
        Doc.DeleteAll();
        AddRow(1, false);
        AddRow(2, false);
        AddRow(3, false);
        Observer.Observe('run', PostMgt.RunBatchEntry(true));
        Doc.Get(1);
        Observer.Observe('row 1 inside', Doc.SeenText);
        Observer.Observe('row 1 after', Doc.AfterText);
        Doc.Get(2);
        Observer.Observe('row 2 inside', Doc.SeenText);
        Observer.Observe('row 2 after', Doc.AfterText);
        Doc.Get(3);
        Observer.Observe('row 3 inside', Doc.SeenText);
        Observer.Observe('row 3 after', Doc.AfterText);
        Observer.Expect('run', 'Yes 1|1');
        Observer.Expect('row 1 inside', 'blank');
        Observer.Expect('row 1 after', '1|1');
        Observer.Expect('row 2 inside', 'skip-exit');
        Observer.Expect('row 2 after', '1|1');
        Observer.Expect('row 3 inside', 'skip-exit');
        Observer.Expect('row 3 after', '1|1');
        Observer.Verify();
    end;

    [Test]
    procedure ManualBound_Confirmed()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        BatchMgt: Codeunit "OVB Manual Batch Mgt";
        PostMgt: Codeunit "OVB Manual Post Mgt";
    begin
        Doc.DeleteAll();
        AddRow(1, true);
        AddRow(2, false);
        AddRow(3, false);
        Observer.Observe('run', PostMgt.RunBound(false));
        Doc.Get(1);
        Observer.Observe('row 1 inside', Doc.SeenText);
        Observer.Observe('row 1 after', Doc.AfterText);
        Doc.Get(2);
        Observer.Observe('row 2 inside', Doc.SeenText);
        Observer.Observe('row 2 after', Doc.AfterText);
        Doc.Get(3);
        Observer.Observe('row 3 inside', Doc.SeenText);
        Observer.Observe('row 3 after', Doc.AfterText);
        Observer.Expect('run', 'Update|2;Update|2;Update|2;end Update|2');
        Observer.Expect('row 1 inside', 'blank');
        Observer.Expect('row 1 after', 'Update|2');
        Observer.Expect('row 2 inside', 'update');
        Observer.Expect('row 2 after', 'Update|2');
        Observer.Expect('row 3 inside', 'update');
        Observer.Expect('row 3 after', 'Update|2');
        Observer.Verify();
    end;

    [Test]
    procedure ManualBound_Declined()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        BatchMgt: Codeunit "OVB Manual Batch Mgt";
        PostMgt: Codeunit "OVB Manual Post Mgt";
    begin
        Doc.DeleteAll();
        AddRow(1, false);
        AddRow(2, false);
        AddRow(3, false);
        Observer.Observe('run', PostMgt.RunBound(false));
        Doc.Get(1);
        Observer.Observe('row 1 inside', Doc.SeenText);
        Observer.Observe('row 1 after', Doc.AfterText);
        Doc.Get(2);
        Observer.Observe('row 2 inside', Doc.SeenText);
        Observer.Observe('row 2 after', Doc.AfterText);
        Doc.Get(3);
        Observer.Observe('row 3 inside', Doc.SeenText);
        Observer.Observe('row 3 after', Doc.AfterText);
        Observer.Expect('run', 'Skip|1;Skip|1;Skip|1;end Skip|1');
        Observer.Expect('row 1 inside', 'blank');
        Observer.Expect('row 1 after', 'Skip|1');
        Observer.Expect('row 2 inside', 'skip-exit');
        Observer.Expect('row 2 after', 'Skip|1');
        Observer.Expect('row 3 inside', 'skip-exit');
        Observer.Expect('row 3 after', 'Skip|1');
        Observer.Verify();
    end;

    [Test]
    procedure ManualBoundQueued_Confirmed()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        BatchMgt: Codeunit "OVB Manual Batch Mgt";
        PostMgt: Codeunit "OVB Manual Post Mgt";
    begin
        Doc.DeleteAll();
        AddRow(1, true);
        AddRow(2, false);
        AddRow(3, false);
        Observer.Observe('run', PostMgt.RunBound(true));
        Doc.Get(1);
        Observer.Observe('row 1 inside', Doc.SeenText);
        Observer.Observe('row 1 after', Doc.AfterText);
        Doc.Get(2);
        Observer.Observe('row 2 inside', Doc.SeenText);
        Observer.Observe('row 2 after', Doc.AfterText);
        Doc.Get(3);
        Observer.Observe('row 3 inside', Doc.SeenText);
        Observer.Observe('row 3 after', Doc.AfterText);
        Observer.Expect('run', '2|2');
        Observer.Expect('row 1 inside', 'blank');
        Observer.Expect('row 1 after', '2|2');
        Observer.Expect('row 2 inside', 'update');
        Observer.Expect('row 2 after', '2|2');
        Observer.Expect('row 3 inside', 'update');
        Observer.Expect('row 3 after', '2|2');
        Observer.Verify();
    end;

    [Test]
    procedure ManualBoundQueued_Declined()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        BatchMgt: Codeunit "OVB Manual Batch Mgt";
        PostMgt: Codeunit "OVB Manual Post Mgt";
    begin
        Doc.DeleteAll();
        AddRow(1, false);
        AddRow(2, false);
        AddRow(3, false);
        Observer.Observe('run', PostMgt.RunBound(true));
        Doc.Get(1);
        Observer.Observe('row 1 inside', Doc.SeenText);
        Observer.Observe('row 1 after', Doc.AfterText);
        Doc.Get(2);
        Observer.Observe('row 2 inside', Doc.SeenText);
        Observer.Observe('row 2 after', Doc.AfterText);
        Doc.Get(3);
        Observer.Observe('row 3 inside', Doc.SeenText);
        Observer.Observe('row 3 after', Doc.AfterText);
        Observer.Expect('run', '1|1');
        Observer.Expect('row 1 inside', 'blank');
        Observer.Expect('row 1 after', '1|1');
        Observer.Expect('row 2 inside', 'skip-exit');
        Observer.Expect('row 2 after', '1|1');
        Observer.Expect('row 3 inside', 'skip-exit');
        Observer.Expect('row 3 after', '1|1');
        Observer.Verify();
    end;

    [Test]
    procedure ManualTestBound_Confirmed()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        BatchMgt: Codeunit "OVB Manual Batch Mgt";
        PostMgt: Codeunit "OVB Manual Post Mgt";
        Log: Text;
    begin
        Doc.DeleteAll();
        AddRow(1, true);
        AddRow(2, false);
        AddRow(3, false);
        BindSubscription(PostMgt);
        Log := BatchMgt.RunBatch(false);
        UnbindSubscription(PostMgt);
        Observer.Observe('run', Log);
        Doc.Get(1);
        Observer.Observe('row 1 inside', Doc.SeenText);
        Observer.Observe('row 1 after', Doc.AfterText);
        Doc.Get(2);
        Observer.Observe('row 2 inside', Doc.SeenText);
        Observer.Observe('row 2 after', Doc.AfterText);
        Doc.Get(3);
        Observer.Observe('row 3 inside', Doc.SeenText);
        Observer.Observe('row 3 after', Doc.AfterText);
        Observer.Expect('run', 'Update|2;Update|2;Update|2;end Update|2');
        Observer.Expect('row 1 inside', 'blank');
        Observer.Expect('row 1 after', 'Update|2');
        Observer.Expect('row 2 inside', 'update');
        Observer.Expect('row 2 after', 'Update|2');
        Observer.Expect('row 3 inside', 'update');
        Observer.Expect('row 3 after', 'Update|2');
        Observer.Verify();
    end;

    [Test]
    procedure ManualTestBound_Declined()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        BatchMgt: Codeunit "OVB Manual Batch Mgt";
        PostMgt: Codeunit "OVB Manual Post Mgt";
        Log: Text;
    begin
        Doc.DeleteAll();
        AddRow(1, false);
        AddRow(2, false);
        AddRow(3, false);
        BindSubscription(PostMgt);
        Log := BatchMgt.RunBatch(false);
        UnbindSubscription(PostMgt);
        Observer.Observe('run', Log);
        Doc.Get(1);
        Observer.Observe('row 1 inside', Doc.SeenText);
        Observer.Observe('row 1 after', Doc.AfterText);
        Doc.Get(2);
        Observer.Observe('row 2 inside', Doc.SeenText);
        Observer.Observe('row 2 after', Doc.AfterText);
        Doc.Get(3);
        Observer.Observe('row 3 inside', Doc.SeenText);
        Observer.Observe('row 3 after', Doc.AfterText);
        Observer.Expect('run', 'Skip|1;Skip|1;Skip|1;end Skip|1');
        Observer.Expect('row 1 inside', 'blank');
        Observer.Expect('row 1 after', 'Skip|1');
        Observer.Expect('row 2 inside', 'skip-exit');
        Observer.Expect('row 2 after', 'Skip|1');
        Observer.Expect('row 3 inside', 'skip-exit');
        Observer.Expect('row 3 after', 'Skip|1');
        Observer.Verify();
    end;

    [Test]
    procedure ManualUnbound_Confirmed()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        BatchMgt: Codeunit "OVB Manual Batch Mgt";
        PostMgt: Codeunit "OVB Manual Post Mgt";
    begin
        Doc.DeleteAll();
        AddRow(1, true);
        AddRow(2, false);
        AddRow(3, false);
        Observer.Observe('run', PostMgt.RunUnbindBeforeRaise(false));
        Doc.Get(1);
        Observer.Observe('row 1 inside', Doc.SeenText);
        Observer.Observe('row 1 after', Doc.AfterText);
        Doc.Get(2);
        Observer.Observe('row 2 inside', Doc.SeenText);
        Observer.Observe('row 2 after', Doc.AfterText);
        Doc.Get(3);
        Observer.Observe('row 3 inside', Doc.SeenText);
        Observer.Observe('row 3 after', Doc.AfterText);
        Observer.Expect('run', ' |0; |0; |0;end  |0');
        Observer.Expect('row 1 inside', '');
        Observer.Expect('row 1 after', '');
        Observer.Expect('row 2 inside', '');
        Observer.Expect('row 2 after', '');
        Observer.Expect('row 3 inside', '');
        Observer.Expect('row 3 after', '');
        Observer.Verify();
    end;

    [Test]
    procedure ManualUnbound_Declined()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        BatchMgt: Codeunit "OVB Manual Batch Mgt";
        PostMgt: Codeunit "OVB Manual Post Mgt";
    begin
        Doc.DeleteAll();
        AddRow(1, false);
        AddRow(2, false);
        AddRow(3, false);
        Observer.Observe('run', PostMgt.RunUnbindBeforeRaise(false));
        Doc.Get(1);
        Observer.Observe('row 1 inside', Doc.SeenText);
        Observer.Observe('row 1 after', Doc.AfterText);
        Doc.Get(2);
        Observer.Observe('row 2 inside', Doc.SeenText);
        Observer.Observe('row 2 after', Doc.AfterText);
        Doc.Get(3);
        Observer.Observe('row 3 inside', Doc.SeenText);
        Observer.Observe('row 3 after', Doc.AfterText);
        Observer.Expect('run', ' |0; |0; |0;end  |0');
        Observer.Expect('row 1 inside', '');
        Observer.Expect('row 1 after', '');
        Observer.Expect('row 2 inside', '');
        Observer.Expect('row 2 after', '');
        Observer.Expect('row 3 inside', '');
        Observer.Expect('row 3 after', '');
        Observer.Verify();
    end;

    [Test]
    procedure ManualUnboundQueued_Confirmed()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        BatchMgt: Codeunit "OVB Manual Batch Mgt";
        PostMgt: Codeunit "OVB Manual Post Mgt";
    begin
        Doc.DeleteAll();
        AddRow(1, true);
        AddRow(2, false);
        AddRow(3, false);
        Observer.Observe('run', PostMgt.RunUnbindBeforeRaise(true));
        Doc.Get(1);
        Observer.Observe('row 1 inside', Doc.SeenText);
        Observer.Observe('row 1 after', Doc.AfterText);
        Doc.Get(2);
        Observer.Observe('row 2 inside', Doc.SeenText);
        Observer.Observe('row 2 after', Doc.AfterText);
        Doc.Get(3);
        Observer.Observe('row 3 inside', Doc.SeenText);
        Observer.Observe('row 3 after', Doc.AfterText);
        Observer.Expect('run', '');
        Observer.Expect('row 1 inside', '');
        Observer.Expect('row 1 after', '');
        Observer.Expect('row 2 inside', '');
        Observer.Expect('row 2 after', '');
        Observer.Expect('row 3 inside', '');
        Observer.Expect('row 3 after', '');
        Observer.Verify();
    end;

    [Test]
    procedure ManualUnboundQueued_Declined()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        BatchMgt: Codeunit "OVB Manual Batch Mgt";
        PostMgt: Codeunit "OVB Manual Post Mgt";
    begin
        Doc.DeleteAll();
        AddRow(1, false);
        AddRow(2, false);
        AddRow(3, false);
        Observer.Observe('run', PostMgt.RunUnbindBeforeRaise(true));
        Doc.Get(1);
        Observer.Observe('row 1 inside', Doc.SeenText);
        Observer.Observe('row 1 after', Doc.AfterText);
        Doc.Get(2);
        Observer.Observe('row 2 inside', Doc.SeenText);
        Observer.Observe('row 2 after', Doc.AfterText);
        Doc.Get(3);
        Observer.Observe('row 3 inside', Doc.SeenText);
        Observer.Observe('row 3 after', Doc.AfterText);
        Observer.Expect('run', '');
        Observer.Expect('row 1 inside', '');
        Observer.Expect('row 1 after', '');
        Observer.Expect('row 2 inside', '');
        Observer.Expect('row 2 after', '');
        Observer.Expect('row 3 inside', '');
        Observer.Expect('row 3 after', '');
        Observer.Verify();
    end;

    [Test]
    procedure ManualNeverBound_Confirmed()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        BatchMgt: Codeunit "OVB Manual Batch Mgt";
        PostMgt: Codeunit "OVB Manual Post Mgt";
    begin
        Doc.DeleteAll();
        AddRow(1, true);
        AddRow(2, false);
        AddRow(3, false);
        Observer.Observe('run', BatchMgt.RunBatch(false));
        Doc.Get(1);
        Observer.Observe('row 1 inside', Doc.SeenText);
        Observer.Observe('row 1 after', Doc.AfterText);
        Doc.Get(2);
        Observer.Observe('row 2 inside', Doc.SeenText);
        Observer.Observe('row 2 after', Doc.AfterText);
        Doc.Get(3);
        Observer.Observe('row 3 inside', Doc.SeenText);
        Observer.Observe('row 3 after', Doc.AfterText);
        Observer.Expect('run', ' |0; |0; |0;end  |0');
        Observer.Expect('row 1 inside', '');
        Observer.Expect('row 1 after', '');
        Observer.Expect('row 2 inside', '');
        Observer.Expect('row 2 after', '');
        Observer.Expect('row 3 inside', '');
        Observer.Expect('row 3 after', '');
        Observer.Verify();
    end;

    [Test]
    procedure ManualNeverBound_Declined()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        BatchMgt: Codeunit "OVB Manual Batch Mgt";
        PostMgt: Codeunit "OVB Manual Post Mgt";
    begin
        Doc.DeleteAll();
        AddRow(1, false);
        AddRow(2, false);
        AddRow(3, false);
        Observer.Observe('run', BatchMgt.RunBatch(false));
        Doc.Get(1);
        Observer.Observe('row 1 inside', Doc.SeenText);
        Observer.Observe('row 1 after', Doc.AfterText);
        Doc.Get(2);
        Observer.Observe('row 2 inside', Doc.SeenText);
        Observer.Observe('row 2 after', Doc.AfterText);
        Doc.Get(3);
        Observer.Observe('row 3 inside', Doc.SeenText);
        Observer.Observe('row 3 after', Doc.AfterText);
        Observer.Expect('run', ' |0; |0; |0;end  |0');
        Observer.Expect('row 1 inside', '');
        Observer.Expect('row 1 after', '');
        Observer.Expect('row 2 inside', '');
        Observer.Expect('row 2 after', '');
        Observer.Expect('row 3 inside', '');
        Observer.Expect('row 3 after', '');
        Observer.Verify();
    end;

    [Test]
    procedure ManualNeverBoundQueued_Confirmed()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        BatchMgt: Codeunit "OVB Manual Batch Mgt";
        PostMgt: Codeunit "OVB Manual Post Mgt";
    begin
        Doc.DeleteAll();
        AddRow(1, true);
        AddRow(2, false);
        AddRow(3, false);
        Observer.Observe('run', BatchMgt.RunBatch(true));
        Doc.Get(1);
        Observer.Observe('row 1 inside', Doc.SeenText);
        Observer.Observe('row 1 after', Doc.AfterText);
        Doc.Get(2);
        Observer.Observe('row 2 inside', Doc.SeenText);
        Observer.Observe('row 2 after', Doc.AfterText);
        Doc.Get(3);
        Observer.Observe('row 3 inside', Doc.SeenText);
        Observer.Observe('row 3 after', Doc.AfterText);
        Observer.Expect('run', '');
        Observer.Expect('row 1 inside', '');
        Observer.Expect('row 1 after', '');
        Observer.Expect('row 2 inside', '');
        Observer.Expect('row 2 after', '');
        Observer.Expect('row 3 inside', '');
        Observer.Expect('row 3 after', '');
        Observer.Verify();
    end;

    [Test]
    procedure ManualNeverBoundQueued_Declined()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        BatchMgt: Codeunit "OVB Manual Batch Mgt";
        PostMgt: Codeunit "OVB Manual Post Mgt";
    begin
        Doc.DeleteAll();
        AddRow(1, false);
        AddRow(2, false);
        AddRow(3, false);
        Observer.Observe('run', BatchMgt.RunBatch(true));
        Doc.Get(1);
        Observer.Observe('row 1 inside', Doc.SeenText);
        Observer.Observe('row 1 after', Doc.AfterText);
        Doc.Get(2);
        Observer.Observe('row 2 inside', Doc.SeenText);
        Observer.Observe('row 2 after', Doc.AfterText);
        Doc.Get(3);
        Observer.Observe('row 3 inside', Doc.SeenText);
        Observer.Observe('row 3 after', Doc.AfterText);
        Observer.Expect('run', '');
        Observer.Expect('row 1 inside', '');
        Observer.Expect('row 1 after', '');
        Observer.Expect('row 2 inside', '');
        Observer.Expect('row 2 after', '');
        Observer.Expect('row 3 inside', '');
        Observer.Expect('row 3 after', '');
        Observer.Verify();
    end;

    [Test]
    procedure ManualQueuedDirect_Confirmed()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        BatchMgt: Codeunit "OVB Manual Batch Mgt";
        PostMgt: Codeunit "OVB Manual Post Mgt";
    begin
        Doc.DeleteAll();
        AddRow(1, true);
        AddRow(2, false);
        AddRow(3, false);
        Observer.Observe('run', PostMgt.RunQueued());
        Doc.Get(1);
        Observer.Observe('row 1 inside', Doc.SeenText);
        Observer.Observe('row 1 after', Doc.AfterText);
        Doc.Get(2);
        Observer.Observe('row 2 inside', Doc.SeenText);
        Observer.Observe('row 2 after', Doc.AfterText);
        Doc.Get(3);
        Observer.Observe('row 3 inside', Doc.SeenText);
        Observer.Observe('row 3 after', Doc.AfterText);
        Observer.Expect('run', '2|2');
        Observer.Expect('row 1 inside', 'blank');
        Observer.Expect('row 1 after', '2|2');
        Observer.Expect('row 2 inside', 'update');
        Observer.Expect('row 2 after', '2|2');
        Observer.Expect('row 3 inside', 'update');
        Observer.Expect('row 3 after', '2|2');
        Observer.Verify();
    end;

    [Test]
    procedure ManualQueuedDirect_Declined()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "OVB Doc";
        BatchMgt: Codeunit "OVB Manual Batch Mgt";
        PostMgt: Codeunit "OVB Manual Post Mgt";
    begin
        Doc.DeleteAll();
        AddRow(1, false);
        AddRow(2, false);
        AddRow(3, false);
        Observer.Observe('run', PostMgt.RunQueued());
        Doc.Get(1);
        Observer.Observe('row 1 inside', Doc.SeenText);
        Observer.Observe('row 1 after', Doc.AfterText);
        Doc.Get(2);
        Observer.Observe('row 2 inside', Doc.SeenText);
        Observer.Observe('row 2 after', Doc.AfterText);
        Doc.Get(3);
        Observer.Observe('row 3 inside', Doc.SeenText);
        Observer.Observe('row 3 after', Doc.AfterText);
        Observer.Expect('run', '1|1');
        Observer.Expect('row 1 inside', 'blank');
        Observer.Expect('row 1 after', '1|1');
        Observer.Expect('row 2 inside', 'skip-exit');
        Observer.Expect('row 2 after', '1|1');
        Observer.Expect('row 3 inside', 'skip-exit');
        Observer.Expect('row 3 after', '1|1');
        Observer.Verify();
    end;

    local procedure AddRow(NewId: Integer; NewConfirmed: Boolean)
    var
        Doc: Record "OVB Doc";
    begin
        Doc.Init();
        Doc.Id := NewId;
        Doc.Confirmed := NewConfirmed;
        Doc.Insert();
    end;
}
