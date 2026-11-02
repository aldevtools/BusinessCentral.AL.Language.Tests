// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpagelink-property
// Scope: in-scope
// Fixtures used: none (objects for Y37LinkFilterTests.al, ids 92600-92611)
// Objects: a line table with a FlowFilter and a FlowField over an entry table, a host table whose Text fields hold filter texts, an error-like
//   table with a RecordId field, list parts that log their link filters, and host pages whose SubPageLink / RunPageLink read a host field
//   as a filter expression: `= field(filter("Line Filter"))`.
// BC versions: 27, 28, 29

table 92600 "LT Y37 LF Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Dept; Code[10]) { }
        field(3; Amount; Decimal) { }
        field(4; "Dept Filter"; Code[10]) { FieldClass = FlowFilter; }
        field(5; "Dept Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT Y37 LF Entry".Amount where(Dept = field("Dept Filter")));
        }
        field(6; "Rec Id Filter"; Text[250]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 92601 "LT Y37 LF Entry"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Dept; Code[10]) { }
        field(3; Amount; Decimal) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 92602 "LT Y37 LF Host"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Line Filter"; Text[250]) { }
        field(3; "Dept Filter Text"; Text[250]) { }
        field(4; "No. FlowFilter"; Code[20]) { FieldClass = FlowFilter; }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 92603 "LT Y37 LF Err"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Record ID"; RecordId) { }
        field(3; Note; Text[30]) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 92604 "LT Y37 LF Log"
{
    SingleInstance = true;

    var
        Buffer: Text;

    procedure Add(Entry: Text)
    begin
        Buffer += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Buffer;
        Buffer := '';
        exit(Result);
    end;

    // The filters of filter group 0 and of the link filter group 4 of a record.
    procedure Filters(var Line: Record "LT Y37 LF Line"): Text
    var
        Result: Text;
        Group: Integer;
    begin
        Group := Line.FilterGroup();
        Line.FilterGroup(0);
        Result := 'f0=[' + Line.GetFilters() + ']';
        Line.FilterGroup(4);
        Result += ' f4=[' + Line.GetFilters() + ']';
        Line.FilterGroup(Group);
        exit(Result);
    end;
}

page 92605 "LT Y37 LF Lines Part"
{
    PageType = ListPart;
    SourceTable = "LT Y37 LF Line";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(DeptCtl; Rec.Dept) { ApplicationArea = All; }
                field(DeptAmountCtl; Rec."Dept Amount") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('LP.open ' + Log.Filters(Rec));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('LP.c ' + Rec."No." + ' ' + Log.Filters(Rec));
    end;

    var
        Log: Codeunit "LT Y37 LF Log";
}

page 92606 "LT Y37 LF Err Part"
{
    PageType = ListPart;
    SourceTable = "LT Y37 LF Err";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Errs)
            {
                field(EntryCtl; Rec."Entry No.") { ApplicationArea = All; }
                field(NoteCtl; Rec.Note) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('EP.open ' + ErrFilters());
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('EP.c ' + Format(Rec."Entry No.") + ' ' + ErrFilters());
    end;

    local procedure ErrFilters(): Text
    var
        Result: Text;
        Group: Integer;
    begin
        Group := Rec.FilterGroup();
        Rec.FilterGroup(4);
        Result := 'f4=[' + Rec.GetFilter("Record ID") + ']';
        Rec.FilterGroup(Group);
        exit(Result);
    end;

    var
        Log: Codeunit "LT Y37 LF Log";
}

page 92607 "LT Y37 LF Card"
{
    PageType = Card;
    SourceTable = "LT Y37 LF Host";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(LineFilterCtl; Rec."Line Filter") { ApplicationArea = All; }
            field(DeptFilterCtl; Rec."Dept Filter Text") { ApplicationArea = All; }
            part(LinesPart; "LT Y37 LF Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field(filter("Line Filter")), "Dept Filter" = field(filter("Dept Filter Text"));
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UpdateAction)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.Update();
                end;
            }
        }
    }
}

page 92608 "LT Y37 LF Document"
{
    PageType = Document;
    SourceTable = "LT Y37 LF Host";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            part(LinesPart; "LT Y37 LF Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field(filter("Line Filter"));
            }
        }
        area(FactBoxes)
        {
            part(ErrPart; "LT Y37 LF Err Part")
            {
                ApplicationArea = All;
                Provider = LinesPart;
                SubPageLink = "Record ID" = field(filter("Rec Id Filter"));
            }
        }
    }
}

page 92609 "LT Y37 LF Run Card"
{
    PageType = Card;
    SourceTable = "LT Y37 LF Host";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenLines)
            {
                ApplicationArea = All;
                RunObject = page "LT Y37 LF Line List";
                RunPageLink = "No." = field(filter("Line Filter"));
            }
        }
    }
}

page 92610 "LT Y37 LF Line List"
{
    PageType = List;
    SourceTable = "LT Y37 LF Line";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('LL.open ' + Log.Filters(Rec));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('LL.c ' + Rec."No." + ' ' + Log.Filters(Rec));
    end;

    var
        Log: Codeunit "LT Y37 LF Log";
}

page 92611 "LT Y37 LF FlowFilter Card"
{
    PageType = Card;
    SourceTable = "LT Y37 LF Host";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            part(LinesPart; "LT Y37 LF Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field(filter("No. FlowFilter"));
            }
        }
    }
}
