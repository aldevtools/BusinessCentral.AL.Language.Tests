// Fixture ListPart for TestPageSubpagePartFieldLink.al over "PKFL Line", whose primary key
// does NOT contain "Header No.". It declares no filter and no properties of its own --
// everything the test observes comes from the host's SubPageLink.
page 60644 "PKFL Lines"
{
    PageType = ListPart;
    SourceTable = "PKFL Line";
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
