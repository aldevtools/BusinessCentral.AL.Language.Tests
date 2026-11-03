// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-gettable-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Universal (60000)
// BC versions: 27.0+
//
// CLAIM UNDER TEST: RecordRef.GetTable accepts a Variant that holds a Record, binds the reference
// to that record's table AND copies the boxed record's current field values into the reference
// buffer — Field().Value() returns the boxed row's values with no Find. (This differs from
// GetTable into a fresh output Record, which reads the reference rather than filling it.) The
// table identity survives SetTable -> Variant -> GetTable.
//
// The copy is of the boxed record's buffer, not a read of the stored row: a value assigned but
// never Modified is what the reference returns.
//
// Measured on W1 sandboxes BC 27.0 (27.0.38460.56409), 28.5 (28.5.54151.56408) and 29.0
// (29.0.54011.55816): every assertion holds unchanged on all three, so no version guard.
//
// This pins the Variant overload of GetTable that the test harness itself relies on
// (Assert.RecordIsEmpty(Variant) does RecRef.GetTable(RecVariant)).

codeunit 69501 "Test RecRef Variant GetTable"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure GetTableFromVariant_BindsTable_FindLoadsRow()
    // CLAIM: GetTable from a Variant binds the table; SetRange + FindFirst then reads the row.
    var
        Rec: Record "ALT Universal";
        RecRef: RecordRef;
        V: Variant;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Integer Field" := 42;
        Rec."Text Field" := 'via variant';
        Rec.Insert();

        V := Rec;
        RecRef.GetTable(V);

        Assert.AreEqual(Database::"ALT Universal", RecRef.Number(), 'GetTable(Variant) must bind the reference to ALT Universal');
        RecRef.Field(1).SetRange(1);
        Assert.IsTrue(RecRef.FindFirst(), 'after GetTable(Variant) a Find must position on the inserted row');
        Assert.AreEqual(42, RecRef.Field(3).Value(), 'Integer Field must read back after Find');
        Assert.AreEqual('via variant', RecRef.Field(6).Value(), 'Text Field must read back after Find');
        RecRef.Close();
    end;

    [Test]
    procedure GetTableFromVariant_CopiesPositionedRow()
    // CLAIM: GetTable(Variant) copies the boxed record's current field values — Field().Value()
    //        returns them with no Find.
    var
        Rec: Record "ALT Universal";
        RecRef: RecordRef;
        V: Variant;
    begin
        Initialize();
        Rec."Entry No." := 2;
        Rec."Integer Field" := 99;
        Rec.Insert();
        Rec.Get(2);

        V := Rec;
        RecRef.GetTable(V);

        Assert.AreEqual(99, RecRef.Field(3).Value(), 'GetTable(Variant) copies the boxed row — Field(3) returns 99 with no Find');
        RecRef.Close();
    end;

    [Test]
    procedure GetTableFromVariant_CopiesUnsavedBufferValue()
    // CLAIM: what GetTable(Variant) copies is the boxed record's buffer, not the stored row — a
    //        value assigned after the Insert and never Modified is what Field().Value() returns.
    var
        Rec: Record "ALT Universal";
        Stored: Record "ALT Universal";
        RecRef: RecordRef;
        V: Variant;
    begin
        Initialize();
        Rec."Entry No." := 4;
        Rec."Integer Field" := 99;
        Rec.Insert();
        Rec."Integer Field" := 123;

        V := Rec;
        RecRef.GetTable(V);

        Assert.AreEqual(123, RecRef.Field(3).Value(), 'GetTable(Variant) copies the unsaved buffer value, not the stored 99');
        RecRef.Close();
        Stored.Get(4);
        Assert.AreEqual(99, Stored."Integer Field", 'control: the stored row still holds 99');
    end;

    [Test]
    procedure SetTableThenVariant_GetTable_RoundTripsTableId()
    // CLAIM: the table identity survives SetTable(Record) -> Variant -> GetTable.
    var
        Rec: Record "ALT Universal";
        SetRef: RecordRef;
        GetRef: RecordRef;
        V: Variant;
    begin
        Initialize();
        Rec."Entry No." := 3;
        Rec.Insert();
        Rec.Get(3);

        SetRef.Open(Database::"ALT Universal");
        SetRef.SetTable(Rec);

        V := Rec;
        GetRef.GetTable(V);

        Assert.AreEqual(SetRef.Number(), GetRef.Number(), 'the table id must round-trip through SetTable and GetTable(Variant)');
        SetRef.Close();
        GetRef.Close();
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
