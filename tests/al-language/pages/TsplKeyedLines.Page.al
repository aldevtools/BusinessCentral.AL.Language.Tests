// Fixture ListPart for TestPageSubpagePartConstFilter.al over "TSPL Keyed Line", whose
// primary key includes Kind. It declares no filter of its own -- everything the test
// observes comes from the host's SubPageLink.
page 60326 "TSPL Keyed Lines"
{
    PageType = ListPart;
    SourceTable = "TSPL Keyed Line";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Header No."; Rec."Header No.") { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}
