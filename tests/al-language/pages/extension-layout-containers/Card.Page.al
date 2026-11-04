// local object: the field shape, enum members or page layout/trigger definition is the behavior under test.
page 69012 "PAG Layout Card"
{
    PageType = Card;
    SourceTable = "PAG Layout Row";
    layout
    {
        area(Content) { group(Data) { field(Code; Rec.Code) { ApplicationArea = All; } field(Description; Rec.Description) { ApplicationArea = All; } } }
        area(FactBoxes) { part(Details; "PAG Layout Factbox") { ApplicationArea = All; SubPageLink = Code = field(Code); } }
    }
}
