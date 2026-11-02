// @expect AL0271 | The action 'Category_Category3' is not found in the target 'MNC Y64 Card'
// @expect AL0271 | The action 'Category_Category21' is not found in the target 'MNC Y64 Card'
// The implicit promoted category groups a page extension can name are Category_New, Category_Process, Category_Report and Category_Category4 to
// Category_Category20 (al-runner issue 6646): Category_Category3 and Category_Category21 do not exist (AL0271). Category_Category5 on a page that
// does not declare it: tests/al-language/pages/lt-up-page-ext/Y64PromotedImplicit.al.
table 52628 "MNC Y64 Row" { fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }
page 52628 "MNC Y64 Card" { PageType = Card; SourceTable = "MNC Y64 Row"; layout { area(Content) { field(Id; Rec.Id) { } } } }
pageextension 52629 "MNC Y64 Card Ext" extends "MNC Y64 Card"
{
    actions
    {
        modify(Category_Category3) { Caption = 'Three'; }
        modify(Category_Category21) { Caption = 'Twenty-one'; }
    }
}
