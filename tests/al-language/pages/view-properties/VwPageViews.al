// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetableview-property
// Scope: in-scope (Cloud)
// local object: the view / filter property of the object is what is under test, so each case needs its own page or report; the capture codeunit is SingleInstance and outlives a test
// Fixtures used: Probe Observer (codeunit 69160); own objects in 96600..96699
// BC versions: 27, 28, 29
// Area matrix (al-runner issues 7371, 7405, 7411, 7423): the view of a page, a part and a part link, crossed with the value forms of a
//   filter and the field types. Each case opens the page (SourceTableView), or a host card with a part (SubPageView) or with a part whose
//   SubPageLink holds the same text, and observes the rows the page shows, Rec.GetFilters() and Rec.GetView() as the page saw them in
//   OnOpenPage, or the error. The same forms run on a report data item in reports/dataitem-table-view/VwDataItemTableView.al and
//   on Record.SetView in record/set-view/VwSetView.al; the TableRelation forms are in table-objects/table-relation-where/.
//   Rows (No. / code / text / integer / kind / date / bool / decimal / option):
//   R1 '' '' 0 Item 0D false 0 A | R2 A A 96600 Resource 2026-01-01 true 5 B | R3 B '' 1 Item 0D true 0 C | R4 '' X 96600 Fixed Asset 2026-01-02 false 0 A | R5 C C 2 Resource 0D false 0 B

enum 96600 "VW Kind"
{
    Extensible = true;

    value(0; Item) { }
    value(1; Resource) { }
    value(2; "Fixed Asset") { }
}

table 96600 "VW Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; CodeF; Code[20]) { }
        field(3; TextF; Text[20]) { }
        field(4; IntF; Integer) { }
        field(5; KindF; Enum "VW Kind") { }
        field(6; DateF; Date) { }
        field(7; BoolF; Boolean) { }
        field(8; DecF; Decimal) { }
        field(9; OptF; Option) { OptionMembers = A,B,C; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 96601 "VW Header"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 96600 "VW Capture"
{
    SingleInstance = true;

    var
        Notes: Dictionary of [Text, Text];
        RowList: Text;

    procedure Reset()
    begin
        Clear(Notes);
        RowList := '';
    end;

    procedure Note(Prefix: Text; Filters: Text; ViewNames: Text; ViewCaptions: Text)
    begin
        Notes.Set(Prefix + '.filters', Filters);
        Notes.Set(Prefix + '.view', ViewNames);
        Notes.Set(Prefix + '.viewCaptions', ViewCaptions);
    end;

    procedure Get(NoteKey: Text): Text
    var
        Value: Text;
    begin
        if Notes.Get(NoteKey, Value) then
            exit(Value);
        exit('<none>');
    end;

    procedure AddRow(No: Text)
    begin
        if RowList <> '' then
            RowList += ',';
        RowList += No;
    end;

    procedure Rows(): Text
    begin
        exit(RowList);
    end;

    procedure Seed()
    var
        Row: Record "VW Row";
        Header: Record "VW Header";
    begin
        Row.DeleteAll();
        Header.DeleteAll();
        Header."No." := 'H1';
        Header.Insert();
        InsertRow('R1', '', '', 0, "VW Kind"::Item, 0D, false, 0, 0);
        InsertRow('R2', 'A', 'A', 96600, "VW Kind"::Resource, DMY2Date(1, 1, 2026), true, 5, 1);
        InsertRow('R3', 'B', '', 1, "VW Kind"::Item, 0D, true, 0, 2);
        InsertRow('R4', '', 'X', 96600, "VW Kind"::"Fixed Asset", DMY2Date(2, 1, 2026), false, 0, 0);
        InsertRow('R5', 'C', 'C', 2, "VW Kind"::Resource, 0D, false, 0, 1);
    end;

    local procedure InsertRow(No: Code[20]; CodeValue: Code[20]; TextValue: Text[20]; IntValue: Integer; KindValue: Enum "VW Kind"; DateValue: Date; BoolValue: Boolean; DecValue: Decimal; OptionValue: Integer)
    var
        Row: Record "VW Row";
    begin
        Row."No." := No;
        Row.CodeF := CodeValue;
        Row.TextF := TextValue;
        Row.IntF := IntValue;
        Row.KindF := KindValue;
        Row.DateF := DateValue;
        Row.BoolF := BoolValue;
        Row.DecF := DecValue;
        Row.OptF := OptionValue;
        Row.Insert();
    end;
}

page 96698 "VW Part V"
{
    PageType = ListPart;
    SourceTable = "VW Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('V', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96699 "VW Part L"
{
    PageType = ListPart;
    SourceTable = "VW Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('L', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96601 "VW List 01"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(CodeF = const(''));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96602 "VW List 02"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(CodeF = filter(''));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96603 "VW List 03"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(CodeF = filter(<> ''));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96604 "VW List 04"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(CodeF = const('A'));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96605 "VW List 05"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(CodeF = filter('A|B'));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96606 "VW List 06"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(CodeF = filter('='''''));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96607 "VW List 07"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(TextF = const(''));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96608 "VW List 08"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(TextF = filter(<> ''));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96609 "VW List 09"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(IntF = const(Database::"VW Row"));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96610 "VW List 10"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(IntF = filter(Database::"VW Row"));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96611 "VW List 11"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(IntF = filter(<> Database::"VW Row"));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96612 "VW List 12"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(IntF = filter(Database::"VW Row" | 1));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96613 "VW List 13"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(IntF = const(0));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96614 "VW List 14"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(IntF = filter(1 .. 2));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96615 "VW List 15"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(KindF = const(Item));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96616 "VW List 16"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(KindF = filter(Item));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96617 "VW List 17"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(KindF = filter("VW Kind"::Item));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96619 "VW List 19"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(KindF = filter(<> "VW Kind"::Item));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96622 "VW List 22"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(KindF = filter("VW Kind"::"Fixed Asset"));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96623 "VW List 23"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(KindF = const("Fixed Asset"));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96624 "VW List 24"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(KindF = const("VW Kind"::Resource));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96625 "VW List 25"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(DateF = filter(''));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96626 "VW List 26"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(DateF = filter('='''''));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96627 "VW List 27"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(DateF = filter(<> ''));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96628 "VW List 28"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(BoolF = const(true));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96629 "VW List 29"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(BoolF = const(false));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96630 "VW List 30"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(BoolF = filter(true));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96631 "VW List 31"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(OptF = const(B));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96632 "VW List 32"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(OptF = filter(<> A));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96633 "VW List 33"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(DecF = filter(> 0));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96635 "VW List 35"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(KindF = filter("VW Kind"::Item), CodeF = const(''));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96636 "VW List 36"
{
    PageType = List;
    SourceTable = "VW Row";
    SourceTableView = where(CodeF = const(''), IntF = const(Database::"VW Row"), KindF = filter(<> "VW Kind"::Item));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capture: Codeunit "VW Capture";
    begin
        Capture.Note('S', Rec.GetFilters(), Rec.GetView(true), Rec.GetView(false));
    end;
}

page 96651 "VW Host 01"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(CodeF = const('')); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = CodeF = const(''); }
        }
    }
}

page 96652 "VW Host 02"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(CodeF = filter('')); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = CodeF = filter(''); }
        }
    }
}

page 96653 "VW Host 03"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(CodeF = filter(<> '')); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = CodeF = filter(<> ''); }
        }
    }
}

page 96654 "VW Host 04"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(CodeF = const('A')); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = CodeF = const('A'); }
        }
    }
}

page 96655 "VW Host 05"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(CodeF = filter('A|B')); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = CodeF = filter('A|B'); }
        }
    }
}

page 96656 "VW Host 06"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(CodeF = filter('=''''')); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = CodeF = filter('='''''); }
        }
    }
}

page 96657 "VW Host 07"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(TextF = const('')); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = TextF = const(''); }
        }
    }
}

page 96658 "VW Host 08"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(TextF = filter(<> '')); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = TextF = filter(<> ''); }
        }
    }
}

page 96659 "VW Host 09"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(IntF = const(Database::"VW Row")); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = IntF = const(Database::"VW Row"); }
        }
    }
}

page 96660 "VW Host 10"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(IntF = filter(Database::"VW Row")); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = IntF = filter(Database::"VW Row"); }
        }
    }
}

page 96661 "VW Host 11"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(IntF = filter(<> Database::"VW Row")); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = IntF = filter(<> Database::"VW Row"); }
        }
    }
}

page 96662 "VW Host 12"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(IntF = filter(Database::"VW Row" | 1)); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = IntF = filter(Database::"VW Row" | 1); }
        }
    }
}

page 96663 "VW Host 13"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(IntF = const(0)); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = IntF = const(0); }
        }
    }
}

page 96664 "VW Host 14"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(IntF = filter(1 .. 2)); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = IntF = filter(1 .. 2); }
        }
    }
}

page 96665 "VW Host 15"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(KindF = const(Item)); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = KindF = const(Item); }
        }
    }
}

page 96666 "VW Host 16"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(KindF = filter(Item)); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = KindF = filter(Item); }
        }
    }
}

page 96667 "VW Host 17"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(KindF = filter("VW Kind"::Item)); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = KindF = filter("VW Kind"::Item); }
        }
    }
}

page 96669 "VW Host 19"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(KindF = filter(<> "VW Kind"::Item)); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = KindF = filter(<> "VW Kind"::Item); }
        }
    }
}

page 96672 "VW Host 22"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(KindF = filter("VW Kind"::"Fixed Asset")); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = KindF = filter("VW Kind"::"Fixed Asset"); }
        }
    }
}

page 96673 "VW Host 23"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(KindF = const("Fixed Asset")); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = KindF = const("Fixed Asset"); }
        }
    }
}

page 96674 "VW Host 24"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(KindF = const("VW Kind"::Resource)); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = KindF = const("VW Kind"::Resource); }
        }
    }
}

page 96675 "VW Host 25"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(DateF = filter('')); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = DateF = filter(''); }
        }
    }
}

page 96676 "VW Host 26"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(DateF = filter('=''''')); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = DateF = filter('='''''); }
        }
    }
}

page 96677 "VW Host 27"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(DateF = filter(<> '')); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = DateF = filter(<> ''); }
        }
    }
}

page 96678 "VW Host 28"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(BoolF = const(true)); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = BoolF = const(true); }
        }
    }
}

page 96679 "VW Host 29"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(BoolF = const(false)); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = BoolF = const(false); }
        }
    }
}

page 96680 "VW Host 30"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(BoolF = filter(true)); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = BoolF = filter(true); }
        }
    }
}

page 96681 "VW Host 31"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(OptF = const(B)); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = OptF = const(B); }
        }
    }
}

page 96682 "VW Host 32"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(OptF = filter(<> A)); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = OptF = filter(<> A); }
        }
    }
}

page 96683 "VW Host 33"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(DecF = filter(> 0)); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = DecF = filter(> 0); }
        }
    }
}

page 96685 "VW Host 35"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(KindF = filter("VW Kind"::Item), CodeF = const('')); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = KindF = filter("VW Kind"::Item), CodeF = const(''); }
        }
    }
}

page 96686 "VW Host 36"
{
    PageType = Card;
    SourceTable = "VW Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "VW Part V") { ApplicationArea = All; SubPageView = where(CodeF = const(''), IntF = const(Database::"VW Row"), KindF = filter(<> "VW Kind"::Item)); }
            part(Links; "VW Part L") { ApplicationArea = All; SubPageLink = CodeF = const(''), IntF = const(Database::"VW Row"), KindF = filter(<> "VW Kind"::Item); }
        }
    }
}

codeunit 96601 "VW Source Table View Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Capture: Codeunit "VW Capture";

    local procedure Initialize()
    begin
        Capture.Seed();
        Capture.Reset();
    end;

    [TryFunction]
    local procedure Open01()
    var
        Page: TestPage "VW List 01";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(CodeF = const('')) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_CodeConstBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open01() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open02()
    var
        Page: TestPage "VW List 02";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(CodeF = filter('')) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_CodeFilterBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open02() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open03()
    var
        Page: TestPage "VW List 03";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(CodeF = filter(<> '')) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_CodeFilterNotBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open03() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open04()
    var
        Page: TestPage "VW List 04";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(CodeF = const('A')) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_CodeConstA()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open04() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open05()
    var
        Page: TestPage "VW List 05";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(CodeF = filter('A|B')) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_CodeFilterOr()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open05() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open06()
    var
        Page: TestPage "VW List 06";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(CodeF = filter('=''''')) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_CodeFilterEqualsBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open06() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open07()
    var
        Page: TestPage "VW List 07";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(TextF = const('')) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_TextConstBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open07() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open08()
    var
        Page: TestPage "VW List 08";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(TextF = filter(<> '')) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_TextFilterNotBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open08() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open09()
    var
        Page: TestPage "VW List 09";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(IntF = const(Database::"VW Row")) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_IntConstDatabase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open09() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open10()
    var
        Page: TestPage "VW List 10";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(IntF = filter(Database::"VW Row")) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_IntFilterDatabase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open10() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open11()
    var
        Page: TestPage "VW List 11";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(IntF = filter(<> Database::"VW Row")) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_IntFilterNotDatabase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open11() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open12()
    var
        Page: TestPage "VW List 12";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(IntF = filter(Database::"VW Row" | 1)) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_IntFilterDatabaseOrNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open12() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open13()
    var
        Page: TestPage "VW List 13";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(IntF = const(0)) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_IntConstZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open13() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open14()
    var
        Page: TestPage "VW List 14";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(IntF = filter(1 .. 2)) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_IntFilterRange()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open14() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open15()
    var
        Page: TestPage "VW List 15";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(KindF = const(Item)) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_EnumConst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open15() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open16()
    var
        Page: TestPage "VW List 16";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(KindF = filter(Item)) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_EnumFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open16() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open17()
    var
        Page: TestPage "VW List 17";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(KindF = filter("VW Kind"::Item)) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_EnumFilterTypeQualified()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open17() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open19()
    var
        Page: TestPage "VW List 19";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(KindF = filter(<> "VW Kind"::Item)) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_EnumFilterNotTypeQualified()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open19() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open22()
    var
        Page: TestPage "VW List 22";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(KindF = filter("VW Kind"::"Fixed Asset")) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_EnumFilterQuotedMember()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open22() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open23()
    var
        Page: TestPage "VW List 23";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(KindF = const("Fixed Asset")) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_EnumConstQuotedMember()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open23() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open24()
    var
        Page: TestPage "VW List 24";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(KindF = const("VW Kind"::Resource)) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_EnumConstTypeQualified()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open24() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open25()
    var
        Page: TestPage "VW List 25";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(DateF = filter('')) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_DateFilterBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open25() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open26()
    var
        Page: TestPage "VW List 26";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(DateF = filter('=''''')) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_DateFilterEqualsBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open26() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open27()
    var
        Page: TestPage "VW List 27";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(DateF = filter(<> '')) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_DateFilterNotBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open27() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open28()
    var
        Page: TestPage "VW List 28";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(BoolF = const(true)) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_BoolConstTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open28() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open29()
    var
        Page: TestPage "VW List 29";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(BoolF = const(false)) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_BoolConstFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open29() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open30()
    var
        Page: TestPage "VW List 30";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(BoolF = filter(true)) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_BoolFilterTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open30() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open31()
    var
        Page: TestPage "VW List 31";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(OptF = const(B)) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_OptionConst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open31() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open32()
    var
        Page: TestPage "VW List 32";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(OptF = filter(<> A)) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_OptionFilterNot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open32() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open33()
    var
        Page: TestPage "VW List 33";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(DecF = filter(> 0)) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_DecimalFilterPositive()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open33() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open35()
    var
        Page: TestPage "VW List 35";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(KindF = filter("VW Kind"::Item), CodeF = const('')) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_TwoConditionsTypeQualifiedEnumCode()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open35() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open36()
    var
        Page: TestPage "VW List 36";
    begin
        Page.OpenView();
        if Page.First() then
            repeat
                Capture.AddRow(Page."No.".Value());
            until not Page.Next();
    end;

    // CLAIM: SourceTableView = where(CodeF = const(''), IntF = const(Database::"VW Row"), KindF = filter(<> "VW Kind"::Item)) shows the rows and filters recorded below.
    [Test]
    procedure SourceTableView_ThreeConditionsDatabaseCodeEnum()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open36() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('S.filters'));
            Observer.Observe('view', Capture.Get('S.view'));
            Observer.Observe('viewCaptions', Capture.Get('S.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;
}

codeunit 96602 "VW Sub Page View Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Capture: Codeunit "VW Capture";

    local procedure Initialize()
    begin
        Capture.Seed();
        Capture.Reset();
    end;

    [TryFunction]
    local procedure Open01()
    var
        Page: TestPage "VW Host 01";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(CodeF = const('')) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_CodeConstBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open01() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open02()
    var
        Page: TestPage "VW Host 02";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(CodeF = filter('')) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_CodeFilterBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open02() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open03()
    var
        Page: TestPage "VW Host 03";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(CodeF = filter(<> '')) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_CodeFilterNotBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open03() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open04()
    var
        Page: TestPage "VW Host 04";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(CodeF = const('A')) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_CodeConstA()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open04() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open05()
    var
        Page: TestPage "VW Host 05";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(CodeF = filter('A|B')) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_CodeFilterOr()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open05() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open06()
    var
        Page: TestPage "VW Host 06";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(CodeF = filter('=''''')) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_CodeFilterEqualsBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open06() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open07()
    var
        Page: TestPage "VW Host 07";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(TextF = const('')) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_TextConstBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open07() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open08()
    var
        Page: TestPage "VW Host 08";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(TextF = filter(<> '')) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_TextFilterNotBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open08() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open09()
    var
        Page: TestPage "VW Host 09";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(IntF = const(Database::"VW Row")) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_IntConstDatabase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open09() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open10()
    var
        Page: TestPage "VW Host 10";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(IntF = filter(Database::"VW Row")) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_IntFilterDatabase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open10() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open11()
    var
        Page: TestPage "VW Host 11";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(IntF = filter(<> Database::"VW Row")) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_IntFilterNotDatabase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open11() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open12()
    var
        Page: TestPage "VW Host 12";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(IntF = filter(Database::"VW Row" | 1)) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_IntFilterDatabaseOrNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open12() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open13()
    var
        Page: TestPage "VW Host 13";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(IntF = const(0)) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_IntConstZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open13() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open14()
    var
        Page: TestPage "VW Host 14";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(IntF = filter(1 .. 2)) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_IntFilterRange()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open14() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open15()
    var
        Page: TestPage "VW Host 15";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(KindF = const(Item)) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_EnumConst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open15() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open16()
    var
        Page: TestPage "VW Host 16";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(KindF = filter(Item)) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_EnumFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open16() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open17()
    var
        Page: TestPage "VW Host 17";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(KindF = filter("VW Kind"::Item)) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_EnumFilterTypeQualified()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open17() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open19()
    var
        Page: TestPage "VW Host 19";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(KindF = filter(<> "VW Kind"::Item)) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_EnumFilterNotTypeQualified()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open19() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open22()
    var
        Page: TestPage "VW Host 22";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(KindF = filter("VW Kind"::"Fixed Asset")) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_EnumFilterQuotedMember()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open22() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open23()
    var
        Page: TestPage "VW Host 23";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(KindF = const("Fixed Asset")) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_EnumConstQuotedMember()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open23() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open24()
    var
        Page: TestPage "VW Host 24";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(KindF = const("VW Kind"::Resource)) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_EnumConstTypeQualified()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open24() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open25()
    var
        Page: TestPage "VW Host 25";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(DateF = filter('')) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_DateFilterBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open25() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open26()
    var
        Page: TestPage "VW Host 26";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(DateF = filter('=''''')) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_DateFilterEqualsBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open26() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open27()
    var
        Page: TestPage "VW Host 27";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(DateF = filter(<> '')) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_DateFilterNotBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open27() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open28()
    var
        Page: TestPage "VW Host 28";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(BoolF = const(true)) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_BoolConstTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open28() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open29()
    var
        Page: TestPage "VW Host 29";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(BoolF = const(false)) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_BoolConstFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open29() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open30()
    var
        Page: TestPage "VW Host 30";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(BoolF = filter(true)) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_BoolFilterTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open30() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open31()
    var
        Page: TestPage "VW Host 31";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(OptF = const(B)) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_OptionConst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open31() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open32()
    var
        Page: TestPage "VW Host 32";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(OptF = filter(<> A)) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_OptionFilterNot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open32() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open33()
    var
        Page: TestPage "VW Host 33";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(DecF = filter(> 0)) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_DecimalFilterPositive()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open33() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open35()
    var
        Page: TestPage "VW Host 35";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(KindF = filter("VW Kind"::Item), CodeF = const('')) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_TwoConditionsTypeQualifiedEnumCode()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open35() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open36()
    var
        Page: TestPage "VW Host 36";
    begin
        Page.OpenView();
        if Page.Lines.First() then
            repeat
                Capture.AddRow(Page.Lines."No.".Value());
            until not Page.Lines.Next();
    end;

    // CLAIM: SubPageView = where(CodeF = const(''), IntF = const(Database::"VW Row"), KindF = filter(<> "VW Kind"::Item)) shows the rows and filters recorded below.
    [Test]
    procedure SubPageView_ThreeConditionsDatabaseCodeEnum()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open36() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('V.filters'));
            Observer.Observe('view', Capture.Get('V.view'));
            Observer.Observe('viewCaptions', Capture.Get('V.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;
}

codeunit 96603 "VW Sub Page Link Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Capture: Codeunit "VW Capture";

    local procedure Initialize()
    begin
        Capture.Seed();
        Capture.Reset();
    end;

    [TryFunction]
    local procedure Open01()
    var
        Page: TestPage "VW Host 01";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = CodeF = const('') shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_CodeConstBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open01() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open02()
    var
        Page: TestPage "VW Host 02";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = CodeF = filter('') shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_CodeFilterBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open02() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open03()
    var
        Page: TestPage "VW Host 03";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = CodeF = filter(<> '') shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_CodeFilterNotBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open03() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open04()
    var
        Page: TestPage "VW Host 04";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = CodeF = const('A') shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_CodeConstA()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open04() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open05()
    var
        Page: TestPage "VW Host 05";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = CodeF = filter('A|B') shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_CodeFilterOr()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open05() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open06()
    var
        Page: TestPage "VW Host 06";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = CodeF = filter('=''''') shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_CodeFilterEqualsBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open06() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open07()
    var
        Page: TestPage "VW Host 07";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = TextF = const('') shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_TextConstBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open07() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open08()
    var
        Page: TestPage "VW Host 08";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = TextF = filter(<> '') shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_TextFilterNotBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open08() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open09()
    var
        Page: TestPage "VW Host 09";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = IntF = const(Database::"VW Row") shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_IntConstDatabase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open09() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open10()
    var
        Page: TestPage "VW Host 10";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = IntF = filter(Database::"VW Row") shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_IntFilterDatabase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open10() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open11()
    var
        Page: TestPage "VW Host 11";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = IntF = filter(<> Database::"VW Row") shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_IntFilterNotDatabase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open11() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open12()
    var
        Page: TestPage "VW Host 12";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = IntF = filter(Database::"VW Row" | 1) shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_IntFilterDatabaseOrNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open12() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open13()
    var
        Page: TestPage "VW Host 13";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = IntF = const(0) shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_IntConstZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open13() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open14()
    var
        Page: TestPage "VW Host 14";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = IntF = filter(1 .. 2) shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_IntFilterRange()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open14() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open15()
    var
        Page: TestPage "VW Host 15";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = KindF = const(Item) shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_EnumConst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open15() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open16()
    var
        Page: TestPage "VW Host 16";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = KindF = filter(Item) shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_EnumFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open16() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open17()
    var
        Page: TestPage "VW Host 17";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = KindF = filter("VW Kind"::Item) shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_EnumFilterTypeQualified()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open17() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open19()
    var
        Page: TestPage "VW Host 19";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = KindF = filter(<> "VW Kind"::Item) shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_EnumFilterNotTypeQualified()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open19() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open22()
    var
        Page: TestPage "VW Host 22";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = KindF = filter("VW Kind"::"Fixed Asset") shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_EnumFilterQuotedMember()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open22() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open23()
    var
        Page: TestPage "VW Host 23";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = KindF = const("Fixed Asset") shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_EnumConstQuotedMember()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open23() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open24()
    var
        Page: TestPage "VW Host 24";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = KindF = const("VW Kind"::Resource) shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_EnumConstTypeQualified()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open24() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open25()
    var
        Page: TestPage "VW Host 25";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = DateF = filter('') shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_DateFilterBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open25() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open26()
    var
        Page: TestPage "VW Host 26";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = DateF = filter('=''''') shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_DateFilterEqualsBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open26() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open27()
    var
        Page: TestPage "VW Host 27";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = DateF = filter(<> '') shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_DateFilterNotBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open27() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open28()
    var
        Page: TestPage "VW Host 28";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = BoolF = const(true) shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_BoolConstTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open28() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open29()
    var
        Page: TestPage "VW Host 29";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = BoolF = const(false) shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_BoolConstFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open29() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open30()
    var
        Page: TestPage "VW Host 30";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = BoolF = filter(true) shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_BoolFilterTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open30() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open31()
    var
        Page: TestPage "VW Host 31";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = OptF = const(B) shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_OptionConst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open31() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open32()
    var
        Page: TestPage "VW Host 32";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = OptF = filter(<> A) shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_OptionFilterNot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open32() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open33()
    var
        Page: TestPage "VW Host 33";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = DecF = filter(> 0) shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_DecimalFilterPositive()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open33() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open35()
    var
        Page: TestPage "VW Host 35";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = KindF = filter("VW Kind"::Item), CodeF = const('') shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_TwoConditionsTypeQualifiedEnumCode()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open35() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure Open36()
    var
        Page: TestPage "VW Host 36";
    begin
        Page.OpenView();
        if Page.Links.First() then
            repeat
                Capture.AddRow(Page.Links."No.".Value());
            until not Page.Links.Next();
    end;

    // CLAIM: SubPageLink = CodeF = const(''), IntF = const(Database::"VW Row"), KindF = filter(<> "VW Kind"::Item) shows the rows and filters recorded below.
    [Test]
    procedure SubPageLink_ThreeConditionsDatabaseCodeEnum()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();

        if Open36() then begin
            Observer.Observe('rows', Capture.Rows());
            Observer.Observe('filters', Capture.Get('L.filters'));
            Observer.Observe('view', Capture.Get('L.view'));
            Observer.Observe('viewCaptions', Capture.Get('L.viewCaptions'));
        end else
            Observer.ObserveError('open');
        Observer.Finish();
    end;
}
