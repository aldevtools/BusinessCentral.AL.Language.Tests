// Fixture ListPart for TestPageSubpagePartFieldLink.al over the SAME "PKFL Line" as
// "PKFL Lines" (60644), differing in exactly one property: PopulateAllFields = true. That is
// the second of the two escapes InitRecordFromFilters offers a non-primary-key field
// (the other being the caller naming the filter's group, which NavForm.NewRecord does not
// do), so this part and "PKFL Lines" isolate the property's effect from everything else.
page 60645 "PKFL Populate Lines"
{
    PageType = ListPart;
    SourceTable = "PKFL Line";
    PopulateAllFields = true;
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
