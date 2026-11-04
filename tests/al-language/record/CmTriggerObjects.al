// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-validatetablerelation-property
// Scope: in-scope
// Fixtures for CmTriggerLeads.al (codeunit 84830): corpus issue 669 (odd AL behavior leads, part D), items 31 to 40.
// Objects 84820-84829, 84831-84833. The log codeunit 84828 is SingleInstance and used only by codeunit 84830.

table 84820 "LT CM Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30])
        {
            // Item 38: xRec inside OnValidate, before and after the trigger changes Rec, and around a nested Validate.
            trigger OnValidate()
            var
                Log: Codeunit "LT CM Log";
            begin
                Log.Add(StrSubstNo('Name.OnValidate rec=%1 x=%2 xnote=%3', Rec.Name, xRec.Name, xRec.Note));
                Rec.Note := 'set-in-name';
                Log.Add(StrSubstNo('Name.after-assign xnote=%1', xRec.Note));
                Rec.Validate(Note, 'nested');
                Log.Add(StrSubstNo('Name.after-nested x=%1 xnote=%2 note=%3', xRec.Name, xRec.Note, Rec.Note));
            end;
        }
        field(3; Note; Text[30])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT CM Log";
            begin
                Log.Add(StrSubstNo('Note.OnValidate rec=%1 x=%2 xname=%3', Rec.Note, xRec.Note, xRec.Name));
            end;
        }
        // Items 33 and 34: a TableRelation and an OnValidate trigger, no ValidateTableRelation property.
        field(4; Rel; Code[20])
        {
            TableRelation = "LT CM Parent".Code;

            trigger OnValidate()
            var
                Log: Codeunit "LT CM Log";
            begin
                Log.Add(StrSubstNo('Rel.OnValidate rec=%1', Rel));
            end;
        }
        field(5; "Rel True"; Code[20])
        {
            TableRelation = "LT CM Parent".Code;
            ValidateTableRelation = true;
        }
        field(6; "Rel False"; Code[20])
        {
            TableRelation = "LT CM Parent".Code;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                Log: Codeunit "LT CM Log";
            begin
                Log.Add(StrSubstNo('RelFalse.OnValidate rec=%1', "Rel False"));
            end;
        }
        field(7; Amount; Decimal) { }
    }

    keys { key(PK; Id) { Clustered = true; } }

    trigger OnModify()
    var
        Log: Codeunit "LT CM Log";
    begin
        Log.Add(StrSubstNo('T.OnModify rec=%1 x=%2 cur=%3', Rec.Name, xRec.Name, CurrFieldNo));
        Rec.Note := 'set-in-modify';
        Log.Add(StrSubstNo('T.OnModify after-assign xnote=%1', xRec.Note));
    end;
}

table 84821 "LT CM Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
    }

    keys { key(PK; Code) { Clustered = true; } }
}

// Item 37: a real (not temporary) table that the triggers of "LT CM Temp Row" write to.
table 84822 "LT CM Log Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; Txt; Text[100]) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}

// Item 37: each trigger writes a row to the real table "LT CM Log Row"; OnDelete also deletes the real related row (same Id) in "LT CM Parent".
table 84823 "LT CM Temp Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }

    trigger OnInsert()
    begin
        WriteLog('OnInsert ' + Format(Id) + ' temp=' + Format(Rec.IsTemporary()));
    end;

    trigger OnModify()
    begin
        WriteLog('OnModify ' + Format(Id));
    end;

    trigger OnDelete()
    var
        Parent: Record "LT CM Parent";
    begin
        WriteLog('OnDelete ' + Format(Id));
        if Parent.Get(Format(Id)) then
            Parent.Delete();
    end;

    local procedure WriteLog(Line: Text)
    var
        LogRow: Record "LT CM Log Row";
    begin
        LogRow.Init();
        LogRow.Txt := CopyStr(Line, 1, MaxStrLen(LogRow.Txt));
        LogRow.Insert();
    end;
}

// Item 36: OnInsert copies the row into "LT CM Backup" with the SystemId of the row being inserted, then looks it up by SystemId.
table 84824 "LT CM Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Mode; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }

    trigger OnInsert()
    var
        Backup: Record "LT CM Backup";
        Found: Record "LT CM Backup";
        Log: Codeunit "LT CM Log";
    begin
        Log.Add('src.sysid_null=' + Format(IsNullGuid(Rec.SystemId)));
        case Mode of
            1:
                begin
                    // SystemId copied by hand, Insert(false, true) keeps it.
                    Backup.Init();
                    Backup.Id := Id;
                    Backup.Name := Name;
                    Backup.SystemId := Rec.SystemId;
                    Backup.Insert(false, true);
                end;
            2:
                begin
                    // TransferFields, then a plain Insert.
                    Backup.Init();
                    Backup.TransferFields(Rec);
                    Backup.Insert();
                end;
            3:
                begin
                    // TransferFields, then Insert(false, true).
                    Backup.Init();
                    Backup.TransferFields(Rec);
                    Backup.Insert(false, true);
                end;
        end;
        Log.Add('backup.same_sysid=' + Format(Backup.SystemId = Rec.SystemId));
        Log.Add('getbysystemid=' + Format(Found.GetBySystemId(Rec.SystemId)));
        if Found.Name <> '' then
            Log.Add('found.name=' + Found.Name);
    end;
}

table 84825 "LT CM Backup"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

// Item 35: a base table with no triggers; its table extension sets fields in OnInsert, OnBeforeInsert and OnAfterInsert.
table 84826 "LT CM Ins Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Set By Before"; Text[30]) { }
        field(3; "Set By Insert"; Text[30]) { }
        field(4; "Set By After"; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

tableextension 84827 "LT CM Ins Row Ext" extends "LT CM Ins Row"
{
    fields
    {
        // Item 34: tableextension fields with a TableRelation, without the property and with true / false.
        field(84820; "Ext Rel"; Code[20]) { TableRelation = "LT CM Parent".Code; DataClassification = SystemMetadata; }
        field(84821; "Ext Rel True"; Code[20]) { TableRelation = "LT CM Parent".Code; ValidateTableRelation = true; DataClassification = SystemMetadata; }
        field(84822; "Ext Rel False"; Code[20]) { TableRelation = "LT CM Parent".Code; ValidateTableRelation = false; DataClassification = SystemMetadata; }
    }

    trigger OnBeforeInsert()
    begin
        Rec."Set By Before" := 'before';
    end;

    trigger OnInsert()
    begin
        Rec."Set By Insert" := 'insert';
    end;

    trigger OnAfterInsert()
    begin
        Rec."Set By After" := 'after';
    end;
}

codeunit 84828 "LT CM Log"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Add(Line: Text)
    begin
        Lines += Line + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Lines;
        Lines := '';
    end;
}

// Item 39: manual subscriber to the Modify events of "LT CM Row".
codeunit 84829 "LT CM Modify Subs"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"LT CM Row", OnBeforeModifyEvent, '', false, false)]
    local procedure BeforeModify(var Rec: Record "LT CM Row"; var xRec: Record "LT CM Row"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT CM Log";
    begin
        Log.Add(StrSubstNo('S.BeforeModify rec=%1 x=%2', Rec.Name, xRec.Name));
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT CM Row", OnAfterModifyEvent, '', false, false)]
    local procedure AfterModify(var Rec: Record "LT CM Row"; var xRec: Record "LT CM Row"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT CM Log";
    begin
        Log.Add(StrSubstNo('S.AfterModify rec=%1 x=%2', Rec.Name, xRec.Name));
    end;
}

page 84831 "LT CM Card"
{
    PageType = Card;
    SourceTable = "LT CM Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
            field(Amount; Rec.Amount) { ApplicationArea = All; }
        }
    }
}

// Item 40: a list page with OnInsertRecord and OnModifyRecord triggers that log and answer true.
page 84832 "LT CM List"
{
    PageType = List;
    SourceTable = "LT CM Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "LT CM Log";
    begin
        Log.Add('P.OnInsertRecord id=' + Format(Rec.Id) + ' filters=' + Rec.GetFilters());
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Log: Codeunit "LT CM Log";
    begin
        Log.Add('P.OnModifyRecord id=' + Format(Rec.Id));
        exit(true);
    end;
}

// Item 31: a table extension assigns CurrFieldNo and then runs Modify(true). Rec.CurrFieldNo does not compile here (must-not-compile case 1696).
tableextension 84833 "LT CM Row Ext" extends "LT CM Row"
{
    procedure CmAssignCurrFieldNoThenModify(Value: Integer)
    begin
        CurrFieldNo := Value;
        Modify(true);
    end;
}
