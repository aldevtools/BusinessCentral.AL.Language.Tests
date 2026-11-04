// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-promoted-actions
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 95650, pages 95651-95653, page extensions 95673-95675, SingleInstance log
//   95654 (used only by test codeunit 95655)
// Probe (al-runner issue 6962): a page extension that only modifies a standard promoted category group (Category_New, Category_Process,
//   Category_Report) with Caption (the form the conversion of PromotedActionCategories writes, with a Comment) or ShowAs, on a base page that
//   does not declare the group and to which the extension adds nothing. Page 95651 declares Category_Process and Category_Report in
//   area(Promoted) but not Category_New; page 95652 promotes the legacy way (Promoted, PromotedCategory = Process and Report); page 95653 has no
//   actions section. The TestPage opens; the actions and actionrefs of the page are read (Visible, Enabled) and invoked.
// local object: the pages and page extensions are under test (their promoted groups); the log must be owned by one test codeunit
// BC versions: 27-29

table 95650 "LT SCM Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 95651 "LT SCM Declared Card"
{
    PageType = Card;
    SourceTable = "LT SCM Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ProcessAct)
            {
                ApplicationArea = All;
                Caption = 'Process Act';
                trigger OnAction()
                var
                    Log: Codeunit "LT SCM Log";
                begin
                    Log.Add('process');
                end;
            }
            action(ReportAct)
            {
                ApplicationArea = All;
                Caption = 'Report Act';
                trigger OnAction()
                var
                    Log: Codeunit "LT SCM Log";
                begin
                    Log.Add('report');
                end;
            }
            action(PlainAct)
            {
                ApplicationArea = All;
                Caption = 'Plain Act';
                trigger OnAction()
                var
                    Log: Codeunit "LT SCM Log";
                begin
                    Log.Add('plain');
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(ProcessAct_Promoted; ProcessAct) { }
            }
            group(Category_Report)
            {
                Caption = 'Report';
                actionref(ReportAct_Promoted; ReportAct) { }
            }
        }
    }
}

pageextension 95673 "LT SCM Declared Ext" extends "LT SCM Declared Card"
{
    actions
    {
        modify(Category_New)
        {
            Caption = 'New', Comment = 'Generated from the PromotedActionCategories property index 0.';
        }
        modify(Category_Process)
        {
            Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';
        }
        modify(Category_Report)
        {
            Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
        }
    }
}

page 95652 "LT SCM Legacy Card"
{
    PageType = Card;
    SourceTable = "LT SCM Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ProcessAct)
            {
                ApplicationArea = All;
                Caption = 'Process Act';
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                trigger OnAction()
                var
                    Log: Codeunit "LT SCM Log";
                begin
                    Log.Add('legacy process');
                end;
            }
            action(ReportAct)
            {
                ApplicationArea = All;
                Caption = 'Report Act';
                Promoted = true;
                PromotedCategory = Report;
                trigger OnAction()
                var
                    Log: Codeunit "LT SCM Log";
                begin
                    Log.Add('legacy report');
                end;
            }
        }
    }
}

pageextension 95674 "LT SCM Legacy Ext" extends "LT SCM Legacy Card"
{
    actions
    {
        modify(Category_New)
        {
            Caption = 'New', Comment = 'Generated from the PromotedActionCategories property index 0.';
        }
        modify(Category_Process)
        {
            Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';
        }
        modify(Category_Report)
        {
            Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
        }
    }
}

page 95653 "LT SCM Bare Card"
{
    PageType = Card;
    SourceTable = "LT SCM Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
        }
    }
}

pageextension 95675 "LT SCM Bare Ext" extends "LT SCM Bare Card"
{
    actions
    {
        addlast(Processing)
        {
            action(ExtAct)
            {
                ApplicationArea = All;
                Caption = 'Ext Act';
                trigger OnAction()
                var
                    Log: Codeunit "LT SCM Log";
                begin
                    Log.Add('ext');
                end;
            }
        }
        modify(Category_New)
        {
            ShowAs = SplitButton;
        }
        modify(Category_Process)
        {
            Caption = 'Process';
        }
        modify(Category_Report)
        {
            ShowAs = Standard;
        }
    }
}

codeunit 95654 "LT SCM Log"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Reset()
    begin
        Lines := '';
    end;

    procedure Add(Line: Text)
    begin
        if Lines <> '' then
            Lines += ';';
        Lines += Line;
    end;

    procedure Dump(): Text
    begin
        exit(Lines);
    end;
}

codeunit 95655 "LT SCM Tests"
{
    Subtype = Test;

    var
        Log: Codeunit "LT SCM Log";

    local procedure Start()
    var
        Row: Record "LT SCM Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Log.Reset();
    end;

    [Test]
    procedure ModifyStandardCategoryCaption_DeclaredPromotedArea_ActionsRun()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT SCM Declared Card";
    begin
        Start();
        P.OpenView();
        Observer.Observe('process visible', Format(P.ProcessAct.Visible()));
        Observer.Observe('process enabled', Format(P.ProcessAct.Enabled()));
        Observer.Observe('report visible', Format(P.ReportAct.Visible()));
        Observer.Observe('plain visible', Format(P.PlainAct.Visible()));
        P.ProcessAct.Invoke();
        P.ReportAct.Invoke();
        P.PlainAct.Invoke();
        Observer.Observe('log', Log.Dump());
        Observer.Observe('id', P.IdCtl.Value());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure ModifyStandardCategoryCaption_LegacyPromoted_ActionsRun()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT SCM Legacy Card";
    begin
        Start();
        P.OpenView();
        Observer.Observe('process visible', Format(P.ProcessAct.Visible()));
        Observer.Observe('process enabled', Format(P.ProcessAct.Enabled()));
        Observer.Observe('report visible', Format(P.ReportAct.Visible()));
        P.ProcessAct.Invoke();
        P.ReportAct.Invoke();
        Observer.Observe('log', Log.Dump());
        Observer.Observe('id', P.IdCtl.Value());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure ModifyStandardCategoryShowAs_PageWithoutActions_ExtensionActionRuns()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT SCM Bare Card";
    begin
        Start();
        P.OpenView();
        Observer.Observe('ext visible', Format(P.ExtAct.Visible()));
        Observer.Observe('ext enabled', Format(P.ExtAct.Enabled()));
        P.ExtAct.Invoke();
        Observer.Observe('log', Log.Dump());
        Observer.Observe('id', P.IdCtl.Value());
        P.Close();
        Observer.Finish();
    end;
}
