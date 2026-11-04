// Fixture for codeunit 69140 "PVD Provider Tests". The Detail part reads "Line No." from the Lines
// part's current row (Provider), the way Sales Quote's Sales Line FactBox reads the sales lines.
page 69142 "PVD Header Card"
{
    PageType = Card;
    SourceTable = "PVD Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "PVD Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
            }
        }
        area(FactBoxes)
        {
            part(Detail; "PVD Detail Part")
            {
                ApplicationArea = All;
                Provider = Lines;
                SubPageLink = "Line Ref" = field("Line No.");
            }
        }
    }
}
