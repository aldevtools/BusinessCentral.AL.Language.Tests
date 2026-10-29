// @expect AL0440 | The Page 'MNC Base Page' already defines a method called 'Pub' with the same parameter types in 'Must Not Compile by AL Language (1.0.0.0)'.
// A page extension declares a protected procedure with the name and parameters of a public procedure of its base page.
page 50001 "MNC Base Page"
{
    PageType = Card;

    procedure Pub()
    begin
    end;
}

pageextension 50002 "MNC Base Page Ext" extends "MNC Base Page"
{
    protected procedure Pub()
    begin
    end;
}
