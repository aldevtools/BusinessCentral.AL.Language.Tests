// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-lastusedrowversion-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 76640 and 76641
// Probe: Database.LastUsedRowVersion() and Database.MinimumActiveRowVersion() after each write shape of an open transaction, measured against
// the value read before the write and against the SystemRowVersion of the row written last (AL Runner issue 8671). RowVersionWrites.al pins
// only that the value grows (greater) after Delete, DeleteAll, Truncate, Rename and ModifyAll after an Insert. This file adds where the value
// lands: a plain Modify after an Insert of the same row (no read between), a checked Insert, a Get and Modify after an Insert, a Modify of a
// committed row, DeleteAll with no Insert before it (unfiltered, filtered, on an empty table), DeleteAll (unfiltered and filtered) and Truncate
// after an Insert, Delete, Rename and ModifyAll after an Insert, writes to two tables, and the write order of the issue (DeleteAll on two tables,
// Insert and Modify, inserts, checked inserts, Get and Modify). After most steps the next Insert's row version is compared with the value + 1.
// Each test empties both tables and commits, then writes in one open transaction with no Commit until the observations are taken.
// Only relations are asserted (same, greater, less), never a row version number: the numbers differ per database.
// Observation names: <step> last/prev is LastUsedRowVersion() against its read before the step; last/row against the SystemRowVersion of the
// row the step wrote (from the record buffer, no re-read); min/min0 is MinimumActiveRowVersion() against its read at the start of the test;
// min/last1 against LastUsedRowVersion() + 1; next/last1 is the buffer SystemRowVersion of a fresh Insert into "RVS Other" against the
// value + 1 read before it.
// Measured on BC 29.0 (local run; 27.5 and 28.5 see the PR run): every write that sends a row (Insert followed by another statement, a checked
// Insert, Modify, Get and Modify, Rename, Delete or DeleteAll of inserted rows, writes to a second table) leaves LastUsedRowVersion() equal to
// the SystemRowVersion of the row written last. A Modify (also right after the row's own Insert) and a Rename give the row a greater
// SystemRowVersion than before. DeleteAll with no Insert before it (unfiltered, filtered, empty table) and a Get leave the value the same.
// A Delete or DeleteAll (any filter) after an Insert makes the value the inserted row's version. Truncate and ModifyAll after an Insert make it
// greater than the inserted row's version; after ModifyAll the last modified row equals the value and the first is below it. In two tables, the
// second table's inserted row is below the first table's row version. MinimumActiveRowVersion() stays at its start value and below
// LastUsedRowVersion() + 1 in every shape. After every shape the next Insert gets LastUsedRowVersion() + 1.
// LastUsedRowVersion() is database wide, and corpus CI runs the whole app, so other sessions can write between two reads. Such a write only
// raises the value. The next-Insert check and the ModifyAll row-against-value check therefore retry (up to five times) until one try lands
// on "same"; a "same" can only come from BC itself. Truncate after Insert is observed but not asserted against the row: BC on Linux differs.
// BC versions: 27+

table 76640 "RVS Row"
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

table 76641 "RVS Other"
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

// local object: the shared steps of the write shape tests.
codeunit 76642 "RVS Steps"
{
    var
        Prev: BigInteger;
        Min0: BigInteger;
        NextId: Integer;

    procedure Rel(Value: BigInteger; Other: BigInteger): Text
    begin
        if Value = Other then
            exit('same');
        if Value > Other then
            exit('greater');
        exit('less');
    end;

    // Empties both tables, seeds Seed committed rows 1..Seed in "RVS Row", commits, then reads the start values.
    procedure Start(Seed: Integer)
    var
        Row: Record "RVS Row";
        Other: Record "RVS Other";
        i: Integer;
    begin
        Row.DeleteAll();
        Other.DeleteAll();
        for i := 1 to Seed do begin
            Row.Init();
            Row.Id := i;
            Row.Insert();
        end;
        Commit();
        NextId := 1000;
        Prev := LastUsedRowVersion();
        Min0 := MinimumActiveRowVersion();
    end;

    procedure Snap(var Observer: Codeunit "Probe Observer"; Tag: Text; RowVersion: BigInteger)
    var
        Last: BigInteger;
        MinActive: BigInteger;
    begin
        Last := LastUsedRowVersion();
        MinActive := MinimumActiveRowVersion();
        Observer.Observe(Tag + ' last/prev', Rel(Last, Prev));
        if RowVersion <> 0 then
            Observer.Observe(Tag + ' last/row', Rel(Last, RowVersion));
        Observer.Observe(Tag + ' min/min0', Rel(MinActive, Min0));
        Observer.Observe(Tag + ' min/last1', Rel(MinActive, Last + 1));
        Prev := Last;
    end;

    // LastUsedRowVersion() is database wide: a write of another session between the read and the Insert gives the row a greater version.
    // Such a write can only raise the row's version, never make it equal to the value + 1, so up to five Inserts are tried and the first
    // one that lands on the value + 1 ends the loop; the observation is the relation of the last try.
    procedure Next(var Observer: Codeunit "Probe Observer"; Tag: Text)
    var
        Other: Record "RVS Other";
        Last: BigInteger;
        Attempt: Integer;
    begin
        repeat
            Attempt += 1;
            Last := LastUsedRowVersion();
            NextId += 1;
            Other.Id := NextId;
            Other.Insert();
        until (Other.SystemRowVersion = Last + 1) or (Attempt = 5);
        Observer.Observe(Tag + ' next/last1', Rel(Other.SystemRowVersion, Last + 1));
        Prev := LastUsedRowVersion();
    end;

    procedure InsertRow(Id: Integer): BigInteger
    var
        Row: Record "RVS Row";
    begin
        Row.Id := Id;
        Row.Insert();
        exit(Row.SystemRowVersion);
    end;
}

codeunit 76643 "RVS Write Shapes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure RowVersion_ModifyAfterInsert()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVS Steps";
        Row: Record "RVS Row";
        Ins: BigInteger;
    begin
        Steps.Start(0);
        Row.Id := 1;
        Row.Insert();
        Ins := Row.SystemRowVersion;
        Row.Name := 'x';
        Row.Modify();
        Observer.Observe('modify row/ins', Steps.Rel(Row.SystemRowVersion, Ins));
        Steps.Snap(Observer, 'modify', Row.SystemRowVersion);
        Row.Get(1);
        Steps.Snap(Observer, 'get', Row.SystemRowVersion);
        Steps.Next(Observer, 'after');
        Observer.Expect('modify row/ins', 'greater');
        Observer.Expect('modify last/prev', 'greater');
        Observer.Expect('modify last/row', 'same');
        Observer.Expect('modify min/min0', 'same');
        Observer.Expect('modify min/last1', 'less');
        Observer.Expect('get last/prev', 'same');
        Observer.Expect('get last/row', 'same');
        Observer.Expect('get min/min0', 'same');
        Observer.Expect('get min/last1', 'less');
        Observer.Expect('after next/last1', 'same');
        Observer.Verify();
    end;

    [Test]
    procedure RowVersion_CheckedInsert()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVS Steps";
        Row: Record "RVS Row";
    begin
        Steps.Start(0);
        Row.Id := 1;
        if not Row.Insert() then
            Error('insert failed');
        Steps.Snap(Observer, 'checked1', Row.SystemRowVersion);
        Row.Id := 2;
        if not Row.Insert() then
            Error('insert failed');
        Steps.Snap(Observer, 'checked2', Row.SystemRowVersion);
        Steps.Next(Observer, 'after');
        Observer.Expect('checked1 last/prev', 'greater');
        Observer.Expect('checked1 last/row', 'same');
        Observer.Expect('checked1 min/min0', 'same');
        Observer.Expect('checked1 min/last1', 'less');
        Observer.Expect('checked2 last/prev', 'greater');
        Observer.Expect('checked2 last/row', 'same');
        Observer.Expect('checked2 min/min0', 'same');
        Observer.Expect('checked2 min/last1', 'less');
        Observer.Expect('after next/last1', 'same');
        Observer.Verify();
    end;

    [Test]
    procedure RowVersion_GetModifyAfterInsert()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVS Steps";
        Row: Record "RVS Row";
    begin
        Steps.Start(0);
        Steps.InsertRow(1);
        Steps.InsertRow(2);
        Row.Get(1);
        Row.Name := 'x';
        Row.Modify();
        Steps.Snap(Observer, 'getmodify', Row.SystemRowVersion);
        Steps.Next(Observer, 'after');
        Observer.Expect('getmodify last/prev', 'greater');
        Observer.Expect('getmodify last/row', 'same');
        Observer.Expect('getmodify min/min0', 'same');
        Observer.Expect('getmodify min/last1', 'less');
        Observer.Expect('after next/last1', 'same');
        Observer.Verify();
    end;

    [Test]
    procedure RowVersion_ModifyCommittedRow()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVS Steps";
        Row: Record "RVS Row";
        Before: BigInteger;
    begin
        Steps.Start(2);
        Row.Get(1);
        Before := Row.SystemRowVersion;
        Row.Name := 'x';
        Row.Modify();
        Observer.Observe('modify row/before', Steps.Rel(Row.SystemRowVersion, Before));
        Steps.Snap(Observer, 'modify', Row.SystemRowVersion);
        Row.Name := 'y';
        Row.Modify();
        Steps.Snap(Observer, 'modify2', Row.SystemRowVersion);
        Steps.Next(Observer, 'after');
        Observer.Expect('modify row/before', 'greater');
        Observer.Expect('modify last/prev', 'greater');
        Observer.Expect('modify last/row', 'same');
        Observer.Expect('modify min/min0', 'same');
        Observer.Expect('modify min/last1', 'less');
        Observer.Expect('modify2 last/prev', 'greater');
        Observer.Expect('modify2 last/row', 'same');
        Observer.Expect('modify2 min/min0', 'same');
        Observer.Expect('modify2 min/last1', 'less');
        Observer.Expect('after next/last1', 'same');
        Observer.Verify();
    end;

    [Test]
    procedure RowVersion_DeleteAllNoInsert_Unfiltered()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVS Steps";
        Row: Record "RVS Row";
    begin
        Steps.Start(3);
        Row.DeleteAll();
        Steps.Snap(Observer, 'deleteall', 0);
        Observer.Observe('count', Format(Row.Count()));
        Steps.Next(Observer, 'after');
        Observer.Expect('deleteall last/prev', 'same');
        Observer.Expect('deleteall min/min0', 'same');
        Observer.Expect('deleteall min/last1', 'less');
        Observer.Expect('count', '0');
        Observer.Expect('after next/last1', 'same');
        Observer.Verify();
    end;

    [Test]
    procedure RowVersion_DeleteAllNoInsert_Filtered()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVS Steps";
        Row: Record "RVS Row";
    begin
        Steps.Start(3);
        Row.SetFilter(Id, '2..');
        Row.DeleteAll();
        Steps.Snap(Observer, 'deleteall', 0);
        Row.Reset();
        Observer.Observe('count', Format(Row.Count()));
        Steps.Next(Observer, 'after');
        Observer.Expect('deleteall last/prev', 'same');
        Observer.Expect('deleteall min/min0', 'same');
        Observer.Expect('deleteall min/last1', 'less');
        Observer.Expect('count', '1');
        Observer.Expect('after next/last1', 'same');
        Observer.Verify();
    end;

    [Test]
    procedure RowVersion_DeleteAllNoInsert_EmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVS Steps";
        Row: Record "RVS Row";
    begin
        Steps.Start(0);
        Row.DeleteAll();
        Steps.Snap(Observer, 'deleteall', 0);
        Steps.Next(Observer, 'after');
        Observer.Expect('deleteall last/prev', 'same');
        Observer.Expect('deleteall min/min0', 'same');
        Observer.Expect('deleteall min/last1', 'less');
        Observer.Expect('after next/last1', 'same');
        Observer.Verify();
    end;

    [Test]
    procedure RowVersion_DeleteAllAfterInsert_Unfiltered()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVS Steps";
        Row: Record "RVS Row";
        Ins: BigInteger;
    begin
        Steps.Start(0);
        Steps.InsertRow(1);
        Ins := Steps.InsertRow(2);
        Row.DeleteAll();
        Steps.Snap(Observer, 'deleteall', Ins);
        Steps.Next(Observer, 'after');
        Observer.Expect('deleteall last/prev', 'greater');
        Observer.Expect('deleteall last/row', 'same');
        Observer.Expect('deleteall min/min0', 'same');
        Observer.Expect('deleteall min/last1', 'less');
        Observer.Expect('after next/last1', 'same');
        Observer.Verify();
    end;

    [Test]
    procedure RowVersion_DeleteAllAfterInsert_FilteredOtherRows()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVS Steps";
        Row: Record "RVS Row";
        Ins: BigInteger;
    begin
        Steps.Start(2);
        Ins := Steps.InsertRow(10);
        Row.SetRange(Id, 1, 2);
        Row.DeleteAll();
        Steps.Snap(Observer, 'deleteall', Ins);
        Row.Reset();
        Observer.Observe('count', Format(Row.Count()));
        Steps.Next(Observer, 'after');
        Observer.Expect('deleteall last/prev', 'greater');
        Observer.Expect('deleteall last/row', 'same');
        Observer.Expect('deleteall min/min0', 'same');
        Observer.Expect('deleteall min/last1', 'less');
        Observer.Expect('count', '1');
        Observer.Expect('after next/last1', 'same');
        Observer.Verify();
    end;

    [Test]
    procedure RowVersion_DeleteAllAfterInsert_CommittedRowsToo()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVS Steps";
        Row: Record "RVS Row";
        Ins: BigInteger;
    begin
        Steps.Start(2);
        Ins := Steps.InsertRow(10);
        Row.DeleteAll();
        Steps.Snap(Observer, 'deleteall', Ins);
        Steps.Next(Observer, 'after');
        Observer.Expect('deleteall last/prev', 'greater');
        Observer.Expect('deleteall last/row', 'same');
        Observer.Expect('deleteall min/min0', 'same');
        Observer.Expect('deleteall min/last1', 'less');
        Observer.Expect('after next/last1', 'same');
        Observer.Verify();
    end;

    [Test]
    procedure RowVersion_TruncateAfterInsert()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVS Steps";
        Row: Record "RVS Row";
        Ins: BigInteger;
    begin
        Steps.Start(0);
        Ins := Steps.InsertRow(1);
        Row.Truncate();
        Steps.Snap(Observer, 'truncate', Ins);
        Steps.Next(Observer, 'after');
        // 'truncate last/row' is observed, not asserted: BC on Windows (27.5, 29.0) gives greater, BC on Linux in corpus CI gives same on
        // 27.5, 28.5 and 29.0. Linux suspect, see https://github.com/aldevtools/MsDyn365Bc.On.Linux/issues/243
        Observer.Ignore('truncate last/row');
        Observer.Expect('truncate last/prev', 'greater');
        Observer.Expect('truncate min/min0', 'same');
        Observer.Expect('truncate min/last1', 'less');
        Observer.Expect('after next/last1', 'same');
        Observer.Verify();
    end;

    [Test]
    procedure RowVersion_DeleteAfterInsert()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVS Steps";
        Row: Record "RVS Row";
        Ins: BigInteger;
    begin
        Steps.Start(0);
        Row.Id := 1;
        Row.Insert();
        Ins := Row.SystemRowVersion;
        Row.Delete();
        Steps.Snap(Observer, 'delete', Ins);
        Steps.Next(Observer, 'after');
        Observer.Expect('delete last/prev', 'greater');
        Observer.Expect('delete last/row', 'same');
        Observer.Expect('delete min/min0', 'same');
        Observer.Expect('delete min/last1', 'less');
        Observer.Expect('after next/last1', 'same');
        Observer.Verify();
    end;

    [Test]
    procedure RowVersion_RenameAfterInsert()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVS Steps";
        Row: Record "RVS Row";
        Ins: BigInteger;
    begin
        Steps.Start(0);
        Row.Id := 1;
        Row.Insert();
        Ins := Row.SystemRowVersion;
        Row.Rename(2);
        Observer.Observe('rename row/ins', Steps.Rel(Row.SystemRowVersion, Ins));
        Steps.Snap(Observer, 'rename', Row.SystemRowVersion);
        Steps.Next(Observer, 'after');
        Observer.Expect('rename row/ins', 'greater');
        Observer.Expect('rename last/prev', 'greater');
        Observer.Expect('rename last/row', 'same');
        Observer.Expect('rename min/min0', 'same');
        Observer.Expect('rename min/last1', 'less');
        Observer.Expect('after next/last1', 'same');
        Observer.Verify();
    end;

    [Test]
    procedure RowVersion_ModifyAllAfterInsert()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVS Steps";
        Row: Record "RVS Row";
        Ins: BigInteger;
        Last: BigInteger;
        Version2: BigInteger;
        Row2: Integer;
        Attempt: Integer;
    begin
        Steps.Start(0);
        Steps.InsertRow(1);
        Ins := Steps.InsertRow(2);
        Row.ModifyAll(Name, 'x');
        Steps.Snap(Observer, 'modifyall', Ins);
        // LastUsedRowVersion() is database wide: a write of another session after the ModifyAll raises it above the last modified row.
        // Such a write can never make the two equal, so the shape (DeleteAll, two Inserts, ModifyAll) is repeated up to four more times
        // until one try has the last modified row equal to the value; the row observations are those of the last try.
        Row2 := 2;
        repeat
            Attempt += 1;
            if Attempt > 1 then begin
                Row.DeleteAll();
                Steps.InsertRow(Row2 + 1);
                Steps.InsertRow(Row2 + 2);
                Row2 += 2;
                Row.ModifyAll(Name, 'x');
            end;
            Last := LastUsedRowVersion();
            Row.Get(Row2);
            Version2 := Row.SystemRowVersion;
        until (Version2 = Last) or (Attempt = 5);
        Observer.Observe('modifyall row2/last', Steps.Rel(Version2, Last));
        Row.Get(Row2 - 1);
        Observer.Observe('modifyall row1/last', Steps.Rel(Row.SystemRowVersion, Last));
        Observer.Observe('modifyall row1/row2', Steps.Rel(Row.SystemRowVersion, Version2));
        Steps.Next(Observer, 'after');
        Observer.Expect('modifyall last/prev', 'greater');
        Observer.Expect('modifyall last/row', 'greater');
        Observer.Expect('modifyall min/min0', 'same');
        Observer.Expect('modifyall min/last1', 'less');
        Observer.Expect('modifyall row2/last', 'same');
        Observer.Expect('modifyall row1/last', 'less');
        Observer.Expect('modifyall row1/row2', 'less');
        Observer.Expect('after next/last1', 'same');
        Observer.Verify();
    end;

    [Test]
    procedure RowVersion_TwoTables()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVS Steps";
        Row: Record "RVS Row";
        Other: Record "RVS Other";
    begin
        Steps.Start(0);
        Row.Id := 1;
        Row.Insert();
        Other.Id := 1;
        Other.Insert();
        Steps.Snap(Observer, 'insert2', Other.SystemRowVersion);
        Observer.Observe('insert2 other/row', Steps.Rel(Other.SystemRowVersion, Row.SystemRowVersion));
        Row.Name := 'x';
        Row.Modify();
        Steps.Snap(Observer, 'modify1', Row.SystemRowVersion);
        Other.Name := 'y';
        Other.Modify();
        Steps.Snap(Observer, 'modify2', Other.SystemRowVersion);
        Steps.Next(Observer, 'after');
        Observer.Expect('insert2 last/prev', 'greater');
        Observer.Expect('insert2 last/row', 'same');
        Observer.Expect('insert2 min/min0', 'same');
        Observer.Expect('insert2 min/last1', 'less');
        Observer.Expect('insert2 other/row', 'less');
        Observer.Expect('modify1 last/prev', 'greater');
        Observer.Expect('modify1 last/row', 'same');
        Observer.Expect('modify1 min/min0', 'same');
        Observer.Expect('modify1 min/last1', 'less');
        Observer.Expect('modify2 last/prev', 'greater');
        Observer.Expect('modify2 last/row', 'same');
        Observer.Expect('modify2 min/min0', 'same');
        Observer.Expect('modify2 min/last1', 'less');
        Observer.Expect('after next/last1', 'same');
        Observer.Verify();
    end;

    // The write order of AL Runner issue 8671: DeleteAll on two tables (one filtered), an Insert and Modify of a setup row, three inserts on
    // another table, the watermark, two checked inserts, the value, Get and Modify of one of them, the value.
    [Test]
    procedure RowVersion_IssueWriteOrder()
    var
        Observer: Codeunit "Probe Observer";
        Steps: Codeunit "RVS Steps";
        Row: Record "RVS Row";
        Other: Record "RVS Other";
        i: Integer;
    begin
        Steps.Start(3);
        Row.SetFilter(Id, '2..');
        Row.DeleteAll();
        Other.DeleteAll();
        Other.Id := 1;
        Other.Insert();
        Other.Name := 'setup';
        Other.Modify();
        for i := 1 to 3 do
            Steps.InsertRow(100 + i);
        Steps.Snap(Observer, 'watermark', 0);
        Row.Reset();
        Row.Id := 201;
        if not Row.Insert() then
            Error('insert failed');
        Row.Id := 202;
        if not Row.Insert() then
            Error('insert failed');
        Steps.Snap(Observer, 'checked', Row.SystemRowVersion);
        Row.Get(201);
        Row.Name := 'x';
        Row.Modify();
        Steps.Snap(Observer, 'modify', Row.SystemRowVersion);
        Observer.Expect('watermark last/prev', 'greater');
        Observer.Expect('watermark min/min0', 'same');
        Observer.Expect('watermark min/last1', 'less');
        Observer.Expect('checked last/prev', 'greater');
        Observer.Expect('checked last/row', 'same');
        Observer.Expect('checked min/min0', 'same');
        Observer.Expect('checked min/last1', 'less');
        Observer.Expect('modify last/prev', 'greater');
        Observer.Expect('modify last/row', 'same');
        Observer.Expect('modify min/min0', 'same');
        Observer.Expect('modify min/last1', 'less');
        Observer.Verify();
    end;
}
