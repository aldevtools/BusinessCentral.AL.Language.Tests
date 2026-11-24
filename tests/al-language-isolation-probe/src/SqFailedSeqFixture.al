namespace ALLanguage.IsolationProbe;

// Fixtures of the number-sequence probe after a failed test with the access shapes of Microsoft's SCM tests
// (SqFailedSeq.al, AL Runner issue 8972; extends SqCommitFail.al and SqRecordRefFail.al).
// No SingleInstance codeunit: every cell codeunit asserts its own readings (AL Runner issue 8520).

table 76440 "LT SQF Row"
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

// An entry table keyed by Entry No.; "LT SQF Seq" hands out the numbers, as Sequence No. Mgt. does for Warehouse Entry.
table 76441 "LT SQF Entry"
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

// AL Runner issue 8524: a table whose insert trigger calls IsolatedStorage and session builtins. This is code of the
// probe app, not of a Microsoft app (the corpus never writes to Microsoft tables).
table 76442 "LT SQF Trigger Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Key"; Code[30]) { }
        field(2; Stamp; Text[100]) { }
    }

    keys
    {
        key(PK; "Key") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        if IsolatedStorage.Contains('LTSQF-NEVER-SET') then;
        Stamp := CopyStr(Format(CurrentDateTime) + CompanyName, 1, MaxStrLen(Stamp));
    end;
}

page 76443 "LT SQF Row Card"
{
    PageType = Card;
    SourceTable = "LT SQF Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Key"; Rec."Key") { ApplicationArea = All; }
            field(Description; Rec.Description) { ApplicationArea = All; }
        }
    }
}

// The NumberSequence calls of Sequence No. Mgt. (Base Application codeunit 9500: GetNextSeqNo, GetCurrentSeqNo,
// ValidateSeqNo, CreateNewTableSequence, CreateSequence, GetLastEntryNoFromTable) in the same order, written for this
// probe: the sequence name is passed in, the table is "LT SQF Entry", there is no per-transaction cache and no preview
// mode. CreateNewTableSequence creates the second sequence 'Preview' + Name in the same call.
codeunit 76444 "LT SQF Seq"
{
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

    procedure GetCurrentSeqNo(Name: Text): Integer
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

    procedure ValidateSeqNo(Name: Text)
    var
        LastEntryNo: Integer;
    begin
        LastEntryNo := GetLastEntryNoFromTable(false);
        if GetCurrentSeqNo(Name) < LastEntryNo then
            CreateNewTableSequence(Name);
    end;

    procedure PreviewName(Name: Text): Text
    begin
        exit('Preview' + Name);
    end;

    // The helper as a test calls it: take the next number and insert an entry with it.
    procedure InsertEntry(Name: Text; CellCode: Code[10]): Integer
    var
        Entry: Record "LT SQF Entry";
    begin
        Entry."Entry No." := GetNextSeqNo(Name);
        Entry.Cell := CellCode;
        Entry.Insert();
        exit(Entry."Entry No.");
    end;

    // 'missing', or 'cur=<Current>'. Reads only.
    procedure State(Name: Text): Text
    begin
        if NumberSequence.Exists(Name) then
            exit('cur=' + Format(NumberSequence.Current(Name)));
        exit('missing');
    end;

    // The Entry Nos. of "LT SQF Entry", comma-separated, or 'none'.
    procedure Entries(): Text
    var
        Entry: Record "LT SQF Entry";
        Result: Text;
    begin
        if Entry.FindSet() then
            repeat
                if Result <> '' then
                    Result += ',';
                Result += Format(Entry."Entry No.");
            until Entry.Next() = 0;
        if Result = '' then
            exit('none');
        exit(Result);
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
        if NumberSequence.Exists(SequenceName) then
            NumberSequence.Restart(SequenceName, StartSeqNo - 1)
        else
            NumberSequence.Insert(SequenceName, StartSeqNo - 1, 1, true);
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
        RecRef.Open(Database::"LT SQF Entry");
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
}

// The access kinds a failed SCM test makes besides Record calls on real tables. Values are thrown away; no cell
// asserts a session value.
codeunit 76445 "LT SQF Access"
{
    procedure InsertRow(RowKey: Code[30])
    var
        Row: Record "LT SQF Row";
    begin
        Row."Key" := RowKey;
        Row.Insert();
    end;

    // The keys of "LT SQF Row" in key order, comma-separated, or 'none'.
    procedure Rows(): Text
    var
        Row: Record "LT SQF Row";
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

    procedure InitDescription(): Text
    var
        Row: Record "LT SQF Row";
    begin
        if not Row.Get('INIT') then
            exit('no INIT row');
        exit('''' + Row.Description + '''');
    end;

    procedure TempRecord()
    var
        TempRow: Record "LT SQF Row" temporary;
    begin
        TempRow."Key" := 'TEMP';
        TempRow.Insert();
        if TempRow.FindSet() then;
    end;

    procedure Builtins()
    var
        Discard: Text;
    begin
        Discard := Format(WorkDate()) + Format(CurrentDateTime()) + UserId() + Format(GuiAllowed()) + Format(GlobalLanguage());
        Discard += Format(Random(10)) + Format(Today()) + Format(Time()) + Format(CurrentClientType()) + Format(UserSecurityId());
        Discard += Format(CurrentTransactionType()) + CompanyName();
        if Discard = '' then;
    end;

    procedure TempRecordRef()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.Open(Database::"LT SQF Row", true);
        FldRef := RecRef.Field(1);
        FldRef.SetRange('INIT');
    end;

    // The RecordRef and FieldRef calls of the failed SCM tests on a real table; the last one modifies the INIT row.
    procedure RecordRefCalls()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        KeyRef: KeyRef;
        Discard: Text;
    begin
        RecRef.Open(Database::"LT SQF Row");
        RecRef.ReadIsolation(IsolationLevel::ReadCommitted);
        KeyRef := RecRef.KeyIndex(1);
        FldRef := KeyRef.FieldIndex(1);
        RecRef.SetLoadFields(1);
        RecRef.AddLoadFields(2);
        Discard := Format(RecRef.FieldCount()) + Format(RecRef.FieldExist(2)) + Format(RecRef.SecurityFiltering());
        FldRef := RecRef.Field(1);
        Discard += Format(FldRef.Class()) + Format(FldRef.Length()) + Format(FldRef.Type());
        FldRef.SetRange('INIT');
        Discard += FldRef.GetFilter() + Format(RecRef.IsEmpty()) + Format(RecRef.IsTemporary());
        if RecRef.Find('-') then;
        if RecRef.FindSet() then
            if RecRef.Next() = 0 then;
        Discard += Format(RecRef.Count()) + Format(RecRef.HasLinks()) + Format(RecRef.RecordId().TableNo());
        RecRef.Reset();
        FldRef := RecRef.Field(1);
        FldRef.SetRange('INIT');
        if RecRef.FindFirst() then begin
            FldRef := RecRef.Field(2);
            FldRef.Value := 'REF';
            RecRef.Modify();
        end;
        if Discard = '' then;
    end;

    procedure InsertTriggerRow(RowKey: Code[30])
    var
        TriggerRow: Record "LT SQF Trigger Row";
    begin
        TriggerRow."Key" := RowKey;
        TriggerRow.Insert(true);
    end;

    procedure DeleteAllRows()
    var
        Row: Record "LT SQF Row";
        Entry: Record "LT SQF Entry";
        TriggerRow: Record "LT SQF Trigger Row";
    begin
        Row.DeleteAll();
        Entry.DeleteAll();
        TriggerRow.DeleteAll();
    end;
}

// A posting codeunit shape: writes a row, then commits at its end.
codeunit 76446 "LT SQF Poster"
{
    trigger OnRun()
    begin
        Post();
    end;

    procedure Post()
    var
        Access: Codeunit "LT SQF Access";
    begin
        Access.InsertRow('POST');
        Commit();
    end;
}
