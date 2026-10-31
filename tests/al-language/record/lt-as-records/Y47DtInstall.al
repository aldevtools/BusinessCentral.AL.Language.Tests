// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/datatransfer/datatransfer-data-type
// Scope: in-scope
// Fixtures used: tables 92909-92912, install codeunit 92912 (read by test codeunit 92913 in Y47DtInstallRead.al)
// Probe (al-runner issue 6586): DataTransfer in OnInstallAppPerCompany behind the reporter's guard
//   `if GetCurrentModuleExecutionContext() in [ExecutionContext::Install, ExecutionContext::Upgrade]`, on tables WITH triggers:
//   S1 the reporter's shape, CopyFields within one table, source filter on the destination field ('Display Name' = ''), Name copied into it;
//   S2 CopyFields within one table with AddConstantValue and a source filter on another field; S3 CopyRows into another table with a source
//   filter, two mapped fields, a constant, and an unmapped destination field that has an InitValue. Every table trigger (OnInsert, OnModify,
//   OnValidate) writes a row into the log table 92912, so the log shows whether DataTransfer ran any. Seeding uses Insert()/Modify() without
//   triggers. Same safety as AsDtInstaller.al: each copy runs in a TryFunction, outcomes are stored, and the 'DONE' row stops a second run.
//   Upgrade code is not probed: the corpus run never upgrades an app.
// BC versions: 27.5+

table 92909 "LT Y47 DT Entry"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Name; Text[50]) { }
        field(3; "Display Name"; Text[50])
        {
            trigger OnValidate()
            var
                Log: Record "LT Y47 DT Log";
            begin
                Log.Add('entry validate ' + Format("Entry No."));
            end;
        }
        field(4; Status; Text[20]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Record "LT Y47 DT Log";
    begin
        Log.Add('entry insert ' + Format("Entry No."));
    end;

    trigger OnModify()
    var
        Log: Record "LT Y47 DT Log";
    begin
        Log.Add('entry modify ' + Format("Entry No."));
    end;
}

table 92910 "LT Y47 DT Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Amount; Integer) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 92911 "LT Y47 DT Dest"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Amount; Integer)
        {
            trigger OnValidate()
            var
                Log: Record "LT Y47 DT Log";
            begin
                Log.Add('dest validate ' + "Code");
            end;
        }
        field(3; Note; Text[30]) { }
        field(4; Unmapped; Text[30]) { InitValue = 'init'; }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Record "LT Y47 DT Log";
    begin
        Log.Add('dest insert ' + "Code");
    end;

    trigger OnModify()
    var
        Log: Record "LT Y47 DT Log";
    begin
        Log.Add('dest modify ' + "Code");
    end;
}

// Outcomes ('S1'..'S3', 'CTX', 'DONE') and the trigger log ('L0001'..), one row each.
table 92912 "LT Y47 DT Log"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Outcome; Text[250]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }

    procedure Add(Line: Text)
    var
        Log: Record "LT Y47 DT Log";
        Next: Integer;
    begin
        Log.SetFilter("Code", 'L*');
        Next := Log.Count() + 1;
        Log.Init();
        Log."Code" := CopyStr('L' + Format(Next, 4, '<Integer,4><Filler Character,0>'), 1, 20);
        Log.Outcome := CopyStr(Line, 1, 250);
        Log.Insert();
    end;
}

codeunit 92912 "LT Y47 DT Installer"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        Obs: Record "LT Y47 DT Log";
    begin
        if Obs.Get('DONE') then
            exit;
        Seed();
        Save('CTX', Format(GetCurrentModuleExecutionContext()));
        if GetCurrentModuleExecutionContext() in [ExecutionContext::Install, ExecutionContext::Upgrade] then begin
            Save('S1', Outcome(TryReporterShape()));
            Save('S2', Outcome(TryConstantSameTable()));
            Save('S3', Outcome(TryCopyRows()));
        end;
        Save('DONE', 'ok');
    end;

    local procedure Seed()
    var
        Entry: Record "LT Y47 DT Entry";
        Src: Record "LT Y47 DT Src";
    begin
        if not Entry.Get(1) then
            AddEntry(1, 'alpha', '');
        if not Entry.Get(2) then
            AddEntry(2, 'beta', 'keep');
        if not Entry.Get(3) then
            AddEntry(3, '', '');
        if not Entry.Get(4) then
            AddEntry(4, 'delta', '');
        if not Src.Get('A') then
            AddSrc('A', 10);
        if not Src.Get('B') then
            AddSrc('B', 20);
        if not Src.Get('C') then
            AddSrc('C', 30);
    end;

    local procedure AddEntry(No: Integer; NewName: Text[50]; NewDisplay: Text[50])
    var
        Entry: Record "LT Y47 DT Entry";
    begin
        Entry.Init();
        Entry."Entry No." := No;
        Entry.Name := NewName;
        Entry."Display Name" := NewDisplay;
        Entry.Status := 'seed';
        Entry.Insert();
    end;

    local procedure AddSrc(NewCode: Code[20]; NewAmount: Integer)
    var
        Src: Record "LT Y47 DT Src";
    begin
        Src.Init();
        Src."Code" := NewCode;
        Src.Amount := NewAmount;
        Src.Insert();
    end;

    local procedure Outcome(Ok: Boolean): Text
    begin
        if Ok then
            exit('ok');
        exit(GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Save(NewCode: Code[20]; Value: Text)
    var
        Obs: Record "LT Y47 DT Log";
    begin
        if Obs.Get(NewCode) then
            exit;
        Obs.Init();
        Obs."Code" := NewCode;
        Obs.Outcome := CopyStr(Value, 1, MaxStrLen(Obs.Outcome));
        Obs.Insert();
    end;

    // S1: the reporter's shape (al-runner issue 6586).
    [TryFunction]
    local procedure TryReporterShape()
    var
        Entry: Record "LT Y47 DT Entry";
        EntryDataTransfer: DataTransfer;
    begin
        EntryDataTransfer.SetTables(Database::"LT Y47 DT Entry", Database::"LT Y47 DT Entry");
        EntryDataTransfer.AddSourceFilter(Entry.FieldNo("Display Name"), '=%1', '');
        EntryDataTransfer.AddFieldValue(Entry.FieldNo(Name), Entry.FieldNo("Display Name"));
        EntryDataTransfer.CopyFields();
    end;

    // S2: CopyFields within one table, constant into Status where Name is not blank (runs after S1).
    [TryFunction]
    local procedure TryConstantSameTable()
    var
        Entry: Record "LT Y47 DT Entry";
        EntryDataTransfer: DataTransfer;
    begin
        EntryDataTransfer.SetTables(Database::"LT Y47 DT Entry", Database::"LT Y47 DT Entry");
        EntryDataTransfer.AddSourceFilter(Entry.FieldNo(Name), '<>%1', '');
        EntryDataTransfer.AddConstantValue('const', Entry.FieldNo(Status));
        EntryDataTransfer.CopyFields();
    end;

    // S3: CopyRows into an empty table, source filter Amount >= 20, Code and Amount mapped, constant into Note, Unmapped left out.
    [TryFunction]
    local procedure TryCopyRows()
    var
        Src: Record "LT Y47 DT Src";
        Dest: Record "LT Y47 DT Dest";
        RowsDataTransfer: DataTransfer;
    begin
        RowsDataTransfer.SetTables(Database::"LT Y47 DT Src", Database::"LT Y47 DT Dest");
        RowsDataTransfer.AddSourceFilter(Src.FieldNo(Amount), '>=%1', 20);
        RowsDataTransfer.AddFieldValue(Src.FieldNo("Code"), Dest.FieldNo("Code"));
        RowsDataTransfer.AddFieldValue(Src.FieldNo(Amount), Dest.FieldNo(Amount));
        RowsDataTransfer.AddConstantValue('rows', Dest.FieldNo(Note));
        RowsDataTransfer.CopyRows();
    end;
}
