// @expect AL0270 | The control 'FactBoxes' is not found in the target 'MNC Y20 RoleCenter 2353'
// A page extension adds to area(FactBoxes) of a RoleCenter page that declares none (writer Y20, al-runner issue 6490). Card, List, Worksheet,
// Document, ListPlus, StandardDialog, ConfirmationDialog and NavigatePage pages accept it: tests/al-language/pageext/lt-bc-implicit-areas.
page 52353 "MNC Y20 RoleCenter 2353"
{
    PageType = RoleCenter;

    layout { area(Content) { group(G) { } } }
}
pageextension 52353 "MNC Y20 RoleCenter Ext 2353" extends "MNC Y20 RoleCenter 2353"
{
    layout
    {
        addfirst(FactBoxes)
        {
            systempart(Links; Links) { ApplicationArea = All; }
        }
    }
}
