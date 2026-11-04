// Fixture for codeunit 69140 "PVD Provider Tests": the part that is linked through a Provider.
page 69141 "PVD Detail Part"
{
    PageType = ListPart;
    SourceTable = "PVD Detail";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Details)
            {
                field(LineRef; Rec."Line Ref") { ApplicationArea = All; }
                field(Info; Rec.Info) { ApplicationArea = All; }
            }
        }
    }
}
