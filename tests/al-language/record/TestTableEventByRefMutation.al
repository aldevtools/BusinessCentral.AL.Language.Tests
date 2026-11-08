// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
// Scope: in-scope
// Fixtures used: ALT Triggered (60002), ALT Trigger Log (60003), ALT Event Publisher (60014), ALT Table Event Subscriber (60016), ALT Event Mutation Control (60030), ALT Event Mutation Sub (60031)
// BC versions: 27.5+

codeunit 60237 "Test Event ByRef Mut"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        MutationControl: Codeunit "ALT Event Mutation Control";

    [Test]
    procedure CodeunitEvent_VarScalarMutation_VisibleToPublisher()
    var
        Publisher: Codeunit "ALT Event Publisher";
    begin
        Initialize();
        MutationControl.SetScenario('CODEUNIT-HANDLED');

        Assert.IsTrue(Publisher.TriggerBeforeAndReturnHandled(7001), 'Var scalar event parameters must allow subscriber mutation back to the publisher');
        MutationControl.ClearScenario(); // leave no scenario for the subscriber when other test codeunits fire these events
    end;

    [Test]
    procedure TableEvent_OnBeforeValidate_RecMutation_VisibleToCallerAndPersistable()
    var
        Triggered: Record "ALT Triggered";
    begin
        Initialize();
        MutationControl.SetScenario('BEFORE-VALIDATE-REC');

        Triggered."Entry No." := 7101;
        Triggered.Insert(false);
        Triggered.Get(7101);
        Triggered.Validate("Watched Field", 'Validated');

        Assert.AreEqual('BeforeValidateMutation', Triggered.Name, 'OnBeforeValidateEvent must be able to mutate Rec by reference');

        Triggered.Modify(false);
        Triggered.Get(7101);
        Assert.AreEqual('BeforeValidateMutation', Triggered.Name, 'Rec mutations from OnBeforeValidateEvent must remain persistable after Validate');
        MutationControl.ClearScenario(); // leave no scenario for the subscriber when other test codeunits fire these events
    end;

    [Test]
    procedure TableEvent_OnAfterValidate_RecMutation_VisibleToCallerAndPersistable()
    var
        Triggered: Record "ALT Triggered";
    begin
        Initialize();
        MutationControl.SetScenario('AFTER-VALIDATE-REC');

        Triggered."Entry No." := 7102;
        Triggered.Insert(false);
        Triggered.Get(7102);
        Triggered.Validate("Watched Field", 'Validated');

        Assert.AreEqual('AfterValidateMutation', Triggered.Name, 'OnAfterValidateEvent must be able to mutate Rec by reference');

        Triggered.Modify(false);
        Triggered.Get(7102);
        Assert.AreEqual('AfterValidateMutation', Triggered.Name, 'Rec mutations from OnAfterValidateEvent must remain persistable after Validate');
        MutationControl.ClearScenario(); // leave no scenario for the subscriber when other test codeunits fire these events
    end;

    [Test]
    procedure TableEvent_OnBeforeValidate_XRecMutation_VisibleToLaterSubscribers()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        MutationControl.SetScenario('BEFORE-VALIDATE-XREC');

        Triggered."Entry No." := 7103;
        Triggered."Watched Field" := 'Original';
        Triggered.Insert(false);
        Triggered.Get(7103);
        Triggered.Validate("Watched Field", 'Validated');

        FindLog(TrigLog, 'TableOnAfterValidate', 7103);
        Assert.AreEqual('XREC-BEFORE-VALIDATE', TrigLog."OldValue", 'xRec mutations must be visible to later validate subscribers');
        MutationControl.ClearScenario(); // leave no scenario for the subscriber when other test codeunits fire these events
    end;

    [Test]
    procedure TableEvent_OnBeforeInsert_RecMutation_PersistsToInsertedRecord()
    var
        Triggered: Record "ALT Triggered";
    begin
        Initialize();
        MutationControl.SetScenario('BEFORE-INSERT-REC');

        Triggered."Entry No." := 7104;
        Triggered.Insert(true);

        Triggered.Get(7104);
        Assert.AreEqual('BeforeInsertMutation', Triggered.Name, 'OnBeforeInsertEvent must be able to mutate the inserted record');
        MutationControl.ClearScenario(); // leave no scenario for the subscriber when other test codeunits fire these events
    end;

    [Test]
    procedure TableEvent_OnAfterInsert_RecMutation_VisibleToCaller()
    var
        Triggered: Record "ALT Triggered";
    begin
        Initialize();
        MutationControl.SetScenario('AFTER-INSERT-REC');

        Triggered."Entry No." := 7105;
        Triggered.Insert(true);

        Assert.AreEqual('AfterInsertMutation', Triggered.Name, 'OnAfterInsertEvent must be able to mutate the caller''s Rec variable');
        MutationControl.ClearScenario(); // leave no scenario for the subscriber when other test codeunits fire these events
    end;

    [Test]
    procedure TableEvent_OnBeforeModify_RecMutation_PersistsToStoredRecord()
    var
        Triggered: Record "ALT Triggered";
    begin
        Initialize();
        MutationControl.SetScenario('BEFORE-MODIFY-REC');

        Triggered."Entry No." := 7107;
        Triggered.Insert(false);
        Triggered.Get(7107);
        Triggered.Modify(true);

        Triggered.Get(7107);
        Assert.AreEqual('BeforeModifyMutation', Triggered.Name, 'OnBeforeModifyEvent must be able to mutate the modified record');
        MutationControl.ClearScenario(); // leave no scenario for the subscriber when other test codeunits fire these events
    end;

    [Test]
    procedure TableEvent_OnBeforeModify_XRecMutation_VisibleToLaterSubscribers()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        MutationControl.SetScenario('BEFORE-MODIFY-XREC');

        Triggered."Entry No." := 7108;
        Triggered.Value := 10;
        Triggered."Watched Field" := 'Original';
        Triggered.Insert(false);

        Triggered.Get(7108);
        Triggered.Value := 20;
        Triggered."Watched Field" := 'Updated';
        Triggered.Modify(true);

        FindLog(TrigLog, 'TableOnAfterModify', 7108);
        Assert.AreEqual(4242, TrigLog."OldIntegerValue", 'xRec integer mutations must be visible to later modify subscribers');
        Assert.AreEqual('XREC-BEFORE-MODIFY', TrigLog."OldValue", 'xRec text mutations must be visible to later modify subscribers');
        MutationControl.ClearScenario(); // leave no scenario for the subscriber when other test codeunits fire these events
    end;

    [Test]
    procedure TableEvent_OnAfterModify_RecMutation_VisibleToCaller()
    var
        Triggered: Record "ALT Triggered";
    begin
        Initialize();
        MutationControl.SetScenario('AFTER-MODIFY-REC');

        Triggered."Entry No." := 7110;
        Triggered.Insert(false);
        Triggered.Get(7110);
        Triggered.Modify(true);

        Assert.AreEqual('AfterModifyMutation', Triggered.Name, 'OnAfterModifyEvent must be able to mutate the caller''s Rec variable');
        MutationControl.ClearScenario(); // leave no scenario for the subscriber when other test codeunits fire these events
    end;

    [Test]
    procedure TableEvent_OnBeforeDelete_RecMutation_VisibleToLaterSubscribers()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        MutationControl.SetScenario('BEFORE-DELETE-REC');

        Triggered."Entry No." := 7111;
        Triggered.Value := 1;
        Triggered."Watched Field" := 'OriginalDelete';
        Triggered.Insert(false);
        ClearLog();

        Triggered.Get(7111);
        Triggered.Delete(true);

        FindLog(TrigLog, 'TableOnAfterDelete', 7111);
        Assert.AreEqual(5151, TrigLog."NewIntegerValue", 'OnBeforeDeleteEvent Rec mutations must be visible to later delete subscribers');
        Assert.AreEqual('BeforeDeleteMutation', TrigLog."NewValue", 'OnBeforeDeleteEvent Rec text mutations must be visible to later delete subscribers');
        MutationControl.ClearScenario(); // leave no scenario for the subscriber when other test codeunits fire these events
    end;

    [Test]
    procedure TableEvent_OnAfterDelete_RecMutation_VisibleToCaller()
    var
        Triggered: Record "ALT Triggered";
    begin
        Initialize();
        MutationControl.SetScenario('AFTER-DELETE-REC');

        Triggered."Entry No." := 7112;
        Triggered.Insert(false);
        Triggered.Get(7112);
        Triggered.Delete(true);

        Assert.AreEqual(5252, Triggered.Value, 'OnAfterDeleteEvent must be able to mutate the caller''s Rec variable');
        MutationControl.ClearScenario(); // leave no scenario for the subscriber when other test codeunits fire these events
    end;

    [Test]
    procedure TableEvent_OnBeforeRename_RecMutation_PersistsToRenamedRecord()
    var
        Triggered: Record "ALT Triggered";
    begin
        Initialize();
        MutationControl.SetScenario('BEFORE-RENAME-REC');

        Triggered."Entry No." := 7114;
        Triggered.Insert(false);
        Triggered.Get(7114);
        Triggered.Rename(8114);

        Triggered.Get(8114);
        Assert.AreEqual('BeforeRenameMutation', Triggered.Name, 'OnBeforeRenameEvent must be able to mutate the renamed record');
        MutationControl.ClearScenario(); // leave no scenario for the subscriber when other test codeunits fire these events
    end;

    [Test]
    procedure TableEvent_OnBeforeRename_XRecMutation_VisibleToLaterSubscribers()
    var
        Triggered: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        MutationControl.SetScenario('BEFORE-RENAME-XREC');

        Triggered."Entry No." := 7115;
        Triggered.Value := 15;
        Triggered.Insert(false);
        ClearLog();

        Triggered.Get(7115);
        Triggered.Rename(8115);

        TrigLog.SetRange("TriggerName", 'TableOnAfterRename');
        TrigLog.SetRange("OldEntryNo", 7115);
        Assert.IsTrue(TrigLog.FindFirst(), 'OnAfterRename subscriber log must exist');
        Assert.AreEqual(6262, TrigLog."OldIntegerValue", 'xRec mutations must be visible to later rename subscribers');
        MutationControl.ClearScenario(); // leave no scenario for the subscriber when other test codeunits fire these events
    end;

    [Test]
    procedure TableEvent_OnAfterRename_RecMutation_VisibleToCaller()
    var
        Triggered: Record "ALT Triggered";
    begin
        Initialize();
        MutationControl.SetScenario('AFTER-RENAME-REC');

        Triggered."Entry No." := 7117;
        Triggered.Insert(false);
        Triggered.Get(7117);
        Triggered.Rename(8117);

        Assert.AreEqual('AfterRenameMutation', Triggered.Name, 'OnAfterRenameEvent must be able to mutate the caller''s Rec variable');
        MutationControl.ClearScenario(); // leave no scenario for the subscriber when other test codeunits fire these events
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
        MutationControl.ClearScenario();
    end;

    local procedure ClearLog()
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.DeleteAll(false);
    end;

    local procedure FindLog(var TrigLog: Record "ALT Trigger Log"; TriggerName: Code[30]; SourceEntryNo: Integer)
    begin
        TrigLog.SetRange("TriggerName", TriggerName);
        TrigLog.SetRange("SourceEntryNo", SourceEntryNo);
        Assert.IsTrue(TrigLog.FindFirst(), StrSubstNo('%1 subscriber log must exist for %2', TriggerName, SourceEntryNo));
    end;
}
