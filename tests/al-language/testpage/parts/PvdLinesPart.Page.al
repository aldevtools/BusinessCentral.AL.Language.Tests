// Fixture for codeunit 69140 "PVD Provider Tests": the Provider part.
page 69140 "PVD Lines Part"
{
    PageType = ListPart;
    SourceTable = "PVD Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(HeaderNo; Rec."Header No.") { ApplicationArea = All; }
                field(LineNo; Rec."Line No.") { ApplicationArea = All; }
            }
        }
    }
}
