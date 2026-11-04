// local object: the field shape, enum members or page layout/trigger definition is the behavior under test.
page 69017 "PAG Layout List"
{
    PageType = List;
    SourceTable = "PAG Layout Row";
    ApplicationArea = All;
    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }
}
