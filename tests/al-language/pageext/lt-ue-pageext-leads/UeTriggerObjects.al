// Objects for UeTriggerTests.al (AL Runner issue 6149): a list page with OnNewRecord, OnInsertRecord, OnModifyRecord and OnAfterGetRecord
// triggers, and two page extensions of it that declare the same triggers. Every trigger writes its name to the log; the extensions' answers
// for OnInsertRecord and OnModifyRecord are set through the log codeunit. Fixtures: table 90330, log 90331, page 90332, extensions 90333 and 90334.

table 90330 "LT UE Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Amount; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 90331 "LT UE Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        Ext1InsertAnswer: Boolean;
        Ext2ModifyAnswer: Boolean;

    procedure Reset()
    begin
        Entries := '';
        Ext1InsertAnswer := true;
        Ext2ModifyAnswer := true;
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;

    procedure SetExt1InsertAnswer(Value: Boolean)
    begin
        Ext1InsertAnswer := Value;
    end;

    procedure GetExt1InsertAnswer(): Boolean
    begin
        exit(Ext1InsertAnswer);
    end;

    procedure SetExt2ModifyAnswer(Value: Boolean)
    begin
        Ext2ModifyAnswer := Value;
    end;

    procedure GetExt2ModifyAnswer(): Boolean
    begin
        exit(Ext2ModifyAnswer);
    end;
}

page 90332 "LT UE List"
{
    PageType = List;
    SourceTable = "LT UE Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { }
                field(Amount; Rec.Amount) { }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT UE Log";
    begin
        Log.Add('base.OnNewRecord');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "LT UE Log";
    begin
        Log.Add('base.OnInsertRecord id=' + Format(Rec.Id));
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Log: Codeunit "LT UE Log";
    begin
        Log.Add('base.OnModifyRecord id=' + Format(Rec.Id) + ' amount=' + Format(Rec.Amount));
        exit(true);
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT UE Log";
    begin
        Log.Add('base.OnAfterGetRecord id=' + Format(Rec.Id));
    end;
}

pageextension 90333 "LT UE List Ext1" extends "LT UE List"
{
    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT UE Log";
    begin
        Log.Add('ext1.OnNewRecord');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "LT UE Log";
    begin
        Log.Add('ext1.OnInsertRecord id=' + Format(Rec.Id));
        exit(Log.GetExt1InsertAnswer());
    end;

    trigger OnModifyRecord(): Boolean
    var
        Log: Codeunit "LT UE Log";
    begin
        Log.Add('ext1.OnModifyRecord id=' + Format(Rec.Id) + ' amount=' + Format(Rec.Amount));
        exit(true);
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT UE Log";
    begin
        Log.Add('ext1.OnAfterGetRecord id=' + Format(Rec.Id));
    end;
}

pageextension 90334 "LT UE List Ext2" extends "LT UE List"
{
    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT UE Log";
    begin
        Log.Add('ext2.OnNewRecord');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "LT UE Log";
    begin
        Log.Add('ext2.OnInsertRecord id=' + Format(Rec.Id));
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Log: Codeunit "LT UE Log";
    begin
        Log.Add('ext2.OnModifyRecord id=' + Format(Rec.Id) + ' amount=' + Format(Rec.Amount));
        exit(Log.GetExt2ModifyAnswer());
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT UE Log";
    begin
        Log.Add('ext2.OnAfterGetRecord id=' + Format(Rec.Id));
    end;
}
