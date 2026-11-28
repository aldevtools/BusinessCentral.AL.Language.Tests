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
// filtered to committed rows, over committed rows too, through a RecordRef, of another table).
// Each value is an offset from LastUsedRowVersion() read right after the commit that starts the attempt: 'value' is LastUsedRowVersion() right
// after the shape, 'rowN' / 'otherN' the buffer SystemRowVersion read after that, 'value2' LastUsedRowVersion() after those reads, 'next' the
// buffer SystemRowVersion of a fresh Insert into RVS Other, 'end' LastUsedRowVersion() at the end. Offsets are counts of row versions this
// transaction handed out, not row version numbers. Each test repeats its shape four times and keeps the attempt with the smallest 'end'
// (another session's write can only raise it; corpus issue 1063).
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
// - After every shape the next Insert gets the value + 1.
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

    [Test]
    procedure RowVersionSend_CheckedInsert_Single()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_Two()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_AfterPlainSameTable()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_AfterLockTable()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_RecordRef()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_PlainInsert_RecordRef()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_BlobTable()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_PlainInsert_BlobTable()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_AutoIncrement()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_PlainInsert_AutoIncrement()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_OtherTableUnsent()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_IssueLayout()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_AfterOtherModify()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsertTrue_OnInsertReadsOther()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_Subscriber()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_WithSystemId()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsertTrue_NoTrigger()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_DuplicateOtherUnsent()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_TemporaryOtherUnsent()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_PlainInsert_ValueFirst()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_PlainInsert_BufferReadFirst()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_PlainInsertTwo_DeleteAll()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_PlainInsertTwo_DeleteAllFilteredOther()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_PlainInsert_DeleteAllCommittedToo()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_PlainInsertTwo_DeleteAllRecordRef()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_PlainInsert_DeleteAllOtherTable()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_PlainModifyAfterInsert()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_DeleteAfterInsert()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_RenameAfterInsert()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_ModifyAllAfterInsert()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_TruncateAfterInsert()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_TwoTablesInsertModify()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_IssueOrder()
    var
        Observer: Codeunit "Probe Observer";
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
        Observer.Finish();
    end;
}
