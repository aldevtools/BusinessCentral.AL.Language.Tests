// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-rename-method
// Scope: in-scope (Cloud)
// Fixtures used: Probe Observer (codeunit 69160); tables 79100-79145, table extension 79100, codeunits 79100-79106 (all self-contained);
//   Base Application GlobalTriggerManagement (codeunit 49) events
// Probe (al-runner issue 7937): Record.Rename of a row whose primary key changes to or from its blank or zero value, when another
//   table relates to the table. Each test commits its setup, runs the Rename inside Codeunit.Run (so an error rolls back only the
//   Rename) and records: whether Rename raised, GetLastErrorText (with the positions and codes of its control characters),
//   GetLastErrorCode, and the rows of the tables afterwards.
// Cells: Code key from and to blank with 0, 1 and 2 related rows; Integer key from and to 0; a two-field key where the blank field
//   changes or keeps its value; Guid, Option and Date keys; a relation with an if condition, with a where filter, to the named key
//   field, to a non-key field; ValidateTableRelation = false; a relation from a table extension field and from a field of the
//   same table; a temporary record; an OnRename trigger and OnBefore/OnAfterRenameEvent subscribers (log of what ran); a
//   table and field Caption; a table nothing relates to (control); a non-blank to non-blank rename (control); the row with the new
//   key already exists; the old row is not stored; the return value form and RecordRef.Rename; a relation from a FlowFilter and
//   from a FlowField; a Boolean key field false <-> true with a relation to a non-key field (Sales Invoice Entity Aggregate) and to
//   the other key field; an Option key field 0 <-> 1 next to the related key field (Sales Header); a relation to key field A while
//   key field B changes to or from blank; the database rename trigger switched on through GlobalTriggerManagement (log of
//   OnAfterOnDatabaseRename against the error); child rows that hold other values; a Code[10] child field against a Code[20] key.
// Results (corpus CI, BC 27.5, 28.5 and 29.0 on Linux, identical on all three):
//   - Rename raises when a primary key field changes from or to its blank or zero value ('' for Code, 0 for Integer, the first
//     Option member, the null Guid, 0D) and a validated TableRelation of another table, a table extension field or a field of the
//     same table targets THAT field (a plain relation to the table, the named key field, with an if condition (met or not),
//     with a where filter, or a Code[10] field against a Code[20] key). Whether any row holds the old value does not matter
//     (0, 1, 2 rows, other values only).
//   - Text: 'The <field caption> field on the <table caption> table cannot be renamed from "<old>" to "<new>".' then two
//     backslash characters (no CR or LF) then 'When a field has a relation defined, the field cannot be renamed to and from zero
//     or an empty value.' The values are formatted (Option caption " ", Date in the session format, Guid with braces).
//     GetLastErrorCode is 'DB:Ok'. Captions are used where the table and field have them.
//   - It does NOT raise: a non-blank to non-blank rename; a key field that keeps its blank value; a key field that changes from
//     blank when the relation targets another key field (A only in the where filter, or the relation to A while B changes);
//     Boolean and Option key fields that change while the relation targets another field; a relation to a non-key field;
//     ValidateTableRelation = false; a relation from a FlowFilter or a FlowField; a temporary record; a table nothing relates to.
//   - Order: OnBeforeRenameEvent, the OnRename trigger and the database rename event (GlobalTriggerManagement
//     OnAfterOnDatabaseRename) run before the error; OnAfterRenameEvent does not run. The row and the related rows stay as they were.
//   - The return value form (Ok := Rec.Rename(...)) raises the same error; RecordRef.Rename raises the same error.
//   - When the new key already exists, the already-exists error (DB:RecordExists) comes instead; when the old row is not stored,
//     the does-not-exist error (DB:RecordNotFound) comes instead.
// BC versions: 27, 28, 29

table 79100 "RBK Master"
{
    DataClassification = SystemMetadata;
    fields { field(1; "Code"; Code[20]) { } }
    keys { key(PK; "Code") { Clustered = true; } }
}

table 79101 "RBK Child"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Master Code"; Code[20]) { TableRelation = "RBK Master"; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 79102 "RBK Int Master"
{
    DataClassification = SystemMetadata;
    fields { field(1; "No."; Integer) { } }
    keys { key(PK; "No.") { Clustered = true; } }
}

table 79103 "RBK Int Child"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Master No."; Integer) { TableRelation = "RBK Int Master"; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 79104 "RBK Multi Master"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; A; Code[10]) { }
        field(2; B; Code[10]) { }
    }
    keys { key(PK; A, B) { Clustered = true; } }
}

table 79105 "RBK Multi Child"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; RefA; Code[10]) { }
        field(3; RefB; Code[10]) { TableRelation = "RBK Multi Master".B where(A = field(RefA)); }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 79106 "RBK Guid Master"
{
    DataClassification = SystemMetadata;
    fields { field(1; Id; Guid) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

table 79107 "RBK Guid Child"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Master Id"; Guid) { TableRelation = "RBK Guid Master"; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 79108 "RBK Option Master"
{
    DataClassification = SystemMetadata;
    fields { field(1; Kind; Option) { OptionMembers = " ",Alpha,Beta; } }
    keys { key(PK; Kind) { Clustered = true; } }
}

table 79109 "RBK Option Child"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Master Kind"; Option) { OptionMembers = " ",Alpha,Beta; TableRelation = "RBK Option Master"; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 79110 "RBK Date Master"
{
    DataClassification = SystemMetadata;
    fields { field(1; Day; Date) { } }
    keys { key(PK; Day) { Clustered = true; } }
}

table 79111 "RBK Date Child"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Master Day"; Date) { TableRelation = "RBK Date Master"; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 79112 "RBK If Master"
{
    DataClassification = SystemMetadata;
    fields { field(1; "Code"; Code[20]) { } }
    keys { key(PK; "Code") { Clustered = true; } }
}

table 79113 "RBK If Child"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Kind; Option) { OptionMembers = " ",Linked; }
        field(3; Ref; Code[20]) { TableRelation = if (Kind = const(Linked)) "RBK If Master"; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 79114 "RBK Where Master"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Name; Text[30]) { }
    }
    keys { key(PK; "Code") { Clustered = true; } }
}

table 79115 "RBK Where Child"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Ref; Code[20]) { TableRelation = "RBK Where Master" where(Name = const('N')); }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 79116 "RBK Named Master"
{
    DataClassification = SystemMetadata;
    fields { field(1; "Code"; Code[20]) { } }
    keys { key(PK; "Code") { Clustered = true; } }
}

table 79117 "RBK Named Child"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Ref; Code[20]) { TableRelation = "RBK Named Master"."Code"; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 79118 "RBK NonKey Master"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Name; Code[20]) { }
    }
    keys { key(PK; "Code") { Clustered = true; } }
}

table 79119 "RBK NonKey Child"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Ref; Code[20]) { TableRelation = "RBK NonKey Master".Name; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 79120 "RBK NoVal Master"
{
    DataClassification = SystemMetadata;
    fields { field(1; "Code"; Code[20]) { } }
    keys { key(PK; "Code") { Clustered = true; } }
}

table 79121 "RBK NoVal Child"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Ref; Code[20])
        {
            TableRelation = "RBK NoVal Master";
            ValidateTableRelation = false;
        }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 79122 "RBK Ext Master"
{
    DataClassification = SystemMetadata;
    fields { field(1; "Code"; Code[20]) { } }
    keys { key(PK; "Code") { Clustered = true; } }
}

table 79123 "RBK Ext Child"
{
    DataClassification = SystemMetadata;
    fields { field(1; "Entry No."; Integer) { } }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

tableextension 79100 "RBK Ext Child Ext" extends "RBK Ext Child"
{
    fields
    {
        field(79100; "RBK Ext Ref"; Code[20])
        {
            DataClassification = SystemMetadata;
            TableRelation = "RBK Ext Master";
        }
    }
}

table 79124 "RBK Self Master"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "Parent Code"; Code[20]) { TableRelation = "RBK Self Master"; }
    }
    keys { key(PK; "Code") { Clustered = true; } }
}

table 79125 "RBK Trg Master"
{
    DataClassification = SystemMetadata;
    fields { field(1; "Code"; Code[20]) { } }
    keys { key(PK; "Code") { Clustered = true; } }

    trigger OnRename()
    var
        Log: Codeunit "RBK Rename Log";
    begin
        Log.Add('OnRename xRec=[' + xRec."Code" + '] Rec=[' + Rec."Code" + ']');
    end;
}

table 79126 "RBK Trg Child"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Ref; Code[20]) { TableRelation = "RBK Trg Master"; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 79127 "RBK Cap Master"
{
    Caption = 'RBK Captioned Master';
    DataClassification = SystemMetadata;
    fields { field(1; "Code"; Code[20]) { Caption = 'Key Caption'; } }
    keys { key(PK; "Code") { Clustered = true; } }
}

table 79128 "RBK Cap Child"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Ref; Code[20]) { TableRelation = "RBK Cap Master"; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 79129 "RBK Plain Master"
{
    DataClassification = SystemMetadata;
    fields { field(1; "Code"; Code[20]) { } }
    keys { key(PK; "Code") { Clustered = true; } }
}

table 79130 "RBK FFilter Master"
{
    DataClassification = SystemMetadata;
    fields { field(1; "Code"; Code[20]) { } }
    keys { key(PK; "Code") { Clustered = true; } }
}

table 79131 "RBK FFilter Child"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Master Filter"; Code[20]) { FieldClass = FlowFilter; TableRelation = "RBK FFilter Master"; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 79132 "RBK FField Master"
{
    DataClassification = SystemMetadata;
    fields { field(1; "Code"; Code[20]) { } }
    keys { key(PK; "Code") { Clustered = true; } }
}

table 79133 "RBK FField Child"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Src; Code[20]) { }
        field(3; Ref; Code[20])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("RBK FField Child".Src where("Entry No." = field("Entry No.")));
            TableRelation = "RBK FField Master";
        }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

// The shape of Base Application's Sales Invoice Entity Aggregate: key (No., Posted), other tables relate to a non-key field.
table 79134 "RBK Bool Master"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Posted; Boolean) { }
        field(3; Id; Code[20]) { }
    }
    keys { key(PK; "No.", Posted) { Clustered = true; } }
}

table 79135 "RBK Bool Child"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; RefId; Code[20]) { TableRelation = "RBK Bool Master".Id; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 79136 "RBK BoolKey Master"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Posted; Boolean) { }
    }
    keys { key(PK; "No.", Posted) { Clustered = true; } }
}

table 79137 "RBK BoolKey Child"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; RefNo; Code[20]) { TableRelation = "RBK BoolKey Master"."No."; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 79138 "RBK OptPair Master"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Kind; Option) { OptionMembers = Quote,Order; }
        field(2; "No."; Code[20]) { }
    }
    keys { key(PK; Kind, "No.") { Clustered = true; } }
}

table 79139 "RBK OptPair Child"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Kind; Option) { OptionMembers = Quote,Order; }
        field(3; "Doc No."; Code[20]) { TableRelation = "RBK OptPair Master"."No." where(Kind = field(Kind)); }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 79140 "RBK PairA Master"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; A; Code[10]) { }
        field(2; B; Code[10]) { }
    }
    keys { key(PK; A, B) { Clustered = true; } }
}

table 79141 "RBK PairA Child"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; RefA; Code[10]) { TableRelation = "RBK PairA Master".A; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 79142 "RBK Short Master"
{
    DataClassification = SystemMetadata;
    fields { field(1; "Code"; Code[20]) { } }
    keys { key(PK; "Code") { Clustered = true; } }
}

table 79143 "RBK Short Child"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Ref; Code[10]) { TableRelation = "RBK Short Master"; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 79144 "RBK DbTrg Master"
{
    DataClassification = SystemMetadata;
    fields { field(1; "Code"; Code[20]) { } }
    keys { key(PK; "Code") { Clustered = true; } }
}

table 79145 "RBK DbTrg Child"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Ref; Code[20]) { TableRelation = "RBK DbTrg Master"; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

// The log of what ran around a Rename of "RBK Trg Master". Used only by the test codeunit "RBK Rename Blank Trg".
codeunit 79102 "RBK Rename Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ' | ';
        Entries += Entry;
    end;

    procedure Get(): Text
    begin
        exit(Entries);
    end;

    procedure Reset()
    begin
        Entries := '';
    end;
}

codeunit 79103 "RBK Rename Subscriber"
{
    [EventSubscriber(ObjectType::Table, Database::"RBK Trg Master", OnBeforeRenameEvent, '', false, false)]
    local procedure OnBeforeRename(var Rec: Record "RBK Trg Master"; var xRec: Record "RBK Trg Master"; RunTrigger: Boolean)
    var
        Log: Codeunit "RBK Rename Log";
    begin
        Log.Add('OnBeforeRenameEvent xRec=[' + xRec."Code" + '] Rec=[' + Rec."Code" + ']');
    end;

    [EventSubscriber(ObjectType::Table, Database::"RBK Trg Master", OnAfterRenameEvent, '', false, false)]
    local procedure OnAfterRename(var Rec: Record "RBK Trg Master"; var xRec: Record "RBK Trg Master"; RunTrigger: Boolean)
    var
        Log: Codeunit "RBK Rename Log";
    begin
        Log.Add('OnAfterRenameEvent xRec=[' + xRec."Code" + '] Rec=[' + Rec."Code" + ']');
    end;
}

// Switches the database rename trigger on for "RBK DbTrg Master" only and logs the database rename events of that table.
codeunit 79106 "RBK Db Rename Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterGetDatabaseTableTriggerSetup', '', false, false)]
    local procedure AfterSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
        if TableId = Database::"RBK DbTrg Master" then
            OnDatabaseRename := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnDatabaseRename', '', false, false)]
    local procedure AfterDbRename(RecRef: RecordRef; xRecRef: RecordRef)
    var
        Log: Codeunit "RBK Rename Log";
    begin
        if RecRef.Number() <> Database::"RBK DbTrg Master" then
            exit;
        Log.Add('OnAfterOnDatabaseRename xRec=[' + Format(xRecRef.Field(1).Value()) + '] Rec=[' + Format(RecRef.Field(1).Value()) + ']');
    end;

    [EventSubscriber(ObjectType::Table, Database::"RBK DbTrg Master", OnBeforeRenameEvent, '', false, false)]
    local procedure OnBeforeRename(var Rec: Record "RBK DbTrg Master"; var xRec: Record "RBK DbTrg Master"; RunTrigger: Boolean)
    var
        Log: Codeunit "RBK Rename Log";
    begin
        Log.Add('OnBeforeRenameEvent xRec=[' + xRec."Code" + '] Rec=[' + Rec."Code" + ']');
    end;
}

// Runs one Rename in OnRun, so the caller can use `if Runner.Run() then` (an error rolls back only the Rename) and read the rows
// afterwards. Set* chooses the table and the old and new key; Rows lists the rows of a table as [value][value]... per row.
codeunit 79101 "RBK Rename Runner"
{
    var
        TableId: Integer;
        OldCode: Code[20];
        NewCode: Code[20];
        OldInt: Integer;
        NewInt: Integer;
        OldGuid: Guid;
        NewGuid: Guid;
        OldOption: Integer;
        NewOption: Integer;
        OldDate: Date;
        NewDate: Date;
        OldA: Code[10];
        OldB: Code[10];
        NewA: Code[10];
        NewB: Code[10];
        UseTemporary: Boolean;
        Mode: Integer;
        ReturnInfo: Text;
        OldBool: Boolean;
        NewBool: Boolean;
        TempMaster: Record "RBK Master" temporary;

    trigger OnRun()
    var
        Master: Record "RBK Master";
        IntMaster: Record "RBK Int Master";
        MultiMaster: Record "RBK Multi Master";
        GuidMaster: Record "RBK Guid Master";
        OptionMaster: Record "RBK Option Master";
        DateMaster: Record "RBK Date Master";
        IfMaster: Record "RBK If Master";
        WhereMaster: Record "RBK Where Master";
        NamedMaster: Record "RBK Named Master";
        NonKeyMaster: Record "RBK NonKey Master";
        NoValMaster: Record "RBK NoVal Master";
        ExtMaster: Record "RBK Ext Master";
        SelfMaster: Record "RBK Self Master";
        TrgMaster: Record "RBK Trg Master";
        CapMaster: Record "RBK Cap Master";
        PlainMaster: Record "RBK Plain Master";
        FFilterMaster: Record "RBK FFilter Master";
        FFieldMaster: Record "RBK FField Master";
        BoolMaster: Record "RBK Bool Master";
        BoolKeyMaster: Record "RBK BoolKey Master";
        OptPairMaster: Record "RBK OptPair Master";
        PairAMaster: Record "RBK PairA Master";
        ShortMaster: Record "RBK Short Master";
        DbTrgMaster: Record "RBK DbTrg Master";
        RecRef: RecordRef;
        Renamed: Boolean;
    begin
        if UseTemporary then begin
            TempMaster.Get(OldCode);
            TempMaster.Rename(NewCode);
            exit;
        end;
        case TableId of
            Database::"RBK Master":
                case Mode of
                    0:
                        begin
                            Master.Get(OldCode);
                            Master.Rename(NewCode);
                        end;
                    1:
                        begin
                            // The old row is not stored: the buffer only holds the old key.
                            Master.Init();
                            Master."Code" := OldCode;
                            Master.Rename(NewCode);
                        end;
                    2:
                        begin
                            Master.Get(OldCode);
                            ClearLastError();
                            Renamed := Master.Rename(NewCode);
                            ReturnInfo := 'returned ' + Format(Renamed) + '; last error ' + GetLastErrorText() + '; controls ' + ControlCodes(GetLastErrorText());
                        end;
                    3:
                        begin
                            Master.Get(OldCode);
                            RecRef.Open(Database::"RBK Master");
                            RecRef.Get(Master.RecordId());
                            RecRef.Rename(NewCode);
                        end;
                end;
            Database::"RBK Int Master":
                begin
                    IntMaster.Get(OldInt);
                    IntMaster.Rename(NewInt);
                end;
            Database::"RBK Multi Master":
                begin
                    MultiMaster.Get(OldA, OldB);
                    MultiMaster.Rename(NewA, NewB);
                end;
            Database::"RBK Guid Master":
                begin
                    GuidMaster.Get(OldGuid);
                    GuidMaster.Rename(NewGuid);
                end;
            Database::"RBK Option Master":
                begin
                    OptionMaster.Get(OldOption);
                    OptionMaster.Rename(NewOption);
                end;
            Database::"RBK Date Master":
                begin
                    DateMaster.Get(OldDate);
                    DateMaster.Rename(NewDate);
                end;
            Database::"RBK If Master":
                begin
                    IfMaster.Get(OldCode);
                    IfMaster.Rename(NewCode);
                end;
            Database::"RBK Where Master":
                begin
                    WhereMaster.Get(OldCode);
                    WhereMaster.Rename(NewCode);
                end;
            Database::"RBK Named Master":
                begin
                    NamedMaster.Get(OldCode);
                    NamedMaster.Rename(NewCode);
                end;
            Database::"RBK NonKey Master":
                begin
                    NonKeyMaster.Get(OldCode);
                    NonKeyMaster.Rename(NewCode);
                end;
            Database::"RBK NoVal Master":
                begin
                    NoValMaster.Get(OldCode);
                    NoValMaster.Rename(NewCode);
                end;
            Database::"RBK Ext Master":
                begin
                    ExtMaster.Get(OldCode);
                    ExtMaster.Rename(NewCode);
                end;
            Database::"RBK Self Master":
                begin
                    SelfMaster.Get(OldCode);
                    SelfMaster.Rename(NewCode);
                end;
            Database::"RBK Trg Master":
                begin
                    TrgMaster.Get(OldCode);
                    TrgMaster.Rename(NewCode);
                end;
            Database::"RBK Cap Master":
                begin
                    CapMaster.Get(OldCode);
                    CapMaster.Rename(NewCode);
                end;
            Database::"RBK Plain Master":
                begin
                    PlainMaster.Get(OldCode);
                    PlainMaster.Rename(NewCode);
                end;
            Database::"RBK FFilter Master":
                begin
                    FFilterMaster.Get(OldCode);
                    FFilterMaster.Rename(NewCode);
                end;
            Database::"RBK FField Master":
                begin
                    FFieldMaster.Get(OldCode);
                    FFieldMaster.Rename(NewCode);
                end;
            Database::"RBK Bool Master":
                begin
                    BoolMaster.Get(OldCode, OldBool);
                    BoolMaster.Rename(NewCode, NewBool);
                end;
            Database::"RBK BoolKey Master":
                begin
                    BoolKeyMaster.Get(OldCode, OldBool);
                    BoolKeyMaster.Rename(NewCode, NewBool);
                end;
            Database::"RBK OptPair Master":
                begin
                    OptPairMaster.Get(OldOption, OldCode);
                    OptPairMaster.Rename(NewOption, NewCode);
                end;
            Database::"RBK PairA Master":
                begin
                    PairAMaster.Get(OldA, OldB);
                    PairAMaster.Rename(NewA, NewB);
                end;
            Database::"RBK Short Master":
                begin
                    ShortMaster.Get(OldCode);
                    ShortMaster.Rename(NewCode);
                end;
            Database::"RBK DbTrg Master":
                begin
                    DbTrgMaster.Get(OldCode);
                    DbTrgMaster.Rename(NewCode);
                end;
        end;
    end;

    procedure SetCode(NewTableId: Integer; FromCode: Code[20]; ToCode: Code[20])
    begin
        TableId := NewTableId;
        OldCode := FromCode;
        NewCode := ToCode;
    end;

    procedure SetInt(FromInt: Integer; ToInt: Integer)
    begin
        TableId := Database::"RBK Int Master";
        OldInt := FromInt;
        NewInt := ToInt;
    end;

    procedure SetMulti(FromA: Code[10]; FromB: Code[10]; ToA: Code[10]; ToB: Code[10])
    begin
        TableId := Database::"RBK Multi Master";
        OldA := FromA;
        OldB := FromB;
        NewA := ToA;
        NewB := ToB;
    end;

    procedure SetGuid(FromGuid: Guid; ToGuid: Guid)
    begin
        TableId := Database::"RBK Guid Master";
        OldGuid := FromGuid;
        NewGuid := ToGuid;
    end;

    procedure SetOption(FromOption: Integer; ToOption: Integer)
    begin
        TableId := Database::"RBK Option Master";
        OldOption := FromOption;
        NewOption := ToOption;
    end;

    // 0 = Get and Rename, 1 = Rename of a buffer whose row is not stored, 2 = the return value form, 3 = RecordRef.Rename (table "RBK Master" only).
    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    procedure ReturnText(): Text
    begin
        exit(ReturnInfo);
    end;

    procedure SetBool(NewTableId: Integer; No: Code[20]; FromBool: Boolean; ToBool: Boolean)
    begin
        TableId := NewTableId;
        OldCode := No;
        NewCode := No;
        OldBool := FromBool;
        NewBool := ToBool;
    end;

    procedure SetOptPair(No: Code[20]; FromKind: Integer; ToKind: Integer)
    begin
        TableId := Database::"RBK OptPair Master";
        OldCode := No;
        NewCode := No;
        OldOption := FromKind;
        NewOption := ToKind;
    end;

    procedure SetPairA(A: Code[10]; FromB: Code[10]; ToB: Code[10])
    begin
        TableId := Database::"RBK PairA Master";
        OldA := A;
        NewA := A;
        OldB := FromB;
        NewB := ToB;
    end;

    procedure SetDate(FromDate: Date; ToDate: Date)
    begin
        TableId := Database::"RBK Date Master";
        OldDate := FromDate;
        NewDate := ToDate;
    end;

    procedure SetTemporary(FromCode: Code[20]; ToCode: Code[20])
    begin
        UseTemporary := true;
        OldCode := FromCode;
        NewCode := ToCode;
        TempMaster.DeleteAll();
        TempMaster."Code" := FromCode;
        TempMaster.Insert();
    end;

    procedure TemporaryRows(): Text
    var
        Result: Text;
    begin
        TempMaster.Reset();
        if TempMaster.FindSet() then
            repeat
                Result += '[' + TempMaster."Code" + ']';
            until TempMaster.Next() = 0;
        exit(Result);
    end;

    procedure Rows(TableNo: Integer): Text
    var
        RecRef: RecordRef;
        FieldIndex: Integer;
        Result: Text;
        RowText: Text;
    begin
        RecRef.Open(TableNo);
        if RecRef.FindSet() then
            repeat
                RowText := '';
                for FieldIndex := 1 to RecRef.FieldCount() do
                    if RecRef.FieldIndex(FieldIndex).Number() < 2000000000 then
                        RowText += '[' + Format(RecRef.FieldIndex(FieldIndex).Value(), 0, 9) + ']';
                if Result <> '' then
                    Result += ' ';
                Result += RowText;
            until RecRef.Next() = 0;
        RecRef.Close();
        exit(Result);
    end;

    // The 1-based position and the character code of every character below 32, as pos:code joined by commas.
    procedure ControlCodes(Value: Text): Text
    var
        Index: Integer;
        Code: Integer;
        Result: Text;
    begin
        for Index := 1 to StrLen(Value) do begin
            Code := Value[Index];
            if Code < 32 then begin
                if Result <> '' then
                    Result += ',';
                Result += Format(Index) + ':' + Format(Code);
            end;
        end;
        exit(Result);
    end;

    procedure DeleteAllRows()
    var
        TableNo: Integer;
        RecRef: RecordRef;
    begin
        for TableNo := Database::"RBK Master" to Database::"RBK DbTrg Child" do begin
            RecRef.Open(TableNo);
            RecRef.DeleteAll();
            RecRef.Close();
        end;
    end;
}

codeunit 79100 "RBK Rename Blank Key"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Start(var Runner: Codeunit "RBK Rename Runner")
    begin
        Runner.DeleteAllRows();
        Commit();
    end;

    local procedure RunRename(var Runner: Codeunit "RBK Rename Runner")
    begin
        Commit();
        ClearLastError();
        if Runner.Run() then
            Observer.Observe('rename', 'no error')
        else begin
            Observer.Observe('rename', 'error');
            Observer.Observe('control chars', Runner.ControlCodes(GetLastErrorText()));
            Observer.ObserveError('error');
        end;
    end;

    local procedure AddMaster(NewCode: Code[20])
    var
        Master: Record "RBK Master";
    begin
        Master."Code" := NewCode;
        Master.Insert();
    end;

    local procedure AddChild(EntryNo: Integer; MasterCode: Code[20])
    var
        Child: Record "RBK Child";
    begin
        Child."Entry No." := EntryNo;
        Child."Master Code" := MasterCode;
        Child.Insert();
    end;

    local procedure CodeKey(FromCode: Code[20]; ToCode: Code[20]; RelatedRows: Integer)
    var
        Runner: Codeunit "RBK Rename Runner";
        Index: Integer;
    begin
        Start(Runner);
        AddMaster(FromCode);
        for Index := 1 to RelatedRows do
            AddChild(Index + 1, FromCode);
        Runner.SetCode(Database::"RBK Master", FromCode, ToCode);
        RunRename(Runner);
        Observer.Observe('master rows', Runner.Rows(Database::"RBK Master"));
        Observer.Observe('child rows', Runner.Rows(Database::"RBK Child"));
    end;

    [Test]
    procedure CodeKey_FromBlank_NoRelatedRow()
    begin
        CodeKey('', 'X', 0);
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK Master table cannot be renamed from "" to "X".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[]');
        Observer.Expect('child rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure CodeKey_FromBlank_OneRelatedRow()
    begin
        // The reporter's shape (al-runner issue 7937): one child row (Entry No. 2) holds the blank key.
        CodeKey('', 'X', 1);
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK Master table cannot be renamed from "" to "X".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[]');
        Observer.Expect('child rows', '[2][]');
        Observer.Verify();
    end;

    [Test]
    procedure CodeKey_FromBlank_TwoRelatedRows()
    begin
        CodeKey('', 'X', 2);
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK Master table cannot be renamed from "" to "X".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[]');
        Observer.Expect('child rows', '[2][] [3][]');
        Observer.Verify();
    end;

    [Test]
    procedure CodeKey_ToBlank_NoRelatedRow()
    begin
        CodeKey('X', '', 0);
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK Master table cannot be renamed from "X" to "".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[X]');
        Observer.Expect('child rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure CodeKey_ToBlank_OneRelatedRow()
    begin
        CodeKey('X', '', 1);
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK Master table cannot be renamed from "X" to "".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[X]');
        Observer.Expect('child rows', '[2][X]');
        Observer.Verify();
    end;

    [Test]
    procedure CodeKey_ToBlank_TwoRelatedRows()
    begin
        CodeKey('X', '', 2);
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK Master table cannot be renamed from "X" to "".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[X]');
        Observer.Expect('child rows', '[2][X] [3][X]');
        Observer.Verify();
    end;

    [Test]
    procedure CodeKey_NonBlankToNonBlank_OneRelatedRow()
    begin
        CodeKey('X', 'Y', 1);
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[Y]');
        Observer.Expect('child rows', '[2][Y]');
        Observer.Verify();
    end;

    local procedure IntKey(FromInt: Integer; ToInt: Integer)
    var
        Runner: Codeunit "RBK Rename Runner";
        Master: Record "RBK Int Master";
        Child: Record "RBK Int Child";
    begin
        Start(Runner);
        Master."No." := FromInt;
        Master.Insert();
        Child."Entry No." := 1;
        Child."Master No." := FromInt;
        Child.Insert();
        Runner.SetInt(FromInt, ToInt);
        RunRename(Runner);
        Observer.Observe('master rows', Runner.Rows(Database::"RBK Int Master"));
        Observer.Observe('child rows', Runner.Rows(Database::"RBK Int Child"));
    end;

    [Test]
    procedure IntegerKey_FromZero()
    begin
        IntKey(0, 5);
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The No. field on the RBK Int Master table cannot be renamed from "0" to "5".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[0]');
        Observer.Expect('child rows', '[1][0]');
        Observer.Verify();
    end;

    [Test]
    procedure IntegerKey_ToZero()
    begin
        IntKey(5, 0);
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The No. field on the RBK Int Master table cannot be renamed from "5" to "0".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[5]');
        Observer.Expect('child rows', '[1][5]');
        Observer.Verify();
    end;

    local procedure MultiKey(FromA: Code[10]; FromB: Code[10]; ToA: Code[10]; ToB: Code[10])
    var
        Runner: Codeunit "RBK Rename Runner";
        Master: Record "RBK Multi Master";
        Child: Record "RBK Multi Child";
    begin
        Start(Runner);
        Master.A := FromA;
        Master.B := FromB;
        Master.Insert();
        Child."Entry No." := 1;
        Child.RefA := FromA;
        Child.RefB := FromB;
        Child.Insert();
        Runner.SetMulti(FromA, FromB, ToA, ToB);
        RunRename(Runner);
        Observer.Observe('master rows', Runner.Rows(Database::"RBK Multi Master"));
        Observer.Observe('child rows', Runner.Rows(Database::"RBK Multi Child"));
    end;

    [Test]
    procedure MultiKey_FirstFieldBlankChanges()
    begin
        // A is only in the where filter of the relation; B is the related field.
        MultiKey('', 'B1', 'X', 'B1');
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[X][B1]');
        Observer.Expect('child rows', '[1][][B1]');
        Observer.Verify();
    end;

    [Test]
    procedure MultiKey_FirstFieldBlankKept()
    begin
        MultiKey('', 'B1', '', 'B2');
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[][B2]');
        Observer.Expect('child rows', '[1][][B2]');
        Observer.Verify();
    end;

    [Test]
    procedure MultiKey_RelatedFieldBlankChanges()
    begin
        MultiKey('A1', '', 'A1', 'X');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The B field on the RBK Multi Master table cannot be renamed from "" to "X".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[A1][]');
        Observer.Expect('child rows', '[1][A1][]');
        Observer.Verify();
    end;

    [Test]
    procedure MultiKey_RelatedFieldBlankKept()
    begin
        MultiKey('A1', '', 'A2', '');
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[A2][]');
        Observer.Expect('child rows', '[1][A1][]');
        Observer.Verify();
    end;

    local procedure GuidKey(FromGuid: Guid; ToGuid: Guid)
    var
        Runner: Codeunit "RBK Rename Runner";
        Master: Record "RBK Guid Master";
        Child: Record "RBK Guid Child";
    begin
        Start(Runner);
        Master.Id := FromGuid;
        Master.Insert();
        Child."Entry No." := 1;
        Child."Master Id" := FromGuid;
        Child.Insert();
        Runner.SetGuid(FromGuid, ToGuid);
        RunRename(Runner);
        Observer.Observe('master rows', Runner.Rows(Database::"RBK Guid Master"));
        Observer.Observe('child rows', Runner.Rows(Database::"RBK Guid Child"));
    end;

    [Test]
    procedure GuidKey_FromBlank()
    var
        Blank: Guid;
    begin
        GuidKey(Blank, '{11111111-2222-3333-4444-555555555555}');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Id field on the RBK Guid Master table cannot be renamed from "{00000000-0000-0000-0000-000000000000}" to "{11111111-2222-3333-4444-555555555555}".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[{00000000-0000-0000-0000-000000000000}]');
        Observer.Expect('child rows', '[1][{00000000-0000-0000-0000-000000000000}]');
        Observer.Verify();
    end;

    [Test]
    procedure GuidKey_ToBlank()
    var
        Blank: Guid;
    begin
        GuidKey('{11111111-2222-3333-4444-555555555555}', Blank);
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Id field on the RBK Guid Master table cannot be renamed from "{11111111-2222-3333-4444-555555555555}" to "{00000000-0000-0000-0000-000000000000}".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[{11111111-2222-3333-4444-555555555555}]');
        Observer.Expect('child rows', '[1][{11111111-2222-3333-4444-555555555555}]');
        Observer.Verify();
    end;

    local procedure OptionKey(FromOption: Integer; ToOption: Integer)
    var
        Runner: Codeunit "RBK Rename Runner";
        Master: Record "RBK Option Master";
        Child: Record "RBK Option Child";
    begin
        Start(Runner);
        Master.Kind := FromOption;
        Master.Insert();
        Child."Entry No." := 1;
        Child."Master Kind" := FromOption;
        Child.Insert();
        Runner.SetOption(FromOption, ToOption);
        RunRename(Runner);
        Observer.Observe('master rows', Runner.Rows(Database::"RBK Option Master"));
        Observer.Observe('child rows', Runner.Rows(Database::"RBK Option Child"));
    end;

    [Test]
    procedure OptionKey_FromBlank()
    begin
        OptionKey(0, 1);
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Kind field on the RBK Option Master table cannot be renamed from " " to "Alpha".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[0]');
        Observer.Expect('child rows', '[1][0]');
        Observer.Verify();
    end;

    [Test]
    procedure OptionKey_ToBlank()
    begin
        OptionKey(1, 0);
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Kind field on the RBK Option Master table cannot be renamed from "Alpha" to " ".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[1]');
        Observer.Expect('child rows', '[1][1]');
        Observer.Verify();
    end;

    local procedure DateKey(FromDate: Date; ToDate: Date)
    var
        Runner: Codeunit "RBK Rename Runner";
        Master: Record "RBK Date Master";
        Child: Record "RBK Date Child";
    begin
        Start(Runner);
        Master.Day := FromDate;
        Master.Insert();
        Child."Entry No." := 1;
        Child."Master Day" := FromDate;
        Child.Insert();
        Runner.SetDate(FromDate, ToDate);
        RunRename(Runner);
        Observer.Observe('master rows', Runner.Rows(Database::"RBK Date Master"));
        Observer.Observe('child rows', Runner.Rows(Database::"RBK Date Child"));
    end;

    [Test]
    procedure DateKey_FromBlank()
    begin
        DateKey(0D, DMY2Date(1, 2, 2024));
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Day field on the RBK Date Master table cannot be renamed from "" to "02/01/24".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[]');
        Observer.Expect('child rows', '[1][]');
        Observer.Verify();
    end;

    [Test]
    procedure DateKey_ToBlank()
    begin
        DateKey(DMY2Date(1, 2, 2024), 0D);
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Day field on the RBK Date Master table cannot be renamed from "02/01/24" to "".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[2024-02-01]');
        Observer.Expect('child rows', '[1][2024-02-01]');
        Observer.Verify();
    end;

    local procedure TemporaryKey(FromCode: Code[20]; ToCode: Code[20])
    var
        Runner: Codeunit "RBK Rename Runner";
    begin
        Start(Runner);
        AddChild(1, FromCode);
        Runner.SetTemporary(FromCode, ToCode);
        RunRename(Runner);
        Observer.Observe('temporary rows', Runner.TemporaryRows());
        Observer.Observe('master rows', Runner.Rows(Database::"RBK Master"));
        Observer.Observe('child rows', Runner.Rows(Database::"RBK Child"));
    end;

    [Test]
    procedure TemporaryRecord_FromBlank()
    begin
        TemporaryKey('', 'X');
        Observer.Expect('rename', 'no error');
        Observer.Expect('temporary rows', '[X]');
        Observer.Expect('master rows', '');
        Observer.Expect('child rows', '[1][]');
        Observer.Verify();
    end;

    [Test]
    procedure TemporaryRecord_ToBlank()
    begin
        TemporaryKey('X', '');
        Observer.Expect('rename', 'no error');
        Observer.Expect('temporary rows', '[]');
        Observer.Expect('master rows', '');
        Observer.Expect('child rows', '[1][X]');
        Observer.Verify();
    end;

    local procedure PlainKey(FromCode: Code[20]; ToCode: Code[20])
    var
        Runner: Codeunit "RBK Rename Runner";
        Master: Record "RBK Plain Master";
    begin
        Start(Runner);
        Master."Code" := FromCode;
        Master.Insert();
        Runner.SetCode(Database::"RBK Plain Master", FromCode, ToCode);
        RunRename(Runner);
        Observer.Observe('master rows', Runner.Rows(Database::"RBK Plain Master"));
    end;

    [Test]
    procedure NoRelation_FromBlank()
    begin
        PlainKey('', 'X');
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[X]');
        Observer.Verify();
    end;

    [Test]
    procedure NoRelation_ToBlank()
    begin
        PlainKey('X', '');
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[]');
        Observer.Verify();
    end;
}

codeunit 79104 "RBK Rename Blank Relations"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Start(var Runner: Codeunit "RBK Rename Runner")
    var
        Log: Codeunit "RBK Rename Log";
    begin
        Runner.DeleteAllRows();
        Log.Reset();
        Commit();
    end;

    local procedure RunRename(var Runner: Codeunit "RBK Rename Runner"; MasterTable: Integer; ChildTable: Integer)
    begin
        Commit();
        ClearLastError();
        if Runner.Run() then
            Observer.Observe('rename', 'no error')
        else begin
            Observer.Observe('rename', 'error');
            Observer.Observe('control chars', Runner.ControlCodes(GetLastErrorText()));
            Observer.ObserveError('error');
        end;
        Observer.Observe('master rows', Runner.Rows(MasterTable));
        if ChildTable <> 0 then
            Observer.Observe('child rows', Runner.Rows(ChildTable));
    end;

    local procedure IfRelation(FromCode: Code[20]; ToCode: Code[20]; ChildKind: Option)
    var
        Runner: Codeunit "RBK Rename Runner";
        Master: Record "RBK If Master";
        Child: Record "RBK If Child";
    begin
        Start(Runner);
        Master."Code" := FromCode;
        Master.Insert();
        Child."Entry No." := 1;
        Child.Kind := ChildKind;
        Child.Ref := FromCode;
        Child.Insert();
        Runner.SetCode(Database::"RBK If Master", FromCode, ToCode);
        RunRename(Runner, Database::"RBK If Master", Database::"RBK If Child");
    end;

    [Test]
    procedure IfRelation_FromBlank_ConditionMet()
    var
        Child: Record "RBK If Child";
    begin
        IfRelation('', 'X', Child.Kind::Linked);
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK If Master table cannot be renamed from "" to "X".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[]');
        Observer.Expect('child rows', '[1][1][]');
        Observer.Verify();
    end;

    [Test]
    procedure IfRelation_FromBlank_ConditionNotMet()
    var
        Child: Record "RBK If Child";
    begin
        IfRelation('', 'X', Child.Kind::" ");
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK If Master table cannot be renamed from "" to "X".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[]');
        Observer.Expect('child rows', '[1][0][]');
        Observer.Verify();
    end;

    [Test]
    procedure IfRelation_ToBlank_ConditionMet()
    var
        Child: Record "RBK If Child";
    begin
        IfRelation('X', '', Child.Kind::Linked);
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK If Master table cannot be renamed from "X" to "".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[X]');
        Observer.Expect('child rows', '[1][1][X]');
        Observer.Verify();
    end;

    local procedure WhereRelation(FromCode: Code[20]; ToCode: Code[20])
    var
        Runner: Codeunit "RBK Rename Runner";
        Master: Record "RBK Where Master";
        Child: Record "RBK Where Child";
    begin
        Start(Runner);
        Master."Code" := FromCode;
        Master.Name := 'N';
        Master.Insert();
        Child."Entry No." := 1;
        Child.Ref := FromCode;
        Child.Insert();
        Runner.SetCode(Database::"RBK Where Master", FromCode, ToCode);
        RunRename(Runner, Database::"RBK Where Master", Database::"RBK Where Child");
    end;

    [Test]
    procedure WhereRelation_FromBlank()
    begin
        WhereRelation('', 'X');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK Where Master table cannot be renamed from "" to "X".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[][N]');
        Observer.Expect('child rows', '[1][]');
        Observer.Verify();
    end;

    [Test]
    procedure WhereRelation_ToBlank()
    begin
        WhereRelation('X', '');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK Where Master table cannot be renamed from "X" to "".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[X][N]');
        Observer.Expect('child rows', '[1][X]');
        Observer.Verify();
    end;

    local procedure NamedRelation(FromCode: Code[20]; ToCode: Code[20])
    var
        Runner: Codeunit "RBK Rename Runner";
        Master: Record "RBK Named Master";
        Child: Record "RBK Named Child";
    begin
        Start(Runner);
        Master."Code" := FromCode;
        Master.Insert();
        Child."Entry No." := 1;
        Child.Ref := FromCode;
        Child.Insert();
        Runner.SetCode(Database::"RBK Named Master", FromCode, ToCode);
        RunRename(Runner, Database::"RBK Named Master", Database::"RBK Named Child");
    end;

    [Test]
    procedure NamedKeyRelation_FromBlank()
    begin
        NamedRelation('', 'X');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK Named Master table cannot be renamed from "" to "X".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[]');
        Observer.Expect('child rows', '[1][]');
        Observer.Verify();
    end;

    [Test]
    procedure NamedKeyRelation_ToBlank()
    begin
        NamedRelation('X', '');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK Named Master table cannot be renamed from "X" to "".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[X]');
        Observer.Expect('child rows', '[1][X]');
        Observer.Verify();
    end;

    local procedure NonKeyRelation(FromCode: Code[20]; ToCode: Code[20])
    var
        Runner: Codeunit "RBK Rename Runner";
        Master: Record "RBK NonKey Master";
        Child: Record "RBK NonKey Child";
    begin
        Start(Runner);
        Master."Code" := FromCode;
        Master.Name := 'NAME';
        Master.Insert();
        Child."Entry No." := 1;
        Child.Ref := 'NAME';
        Child.Insert();
        Runner.SetCode(Database::"RBK NonKey Master", FromCode, ToCode);
        RunRename(Runner, Database::"RBK NonKey Master", Database::"RBK NonKey Child");
    end;

    [Test]
    procedure NonKeyRelation_FromBlank()
    begin
        NonKeyRelation('', 'X');
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[X][NAME]');
        Observer.Expect('child rows', '[1][NAME]');
        Observer.Verify();
    end;

    [Test]
    procedure NonKeyRelation_ToBlank()
    begin
        NonKeyRelation('X', '');
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[][NAME]');
        Observer.Expect('child rows', '[1][NAME]');
        Observer.Verify();
    end;

    local procedure NoValidateRelation(FromCode: Code[20]; ToCode: Code[20])
    var
        Runner: Codeunit "RBK Rename Runner";
        Master: Record "RBK NoVal Master";
        Child: Record "RBK NoVal Child";
    begin
        Start(Runner);
        Master."Code" := FromCode;
        Master.Insert();
        Child."Entry No." := 1;
        Child.Ref := FromCode;
        Child.Insert();
        Runner.SetCode(Database::"RBK NoVal Master", FromCode, ToCode);
        RunRename(Runner, Database::"RBK NoVal Master", Database::"RBK NoVal Child");
    end;

    [Test]
    procedure NoValidateRelation_FromBlank()
    begin
        NoValidateRelation('', 'X');
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[X]');
        Observer.Expect('child rows', '[1][]');
        Observer.Verify();
    end;

    [Test]
    procedure NoValidateRelation_ToBlank()
    begin
        NoValidateRelation('X', '');
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[]');
        Observer.Expect('child rows', '[1][X]');
        Observer.Verify();
    end;

    local procedure ExtRelation(FromCode: Code[20]; ToCode: Code[20])
    var
        Runner: Codeunit "RBK Rename Runner";
        Master: Record "RBK Ext Master";
        Child: Record "RBK Ext Child";
    begin
        Start(Runner);
        Master."Code" := FromCode;
        Master.Insert();
        Child."Entry No." := 1;
        Child."RBK Ext Ref" := FromCode;
        Child.Insert();
        Runner.SetCode(Database::"RBK Ext Master", FromCode, ToCode);
        RunRename(Runner, Database::"RBK Ext Master", Database::"RBK Ext Child");
    end;

    [Test]
    procedure TableExtensionRelation_FromBlank()
    begin
        ExtRelation('', 'X');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK Ext Master table cannot be renamed from "" to "X".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[]');
        Observer.Expect('child rows', '[1][]');
        Observer.Verify();
    end;

    [Test]
    procedure TableExtensionRelation_ToBlank()
    begin
        ExtRelation('X', '');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK Ext Master table cannot be renamed from "X" to "".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[X]');
        Observer.Expect('child rows', '[1][X]');
        Observer.Verify();
    end;

    local procedure SelfRelation(FromCode: Code[20]; ToCode: Code[20])
    var
        Runner: Codeunit "RBK Rename Runner";
        Master: Record "RBK Self Master";
    begin
        Start(Runner);
        Master."Code" := FromCode;
        Master."Parent Code" := FromCode;
        Master.Insert();
        Master."Code" := 'OTHER';
        Master."Parent Code" := FromCode;
        Master.Insert();
        Runner.SetCode(Database::"RBK Self Master", FromCode, ToCode);
        RunRename(Runner, Database::"RBK Self Master", 0);
    end;

    [Test]
    procedure SameTableRelation_FromBlank()
    begin
        SelfRelation('', 'X');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK Self Master table cannot be renamed from "" to "X".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[][] [OTHER][]');
        Observer.Verify();
    end;

    [Test]
    procedure SameTableRelation_ToBlank()
    begin
        SelfRelation('X', '');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK Self Master table cannot be renamed from "X" to "".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[OTHER][X] [X][X]');
        Observer.Verify();
    end;

    local procedure TriggerRelation(FromCode: Code[20]; ToCode: Code[20])
    var
        Runner: Codeunit "RBK Rename Runner";
        Log: Codeunit "RBK Rename Log";
        Master: Record "RBK Trg Master";
        Child: Record "RBK Trg Child";
    begin
        Start(Runner);
        Master."Code" := FromCode;
        Master.Insert();
        Child."Entry No." := 1;
        Child.Ref := FromCode;
        Child.Insert();
        Runner.SetCode(Database::"RBK Trg Master", FromCode, ToCode);
        RunRename(Runner, Database::"RBK Trg Master", Database::"RBK Trg Child");
        Observer.Observe('log', Log.Get());
    end;

    [Test]
    procedure TriggerAndSubscribers_FromBlank()
    begin
        TriggerRelation('', 'X');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK Trg Master table cannot be renamed from "" to "X".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[]');
        Observer.Expect('child rows', '[1][]');
        Observer.Expect('log', 'OnBeforeRenameEvent xRec=[] Rec=[X] | OnRename xRec=[] Rec=[X]');
        Observer.Verify();
    end;

    [Test]
    procedure TriggerAndSubscribers_ToBlank()
    begin
        TriggerRelation('X', '');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK Trg Master table cannot be renamed from "X" to "".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[X]');
        Observer.Expect('child rows', '[1][X]');
        Observer.Expect('log', 'OnBeforeRenameEvent xRec=[X] Rec=[] | OnRename xRec=[X] Rec=[]');
        Observer.Verify();
    end;

    [Test]
    procedure TriggerAndSubscribers_NonBlank()
    begin
        TriggerRelation('X', 'Y');
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[Y]');
        Observer.Expect('child rows', '[1][Y]');
        Observer.Expect('log', 'OnBeforeRenameEvent xRec=[X] Rec=[Y] | OnRename xRec=[X] Rec=[Y] | OnAfterRenameEvent xRec=[X] Rec=[Y]');
        Observer.Verify();
    end;

    local procedure CaptionRelation(FromCode: Code[20]; ToCode: Code[20])
    var
        Runner: Codeunit "RBK Rename Runner";
        Master: Record "RBK Cap Master";
        Child: Record "RBK Cap Child";
    begin
        Start(Runner);
        Master."Code" := FromCode;
        Master.Insert();
        Child."Entry No." := 1;
        Child.Ref := FromCode;
        Child.Insert();
        Runner.SetCode(Database::"RBK Cap Master", FromCode, ToCode);
        RunRename(Runner, Database::"RBK Cap Master", Database::"RBK Cap Child");
    end;

    [Test]
    procedure Captions_FromBlank()
    begin
        CaptionRelation('', 'X');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Key Caption field on the RBK Captioned Master table cannot be renamed from "" to "X".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[]');
        Observer.Expect('child rows', '[1][]');
        Observer.Verify();
    end;

    [Test]
    procedure Captions_ToBlank()
    begin
        CaptionRelation('X', '');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Key Caption field on the RBK Captioned Master table cannot be renamed from "X" to "".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[X]');
        Observer.Expect('child rows', '[1][X]');
        Observer.Verify();
    end;

    local procedure DbTriggerRelation(FromCode: Code[20]; ToCode: Code[20])
    var
        Runner: Codeunit "RBK Rename Runner";
        Log: Codeunit "RBK Rename Log";
        Master: Record "RBK DbTrg Master";
        Child: Record "RBK DbTrg Child";
    begin
        Start(Runner);
        Master."Code" := FromCode;
        Master.Insert();
        Child."Entry No." := 1;
        Child.Ref := FromCode;
        Child.Insert();
        Runner.SetCode(Database::"RBK DbTrg Master", FromCode, ToCode);
        RunRename(Runner, Database::"RBK DbTrg Master", Database::"RBK DbTrg Child");
        Observer.Observe('log', Log.Get());
    end;

    [Test]
    procedure DatabaseRenameTrigger_FromBlank()
    begin
        DbTriggerRelation('', 'X');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK DbTrg Master table cannot be renamed from "" to "X".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[]');
        Observer.Expect('child rows', '[1][]');
        Observer.Expect('log', 'OnBeforeRenameEvent xRec=[] Rec=[X] | OnAfterOnDatabaseRename xRec=[] Rec=[X]');
        Observer.Verify();
    end;

    [Test]
    procedure DatabaseRenameTrigger_ToBlank()
    begin
        DbTriggerRelation('X', '');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK DbTrg Master table cannot be renamed from "X" to "".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[X]');
        Observer.Expect('child rows', '[1][X]');
        Observer.Expect('log', 'OnBeforeRenameEvent xRec=[X] Rec=[] | OnAfterOnDatabaseRename xRec=[X] Rec=[]');
        Observer.Verify();
    end;

    [Test]
    procedure DatabaseRenameTrigger_NonBlank()
    begin
        DbTriggerRelation('X', 'Y');
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[Y]');
        Observer.Expect('child rows', '[1][Y]');
        Observer.Expect('log', 'OnBeforeRenameEvent xRec=[X] Rec=[Y] | OnAfterOnDatabaseRename xRec=[X] Rec=[Y]');
        Observer.Verify();
    end;
}

codeunit 79105 "RBK Rename Blank Shapes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Start(var Runner: Codeunit "RBK Rename Runner")
    begin
        Runner.DeleteAllRows();
        Commit();
    end;

    local procedure RunRename(var Runner: Codeunit "RBK Rename Runner"; MasterTable: Integer; ChildTable: Integer)
    begin
        Commit();
        ClearLastError();
        if Runner.Run() then
            Observer.Observe('rename', 'no error')
        else begin
            Observer.Observe('rename', 'error');
            Observer.Observe('control chars', Runner.ControlCodes(GetLastErrorText()));
            Observer.ObserveError('error');
        end;
        Observer.Observe('master rows', Runner.Rows(MasterTable));
        if ChildTable <> 0 then
            Observer.Observe('child rows', Runner.Rows(ChildTable));
    end;

    local procedure AddMaster(NewCode: Code[20])
    var
        Master: Record "RBK Master";
    begin
        Master."Code" := NewCode;
        Master.Insert();
    end;

    local procedure AddChild(EntryNo: Integer; MasterCode: Code[20])
    var
        Child: Record "RBK Child";
    begin
        Child."Entry No." := EntryNo;
        Child."Master Code" := MasterCode;
        Child.Insert();
    end;

    // The row with the new key already exists.
    local procedure NewKeyExists(FromCode: Code[20]; ToCode: Code[20])
    var
        Runner: Codeunit "RBK Rename Runner";
    begin
        Start(Runner);
        AddMaster(FromCode);
        AddMaster(ToCode);
        AddChild(1, FromCode);
        Runner.SetCode(Database::"RBK Master", FromCode, ToCode);
        RunRename(Runner, Database::"RBK Master", Database::"RBK Child");
    end;

    [Test]
    procedure NewKeyExists_FromBlank()
    begin
        NewKeyExists('', 'X');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The record in table RBK Master already exists. Identification fields and values: Code=''X''');
        Observer.Expect('error|code', 'DB:RecordExists');
        Observer.Expect('master rows', '[] [X]');
        Observer.Expect('child rows', '[1][]');
        Observer.Verify();
    end;

    [Test]
    procedure NewKeyExists_ToBlank()
    begin
        NewKeyExists('X', '');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The record in table RBK Master already exists. Identification fields and values: Code=''''');
        Observer.Expect('error|code', 'DB:RecordExists');
        Observer.Expect('master rows', '[] [X]');
        Observer.Expect('child rows', '[1][X]');
        Observer.Verify();
    end;

    [Test]
    procedure NewKeyExists_NonBlank()
    begin
        NewKeyExists('X', 'Y');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The record in table RBK Master already exists. Identification fields and values: Code=''Y''');
        Observer.Expect('error|code', 'DB:RecordExists');
        Observer.Expect('master rows', '[X] [Y]');
        Observer.Expect('child rows', '[1][X]');
        Observer.Verify();
    end;

    // The buffer holds the old key, but no row with it is stored.
    local procedure OldRowNotStored(FromCode: Code[20]; ToCode: Code[20])
    var
        Runner: Codeunit "RBK Rename Runner";
    begin
        Start(Runner);
        AddChild(1, FromCode);
        Runner.SetCode(Database::"RBK Master", FromCode, ToCode);
        Runner.SetMode(1);
        RunRename(Runner, Database::"RBK Master", Database::"RBK Child");
    end;

    [Test]
    procedure OldRowNotStored_FromBlank()
    begin
        OldRowNotStored('', 'X');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The RBK Master does not exist. Identification fields and values: Code=''''');
        Observer.Expect('error|code', 'DB:RecordNotFound');
        Observer.Expect('master rows', '');
        Observer.Expect('child rows', '[1][]');
        Observer.Verify();
    end;

    [Test]
    procedure OldRowNotStored_ToBlank()
    begin
        OldRowNotStored('X', '');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The RBK Master does not exist. Identification fields and values: Code=''X''');
        Observer.Expect('error|code', 'DB:RecordNotFound');
        Observer.Expect('master rows', '');
        Observer.Expect('child rows', '[1][X]');
        Observer.Verify();
    end;

    [Test]
    procedure OldRowNotStored_NonBlank()
    begin
        OldRowNotStored('X', 'Y');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The RBK Master does not exist. Identification fields and values: Code=''X''');
        Observer.Expect('error|code', 'DB:RecordNotFound');
        Observer.Expect('master rows', '');
        Observer.Expect('child rows', '[1][X]');
        Observer.Verify();
    end;

    local procedure ReturnValueForm(FromCode: Code[20]; ToCode: Code[20])
    var
        Runner: Codeunit "RBK Rename Runner";
    begin
        Start(Runner);
        AddMaster(FromCode);
        AddChild(1, FromCode);
        Runner.SetCode(Database::"RBK Master", FromCode, ToCode);
        Runner.SetMode(2);
        RunRename(Runner, Database::"RBK Master", Database::"RBK Child");
        Observer.Observe('return value form', Runner.ReturnText());
    end;

    [Test]
    procedure ReturnValueForm_FromBlank()
    begin
        ReturnValueForm('', 'X');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK Master table cannot be renamed from "" to "X".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[]');
        Observer.Expect('child rows', '[1][]');
        Observer.Expect('return value form', '');
        Observer.Verify();
    end;

    [Test]
    procedure ReturnValueForm_ToBlank()
    begin
        ReturnValueForm('X', '');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK Master table cannot be renamed from "X" to "".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[X]');
        Observer.Expect('child rows', '[1][X]');
        Observer.Expect('return value form', '');
        Observer.Verify();
    end;

    local procedure RecordRefForm(FromCode: Code[20]; ToCode: Code[20])
    var
        Runner: Codeunit "RBK Rename Runner";
    begin
        Start(Runner);
        AddMaster(FromCode);
        AddChild(1, FromCode);
        Runner.SetCode(Database::"RBK Master", FromCode, ToCode);
        Runner.SetMode(3);
        RunRename(Runner, Database::"RBK Master", Database::"RBK Child");
    end;

    [Test]
    procedure RecordRefRename_FromBlank()
    begin
        RecordRefForm('', 'X');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK Master table cannot be renamed from "" to "X".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[]');
        Observer.Expect('child rows', '[1][]');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRefRename_ToBlank()
    begin
        RecordRefForm('X', '');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK Master table cannot be renamed from "X" to "".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[X]');
        Observer.Expect('child rows', '[1][X]');
        Observer.Verify();
    end;

    // The child table holds other rows beside (or instead of) the one with the old key.
    [Test]
    procedure ChildOtherRows_FromBlank()
    var
        Runner: Codeunit "RBK Rename Runner";
    begin
        Start(Runner);
        AddMaster('');
        AddChild(1, '');
        AddChild(2, 'OTHER');
        Runner.SetCode(Database::"RBK Master", '', 'X');
        RunRename(Runner, Database::"RBK Master", Database::"RBK Child");
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK Master table cannot be renamed from "" to "X".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[]');
        Observer.Expect('child rows', '[1][] [2][OTHER]');
        Observer.Verify();
    end;

    [Test]
    procedure ChildOtherRows_ToBlank()
    var
        Runner: Codeunit "RBK Rename Runner";
    begin
        Start(Runner);
        AddMaster('X');
        AddChild(1, 'X');
        AddChild(2, 'OTHER');
        Runner.SetCode(Database::"RBK Master", 'X', '');
        RunRename(Runner, Database::"RBK Master", Database::"RBK Child");
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK Master table cannot be renamed from "X" to "".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[X]');
        Observer.Expect('child rows', '[1][X] [2][OTHER]');
        Observer.Verify();
    end;

    [Test]
    procedure ChildOnlyOtherValues_FromBlank()
    var
        Runner: Codeunit "RBK Rename Runner";
    begin
        Start(Runner);
        AddMaster('');
        AddChild(1, 'OTHER');
        Runner.SetCode(Database::"RBK Master", '', 'X');
        RunRename(Runner, Database::"RBK Master", Database::"RBK Child");
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK Master table cannot be renamed from "" to "X".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[]');
        Observer.Expect('child rows', '[1][OTHER]');
        Observer.Verify();
    end;

    local procedure FlowFilterRelation(FromCode: Code[20]; ToCode: Code[20])
    var
        Runner: Codeunit "RBK Rename Runner";
        Master: Record "RBK FFilter Master";
        Child: Record "RBK FFilter Child";
    begin
        Start(Runner);
        Master."Code" := FromCode;
        Master.Insert();
        Child."Entry No." := 1;
        Child.Insert();
        Runner.SetCode(Database::"RBK FFilter Master", FromCode, ToCode);
        RunRename(Runner, Database::"RBK FFilter Master", 0);
    end;

    [Test]
    procedure FlowFilterRelation_FromBlank()
    begin
        FlowFilterRelation('', 'X');
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[X]');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFilterRelation_ToBlank()
    begin
        FlowFilterRelation('X', '');
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[]');
        Observer.Verify();
    end;

    local procedure FlowFieldRelation(FromCode: Code[20]; ToCode: Code[20])
    var
        Runner: Codeunit "RBK Rename Runner";
        Master: Record "RBK FField Master";
        Child: Record "RBK FField Child";
    begin
        Start(Runner);
        Master."Code" := FromCode;
        Master.Insert();
        Child."Entry No." := 1;
        Child.Src := FromCode;
        Child.Insert();
        Runner.SetCode(Database::"RBK FField Master", FromCode, ToCode);
        RunRename(Runner, Database::"RBK FField Master", Database::"RBK FField Child");
    end;

    [Test]
    procedure FlowFieldRelation_FromBlank()
    begin
        FlowFieldRelation('', 'X');
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[X]');
        Observer.Expect('child rows', '[1][][]');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldRelation_ToBlank()
    begin
        FlowFieldRelation('X', '');
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[]');
        Observer.Expect('child rows', '[1][X][]');
        Observer.Verify();
    end;

    // Sales Invoice Entity Aggregate shape: Posted changes false -> true, the only relation targets the non-key field Id.
    local procedure BoolKeyNonKeyRelation(FromBool: Boolean; ToBool: Boolean)
    var
        Runner: Codeunit "RBK Rename Runner";
        Master: Record "RBK Bool Master";
        Child: Record "RBK Bool Child";
    begin
        Start(Runner);
        Master."No." := 'DOC1';
        Master.Posted := FromBool;
        Master.Id := 'ID1';
        Master.Insert();
        Child."Entry No." := 1;
        Child.RefId := 'ID1';
        Child.Insert();
        Runner.SetBool(Database::"RBK Bool Master", 'DOC1', FromBool, ToBool);
        RunRename(Runner, Database::"RBK Bool Master", Database::"RBK Bool Child");
    end;

    [Test]
    procedure BooleanKey_NonKeyRelation_FalseToTrue()
    begin
        BoolKeyNonKeyRelation(false, true);
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[DOC1][true][ID1]');
        Observer.Expect('child rows', '[1][ID1]');
        Observer.Verify();
    end;

    [Test]
    procedure BooleanKey_NonKeyRelation_TrueToFalse()
    begin
        BoolKeyNonKeyRelation(true, false);
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[DOC1][false][ID1]');
        Observer.Expect('child rows', '[1][ID1]');
        Observer.Verify();
    end;

    // The relation targets key field No. while the Boolean key field Posted changes.
    local procedure BoolKeyKeyRelation(FromBool: Boolean; ToBool: Boolean)
    var
        Runner: Codeunit "RBK Rename Runner";
        Master: Record "RBK BoolKey Master";
        Child: Record "RBK BoolKey Child";
    begin
        Start(Runner);
        Master."No." := 'DOC1';
        Master.Posted := FromBool;
        Master.Insert();
        Child."Entry No." := 1;
        Child.RefNo := 'DOC1';
        Child.Insert();
        Runner.SetBool(Database::"RBK BoolKey Master", 'DOC1', FromBool, ToBool);
        RunRename(Runner, Database::"RBK BoolKey Master", Database::"RBK BoolKey Child");
    end;

    [Test]
    procedure BooleanKey_KeyFieldRelation_FalseToTrue()
    begin
        BoolKeyKeyRelation(false, true);
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[DOC1][true]');
        Observer.Expect('child rows', '[1][DOC1]');
        Observer.Verify();
    end;

    [Test]
    procedure BooleanKey_KeyFieldRelation_TrueToFalse()
    begin
        BoolKeyKeyRelation(true, false);
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[DOC1][false]');
        Observer.Expect('child rows', '[1][DOC1]');
        Observer.Verify();
    end;

    // Sales Header shape: key (Kind, No.), the relation targets No. with where(Kind = field(Kind)); Kind changes 0 <-> 1.
    local procedure OptionPairKey(FromKind: Integer; ToKind: Integer)
    var
        Runner: Codeunit "RBK Rename Runner";
        Master: Record "RBK OptPair Master";
        Child: Record "RBK OptPair Child";
    begin
        Start(Runner);
        Master.Kind := FromKind;
        Master."No." := 'DOC1';
        Master.Insert();
        Child."Entry No." := 1;
        Child.Kind := FromKind;
        Child."Doc No." := 'DOC1';
        Child.Insert();
        Runner.SetOptPair('DOC1', FromKind, ToKind);
        RunRename(Runner, Database::"RBK OptPair Master", Database::"RBK OptPair Child");
    end;

    [Test]
    procedure OptionPairKey_ZeroToOne()
    begin
        OptionPairKey(0, 1);
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[1][DOC1]');
        Observer.Expect('child rows', '[1][0][DOC1]');
        Observer.Verify();
    end;

    [Test]
    procedure OptionPairKey_OneToZero()
    begin
        OptionPairKey(1, 0);
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[0][DOC1]');
        Observer.Expect('child rows', '[1][1][DOC1]');
        Observer.Verify();
    end;

    // The relation targets key field A while key field B changes to or from blank.
    local procedure PairAKey(FromB: Code[10]; ToB: Code[10])
    var
        Runner: Codeunit "RBK Rename Runner";
        Master: Record "RBK PairA Master";
        Child: Record "RBK PairA Child";
    begin
        Start(Runner);
        Master.A := 'A1';
        Master.B := FromB;
        Master.Insert();
        Child."Entry No." := 1;
        Child.RefA := 'A1';
        Child.Insert();
        Runner.SetPairA('A1', FromB, ToB);
        RunRename(Runner, Database::"RBK PairA Master", Database::"RBK PairA Child");
    end;

    [Test]
    procedure RelationToFieldA_FieldBFromBlank()
    begin
        PairAKey('', 'X');
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[A1][X]');
        Observer.Expect('child rows', '[1][A1]');
        Observer.Verify();
    end;

    [Test]
    procedure RelationToFieldA_FieldBToBlank()
    begin
        PairAKey('X', '');
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[A1][]');
        Observer.Expect('child rows', '[1][A1]');
        Observer.Verify();
    end;

    // A Code[10] child field against a Code[20] key.
    local procedure ShortChildField(FromCode: Code[20]; ToCode: Code[20])
    var
        Runner: Codeunit "RBK Rename Runner";
        Master: Record "RBK Short Master";
        Child: Record "RBK Short Child";
    begin
        Start(Runner);
        Master."Code" := FromCode;
        Master.Insert();
        Child."Entry No." := 1;
        Child.Ref := CopyStr(FromCode, 1, 10);
        Child.Insert();
        Runner.SetCode(Database::"RBK Short Master", FromCode, ToCode);
        RunRename(Runner, Database::"RBK Short Master", Database::"RBK Short Child");
    end;

    [Test]
    procedure ShortChildField_FromBlank()
    begin
        ShortChildField('', 'X');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK Short Master table cannot be renamed from "" to "X".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[]');
        Observer.Expect('child rows', '[1][]');
        Observer.Verify();
    end;

    [Test]
    procedure ShortChildField_ToBlank()
    begin
        ShortChildField('X', '');
        Observer.Expect('rename', 'error');
        Observer.Expect('control chars', '');
        Observer.Expect('error|text', 'The Code field on the RBK Short Master table cannot be renamed from "X" to "".\\When a field has a relation defined, the field cannot be renamed to and from zero or an empty value.');
        Observer.Expect('error|code', 'DB:Ok');
        Observer.Expect('master rows', '[X]');
        Observer.Expect('child rows', '[1][X]');
        Observer.Verify();
    end;
}
