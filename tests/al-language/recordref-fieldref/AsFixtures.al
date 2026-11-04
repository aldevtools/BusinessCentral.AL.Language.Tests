// Fixtures for the LT AS record probes (corpus issue 644): own tables 79900-79912, enum 79907, helper codeunit 79913. Not a test codeunit.

table 79900 "LT AS Int Key"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; D; Date) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 79901 "LT AS Big Key"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; BigInteger) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 79902 "LT AS Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
        field(4; Data; Blob) { }
        field(5; Cd; Code[20]) { }
        field(6; LogCount; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT AS Log");
        }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnDelete()
    var
        Log: Record "LT AS Log";
    begin
        Log.Add('OnDelete ' + "No.");
    end;
}

table 79903 "LT AS Log"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Msg; Text[100]) { }
    }
    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }

    procedure Add(Text: Text)
    var
        Last: Record "LT AS Log";
        Next: Integer;
    begin
        if Last.FindLast() then
            Next := Last."Entry No.";
        Rec.Init();
        Rec."Entry No." := Next + 1;
        Rec.Msg := CopyStr(Text, 1, MaxStrLen(Rec.Msg));
        Rec.Insert();
    end;

    procedure Dump(): Text
    var
        Row: Record "LT AS Log";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                if Result <> '' then
                    Result += ',';
                Result += Row.Msg;
            until Row.Next() = 0;
        exit(Result);
    end;
}

table 79904 "LT AS Other"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Key"; Code[20]) { }
        field(2; Description; Text[30]) { }
    }
    keys
    {
        key(PK; "Key") { Clustered = true; }
    }
}

table 79905 "LT AS Code Key"
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

table 79906 "LT AS TF Row"
{
    DataClassification = SystemMetadata;
    Caption = 'AS TF Caption';

    fields
    {
        field(1; Id; Integer) { Caption = 'Id Cap'; }
        field(2; Num; Integer) { Caption = 'Num Cap'; }
        field(3; Kind; Enum "LT AS Kind") { Caption = 'Kind Cap'; }
        field(4; Cd; Code[50]) { Caption = 'Cd Cap'; }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

enum 79907 "LT AS Kind"
{
    Extensible = false;

    value(0; None) { Caption = 'Nothing Cap'; }
    value(1; Alpha) { Caption = 'Alpha Cap'; }
}

table 79908 "LT AS Caption PK"
{
    DataClassification = SystemMetadata;
    Caption = 'AS PK Table Cap';

    fields
    {
        field(1; "Key Code"; Code[20]) { Caption = 'Key Caption'; }
        field(2; Name; Text[30]) { Caption = 'Name Caption'; }
    }
    keys
    {
        key(PK; "Key Code") { Clustered = true; }
    }
}

table 79910 "LT AS Rel Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Kind; Integer) { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 79911 "LT AS Flow Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; LineCount; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT AS Flow Line" where(Head = field("Code")));
        }
        field(3; RelCode; Code[20])
        {
            TableRelation = "LT AS Rel Parent"."Code" where(Kind = field(LineCount));
        }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 79912 "LT AS Flow Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Head; Code[20]) { }
        field(2; Line; Integer) { }
    }
    keys
    {
        key(PK; Head, Line) { Clustered = true; }
    }
}

codeunit 79913 "LT AS Helper"
{
    procedure SeedRows()
    var
        Row: Record "LT AS Row";
        Log: Record "LT AS Log";
    begin
        Row.DeleteAll();
        Log.DeleteAll();
        AddRow('A', 'alpha', 1);
        AddRow('B', 'beta', 2);
        AddRow('C', 'gamma', 3);
    end;

    procedure AddRow(No: Code[20]; Name: Text[30]; Amount: Decimal)
    var
        Row: Record "LT AS Row";
    begin
        Row."No." := No;
        Row.Name := Name;
        Row.Amount := Amount;
        Row.Cd := No;
        Row.Insert();
    end;

    procedure Rows(): Text
    var
        Row: Record "LT AS Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Row."No.";
            until Row.Next() = 0;
        exit(Result);
    end;

    procedure LastError(): Text
    var
        Result: Text;
    begin
        Result := GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;
}
