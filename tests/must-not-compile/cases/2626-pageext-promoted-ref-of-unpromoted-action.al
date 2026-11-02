// @expect AL0271 | The action 'Plain_Promoted' is not found in the target 'MNC Y64 Card'
// Only an action with the legacy Promoted = true gets the implicit actionref <Action>_Promoted (al-runner issue 6647): modify() of
// Plain_Promoted, where Plain is not promoted, is AL0271. The promoted form: tests/al-language/pages/lt-up-page-ext/Y64PromotedImplicit.al.
table 52630 "MNC Y64 Row" { fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }
page 52630 "MNC Y64 Card"
{
    PageType = Card;
    SourceTable = "MNC Y64 Row";
    layout { area(Content) { field(Id; Rec.Id) { } } }
    actions { area(Processing) { action(Plain) { trigger OnAction() begin end; } } }
}
pageextension 52631 "MNC Y64 Card Ext" extends "MNC Y64 Card"
{
    actions
    {
        modify(Plain_Promoted) { Visible = false; }
    }
}
