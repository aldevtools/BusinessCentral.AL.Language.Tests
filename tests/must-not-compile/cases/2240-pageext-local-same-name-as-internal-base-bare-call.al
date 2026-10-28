// @expect AL0196 | The call is ambiguous between the method 'Int()' defined in PageExtension 'MNC Base Page Ext' by the extension 'Must Not Compile by AL Language (1.0.0.0)' and the method 'Int()' defined in Page 'MNC Base Page' by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// Same as 2238 for an internal base procedure.
page 50001 "MNC Base Page"
{
    PageType = Card;

    internal procedure Int()
    begin
    end;
}

pageextension 50002 "MNC Base Page Ext" extends "MNC Base Page"
{
    local procedure Int()
    begin
    end;

    trigger OnOpenPage()
    begin
        Int();
    end;
}
