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
// BC versions: 27, 28, 29

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
        Obs.Finish();
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
        Obs.Finish();
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
        Obs.Finish();
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
        Obs.Finish();
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
        Obs.Finish();
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
        Obs.Finish();
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
        Obs.Finish();
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
        Obs.Finish();
    end;
}
