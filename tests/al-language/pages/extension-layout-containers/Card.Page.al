// local object: the field shape, enum members or page layout/trigger definition is the behavior under test.
page 69012 "PAG Layout Card"
{
    PageType = Card;
    SourceTable = "ALT Universal";
    layout
    {
        area(Content) { group(Data) { field(Code; Rec."Code Field") { ApplicationArea = All; } field(Description; Rec."Text Field") { ApplicationArea = All; } } }
        area(FactBoxes) { part(Details; "PAG Layout Factbox") { ApplicationArea = All; SubPageLink = "Code Field" = field("Code Field"); } }
    }
}
