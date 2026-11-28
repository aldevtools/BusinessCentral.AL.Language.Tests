// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-lastusedrowversion-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 76640 (RVS Row) and 76641 (RVS Other) from RowVersionWriteShapes.al, 76644 to 76647 and 76651
// Probe: when an Insert of an open transaction gets its row version (when BC sends the row), measured by reading Database.LastUsedRowVersion()
// FIRST, before any read of a record buffer (AL Runner issue 8671, review of runner PR 9237). RowVersionWriteShapes.al reads SystemRowVersion
// from the buffer before LastUsedRowVersion(), and that read itself sends an unsent row; this file separates the two. Shapes: a checked Insert
// (alone, twice, after a plain Insert into the same table, after LockTable, through a RecordRef, into a table with a Blob field or an
// AutoIncrement field, while another table holds unsent rows, the issue's table layout, after another table's Insert and Modify, Insert(true)
// with an OnInsert trigger that reads another table, with an OnBeforeInsertEvent subscriber, Insert(false, true), Insert(true) with no trigger,
// a checked Insert that fails on a duplicate key, a checked Insert into a temporary record); a plain Insert (record and RecordRef, Blob and
// AutoIncrement tables) with the value read first, a plain Insert with the buffer read first; plain Inserts followed by DeleteAll (unfiltered,
// filtered to committed rows, over committed rows too, through a RecordRef, of another table); the no-read twins of RowVersionWriteShapes.al:
// a plain Modify, Delete, Rename, ModifyAll and Truncate after an Insert, Inserts and Modifies in two tables, and the issue order (are the
// three config rows above the watermark the issue's export reads).
// Each value is an offset from LastUsedRowVersion() read right after the commit that starts the attempt: 'value' is LastUsedRowVersion() right
// after the shape, 'rowN' / 'otherN' the buffer SystemRowVersion read after that, 'value2' LastUsedRowVersion() after those reads, 'next' the
// buffer SystemRowVersion of a fresh Insert into RVS Other, 'end' LastUsedRowVersion() at the end. Offsets are counts of row versions this
// transaction handed out, not row version numbers. Another session's write can only raise an offset, so each test runs its body up to four
// times and passes on the first attempt whose observations all match; a difference that is the same on every attempt still fails (the
// pattern of PlTRowVersionValue.al, corpus issue 1063).
// Measured on BC 27.5, 28.5 and 29.0 (local runs of the CI leg; the PR run follows):
// - A checked Insert (if not Rec.Insert() then) sends its row at once: the value is the row's version. It also sends the unsent rows of the
//   same table first (plain then checked: value 2, rows 1 and 2), but not the unsent rows of another table: those get their versions only
//   when their buffer is read, after the checked rows (other table unsent: value 1, row 1, other 2; issue layout: value 2, the three other
//   rows 5). LockTable, a RecordRef, a Blob or AutoIncrement table, Insert(true), Insert(false, true) and an OnBeforeInsertEvent subscriber do
//   not change this. An OnInsert trigger that reads the other table sends that table's unsent row before the checked row (other 1, row 2).
// - Another table's Insert and Modify do not send an unsent row of the first table; the later checked Insert sends it (row 3 after other 2).
// - A checked Insert that fails on a duplicate key returns false, hands out one row version, and does not send another table's unsent row.
// - A checked Insert into a temporary record sends nothing (value 0).
// - A plain Insert into a normal table is not sent (value 0, also through a RecordRef); reading its SystemRowVersion from the buffer sends it
//   (value 1 after the read). A plain Insert into a table with a Blob or an AutoIncrement field is sent at once (value 1).
// - DeleteAll of the same table after plain Inserts sends them first, whatever its filter and also through a RecordRef (two rows: value 2);
//   a DeleteAll of another table does not (value 0). After such a DeleteAll every inserted row's buffer shows the version of the last one.
// - A plain Modify, Delete or Rename right after the Insert sends the row first: Modify and Rename hand out the insert's and their own version
//   (value 2), Delete only the insert's (value 1). ModifyAll after two Inserts sends both, then modifies both (value 4; a Get shows rows 3
//   and 4). Truncate after an Insert gives value 1 on BC on Linux (RowVersionWriteShapes.al has the Windows difference).
// - Two tables: two plain Inserts leave the value the same; a Modify of the first table's row sends only that table's row (value 2); the
//   second table's row is sent by its own Modify (insert 3, modify 4).
// - Issue order: after the setup row's Insert and Modify (watermark 2) and three plain Inserts into another table, two checked Inserts give
//   value 4; the three config rows were not sent then, and a Get gives them versions 5, 6 and 7, all above the watermark.
// - After every shape the next Insert gets the value + 1.
// - One run of RowVersionSend_CheckedInsert_AfterOtherModify on BC 29.0 gave every offset one higher than the other runs (an extra row
//   version before the other table's Insert); the asserted values are those of the other runs, and the retry covers such a run.
// BC versions: 27+

table 76644 "RVS Blob Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 76645 "RVS Auto Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 76646 "RVS Trig Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    // Reads another table: the checked Insert(true) cell measures whether the trigger's read sends that table's unsent row.
    trigger OnInsert()
    var
        Other: Record "RVS Other";
    begin
        if Other.FindFirst() then
            Name := Other.Name;
    end;
}

table 76647 "RVS Sub Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// The config rows of the issue-order cell (the issue inserts them into another table than the checked Inserts).
table 76651 "RVS Config Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// local object: the OnBeforeInsertEvent subscriber of the checked Insert cell with a subscriber (only table RVS Sub Row).
codeunit 76648 "RVS Sub Row Events"
{
    [EventSubscriber(ObjectType::Table, Database::"RVS Sub Row", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeInsertSubRow(var Rec: Record "RVS Sub Row"; RunTrigger: Boolean)
    begin
        Rec.Name := 'sub';
    end;
}

// local object: the shared steps of the send order tests. Each value is an offset from LastUsedRowVersion() read right after the commit
// that starts the test ('zero' for a SystemRowVersion of 0).
codeunit 76649 "RVS Send Cells"
{
    var
        Prev: BigInteger;
        Acc: Text;

    procedure Start(SeedRows: Integer; SeedOther: Boolean)
    var
        Row: Record "RVS Row";
        Other: Record "RVS Other";
        BlobRow: Record "RVS Blob Row";
        AutoRow: Record "RVS Auto Row";
        TrigRow: Record "RVS Trig Row";
        SubRow: Record "RVS Sub Row";
        ConfigRow: Record "RVS Config Row";
        i: Integer;
    begin
        Row.DeleteAll();
        Other.DeleteAll();
        BlobRow.DeleteAll();
        AutoRow.DeleteAll();
        TrigRow.DeleteAll();
        SubRow.DeleteAll();
        ConfigRow.DeleteAll();
        for i := 1 to SeedRows do begin
            Row.Init();
            Row.Id := i;
            Row.Insert();
        end;
        if SeedOther then begin
            Other.Init();
            Other.Id := 500;
            Other.Insert();
        end;
        Commit();
        Acc := '';
        Prev := LastUsedRowVersion();
    end;

    procedure Rel(Value: BigInteger; Other: BigInteger): Text
    begin
        if Value = Other then
            exit('same');
        if Value > Other then
            exit('greater');
        exit('less');
    end;

    local procedure Offset(RowVersion: BigInteger): Text
    begin
        if RowVersion = 0 then
            exit('zero');
        exit(Format(RowVersion - Prev, 0, 9));
    end;

    local procedure Add(Tag: Text; Value: Text)
    begin
        Acc += Tag + '=' + Value + '|';
    end;

    // LastUsedRowVersion() now.
    procedure Value(Tag: Text)
    begin
        Add(Tag, Offset(LastUsedRowVersion()));
    end;

    procedure Version(Tag: Text; RowVersion: BigInteger)
    begin
        Add(Tag, Offset(RowVersion));
    end;

    procedure Fact(Tag: Text; FactValue: Text)
    begin
        Add(Tag, FactValue);
    end;

    // A fresh Insert into RVS Other and its buffer SystemRowVersion.
    procedure NextInsert()
    var
        Other: Record "RVS Other";
    begin
        Other.Id := 1000;
        Other.Insert();
        Add('next', Offset(Other.SystemRowVersion));
    end;

    // LastUsedRowVersion() at the end of the test.
    procedure EndValue()
    begin
        Add('end', Offset(LastUsedRowVersion()));
    end;

    procedure Emit(var Observer: Codeunit "Probe Observer")
    var
        Pair: Text;
        At: Integer;
    begin
        foreach Pair in Acc.Split('|') do
            if Pair <> '' then begin
                At := Pair.IndexOf('=');
                Observer.Observe(CopyStr(Pair, 1, At - 1), CopyStr(Pair, At + 1));
            end;
    end;
}

codeunit 76650 "RVS Send Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryVerify(var Observer: Codeunit "Probe Observer")
    begin
        Observer.Verify();
    end;

    local procedure RowVersionSend_CheckedInsert_Single_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        R1: Record "RVS Row";
    begin
        Cells.Start(0, false);
        R1.Id := 1;
        if not R1.Insert() then
            Error('insert failed');
        Cells.Value('value');
        Cells.Version('row1', R1.SystemRowVersion);
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '1');
        Observer.Expect('row1', '1');
        Observer.Expect('value2', '1');
        Observer.Expect('next', '2');
        Observer.Expect('end', '2');
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_Single()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_CheckedInsert_Single_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_CheckedInsert_Single_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_CheckedInsert_Two_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        R1: Record "RVS Row";
        R2: Record "RVS Row";
    begin
        Cells.Start(0, false);
        R1.Id := 1;
        if not R1.Insert() then
            Error('insert failed');
        R2.Id := 2;
        if not R2.Insert() then
            Error('insert failed');
        Cells.Value('value');
        Cells.Version('row1', R1.SystemRowVersion);
        Cells.Version('row2', R2.SystemRowVersion);
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '2');
        Observer.Expect('row1', '1');
        Observer.Expect('row2', '2');
        Observer.Expect('value2', '2');
        Observer.Expect('next', '3');
        Observer.Expect('end', '3');
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_Two()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_CheckedInsert_Two_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_CheckedInsert_Two_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_CheckedInsert_AfterPlainSameTable_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        R1: Record "RVS Row";
        R2: Record "RVS Row";
    begin
        Cells.Start(0, false);
        R1.Id := 1;
        R1.Insert();
        R2.Id := 2;
        if not R2.Insert() then
            Error('insert failed');
        Cells.Value('value');
        Cells.Version('row1', R1.SystemRowVersion);
        Cells.Version('row2', R2.SystemRowVersion);
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '2');
        Observer.Expect('row1', '1');
        Observer.Expect('row2', '2');
        Observer.Expect('value2', '2');
        Observer.Expect('next', '3');
        Observer.Expect('end', '3');
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_AfterPlainSameTable()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_CheckedInsert_AfterPlainSameTable_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_CheckedInsert_AfterPlainSameTable_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_CheckedInsert_AfterLockTable_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        R1: Record "RVS Row";
    begin
        Cells.Start(0, false);
        R1.LockTable();
        R1.Id := 1;
        if not R1.Insert() then
            Error('insert failed');
        Cells.Value('value');
        Cells.Version('row1', R1.SystemRowVersion);
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '1');
        Observer.Expect('row1', '1');
        Observer.Expect('value2', '1');
        Observer.Expect('next', '2');
        Observer.Expect('end', '2');
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_AfterLockTable()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_CheckedInsert_AfterLockTable_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_CheckedInsert_AfterLockTable_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_CheckedInsert_RecordRef_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        RecRef: RecordRef;
        R1: Record "RVS Row";
        RowVersion: BigInteger;
    begin
        Cells.Start(0, false);
        RecRef.Open(Database::"RVS Row");
        RecRef.Field(1).Value := 1;
        if not RecRef.Insert() then
            Error('insert failed');
        Cells.Value('value');
        RowVersion := RecRef.Field(R1.FieldNo(SystemRowVersion)).Value;
        Cells.Version('row1', RowVersion);
        RecRef.Close();
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '1');
        Observer.Expect('row1', '1');
        Observer.Expect('value2', '1');
        Observer.Expect('next', '2');
        Observer.Expect('end', '2');
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_RecordRef()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_CheckedInsert_RecordRef_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_CheckedInsert_RecordRef_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_PlainInsert_RecordRef_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        RecRef: RecordRef;
        R1: Record "RVS Row";
        RowVersion: BigInteger;
    begin
        Cells.Start(0, false);
        RecRef.Open(Database::"RVS Row");
        RecRef.Field(1).Value := 1;
        RecRef.Insert();
        Cells.Value('value');
        RowVersion := RecRef.Field(R1.FieldNo(SystemRowVersion)).Value;
        Cells.Version('row1', RowVersion);
        RecRef.Close();
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '0');
        Observer.Expect('row1', '1');
        Observer.Expect('value2', '1');
        Observer.Expect('next', '2');
        Observer.Expect('end', '2');
    end;

    [Test]
    procedure RowVersionSend_PlainInsert_RecordRef()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_PlainInsert_RecordRef_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_PlainInsert_RecordRef_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_CheckedInsert_BlobTable_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        B1: Record "RVS Blob Row";
    begin
        Cells.Start(0, false);
        B1.Id := 1;
        if not B1.Insert() then
            Error('insert failed');
        Cells.Value('value');
        Cells.Version('row1', B1.SystemRowVersion);
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '1');
        Observer.Expect('row1', '1');
        Observer.Expect('value2', '1');
        Observer.Expect('next', '2');
        Observer.Expect('end', '2');
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_BlobTable()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_CheckedInsert_BlobTable_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_CheckedInsert_BlobTable_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_PlainInsert_BlobTable_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        B1: Record "RVS Blob Row";
    begin
        Cells.Start(0, false);
        B1.Id := 1;
        B1.Insert();
        Cells.Value('value');
        Cells.Version('row1', B1.SystemRowVersion);
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '1');
        Observer.Expect('row1', '1');
        Observer.Expect('value2', '1');
        Observer.Expect('next', '2');
        Observer.Expect('end', '2');
    end;

    [Test]
    procedure RowVersionSend_PlainInsert_BlobTable()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_PlainInsert_BlobTable_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_PlainInsert_BlobTable_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_CheckedInsert_AutoIncrement_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        A1: Record "RVS Auto Row";
    begin
        Cells.Start(0, false);
        A1.Id := 0;
        if not A1.Insert() then
            Error('insert failed');
        Cells.Value('value');
        Cells.Version('row1', A1.SystemRowVersion);
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '1');
        Observer.Expect('row1', '1');
        Observer.Expect('value2', '1');
        Observer.Expect('next', '2');
        Observer.Expect('end', '2');
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_AutoIncrement()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_CheckedInsert_AutoIncrement_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_CheckedInsert_AutoIncrement_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_PlainInsert_AutoIncrement_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        A1: Record "RVS Auto Row";
    begin
        Cells.Start(0, false);
        A1.Id := 0;
        A1.Insert();
        Cells.Value('value');
        Cells.Version('row1', A1.SystemRowVersion);
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '1');
        Observer.Expect('row1', '1');
        Observer.Expect('value2', '1');
        Observer.Expect('next', '2');
        Observer.Expect('end', '2');
    end;

    [Test]
    procedure RowVersionSend_PlainInsert_AutoIncrement()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_PlainInsert_AutoIncrement_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_PlainInsert_AutoIncrement_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_CheckedInsert_OtherTableUnsent_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        O1: Record "RVS Other";
        R1: Record "RVS Row";
    begin
        Cells.Start(0, false);
        O1.Id := 1;
        O1.Insert();
        R1.Id := 1;
        if not R1.Insert() then
            Error('insert failed');
        Cells.Value('value');
        Cells.Version('other1', O1.SystemRowVersion);
        Cells.Version('row1', R1.SystemRowVersion);
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '1');
        Observer.Expect('other1', '2');
        Observer.Expect('row1', '1');
        Observer.Expect('value2', '2');
        Observer.Expect('next', '3');
        Observer.Expect('end', '3');
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_OtherTableUnsent()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_CheckedInsert_OtherTableUnsent_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_CheckedInsert_OtherTableUnsent_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_CheckedInsert_IssueLayout_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        O1: Record "RVS Other";
        O2: Record "RVS Other";
        O3: Record "RVS Other";
        R1: Record "RVS Row";
        R2: Record "RVS Row";
    begin
        Cells.Start(0, false);
        O1.Id := 1;
        O1.Insert();
        O2.Id := 2;
        O2.Insert();
        O3.Id := 3;
        O3.Insert();
        R1.Id := 1;
        if not R1.Insert() then
            Error('insert failed');
        R2.Id := 2;
        if not R2.Insert() then
            Error('insert failed');
        Cells.Value('value');
        Cells.Version('other1', O1.SystemRowVersion);
        Cells.Version('other2', O2.SystemRowVersion);
        Cells.Version('other3', O3.SystemRowVersion);
        Cells.Version('row1', R1.SystemRowVersion);
        Cells.Version('row2', R2.SystemRowVersion);
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '2');
        Observer.Expect('other1', '5');
        Observer.Expect('other2', '5');
        Observer.Expect('other3', '5');
        Observer.Expect('row1', '1');
        Observer.Expect('row2', '2');
        Observer.Expect('value2', '5');
        Observer.Expect('next', '6');
        Observer.Expect('end', '6');
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_IssueLayout()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_CheckedInsert_IssueLayout_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_CheckedInsert_IssueLayout_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_CheckedInsert_AfterOtherModify_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        O1: Record "RVS Other";
        R1: Record "RVS Row";
        R2: Record "RVS Row";
    begin
        Cells.Start(0, false);
        R1.Id := 1;
        R1.Insert();
        O1.Id := 1;
        O1.Insert();
        O1.Name := 'y';
        O1.Modify();
        R2.Id := 2;
        if not R2.Insert() then
            Error('insert failed');
        Cells.Value('value');
        Cells.Version('row1', R1.SystemRowVersion);
        Cells.Version('other1', O1.SystemRowVersion);
        Cells.Version('row2', R2.SystemRowVersion);
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '4');
        Observer.Expect('row1', '3');
        Observer.Expect('other1', '2');
        Observer.Expect('row2', '4');
        Observer.Expect('value2', '4');
        Observer.Expect('next', '5');
        Observer.Expect('end', '5');
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_AfterOtherModify()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_CheckedInsert_AfterOtherModify_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_CheckedInsert_AfterOtherModify_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_CheckedInsertTrue_OnInsertReadsOther_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        O1: Record "RVS Other";
        T1: Record "RVS Trig Row";
    begin
        Cells.Start(0, false);
        O1.Id := 1;
        O1.Name := 'o';
        O1.Insert();
        T1.Id := 1;
        if not T1.Insert(true) then
            Error('insert failed');
        Cells.Value('value');
        Cells.Fact('trigger name', T1.Name);
        Cells.Version('other1', O1.SystemRowVersion);
        Cells.Version('row1', T1.SystemRowVersion);
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '2');
        Observer.Expect('trigger name', 'o');
        Observer.Expect('other1', '1');
        Observer.Expect('row1', '2');
        Observer.Expect('value2', '2');
        Observer.Expect('next', '3');
        Observer.Expect('end', '3');
    end;

    [Test]
    procedure RowVersionSend_CheckedInsertTrue_OnInsertReadsOther()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_CheckedInsertTrue_OnInsertReadsOther_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_CheckedInsertTrue_OnInsertReadsOther_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_CheckedInsert_Subscriber_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        S1: Record "RVS Sub Row";
    begin
        Cells.Start(0, false);
        S1.Id := 1;
        if not S1.Insert() then
            Error('insert failed');
        Cells.Value('value');
        Cells.Fact('subscriber name', S1.Name);
        Cells.Version('row1', S1.SystemRowVersion);
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '1');
        Observer.Expect('subscriber name', 'sub');
        Observer.Expect('row1', '1');
        Observer.Expect('value2', '1');
        Observer.Expect('next', '2');
        Observer.Expect('end', '2');
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_Subscriber()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_CheckedInsert_Subscriber_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_CheckedInsert_Subscriber_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_CheckedInsert_WithSystemId_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        R1: Record "RVS Row";
    begin
        Cells.Start(0, false);
        R1.SystemId := CreateGuid();
        R1.Id := 1;
        if not R1.Insert(false, true) then
            Error('insert failed');
        Cells.Value('value');
        Cells.Version('row1', R1.SystemRowVersion);
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '1');
        Observer.Expect('row1', '1');
        Observer.Expect('value2', '1');
        Observer.Expect('next', '2');
        Observer.Expect('end', '2');
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_WithSystemId()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_CheckedInsert_WithSystemId_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_CheckedInsert_WithSystemId_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_CheckedInsertTrue_NoTrigger_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        R1: Record "RVS Row";
    begin
        Cells.Start(0, false);
        R1.Id := 1;
        if not R1.Insert(true) then
            Error('insert failed');
        Cells.Value('value');
        Cells.Version('row1', R1.SystemRowVersion);
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '1');
        Observer.Expect('row1', '1');
        Observer.Expect('value2', '1');
        Observer.Expect('next', '2');
        Observer.Expect('end', '2');
    end;

    [Test]
    procedure RowVersionSend_CheckedInsertTrue_NoTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_CheckedInsertTrue_NoTrigger_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_CheckedInsertTrue_NoTrigger_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_CheckedInsert_DuplicateOtherUnsent_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        O1: Record "RVS Other";
        R1: Record "RVS Row";
    begin
        Cells.Start(1, false);
        O1.Id := 1;
        O1.Insert();
        R1.Id := 1;
        Cells.Fact('inserted', Format(R1.Insert()));
        Cells.Value('value');
        Cells.Version('other1', O1.SystemRowVersion);
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('inserted', 'No');
        Observer.Expect('value', '1');
        Observer.Expect('other1', '2');
        Observer.Expect('value2', '2');
        Observer.Expect('next', '3');
        Observer.Expect('end', '3');
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_DuplicateOtherUnsent()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_CheckedInsert_DuplicateOtherUnsent_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_CheckedInsert_DuplicateOtherUnsent_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_CheckedInsert_TemporaryOtherUnsent_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        O1: Record "RVS Other";
        R1: Record "RVS Row" temporary;
    begin
        Cells.Start(0, false);
        R1.DeleteAll();
        O1.Id := 1;
        O1.Insert();
        R1.Id := 1;
        if not R1.Insert() then
            Error('insert failed');
        Cells.Value('value');
        Cells.Version('other1', O1.SystemRowVersion);
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '0');
        Observer.Expect('other1', '1');
        Observer.Expect('value2', '1');
        Observer.Expect('next', '2');
        Observer.Expect('end', '2');
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_TemporaryOtherUnsent()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_CheckedInsert_TemporaryOtherUnsent_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_CheckedInsert_TemporaryOtherUnsent_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_PlainInsert_ValueFirst_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        R1: Record "RVS Row";
    begin
        Cells.Start(0, false);
        R1.Id := 1;
        R1.Insert();
        Cells.Value('value');
        Cells.Version('row1', R1.SystemRowVersion);
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '0');
        Observer.Expect('row1', '1');
        Observer.Expect('value2', '1');
        Observer.Expect('next', '2');
        Observer.Expect('end', '2');
    end;

    [Test]
    procedure RowVersionSend_PlainInsert_ValueFirst()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_PlainInsert_ValueFirst_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_PlainInsert_ValueFirst_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_PlainInsert_BufferReadFirst_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        R1: Record "RVS Row";
        RowVersion: BigInteger;
    begin
        Cells.Start(0, false);
        R1.Id := 1;
        R1.Insert();
        RowVersion := R1.SystemRowVersion;
        Cells.Value('value');
        Cells.Version('row1', RowVersion);
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '1');
        Observer.Expect('row1', '1');
        Observer.Expect('value2', '1');
        Observer.Expect('next', '2');
        Observer.Expect('end', '2');
    end;

    [Test]
    procedure RowVersionSend_PlainInsert_BufferReadFirst()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_PlainInsert_BufferReadFirst_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_PlainInsert_BufferReadFirst_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_PlainInsertTwo_DeleteAll_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        R1: Record "RVS Row";
        R2: Record "RVS Row";
        Row: Record "RVS Row";
    begin
        Cells.Start(0, false);
        R1.Id := 1;
        R1.Insert();
        R2.Id := 2;
        R2.Insert();
        Row.DeleteAll();
        Cells.Value('value');
        Cells.Version('row1', R1.SystemRowVersion);
        Cells.Version('row2', R2.SystemRowVersion);
        Cells.Value('value2');
        Cells.Fact('count', Format(Row.Count()));
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '2');
        Observer.Expect('row1', '2');
        Observer.Expect('row2', '2');
        Observer.Expect('value2', '2');
        Observer.Expect('count', '0');
        Observer.Expect('next', '3');
        Observer.Expect('end', '3');
    end;

    [Test]
    procedure RowVersionSend_PlainInsertTwo_DeleteAll()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_PlainInsertTwo_DeleteAll_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_PlainInsertTwo_DeleteAll_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_PlainInsertTwo_DeleteAllFilteredOther_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        R1: Record "RVS Row";
        R2: Record "RVS Row";
        Row: Record "RVS Row";
    begin
        Cells.Start(2, false);
        R1.Id := 10;
        R1.Insert();
        R2.Id := 11;
        R2.Insert();
        Row.SetRange(Id, 1, 2);
        Row.DeleteAll();
        Cells.Value('value');
        Cells.Version('row1', R1.SystemRowVersion);
        Cells.Version('row2', R2.SystemRowVersion);
        Cells.Value('value2');
        Row.Reset();
        Cells.Fact('count', Format(Row.Count()));
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '2');
        Observer.Expect('row1', '2');
        Observer.Expect('row2', '2');
        Observer.Expect('value2', '2');
        Observer.Expect('count', '2');
        Observer.Expect('next', '3');
        Observer.Expect('end', '3');
    end;

    [Test]
    procedure RowVersionSend_PlainInsertTwo_DeleteAllFilteredOther()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_PlainInsertTwo_DeleteAllFilteredOther_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_PlainInsertTwo_DeleteAllFilteredOther_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_PlainInsert_DeleteAllCommittedToo_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        R1: Record "RVS Row";
        Row: Record "RVS Row";
    begin
        Cells.Start(2, false);
        R1.Id := 10;
        R1.Insert();
        Row.DeleteAll();
        Cells.Value('value');
        Cells.Version('row1', R1.SystemRowVersion);
        Cells.Value('value2');
        Cells.Fact('count', Format(Row.Count()));
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '1');
        Observer.Expect('row1', '1');
        Observer.Expect('value2', '1');
        Observer.Expect('count', '0');
        Observer.Expect('next', '2');
        Observer.Expect('end', '2');
    end;

    [Test]
    procedure RowVersionSend_PlainInsert_DeleteAllCommittedToo()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_PlainInsert_DeleteAllCommittedToo_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_PlainInsert_DeleteAllCommittedToo_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_PlainInsertTwo_DeleteAllRecordRef_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        R1: Record "RVS Row";
        R2: Record "RVS Row";
        RecRef: RecordRef;
    begin
        Cells.Start(0, false);
        R1.Id := 1;
        R1.Insert();
        R2.Id := 2;
        R2.Insert();
        RecRef.Open(Database::"RVS Row");
        RecRef.DeleteAll();
        Cells.Value('value');
        Cells.Version('row1', R1.SystemRowVersion);
        Cells.Version('row2', R2.SystemRowVersion);
        Cells.Value('value2');
        Cells.Fact('count', Format(RecRef.Count()));
        RecRef.Close();
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '2');
        Observer.Expect('row1', '2');
        Observer.Expect('row2', '2');
        Observer.Expect('value2', '2');
        Observer.Expect('count', '0');
        Observer.Expect('next', '3');
        Observer.Expect('end', '3');
    end;

    [Test]
    procedure RowVersionSend_PlainInsertTwo_DeleteAllRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_PlainInsertTwo_DeleteAllRecordRef_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_PlainInsertTwo_DeleteAllRecordRef_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_PlainInsert_DeleteAllOtherTable_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        R1: Record "RVS Row";
        Other: Record "RVS Other";
    begin
        Cells.Start(0, true);
        R1.Id := 1;
        R1.Insert();
        Other.DeleteAll();
        Cells.Value('value');
        Cells.Version('row1', R1.SystemRowVersion);
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '0');
        Observer.Expect('row1', '1');
        Observer.Expect('value2', '1');
        Observer.Expect('next', '2');
        Observer.Expect('end', '2');
    end;

    [Test]
    procedure RowVersionSend_PlainInsert_DeleteAllOtherTable()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_PlainInsert_DeleteAllOtherTable_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_PlainInsert_DeleteAllOtherTable_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_PlainModifyAfterInsert_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        R1: Record "RVS Row";
    begin
        Cells.Start(0, false);
        R1.Id := 1;
        R1.Insert();
        R1.Name := 'x';
        R1.Modify();
        Cells.Value('value');
        Cells.Version('row1', R1.SystemRowVersion);
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '2');
        Observer.Expect('row1', '2');
        Observer.Expect('value2', '2');
        Observer.Expect('next', '3');
        Observer.Expect('end', '3');
    end;

    [Test]
    procedure RowVersionSend_PlainModifyAfterInsert()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_PlainModifyAfterInsert_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_PlainModifyAfterInsert_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_DeleteAfterInsert_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        R1: Record "RVS Row";
    begin
        Cells.Start(0, false);
        R1.Id := 1;
        R1.Insert();
        R1.Delete();
        Cells.Value('value');
        Cells.Version('row1', R1.SystemRowVersion);
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '1');
        Observer.Expect('row1', '1');
        Observer.Expect('value2', '1');
        Observer.Expect('next', '2');
        Observer.Expect('end', '2');
    end;

    [Test]
    procedure RowVersionSend_DeleteAfterInsert()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_DeleteAfterInsert_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_DeleteAfterInsert_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_RenameAfterInsert_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        R1: Record "RVS Row";
    begin
        Cells.Start(0, false);
        R1.Id := 1;
        R1.Insert();
        R1.Rename(2);
        Cells.Value('value');
        Cells.Version('row1', R1.SystemRowVersion);
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '2');
        Observer.Expect('row1', '2');
        Observer.Expect('value2', '2');
        Observer.Expect('next', '3');
        Observer.Expect('end', '3');
    end;

    [Test]
    procedure RowVersionSend_RenameAfterInsert()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_RenameAfterInsert_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_RenameAfterInsert_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_ModifyAllAfterInsert_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        R1: Record "RVS Row";
        R2: Record "RVS Row";
        Row: Record "RVS Row";
    begin
        Cells.Start(0, false);
        R1.Id := 1;
        R1.Insert();
        R2.Id := 2;
        R2.Insert();
        Row.ModifyAll(Name, 'x');
        Cells.Value('value');
        Cells.Version('row1', R1.SystemRowVersion);
        Cells.Version('row2', R2.SystemRowVersion);
        Row.Get(1);
        Cells.Version('get1', Row.SystemRowVersion);
        Row.Get(2);
        Cells.Version('get2', Row.SystemRowVersion);
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '4');
        Observer.Expect('row1', '2');
        Observer.Expect('row2', '2');
        Observer.Expect('get1', '3');
        Observer.Expect('get2', '4');
        Observer.Expect('value2', '4');
        Observer.Expect('next', '5');
        Observer.Expect('end', '5');
    end;

    [Test]
    procedure RowVersionSend_ModifyAllAfterInsert()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_ModifyAllAfterInsert_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_ModifyAllAfterInsert_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_TruncateAfterInsert_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        R1: Record "RVS Row";
        Row: Record "RVS Row";
    begin
        Cells.Start(0, false);
        R1.Id := 1;
        R1.Insert();
        Row.Truncate();
        Cells.Value('value');
        Cells.Version('row1', R1.SystemRowVersion);
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '1');
        Observer.Expect('row1', '1');
        Observer.Expect('value2', '1');
        Observer.Expect('next', '2');
        Observer.Expect('end', '2');
    end;

    [Test]
    procedure RowVersionSend_TruncateAfterInsert()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_TruncateAfterInsert_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_TruncateAfterInsert_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_TwoTablesInsertModify_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        R1: Record "RVS Row";
        O1: Record "RVS Other";
    begin
        Cells.Start(0, false);
        R1.Id := 1;
        R1.Insert();
        O1.Id := 1;
        O1.Insert();
        Cells.Value('value');
        R1.Name := 'x';
        R1.Modify();
        Cells.Value('value modify1');
        O1.Name := 'y';
        O1.Modify();
        Cells.Value('value modify2');
        Cells.Version('row1', R1.SystemRowVersion);
        Cells.Version('other1', O1.SystemRowVersion);
        Cells.Value('value2');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('value', '0');
        Observer.Expect('value modify1', '2');
        Observer.Expect('value modify2', '4');
        Observer.Expect('row1', '2');
        Observer.Expect('other1', '4');
        Observer.Expect('value2', '4');
        Observer.Expect('next', '5');
        Observer.Expect('end', '5');
    end;

    [Test]
    procedure RowVersionSend_TwoTablesInsertModify()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_TwoTablesInsertModify_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_TwoTablesInsertModify_Body(Observer);
        Observer.Verify();
    end;

    local procedure RowVersionSend_IssueOrder_Body(var Observer: Codeunit "Probe Observer")
    var
        Cells: Codeunit "RVS Send Cells";
        Row: Record "RVS Row";
        Other: Record "RVS Other";
        Config: Record "RVS Config Row";
        R1: Record "RVS Row";
        R2: Record "RVS Row";
        Watermark: BigInteger;
        Value: BigInteger;
        i: Integer;
    begin
        Cells.Start(3, false);
        Row.SetFilter(Id, '2..');
        Row.DeleteAll();
        Row.Reset();
        Other.DeleteAll();
        Other.Id := 1;
        Other.Insert();
        Other.Name := 'setup';
        Other.Modify();
        for i := 1 to 3 do begin
            Config.Init();
            Config.Id := i;
            Config.Insert();
        end;
        Watermark := LastUsedRowVersion();
        Cells.Version('watermark', Watermark);
        R1.Id := 201;
        if not R1.Insert() then
            Error('insert failed');
        R2.Id := 202;
        if not R2.Insert() then
            Error('insert failed');
        Value := LastUsedRowVersion();
        Cells.Version('value', Value);
        for i := 1 to 3 do begin
            Config.Get(i);
            Cells.Fact('config' + Format(i) + '/watermark', Cells.Rel(Config.SystemRowVersion, Watermark));
            Cells.Version('config' + Format(i), Config.SystemRowVersion);
        end;
        Row.Get(201);
        Cells.Fact('row201/value', Cells.Rel(Row.SystemRowVersion, Value));
        Row.Get(202);
        Cells.Fact('row202/value', Cells.Rel(Row.SystemRowVersion, Value));
        Row.Get(201);
        Row.Name := 'x';
        Row.Modify();
        Cells.Value('value modify');
        Cells.NextInsert();
        Cells.EndValue();
        Cells.Emit(Observer);
        Observer.Expect('watermark', '2');
        Observer.Expect('value', '4');
        Observer.Expect('config1/watermark', 'greater');
        Observer.Expect('config1', '5');
        Observer.Expect('config2/watermark', 'greater');
        Observer.Expect('config2', '6');
        Observer.Expect('config3/watermark', 'greater');
        Observer.Expect('config3', '7');
        Observer.Expect('row201/value', 'less');
        Observer.Expect('row202/value', 'same');
        Observer.Expect('value modify', '8');
        Observer.Expect('next', '9');
        Observer.Expect('end', '9');
    end;

    [Test]
    procedure RowVersionSend_IssueOrder()
    var
        Observer: Codeunit "Probe Observer";
        Attempt: Integer;
    begin
        // Another session or a background task of the BC service can write between two reads of LastUsedRowVersion; a run that
        // saw such a write is repeated, a difference that is the same on every attempt still fails (issue 1063).
        for Attempt := 1 to 4 do begin
            Clear(Observer);
            RowVersionSend_IssueOrder_Body(Observer);
            if TryVerify(Observer) then
                exit;
        end;
        Clear(Observer);
        RowVersionSend_IssueOrder_Body(Observer);
        Observer.Verify();
    end;
}
