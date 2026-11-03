// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-data-type
// Scope: in-scope
// Fixtures for "LT CE Page Run Tests" (84362) and "LT CE Page Ext Tests" (84363): corpus issue 667 items about Page.Run,
// Page.RunModal, SetTableView, SourceTableView with OnFindRecord, ClearAll in a base page and page extension triggers and actions.

enum 84340 "LT CE Kind"
{
    Extensible = false;
    value(0; A) { }
    value(1; B) { }
    value(2; C) { }
}

table 84340 "LT CE Row"
{
    DataClassification = SystemMetadata;
    LookupPageId = "LT CE List";

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "LT CE Kind") { }
        field(3; Opt; Option) { OptionMembers = A,B,C; }
        field(4; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// No LookupPageId and no DrillDownPageId.
table 84341 "LT CE Plain Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 84344 "LT CE List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT CE Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
                field(Opt; Rec.Opt) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

page 84345 "LT CE View List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT CE Row";
    SourceTableView = where(Kind = const(A));
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
            }
        }
    }
}

page 84346 "LT CE Desc Find List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT CE Row";
    SourceTableView = sorting(Id) order(descending);
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT CE Log";
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        Log.Add('find(' + Which + ')=' + Format(Rec.Id));
        exit(Found);
    end;
}

page 84347 "LT CE Desc Plain List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT CE Row";
    SourceTableView = sorting(Id) order(descending);
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
    }
}

// The base page calls ClearAll in OnAfterGetRecord, like the Base Application statistics pages.
page 84348 "LT CE ClearAll Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT CE Row";
    Editable = false;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }

    var
        BaseFlag: Boolean;

    trigger OnOpenPage()
    begin
        BaseFlag := true;
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT CE Ext Log";
    begin
        Log.Add('base AGR before ClearAll flag=' + Format(BaseFlag));
        ClearAll();
        Log.Add('base AGR after ClearAll flag=' + Format(BaseFlag));
    end;
}

pageextension 84356 "LT CE ClearAll Ext" extends "LT CE ClearAll Card"
{
    var
        ExtFlag: Boolean;

    trigger OnOpenPage()
    begin
        ExtFlag := true;
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT CE Ext Log";
    begin
        Log.Add('ext AGR flag=' + Format(ExtFlag));
    end;
}

// Page 302 of the Base Application calls ClearAll() first in its OnAfterGetRecord (BC 27 source).
pageextension 84357 "LT CE Cust Entry Stat Ext" extends "Customer Entry Statistics"
{
    var
        ExtFlag: Boolean;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT CE Ext Log";
    begin
        ExtFlag := true;
        Log.Add('ext OnOpenPage');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT CE Ext Log";
    begin
        Log.Add('ext AGR flag=' + Format(ExtFlag));
    end;
}

page 84349 "LT CE Vis Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT CE Row";
    Editable = false;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(BaseAct)
            {
                ApplicationArea = All;
                Visible = BaseVis;
                trigger OnAction()
                begin
                end;
            }
        }
    }

    var
        BaseVis: Boolean;

    trigger OnOpenPage()
    begin
        BaseVis := true;
    end;
}

pageextension 84358 "LT CE Vis Ext" extends "LT CE Vis Card"
{
    actions
    {
        addlast(Processing)
        {
            action(ExtAct)
            {
                ApplicationArea = All;
                Caption = 'Ext action';
                Visible = ExtActive;
                trigger OnAction()
                begin
                end;
            }
            action(ExtActNeverSet)
            {
                ApplicationArea = All;
                Caption = 'Ext action never set';
                Visible = NeverSet;
                trigger OnAction()
                begin
                end;
            }
        }
    }

    var
        ExtActive: Boolean;
        NeverSet: Boolean;

    trigger OnOpenPage()
    begin
        ExtActive := true;
    end;
}

// The two logs stay at the end of the file: each is used by one test codeunit only (check-singleinstance-fixture-owners.py).
codeunit 84361 "LT CE Log"
{
    SingleInstance = true;

    var
        Entries: Text;

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
}

// Separate from "LT CE Log": a SingleInstance log is used by one test codeunit only.
codeunit 84364 "LT CE Ext Log"
{
    SingleInstance = true;

    var
        Entries: Text;

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
}
