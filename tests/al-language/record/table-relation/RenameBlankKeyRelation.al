// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-rename-method
// Scope: in-scope (Cloud)
// Fixtures used: Probe Observer (codeunit 69160); tables 79100-79129, table extension 79100, codeunits 79100-79104 (all self-contained)
// Probe (al-runner issue 7937): Record.Rename of a row whose primary key changes to or from its blank or zero value, when another
//   table relates to the table. Each test commits its setup, runs the Rename inside Codeunit.Run (so an error rolls back only the
//   Rename) and records: whether Rename raised, GetLastErrorText (with the positions and codes of its control characters),
//   GetLastErrorCode, and the rows of the tables afterwards.
// Cells: Code key from and to blank with 0, 1 and 2 related rows; Integer key from and to 0; a two-field key where the blank field
//   changes or keeps its value; Guid, Option and Date keys; a relation with an if condition, with a where filter, to the named key
//   field, to a non-key field; ValidateTableRelation = false; a relation from a table extension field and from a field of the
//   same table; a temporary record; an OnRename trigger and OnBefore/OnAfterRenameEvent subscribers (log of what ran); a
//   table and field Caption; a table nothing relates to (control); a non-blank to non-blank rename (control).
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
    begin
        if UseTemporary then begin
            TempMaster.Get(OldCode);
            TempMaster.Rename(NewCode);
            exit;
        end;
        case TableId of
            Database::"RBK Master":
                begin
                    Master.Get(OldCode);
                    Master.Rename(NewCode);
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
        for TableNo := Database::"RBK Master" to Database::"RBK Plain Master" do begin
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
        Observer.Finish();
    end;

    [Test]
    procedure CodeKey_FromBlank_NoRelatedRow()
    begin
        CodeKey('', 'X', 0);
    end;

    [Test]
    procedure CodeKey_FromBlank_OneRelatedRow()
    begin
        // The reporter's shape (al-runner issue 7937): one child row (Entry No. 2) holds the blank key.
        CodeKey('', 'X', 1);
    end;

    [Test]
    procedure CodeKey_FromBlank_TwoRelatedRows()
    begin
        CodeKey('', 'X', 2);
    end;

    [Test]
    procedure CodeKey_ToBlank_NoRelatedRow()
    begin
        CodeKey('X', '', 0);
    end;

    [Test]
    procedure CodeKey_ToBlank_OneRelatedRow()
    begin
        CodeKey('X', '', 1);
    end;

    [Test]
    procedure CodeKey_ToBlank_TwoRelatedRows()
    begin
        CodeKey('X', '', 2);
    end;

    [Test]
    procedure CodeKey_NonBlankToNonBlank_OneRelatedRow()
    begin
        CodeKey('X', 'Y', 1);
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
        Observer.Finish();
    end;

    [Test]
    procedure IntegerKey_FromZero()
    begin
        IntKey(0, 5);
    end;

    [Test]
    procedure IntegerKey_ToZero()
    begin
        IntKey(5, 0);
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
        Observer.Finish();
    end;

    [Test]
    procedure MultiKey_FirstFieldBlankChanges()
    begin
        // A is only in the where filter of the relation; B is the related field.
        MultiKey('', 'B1', 'X', 'B1');
    end;

    [Test]
    procedure MultiKey_FirstFieldBlankKept()
    begin
        MultiKey('', 'B1', '', 'B2');
    end;

    [Test]
    procedure MultiKey_RelatedFieldBlankChanges()
    begin
        MultiKey('A1', '', 'A1', 'X');
    end;

    [Test]
    procedure MultiKey_RelatedFieldBlankKept()
    begin
        MultiKey('A1', '', 'A2', '');
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
        Observer.Finish();
    end;

    [Test]
    procedure GuidKey_FromBlank()
    var
        Blank: Guid;
    begin
        GuidKey(Blank, '{11111111-2222-3333-4444-555555555555}');
    end;

    [Test]
    procedure GuidKey_ToBlank()
    var
        Blank: Guid;
    begin
        GuidKey('{11111111-2222-3333-4444-555555555555}', Blank);
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
        Observer.Finish();
    end;

    [Test]
    procedure OptionKey_FromBlank()
    begin
        OptionKey(0, 1);
    end;

    [Test]
    procedure OptionKey_ToBlank()
    begin
        OptionKey(1, 0);
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
        Observer.Finish();
    end;

    [Test]
    procedure DateKey_FromBlank()
    begin
        DateKey(0D, DMY2Date(1, 2, 2024));
    end;

    [Test]
    procedure DateKey_ToBlank()
    begin
        DateKey(DMY2Date(1, 2, 2024), 0D);
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
        Observer.Finish();
    end;

    [Test]
    procedure TemporaryRecord_FromBlank()
    begin
        TemporaryKey('', 'X');
    end;

    [Test]
    procedure TemporaryRecord_ToBlank()
    begin
        TemporaryKey('X', '');
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
        Observer.Finish();
    end;

    [Test]
    procedure NoRelation_FromBlank()
    begin
        PlainKey('', 'X');
    end;

    [Test]
    procedure NoRelation_ToBlank()
    begin
        PlainKey('X', '');
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
        Observer.Finish();
    end;

    [Test]
    procedure IfRelation_FromBlank_ConditionMet()
    var
        Child: Record "RBK If Child";
    begin
        IfRelation('', 'X', Child.Kind::Linked);
    end;

    [Test]
    procedure IfRelation_FromBlank_ConditionNotMet()
    var
        Child: Record "RBK If Child";
    begin
        IfRelation('', 'X', Child.Kind::" ");
    end;

    [Test]
    procedure IfRelation_ToBlank_ConditionMet()
    var
        Child: Record "RBK If Child";
    begin
        IfRelation('X', '', Child.Kind::Linked);
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
        Observer.Finish();
    end;

    [Test]
    procedure WhereRelation_FromBlank()
    begin
        WhereRelation('', 'X');
    end;

    [Test]
    procedure WhereRelation_ToBlank()
    begin
        WhereRelation('X', '');
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
        Observer.Finish();
    end;

    [Test]
    procedure NamedKeyRelation_FromBlank()
    begin
        NamedRelation('', 'X');
    end;

    [Test]
    procedure NamedKeyRelation_ToBlank()
    begin
        NamedRelation('X', '');
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
        Observer.Finish();
    end;

    [Test]
    procedure NonKeyRelation_FromBlank()
    begin
        NonKeyRelation('', 'X');
    end;

    [Test]
    procedure NonKeyRelation_ToBlank()
    begin
        NonKeyRelation('X', '');
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
        Observer.Finish();
    end;

    [Test]
    procedure NoValidateRelation_FromBlank()
    begin
        NoValidateRelation('', 'X');
    end;

    [Test]
    procedure NoValidateRelation_ToBlank()
    begin
        NoValidateRelation('X', '');
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
        Observer.Finish();
    end;

    [Test]
    procedure TableExtensionRelation_FromBlank()
    begin
        ExtRelation('', 'X');
    end;

    [Test]
    procedure TableExtensionRelation_ToBlank()
    begin
        ExtRelation('X', '');
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
        Observer.Finish();
    end;

    [Test]
    procedure SameTableRelation_FromBlank()
    begin
        SelfRelation('', 'X');
    end;

    [Test]
    procedure SameTableRelation_ToBlank()
    begin
        SelfRelation('X', '');
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
        Observer.Finish();
    end;

    [Test]
    procedure TriggerAndSubscribers_FromBlank()
    begin
        TriggerRelation('', 'X');
    end;

    [Test]
    procedure TriggerAndSubscribers_ToBlank()
    begin
        TriggerRelation('X', '');
    end;

    [Test]
    procedure TriggerAndSubscribers_NonBlank()
    begin
        TriggerRelation('X', 'Y');
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
        Observer.Finish();
    end;

    [Test]
    procedure Captions_FromBlank()
    begin
        CaptionRelation('', 'X');
    end;

    [Test]
    procedure Captions_ToBlank()
    begin
        CaptionRelation('X', '');
    end;
}
