// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-gettable-method
// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-settable-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Universal (60000)
// Purpose: Documents BC Cloud behavior of GetTable/SetTable — these methods link the
//          Record/RecordRef to a table but do NOT transfer field values through the buffer.
//          Correct usage requires a subsequent Get() or SetRange+FindFirst to load data.

codeunit 60200 "Test RecordRef GetSetTable"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── GetTable: field values are NOT copied into the Record variable ─────────────

    [Test]
    procedure RecordRef_GetTable_FieldValuesAreDefault_NoCopyFromBuffer()
    // CLAIM: After GetTable on a correctly positioned RecordRef (FindFirst returned true),
    //        the typed Record's field values remain at their defaults (0, '').
    //        GetTable does NOT copy the current RecordRef row into the Record buffer.
    var
        Rec: Record "ALT Universal";
        RecRef: RecordRef;
        RecCopy: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 42;
        Rec.Insert();

        RecRef.Open(60000);
        RecRef.Field(1).SetRange(1);
        Assert.IsTrue(RecRef.FindFirst(), 'RecordRef must find Entry No.=1 to confirm positioning');

        RecRef.GetTable(RecCopy);

        // GetTable links the Record to the same table but does NOT copy the positioned row's data.
        Assert.AreEqual(0, RecCopy."Integer Field", 'GetTable does NOT copy field values — Integer Field stays at default 0');
        RecRef.Close();
    end;

    // ── GetTable: correct usage pattern — follow with Record.Get() ────────────────

    [Test]
    procedure RecordRef_GetTable_RecordGetByPk_LoadsData()
    // CLAIM: Correct usage of GetTable is to follow it with Record.Get() using the known PK.
    //        GetTable links the Record to the table; Record.Get() loads the actual row.
    var
        Rec: Record "ALT Universal";
        RecRef: RecordRef;
        RecCopy: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 2;
        Rec."Integer Field" := 77;
        Rec."Text Field" := 'contract';
        Rec.Insert();

        RecRef.Open(60000);
        RecRef.Field(1).SetRange(2);
        Assert.IsTrue(RecRef.FindFirst(), 'RecordRef must find Entry No.=2');
        RecRef.GetTable(RecCopy);

        // Use Record.Get() after GetTable to load the actual record data.
        Assert.IsTrue(RecCopy.Get(2), 'After GetTable, Record.Get(2) must find the record');
        Assert.AreEqual(77, RecCopy."Integer Field", 'After GetTable + Get, Integer Field must be 77');
        Assert.AreEqual('contract', RecCopy."Text Field", 'After GetTable + Get, Text Field must match');
        RecRef.Close();
    end;

    // ── SetTable: Field().Value() returns 0 without a subsequent Find ─────────────

    [Test]
    procedure RecordRef_SetTable_FieldRef_ReturnsDefault_WithoutFind()
    // CLAIM: After SetTable(Rec), RecordRef.Field(n).Value() returns 0 (default) if no
    //        Find/FindFirst has been called. SetTable links the RecordRef to the table
    //        but does NOT populate the RecordRef buffer with Rec's field values.
    var
        Rec: Record "ALT Universal";
        RecRef: RecordRef;
    begin
        Initialize();
        Rec."Entry No." := 3;
        Rec."Integer Field" := 99;
        Rec.Insert();
        Rec.Get(3);

        RecRef.Open(60000);
        RecRef.SetTable(Rec);

        // SetTable does NOT copy Rec's field values into RecordRef's buffer.
        Assert.AreEqual(0, RecRef.Field(3).Value(), 'SetTable does NOT populate RecordRef buffer — Field(3) returns default 0 without Find');
        RecRef.Close();
    end;

    // ── SetTable: correct usage pattern — follow with SetRange + FindFirst ────────

    [Test]
    procedure RecordRef_SetTable_SetRangeFindFirst_LoadsData()
    // CLAIM: Correct usage of SetTable is to follow it with SetRange + FindFirst to position
    //        the RecordRef on the target row before reading Field().Value().
    var
        Rec: Record "ALT Universal";
        RecRef: RecordRef;
    begin
        Initialize();
        Rec."Entry No." := 4;
        Rec."Integer Field" := 55;
        Rec."Text Field" := 'linked';
        Rec.Insert();
        Rec.Get(4);

        RecRef.Open(60000);
        RecRef.SetTable(Rec);

        // Use SetRange + FindFirst after SetTable to position the RecordRef.
        RecRef.Field(1).SetRange(4);
        Assert.IsTrue(RecRef.FindFirst(), 'After SetTable, RecordRef must be able to find Entry No.=4');
        Assert.AreEqual(55, RecRef.Field(3).Value(), 'After SetTable + FindFirst, Integer Field must be 55');
        Assert.AreEqual('linked', RecRef.Field(6).Value(), 'After SetTable + FindFirst, Text Field must match');
        RecRef.Close();
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
