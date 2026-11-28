namespace ALLanguage.IsolationProbe;

// Fixtures of the number-sequence probe with mixed access kinds between two transaction ends (SqMixedAccess.al, AL Runner
// issue 8972). Extends SqFailedSeq.al and SqExistingRestart.al, whose stretches between commits hold one access kind.
// local object: the tests commit, fail on purpose and read the tables in a later test of the same codeunit.
// No SingleInstance codeunit: every cell codeunit asserts its own readings (AL Runner issue 8520).

table 79520 "LT SQM Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Key"; Code[30]) { }
        field(2; Description; Text[50]) { }
        field(3; Data; Blob) { }
    }

    keys
    {
        key(PK; "Key") { Clustered = true; }
    }
}

// An entry table keyed by Entry No.; "LT SQM Seq" hands out the numbers, as Sequence No. Mgt. does for a ledger entry table.
table 79521 "LT SQM Entry"
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

// A second entry table with its own sequence: two helper calls on different tables in one stretch.
table 79522 "LT SQM Entry2"
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

page 79523 "LT SQM Row Card"
{
    PageType = Card;
    SourceTable = "LT SQM Row";
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

query 79524 "LT SQM Row Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "LT SQM Row")
        {
            column(RowKey; "Key") { }
        }
    }
}

report 79525 "LT SQM Row Report"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT SQM Row")
        {
            column(RowKey; "Key") { }
        }
    }
}

// The NumberSequence calls of Sequence No. Mgt. (Base Application codeunit 9500: GetNextSeqNo, ValidateSeqNo,
// GetCurrentSeqNo, CreateNewTableSequence, CreateSequence, GetLastEntryNoFromTable) in the same order, written for this
// probe: the sequence name and the table are passed in, there is no per-transaction cache and no preview mode.
// CreateNewTableSequence also restarts or makes 'Preview' + Name. The readers below only read, except NextRel / NextAbs,
// which call Next.
codeunit 79526 "LT SQM Seq"
{
    procedure GetNextSeqNo(Name: Text; TableNo: Integer): Integer
    var
        NewSeqNo: Integer;
    begin
        ValidateSeqNo(Name, TableNo);
        if TryGetNextNo(Name, NewSeqNo) then
            exit(NewSeqNo);
        ClearLastError();
        CreateNewTableSequence(Name, TableNo);
        TryGetNextNo(Name, NewSeqNo);
        exit(NewSeqNo);
    end;

    procedure PreviewName(Name: Text): Text
    begin
        exit('Preview' + Name);
    end;

    // The posting step as a test reaches it: take the next number and insert an entry of "LT SQM Entry" with it.
    procedure InsertEntry(Name: Text; CellCode: Code[10]): Integer
    var
        Entry: Record "LT SQM Entry";
    begin
        Entry."Entry No." := GetNextSeqNo(Name, Database::"LT SQM Entry");
        Entry.Cell := CellCode;
        Entry.Insert();
        exit(Entry."Entry No.");
    end;

    // The same for "LT SQM Entry2" and its own sequence.
    procedure InsertEntry2(Name: Text; CellCode: Code[10]): Integer
    var
        Entry2: Record "LT SQM Entry2";
    begin
        Entry2."Entry No." := GetNextSeqNo(Name, Database::"LT SQM Entry2");
        Entry2.Cell := CellCode;
        Entry2.Insert();
        exit(Entry2."Entry No.");
    end;

    // What the last GetNextSeqNo did to the sequences: 'none', 'restart' or 'insert'.
    procedure LastCreate(): Text
    begin
        if LastCreateKind = '' then
            exit('none');
        exit(LastCreateKind);
    end;

    // Called by a cell codeunit's OnRun: makes the sequence when it is missing. Returns 'found' or 'created'.
    procedure Prepare(Name: Text): Text
    begin
        if NumberSequence.Exists(Name) then
            exit('found');
        NumberSequence.Insert(Name, 1, 1, true);
        if NumberSequence.Next(Name) = 0 then;
        if NumberSequence.Next(Name) = 0 then;
        exit('created');
    end;

    // 'missing', or 'cur=<Current>'.
    procedure State(Name: Text): Text
    begin
        if NumberSequence.Exists(Name) then
            exit('cur=' + Format(NumberSequence.Current(Name)));
        exit('missing');
    end;

    // 'missing', or what Next returns.
    procedure NextAbs(Name: Text): Text
    begin
        if NumberSequence.Exists(Name) then
            exit(Format(NumberSequence.Next(Name)));
        exit('missing');
    end;

    procedure CurrentOrZero(Name: Text): BigInteger
    begin
        if NumberSequence.Exists(Name) then
            exit(NumberSequence.Current(Name));
        exit(0);
    end;

    // 'missing', or 'cur=' and the Current value relative to Base ('S', 'S+6', 'S-2').
    procedure Rel(Name: Text; Base: BigInteger): Text
    begin
        if not NumberSequence.Exists(Name) then
            exit('missing');
        exit('cur=' + Offset(NumberSequence.Current(Name), Base));
    end;

    // 'missing', or what Next returns, relative to Base.
    procedure NextRel(Name: Text; Base: BigInteger): Text
    begin
        if not NumberSequence.Exists(Name) then
            exit('missing');
        exit(Offset(NumberSequence.Next(Name), Base));
    end;

    procedure Offset(Value: BigInteger; Base: BigInteger): Text
    begin
        if Value = Base then
            exit('S');
        if Value > Base then
            exit('S+' + Format(Value - Base));
        exit('S-' + Format(Base - Value));
    end;

    // The Entry Nos. of "LT SQM Entry", comma-separated, or 'none'.
    procedure Entries(): Text
    var
        Entry: Record "LT SQM Entry";
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

    // The Entry Nos. of "LT SQM Entry" relative to Base.
    procedure EntriesRel(Base: BigInteger): Text
    var
        Entry: Record "LT SQM Entry";
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

    // The Entry Nos. of "LT SQM Entry2", comma-separated, or 'none'.
    procedure Entries2(): Text
    var
        Entry2: Record "LT SQM Entry2";
        Result: Text;
    begin
        if Entry2.FindSet() then
            repeat
                if Result <> '' then
                    Result += ',';
                Result += Format(Entry2."Entry No.");
            until Entry2.Next() = 0;
        if Result = '' then
            exit('none');
        exit(Result);
    end;

    local procedure ValidateSeqNo(Name: Text; TableNo: Integer)
    var
        LastEntryNo: Integer;
    begin
        LastEntryNo := GetLastEntryNoFromTable(TableNo, false);
        if GetCurrentSeqNo(Name, TableNo) < LastEntryNo then
            CreateNewTableSequence(Name, TableNo);
    end;

    local procedure GetCurrentSeqNo(Name: Text; TableNo: Integer): Integer
    var
        CurrSeqNo: Integer;
    begin
        if TryGetCurrentNo(Name, CurrSeqNo) then
            exit(CurrSeqNo);
        ClearLastError();
        CreateNewTableSequence(Name, TableNo);
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

    local procedure CreateNewTableSequence(Name: Text; TableNo: Integer)
    begin
        CreateSequence(Name, GetLastEntryNoFromTable(TableNo, true) + 1);
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

    local procedure GetLastEntryNoFromTable(TableNo: Integer; WithLock: Boolean): BigInteger
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        RecRef: RecordRef;
        FldRef: FieldRef;
        KeyRef: KeyRef;
        LastEntryNo: BigInteger;
    begin
        RecRef.Open(TableNo);
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

// The access kinds of a Microsoft SCM test body besides Record calls on real tables. Values are thrown away; no cell
// asserts a session value.
codeunit 79527 "LT SQM Access"
{
    procedure InsertRow(RowKey: Code[30])
    var
        Row: Record "LT SQM Row";
    begin
        Row."Key" := RowKey;
        Row.Insert();
    end;

    // An entry written without the sequence, as a ledger entry that the sequence has not handed out.
    procedure InsertDirectEntry(EntryNo: Integer; CellCode: Code[10])
    var
        Entry: Record "LT SQM Entry";
    begin
        Entry."Entry No." := EntryNo;
        Entry.Cell := CellCode;
        Entry.Insert();
    end;

    // The keys of "LT SQM Row" in key order, comma-separated, or 'none'.
    procedure Rows(): Text
    var
        Row: Record "LT SQM Row";
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

    // Calls of a temporary Record variable: Insert, FindSet, Modify, DeleteAll.
    procedure TempRecord()
    var
        TempRow: Record "LT SQM Row" temporary;
    begin
        TempRow."Key" := 'TEMP';
        TempRow.Insert();
        if TempRow.FindSet() then begin
            TempRow.Description := 'T';
            TempRow.Modify();
        end;
        TempRow.DeleteAll();
    end;

    // Session builtins.
    procedure Builtins()
    var
        Discard: Text;
    begin
        Discard := CompanyName() + UserId() + Format(GuiAllowed()) + Format(WorkDate()) + Format(CurrentDateTime());
        Discard += Format(GlobalLanguage()) + Format(CurrentClientType()) + Format(UserSecurityId()) + Format(SessionId());
        if Discard = '' then;
    end;

    // A Query open and read over "LT SQM Row".
    procedure QueryRead()
    var
        RowQuery: Query "LT SQM Row Query";
        Discard: Text;
    begin
        RowQuery.Open();
        while RowQuery.Read() do
            Discard += RowQuery.RowKey;
        RowQuery.Close();
        if Discard = '' then;
    end;

    // RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), no read.
    procedure RecordRefExtra()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Discard: Text;
    begin
        RecRef.Open(Database::"LT SQM Row");
        Discard := Format(RecRef.FieldCount());
        FldRef := RecRef.Field(1);
        FldRef.Value := 'INIT';
        RecRef.SetRecFilter();
        Discard += RecRef.GetFilters();
        RecRef.Close();
        if Discard = '' then;
    end;

    // Page.Run of the card on the INIT row; the test's PageHandler closes it.
    procedure RunPage()
    var
        Row: Record "LT SQM Row";
    begin
        Row."Key" := 'INIT';
        Row.SetRecFilter();
        Page.Run(Page::"LT SQM Row Card", Row);
    end;

    // Report.SaveAs in Xml format into the Blob of a temporary record (the report reads "LT SQM Row").
    procedure ReportXml()
    var
        TempRow: Record "LT SQM Row" temporary;
        OutS: OutStream;
    begin
        TempRow.Data.CreateOutStream(OutS);
        Report.SaveAs(Report::"LT SQM Row Report", '', ReportFormat::Xml, OutS);
    end;

    // The posting preview shape: Codeunit.Run (with a return value) of a codeunit that posts and, by Mode, ends with
    // Error('') (0), ends normally (1) or ends with Error('preview engine error') (2). Returns 'Yes' or 'No' and the last
    // error text.
    procedure RunPreview(Name: Text; Mode: Integer): Text
    var
        Engine: Codeunit "LT SQM Preview";
        Ok: Boolean;
        Result: Text;
    begin
        Engine.SetName(Name);
        Engine.SetMode(Mode);
        Ok := Engine.Run();
        Result := Format(Ok) + ':''' + GetLastErrorText() + '''';
        ClearLastError();
        exit(Result);
    end;

    // The same posting in a plain call that ends with Error(''), for asserterror.
    procedure PreviewInline(Name: Text)
    var
        Seq: Codeunit "LT SQM Seq";
    begin
        InsertRow('PVA');
        if Name <> '' then
            Seq.InsertEntry(Name, 'PVA');
        Error('');
    end;

    procedure DeleteAllRows()
    var
        Row: Record "LT SQM Row";
        Entry: Record "LT SQM Entry";
        Entry2: Record "LT SQM Entry2";
    begin
        Row.DeleteAll();
        Entry.DeleteAll();
        Entry2.DeleteAll();
    end;
}

// The posting preview engine shape: writes a row, takes a number through the helper when a name is set, then by Mode
// Error('') (0, as Gen. Jnl.-Post Preview ends), nothing (1) or Error('preview engine error') (2).
codeunit 79528 "LT SQM Preview"
{
    trigger OnRun()
    var
        Access: Codeunit "LT SQM Access";
        Seq: Codeunit "LT SQM Seq";
    begin
        Access.InsertRow('PV');
        if SequenceName <> '' then
            Seq.InsertEntry(SequenceName, 'PV');
        case EngineMode of
            0:
                Error('');
            2:
                Error('preview engine error');
        end;
    end;

    procedure SetName(Name: Text)
    begin
        SequenceName := Name;
    end;

    procedure SetMode(Mode: Integer)
    begin
        EngineMode := Mode;
    end;

    var
        SequenceName: Text;
        EngineMode: Integer;
}
