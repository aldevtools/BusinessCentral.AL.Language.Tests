// Migrated from AL Runner tests/runner-extras/testpage-record-triggers (TrtSrc.al).
/// <summary>A card whose OnInsertRecord vetoes the insert by returning false.</summary>
page 60842 "TRT Card No Insert"
{
    PageType = Card;
    SourceTable = "TRT Row";
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

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        exit(false);
    end;
}
