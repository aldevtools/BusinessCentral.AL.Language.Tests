// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Assert (60021), Base Application page 9 "Languages", and the objects below.
//
// CLAIM, for a part that a pageextension adds, on a source host page and on a precompiled one:
//   1. It opens with its host: opening the host page alone runs the part page's OnOpenPage,
//      as it does for a page's own parts (corpus codeunit for TestPagePartAgcr_Tests.al).
//   2. Declared Visible = false, it is not on the test page at all: reaching it raises
//      "was not found on the page", as it does for a page's own parts (codeunit 60346).
//
// Written by agent stma-auto2-13, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issues StefanMaron/BusinessCentral.AL.Runner#4887 and #4891.

codeunit 67621 "PXP Trace"
{
    SingleInstance = true;

    var
        Trace: Text;

    procedure Append(Marker: Text)
    begin
        Trace += Marker + ';';
    end;

    procedure GetTrace(): Text
    begin
        exit(Trace);
    end;

    procedure Reset()
    begin
        Trace := '';
    end;
}

table 67620 "PXP Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 67620 "PXP Source Host Part"
{
    PageType = CardPart;
    ApplicationArea = All;
    UsageCategory = None;

    trigger OnOpenPage()
    var
        Trace: Codeunit "PXP Trace";
    begin
        Trace.Append('SourceHostPartOpen');
    end;
}

page 67621 "PXP Precompiled Host Part"
{
    PageType = CardPart;
    ApplicationArea = All;
    UsageCategory = None;

    trigger OnOpenPage()
    var
        Trace: Codeunit "PXP Trace";
    begin
        Trace.Append('PrecompiledHostPartOpen');
    end;
}

page 67622 "PXP Hidden Part"
{
    PageType = CardPart;
    ApplicationArea = All;
    UsageCategory = None;

    trigger OnOpenPage()
    var
        Trace: Codeunit "PXP Trace";
    begin
        Trace.Append('HiddenPartOpen');
    end;
}

page 67623 "PXP Host"
{
    PageType = Card;
    SourceTable = "PXP Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Trace: Codeunit "PXP Trace";
    begin
        Trace.Append('HostOpen');
    end;
}

pageextension 67620 "PXP Host Ext" extends "PXP Host"
{
    layout
    {
        addlast(Content)
        {
            part(ExtPart; "PXP Source Host Part")
            {
                ApplicationArea = All;
            }
            part(ExtHiddenPart; "PXP Hidden Part")
            {
                ApplicationArea = All;
                Visible = false;
            }
        }
    }
}

pageextension 67621 "PXP Languages Ext" extends Languages
{
    layout
    {
        addlast(Content)
        {
            part(PxpExtPart; "PXP Precompiled Host Part")
            {
                ApplicationArea = All;
            }
            part(PxpExtHiddenPart; "PXP Hidden Part")
            {
                ApplicationArea = All;
                Visible = false;
            }
        }
    }
}

codeunit 67620 "PXP Extension Part Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure SeedRow()
    var
        Row: Record "PXP Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 'PXP';
        Row.Insert();
    end;

    [Test]
    procedure SourceHost_ExtensionPart_OpensWithTheHost()
    var
        Host: TestPage "PXP Host";
        Trace: Codeunit "PXP Trace";
        Order: Text;
    begin
        SeedRow();
        Trace.Reset();

        Host.OpenView();
        Host.Close();

        Order := Trace.GetTrace();
        Assert.IsTrue(StrPos(Order, 'HostOpen') > 0, 'the host''s own OnOpenPage must run; trace: ' + Order);
        Assert.IsTrue(StrPos(Order, 'SourceHostPartOpen') > 0,
            'opening the host alone must run the extension part''s OnOpenPage; trace: ' + Order);
    end;

    [Test]
    procedure SourceHost_ExtensionPartVisibleFalse_IsNotOnThePage()
    var
        Host: TestPage "PXP Host";
        Reached: Boolean;
    begin
        SeedRow();

        Host.OpenView();
        Assert.IsTrue(Host.ExtPart.Visible(), 'the visible extension part must be reachable');
        asserterror Reached := Host.ExtHiddenPart.Visible();
        Assert.IsTrue(StrPos(GetLastErrorText(), 'was not found on the page') > 0,
            'reaching an extension part declared Visible = false must error that it is not on the page; got: ' + GetLastErrorText());
        Host.Close();
    end;

    [Test]
    procedure PrecompiledHost_ExtensionPart_OpensWithTheHost()
    var
        LanguagesPage: TestPage Languages;
        Trace: Codeunit "PXP Trace";
        Order: Text;
    begin
        Trace.Reset();

        LanguagesPage.OpenView();
        LanguagesPage.Close();

        Order := Trace.GetTrace();
        Assert.IsTrue(StrPos(Order, 'PrecompiledHostPartOpen') > 0,
            'opening a precompiled host alone must run its extension part''s OnOpenPage; trace: ' + Order);
    end;

    [Test]
    procedure PrecompiledHost_ExtensionPartVisibleFalse_IsNotOnThePage()
    var
        LanguagesPage: TestPage Languages;
        Reached: Boolean;
    begin
        LanguagesPage.OpenView();
        Assert.IsTrue(LanguagesPage.PxpExtPart.Visible(), 'the visible extension part must be reachable');
        asserterror Reached := LanguagesPage.PxpExtHiddenPart.Visible();
        Assert.IsTrue(StrPos(GetLastErrorText(), 'was not found on the page') > 0,
            'reaching an extension part declared Visible = false must error that it is not on the page; got: ' + GetLastErrorText());
        LanguagesPage.Close();
    end;
}
