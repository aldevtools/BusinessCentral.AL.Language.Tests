namespace ALLanguage.IsolationProbe;

// Fixtures of the probe "a number sequence that existed when the tests began, after a failed test that restarted or
// deleted it" (SqExistingRestart.al, AL Runner issue 8972). Extends SqCommitFail.al (B1-B4: the same steps with no table
// access). No SingleInstance codeunit: every cell codeunit asserts its own readings (AL Runner issue 8520).

table 79300 "LT SQE Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Key"; Code[30]) { }
        field(2; Description; Text[50]) { }
    }

    keys
    {
        key(PK; "Key") { Clustered = true; }
    }
}

// An entry table keyed by Entry No.; "LT SQE Seq" hands out the numbers, as Sequence No. Mgt. does for Item Ledger Entry.
table 79301 "LT SQE Entry"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Cell; Code[10]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

// The sequence calls of the cells. A sequence name is fixed per cell: the cell needs a sequence that exists before the
// codeunit runs, so the name must be the same in every run. Readings are relative to the Current value the first test
// found (Base), because numbers taken with Next stay taken from run to run.
codeunit 79302 "LT SQE Seq"
{
    // Called by the cell codeunit's OnRun: makes the sequence when it is missing. Returns 'found' or 'created'.
    procedure Prepare(Name: Text; CompanyWide: Boolean): Text
    begin
        if NumberSequence.Exists(Name, CompanyWide) then
            exit('found');
        NumberSequence.Insert(Name, 1, 1, CompanyWide);
        if NumberSequence.Next(Name, CompanyWide) = 0 then;
        if NumberSequence.Next(Name, CompanyWide) = 0 then;
        exit('created');
    end;

    procedure RestartTo(Name: Text; CompanyWide: Boolean; Value: BigInteger)
    begin
        NumberSequence.Restart(Name, Value, CompanyWide);
    end;

    procedure CurrentOrZero(Name: Text; CompanyWide: Boolean): BigInteger
    begin
        if NumberSequence.Exists(Name, CompanyWide) then
            exit(NumberSequence.Current(Name, CompanyWide));
        exit(0);
    end;

    // 'missing', or 'cur=' and the Current value relative to Base ('S', 'S+1000', 'S-2').
    procedure Rel(Name: Text; CompanyWide: Boolean; Base: BigInteger): Text
    begin
        if not NumberSequence.Exists(Name, CompanyWide) then
            exit('missing');
        exit('cur=' + Offset(NumberSequence.Current(Name, CompanyWide), Base));
    end;

    // 'missing', or what Next returns, relative to Base.
    procedure RelNext(Name: Text; CompanyWide: Boolean; Base: BigInteger): Text
    begin
        if not NumberSequence.Exists(Name, CompanyWide) then
            exit('missing');
        exit(Offset(NumberSequence.Next(Name, CompanyWide), Base));
    end;

    // The same readings with the calls of Sequence No. Mgt.: no CompanyWide argument (used by the SCM-shape cells).
    procedure CurrentOrZeroDefault(Name: Text): BigInteger
    begin
        if NumberSequence.Exists(Name) then
            exit(NumberSequence.Current(Name));
        exit(0);
    end;

    procedure RelDefault(Name: Text; Base: BigInteger): Text
    begin
        if not NumberSequence.Exists(Name) then
            exit('missing');
        exit('cur=' + Offset(NumberSequence.Current(Name), Base));
    end;

    procedure Offset(Value: BigInteger; Base: BigInteger): Text
    begin
        if Value = Base then
            exit('S');
        if Value > Base then
            exit('S+' + Format(Value - Base));
        exit('S-' + Format(Base - Value));
    end;

    // The NumberSequence calls of Sequence No. Mgt. (Base Application codeunit 9500: GetNextSeqNo, ValidateSeqNo,
    // GetCurrentSeqNo, RebaseSeqNo, CreateNewTableSequence, CreateSequence, GetLastEntryNoFromTable) in the same order,
    // written for this probe: the sequence name is passed in, the table is "LT SQE Entry", there is no per-transaction
    // cache, no buffer and no preview mode. CreateNewTableSequence also restarts or makes 'Preview' + Name.
    procedure GetNextSeqNo(Name: Text): Integer
    var
        NewSeqNo: Integer;
    begin
        ValidateSeqNo(Name);
        if TryGetNextNo(Name, NewSeqNo) then
            exit(NewSeqNo);
        ClearLastError();
        CreateNewTableSequence(Name);
        TryGetNextNo(Name, NewSeqNo);
        exit(NewSeqNo);
    end;

    procedure PreviewName(Name: Text): Text
    begin
        exit('Preview' + Name);
    end;

    // The posting step as a test reaches it: take the next number and insert an entry with it.
    procedure InsertEntry(Name: Text; CellCode: Code[10]): Integer
    var
        Entry: Record "LT SQE Entry";
    begin
        Entry."Entry No." := GetNextSeqNo(Name);
        Entry.Cell := CellCode;
        Entry.Insert();
        exit(Entry."Entry No.");
    end;

    // What the last GetNextSeqNo did to the sequences: 'none', 'restart' or 'insert'.
    procedure LastCreate(): Text
    begin
        if LastCreateKind = '' then
            exit('none');
        exit(LastCreateKind);
    end;

    // The Entry Nos. of "LT SQE Entry" relative to Base, comma-separated, or 'none'.
    procedure Entries(Base: BigInteger): Text
    var
        Entry: Record "LT SQE Entry";
        Result: Text;
    begin
        if Entry.FindSet() then
            repeat
                if Result <> '' then
                    Result += ',';
                Result += Offset(Entry."Entry No.", Base);
            until Entry.Next() = 0;
        if Result = '' then
            exit('none');
        exit(Result);
    end;

    local procedure ValidateSeqNo(Name: Text)
    var
        LastEntryNo: Integer;
    begin
        LastEntryNo := GetLastEntryNoFromTable(false);
        if GetCurrentSeqNo(Name) < LastEntryNo then
            CreateNewTableSequence(Name);
    end;

    local procedure GetCurrentSeqNo(Name: Text): Integer
    var
        CurrSeqNo: Integer;
    begin
        if TryGetCurrentNo(Name, CurrSeqNo) then
            exit(CurrSeqNo);
        ClearLastError();
        CreateNewTableSequence(Name);
        TryGetCurrentNo(Name, CurrSeqNo);
        exit(CurrSeqNo);
    end;

    [TryFunction]
    local procedure TryGetNextNo(Name: Text; var NewSeqNo: Integer)
    begin
        NewSeqNo := NumberSequence.Next(Name);
    end;

    [TryFunction]
    local procedure TryGetCurrentNo(Name: Text; var CurrSeqNo: Integer)
    begin
        CurrSeqNo := NumberSequence.Current(Name);
    end;

    local procedure CreateNewTableSequence(Name: Text)
    begin
        CreateSequence(Name, GetLastEntryNoFromTable(true) + 1);
        CreateSequence(PreviewName(Name), -2000000000);
    end;

    local procedure CreateSequence(SequenceName: Text; StartSeqNo: BigInteger)
    begin
        if NumberSequence.Exists(SequenceName) then begin
            NumberSequence.Restart(SequenceName, StartSeqNo - 1);
            LastCreateKind := 'restart';
        end else begin
            NumberSequence.Insert(SequenceName, StartSeqNo - 1, 1, true);
            LastCreateKind := 'insert';
        end;
        if NumberSequence.Next(SequenceName) = 1 then;
    end;

    local procedure GetLastEntryNoFromTable(WithLock: Boolean): BigInteger
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        RecRef: RecordRef;
        FldRef: FieldRef;
        KeyRef: KeyRef;
        LastEntryNo: BigInteger;
    begin
        RecRef.Open(Database::"LT SQE Entry");
        if WithLock then
            RecRef.ReadIsolation(IsolationLevel::UpdLock)
        else
            RecRef.ReadIsolation(IsolationLevel::ReadUncommitted);
        KeyRef := RecRef.KeyIndex(1);
        RecRef.SetLoadFields(KeyRef.FieldIndex(KeyRef.FieldCount).Number);
        if RecRef.FindLast() then begin
            FldRef := KeyRef.FieldIndex(KeyRef.FieldCount);
            LastEntryNo := FldRef.Value
        end else
            LastEntryNo := 0;
        exit(LastEntryNo);
    end;

    var
        LastCreateKind: Text;
}

// The table access of the cells.
codeunit 79303 "LT SQE Access"
{
    procedure InsertRow(RowKey: Code[30])
    var
        Row: Record "LT SQE Row";
    begin
        Row."Key" := RowKey;
        Row.Insert();
    end;

    // An entry written without the sequence, as a ledger entry that the sequence has not handed out.
    procedure InsertDirectEntry(EntryNo: Integer; CellCode: Code[10])
    var
        Entry: Record "LT SQE Entry";
    begin
        Entry."Entry No." := EntryNo;
        Entry.Cell := CellCode;
        Entry.Insert();
    end;

    // The keys of "LT SQE Row" in key order, comma-separated, or 'none'.
    procedure Rows(): Text
    var
        Row: Record "LT SQE Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                if Result <> '' then
                    Result += ',';
                Result += Row."Key";
            until Row.Next() = 0;
        if Result = '' then
            exit('none');
        exit(Result);
    end;

    procedure PlainRead()
    var
        Row: Record "LT SQE Row";
    begin
        if Row.FindFirst() then;
    end;

    // RecordRef.Open and Close on the real table, nothing read.
    procedure RefOpenClose()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LT SQE Row");
        RecRef.Close();
    end;

    procedure InsertRowThenError(RowKey: Code[30])
    begin
        InsertRow(RowKey);
        Error('inner error');
    end;

    procedure DeleteAllRows()
    var
        Row: Record "LT SQE Row";
        Entry: Record "LT SQE Entry";
    begin
        Row.DeleteAll();
        Entry.DeleteAll();
    end;
}

// A posting codeunit shape: takes a number through the helper, inserts the entry, then commits at its end.
codeunit 79304 "LT SQE Poster"
{
    trigger OnRun()
    begin
        Seq.InsertEntry(SequenceName, 'POST');
        Commit();
    end;

    procedure SetName(Name: Text)
    begin
        SequenceName := Name;
    end;

    var
        Seq: Codeunit "LT SQE Seq";
        SequenceName: Text;
}
