// @expect AL0270 | The control 'FactBoxes' is not found in the target 'MNC Y20 CardPart 2352'
// A page extension adds to area(FactBoxes) of a CardPart page that declares none (writer Y20, al-runner issue 6490). Card, List, Worksheet,
// Document, ListPlus, StandardDialog, ConfirmationDialog and NavigatePage pages accept it: tests/al-language/pageext/lt-bc-implicit-areas.
table 52352 "MNC Y20 Row2352"
{
    fields { field(1; K; Code[10]) { } }
    keys { key(PK; K) { Clustered = true; } }
}
page 52352 "MNC Y20 CardPart 2352"
{
    PageType = CardPart;
    SourceTable = "MNC Y20 Row2352";
    layout { area(Content) { group(G) { } } }
}
pageextension 52352 "MNC Y20 CardPart Ext 2352" extends "MNC Y20 CardPart 2352"
{
    layout
    {
        addfirst(FactBoxes)
        {
            systempart(Links; Links) { ApplicationArea = All; }
        }
    }
}
