// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); shared table 50001 "ALT Shape 01"; self-contained log 65300, pages 65301 65302, report 65303,
//   page extension 65304, subscribers 65305, test codeunit 65306
// Probe: observe-only, for subscribers of OnBeforeActionEvent and OnAfterActionEvent of page actions that have no OnAction trigger anywhere.
// Facts: does a page that has such subscribers open; which of the events fire when a TestPage opens without invoking the action and when it invokes it
//   (plain action, action in a group, hidden action, disabled action, action added by a page extension, action with OnBeforeAction and OnAfterAction
//   triggers only in a page extension, RunObject = Report, RunObject = Page with RunPageLink); Invoke result (error text and code); a second Invoke.
//   A subscriber for an action name the page does not have does not compile (AL0271, must-not-compile case 3113). P114PageActionEvents.al and PageActionSubscriberErrors.al pin the plain action with a
//   trigger and RunObject = Page and Codeunit.
// local object: the page, its extension, the report and the subscribers are what is under test (actions without trigger, extension actions).
// BC versions: 27, 28, 29

codeunit 65300 "LT PAN Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];

    procedure Reset()
    begin
        Clear(Lines);
    end;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Dump(): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Lines do begin
            if Result <> '' then
                Result += ' | ';
            Result += Line;
        end;
        exit('[' + Result + ']');
    end;
}

page 65302 "LT PAN Target"
{
    PageType = Card;
    SourceTable = "ALT Shape 01";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PAN Log";
    begin
        Log.Add('target-OnOpenPage(filter=' + Rec.GetFilter(Id) + ')');
    end;
}

report 65303 "LT PAN Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;
    UsageCategory = None;

    trigger OnPreReport()
    var
        Log: Codeunit "LT PAN Log";
    begin
        Log.Add('report-OnPreReport');
    end;
}

page 65301 "LT PAN Card"
{
    PageType = Card;
    SourceTable = "ALT Shape 01";
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
            action(WithTrigger)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT PAN Log";
                begin
                    Log.Add('OnAction-WithTrigger');
                end;
            }
            action(NoTrigger)
            {
                ApplicationArea = All;
            }
            action(NoTriggerExtOnly)
            {
                ApplicationArea = All;
            }
            action(HiddenNoTrigger)
            {
                ApplicationArea = All;
                Visible = false;
            }
            action(DisabledNoTrigger)
            {
                ApplicationArea = All;
                Enabled = false;
            }
            action(RunRep)
            {
                ApplicationArea = All;
                RunObject = Report "LT PAN Report";
            }
            action(RunPgLink)
            {
                ApplicationArea = All;
                RunObject = Page "LT PAN Target";
                RunPageLink = Id = field(Id);
            }
            group(Grp)
            {
                action(InGroupNoTrigger)
                {
                    ApplicationArea = All;
                }
            }
        }
        area(Promoted)
        {
            actionref(NoTrigger_Promoted; NoTrigger) { }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PAN Log";
    begin
        Log.Add('card-OnOpenPage');
    end;
}

pageextension 65304 "LT PAN Card Ext" extends "LT PAN Card"
{
    actions
    {
        addlast(Processing)
        {
            action(ExtNoTrigger)
            {
                ApplicationArea = All;
            }
        }
        modify(NoTriggerExtOnly)
        {
            trigger OnBeforeAction()
            var
                Log: Codeunit "LT PAN Log";
            begin
                Log.Add('ext-OnBeforeAction-NoTriggerExtOnly');
            end;

            trigger OnAfterAction()
            var
                Log: Codeunit "LT PAN Log";
            begin
                Log.Add('ext-OnAfterAction-NoTriggerExtOnly');
            end;
        }
    }
}

codeunit 65305 "LT PAN Subs"
{
    [EventSubscriber(ObjectType::Page, Page::"LT PAN Card", 'OnBeforeActionEvent', 'WithTrigger', false, false)]
    local procedure BeforeWithTrigger()
    begin
        Add('before-WithTrigger');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PAN Card", 'OnAfterActionEvent', 'WithTrigger', false, false)]
    local procedure AfterWithTrigger()
    begin
        Add('after-WithTrigger');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PAN Card", 'OnBeforeActionEvent', 'NoTrigger', false, false)]
    local procedure BeforeNoTrigger()
    begin
        Add('before-NoTrigger');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PAN Card", 'OnAfterActionEvent', 'NoTrigger', false, false)]
    local procedure AfterNoTrigger()
    begin
        Add('after-NoTrigger');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PAN Card", 'OnBeforeActionEvent', 'NoTriggerExtOnly', false, false)]
    local procedure BeforeNoTriggerExtOnly()
    begin
        Add('before-NoTriggerExtOnly');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PAN Card", 'OnAfterActionEvent', 'NoTriggerExtOnly', false, false)]
    local procedure AfterNoTriggerExtOnly()
    begin
        Add('after-NoTriggerExtOnly');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PAN Card", 'OnBeforeActionEvent', 'HiddenNoTrigger', false, false)]
    local procedure BeforeHidden()
    begin
        Add('before-HiddenNoTrigger');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PAN Card", 'OnAfterActionEvent', 'HiddenNoTrigger', false, false)]
    local procedure AfterHidden()
    begin
        Add('after-HiddenNoTrigger');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PAN Card", 'OnBeforeActionEvent', 'DisabledNoTrigger', false, false)]
    local procedure BeforeDisabled()
    begin
        Add('before-DisabledNoTrigger');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PAN Card", 'OnAfterActionEvent', 'DisabledNoTrigger', false, false)]
    local procedure AfterDisabled()
    begin
        Add('after-DisabledNoTrigger');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PAN Card", 'OnBeforeActionEvent', 'RunRep', false, false)]
    local procedure BeforeRunRep()
    begin
        Add('before-RunRep');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PAN Card", 'OnAfterActionEvent', 'RunRep', false, false)]
    local procedure AfterRunRep()
    begin
        Add('after-RunRep');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PAN Card", 'OnBeforeActionEvent', 'RunPgLink', false, false)]
    local procedure BeforeRunPgLink()
    begin
        Add('before-RunPgLink');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PAN Card", 'OnAfterActionEvent', 'RunPgLink', false, false)]
    local procedure AfterRunPgLink()
    begin
        Add('after-RunPgLink');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PAN Card", 'OnBeforeActionEvent', 'InGroupNoTrigger', false, false)]
    local procedure BeforeInGroup()
    begin
        Add('before-InGroupNoTrigger');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PAN Card", 'OnAfterActionEvent', 'InGroupNoTrigger', false, false)]
    local procedure AfterInGroup()
    begin
        Add('after-InGroupNoTrigger');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PAN Card", 'OnBeforeActionEvent', 'ExtNoTrigger', false, false)]
    local procedure BeforeExtNoTrigger()
    begin
        Add('before-ExtNoTrigger');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PAN Card", 'OnAfterActionEvent', 'ExtNoTrigger', false, false)]
    local procedure AfterExtNoTrigger()
    begin
        Add('after-ExtNoTrigger');
    end;

    local procedure Add(Line: Text)
    var
        Log: Codeunit "LT PAN Log";
    begin
        Log.Add(Line);
    end;
}

codeunit 65306 "LT PAN Action Events"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PAN Log";

    local procedure Row()
    var
        Shape: Record "ALT Shape 01";
    begin
        Shape.DeleteAll();
        Shape.Id := 1;
        Shape.Insert();
    end;

    local procedure Result(Name: Text; Ok: Boolean)
    begin
        Observer.Observe(Name + '.ok', Format(Ok));
        Observer.Observe(Name + '.err', GetLastErrorText());
        Observer.Observe(Name + '.code', GetLastErrorCode());
        Observer.Observe(Name + '.log', Log.Dump());
        ClearLastError();
        Log.Reset();
    end;

    [TryFunction]
    local procedure TryOpenView(var Card: TestPage "LT PAN Card")
    begin
        Card.OpenView();
    end;

    [TryFunction]
    local procedure TryInvokeWithTrigger(var Card: TestPage "LT PAN Card")
    begin
        Card.WithTrigger.Invoke();
    end;

    [TryFunction]
    local procedure TryInvokeNoTrigger(var Card: TestPage "LT PAN Card")
    begin
        Card.NoTrigger.Invoke();
    end;

    [TryFunction]
    local procedure TryInvokeNoTriggerExtOnly(var Card: TestPage "LT PAN Card")
    begin
        Card.NoTriggerExtOnly.Invoke();
    end;

    [TryFunction]
    local procedure TryInvokeHidden(var Card: TestPage "LT PAN Card")
    begin
        Card.HiddenNoTrigger.Invoke();
    end;

    [TryFunction]
    local procedure TryInvokeDisabled(var Card: TestPage "LT PAN Card")
    begin
        Card.DisabledNoTrigger.Invoke();
    end;

    [TryFunction]
    local procedure TryInvokeRunRep(var Card: TestPage "LT PAN Card")
    begin
        Card.RunRep.Invoke();
    end;

    [TryFunction]
    local procedure TryInvokeRunPgLink(var Card: TestPage "LT PAN Card")
    begin
        Card.RunPgLink.Invoke();
    end;

    [TryFunction]
    local procedure TryInvokeInGroup(var Card: TestPage "LT PAN Card")
    begin
        Card.InGroupNoTrigger.Invoke();
    end;

    [TryFunction]
    local procedure TryInvokeExtNoTrigger(var Card: TestPage "LT PAN Card")
    begin
        Card.ExtNoTrigger.Invoke();
    end;

    [Test]
    procedure ActionEvents_OpenWithoutInvoke_SubscribersOfTriggerlessActions()
    var
        Card: TestPage "LT PAN Card";
    begin
        Row();
        Log.Reset();
        Result('open', TryOpenView(Card));
        Card.Close();
        Observer.Observe('close.log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure ActionEvents_Invoke_PlainActionWithAndWithoutTrigger()
    var
        Card: TestPage "LT PAN Card";
    begin
        Row();
        Card.OpenView();
        Log.Reset();
        Result('with_trigger', TryInvokeWithTrigger(Card));
        Result('no_trigger', TryInvokeNoTrigger(Card));
        Result('no_trigger_again', TryInvokeNoTrigger(Card));
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure ActionEvents_Invoke_GroupHiddenDisabledNoTrigger()
    var
        Card: TestPage "LT PAN Card";
    begin
        Row();
        Card.OpenView();
        Log.Reset();
        Result('in_group', TryInvokeInGroup(Card));
        Result('hidden', TryInvokeHidden(Card));
        Result('disabled', TryInvokeDisabled(Card));
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure ActionEvents_Invoke_ExtensionActionAndExtensionTriggersOnly()
    var
        Card: TestPage "LT PAN Card";
    begin
        Row();
        Card.OpenView();
        Log.Reset();
        Result('ext_action', TryInvokeExtNoTrigger(Card));
        Result('ext_triggers_only', TryInvokeNoTriggerExtOnly(Card));
        Result('ext_triggers_only_again', TryInvokeNoTriggerExtOnly(Card));
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure ActionEvents_Invoke_RunObjectReportAndPageWithLink()
    var
        Card: TestPage "LT PAN Card";
    begin
        Row();
        Card.OpenView();
        Log.Reset();
        Result('run_report', TryInvokeRunRep(Card));
        Result('run_page_link', TryInvokeRunPgLink(Card));
        Card.Close();
        Observer.Finish();
    end;
}
