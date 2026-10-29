// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 90498, pages 90499 and 90501, page extensions 90500 and 90502, codeunit 90506
// Probe (writer UP):
//   1. al-runner issue 6219: a page extension reads and assigns the base page's protected var through CurrPage.<var>, and through the unqualified
//      name; the value the base page sees (a TestPage action's Enabled, a base procedure).
//   The promoted category half (al-runner issue 6217) is in UpPromotedCategories.al next to this file.
// BC versions: 27-29

table 90498 "LT UP Page Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

page 90499 "LT UP Protected Var List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT UP Page Row";

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.") { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Apply)
            {
                Caption = 'Apply';
                Enabled = ApplyEnabled;
                trigger OnAction()
                begin
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        ApplyEnabled := false;
        Seen := 'base-open';
    end;

    procedure IsApplyEnabled(): Boolean
    begin
        exit(ApplyEnabled);
    end;

    protected var
        ApplyEnabled: Boolean;
        Seen: Text;
}

pageextension 90500 "LT UP Protected Var Ext" extends "LT UP Protected Var List"
{
    trigger OnOpenPage()
    begin
        if CurrPage.ApplyEnabled then
            exit;
        Seen += '|ext-before=' + Format(CurrPage.ApplyEnabled);
        CurrPage.ApplyEnabled := true;
        Seen += '|ext-after=' + Format(ApplyEnabled);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Caption := Seen;
    end;
}

page 90501 "LT UP Unqualified Var List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT UP Page Row";

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.") { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Apply)
            {
                Caption = 'Apply';
                Enabled = ApplyEnabled;
                trigger OnAction()
                begin
                end;
            }
        }
    }

    procedure IsApplyEnabled(): Boolean
    begin
        exit(ApplyEnabled);
    end;

    protected var
        ApplyEnabled: Boolean;
}

pageextension 90502 "LT UP Unqualified Var Ext" extends "LT UP Unqualified Var List"
{
    trigger OnOpenPage()
    begin
        ApplyEnabled := true;
    end;
}

codeunit 90506 "LT UP Page Ext Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeedRow()
    var
        Row: Record "LT UP Page Row";
    begin
        Row.DeleteAll();
        Row."No." := 'A';
        Row.Insert();
    end;

    [Test]
    procedure UP_PageExt_AssignsProtectedVarThroughCurrPage()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT UP Protected Var List";
    begin
        SeedRow();
        Pg.OpenView();
        Observer.Observe('apply enabled', Format(Pg.Apply.Enabled()));
        Observer.Observe('caption', Pg.Caption());
        Pg.Close();
        Observer.Expect('apply enabled', 'Yes');
        Observer.Expect('caption', 'base-open|ext-before=No|ext-after=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure UP_PageExt_AssignsProtectedVarUnqualified()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT UP Unqualified Var List";
    begin
        SeedRow();
        Pg.OpenView();
        Observer.Observe('apply enabled', Format(Pg.Apply.Enabled()));
        Pg.Close();
        Observer.Expect('apply enabled', 'Yes');
        Observer.Verify();
    end;
}
