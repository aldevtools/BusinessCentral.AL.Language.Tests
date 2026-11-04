// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testpage-overview
// Scope: in-scope
// Fixtures used: this file declares reports 70150-70153, pages 70154-70163 and codeunits 70167-70168 of the PnG probes (run-object targets, request pages)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

report 70150 "LT PnG Rpt"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Items; "LT PnG Item")
        {
            RequestFilterFields = "No.", Name;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(ReqTextCtl; ReqText)
                {
                    ApplicationArea = All;
                }
                field(ReqNumCtl; ReqNum)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    protected var
        BaseProt: Text[30];

    var
        ReqText: Text[30];
        ReqNum: Integer;

    trigger OnInitReport()
    begin
        BaseProt := 'BaseInit';
        ReqText := 'TextInit';
        ReqNum := 3;
    end;

    trigger OnPreReport()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('Rpt.OnPreReport(' + BaseProt + '|' + ReqText + '|' + Format(ReqNum) + ')');
    end;
}

reportextension 70151 "LT PnG Rpt Ext" extends "LT PnG Rpt"
{
    requestpage
    {
        layout
        {
            addlast(Content)
            {
                field(ExtProtCtl; BaseProt)
                {
                    ApplicationArea = All;
                }
                field(ExtOwnCtl; ExtOwn)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        ExtOwn: Text[30];

    trigger OnPreReport()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('RptExt.OnPreReport(' + BaseProt + '|' + ExtOwn + ')');
    end;
}

report 70152 "LT PnG Rpt NoFilter"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Items; "LT PnG Item")
        {
            RequestFilterFields = "No.", Name;
        }
    }

    requestpage
    {
        ShowFilter = false;

        layout
        {
            area(Content)
            {
                field(OptCtl; OptText)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        OptText: Text[30];
}

report 70153 "LT PnG Rpt Filter"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Items; "LT PnG Item")
        {
            RequestFilterFields = "No.", Name;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(OptCtl; OptText)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        OptText: Text[30];
}

page 70154 "LT PnG Worksheet"
{
    PageType = Worksheet;
    SourceTable = "LT PnG Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
            }
        }
    }
}

page 70155 "LT PnG ListPlus"
{
    PageType = ListPlus;
    SourceTable = "LT PnG Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
            }
        }
    }
}

page 70156 "LT PnG Navigate"
{
    PageType = NavigatePage;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(TxtCtl; TxtVar) { ApplicationArea = All; }
        }
    }

    var
        TxtVar: Text[30];
}

page 70157 "LT PnG Confirm"
{
    PageType = ConfirmationDialog;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(TxtCtl; TxtVar) { ApplicationArea = All; }
        }
    }

    var
        TxtVar: Text[30];
}

page 70158 "LT PnG Prompt"
{
    PageType = PromptDialog;
    Extensible = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Prompt)
        {
            field(TxtCtl; TxtVar) { ApplicationArea = All; }
        }
    }

    var
        TxtVar: Text[30];
}

page 70159 "LT PnG Dlg"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(TxtCtl; TxtVar) { ApplicationArea = All; }
        }
    }

    var
        TxtVar: Text[30];
}

page 70160 "LT PnG No Type"
{
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(TxtCtl; TxtVar) { ApplicationArea = All; }
        }
    }

    var
        TxtVar: Text[30];
}

page 70161 "LT PnG Card View"
{
    PageType = Card;
    SourceTable = "LT PnG Item";
    SourceTableView = where(Qty = filter('>=2'));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
        }
    }
}

codeunit 70167 "LT PnG Run Cu"
{
    TableNo = "LT PnG Item";

    trigger OnRun()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('RunCu(' + Rec."No." + ')');
    end;
}

codeunit 70168 "LT PnG Run Cu Single"
{
    TableNo = "LT PnG Item";
    SingleInstance = true;

    trigger OnRun()
    var
        Log: Codeunit "LT PnG Log";
    begin
        Log.Add('RunCuSingle(' + Rec."No." + ')');
    end;
}

page 70162 "LT PnG RunObj Host"
{
    PageType = Card;
    SourceTable = "LT PnG Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunCard) { ApplicationArea = All; RunObject = page "LT PnG Card"; }
            action(RunList) { ApplicationArea = All; RunObject = page "LT PnG List"; }
            action(RunWorksheet) { ApplicationArea = All; RunObject = page "LT PnG Worksheet"; }
            action(RunListPlus) { ApplicationArea = All; RunObject = page "LT PnG ListPlus"; }
            action(RunNavigate) { ApplicationArea = All; RunObject = page "LT PnG Navigate"; }
            action(RunConfirm) { ApplicationArea = All; RunObject = page "LT PnG Confirm"; }
            action(RunPrompt) { ApplicationArea = All; RunObject = page "LT PnG Prompt"; }
            action(RunDialog) { ApplicationArea = All; RunObject = page "LT PnG Dlg"; }
            action(RunNoType) { ApplicationArea = All; RunObject = page "LT PnG No Type"; }
            action(RunCardOnRec) { ApplicationArea = All; RunObject = page "LT PnG Card"; RunPageOnRec = true; }
            action(RunCardLink) { ApplicationArea = All; RunObject = page "LT PnG List"; RunPageLink = "No." = field("No."); }
            action(RunCardView) { ApplicationArea = All; RunObject = page "LT PnG List"; RunPageView = where(Qty = filter('>1')); }
            action(RunCardEdit) { ApplicationArea = All; RunObject = page "LT PnG Card"; RunPageMode = Edit; }
            action(RunCardViewMode) { ApplicationArea = All; RunObject = page "LT PnG Card"; RunPageMode = View; }
            action(RunCardCreate) { ApplicationArea = All; RunObject = page "LT PnG Card"; RunPageMode = Create; }
            action(RunCardCreateOnRec) { ApplicationArea = All; RunObject = page "LT PnG Card"; RunPageMode = Create; RunPageOnRec = true; }
            action(RunCardCreateLink) { ApplicationArea = All; RunObject = page "LT PnG List"; RunPageMode = Create; RunPageLink = "No." = field("No."); }
            action(RunCardCreateView) { ApplicationArea = All; RunObject = page "LT PnG List"; RunPageMode = Create; RunPageView = where(Qty = filter('>1')); }
            action(RunViewListOnRec) { ApplicationArea = All; RunObject = page "LT PnG View List"; RunPageOnRec = true; }
            action(RunViewListLink) { ApplicationArea = All; RunObject = page "LT PnG View List"; RunPageLink = "No." = field("No."); }
            action(RunViewListView) { ApplicationArea = All; RunObject = page "LT PnG View List"; RunPageView = where(Qty = filter('>2')); }
            action(RunCuOnRec) { ApplicationArea = All; RunObject = codeunit "LT PnG Run Cu"; RunPageOnRec = true; }
            action(RunCuPlain) { ApplicationArea = All; RunObject = codeunit "LT PnG Run Cu"; }
            action(RunCuSingleOnRec) { ApplicationArea = All; RunObject = codeunit "LT PnG Run Cu Single"; RunPageOnRec = true; }
        }
    }
}

page 70163 "LT PnG RunObj Host Head"
{
    PageType = Card;
    SourceTable = "LT PnG Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec."Code") { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunCardOnRec) { ApplicationArea = All; RunObject = page "LT PnG Card"; RunPageOnRec = true; }
            action(RunCuOnRec) { ApplicationArea = All; RunObject = codeunit "LT PnG Run Cu"; RunPageOnRec = true; }
        }
    }
}
