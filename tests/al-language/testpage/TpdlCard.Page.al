// Fixture host card for TestPagePartDraftLineLink.al. One part, linked on the line table's
// FIRST primary-key field, which is the shape of every document card in the Base Application
// (Sales Order -> Sales Lines on "Document Type"/"Document No.").
page 60998 "TPDL Card"
{
    PageType = Card;
    SourceTable = "TPDL Header";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "TPDL Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
            }
        }
    }
}
