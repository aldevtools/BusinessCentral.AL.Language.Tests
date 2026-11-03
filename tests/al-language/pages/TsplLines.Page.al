// Fixture ListPart for TestPageSubpagePartConstFilter.al: the lines page every part on
// "TSPL Card" hosts. It declares no filter of its own -- everything the test observes about
// which rows are visible comes from the host's SubPageLink. "Header No." is on the page so a
// test can read what New() stamped onto a new row through the field(...) half of a link.
page 60322 "TSPL Lines"
{
    PageType = ListPart;
    SourceTable = "TSPL Line";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Header No."; Rec."Header No.") { ApplicationArea = All; }
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field("Table ID"; Rec."Table ID") { ApplicationArea = All; }
                field(Category; Rec.Category) { ApplicationArea = All; }
            }
        }
    }
}
