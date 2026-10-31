// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-datacaptionfields-property
// Scope: in-scope
// Fixtures used: none (objects for Y37ListCaptionTests.al, ids 92623 - 92637)
// Probe: gap cycle 3 spec C3-13 (the caption of a list whose record carries a filter on a data caption field). Own minimal shapes.
// BC versions: 27, 28, 29

table 92623 "LT Y37 Cap B"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Zone; Code[10]) { }
        field(3; "Area"; Code[10]) { }
        field(4; Dt; Date) { }
        field(5; Kind; Option) { OptionMembers = A,B; }
        field(6; "Item Filter"; Code[10]) { FieldClass = FlowFilter; }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 92624 "LT Y37 Cap B2"
{
    DataClassification = SystemMetadata;
    DataCaptionFields = Zone;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Zone; Code[10]) { }
        field(3; "Area"; Code[10]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 92625 "LT Y37 Cap HL"
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

table 92626 "LT Y37 Cap LL"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Doc No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Zone; Code[10]) { }
    }

    keys
    {
        key(PK; "Doc No.", "Line No.") { Clustered = true; }
    }
}

page 92627 "LT Y37 Cap LZ"
{
    PageType = List;
    SourceTable = "LT Y37 Cap B";
    Caption = 'C313 Zone List';
    DataCaptionFields = Zone;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Zone; Rec.Zone) { ApplicationArea = All; }
            }
        }
    }
}

page 92628 "LT Y37 Cap LN"
{
    PageType = List;
    SourceTable = "LT Y37 Cap B";
    Caption = 'C313 Plain List';
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Zone; Rec.Zone) { ApplicationArea = All; }
            }
        }
    }
}

page 92629 "LT Y37 Cap LT"
{
    PageType = List;
    SourceTable = "LT Y37 Cap B2";
    Caption = 'C313 Table DCF List';
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Zone; Rec.Zone) { ApplicationArea = All; }
            }
        }
    }
}

page 92630 "LT Y37 Cap LZA"
{
    PageType = List;
    SourceTable = "LT Y37 Cap B";
    Caption = 'C313 Zone Area List';
    DataCaptionFields = Zone, "Area";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Zone; Rec.Zone) { ApplicationArea = All; }
                field("Area"; Rec."Area") { ApplicationArea = All; }
            }
        }
    }
}

page 92631 "LT Y37 Cap WZ"
{
    PageType = Worksheet;
    SourceTable = "LT Y37 Cap B";
    Caption = 'C313 Zone Worksheet';
    DataCaptionFields = Zone;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Zone; Rec.Zone) { ApplicationArea = All; }
            }
        }
    }
}

page 92632 "LT Y37 Cap D"
{
    PageType = Document;
    SourceTable = "LT Y37 Cap HL";
    Caption = 'C313 Doc';
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "LT Y37 Cap LP")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }
}

page 92633 "LT Y37 Cap LP"
{
    PageType = ListPart;
    SourceTable = "LT Y37 Cap LL";
    Caption = 'C313 Lines';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Zone; Rec.Zone) { ApplicationArea = All; }
            }
        }
    }
}

page 92634 "LT Y37 Cap LG"
{
    PageType = List;
    SourceTable = "LT Y37 Cap B";
    SourceTableView = where(Zone = const(Z1));
    Caption = 'C313 View List';
    DataCaptionFields = Zone;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Zone; Rec.Zone) { ApplicationArea = All; }
            }
        }
    }
}

page 92635 "LT Y37 Cap LGO"
{
    PageType = List;
    SourceTable = "LT Y37 Cap B";
    Caption = 'C313 Group List';
    DataCaptionFields = Zone;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Zone; Rec.Zone) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange(Zone, 'Z1');
        Rec.FilterGroup(0);
    end;
}

page 92636 "LT Y37 Cap LD"
{
    PageType = List;
    SourceTable = "LT Y37 Cap B";
    Caption = 'C313 Date List';
    DataCaptionFields = Dt;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Dt; Rec.Dt) { ApplicationArea = All; }
            }
        }
    }
}

page 92637 "LT Y37 Cap LK"
{
    PageType = List;
    SourceTable = "LT Y37 Cap B";
    Caption = 'C313 Kind List';
    DataCaptionFields = Kind;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
            }
        }
    }
}
