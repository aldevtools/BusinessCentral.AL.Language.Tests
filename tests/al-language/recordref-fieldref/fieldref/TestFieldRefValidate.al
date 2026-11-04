codeunit 60074 "Test FieldRef Validate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure FieldRef_Validate_WithNewValue_SetsField()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Triggered";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Name" := 'Test';
        Rec.Insert();

        RecRef.Open(60002);
        RecRef.FindFirst();
        FldRef := RecRef.Field(4);  // Watched Field
        FldRef.Validate('Hello');

        Assert.AreEqual('Hello', FldRef.Value(), 'Watched Field must equal Hello after Validate');
    end;

    [Test]
    procedure FieldRef_Validate_FiresOnValidate_TriggerLog()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
        InitialCount: Integer;
        FinalCount: Integer;
    begin
        Initialize();
        Rec."Entry No." := 2;
        Rec."Name" := 'Test';
        Rec.Insert();

        TrigLog.Reset();
        TrigLog.SetRange("TriggerName", 'OnValidate');
        TrigLog.SetRange("SourceEntryNo", 2);
        InitialCount := TrigLog.Count();

        RecRef.Open(60002);
        RecRef.FindFirst();
        FldRef := RecRef.Field(4);  // Watched Field
        FldRef.Validate('TestValue');

        TrigLog.Reset();
        TrigLog.SetRange("TriggerName", 'OnValidate');
        TrigLog.SetRange("SourceEntryNo", 2);
        FinalCount := TrigLog.Count();

        Assert.IsTrue(FinalCount > InitialCount, 'OnValidate trigger must fire and log entry');
    end;

    [Test]
    procedure FieldRef_Validate_WithoutValue_ValidatesExisting()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Triggered";
    begin
        Initialize();
        Rec."Entry No." := 3;
        Rec."Name" := 'Test';
        Rec."Watched Field" := 'Existing';
        Rec.Insert();

        RecRef.Open(60002);
        RecRef.FindFirst();
        FldRef := RecRef.Field(4);
        FldRef.Validate();  // No parameter

        Assert.AreEqual('Existing', FldRef.Value(), 'Watched Field must remain unchanged');
    end;

    [Test]
    procedure FieldRef_Validate_NewValueAppearsInTriggerLog()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
    begin
        Initialize();
        Rec."Entry No." := 4;
        Rec."Name" := 'Test';
        Rec.Insert();

        RecRef.Open(60002);
        RecRef.FindFirst();
        FldRef := RecRef.Field(4);
        FldRef.Validate('LoggedVal');

        TrigLog.Reset();
        TrigLog.SetRange("TriggerName", 'OnValidate');
        TrigLog.SetRange("SourceEntryNo", 4);
        if TrigLog.FindFirst() then
            Assert.AreEqual('LoggedVal', TrigLog."NewValue", 'LoggedVal must appear in trigger log')
        else
            Assert.Fail('OnValidate log entry must exist');
    end;

    [Test]
    procedure FieldRef_Validate_WatchedField_TriggerFires()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Rec: Record "ALT Triggered";
        TrigLog: Record "ALT Trigger Log";
        LogCount: Integer;
    begin
        Initialize();
        Rec."Entry No." := 5;
        Rec."Name" := 'Test';
        Rec.Insert();

        TrigLog.Reset();
        TrigLog.SetRange("SourceEntryNo", 5);
        TrigLog.SetRange("TriggerName", 'OnValidate');
        LogCount := TrigLog.Count();
        Assert.AreEqual(0, LogCount, 'No OnValidate logs before Validate call');

        RecRef.Open(60002);
        RecRef.FindFirst();
        FldRef := RecRef.Field(4);
        FldRef.Validate('X');

        TrigLog.Reset();
        TrigLog.SetRange("SourceEntryNo", 5);
        TrigLog.SetRange("TriggerName", 'OnValidate');
        LogCount := TrigLog.Count();
        Assert.AreEqual(1, LogCount, 'Exactly one OnValidate log must exist after Validate call');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
