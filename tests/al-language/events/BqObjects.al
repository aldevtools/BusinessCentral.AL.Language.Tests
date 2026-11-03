// Scope: in-scope
// Fixtures for corpus issue 668 ("Odd AL behavior leads", part C), writer BQ. The tests that use them were added to the existing test
// codeunits of their areas (record/lt-record-read, record/lt-record-write, record/lt-set-current-key, filters, ...); this file holds only
// the tables, enums and helper codeunits they need. Object ids 82750-82773.

table 82750 "LT BQ Flt Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; G; Guid) { }
        field(3; Txt; Text[30]) { }
        field(4; Cd; Code[20]) { }
        field(5; Num; Integer) { }
        field(6; DT; DateTime) { }
        field(7; D; Date) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// Resolves the custom filter tokens BQGUID (to a Guid text) and BQFIVE (to 5) through the System Application's Filter Tokens event.
codeunit 82751 "LT BQ Token Sub"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Filter Tokens", 'OnResolveTextFilterToken', '', true, true)]
    local procedure ResolveToken(TextToken: Text; var TextFilter: Text; var Handled: Boolean)
    var
        Log: Codeunit "LT BQ Token Log";
    begin
        Log.Add('token:' + TextToken);
        case UpperCase(TextToken) of
            'BQGUID':
                begin
                    TextFilter := '{00000000-0000-0000-0000-000000000001}';
                    Handled := true;
                end;
            'BQFIVE':
                begin
                    TextFilter := '5';
                    Handled := true;
                end;
        end;
    end;
}

// Log of the ChangeCompany tests (codeunit 68391 "Probe Chg Company Arm" only: a SingleInstance fixture has one test codeunit owner).
codeunit 82752 "LT BQ Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        TargetCompany: Text[30];

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ',';
        Entries += Entry;
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;

    procedure SetTarget(NewTarget: Text[30])
    begin
        TargetCompany := NewTarget;
    end;

    procedure Target(): Text[30]
    begin
        exit(TargetCompany);
    end;
}

table 82753 "LT BQ FG Owner"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
        field(3; Total; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT BQ FG Line".Amount where(OwnerId = field(Id)));
        }
        field(4; NestedTotal; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = lookup("LT BQ FG Owner".Total where(Id = field(Id)));
        }
        field(5; FirstTxt; Text[20])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("LT BQ FG Line".Txt where(OwnerId = field(Id)));
        }
        field(6; IdFilter; Integer)
        {
            FieldClass = FlowFilter;
        }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 82754 "LT BQ FG Line"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; OwnerId; Integer) { }
        field(3; Amount; Decimal) { }
        field(4; Txt; Text[20]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// Keys for the question which key SetCurrentKey picks: K1 (A, B) and K2 (A, C) both start with A, K3 (C) and K2 both hold C, E is only an
// included field of K5, F is only in the disabled key K6.
table 82755 "LT BQ Key Pick"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; A; Integer) { }
        field(3; B; Integer) { }
        field(4; C; Integer) { }
        field(5; D; Integer) { }
        field(6; E; Integer) { }
        field(7; F; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
        key(K1; A, B) { }
        key(K2; A, C) { }
        key(K3; C) { }
        key(K5; D) { IncludedFields = E; }
        key(K6; F) { Enabled = false; }
    }
}

table 82756 "LT BQ Blob Src"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Data; Blob) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 82757 "LT BQ Blob Dst"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Data; Blob) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// Field numbers of Customer (Base Application) with other types: 2 Name is Text[100] there, 3 "Search Name" is Code[100], 5 Address is
// Text[100].
table 82758 "LT BQ Cust Dst"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Integer) { }
        field(3; "Search Name"; Text[100]) { }
        field(5; Address; Text[10]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 82759 "LT BQ Rid Key"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Ref; RecordId) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(PK; Ref) { Clustered = true; }
    }
}

table 82760 "LT BQ AutoInc Removed"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Seq; BigInteger)
        {
            AutoIncrement = true;
            ObsoleteState = Removed;
            ObsoleteReason = 'Probe of a removed AutoIncrement field.';
            ObsoleteTag = '1.0';
        }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 82761 "LT BQ AutoInc Plain"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Seq; BigInteger) { AutoIncrement = true; }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// Triggers and a validated field that log CompanyName(); OnModify inserts a row into "LT BQ Chg Empty" in the company the log names.
table 82762 "LT BQ Chg Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT BQ Log";
            begin
                Log.Add('V:' + CompanyName());
            end;
        }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "LT BQ Log";
    begin
        Log.Add('I:' + CompanyName());
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT BQ Log";
        Empty: Record "LT BQ Chg Empty";
    begin
        Log.Add('M:' + CompanyName());
        if Log.Target() <> '' then begin
            Empty.ChangeCompany(Log.Target());
            Empty.Id := 1;
            Empty.Txt := 'from OnModify';
            if Empty.Insert() then
                Log.Add('emptyInsert:ok:' + Empty.CurrentCompany())
            else
                Log.Add('emptyInsert:false:' + GetLastErrorText());
        end;
    end;

    trigger OnDelete()
    var
        Log: Codeunit "LT BQ Log";
    begin
        Log.Add('D:' + CompanyName());
    end;
}

table 82763 "LT BQ Chg Side"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[60]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 82764 "LT BQ Chg Empty"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// Database-event subscribers of "LT BQ Chg Row": log CompanyName() and the record's CurrentCompany(), and write a row into "LT BQ Chg Side"
// through a plain record variable (no ChangeCompany).
codeunit 82765 "LT BQ Chg Sub"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"LT BQ Chg Row", 'OnAfterInsertEvent', '', false, false)]
    local procedure AfterInsert(var Rec: Record "LT BQ Chg Row"; RunTrigger: Boolean)
    begin
        Note('SI', Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT BQ Chg Row", 'OnAfterModifyEvent', '', false, false)]
    local procedure AfterModify(var Rec: Record "LT BQ Chg Row"; var xRec: Record "LT BQ Chg Row"; RunTrigger: Boolean)
    begin
        Note('SM', Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT BQ Chg Row", 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDelete(var Rec: Record "LT BQ Chg Row"; RunTrigger: Boolean)
    begin
        Note('SD', Rec);
    end;

    local procedure Note(Kind: Text; var Rec: Record "LT BQ Chg Row")
    var
        Log: Codeunit "LT BQ Log";
        Side: Record "LT BQ Chg Side";
    begin
        Log.Add(Kind + ':' + CompanyName() + '/' + Rec.CurrentCompany());
        if Side.FindLast() then
            Side.Id += 1
        else
            Side.Id := 1;
        Side.Txt := CopyStr(Kind + ' ' + Format(Rec.Id), 1, 60);
        Side.Insert();
    end;
}

// A publisher with a record parameter passed by value, and a subscriber that logs what it receives.
codeunit 82766 "LT BQ TRV Pub"
{
    procedure Raise(R: Record "LT TRV Row")
    begin
        OnByValue(R);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnByValue(R: Record "LT TRV Row")
    begin
    end;
}

codeunit 82767 "LT BQ TRV Sub"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT BQ TRV Pub", 'OnByValue', '', false, false)]
    local procedure ByValue(R: Record "LT TRV Row")
    var
        Log: Codeunit "LT BQ TRV Log";
    begin
        Log.Add('temp=' + Format(R.IsTemporary()) + ' count=' + Format(R.Count()));
    end;
}

// Table procedures whose return type is the table's own record type (microsoft/AL issue 6529).
table 82768 "LT BQ Ret Row"
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

    procedure FirstUnnamed(): Record "LT BQ Ret Row"
    begin
        Rec.FindFirst();
    end;

    procedure FirstNamed() Result: Record "LT BQ Ret Row"
    begin
        Result.FindFirst();
    end;

    procedure FirstExitRec(): Record "LT BQ Ret Row"
    begin
        Rec.FindFirst();
        exit(Rec);
    end;
}

tableextension 82769 "LT BQ Ret Ext" extends "LT BQ Ret Row"
{
    fields
    {
        field(82750; ExtNote; Text[30]) { DataClassification = SystemMetadata; }
    }

    procedure ExtFirstUnnamed(): Record "LT BQ Ret Row"
    begin
        Rec.FindFirst();
    end;

    procedure ExtFirstExitRec(): Record "LT BQ Ret Row"
    begin
        Rec.FindFirst();
        exit(Rec);
    end;
}

table 82770 "LT BQ Pos Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Integer) { }
        field(3; Name; Text[30]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
        key(BySys; Grp, SystemId) { }
    }
}

codeunit 82771 "LT BQ Seed"
{
    // Owners: 1 'one' (Total 0, no lines), 2 '' (Total 5, line Txt 'beta'), 3 'three' (Total 7, lines Txt 'alpha' and 'gamma').
    procedure Owners()
    var
        Owner: Record "LT BQ FG Owner";
        Line: Record "LT BQ FG Line";
    begin
        Owner.DeleteAll();
        Line.DeleteAll();
        AddOwner(1, 'one');
        AddOwner(2, '');
        AddOwner(3, 'three');
        AddLine(10, 2, 5, 'beta');
        AddLine(11, 3, 3, 'alpha');
        AddLine(12, 3, 4, 'gamma');
    end;

    local procedure AddOwner(Id: Integer; Name: Text[20])
    var
        Owner: Record "LT BQ FG Owner";
    begin
        Owner.Id := Id;
        Owner.Name := Name;
        Owner.Insert();
    end;

    local procedure AddLine(Id: Integer; OwnerId: Integer; Amount: Decimal; Txt: Text[20])
    var
        Line: Record "LT BQ FG Line";
    begin
        Line.Id := Id;
        Line.OwnerId := OwnerId;
        Line.Amount := Amount;
        Line.Txt := Txt;
        Line.Insert();
    end;

    // Rows: 1 G ...0001 'abc' 'C5' 5; 2 G ...0002 '5' '5' 7; 3 all blank.
    procedure FltRows()
    var
        R: Record "LT BQ Flt Row";
    begin
        R.DeleteAll();
        R.Init();
        R.Id := 1;
        Evaluate(R.G, '{00000000-0000-0000-0000-000000000001}');
        R.Txt := 'abc';
        R.Cd := 'C5';
        R.Num := 5;
        R.Insert();
        R.Init();
        R.Id := 2;
        Evaluate(R.G, '{00000000-0000-0000-0000-000000000002}');
        R.Txt := '5';
        R.Cd := '5';
        R.Num := 7;
        R.Insert();
        R.Init();
        R.Id := 3;
        R.Insert();
    end;

    procedure Ids(var R: Record "LT BQ Flt Row"): Text
    var
        Result: Text;
    begin
        if R.FindSet() then
            repeat
                Result += Format(R.Id) + ' ';
            until R.Next() = 0;
        exit(Result);
    end;
}

// Log of the custom filter token tests (codeunit 71504 "LT RcA SetFilter" only), written by "LT BQ Token Sub".
codeunit 82772 "LT BQ Token Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ',';
        Entries += Entry;
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

// Log of the record-by-value event tests (codeunit 74886 "LT TRV Tests" only), written by "LT BQ TRV Sub".
codeunit 82773 "LT BQ TRV Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ',';
        Entries += Entry;
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}
