// @expect AL0270 | The control 'FactBoxes' is not found in the target 'MNC Y20 HeadlinePart 2354'
// A page extension adds to area(FactBoxes) of a HeadlinePart page that declares none (writer Y20, al-runner issue 6490). Card, List, Worksheet,
// Document, ListPlus, StandardDialog, ConfirmationDialog and NavigatePage pages accept it: tests/al-language/pageext/lt-bc-implicit-areas.
table 52354 "MNC Y20 Row2354"
{
    fields { field(1; K; Code[10]) { } }
    keys { key(PK; K) { Clustered = true; } }
}
page 52354 "MNC Y20 HeadlinePart 2354"
{
    PageType = HeadlinePart;
    SourceTable = "MNC Y20 Row2354";
    layout { area(Content) { group(G) { } } }
}
pageextension 52354 "MNC Y20 HeadlinePart Ext 2354" extends "MNC Y20 HeadlinePart 2354"
{
    layout
    {
        addfirst(FactBoxes)
        {
            systempart(Links; Links) { ApplicationArea = All; }
        }
    }
}
