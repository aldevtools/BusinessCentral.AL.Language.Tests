// @expect AL0162 | 'OnBeforeValidate' is not a valid trigger for this object type.
// A control bound to a page variable declares OnBeforeValidate.
page 50001 "MNC Page"
{
    PageType = Card;

    layout
    {
        area(Content)
        {
            field(VarName; NameText)
            {
                trigger OnBeforeValidate()
                begin
                end;
            }
        }
    }

    var
        NameText: Text[30];
}
