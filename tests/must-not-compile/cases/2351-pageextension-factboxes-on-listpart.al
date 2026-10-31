// @expect AL0270 | The control 'FactBoxes' is not found in the target 'MNC Y20 ListPart 2351'
// A page extension adds to area(FactBoxes) of a ListPart page that declares none (writer Y20, al-runner issue 6490). Card, List, Worksheet,
// Document, ListPlus, StandardDialog, ConfirmationDialog and NavigatePage pages accept it: tests/al-language/pageext/lt-bc-implicit-areas.
table 52351 "MNC Y20 Row2351"
{
    fields { field(1; K; Code[10]) { } }
    keys { key(PK; K) { Clustered = true; } }
}
page 52351 "MNC Y20 ListPart 2351"
{
    PageType = ListPart;
    SourceTable = "MNC Y20 Row2351";
    layout { area(Content) { group(G) { } } }
}
pageextension 52351 "MNC Y20 ListPart Ext 2351" extends "MNC Y20 ListPart 2351"
{
    layout
    {
        addfirst(FactBoxes)
        {
            systempart(Links; Links) { ApplicationArea = All; }
        }
    }
}
