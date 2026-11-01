// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-promoted-actions
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 93321-93325 (SingleInstance log 93325 is used only by test codeunit 93324)
// Probe (writer Y64, al-runner issues 6646 and 6647): a page extension that modifies an implicit promoted category group (Category_Category5,
//   Category_Category6) of a base page that does not declare it, adds an actionref to it, and anchors on the implicit <Action>_Promoted
//   actionref that the compiler makes for an action with the legacy Promoted property (addafter, addbefore, modify). Page 93322 promotes with
//   Promoted/PromotedCategory; page 93323 has no actions section (the shape of 6646). The TestPage opens; the actions and actionrefs are read
//   (Visible, Enabled) and invoked.
// Compile facts (AL compiler 30, BC 27-29): Category_Category4 to Category_Category20 exist on every page, also one without actions;
//   Category_Category1 to 3 and 21 and higher are AL0271 (must-not-compile 2625). modify() of such a group takes Caption, Visible and ShowAs;
//   Image is AL0246, a second modify() of the group AL0356. An action without Promoted = true has no <Action>_Promoted (AL0271, 2626).
//   modify(<Action>_Promoted) takes Visible; Caption is AL0124 (2627). Already pinned: addlast(Category_Category7/12/New) of an undeclared group
//   (UpPromotedCategories.al), addlast(Category_Category4) (pages/lt-page-ext-promoted/PageExtPromotedCategoryRisky.al), modify of an explicit
//   actionref (pageext/lt-u-page-props/UPageObjects.al:348).
// BC versions: 27-29

table 93321 "LT Y64 PI Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 93325 "LT Y64 PI Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

page 93322 "LT Y64 PI Card"
{
    PageType = Card;
    SourceTable = "LT Y64 PI Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
        }
    }

    actions
    {
        area(Processing)
        {
            action("My Action")
            {
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    Log: Codeunit "LT Y64 PI Log";
                begin
                    Log.Add('my action');
                end;
            }
            action(Cat5Act)
            {
                Promoted = true;
                PromotedCategory = Category5;

                trigger OnAction()
                var
                    Log: Codeunit "LT Y64 PI Log";
                begin
                    Log.Add('cat5 action');
                end;
            }
            action(Plain)
            {
                trigger OnAction()
                var
                    Log: Codeunit "LT Y64 PI Log";
                begin
                    Log.Add('plain');
                end;
            }
        }
    }
}

pageextension 93322 "LT Y64 PI Card Ext" extends "LT Y64 PI Card"
{
    actions
    {
        addlast(Processing)
        {
            action("My New Action")
            {
                trigger OnAction()
                var
                    Log: Codeunit "LT Y64 PI Log";
                begin
                    Log.Add('my new action');
                end;
            }
            action(N2)
            {
                trigger OnAction()
                var
                    Log: Codeunit "LT Y64 PI Log";
                begin
                    Log.Add('n2');
                end;
            }
            action(N3)
            {
                trigger OnAction()
                var
                    Log: Codeunit "LT Y64 PI Log";
                begin
                    Log.Add('n3');
                end;
            }
        }
        addafter("My Action_Promoted")
        {
            actionref("My New Action_Promoted"; "My New Action") { }
        }
        addbefore(Cat5Act_Promoted)
        {
            actionref(N2_Promoted; N2) { }
        }
        modify("My Action_Promoted")
        {
            Visible = false;
        }
        modify(Category_Category5)
        {
            Caption = 'My Category';
        }
        modify(Category_Category6)
        {
            Caption = 'Six';
        }
        addlast(Category_Category6)
        {
            actionref(N3_Promoted; N3) { }
        }
    }
}

page 93323 "LT Y64 PI Plain Card"
{
    PageType = Card;
    SourceTable = "LT Y64 PI Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
        }
    }
}

pageextension 93323 "LT Y64 PI Plain Card Ext" extends "LT Y64 PI Plain Card"
{
    actions
    {
        addlast(Processing)
        {
            action(MyAction)
            {
                trigger OnAction()
                var
                    Log: Codeunit "LT Y64 PI Log";
                begin
                    Log.Add('plain card my action');
                end;
            }
        }
        modify(Category_Category5)
        {
            Caption = 'My Category';
        }
        addlast(Category_Category5)
        {
            actionref(MyAction_Promoted; MyAction) { }
        }
    }
}

codeunit 93324 "LT Y64 PI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y64 PI Log";

    local procedure Seed()
    var
        Row: Record "LT Y64 PI Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Log.Take();
    end;

    [Test]
    procedure Y64_ImplicitPromoted_Anchors()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT Y64 PI Card";
    begin
        Seed();
        Card.OpenEdit();
        Observer.Observe('my action_promoted visible', Format(Card."My Action_Promoted".Visible()));
        Observer.Observe('my action visible', Format(Card."My Action".Visible()));
        Observer.Observe('my new action_promoted visible', Format(Card."My New Action_Promoted".Visible()));
        Observer.Observe('n2_promoted visible', Format(Card.N2_Promoted.Visible()));
        Observer.Observe('n3_promoted visible', Format(Card.N3_Promoted.Visible()));
        Observer.Observe('cat5act_promoted visible', Format(Card.Cat5Act_Promoted.Visible()));
        Observer.Observe('cat5act_promoted enabled', Format(Card.Cat5Act_Promoted.Enabled()));
        Card."My New Action_Promoted".Invoke();
        Card.N2_Promoted.Invoke();
        Card.N3_Promoted.Invoke();
        Card.Cat5Act_Promoted.Invoke();
        Card."My Action".Invoke();
        Observer.Observe('log', Log.Take());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y64_ImplicitPromoted_HiddenActionRefInvoke()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT Y64 PI Card";
    begin
        Seed();
        Card.OpenEdit();
        asserterror Card."My Action_Promoted".Invoke();
        Observer.ObserveError('invoke hidden actionref');
        Observer.Observe('log', Log.Take());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y64_CategoryGroup_UndeclaredOnPageWithoutActions()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT Y64 PI Plain Card";
    begin
        Seed();
        Card.OpenView();
        Observer.Observe('actionref visible', Format(Card.MyAction_Promoted.Visible()));
        Card.MyAction_Promoted.Invoke();
        Card.MyAction.Invoke();
        Observer.Observe('log', Log.Take());
        Card.Close();
        Observer.Finish();
    end;
}
