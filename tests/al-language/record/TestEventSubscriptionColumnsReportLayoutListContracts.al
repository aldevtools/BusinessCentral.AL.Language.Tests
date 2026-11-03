// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained codeunits 69080..69082 and 69086, report 69083, report extension 69084
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins:
//  - "Event Subscription": "Subscriber Instance" reads Static-Automatic for an ordinary subscriber and Manual for one with
//    EventSubscriberInstance = Manual; "Active Manual Instances" is 0 until BindSubscription (1) and 0 again after UnbindSubscription;
//    "Number of Calls" counts the raised events a subscriber handled: +1 for the static subscriber on each Fire, +1 for the manual one
//    only while it is bound, and the count stays after the unbind; "Error Information" is blank.
//  - "Report Layout List": one row per layout of the report, including a layout a reportextension adds; Caption, "Layout Format"
//    (RDLC, Word), "Application ID" the id of the app that declares the layout (here this app, also for the extension's layout), and
//    Description the layout's Summary, else the layout name.
// BC versions: 27.5

codeunit 69080 "Probe ES Publisher"
{
    [IntegrationEvent(false, false)]
    procedure OnProbeEvent()
    begin
    end;

    procedure Fire()
    begin
        OnProbeEvent();
    end;
}

codeunit 69081 "Probe ES Static"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Probe ES Publisher", 'OnProbeEvent', '', false, false)]
    local procedure Handle()
    begin
    end;
}

codeunit 69082 "Probe ES Manual"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Probe ES Publisher", 'OnProbeEvent', '', false, false)]
    local procedure Handle()
    begin
    end;
}

report 69083 "Probe RL Report"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(Item; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            column(Num; Number) { }
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/ProbeRlLayout.rdl';
            Caption = 'RL rdlc';
            Summary = 'rdlc summary';
        }
        layout(Word)
        {
            Type = Word;
            LayoutFile = './_fixtures/layouts/ProbeRlLayout_2.docx';
            Caption = 'RL word';
        }
    }
}

reportextension 69084 "Probe RL Report Ext" extends "Probe RL Report"
{
    rendering
    {
        layout(ExtWord)
        {
            Type = Word;
            LayoutFile = './_fixtures/layouts/ProbeRlExtLayout.docx';
            Caption = 'RL ext word';
        }
    }
}

codeunit 69086 "Probe ES Columns Layouts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Row(SubscriberCodeunit: Integer; var EventSub: Record "Event Subscription")
    begin
        EventSub.Reset();
        EventSub.SetRange("Subscriber Codeunit ID", SubscriberCodeunit);
        EventSub.FindFirst();
    end;

    [Test]
    procedure EventSubscription_InstanceActiveInstancesAndCalls()
    var
        EventSub: Record "Event Subscription";
        Publisher: Codeunit "Probe ES Publisher";
        ManualSub: Codeunit "Probe ES Manual";
        StaticCalls: BigInteger;
        ManualCalls: BigInteger;
    begin
        Row(Codeunit::"Probe ES Static", EventSub);
        Assert.AreEqual('Static-Automatic', Format(EventSub."Subscriber Instance"), 'static instance');
        StaticCalls := EventSub."Number of Calls";
        Assert.AreEqual(0, EventSub."Active Manual Instances", 'static active instances');
        Row(Codeunit::"Probe ES Manual", EventSub);
        Assert.AreEqual('Manual', Format(EventSub."Subscriber Instance"), 'manual instance');
        ManualCalls := EventSub."Number of Calls";
        Assert.AreEqual(0, EventSub."Active Manual Instances", 'manual before bind');
        Assert.AreEqual('', EventSub."Error Information", 'Error Information');

        Publisher.Fire();
        Row(Codeunit::"Probe ES Static", EventSub);
        Assert.AreEqual(StaticCalls + 1, EventSub."Number of Calls", 'static counts the event');
        Row(Codeunit::"Probe ES Manual", EventSub);
        Assert.AreEqual(ManualCalls, EventSub."Number of Calls", 'an unbound manual subscriber counts nothing');

        BindSubscription(ManualSub);
        Row(Codeunit::"Probe ES Manual", EventSub);
        Assert.AreEqual(1, EventSub."Active Manual Instances", 'after BindSubscription');
        Publisher.Fire();
        Row(Codeunit::"Probe ES Manual", EventSub);
        Assert.AreEqual(ManualCalls + 1, EventSub."Number of Calls", 'bound manual subscriber counts');

        UnbindSubscription(ManualSub);
        Row(Codeunit::"Probe ES Manual", EventSub);
        Assert.AreEqual(0, EventSub."Active Manual Instances", 'after UnbindSubscription');
        Assert.AreEqual(ManualCalls + 1, EventSub."Number of Calls", 'the count stays');
    end;

    [Test]
    procedure ReportLayoutList_RowsForTheLayoutsOfAReportAndItsExtension()
    var
        Layouts: Record "Report Layout List";
        Info: ModuleInfo;
        Rows: Text;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        Layouts.SetRange("Report ID", Report::"Probe RL Report");
        Layouts.FindSet();
        repeat
            Rows += Layouts.Name + ': caption=[' + Layouts.Caption + '] type=' + Format(Layouts."Layout Format") + ' app=' + Format(Layouts."Application ID" = Info.Id()) + ' desc=[' + Layouts.Description + ']; ';
        until Layouts.Next() = 0;

        Assert.AreEqual(
            'ExtWord: caption=[RL ext word] type=Word app=Yes desc=[ExtWord]; Rdlc: caption=[RL rdlc] type=RDLC app=Yes desc=[rdlc summary]; Word: caption=[RL word] type=Word app=Yes desc=[Word]; ',
            Rows, 'layouts');
    end;
}
