// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-caption-method
// Scope: in-scope
// Fixtures used: TP Field Caption Row (60993), TP Ext Caption Host (67660), TP Ext Caption Ext (67660)
//
// A pageextension adds controls whose control name, bound expression and caption are all spelled
// differently, so TestPage.<field>.Caption() can only be satisfied by the right one of the three.
// Page 67660 itself declares only PK; every other control comes from pageextension 67660:
//   ExtDeclaredRecCtl   - Rec.Klass (field Caption = 'Severity'), control Caption = 'Ext Declared Severity'.
//   ExtUndeclaredRecCtl - Rec.Klass, no control Caption.
//   ExtDeclaredVarCtl   - page variable ExtDeclaredVar, control Caption = 'Ext Declared Var Caption'.
//   ExtUndeclaredVarCtl - page variable ExtUndeclaredVar, no Caption at all.
//   ExtSemiCtl          - page variable ExtSemiVar, a control Caption containing a semicolon.
//   ExtGroupedCtl       - inside an added group, page variable ExtGroupedVar, Caption = 'Ext Grouped Caption'.
//   ExtFlagCtl          - Boolean page variable ExtFlagVar, Caption = 'Ext Flag'.
//   ExtOptCtl           - Option page variable ExtOptVar (Alpha,Beta), Caption = 'Ext Option Caption',
//                         OptionCaption = 'Alpha Cap,Beta Cap'.
//
// Written by agent stma-auto-6 (Claude agent), an automated implementation agent acting on the
// account holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4913.

page 67660 "TP Ext Caption Host"
{
    PageType = Card;
    SourceTable = "TP Field Caption Row";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            field(PK; Rec.PK) { ApplicationArea = All; }
        }
    }
}

pageextension 67660 "TP Ext Caption Ext" extends "TP Ext Caption Host"
{
    layout
    {
        addlast(Content)
        {
            field(ExtDeclaredRecCtl; Rec.Klass) { ApplicationArea = All; Caption = 'Ext Declared Severity'; }
            field(ExtUndeclaredRecCtl; Rec.Klass) { ApplicationArea = All; }
            field(ExtDeclaredVarCtl; ExtDeclaredVar) { ApplicationArea = All; Caption = 'Ext Declared Var Caption'; }
            field(ExtUndeclaredVarCtl; ExtUndeclaredVar) { ApplicationArea = All; }
            field(ExtSemiCtl; ExtSemiVar) { ApplicationArea = All; Caption = 'Ext; Semi Caption'; }
            group(ExtGroup)
            {
                field(ExtGroupedCtl; ExtGroupedVar) { ApplicationArea = All; Caption = 'Ext Grouped Caption'; }
            }
            field(ExtFlagCtl; ExtFlagVar) { ApplicationArea = All; Caption = 'Ext Flag'; }
            field(ExtOptCtl; ExtOptVar)
            {
                ApplicationArea = All;
                Caption = 'Ext Option Caption';
                OptionCaption = 'Alpha Cap,Beta Cap';
            }
        }
    }

    var
        ExtDeclaredVar: Text[30];
        ExtUndeclaredVar: Text[30];
        ExtSemiVar: Text[30];
        ExtGroupedVar: Text[30];
        ExtFlagVar: Boolean;
        ExtOptVar: Option Alpha,Beta;
}
