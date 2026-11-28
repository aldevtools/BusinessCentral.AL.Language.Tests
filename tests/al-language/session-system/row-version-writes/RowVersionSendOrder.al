// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-lastusedrowversion-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 76641 (RVS Other, from RowVersionWriteShapes.al), 76640 (RVS Row), 76644 to 76647
// Probe: HEADER-TODO
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
// that starts the attempt ('zero' for a SystemRowVersion of 0). Each test repeats its shape four times and keeps the attempt with the
// smallest end offset: LastUsedRowVersion() is database wide, and a write of another session can only add to the end offset, so the
// attempt with the smallest one is the attempt no other session wrote into (corpus issue 1063).
codeunit 76649 "RVS Send Cells"
{
    var
        Prev: BigInteger;
        Acc: Text;
        Best: BigInteger;
        BestAcc: Text;
        Attempts: Integer;

    procedure StartAttempt(SeedRows: Integer; SeedOther: Boolean)
    var
        Row: Record "RVS Row";
        Other: Record "RVS Other";
        BlobRow: Record "RVS Blob Row";
        AutoRow: Record "RVS Auto Row";
        TrigRow: Record "RVS Trig Row";
        SubRow: Record "RVS Sub Row";
        i: Integer;
    begin
        Row.DeleteAll();
        Other.DeleteAll();
        BlobRow.DeleteAll();
        AutoRow.DeleteAll();
        TrigRow.DeleteAll();
        SubRow.DeleteAll();
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

    procedure Keep()
    var
        EndValue: BigInteger;
    begin
        EndValue := LastUsedRowVersion();
        Add('end', Offset(EndValue));
        Attempts += 1;
        if (Attempts = 1) or (EndValue - Prev < Best) then begin
            Best := EndValue - Prev;
            BestAcc := Acc;
        end;
    end;

    procedure Emit(var Observer: Codeunit "Probe Observer")
    var
        Pair: Text;
        At: Integer;
    begin
        foreach Pair in BestAcc.Split('|') do
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
        Attempt: Integer;
        R1: Record "RVS Row";
    begin
        for Attempt := 1 to 4 do begin
            Cells.StartAttempt(0, false);
            Clear(R1);
            R1.Id := 1;
            if not R1.Insert() then
                Error('insert failed');
            Cells.Value('value');
            Cells.Version('row1', R1.SystemRowVersion);
            Cells.Value('value2');
            Cells.NextInsert();
            Cells.Keep();
        end;
        Cells.Emit(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_Two()
    var
        Observer: Codeunit "Probe Observer";
        Cells: Codeunit "RVS Send Cells";
        Attempt: Integer;
        R1: Record "RVS Row";
        R2: Record "RVS Row";
    begin
        for Attempt := 1 to 4 do begin
            Cells.StartAttempt(0, false);
            Clear(R1);
            Clear(R2);
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
            Cells.Keep();
        end;
        Cells.Emit(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_AfterPlainSameTable()
    var
        Observer: Codeunit "Probe Observer";
        Cells: Codeunit "RVS Send Cells";
        Attempt: Integer;
        R1: Record "RVS Row";
        R2: Record "RVS Row";
    begin
        for Attempt := 1 to 4 do begin
            Cells.StartAttempt(0, false);
            Clear(R1);
            Clear(R2);
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
            Cells.Keep();
        end;
        Cells.Emit(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_AfterLockTable()
    var
        Observer: Codeunit "Probe Observer";
        Cells: Codeunit "RVS Send Cells";
        Attempt: Integer;
        R1: Record "RVS Row";
    begin
        for Attempt := 1 to 4 do begin
            Cells.StartAttempt(0, false);
            Clear(R1);
            R1.LockTable();
            R1.Id := 1;
            if not R1.Insert() then
                Error('insert failed');
            Cells.Value('value');
            Cells.Version('row1', R1.SystemRowVersion);
            Cells.Value('value2');
            Cells.NextInsert();
            Cells.Keep();
        end;
        Cells.Emit(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_RecordRef()
    var
        Observer: Codeunit "Probe Observer";
        Cells: Codeunit "RVS Send Cells";
        Attempt: Integer;
        RecRef: RecordRef;
        R1: Record "RVS Row";
        RowVersion: BigInteger;
    begin
        for Attempt := 1 to 4 do begin
            Cells.StartAttempt(0, false);
            Clear(RecRef);
            Clear(R1);
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
            Cells.Keep();
        end;
        Cells.Emit(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_PlainInsert_RecordRef()
    var
        Observer: Codeunit "Probe Observer";
        Cells: Codeunit "RVS Send Cells";
        Attempt: Integer;
        RecRef: RecordRef;
        R1: Record "RVS Row";
        RowVersion: BigInteger;
    begin
        for Attempt := 1 to 4 do begin
            Cells.StartAttempt(0, false);
            Clear(RecRef);
            Clear(R1);
            RecRef.Open(Database::"RVS Row");
            RecRef.Field(1).Value := 1;
            RecRef.Insert();
            Cells.Value('value');
            RowVersion := RecRef.Field(R1.FieldNo(SystemRowVersion)).Value;
            Cells.Version('row1', RowVersion);
            RecRef.Close();
            Cells.Value('value2');
            Cells.NextInsert();
            Cells.Keep();
        end;
        Cells.Emit(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_BlobTable()
    var
        Observer: Codeunit "Probe Observer";
        Cells: Codeunit "RVS Send Cells";
        Attempt: Integer;
        B1: Record "RVS Blob Row";
    begin
        for Attempt := 1 to 4 do begin
            Cells.StartAttempt(0, false);
            Clear(B1);
            B1.Id := 1;
            if not B1.Insert() then
                Error('insert failed');
            Cells.Value('value');
            Cells.Version('row1', B1.SystemRowVersion);
            Cells.Value('value2');
            Cells.NextInsert();
            Cells.Keep();
        end;
        Cells.Emit(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_PlainInsert_BlobTable()
    var
        Observer: Codeunit "Probe Observer";
        Cells: Codeunit "RVS Send Cells";
        Attempt: Integer;
        B1: Record "RVS Blob Row";
    begin
        for Attempt := 1 to 4 do begin
            Cells.StartAttempt(0, false);
            Clear(B1);
            B1.Id := 1;
            B1.Insert();
            Cells.Value('value');
            Cells.Version('row1', B1.SystemRowVersion);
            Cells.Value('value2');
            Cells.NextInsert();
            Cells.Keep();
        end;
        Cells.Emit(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_AutoIncrement()
    var
        Observer: Codeunit "Probe Observer";
        Cells: Codeunit "RVS Send Cells";
        Attempt: Integer;
        A1: Record "RVS Auto Row";
    begin
        for Attempt := 1 to 4 do begin
            Cells.StartAttempt(0, false);
            Clear(A1);
            A1.Id := 0;
            if not A1.Insert() then
                Error('insert failed');
            Cells.Value('value');
            Cells.Version('row1', A1.SystemRowVersion);
            Cells.Value('value2');
            Cells.NextInsert();
            Cells.Keep();
        end;
        Cells.Emit(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_PlainInsert_AutoIncrement()
    var
        Observer: Codeunit "Probe Observer";
        Cells: Codeunit "RVS Send Cells";
        Attempt: Integer;
        A1: Record "RVS Auto Row";
    begin
        for Attempt := 1 to 4 do begin
            Cells.StartAttempt(0, false);
            Clear(A1);
            A1.Id := 0;
            A1.Insert();
            Cells.Value('value');
            Cells.Version('row1', A1.SystemRowVersion);
            Cells.Value('value2');
            Cells.NextInsert();
            Cells.Keep();
        end;
        Cells.Emit(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_OtherTableUnsent()
    var
        Observer: Codeunit "Probe Observer";
        Cells: Codeunit "RVS Send Cells";
        Attempt: Integer;
        O1: Record "RVS Other";
        R1: Record "RVS Row";
    begin
        for Attempt := 1 to 4 do begin
            Cells.StartAttempt(0, false);
            Clear(O1);
            Clear(R1);
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
            Cells.Keep();
        end;
        Cells.Emit(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_IssueLayout()
    var
        Observer: Codeunit "Probe Observer";
        Cells: Codeunit "RVS Send Cells";
        Attempt: Integer;
        O1: Record "RVS Other";
        O2: Record "RVS Other";
        O3: Record "RVS Other";
        R1: Record "RVS Row";
        R2: Record "RVS Row";
    begin
        for Attempt := 1 to 4 do begin
            Cells.StartAttempt(0, false);
            Clear(O1);
            Clear(O2);
            Clear(O3);
            Clear(R1);
            Clear(R2);
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
            Cells.Keep();
        end;
        Cells.Emit(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_AfterOtherModify()
    var
        Observer: Codeunit "Probe Observer";
        Cells: Codeunit "RVS Send Cells";
        Attempt: Integer;
        O1: Record "RVS Other";
        R1: Record "RVS Row";
        R2: Record "RVS Row";
    begin
        for Attempt := 1 to 4 do begin
            Cells.StartAttempt(0, false);
            Clear(O1);
            Clear(R1);
            Clear(R2);
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
            Cells.Keep();
        end;
        Cells.Emit(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsertTrue_OnInsertReadsOther()
    var
        Observer: Codeunit "Probe Observer";
        Cells: Codeunit "RVS Send Cells";
        Attempt: Integer;
        O1: Record "RVS Other";
        T1: Record "RVS Trig Row";
    begin
        for Attempt := 1 to 4 do begin
            Cells.StartAttempt(0, false);
            Clear(O1);
            Clear(T1);
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
            Cells.Keep();
        end;
        Cells.Emit(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_Subscriber()
    var
        Observer: Codeunit "Probe Observer";
        Cells: Codeunit "RVS Send Cells";
        Attempt: Integer;
        S1: Record "RVS Sub Row";
    begin
        for Attempt := 1 to 4 do begin
            Cells.StartAttempt(0, false);
            Clear(S1);
            S1.Id := 1;
            if not S1.Insert() then
                Error('insert failed');
            Cells.Value('value');
            Cells.Fact('subscriber name', S1.Name);
            Cells.Version('row1', S1.SystemRowVersion);
            Cells.Value('value2');
            Cells.NextInsert();
            Cells.Keep();
        end;
        Cells.Emit(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_WithSystemId()
    var
        Observer: Codeunit "Probe Observer";
        Cells: Codeunit "RVS Send Cells";
        Attempt: Integer;
        R1: Record "RVS Row";
    begin
        for Attempt := 1 to 4 do begin
            Cells.StartAttempt(0, false);
            Clear(R1);
            R1.SystemId := CreateGuid();
            R1.Id := 1;
            if not R1.Insert(false, true) then
                Error('insert failed');
            Cells.Value('value');
            Cells.Version('row1', R1.SystemRowVersion);
            Cells.Value('value2');
            Cells.NextInsert();
            Cells.Keep();
        end;
        Cells.Emit(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsertTrue_NoTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Cells: Codeunit "RVS Send Cells";
        Attempt: Integer;
        R1: Record "RVS Row";
    begin
        for Attempt := 1 to 4 do begin
            Cells.StartAttempt(0, false);
            Clear(R1);
            R1.Id := 1;
            if not R1.Insert(true) then
                Error('insert failed');
            Cells.Value('value');
            Cells.Version('row1', R1.SystemRowVersion);
            Cells.Value('value2');
            Cells.NextInsert();
            Cells.Keep();
        end;
        Cells.Emit(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_DuplicateOtherUnsent()
    var
        Observer: Codeunit "Probe Observer";
        Cells: Codeunit "RVS Send Cells";
        Attempt: Integer;
        O1: Record "RVS Other";
        R1: Record "RVS Row";
    begin
        for Attempt := 1 to 4 do begin
            Cells.StartAttempt(1, false);
            Clear(O1);
            Clear(R1);
            O1.Id := 1;
            O1.Insert();
            R1.Id := 1;
            Cells.Fact('inserted', Format(R1.Insert()));
            Cells.Value('value');
            Cells.Version('other1', O1.SystemRowVersion);
            Cells.Value('value2');
            Cells.NextInsert();
            Cells.Keep();
        end;
        Cells.Emit(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_CheckedInsert_TemporaryOtherUnsent()
    var
        Observer: Codeunit "Probe Observer";
        Cells: Codeunit "RVS Send Cells";
        Attempt: Integer;
        O1: Record "RVS Other";
        R1: Record "RVS Row" temporary;
    begin
        for Attempt := 1 to 4 do begin
            Cells.StartAttempt(0, false);
            Clear(O1);
            Clear(R1);
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
            Cells.Keep();
        end;
        Cells.Emit(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_PlainInsert_ValueFirst()
    var
        Observer: Codeunit "Probe Observer";
        Cells: Codeunit "RVS Send Cells";
        Attempt: Integer;
        R1: Record "RVS Row";
    begin
        for Attempt := 1 to 4 do begin
            Cells.StartAttempt(0, false);
            Clear(R1);
            R1.Id := 1;
            R1.Insert();
            Cells.Value('value');
            Cells.Version('row1', R1.SystemRowVersion);
            Cells.Value('value2');
            Cells.NextInsert();
            Cells.Keep();
        end;
        Cells.Emit(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_PlainInsert_BufferReadFirst()
    var
        Observer: Codeunit "Probe Observer";
        Cells: Codeunit "RVS Send Cells";
        Attempt: Integer;
        R1: Record "RVS Row";
        RowVersion: BigInteger;
    begin
        for Attempt := 1 to 4 do begin
            Cells.StartAttempt(0, false);
            Clear(R1);
            R1.Id := 1;
            R1.Insert();
            RowVersion := R1.SystemRowVersion;
            Cells.Value('value');
            Cells.Version('row1', RowVersion);
            Cells.Value('value2');
            Cells.NextInsert();
            Cells.Keep();
        end;
        Cells.Emit(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_PlainInsertTwo_DeleteAll()
    var
        Observer: Codeunit "Probe Observer";
        Cells: Codeunit "RVS Send Cells";
        Attempt: Integer;
        R1: Record "RVS Row";
        R2: Record "RVS Row";
        Row: Record "RVS Row";
    begin
        for Attempt := 1 to 4 do begin
            Cells.StartAttempt(0, false);
            Clear(R1);
            Clear(R2);
            Clear(Row);
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
            Cells.Keep();
        end;
        Cells.Emit(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_PlainInsertTwo_DeleteAllFilteredOther()
    var
        Observer: Codeunit "Probe Observer";
        Cells: Codeunit "RVS Send Cells";
        Attempt: Integer;
        R1: Record "RVS Row";
        R2: Record "RVS Row";
        Row: Record "RVS Row";
    begin
        for Attempt := 1 to 4 do begin
            Cells.StartAttempt(2, false);
            Clear(R1);
            Clear(R2);
            Clear(Row);
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
            Cells.Keep();
        end;
        Cells.Emit(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_PlainInsert_DeleteAllCommittedToo()
    var
        Observer: Codeunit "Probe Observer";
        Cells: Codeunit "RVS Send Cells";
        Attempt: Integer;
        R1: Record "RVS Row";
        Row: Record "RVS Row";
    begin
        for Attempt := 1 to 4 do begin
            Cells.StartAttempt(2, false);
            Clear(R1);
            Clear(Row);
            R1.Id := 10;
            R1.Insert();
            Row.DeleteAll();
            Cells.Value('value');
            Cells.Version('row1', R1.SystemRowVersion);
            Cells.Value('value2');
            Cells.Fact('count', Format(Row.Count()));
            Cells.NextInsert();
            Cells.Keep();
        end;
        Cells.Emit(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_PlainInsertTwo_DeleteAllRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        Cells: Codeunit "RVS Send Cells";
        Attempt: Integer;
        R1: Record "RVS Row";
        R2: Record "RVS Row";
        RecRef: RecordRef;
    begin
        for Attempt := 1 to 4 do begin
            Cells.StartAttempt(0, false);
            Clear(R1);
            Clear(R2);
            Clear(RecRef);
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
            Cells.Keep();
        end;
        Cells.Emit(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure RowVersionSend_PlainInsert_DeleteAllOtherTable()
    var
        Observer: Codeunit "Probe Observer";
        Cells: Codeunit "RVS Send Cells";
        Attempt: Integer;
        R1: Record "RVS Row";
        Other: Record "RVS Other";
    begin
        for Attempt := 1 to 4 do begin
            Cells.StartAttempt(0, true);
            Clear(R1);
            Clear(Other);
            R1.Id := 1;
            R1.Insert();
            Other.DeleteAll();
            Cells.Value('value');
            Cells.Version('row1', R1.SystemRowVersion);
            Cells.Value('value2');
            Cells.NextInsert();
            Cells.Keep();
        end;
        Cells.Emit(Observer);
        Observer.Finish();
    end;
}
