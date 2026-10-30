// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-caption-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: the bare assignment `Caption := '...'` in a page and in a page extension (not CurrPage.Caption). Facts: that it compiles and what
// TestPage.Caption() returns on open and after the code changes the caption again (record change, action).
// BC versions: 27-29

table 99810 "LT SS Cap Entry"
{
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Kind; Option) { OptionMembers = Normal,Cash; }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}

page 99810 "LT SS Cap Entries"
{
    PageType = List;
    SourceTable = "LT SS Cap Entry";
    Caption = 'Entries';
    ApplicationArea = All;
    UsageCategory = Lists;
    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Rename)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Caption := 'Renamed by action';
                end;
            }
        }
    }
    trigger OnOpenPage()
    begin
        Caption := 'Entries (base)';
    end;
}

page 99811 "LT SS Cap Plain"
{
    PageType = List;
    SourceTable = "LT SS Cap Entry";
    Caption = 'Plain';
    ApplicationArea = All;
    UsageCategory = Lists;
    layout { area(Content) { repeater(Lines) { field("No."; Rec."No.") { ApplicationArea = All; } } } }
}

pageextension 99810 "LT SS Cap Ent Ext" extends "LT SS Cap Entries"
{
    trigger OnAfterGetCurrRecord()
    begin
        if Rec.Kind = Rec.Kind::Cash then
            Caption := 'Cash Entries'
        else
            Caption := 'Other Entries';
    end;
}

pageextension 99811 "LT SS Cap Plain Ext" extends "LT SS Cap Plain"
{
    trigger OnOpenPage()
    begin
        Caption := 'Plain (extension)';
    end;
}

codeunit 99810 "LT SS Page Caption Assign"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Entry: Record "LT SS Cap Entry";
    begin
        Entry.DeleteAll();
        Entry.Init();
        Entry."No." := 'A';
        Entry.Kind := Entry.Kind::Normal;
        Entry.Insert();
        Entry."No." := 'B';
        Entry.Kind := Entry.Kind::Cash;
        Entry.Insert();
    end;

    [Test]
    procedure Caption_AssignedInPageAndExtension_List()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT SS Cap Entries";
    begin
        Seed();
        TP.OpenView();
        Observer.Observe('on_open', TP.Caption());
        TP.First();
        Observer.Observe('row_a', TP.Caption());
        TP.Next();
        Observer.Observe('row_b', TP.Caption());
        TP.Previous();
        Observer.Observe('row_a_again', TP.Caption());
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Caption_AssignedInAction()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT SS Cap Entries";
    begin
        Seed();
        TP.OpenView();
        TP.Rename.Invoke();
        Observer.Observe('after_action', TP.Caption());
        TP.Next();
        Observer.Observe('after_next', TP.Caption());
        TP.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Caption_AssignedOnlyInExtensionOnOpen()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT SS Cap Plain";
    begin
        Seed();
        TP.OpenView();
        Observer.Observe('on_open', TP.Caption());
        TP.Close();
        Observer.Finish();
    end;
}
