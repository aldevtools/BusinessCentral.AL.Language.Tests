// local object: the field shape, enum members or page layout/trigger definition is the behavior under test.
page 69029 "TPG Empty Host"
{
    Caption = 'Runner Repro Header';
    PageType = Card;
    SourceTable = "TPG Empty Header";
    layout
    {
        area(Content)
        {
            group(Data) { field(Code; Rec.Code) { ApplicationArea = All; } }
            part(Lines; "TPG Empty Lines") { ApplicationArea = All; SubPageLink = "Header Code" = field(Code); }
        }
    }
}
