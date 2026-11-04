// Objects for codeunit 84439 "LT CF Page Leads" (corpus issue 667 items 81, 85, 86, 88, 89, 90).
// Ids 84420-84435. A SingleInstance log records which triggers ran, in order.

codeunit 84435 "LT CF P Log"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Reset()
    begin
        Lines := '';
    end;

    procedure Add(Entry: Text)
    begin
        if Lines <> '' then
            Lines += ',';
        Lines += Entry;
    end;

    procedure Text(): Text
    begin
        exit(Lines);
    end;
}

table 84420 "LT CF P Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Val; Text[30]) { }
        field(3; "Date Filter"; Date)
        {
            FieldClass = FlowFilter;
            trigger OnValidate()
            var
                Log: Codeunit "LT CF P Log";
            begin
                Log.Add('DateFilter.OnValidate');
            end;
        }
        field(4; Amount; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT CF P Entry".Amount where("Code" = field("Code"), "Posting Date" = field("Date Filter")));
            Editable = true;
            trigger OnValidate()
            var
                Log: Codeunit "LT CF P Log";
            begin
                Log.Add('Amount.OnValidate:' + Format(Amount) + '/' + Format(xRec.Amount));
            end;
        }
    }
    keys { key(PK; "Code") { Clustered = true; } }

    trigger OnInsert()
    var
        Log: Codeunit "LT CF P Log";
    begin
        Log.Add('Row.OnInsert');
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT CF P Log";
    begin
        Log.Add('Row.OnModify');
    end;
}

table 84421 "LT CF P Entry"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Code"; Code[10]) { }
        field(3; "Posting Date"; Date) { }
        field(4; Amount; Decimal) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }

    trigger OnInsert()
    var
        Log: Codeunit "LT CF P Log";
    begin
        Log.Add('Entry.OnInsert');
    end;
}

// Item 81: an API page whose OnInsertRecord runs Rec.Insert(true) itself.
table 84422 "LT CF P Api Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }

    trigger OnInsert()
    var
        Log: Codeunit "LT CF P Log";
    begin
        Log.Add('ApiRow.OnInsert:' + Format(Id) + '/' + Name);
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT CF P Log";
    begin
        Log.Add('ApiRow.OnModify:' + Format(Id) + '/' + Name);
    end;
}

page 84423 "LT CF P Api False"
{
    PageType = API;
    SourceTable = "LT CF P Api Row";
    APIPublisher = 'ltcf';
    APIGroup = 'ltcf';
    APIVersion = 'v1.0';
    EntityName = 'ltcfRowFalse';
    EntitySetName = 'ltcfRowsFalse';
    ODataKeyFields = Id;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(id; Rec.Id) { }
                field(name; Rec.Name) { }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "LT CF P Log";
    begin
        Log.Add('OnInsertRecord');
        Rec.Insert(true);
        exit(false);
    end;
}

page 84424 "LT CF P Api True"
{
    PageType = API;
    SourceTable = "LT CF P Api Row";
    APIPublisher = 'ltcf';
    APIGroup = 'ltcf';
    APIVersion = 'v1.0';
    EntityName = 'ltcfRowTrue';
    EntitySetName = 'ltcfRowsTrue';
    ODataKeyFields = Id;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(id; Rec.Id) { }
                field(name; Rec.Name) { }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "LT CF P Log";
    begin
        Log.Add('OnInsertRecord');
        Rec.Insert(true);
        exit(true);
    end;
}

// Item 85: a card whose OnNewRecord inserts the record when "No." is blank (microsoft/AL issue 814).
table 84425 "LT CF P Doc"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[30])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT CF P Log";
            begin
                Log.Add('Description.OnValidate');
            end;
        }
    }
    keys { key(PK; "No.") { Clustered = true; } }

    trigger OnInsert()
    var
        Log: Codeunit "LT CF P Log";
    begin
        if "No." = '' then
            "No." := 'DOC1';
        Log.Add('Doc.OnInsert:' + "No.");
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT CF P Log";
    begin
        Log.Add('Doc.OnModify:' + "No." + '/' + Description);
    end;
}

page 84426 "LT CF P New Card"
{
    PageType = Card;
    SourceTable = "LT CF P Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Description; Rec.Description) { ApplicationArea = All; }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "LT CF P Log";
    begin
        Log.Add('OnNewRecord');
        if Rec."No." = '' then
            Rec.Insert(true);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "LT CF P Log";
    begin
        Log.Add('OnInsertRecord:' + Rec."No.");
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Log: Codeunit "LT CF P Log";
    begin
        Log.Add('OnModifyRecord:' + Rec."No.");
        exit(true);
    end;
}

// Item 86: a FlowFilter field as a list column, on the page and from a page extension (microsoft/AL issue 2568).
page 84427 "LT CF P FlowFilter List"
{
    PageType = List;
    SourceTable = "LT CF P Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(DateFilter; Rec."Date Filter") { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
            }
        }
    }
}

pageextension 84428 "LT CF P FlowFilter List Ext" extends "LT CF P FlowFilter List"
{
    layout
    {
        addlast(Rows)
        {
            field(ExtDateFilter; Rec."Date Filter") { ApplicationArea = All; }
        }
    }
}

// Item 88: a FlowField used in a TableRelation filter, calculated in OnAfterGetCurrRecord (microsoft/AL issue 7460).
table 84429 "LT CF P Hdr"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Vendor; Code[20]) { }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}

table 84430 "LT CF P Line"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Doc No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; HdrVendor; Code[20])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("LT CF P Hdr".Vendor where("No." = field("Doc No.")));
            Editable = false;
        }
        field(4; Item; Code[20])
        {
            TableRelation = "LT CF P Item"."Code" where(Vendor = field(HdrVendor));
        }
    }
    keys { key(PK; "Doc No.", "Line No.") { Clustered = true; } }
}

table 84431 "LT CF P Item"
{
    DataClassification = SystemMetadata;
    LookupPageId = "LT CF P Item List";
    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Vendor; Code[20]) { }
    }
    keys { key(PK; "Code") { Clustered = true; } }
}

page 84432 "LT CF P Item List"
{
    PageType = List;
    SourceTable = "LT CF P Item";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Vendor; Rec.Vendor) { ApplicationArea = All; }
            }
        }
    }
}

page 84433 "LT CF P Line Card"
{
    PageType = Card;
    SourceTable = "LT CF P Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Doc No."; Rec."Doc No.") { ApplicationArea = All; }
            field("Line No."; Rec."Line No.") { ApplicationArea = All; }
            field(HdrVendor; Rec.HdrVendor) { ApplicationArea = All; }
            field(Item; Rec.Item) { ApplicationArea = All; }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        Rec.CalcFields(HdrVendor);
    end;
}

// Items 89 and 90: an editable FlowField and a FlowFilter on a card.
page 84434 "LT CF P Row Card"
{
    PageType = Card;
    SourceTable = "LT CF P Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(Val; Rec.Val) { ApplicationArea = All; }
            field(DateFilter; Rec."Date Filter") { ApplicationArea = All; }
            field(Amount; Rec.Amount) { ApplicationArea = All; }
        }
    }

    trigger OnModifyRecord(): Boolean
    var
        Log: Codeunit "LT CF P Log";
    begin
        Log.Add('OnModifyRecord');
        exit(true);
    end;
}
