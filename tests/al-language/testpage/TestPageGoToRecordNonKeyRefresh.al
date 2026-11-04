// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-gotorecord-method
// Scope: in-scope
// Fixtures used: none (self-contained)
//
// Whether TestPage.GoToRecord's not-found path -- positioned on a row that is NOT the last
// row a forward not-found scan visits, then probed with an absent key -- leaves the page's
// non-key fields reading the ORIGINALLY POSITIONED row's own values, or something else
// (e.g. the last-scanned row's stale values). Companion to codeunit 60044 "Test GoToRecord
// DupCap Tests" (#122), which only asserted the KEY field and (for its arm) a row that
// happened to be the last one scanned.

table 60045 "Test GTR NonKeyRefresh Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[10])
        {
            DataClassification = CustomerContent;
        }
        field(2; Descr; Text[50])
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }
}

page 60046 "Test GTR NonKeyRefresh List"
{
    PageType = List;
    SourceTable = "Test GTR NonKeyRefresh Row";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.")
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
