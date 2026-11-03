// Fixtures of pages/lt-y45-list-caption-relation. The facts are in Y45ListCaptionRelation.al.
table 92882 "LT Y45 Ref"
{
    DataClassification = SystemMetadata;
    LookupPageId = "LT Y45 Ref List";
    DrillDownPageId = "LT Y45 Ref List";

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50]) { }
        field(3; Extra; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Extra) { }
        fieldgroup(Brick; "No.", Extra) { }
    }
}

table 92884 "LT Y45 Ref Dcf"
{
    DataClassification = SystemMetadata;
    DataCaptionFields = "No.", Name;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 92885 "LT Y45 Ref Desc"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 92883 "LT Y45 Cap Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; RefNo; Code[20]) { TableRelation = "LT Y45 Ref"; }
        field(3; Plain; Code[20]) { }
        field(4; RefDcf; Code[20]) { TableRelation = "LT Y45 Ref Dcf"; }
        field(5; RefDesc; Code[20]) { TableRelation = "LT Y45 Ref Desc"; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 92889 "LT Y45 Ref List"
{
    PageType = List;
    SourceTable = "LT Y45 Ref";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;
    Caption = 'Y45 Refs';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

page 92886 "LT Y45 Cap List"
{
    PageType = List;
    SourceTable = "LT Y45 Cap Row";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;
    Caption = 'Y45 Cap List';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(RefNo; Rec.RefNo) { ApplicationArea = All; }
                field(Plain; Rec.Plain) { ApplicationArea = All; }
            }
        }
    }
}

page 92887 "LT Y45 Cap List DCF"
{
    PageType = List;
    SourceTable = "LT Y45 Cap Row";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;
    Caption = 'Y45 Cap DCF';
    DataCaptionFields = RefNo;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(RefNo; Rec.RefNo) { ApplicationArea = All; }
                field(Plain; Rec.Plain) { ApplicationArea = All; }
            }
        }
    }
}

page 92888 "LT Y45 Cap Card DCF"
{
    PageType = Card;
    SourceTable = "LT Y45 Cap Row";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;
    Caption = 'Y45 Cap Card';
    DataCaptionFields = RefNo;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(RefNo; Rec.RefNo) { ApplicationArea = All; }
                field(Plain; Rec.Plain) { ApplicationArea = All; }
            }
        }
    }
}

page 92891 "LT Y45 Cap List Plain"
{
    PageType = List;
    SourceTable = "LT Y45 Cap Row";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;
    Caption = 'Y45 Cap Plain';
    DataCaptionFields = Plain;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(RefNo; Rec.RefNo) { ApplicationArea = All; }
                field(Plain; Rec.Plain) { ApplicationArea = All; }
            }
        }
    }
}

page 92892 "LT Y45 Cap List Two"
{
    PageType = List;
    SourceTable = "LT Y45 Cap Row";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;
    Caption = 'Y45 Cap Two';
    DataCaptionFields = RefNo, Plain;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(RefNo; Rec.RefNo) { ApplicationArea = All; }
                field(Plain; Rec.Plain) { ApplicationArea = All; }
            }
        }
    }
}

page 92893 "LT Y45 Cap List RefDcf"
{
    PageType = List;
    SourceTable = "LT Y45 Cap Row";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;
    Caption = 'Y45 Cap RefDcf';
    DataCaptionFields = RefDcf;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(RefDcf; Rec.RefDcf) { ApplicationArea = All; }
            }
        }
    }
}

page 92894 "LT Y45 Cap List RefDesc"
{
    PageType = List;
    SourceTable = "LT Y45 Cap Row";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;
    Caption = 'Y45 Cap RefDesc';
    DataCaptionFields = RefDesc;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(RefDesc; Rec.RefDesc) { ApplicationArea = All; }
            }
        }
    }
}
