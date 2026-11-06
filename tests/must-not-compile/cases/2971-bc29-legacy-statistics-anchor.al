// @from 29
// @expect AL0271 | The action 'Statistics' is not found in the target 'Sales Order List'
// BC29 no longer exposes the legacy action. Verified with the official AL compiler and BC29 symbols.
pageextension 50170 "MNC Legacy Stats Anchor" extends "Sales Order List"
{
    actions { addafter(Statistics) { action(NeutralMarker) { ApplicationArea = All; trigger OnAction() begin end; } } }
}
