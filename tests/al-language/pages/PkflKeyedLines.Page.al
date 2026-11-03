// Fixture ListPart for TestPageSubpagePartFieldLink.al over "PKFL Keyed Line", whose primary
// key contains "Header No.". Same layout and same absence of page properties as
// "PKFL Lines" (60644), so the only difference between the two parts is the key shape of the
// table underneath.
page 60646 "PKFL Keyed Lines"
{
    PageType = ListPart;
    SourceTable = "PKFL Keyed Line";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Header No."; Rec."Header No.") { ApplicationArea = All; }
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}
