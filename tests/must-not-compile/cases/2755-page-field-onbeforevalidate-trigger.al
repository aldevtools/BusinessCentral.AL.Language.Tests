// @expect AL0162 | 'OnBeforeValidate' is not a valid trigger for this object type.
// A control of a page (not a modify block of an extension) declares OnBeforeValidate.
table 50000 "MNC Table"
{
    fields { field(1; Id; Integer) { } field(2; Name; Text[30]) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

page 50001 "MNC Page"
{
    PageType = Card;
    SourceTable = "MNC Table";

    layout
    {
        area(Content)
        {
            field(Name; Rec.Name)
            {
                trigger OnBeforeValidate()
                begin
                end;
            }
        }
    }
}
