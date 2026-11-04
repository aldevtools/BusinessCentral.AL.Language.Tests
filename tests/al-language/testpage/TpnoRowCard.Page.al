// Fixture for TestPageNeverOpened_Tests.al (codeunit 67040): a plain card over "TPNO Row".
page 67040 "TPNO Row Card"
{
    PageType = Card;
    SourceTable = "TPNO Row";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}
