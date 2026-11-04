// Migrated from AL Runner tests/runner-extras/testpage-setrecord (TsrSrc.al).
page 60846 "TSR Card"
{
    PageType = Card;
    SourceTable = "TSR Row";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Note; Rec.Note) { ApplicationArea = All; }
            }
        }
    }
}
