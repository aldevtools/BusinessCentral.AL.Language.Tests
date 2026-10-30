// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/eventsubscription/eventsubscription-table
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 91354, pages 91355 and 91356, page extension 91357, subscriber codeunit 91358, test codeunit 91359
// Probe: observe probe (writer Y7, 2026-10-30, asked by an al-runtime-rs runtime agent); every literal asserted below is what the BC service tier produced
//   (SaaS sandbox BC 29 first, then the corpus CI legs).
// Facts: the Published Function text ('OnBeforeActionEvent - <number>' / 'OnAfterActionEvent - <number>') of the Event Subscription rows for subscribers to page
//   action events, so the runtime can derive the number from the action: the same action name on two pages, OnBefore and OnAfter of one action, short and long
//   names, a quoted name with a blank, actions inside a group and in area(Navigation), and an action added by a page extension.
//   EventSubscriptionTriggerRows.al:222 pins 'OnAfterActionEvent - 780149250' for action AfterAct of page 73669.
// BC versions: 27, 28, 29

table 91354 "LT Y7 Action Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 91355 "LT Y7 Action Page A"
{
    PageType = Card;
    SourceTable = "LT Y7 Action Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SendIt)
            {
                trigger OnAction()
                begin
                end;
            }
            action(A)
            {
                trigger OnAction()
                begin
                end;
            }
            action(Post)
            {
                trigger OnAction()
                begin
                end;
            }
            action("My Action")
            {
                trigger OnAction()
                begin
                end;
            }
            action(AVeryLongActionNameForTheHashProbe)
            {
                trigger OnAction()
                begin
                end;
            }
            group(Grp)
            {
                action(GroupedAction)
                {
                    trigger OnAction()
                    begin
                    end;
                }
            }
        }
        area(Navigation)
        {
            action(NavAction)
            {
                trigger OnAction()
                begin
                end;
            }
        }
    }
}

page 91356 "LT Y7 Action Page B"
{
    PageType = Card;
    SourceTable = "LT Y7 Action Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SendIt)
            {
                trigger OnAction()
                begin
                end;
            }
            action(Post)
            {
                trigger OnAction()
                begin
                end;
            }
        }
    }
}

pageextension 91357 "LT Y7 Action Page A Ext" extends "LT Y7 Action Page A"
{
    actions
    {
        addlast(Processing)
        {
            action(ExtAction)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                end;
            }
        }
    }
}

codeunit 91358 "LT Y7 Action Subscribers"
{
    [EventSubscriber(ObjectType::Page, Page::"LT Y7 Action Page A", OnBeforeActionEvent, 'SendIt', false, false)]
    local procedure A01_BeforeSendItA(var Rec: Record "LT Y7 Action Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y7 Action Page A", OnAfterActionEvent, 'SendIt', false, false)]
    local procedure A02_AfterSendItA(var Rec: Record "LT Y7 Action Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y7 Action Page B", OnBeforeActionEvent, 'SendIt', false, false)]
    local procedure A03_BeforeSendItB(var Rec: Record "LT Y7 Action Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y7 Action Page B", OnAfterActionEvent, 'SendIt', false, false)]
    local procedure A04_AfterSendItB(var Rec: Record "LT Y7 Action Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y7 Action Page A", OnBeforeActionEvent, 'A', false, false)]
    local procedure A05_BeforeA(var Rec: Record "LT Y7 Action Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y7 Action Page A", OnBeforeActionEvent, 'Post', false, false)]
    local procedure A06_BeforePostA(var Rec: Record "LT Y7 Action Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y7 Action Page B", OnBeforeActionEvent, 'Post', false, false)]
    local procedure A07_BeforePostB(var Rec: Record "LT Y7 Action Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y7 Action Page A", OnBeforeActionEvent, 'My Action', false, false)]
    local procedure A08_BeforeMyAction(var Rec: Record "LT Y7 Action Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y7 Action Page A", OnBeforeActionEvent, 'AVeryLongActionNameForTheHashProbe', false, false)]
    local procedure A09_BeforeLongName(var Rec: Record "LT Y7 Action Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y7 Action Page A", OnBeforeActionEvent, 'GroupedAction', false, false)]
    local procedure A10_BeforeGrouped(var Rec: Record "LT Y7 Action Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y7 Action Page A", OnBeforeActionEvent, 'NavAction', false, false)]
    local procedure A11_BeforeNav(var Rec: Record "LT Y7 Action Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y7 Action Page A", OnBeforeActionEvent, 'ExtAction', false, false)]
    local procedure A12_BeforeExtAction(var Rec: Record "LT Y7 Action Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT Y7 Action Page A", OnAfterActionEvent, 'ExtAction', false, false)]
    local procedure A13_AfterExtAction(var Rec: Record "LT Y7 Action Row")
    begin
    end;
}

codeunit 91359 "LT Y7 Action Published Fn"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Row(var Observer: Codeunit "Probe Observer"; FunctionName: Text)
    var
        Sub: Record "Event Subscription";
    begin
        Sub.SetRange("Subscriber Codeunit ID", Codeunit::"LT Y7 Action Subscribers");
        Sub.SetRange("Subscriber Function", FunctionName);
        if Sub.FindFirst() then
            Observer.Observe(FunctionName, Format(Sub."Publisher Object ID") + '|' + Sub."Published Function" + '|' + Format(Sub."Event Type") + '|' + Format(Sub.Active))
        else
            Observer.Observe(FunctionName, 'no row');
    end;

    [Test]
    procedure Y7_ActionEvent_PublishedFunction_PerAction()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Record "Event Subscription";
    begin
        Sub.SetRange("Subscriber Codeunit ID", Codeunit::"LT Y7 Action Subscribers");
        Observer.Observe('count', Format(Sub.Count()));
        Row(Observer, 'A01_BeforeSendItA');
        Row(Observer, 'A02_AfterSendItA');
        Row(Observer, 'A03_BeforeSendItB');
        Row(Observer, 'A04_AfterSendItB');
        Row(Observer, 'A05_BeforeA');
        Row(Observer, 'A06_BeforePostA');
        Row(Observer, 'A07_BeforePostB');
        Row(Observer, 'A08_BeforeMyAction');
        Row(Observer, 'A09_BeforeLongName');
        Row(Observer, 'A10_BeforeGrouped');
        Row(Observer, 'A11_BeforeNav');
        Row(Observer, 'A12_BeforeExtAction');
        Row(Observer, 'A13_AfterExtAction');
        Observer.Finish();
    end;
}
