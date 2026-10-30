// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects 90700-90703
// Probe: written against al-runner issue 6293 (Event Subscription read refused for a subscriber to OnBeforeActionEvent); every value asserted below is what the BC service tier produced.
// Facts: the Event Subscription row of a static subscriber to OnBeforeActionEvent of a page action (Published Function, Event Type, Active, Number of Calls),
//        and the "are all subscribers of my codeunit active?" read: filter on Subscriber Codeunit ID and Active = false.
// BC versions: 27, 28, 29

table 90700 "LT WD Action Item"
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

page 90701 "LT WD Action Card"
{
    PageType = Card;
    SourceTable = "LT WD Action Item";
    ApplicationArea = All;
    UsageCategory = Administration;

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
        }
    }
}

codeunit 90702 "LT WD Action Subscribers"
{
    [EventSubscriber(ObjectType::Page, Page::"LT WD Action Card", OnBeforeActionEvent, 'SendIt', true, true)]
    local procedure OnBeforeSendIt(var Rec: Record "LT WD Action Item")
    begin
    end;
}

codeunit 90703 "LT WD Action Event Row"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure WD_ActionEvent_Before_RowColumns()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Record "Event Subscription";
    begin
        Sub.SetRange("Subscriber Codeunit ID", Codeunit::"LT WD Action Subscribers");
        Observer.Observe('count', Format(Sub.Count()));
        if Sub.FindFirst() then begin
            Observer.Observe('Subscriber Function', Sub."Subscriber Function");
            Observer.Observe('Event Type', Format(Sub."Event Type"));
            Observer.Observe('Publisher Object Type', Format(Sub."Publisher Object Type"));
            Observer.Observe('Publisher Object ID', Format(Sub."Publisher Object ID"));
            Observer.Observe('Published Function', Sub."Published Function");
            Observer.Observe('Active', Format(Sub.Active));
            Observer.Observe('Number of Calls', Format(Sub."Number of Calls"));
            Observer.Observe('Error Information', Sub."Error Information");
            Observer.Observe('Subscriber Instance', Format(Sub."Subscriber Instance"));
        end;
        Observer.Finish();
    end;

    [Test]
    procedure WD_ActionEvent_Before_ActiveFilter()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Record "Event Subscription";
    begin
        Sub.SetRange("Subscriber Codeunit ID", Codeunit::"LT WD Action Subscribers");
        Sub.SetRange(Active, false);
        Observer.Observe('inactive: FindFirst', Format(Sub.FindFirst()));
        Observer.Observe('inactive: Count', Format(Sub.Count()));
        Sub.SetRange(Active, true);
        Observer.Observe('active: Count', Format(Sub.Count()));
        Sub.SetRange(Active);
        Sub.SetRange("Event Type", Sub."Event Type"::Trigger);
        Observer.Observe('trigger: Count', Format(Sub.Count()));
        Sub.SetRange("Event Type");
        Sub.SetRange("Subscriber Function", 'OnBeforeSendIt');
        Observer.Observe('by function: Count', Format(Sub.Count()));
        Observer.Finish();
    end;
}
