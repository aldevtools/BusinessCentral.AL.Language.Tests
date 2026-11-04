// Fixture host card for TestPageSubpagePartFieldLink.al. Four parts over the header, three
// of them carrying the SAME SubPageLink -- "Header No." = field("No.") -- so that the only
// thing varying between those three is what sits underneath, and a fourth that changes only
// the LINK KIND:
//   Lines         "PKFL Line", primary key ("Line No.") -- the linked field is NOT in the key
//   PopLines      the same table through a part page that sets PopulateAllFields = true
//   ConstLines    the same table and the same non-key field, linked by const('H1') instead of
//                 field("No.") -- so LINK KIND is the only thing that differs from Lines
//   KeyedLines    "PKFL Keyed Line", primary key ("Header No.", "Line No.") -- it IS in the key
page 60647 "PKFL Card"
{
    PageType = Card;
    SourceTable = "PKFL Header";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "PKFL Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
            }
            part(PopLines; "PKFL Populate Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
            }
            part(ConstLines; "PKFL Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = const('H1');
            }
            part(KeyedLines; "PKFL Keyed Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
            }
        }
    }
}
