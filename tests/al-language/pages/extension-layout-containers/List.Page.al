// local object: the field shape, enum members or page layout/trigger definition is the behavior under test.
page 69017 "PAG Layout List"
{
    PageType = List;
    SourceTable = "ALT Universal";
    ApplicationArea = All;
    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Rec."Code Field") { ApplicationArea = All; }
                field(Description; Rec."Text Field") { ApplicationArea = All; }
            }
        }
    }
}
