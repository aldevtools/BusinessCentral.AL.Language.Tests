// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-caption-method
// Scope: in-scope
// Fixtures used: TP Field Caption Row (60993), TP Var Control Caption (67640),
//   TP Rec Control Caption (67641)
//
// Controls whose control name, bound expression and caption are all spelled differently, so
// TestPage.<field>.Caption() can only be satisfied by the right one of the three:
// Page 67640, which has no source table, so its page-variable controls are editable:
//   DeclaredCtl   - page variable DeclaredVar, control Caption = 'Declared Var Caption'.
//   UndeclaredCtl - page variable UndeclaredVar, no Caption at all.
//   FlagCtl       - Boolean page variable FlagVar, control Caption = 'Declared Flag'.
//   OptCtl        - Option page variable OptVar, control Caption = 'My Option Caption'.
// Page 67641, over a source table:
//   RenamedKlass  - Rec.Klass (field Caption = 'Severity'), no control Caption.
//   RenamedPK     - Rec.PK (no field Caption), no control Caption.

page 67640 "TP Var Control Caption"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            field(DeclaredCtl; DeclaredVar) { ApplicationArea = All; Caption = 'Declared Var Caption'; }
            field(UndeclaredCtl; UndeclaredVar) { ApplicationArea = All; }
            field(FlagCtl; FlagVar) { ApplicationArea = All; Caption = 'Declared Flag'; }
            field(OptCtl; OptVar)
            {
                ApplicationArea = All;
                Caption = 'My Option Caption';
                OptionCaption = 'Alpha Cap,Beta Cap';
            }
        }
    }

    var
        DeclaredVar: Text[30];
        UndeclaredVar: Text[30];
        FlagVar: Boolean;
        OptVar: Option Alpha,Beta;
}

page 67641 "TP Rec Control Caption"
{
    PageType = Card;
    SourceTable = "TP Field Caption Row";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            field(RenamedKlass; Rec.Klass) { ApplicationArea = All; }
            field(RenamedPK; Rec.PK) { ApplicationArea = All; }
        }
    }
}
