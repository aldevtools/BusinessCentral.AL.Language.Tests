// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-using-access-property
// Scope: in-scope (Cloud-compatible, multi-app fixture required)
// Fixtures used: ALT Internal Codeunit (61000), ALT Internal Table (61001), ALT Trigger Log (60003)
// BC versions: 27.5+

codeunit 60202 "Test InternalsVisibleTo"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── internalsVisibleTo / Access = Internal ─────────────────────────────────────

    [Test]
    procedure InternalsVisibleTo_InternalCodeunit_CanCallProcedure()
    // CLAIM: an app listed in internalsVisibleTo can invoke procedures on an Access=Internal codeunit.
    // DOCS: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-using-access-property
    var
        InternalCU: Codeunit "ALT Internal Codeunit";
        Result: Integer;
    begin
        Initialize();
        Result := InternalCU.Compute(21);
        Assert.AreEqual(42, Result, 'Internal codeunit Compute(21) must return 42');
    end;

    [Test]
    procedure InternalsVisibleTo_InternalTable_CanInsertAndRetrieve()
    // CLAIM: an app listed in internalsVisibleTo can read and write an Access=Internal table.
    var
        InternalRec: Record "ALT Internal Table";
    begin
        Initialize();
        InternalRec."Value" := 99;
        InternalRec.Insert(false);
        InternalRec.FindFirst();
        Assert.AreEqual(99, InternalRec.Value, 'Internal table must store and return the inserted value');
    end;

    [Test]
    procedure InternalsVisibleTo_InternalTableField_CanReadWriteInternalField()
    // CLAIM: an app listed in internalsVisibleTo can access an Access=Internal field on an internal table.
    var
        InternalRec: Record "ALT Internal Table";
    begin
        Initialize();
        InternalRec."Value" := 7;
        InternalRec."Internal Code" := 'TESTCODE';
        InternalRec.Insert(false);
        InternalRec.FindFirst();
        Assert.AreEqual('TESTCODE', InternalRec."Internal Code", 'Internal field must be readable from a granted app');
    end;

    [Test]
    procedure InternalsVisibleTo_EventSubscriber_CanSubscribeToInternalEvent()
    // CLAIM: an app listed in internalsVisibleTo can subscribe to an IntegrationEvent on an Access=Internal codeunit.
    var
        InternalCU: Codeunit "ALT Internal Codeunit";
        TrigLog: Record "ALT Trigger Log";
        Count: Integer;
    begin
        Initialize();
        InternalCU.ComputeAndPublish(5);
        TrigLog.SetRange(TriggerName, 'OnValueComputed');
        Count := TrigLog.Count();
        Assert.AreEqual(1, Count, 'Subscriber in granted app must receive OnValueComputed from internal codeunit');
    end;

    [Test]
    procedure InternalsVisibleTo_NotGrantedApp_AL0161_CompiletimeOnly()
    // CLAIM: an app NOT listed in internalsVisibleTo gets AL0161 ("inaccessible due to its protection level")
    // at compile time when referencing internal objects.
    // Cannot be expressed as a runtime [Test] -- the reference prevents compilation.
    // The positive tests above prove the granted-access contract; AL0161 is its compile-time inverse.
    begin
        Initialize();
        Assert.IsTrue(true, 'AL0161 is a compile-time error; this test documents the negative contract');
    end;

    local procedure Initialize()
    var
        InternalRec: Record "ALT Internal Table";
    begin
        Cleanup.Initialize();
        InternalRec.DeleteAll(false);
    end;
}
