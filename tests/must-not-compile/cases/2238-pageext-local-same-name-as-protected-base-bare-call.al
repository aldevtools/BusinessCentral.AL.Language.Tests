// @expect AL0196 | The call is ambiguous between the method 'Prot()' defined in PageExtension 'MNC Base Page Ext' by the extension 'Must Not Compile by AL Language (1.0.0.0)' and the method 'Prot()' defined in Page 'MNC Base Page' by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// A page extension declares a local procedure with the name of a protected procedure of its base page in the same app (declaring it compiles) and calls it by its bare name: the call is ambiguous.
page 50001 "MNC Base Page"
{
    PageType = Card;

    protected procedure Prot()
    begin
    end;
}

pageextension 50002 "MNC Base Page Ext" extends "MNC Base Page"
{
    local procedure Prot()
    begin
    end;

    trigger OnOpenPage()
    begin
        Prot();
    end;
}
