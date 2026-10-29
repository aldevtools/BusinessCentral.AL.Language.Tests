table 90530 "LT UV CP Entry"
{
    fields
    {
        field(1; "No."; Code[20]) { }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}

page 90531 "LT UV CP List"
{
    PageType = List;
    SourceTable = "LT UV CP Entry";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        ApplyEnabled := false;
    end;

    procedure IsApplyEnabled(): Boolean
    begin
        exit(ApplyEnabled);
    end;

    protected var
        ApplyEnabled: Boolean;
}

pageextension 90532 "LT UV CP List Ext" extends "LT UV CP List"
{
    trigger OnOpenPage()
    begin
        if CurrPage.ApplyEnabled then
            exit;
        CurrPage.ApplyEnabled := true;
    end;
}

codeunit 90533 "LT UV CurrPage Var"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure OpenPage_ExtensionAssignsProtectedVarThroughCurrPage()
    var
        Observer: Codeunit "Probe Observer";
        CPList: TestPage "LT UV CP List";
    begin
        asserterror CPList.OpenView();
        Observer.ObserveError('open');
        Observer.Finish();
    end;
}
