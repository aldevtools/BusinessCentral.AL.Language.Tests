// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-gotorecord-method
// Scope: in-scope
// Fixtures used: none (self-contained)
//
// GoToRecord when the source table has two fields sharing the same caption -- legal AL and
// common on older tables. Companion to codeunit 60697 "Test Page GoToRecord Tests", which
// covers the single-unambiguous-caption case; this covers a table whose primary key resolution
// must not depend on caption text at all, including the not-found path.

table 60040 "Test GoToRecord DupCap Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Attribute ID';
            DataClassification = CustomerContent;
        }
        field(2; "Attribute Entry ID"; Integer)
        {
            Caption = 'Attribute ID';
            DataClassification = CustomerContent;
        }
        field(3; Descr; Text[50])
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}

table 60041 "Test GoToRecord DupCap CK Row"
{
    // Composite-primary-key variant: BOTH key fields share the caption "Attribute ID".
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Config No."; Code[20])
        {
            Caption = 'Configuration No.';
            DataClassification = CustomerContent;
        }
        field(2; "Attribute Entry ID"; Integer)
        {
            Caption = 'Attribute ID';
            DataClassification = CustomerContent;
        }
        field(3; "Entry No."; Integer)
        {
            Caption = 'Attribute ID';
            DataClassification = CustomerContent;
        }
        field(4; Descr; Text[50])
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Config No.", "Attribute Entry ID", "Entry No.")
        {
            Clustered = true;
        }
    }
}

page 60042 "Test GoToRecord DupCap List"
{
    PageType = List;
    SourceTable = "Test GoToRecord DupCap Row";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field(Descr; Rec.Descr)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}

page 60043 "Test GoToRecord DupCap CK List"
{
    PageType = List;
    SourceTable = "Test GoToRecord DupCap CK Row";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Descr; Rec.Descr)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
