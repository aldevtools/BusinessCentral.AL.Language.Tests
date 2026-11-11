// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-insert-method
// Scope: in-scope
// local object: the insert counts and the keys are what is under test, so the probe needs its own tables
// Fixtures used: Probe Observer (codeunit 69160); own tables 99671 to 99673, test codeunit 99671
// Probe (al-runner issue 7407): when does a statement-form Insert of an existing key raise, and which row can it duplicate? The corpus pins
//   that a duplicate Insert into a table without a Blob field raises at the next access to the table, at Commit or at the end of the test
//   (errors/last-error/InsertDuplicateKeyExcludeFlag.al, record/TestRecordRuntimeTextsAndViews.al), for a few inserts in a row. It does not pin
//   what happens once more inserts went into the table in the same transaction (Microsoft Learn: BufferedInsertEnabled, "up to 5 rows will be
//   buffered in the table queue before they are inserted"). Cells: the duplicate as the 2nd to the 7th insert of one transaction (a row still
//   in the buffer, and a row already sent when the buffer filled), with and without a Commit before, an Enum key, a table with a Blob field as
//   the control, and the shape of the report: the same four inserts a second time.
// Readings per cell: whether the statement after the duplicate Insert is reached inside the asserterror (the Insert raised at once or not),
//   the error text and code, and the rows in the table after the asserterror.
// BC versions: 27, 28, 29

enum 99671 "LT DB Kind"
{
    Extensible = true;
    value(0; Alpha) { }
    value(1; Beta) { }
    value(2; Gamma) { }
    value(3; Delta) { }
}

table 99671 "LT DB Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Note; Text[30]) { }
    }

    keys { key(PK; Code) { Clustered = true; } }
}

table 99672 "LT DB Kind Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Kind; Enum "LT DB Kind") { }
        field(2; Note; Text[30]) { }
    }

    keys { key(PK; Kind) { Clustered = true; } }
}

table 99673 "LT DB Blob Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Data; Blob) { }
    }

    keys { key(PK; Code) { Clustered = true; } }
}

codeunit 99671 "LT DB Duplicate Buffer"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure InsertRows(Count: Integer)
    var
        Row: Record "LT DB Row";
        i: Integer;
    begin
        for i := 1 to Count do begin
            Row.Init();
            Row.Code := 'K' + Format(i);
            Row.Insert();
        end;
    end;

    // Inserts Rows rows, commits after CommitAfter of them (0: no Commit), then inserts the key DupOf again inside an asserterror
    // that reads the table afterwards.
    local procedure DuplicateAfter(var Observer: Codeunit "Probe Observer"; Rows: Integer; CommitAfter: Integer; DupOf: Code[10])
    var
        Row: Record "LT DB Row";
        Dup: Record "LT DB Row";
        i: Integer;
    begin
        Row.DeleteAll();
        Commit();
        for i := 1 to Rows do begin
            Row.Init();
            Row.Code := 'K' + Format(i);
            Row.Insert();
            if i = CommitAfter then
                Commit();
        end;
        asserterror
        begin
            Dup.Init();
            Dup.Code := DupOf;
            Dup.Insert();
            Observer.Observe('statement after the duplicate Insert reached', 'yes');
            Observer.Observe('count read', Format(Row.Count()));
        end;
        Observer.ObserveError('duplicate');
        Observer.Observe('rows after', Format(Row.Count()));
        Row.DeleteAll();
        Commit();
    end;

    [Test]
    procedure Dup_2ndInsert_OfFirstRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DuplicateAfter(Observer, 1, 0, 'K1');
        Observer.Expect('statement after the duplicate Insert reached', 'yes');
        Observer.Expect('duplicate|text', 'The record in table LT DB Row already exists. Identification fields and values: Code=''K1''');
        Observer.Expect('duplicate|code', 'DB:RecordExists');
        Observer.Expect('rows after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Dup_3rdInsert_OfFirstRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DuplicateAfter(Observer, 2, 0, 'K1');
        Observer.Expect('statement after the duplicate Insert reached', 'yes');
        Observer.Expect('duplicate|text', 'The record in table LT DB Row already exists. Identification fields and values: Code=''K1''');
        Observer.Expect('duplicate|code', 'DB:RecordExists');
        Observer.Expect('rows after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Dup_4thInsert_OfFirstRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DuplicateAfter(Observer, 3, 0, 'K1');
        Observer.Expect('statement after the duplicate Insert reached', 'yes');
        Observer.Expect('duplicate|text', 'The record in table LT DB Row already exists. Identification fields and values: Code=''K1''');
        Observer.Expect('duplicate|code', 'DB:RecordExists');
        Observer.Expect('rows after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Dup_5thInsert_OfFirstRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DuplicateAfter(Observer, 4, 0, 'K1');
        Observer.Expect('duplicate|text', 'The record in table LT DB Row already exists. Identification fields and values: Code=''K1''');
        Observer.Expect('duplicate|code', 'DB:RecordExists');
        Observer.Expect('rows after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Dup_6thInsert_OfFirstRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DuplicateAfter(Observer, 5, 0, 'K1');
        Observer.Expect('statement after the duplicate Insert reached', 'yes');
        Observer.Expect('duplicate|text', 'The record in table LT DB Row already exists. Identification fields and values: Code=''K1''');
        Observer.Expect('duplicate|code', 'DB:RecordExists');
        Observer.Expect('rows after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Dup_7thInsert_OfFirstRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DuplicateAfter(Observer, 6, 0, 'K1');
        Observer.Expect('statement after the duplicate Insert reached', 'yes');
        Observer.Expect('duplicate|text', 'The record in table LT DB Row already exists. Identification fields and values: Code=''K1''');
        Observer.Expect('duplicate|code', 'DB:RecordExists');
        Observer.Expect('rows after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Dup_6thInsert_OfLastRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DuplicateAfter(Observer, 5, 0, 'K5');
        Observer.Expect('statement after the duplicate Insert reached', 'yes');
        Observer.Expect('duplicate|text', 'The record in table LT DB Row already exists. Identification fields and values: Code=''K5''');
        Observer.Expect('duplicate|code', 'DB:RecordExists');
        Observer.Expect('rows after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Dup_7thInsert_OfFourthRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DuplicateAfter(Observer, 6, 0, 'K4');
        Observer.Expect('statement after the duplicate Insert reached', 'yes');
        Observer.Expect('duplicate|text', 'The record in table LT DB Row already exists. Identification fields and values: Code=''K4''');
        Observer.Expect('duplicate|code', 'DB:RecordExists');
        Observer.Expect('rows after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Dup_3rdInsert_OfCommittedRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DuplicateAfter(Observer, 2, 1, 'K1');
        Observer.Expect('statement after the duplicate Insert reached', 'yes');
        Observer.Expect('duplicate|text', 'The record in table LT DB Row already exists. Identification fields and values: Code=''K1''');
        Observer.Expect('duplicate|code', 'DB:RecordExists');
        Observer.Expect('rows after', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Dup_6thInsert_OfCommittedRow_CommitAfter3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DuplicateAfter(Observer, 5, 3, 'K1');
        Observer.Expect('statement after the duplicate Insert reached', 'yes');
        Observer.Expect('duplicate|text', 'The record in table LT DB Row already exists. Identification fields and values: Code=''K1''');
        Observer.Expect('duplicate|code', 'DB:RecordExists');
        Observer.Expect('rows after', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Dup_6thInsert_OfRowAfterCommit_CommitAfter2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DuplicateAfter(Observer, 5, 2, 'K4');
        Observer.Expect('statement after the duplicate Insert reached', 'yes');
        Observer.Expect('duplicate|text', 'The record in table LT DB Row already exists. Identification fields and values: Code=''K4''');
        Observer.Expect('duplicate|code', 'DB:RecordExists');
        Observer.Expect('rows after', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Dup_5thInsert_OfCommittedRow_CommitAfter4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DuplicateAfter(Observer, 4, 4, 'K1');
        Observer.Expect('statement after the duplicate Insert reached', 'yes');
        Observer.Expect('duplicate|text', 'The record in table LT DB Row already exists. Identification fields and values: Code=''K1''');
        Observer.Expect('duplicate|code', 'DB:RecordExists');
        Observer.Expect('rows after', '4');
        Observer.Verify();
    end;

    // The report: one call inserts four rows, the second call inserts the same four keys, no Commit, nothing reads the table in between.
    [Test]
    procedure Report_FourRowsTwice_NoRead()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT DB Row";
    begin
        Row.DeleteAll();
        Commit();
        InsertRows(4);
        asserterror
        begin
            InsertRows(4);
            Observer.Observe('second call finished without an error', 'yes');
        end;
        Observer.ObserveError('second call');
        Observer.Observe('rows after', Format(Row.Count()));
        Row.DeleteAll();
        Commit();
        Observer.Expect('second call|text', 'The record in table LT DB Row already exists. Identification fields and values: Code=''K1''');
        Observer.Expect('second call|code', 'DB:RecordExists');
        Observer.Expect('rows after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Report_FiveRowsTwice_NoRead()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT DB Row";
    begin
        Row.DeleteAll();
        Commit();
        InsertRows(5);
        asserterror
        begin
            InsertRows(5);
            Observer.Observe('second call finished without an error', 'yes');
        end;
        Observer.ObserveError('second call');
        Observer.Observe('rows after', Format(Row.Count()));
        Row.DeleteAll();
        Commit();
        Observer.Expect('second call|text', 'The record in table LT DB Row already exists. Identification fields and values: Code=''K1''');
        Observer.Expect('second call|code', 'DB:RecordExists');
        Observer.Expect('rows after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Report_FourRowsTwice_CommitBetween()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT DB Row";
    begin
        Row.DeleteAll();
        Commit();
        InsertRows(4);
        Commit();
        InsertRows(4);
        Observer.Observe('second call finished without an error', 'yes');
        asserterror if Row.Count() = 0 then;
        Observer.ObserveError('first read after the second call');
        Observer.Observe('rows after', Format(Row.Count()));
        Row.DeleteAll();
        Commit();
        Observer.Expect('second call finished without an error', 'yes');
        Observer.Expect('first read after the second call|text', 'The record in table LT DB Row already exists. Identification fields and values: Code=''K1''');
        Observer.Expect('first read after the second call|code', 'DB:RecordExists');
        Observer.Expect('rows after', '4');
        Observer.Verify();
    end;

    // The same cells with an Enum primary key (the report's table).
    local procedure InsertKinds(Count: Integer)
    var
        Row: Record "LT DB Kind Row";
        i: Integer;
    begin
        for i := 0 to Count - 1 do begin
            Row.Init();
            Row.Kind := Enum::"LT DB Kind".FromInteger(i);
            Row.Insert();
        end;
    end;

    [Test]
    procedure EnumKey_FourRowsTwice_NoRead()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT DB Kind Row";
    begin
        Row.DeleteAll();
        Commit();
        InsertKinds(4);
        asserterror
        begin
            InsertKinds(4);
            Observer.Observe('second call finished without an error', 'yes');
        end;
        Observer.ObserveError('second call');
        Observer.Observe('rows after', Format(Row.Count()));
        Row.DeleteAll();
        Commit();
        Observer.Expect('second call|text', 'The record in table LT DB Kind Row already exists. Identification fields and values: Kind=''Alpha''');
        Observer.Expect('second call|code', 'DB:RecordExists');
        Observer.Expect('rows after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure EnumKey_2ndInsert_Dup_ThenRead()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT DB Kind Row";
    begin
        Row.DeleteAll();
        Commit();
        InsertKinds(1);
        asserterror
        begin
            InsertKinds(1);
            Observer.Observe('statement after the duplicate Insert reached', 'yes');
            Observer.Observe('count read', Format(Row.Count()));
        end;
        Observer.ObserveError('duplicate');
        Row.DeleteAll();
        Commit();
        Observer.Expect('statement after the duplicate Insert reached', 'yes');
        Observer.Expect('duplicate|text', 'The record in table LT DB Kind Row already exists. Identification fields and values: Kind=''Alpha''');
        Observer.Expect('duplicate|code', 'DB:RecordExists');
        Observer.Verify();
    end;

    // Control: a table with a Blob field raises at the Insert itself.
    [Test]
    procedure BlobTable_2ndInsert_Dup()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT DB Blob Row";
    begin
        Row.DeleteAll();
        Commit();
        Row.Init();
        Row.Code := 'B1';
        Row.Insert();
        asserterror
        begin
            Row.Init();
            Row.Code := 'B1';
            Row.Insert();
            Observer.Observe('statement after the duplicate Insert reached', 'yes');
        end;
        Observer.ObserveError('duplicate');
        Row.DeleteAll();
        Commit();
        Observer.Expect('duplicate|text', 'The record in table LT DB Blob Row already exists. Identification fields and values: Code=''B1''');
        Observer.Expect('duplicate|code', 'DB:RecordExists');
        Observer.Verify();
    end;
}
