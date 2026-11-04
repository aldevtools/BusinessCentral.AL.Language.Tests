// @expect AL0196 | The call is ambiguous between the method 'Pub()' defined in PageExtension 'MNC Base Page Ext' by the extension 'Must Not Compile by AL Language (1.0.0.0)' and the method 'Pub()' defined in Page 'MNC Base Page' by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// Same as 2238 for a public base procedure.
page 50001 "MNC Base Page"
{
    PageType = Card;

    procedure Pub()
    begin
    end;
}

pageextension 50002 "MNC Base Page Ext" extends "MNC Base Page"
{
    local procedure Pub()
    begin
    end;

    trigger OnOpenPage()
    begin
        Pub();
    end;
}
