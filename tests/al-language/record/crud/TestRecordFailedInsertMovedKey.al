// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 87210, test codeunit 87211
// local object: the test must commit (the seed, and the Commit between the two calls of cell P8)
// Probe (al-runner issue 8721): a record variable that takes another row's buffer (`Copy := Src`), moves its key to a row that
//   exists (`Copy.Code := 'TARGET'`), whose `Insert(true)` then fails, and which is modified after that (`TransferFields(Src, false)`
//   and `Modify(true)`, the upsert shape). The buffer's row version came from the source row, never from the target row. Question:
//   does BC raise DB:RecordChanged on that Modify, and on which shapes. Neighbours of Y71FailedInsertModify.al (same key) and of
//   CodeunitRunTableNoWrites.al part four (one buffer over two rows that already exist).
//   P1  the upsert twice: the 1st Insert creates TARGET after Src was read, the 2nd Insert fails, TransferFields, Modify(true).
//   P2  as P1, TARGET modified through a 2nd variable between the two calls.
//   P3  as P1, SOURCE modified through a 2nd variable between the two calls.
//   P4  as P1, the 2nd call does Modify() with no TransferFields.
//   P5  as P1, Src read by SetRange + FindFirst in place of Get.
//   P6  the buffer's version from its own Insert of another key (OWN), TARGET inserted after that by another call, then the buffer's
//       key moved to TARGET, Insert(true) fails, TransferFields, Modify(true).
//   P7  TARGET inserted BEFORE SOURCE (its version is older than Src's read), a 2nd variable modifies TARGET AFTER Src.Get, then
//       the upsert once. Tells "the moved key's version does not count" (written, stored TARGET=new) from "a row changed after the
//       read raises even through a moved key" (DB:RecordChanged, stored TARGET=old after the rollback).
//   P8  as P1, with a Commit between the two calls.
// Between the two calls of P1..P6 and P8 the test sets Src.Name := 'second' in memory only (no write, no new row version), so the
//   stored TARGET row shows whether the 2nd Modify was written ('second') or not.
// Per cell: insert=<ok|fail> per Insert in order, raised=none or <code>/<text>, stored=<Code>=<Name> of every row in key order
//   (read inside the asserterror block when nothing was raised, else after the rollback).
// Cells Q1a, Q1b and Q2-Q7 (round 2) are described above their tests at the end of the codeunit.
// Measured on BC 29.0 (all 16 cells in one run; asserted verbatim). Facts: the Modify after the failed Insert raises DB:RecordChanged
//   when the buffer's version was read before this transaction wrote to the table (P1-P5, P7, P8, and Q3, where only ANOTHER table
//   was written before the read). It is written when the same table was written in the transaction before the version reached the
//   buffer: an uncommitted seed (Q1a, Q1b, Q4 even with a Commit after the read), a row X of the same table (Q2), a 2nd variable's
//   Modify of the source row (Q5), or the buffer's own Insert (P6, Q6 even with a Commit after it; Q7 with its own Modify).
//   asserterror around the 2nd call does not change the outcome (Q1a = Q1b).
// BC versions: 29 measured; 27 and 28 by the corpus CI matrix

table 87210 "REC MovedKey Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Name; Text[50]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 87211 "REC MovedKey Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";
        Inserts: Text;
        StoredInside: Text;
        NoErrorTxt: Label 'REC_MOVEDKEY_NO_ERROR', Locked = true;

    local procedure Seed(TargetFirst: Boolean)
    var
        Row: Record "REC MovedKey Row";
    begin
        Row.DeleteAll();
        if TargetFirst then
            AddRow('TARGET', 'old');
        AddRow('SOURCE', 'new');
        Commit();
        Inserts := '';
        StoredInside := '';
    end;

    local procedure AddRow(NewCode: Code[20]; NewName: Text[50])
    var
        Row: Record "REC MovedKey Row";
    begin
        Row.Code := NewCode;
        Row.Name := NewName;
        Row.Insert();
    end;

    local procedure NoteInsert(Done: Boolean)
    begin
        if Inserts <> '' then
            Inserts += ',';
        if Done then
            Inserts += 'ok'
        else
            Inserts += 'fail';
    end;

    // The upsert of the issue: a fresh copy of Src, its key moved, Insert(true), and on failure TransferFields + Modify(true).
    local procedure CopyTo(var Src: Record "REC MovedKey Row"; ToCode: Code[20])
    var
        Copy: Record "REC MovedKey Row";
        Done: Boolean;
    begin
        Copy := Src;
        Copy.Code := ToCode;
        Done := Copy.Insert(true);
        NoteInsert(Done);
        if not Done then begin
            Copy.TransferFields(Src, false);
            Copy.Modify(true);
        end;
    end;

    // P4: the same, Modify() without TransferFields.
    local procedure CopyToPlainModify(var Src: Record "REC MovedKey Row"; ToCode: Code[20])
    var
        Copy: Record "REC MovedKey Row";
        Done: Boolean;
    begin
        Copy := Src;
        Copy.Code := ToCode;
        Done := Copy.Insert(true);
        NoteInsert(Done);
        if not Done then
            Copy.Modify();
    end;

    local procedure Stored(): Text
    var
        Row: Record "REC MovedKey Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                if Result <> '' then
                    Result += ' ';
                Result += Row.Code + '=' + Row.Name;
            until Row.Next() = 0;
        exit(Result);
    end;

    // Call right after the asserterror block of a cell: records raised= and stored=, then empties the table.
    local procedure CloseCell(Cell: Text)
    var
        Row: Record "REC MovedKey Row";
        Raised: Boolean;
        After: Text;
    begin
        Raised := GetLastErrorText() <> NoErrorTxt;
        Obs.Observe(Cell + '|insert', Inserts);
        if Raised then
            Obs.Observe(Cell + '|raised', GetLastErrorCode() + '/' + GetLastErrorText())
        else
            Obs.Observe(Cell + '|raised', 'none');
        ClearLastError();
        if Raised then begin
            // read the rolled back state; guarded in case the transaction itself was stopped
            asserterror begin
                After := Stored();
                Error(NoErrorTxt);
            end;
            if GetLastErrorText() = NoErrorTxt then
                Obs.Observe(Cell + '|stored', After)
            else
                Obs.Observe(Cell + '|stored', 'read raised ' + GetLastErrorCode() + '/' + GetLastErrorText());
            ClearLastError();
        end else
            Obs.Observe(Cell + '|stored', StoredInside);
        Row.DeleteAll();
        Commit();
    end;

    [Test]
    procedure FailedInsert_MovedKey_P1_UpsertTwice()
    var
        Src: Record "REC MovedKey Row";
    begin
        Seed(false);
        Src.Get('SOURCE');
        CopyTo(Src, 'TARGET');
        Src.Name := 'second';
        asserterror begin
            CopyTo(Src, 'TARGET');
            StoredInside := Stored();
            Error(NoErrorTxt);
        end;
        CloseCell('P1');
        Obs.Expect('P1|insert', 'ok,fail');
        Obs.Expect('P1|raised', 'DB:RecordChanged/The changes to the REC MovedKey Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Code=''TARGET''');
        Obs.Expect('P1|stored', 'SOURCE=new');
        Obs.Verify();
    end;

    [Test]
    procedure FailedInsert_MovedKey_P2_TargetModifiedBetween()
    var
        Src: Record "REC MovedKey Row";
        Other: Record "REC MovedKey Row";
    begin
        Seed(false);
        Src.Get('SOURCE');
        CopyTo(Src, 'TARGET');
        Other.Get('TARGET');
        Other.Name := 'between';
        Other.Modify();
        Src.Name := 'second';
        asserterror begin
            CopyTo(Src, 'TARGET');
            StoredInside := Stored();
            Error(NoErrorTxt);
        end;
        CloseCell('P2');
        Obs.Expect('P2|insert', 'ok,fail');
        Obs.Expect('P2|raised', 'DB:RecordChanged/The changes to the REC MovedKey Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Code=''TARGET''');
        Obs.Expect('P2|stored', 'SOURCE=new');
        Obs.Verify();
    end;

    [Test]
    procedure FailedInsert_MovedKey_P3_SourceModifiedBetween()
    var
        Src: Record "REC MovedKey Row";
        Other: Record "REC MovedKey Row";
    begin
        Seed(false);
        Src.Get('SOURCE');
        CopyTo(Src, 'TARGET');
        Other.Get('SOURCE');
        Other.Name := 'between';
        Other.Modify();
        Src.Name := 'second';
        asserterror begin
            CopyTo(Src, 'TARGET');
            StoredInside := Stored();
            Error(NoErrorTxt);
        end;
        CloseCell('P3');
        Obs.Expect('P3|insert', 'ok,fail');
        Obs.Expect('P3|raised', 'DB:RecordChanged/The changes to the REC MovedKey Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Code=''TARGET''');
        Obs.Expect('P3|stored', 'SOURCE=new');
        Obs.Verify();
    end;

    [Test]
    procedure FailedInsert_MovedKey_P4_PlainModifyNoTransferFields()
    var
        Src: Record "REC MovedKey Row";
    begin
        Seed(false);
        Src.Get('SOURCE');
        CopyToPlainModify(Src, 'TARGET');
        Src.Name := 'second';
        asserterror begin
            CopyToPlainModify(Src, 'TARGET');
            StoredInside := Stored();
            Error(NoErrorTxt);
        end;
        CloseCell('P4');
        Obs.Expect('P4|insert', 'ok,fail');
        Obs.Expect('P4|raised', 'DB:RecordChanged/The changes to the REC MovedKey Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Code=''TARGET''');
        Obs.Expect('P4|stored', 'SOURCE=new');
        Obs.Verify();
    end;

    [Test]
    procedure FailedInsert_MovedKey_P5_SourceReadByFindFirst()
    var
        Src: Record "REC MovedKey Row";
    begin
        Seed(false);
        Src.SetRange(Code, 'SOURCE');
        Src.FindFirst();
        CopyTo(Src, 'TARGET');
        Src.Name := 'second';
        asserterror begin
            CopyTo(Src, 'TARGET');
            StoredInside := Stored();
            Error(NoErrorTxt);
        end;
        CloseCell('P5');
        Obs.Expect('P5|insert', 'ok,fail');
        Obs.Expect('P5|raised', 'DB:RecordChanged/The changes to the REC MovedKey Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Code=''TARGET''');
        Obs.Expect('P5|stored', 'SOURCE=new');
        Obs.Verify();
    end;

    [Test]
    procedure FailedInsert_MovedKey_P6_VersionFromOwnInsertOfOtherKey()
    var
        Src: Record "REC MovedKey Row";
        Copy: Record "REC MovedKey Row";
        Done: Boolean;
    begin
        Seed(false);
        Src.Get('SOURCE');
        Copy := Src;
        Copy.Code := 'OWN';
        NoteInsert(Copy.Insert(true));
        CopyTo(Src, 'TARGET');
        Src.Name := 'second';
        asserterror begin
            Copy.Code := 'TARGET';
            Done := Copy.Insert(true);
            NoteInsert(Done);
            if not Done then begin
                Copy.TransferFields(Src, false);
                Copy.Modify(true);
            end;
            StoredInside := Stored();
            Error(NoErrorTxt);
        end;
        CloseCell('P6');
        Obs.Expect('P6|insert', 'ok,ok,fail');
        Obs.Expect('P6|raised', 'none');
        Obs.Expect('P6|stored', 'OWN=new SOURCE=new TARGET=second');
        Obs.Verify();
    end;

    [Test]
    procedure FailedInsert_MovedKey_P7_OlderTargetModifiedAfterRead()
    var
        Src: Record "REC MovedKey Row";
        Other: Record "REC MovedKey Row";
    begin
        Seed(true);
        Src.Get('SOURCE');
        Other.Get('TARGET');
        Other.Name := 'between';
        Other.Modify();
        asserterror begin
            CopyTo(Src, 'TARGET');
            StoredInside := Stored();
            Error(NoErrorTxt);
        end;
        CloseCell('P7');
        Obs.Expect('P7|insert', 'fail');
        Obs.Expect('P7|raised', 'DB:RecordChanged/The changes to the REC MovedKey Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Code=''TARGET''');
        Obs.Expect('P7|stored', 'SOURCE=new TARGET=old');
        Obs.Verify();
    end;

    [Test]
    procedure FailedInsert_MovedKey_P8_CommitBetween()
    var
        Src: Record "REC MovedKey Row";
    begin
        Seed(false);
        Src.Get('SOURCE');
        CopyTo(Src, 'TARGET');
        Commit();
        Src.Name := 'second';
        asserterror begin
            CopyTo(Src, 'TARGET');
            StoredInside := Stored();
            Error(NoErrorTxt);
        end;
        CloseCell('P8');
        Obs.Expect('P8|insert', 'ok,fail');
        Obs.Expect('P8|raised', 'DB:RecordChanged/The changes to the REC MovedKey Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Code=''TARGET''');
        Obs.Expect('P8|stored', 'SOURCE=new TARGET=new');
        Obs.Verify();
    end;

    // Round 2 (cells Q1-Q7, al-runner issue 8721): which version the check after a failed Insert counts. Shape as P1 unless stated:
    //   Src read, CopyTo creates TARGET, Src.Name := 'second' in memory, the 2nd CopyTo inside asserterror.
    //   Q1  the seed NOT committed (DeleteAll + Insert SOURCE in the open transaction), then Src.Get. Q1a with asserterror around
    //       the 2nd call, Q1b without it (the issue's cell 5 has none): Q1b raising shows as a test failure without OBSERVE:.
    //   Q2  committed seed, row X of the SAME table inserted (no Commit), then Src.Get.
    //   Q3  committed seed, a row of ANOTHER table (87212) inserted (no Commit), then Src.Get.
    //   Q4  the seed NOT committed, Src.Get, then a Commit, then the upsert twice.
    //   Q5  committed seed, a 2nd variable modifies SOURCE (Name 'modified', no Commit), then Src.Get.
    //   Q6  P6 with a Commit right after the own Insert of OWN.
    //   Q7  P6 with Copy.Name := 'ownmod' and Copy.Modify() after the own Insert of OWN, before TARGET is inserted.

    local procedure SeedOpen()
    var
        Row: Record "REC MovedKey Row";
    begin
        Row.DeleteAll();
        AddRow('SOURCE', 'new');
        Inserts := '';
        StoredInside := '';
    end;

    // Q1b: the 2nd call ran unguarded and did not raise (a raise ends the test with its own message).
    local procedure CloseUnguarded(Cell: Text)
    var
        Row: Record "REC MovedKey Row";
    begin
        Obs.Observe(Cell + '|insert', Inserts);
        Obs.Observe(Cell + '|raised', 'none');
        Obs.Observe(Cell + '|stored', StoredInside);
        Row.DeleteAll();
        Commit();
    end;

    [Test]
    procedure FailedInsert_MovedKey_Q1a_OpenSeed_Guarded()
    var
        Src: Record "REC MovedKey Row";
    begin
        SeedOpen();
        Src.Get('SOURCE');
        CopyTo(Src, 'TARGET');
        Src.Name := 'second';
        asserterror begin
            CopyTo(Src, 'TARGET');
            StoredInside := Stored();
            Error(NoErrorTxt);
        end;
        CloseCell('Q1a');
        Obs.Expect('Q1a|insert', 'ok,fail');
        Obs.Expect('Q1a|raised', 'none');
        Obs.Expect('Q1a|stored', 'SOURCE=new TARGET=second');
        Obs.Verify();
    end;

    [Test]
    procedure FailedInsert_MovedKey_Q1b_OpenSeed_Unguarded()
    var
        Src: Record "REC MovedKey Row";
    begin
        SeedOpen();
        Src.Get('SOURCE');
        CopyTo(Src, 'TARGET');
        Src.Name := 'second';
        CopyTo(Src, 'TARGET');
        StoredInside := Stored();
        CloseUnguarded('Q1b');
        Obs.Expect('Q1b|insert', 'ok,fail');
        Obs.Expect('Q1b|raised', 'none');
        Obs.Expect('Q1b|stored', 'SOURCE=new TARGET=second');
        Obs.Verify();
    end;

    [Test]
    procedure FailedInsert_MovedKey_Q2_SameTableWrittenBeforeRead()
    var
        Src: Record "REC MovedKey Row";
    begin
        Seed(false);
        AddRow('X', 'x');
        Src.Get('SOURCE');
        CopyTo(Src, 'TARGET');
        Src.Name := 'second';
        asserterror begin
            CopyTo(Src, 'TARGET');
            StoredInside := Stored();
            Error(NoErrorTxt);
        end;
        CloseCell('Q2');
        Obs.Expect('Q2|insert', 'ok,fail');
        Obs.Expect('Q2|raised', 'none');
        Obs.Expect('Q2|stored', 'SOURCE=new TARGET=second X=x');
        Obs.Verify();
    end;

    [Test]
    procedure FailedInsert_MovedKey_Q3_OtherTableWrittenBeforeRead()
    var
        Src: Record "REC MovedKey Row";
        Side: Record "REC MovedKey Side";
    begin
        Side.DeleteAll();
        Seed(false);
        Side.Code := 'S';
        Side.Insert();
        Src.Get('SOURCE');
        CopyTo(Src, 'TARGET');
        Src.Name := 'second';
        asserterror begin
            CopyTo(Src, 'TARGET');
            StoredInside := Stored();
            Error(NoErrorTxt);
        end;
        CloseCell('Q3');
        Side.DeleteAll();
        Commit();
        Obs.Expect('Q3|insert', 'ok,fail');
        Obs.Expect('Q3|raised', 'DB:RecordChanged/The changes to the REC MovedKey Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Code=''TARGET''');
        Obs.Expect('Q3|stored', 'SOURCE=new');
        Obs.Verify();
    end;

    [Test]
    procedure FailedInsert_MovedKey_Q4_OpenSeed_CommitAfterRead()
    var
        Src: Record "REC MovedKey Row";
    begin
        SeedOpen();
        Src.Get('SOURCE');
        Commit();
        CopyTo(Src, 'TARGET');
        Src.Name := 'second';
        asserterror begin
            CopyTo(Src, 'TARGET');
            StoredInside := Stored();
            Error(NoErrorTxt);
        end;
        CloseCell('Q4');
        Obs.Expect('Q4|insert', 'ok,fail');
        Obs.Expect('Q4|raised', 'none');
        Obs.Expect('Q4|stored', 'SOURCE=new TARGET=second');
        Obs.Verify();
    end;

    [Test]
    procedure FailedInsert_MovedKey_Q5_SourceModifiedBeforeRead()
    var
        Src: Record "REC MovedKey Row";
        Other: Record "REC MovedKey Row";
    begin
        Seed(false);
        Other.Get('SOURCE');
        Other.Name := 'modified';
        Other.Modify();
        Src.Get('SOURCE');
        CopyTo(Src, 'TARGET');
        Src.Name := 'second';
        asserterror begin
            CopyTo(Src, 'TARGET');
            StoredInside := Stored();
            Error(NoErrorTxt);
        end;
        CloseCell('Q5');
        Obs.Expect('Q5|insert', 'ok,fail');
        Obs.Expect('Q5|raised', 'none');
        Obs.Expect('Q5|stored', 'SOURCE=modified TARGET=second');
        Obs.Verify();
    end;

    [Test]
    procedure FailedInsert_MovedKey_Q6_OwnInsertThenCommit()
    var
        Src: Record "REC MovedKey Row";
        Copy: Record "REC MovedKey Row";
        Done: Boolean;
    begin
        Seed(false);
        Src.Get('SOURCE');
        Copy := Src;
        Copy.Code := 'OWN';
        NoteInsert(Copy.Insert(true));
        Commit();
        CopyTo(Src, 'TARGET');
        Src.Name := 'second';
        asserterror begin
            Copy.Code := 'TARGET';
            Done := Copy.Insert(true);
            NoteInsert(Done);
            if not Done then begin
                Copy.TransferFields(Src, false);
                Copy.Modify(true);
            end;
            StoredInside := Stored();
            Error(NoErrorTxt);
        end;
        CloseCell('Q6');
        Obs.Expect('Q6|insert', 'ok,ok,fail');
        Obs.Expect('Q6|raised', 'none');
        Obs.Expect('Q6|stored', 'OWN=new SOURCE=new TARGET=second');
        Obs.Verify();
    end;

    [Test]
    procedure FailedInsert_MovedKey_Q7_OwnInsertThenOwnModify()
    var
        Src: Record "REC MovedKey Row";
        Copy: Record "REC MovedKey Row";
        Done: Boolean;
    begin
        Seed(false);
        Src.Get('SOURCE');
        Copy := Src;
        Copy.Code := 'OWN';
        NoteInsert(Copy.Insert(true));
        Copy.Name := 'ownmod';
        Copy.Modify();
        CopyTo(Src, 'TARGET');
        Src.Name := 'second';
        asserterror begin
            Copy.Code := 'TARGET';
            Done := Copy.Insert(true);
            NoteInsert(Done);
            if not Done then begin
                Copy.TransferFields(Src, false);
                Copy.Modify(true);
            end;
            StoredInside := Stored();
            Error(NoErrorTxt);
        end;
        CloseCell('Q7');
        Obs.Expect('Q7|insert', 'ok,ok,fail');
        Obs.Expect('Q7|raised', 'none');
        Obs.Expect('Q7|stored', 'OWN=ownmod SOURCE=new TARGET=second');
        Obs.Verify();
    end;

    // Round 3 (cells R1-R10, al-runner issue 8721): shapes after the open transaction locked, deleted or otherwise
    //   wrote the table, or where the version reached the buffer another way. Shape as Q2 unless stated: committed seed, the
    //   table written before the read, Src read, CopyTo creates TARGET, Src.Name := 'second' in memory, the 2nd call in asserterror.
    //   R1   Src.LockTable(), then Src.Get (no other write). R1b the same with the seed NOT committed.
    //   R2   row X inserted, then Src read by SetRange + FindFirst.
    //   R3   row A inserted, then Src read by FindSet, looping to SOURCE.
    //   R4   committed row D deleted by a 2nd variable, then Src.Get.
    //   R5a  committed row D deleted by SetRange + DeleteAll, then Src.Get.  R5b  the same row changed by ModifyAll.
    //   R6   the same key: row X inserted, Src.Get, a 2nd variable modifies SOURCE, then Src.Insert(true) fails and Src.Modify(true).
    //   R7   P6 with a version from Rename: committed row OLD read by Get and renamed to REN, then moved to TARGET.
    //   R8   row X inserted, Src.Get, the buffer filled by TransferFields(Src) (key included), then moved to TARGET.
    //   R9   P6 with a version from the buffer's own Modify after a Get of committed row OWN.
    //   R10  row X inserted, Src.Get, then the 2nd call through a RecordRef: GetTable(Src), key field set to TARGET,
    //        Insert(true) fails, Modify(true).
    //   Measured on BC 29.0 (asserted verbatim): every R cell is written except R8, which raises DB:RecordChanged (a buffer filled
    //   by TransferFields(Src) with the key included). LockTable counts like a write (R1, R1b), and so do Delete, DeleteAll and
    //   ModifyAll of another row (R4, R5a, R5b). A FindFirst or FindSet read after a write (R2, R3), the same key changed after the
    //   read (R6), a version from Rename (R7) or from the buffer's own Modify after a Get (R9), and a RecordRef (R10) are written too.

    local procedure SeedPlus(ExtraCode: Code[20]; ExtraName: Text[50])
    begin
        Seed(false);
        AddRow(ExtraCode, ExtraName);
        Commit();
    end;

    [Test]
    procedure FailedInsert_MovedKey_R1_LockTableThenGet()
    var
        Src: Record "REC MovedKey Row";
    begin
        Seed(false);
        Src.LockTable();
        Src.Get('SOURCE');
        CopyTo(Src, 'TARGET');
        Src.Name := 'second';
        asserterror begin
            CopyTo(Src, 'TARGET');
            StoredInside := Stored();
            Error(NoErrorTxt);
        end;
        CloseCell('R1');
        Obs.Expect('R1|insert', 'ok,fail');
        Obs.Expect('R1|raised', 'none');
        Obs.Expect('R1|stored', 'SOURCE=new TARGET=second');
        Obs.Verify();
    end;

    [Test]
    procedure FailedInsert_MovedKey_R1b_OpenSeed_LockTableThenGet()
    var
        Src: Record "REC MovedKey Row";
    begin
        SeedOpen();
        Src.LockTable();
        Src.Get('SOURCE');
        CopyTo(Src, 'TARGET');
        Src.Name := 'second';
        asserterror begin
            CopyTo(Src, 'TARGET');
            StoredInside := Stored();
            Error(NoErrorTxt);
        end;
        CloseCell('R1b');
        Obs.Expect('R1b|insert', 'ok,fail');
        Obs.Expect('R1b|raised', 'none');
        Obs.Expect('R1b|stored', 'SOURCE=new TARGET=second');
        Obs.Verify();
    end;

    [Test]
    procedure FailedInsert_MovedKey_R2_TableWrittenThenFindFirst()
    var
        Src: Record "REC MovedKey Row";
    begin
        Seed(false);
        AddRow('X', 'x');
        Src.SetRange(Code, 'SOURCE');
        Src.FindFirst();
        CopyTo(Src, 'TARGET');
        Src.Name := 'second';
        asserterror begin
            CopyTo(Src, 'TARGET');
            StoredInside := Stored();
            Error(NoErrorTxt);
        end;
        CloseCell('R2');
        Obs.Expect('R2|insert', 'ok,fail');
        Obs.Expect('R2|raised', 'none');
        Obs.Expect('R2|stored', 'SOURCE=new TARGET=second X=x');
        Obs.Verify();
    end;

    [Test]
    procedure FailedInsert_MovedKey_R3_TableWrittenThenFindSet()
    var
        Src: Record "REC MovedKey Row";
    begin
        Seed(false);
        AddRow('A', 'a');
        if Src.FindSet() then
            repeat
            until (Src.Code = 'SOURCE') or (Src.Next() = 0);
        CopyTo(Src, 'TARGET');
        Src.Name := 'second';
        asserterror begin
            CopyTo(Src, 'TARGET');
            StoredInside := Stored();
            Error(NoErrorTxt);
        end;
        CloseCell('R3');
        Obs.Expect('R3|insert', 'ok,fail');
        Obs.Expect('R3|raised', 'none');
        Obs.Expect('R3|stored', 'A=a SOURCE=new TARGET=second');
        Obs.Verify();
    end;

    [Test]
    procedure FailedInsert_MovedKey_R4_OtherRowDeletedThenGet()
    var
        Src: Record "REC MovedKey Row";
        Other: Record "REC MovedKey Row";
    begin
        SeedPlus('D', 'd');
        Other.Get('D');
        Other.Delete();
        Src.Get('SOURCE');
        CopyTo(Src, 'TARGET');
        Src.Name := 'second';
        asserterror begin
            CopyTo(Src, 'TARGET');
            StoredInside := Stored();
            Error(NoErrorTxt);
        end;
        CloseCell('R4');
        Obs.Expect('R4|insert', 'ok,fail');
        Obs.Expect('R4|raised', 'none');
        Obs.Expect('R4|stored', 'SOURCE=new TARGET=second');
        Obs.Verify();
    end;

    [Test]
    procedure FailedInsert_MovedKey_R5a_DeleteAllThenGet()
    var
        Src: Record "REC MovedKey Row";
        Other: Record "REC MovedKey Row";
    begin
        SeedPlus('D', 'd');
        Other.SetRange(Code, 'D');
        Other.DeleteAll();
        Src.Get('SOURCE');
        CopyTo(Src, 'TARGET');
        Src.Name := 'second';
        asserterror begin
            CopyTo(Src, 'TARGET');
            StoredInside := Stored();
            Error(NoErrorTxt);
        end;
        CloseCell('R5a');
        Obs.Expect('R5a|insert', 'ok,fail');
        Obs.Expect('R5a|raised', 'none');
        Obs.Expect('R5a|stored', 'SOURCE=new TARGET=second');
        Obs.Verify();
    end;

    [Test]
    procedure FailedInsert_MovedKey_R5b_ModifyAllThenGet()
    var
        Src: Record "REC MovedKey Row";
        Other: Record "REC MovedKey Row";
    begin
        SeedPlus('D', 'd');
        Other.SetRange(Code, 'D');
        Other.ModifyAll(Name, 'dm');
        Src.Get('SOURCE');
        CopyTo(Src, 'TARGET');
        Src.Name := 'second';
        asserterror begin
            CopyTo(Src, 'TARGET');
            StoredInside := Stored();
            Error(NoErrorTxt);
        end;
        CloseCell('R5b');
        Obs.Expect('R5b|insert', 'ok,fail');
        Obs.Expect('R5b|raised', 'none');
        Obs.Expect('R5b|stored', 'D=dm SOURCE=new TARGET=second');
        Obs.Verify();
    end;

    [Test]
    procedure FailedInsert_MovedKey_R6_SameKeyChangedAfterRead()
    var
        Src: Record "REC MovedKey Row";
        Other: Record "REC MovedKey Row";
        Done: Boolean;
    begin
        Seed(false);
        AddRow('X', 'x');
        Src.Get('SOURCE');
        Other.Get('SOURCE');
        Other.Name := 'changed';
        Other.Modify();
        asserterror begin
            Src.Name := 'second';
            Done := Src.Insert(true);
            NoteInsert(Done);
            if not Done then
                Src.Modify(true);
            StoredInside := Stored();
            Error(NoErrorTxt);
        end;
        CloseCell('R6');
        Obs.Expect('R6|insert', 'fail');
        Obs.Expect('R6|raised', 'none');
        Obs.Expect('R6|stored', 'SOURCE=second X=x');
        Obs.Verify();
    end;

    [Test]
    procedure FailedInsert_MovedKey_R7_VersionFromRename()
    var
        Src: Record "REC MovedKey Row";
        Buf: Record "REC MovedKey Row";
        Done: Boolean;
    begin
        SeedPlus('OLD', 'old');
        Src.Get('SOURCE');
        Buf.Get('OLD');
        Buf.Rename('REN');
        CopyTo(Src, 'TARGET');
        Src.Name := 'second';
        asserterror begin
            Buf.Code := 'TARGET';
            Done := Buf.Insert(true);
            NoteInsert(Done);
            if not Done then begin
                Buf.TransferFields(Src, false);
                Buf.Modify(true);
            end;
            StoredInside := Stored();
            Error(NoErrorTxt);
        end;
        CloseCell('R7');
        Obs.Expect('R7|insert', 'ok,fail');
        Obs.Expect('R7|raised', 'none');
        Obs.Expect('R7|stored', 'REN=old SOURCE=new TARGET=second');
        Obs.Verify();
    end;

    [Test]
    procedure FailedInsert_MovedKey_R8_VersionFromTransferFields()
    var
        Src: Record "REC MovedKey Row";
        Buf: Record "REC MovedKey Row";
        Done: Boolean;
    begin
        Seed(false);
        AddRow('X', 'x');
        Src.Get('SOURCE');
        CopyTo(Src, 'TARGET');
        Src.Name := 'second';
        asserterror begin
            Buf.TransferFields(Src);
            Buf.Code := 'TARGET';
            Done := Buf.Insert(true);
            NoteInsert(Done);
            if not Done then begin
                Buf.TransferFields(Src, false);
                Buf.Modify(true);
            end;
            StoredInside := Stored();
            Error(NoErrorTxt);
        end;
        CloseCell('R8');
        Obs.Expect('R8|insert', 'ok,fail');
        Obs.Expect('R8|raised', 'DB:RecordChanged/The changes to the REC MovedKey Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Code=''TARGET''');
        Obs.Expect('R8|stored', 'SOURCE=new');
        Obs.Verify();
    end;

    [Test]
    procedure FailedInsert_MovedKey_R9_VersionFromOwnModifyAfterGet()
    var
        Src: Record "REC MovedKey Row";
        Buf: Record "REC MovedKey Row";
        Done: Boolean;
    begin
        SeedPlus('OWN', 'own');
        Src.Get('SOURCE');
        Buf.Get('OWN');
        Buf.Name := 'ownmod';
        Buf.Modify();
        CopyTo(Src, 'TARGET');
        Src.Name := 'second';
        asserterror begin
            Buf.Code := 'TARGET';
            Done := Buf.Insert(true);
            NoteInsert(Done);
            if not Done then begin
                Buf.TransferFields(Src, false);
                Buf.Modify(true);
            end;
            StoredInside := Stored();
            Error(NoErrorTxt);
        end;
        CloseCell('R9');
        Obs.Expect('R9|insert', 'ok,fail');
        Obs.Expect('R9|raised', 'none');
        Obs.Expect('R9|stored', 'OWN=ownmod SOURCE=new TARGET=second');
        Obs.Verify();
    end;

    [Test]
    procedure FailedInsert_MovedKey_R10_RecordRefGetTable()
    var
        Src: Record "REC MovedKey Row";
        RecRef: RecordRef;
        Done: Boolean;
    begin
        Seed(false);
        AddRow('X', 'x');
        Src.Get('SOURCE');
        CopyTo(Src, 'TARGET');
        Src.Name := 'second';
        asserterror begin
            RecRef.GetTable(Src);
            RecRef.Field(1).Value := 'TARGET';
            Done := RecRef.Insert(true);
            NoteInsert(Done);
            if not Done then
                RecRef.Modify(true);
            StoredInside := Stored();
            Error(NoErrorTxt);
        end;
        CloseCell('R10');
        Obs.Expect('R10|insert', 'ok,fail');
        Obs.Expect('R10|raised', 'none');
        Obs.Expect('R10|stored', 'SOURCE=new TARGET=second X=x');
        Obs.Verify();
    end;
}

// Q3: a second table, written before the read.
table 87212 "REC MovedKey Side"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}
