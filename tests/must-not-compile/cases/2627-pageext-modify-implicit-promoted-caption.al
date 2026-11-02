// @expect AL0124 | The property 'Caption' cannot be used in this context. Verify the property is available for the current object type.
// modify() of the implicit actionref <Action>_Promoted of a legacy-promoted action takes Visible, not Caption (al-runner issue 6647; AL0124).
// Visible and addafter/addbefore on it: tests/al-language/pages/lt-up-page-ext/Y64PromotedImplicit.al.
table 52632 "MNC Y64 Row" { fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }
page 52632 "MNC Y64 Card"
{
    PageType = Card;
    SourceTable = "MNC Y64 Row";
    layout { area(Content) { field(Id; Rec.Id) { } } }
    actions { area(Processing) { action("My Action") { Promoted = true; PromotedCategory = Process; trigger OnAction() begin end; } } }
}
pageextension 52633 "MNC Y64 Card Ext" extends "MNC Y64 Card"
{
    actions
    {
        modify("My Action_Promoted") { Caption = 'Other'; }
    }
}
