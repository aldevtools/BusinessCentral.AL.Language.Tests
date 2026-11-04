// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: TP Field Caption Row (60993); the dependency app's page 61020 "ALT Modify Caption
//   Page" with its pageextension 61021, and report 61022 "ALT Modify Caption Report" with its
//   reportextension 61023 (tests/al-language-internals-fixture/ALTModifyCaption.al).
//
// Extensions whose modify() changes a control's Caption or OptionCaption, read by codeunit 67670:
//   * pageextensions 67670, 67673, 67675 and 67676 over page 67670, declared in THIS app;
//   * pageextensions 67671 and 60941 over the dependency app's page 61020;
//   * pageextension 67674 over Base Application page 7389 "Warehouse Reason Codes", which ships
//     precompiled: its Description control (field Caption 'Description') gets 'WRC Modified
//     Description';
//   * reportextension 67672 over report 67672, declared in this app.
// Page 67670's controls:
//   RenCtl   - Rec.Klass (field Caption 'Severity'), no control Caption; modify gives 'Modified Ren'.
//   VarCtl   - page variable, Caption 'Host Var'; modify gives 'Modified Var'.
//   OptCtl   - Option page variable (Alpha,Beta), Caption 'Host Option', OptionCaption
//              'Alpha Cap,Beta Cap'; modify gives Caption 'Modified Option' and OptionCaption
//              'Alpha Mod,Beta Mod'.
//   PlainCtl - page variable, Caption 'Host Plain'; nothing modifies it.
//   TwiceCtl - page variable, Caption 'Host Twice'; pageextension 67670 modifies it to
//              'First Ext Twice' and pageextension 67673, in the same app, to 'Second Ext Twice'.
//   Twice2Ctl - page variable, Caption 'Host Twice2'; pageextension 67676, declared FIRST and named
//              'TP Mod Cap AAA High', modifies it to 'High Id Twice2'; pageextension 67675,
//              declared after it and named 'TP Mod Cap ZZZ Low', to 'Low Id Twice2'. So object id,
//              declaration order and name order do not all point the same way.
// Page 61020's FxBoth2Ctl is modified by the dependency's pageextension 61021 and by this app's
// pageextension 60941, whose object id is LOWER than 61021's.
//
// Written by agent stma-auto-6 (Claude agent), an automated implementation agent acting on the
// account holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4928.

page 67670 "TP Modify Caption Host"
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
            field(RenCtl; Rec.Klass) { ApplicationArea = All; }
            field(VarCtl; HostVar) { ApplicationArea = All; Caption = 'Host Var'; }
            field(OptCtl; HostOpt) { ApplicationArea = All; Caption = 'Host Option'; OptionCaption = 'Alpha Cap,Beta Cap'; }
            field(PlainCtl; HostPlain) { ApplicationArea = All; Caption = 'Host Plain'; }
            field(TwiceCtl; HostTwice) { ApplicationArea = All; Caption = 'Host Twice'; }
            field(Twice2Ctl; HostTwice2) { ApplicationArea = All; Caption = 'Host Twice2'; }
        }
    }

    var
        HostVar: Text[30];
        HostOpt: Option Alpha,Beta;
        HostPlain: Text[30];
        HostTwice: Text[30];
        HostTwice2: Text[30];
}

pageextension 67670 "TP Modify Caption Host Ext" extends "TP Modify Caption Host"
{
    layout
    {
        modify(RenCtl) { Caption = 'Modified Ren'; }
        modify(VarCtl) { Caption = 'Modified Var'; }
        modify(OptCtl) { Caption = 'Modified Option'; OptionCaption = 'Alpha Mod,Beta Mod'; }
        modify(TwiceCtl) { Caption = 'First Ext Twice'; }
    }
}

pageextension 67673 "TP Modify Caption Host Ext 2" extends "TP Modify Caption Host"
{
    layout
    {
        modify(TwiceCtl) { Caption = 'Second Ext Twice'; }
    }
}

pageextension 67676 "TP Mod Cap AAA High" extends "TP Modify Caption Host"
{
    layout
    {
        modify(Twice2Ctl) { Caption = 'High Id Twice2'; }
    }
}

pageextension 67675 "TP Mod Cap ZZZ Low" extends "TP Modify Caption Host"
{
    layout
    {
        modify(Twice2Ctl) { Caption = 'Low Id Twice2'; }
    }
}

pageextension 60941 "TP Modify Caption Dep Low Ext" extends "ALT Modify Caption Page"
{
    layout
    {
        modify(FxBoth2Ctl) { Caption = 'Main Low Ext Both2'; }
    }
}

pageextension 67671 "TP Modify Caption Dep Ext" extends "ALT Modify Caption Page"
{
    layout
    {
        modify(FxTextCtl) { Caption = 'Main Ext Text'; }
        modify(FxOptCtl) { Caption = 'Main Ext Option'; OptionCaption = 'Red Mod,Green Mod'; }
        modify(FxBothCtl) { Caption = 'Main Ext Both'; }
    }
}

pageextension 67674 "TP Modify Caption WRC Ext" extends "Warehouse Reason Codes"
{
    layout
    {
        modify(Description) { Caption = 'WRC Modified Description'; }
    }
}

report 67672 "TP Modify Caption Report"
{
    ProcessingOnly = true;
    UsageCategory = Tasks;
    ApplicationArea = All;

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(ReqTextCtl; ReqText) { ApplicationArea = All; Caption = 'Request Text'; }
                field(ReqOptCtl; ReqOpt) { ApplicationArea = All; Caption = 'Request Option'; OptionCaption = 'Small,Large'; }
            }
        }
    }

    var
        ReqText: Text[30];
        ReqOpt: Option Small,Large;
}

reportextension 67672 "TP Modify Caption Report Ext" extends "TP Modify Caption Report"
{
    requestpage
    {
        layout
        {
            modify(ReqTextCtl) { Caption = 'Ext Request Text'; }
            modify(ReqOptCtl) { Caption = 'Ext Request Option'; OptionCaption = 'Smaller,Larger'; }
        }
    }
}
