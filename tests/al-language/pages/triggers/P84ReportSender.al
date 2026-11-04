// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-types
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 73036, report 73041, log codeunit 73042 (used only by test codeunit 73044), manual subscriber 73043
// Probe: written against BC 29 ...; observed values are added by the lead after measuring (tag P84, GitHub issue #84)
// Facts: IncludeSender = true on an event published by a report: what Sender is, whether the subscriber can call the report procedures and see its state
// BC versions: 29

report 73041 "LT P84 Sender Rpt"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P84 Row")
        {
            trigger OnAfterGetRecord()
            begin
                Marker := 'get' + Format(Row.Id);
                RaiseFromProc('get');
            end;
        }
    }

    trigger OnInitReport()
    begin
        Marker := 'init';
        RaiseFromProc('init');
    end;

    trigger OnPreReport()
    begin
        Marker := 'pre';
        RaiseFromProc('pre');
    end;

    trigger OnPostReport()
    begin
        Marker := 'post';
        RaiseFromProc('post');
    end;

    var
        Marker: Text;
        Hits: Integer;
        Seen: Text;

    procedure SetMarker(NewMarker: Text)
    begin
        Marker := NewMarker;
    end;

    procedure GetMarker(): Text
    begin
        exit(Marker);
    end;

    procedure GetHits(): Integer
    begin
        exit(Hits);
    end;

    procedure GetSeen(): Text
    begin
        exit(Seen);
    end;

    procedure RaiseFromProc(Where: Text)
    begin
        Hits += 1;
        OnPing(Where);
        Seen += Where + '=' + Marker + ';';
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPing(Where: Text)
    begin
    end;
}

codeunit 73042 "LT P84 RptSnd Log"
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

codeunit 73043 "LT P84 RptSnd Sub"
{
    EventSubscriberInstance = Manual;

    var
        SenderLog: Codeunit "LT P84 RptSnd Log";
        Nest: Boolean;
        ChangeMarker: Boolean;

    procedure SetNest(NewNest: Boolean)
    begin
        Nest := NewNest;
    end;

    procedure SetChangeMarker(NewChange: Boolean)
    begin
        ChangeMarker := NewChange;
    end;

    [EventSubscriber(ObjectType::Report, Report::"LT P84 Sender Rpt", 'OnPing', '', false, false)]
    local procedure HandlePing(Sender: Report "LT P84 Sender Rpt"; Where: Text)
    begin
        SenderLog.Add(Where + '|marker=' + Sender.GetMarker() + '|hits=' + Format(Sender.GetHits()));
        if ChangeMarker then
            Sender.SetMarker('sub-' + Where);
        if Nest and (Where = 'nest') then
            Sender.RaiseFromProc('inner');
    end;
}

codeunit 73044 "LT P84 RptSnd Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SenderLog: Codeunit "LT P84 RptSnd Log";

    local procedure Seed()
    var
        Row: Record "LT P84 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'One';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'Two';
        Row.Insert();
    end;

    [Test]
    procedure Proc_SenderIsReportInstance()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT P84 RptSnd Sub";
        Rpt: Report "LT P84 Sender Rpt";
    begin
        SenderLog.Take();
        Sub.SetChangeMarker(true);
        BindSubscription(Sub);
        Rpt.SetMarker('m1');
        Rpt.RaiseFromProc('p');
        Observer.Observe('log', SenderLog.Take());
        Observer.Observe('marker_after', Rpt.GetMarker());
        Observer.Observe('hits_after', Format(Rpt.GetHits()));
        Observer.Observe('seen', Rpt.GetSeen());
        Rpt.RaiseFromProc('p2');
        Observer.Observe('log2', SenderLog.Take());
        Observer.Observe('seen2', Rpt.GetSeen());
        UnbindSubscription(Sub);
        Observer.Expect('log', 'init|marker=init|hits=1;p|marker=m1|hits=2;');
        Observer.Expect('marker_after', 'sub-p');
        Observer.Expect('hits_after', '2');
        Observer.Expect('seen', 'init=sub-init;p=sub-p;');
        Observer.Expect('log2', 'p2|marker=sub-p|hits=3;');
        Observer.Expect('seen2', 'init=sub-init;p=sub-p;p2=sub-p2;');
        Observer.Verify();
    end;

    [Test]
    procedure Proc_NotBound_NoSubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT P84 Sender Rpt";
    begin
        SenderLog.Take();
        Rpt.SetMarker('m1');
        Rpt.RaiseFromProc('p');
        Observer.Observe('log', SenderLog.Take());
        Observer.Observe('marker_after', Rpt.GetMarker());
        Observer.Observe('hits_after', Format(Rpt.GetHits()));
        Observer.Expect('log', '');
        Observer.Expect('marker_after', 'm1');
        Observer.Expect('hits_after', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Proc_TwoInstances()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT P84 RptSnd Sub";
        Rpt1: Report "LT P84 Sender Rpt";
        Rpt2: Report "LT P84 Sender Rpt";
    begin
        SenderLog.Take();
        Sub.SetChangeMarker(true);
        BindSubscription(Sub);
        Rpt1.SetMarker('first');
        Rpt2.SetMarker('second');
        Rpt2.RaiseFromProc('x');
        Observer.Observe('log_second', SenderLog.Take());
        Observer.Observe('marker1', Rpt1.GetMarker());
        Observer.Observe('marker2', Rpt2.GetMarker());
        Observer.Observe('hits1', Format(Rpt1.GetHits()));
        Observer.Observe('hits2', Format(Rpt2.GetHits()));
        Rpt1.RaiseFromProc('y');
        Observer.Observe('log_first', SenderLog.Take());
        Observer.Observe('marker1_after', Rpt1.GetMarker());
        Observer.Observe('marker2_after', Rpt2.GetMarker());
        UnbindSubscription(Sub);
        Observer.Expect('log_second', 'init|marker=init|hits=1;init|marker=init|hits=1;x|marker=second|hits=2;');
        Observer.Expect('marker1', 'first');
        Observer.Expect('marker2', 'sub-x');
        Observer.Expect('hits1', '1');
        Observer.Expect('hits2', '2');
        Observer.Expect('log_first', 'y|marker=first|hits=2;');
        Observer.Expect('marker1_after', 'sub-y');
        Observer.Expect('marker2_after', 'sub-x');
        Observer.Verify();
    end;

    [Test]
    procedure Proc_NestedRaiseFromSubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT P84 RptSnd Sub";
        Rpt: Report "LT P84 Sender Rpt";
    begin
        SenderLog.Take();
        Sub.SetNest(true);
        BindSubscription(Sub);
        Rpt.SetMarker('m');
        Rpt.RaiseFromProc('nest');
        Observer.Observe('log', SenderLog.Take());
        Observer.Observe('hits', Format(Rpt.GetHits()));
        Observer.Observe('seen', Rpt.GetSeen());
        UnbindSubscription(Sub);
        Observer.Expect('log', 'init|marker=init|hits=1;nest|marker=m|hits=2;inner|marker=m|hits=3;');
        Observer.Expect('hits', '3');
        Observer.Expect('seen', 'init=init;inner=m;nest=m;');
        Observer.Verify();
    end;

    [Test]
    procedure Triggers_Run_SenderInEachTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT P84 RptSnd Sub";
        Rpt: Report "LT P84 Sender Rpt";
    begin
        Seed();
        SenderLog.Take();
        BindSubscription(Sub);
        Rpt.Run();
        Observer.Observe('log', SenderLog.Take());
        Observer.Observe('marker_after', Rpt.GetMarker());
        Observer.Observe('hits_after', Format(Rpt.GetHits()));
        Observer.Observe('seen', Rpt.GetSeen());
        UnbindSubscription(Sub);
        Observer.Expect('log', 'init|marker=init|hits=1;pre|marker=pre|hits=2;get|marker=get1|hits=3;get|marker=get2|hits=4;post|marker=post|hits=5;');
        Observer.Expect('marker_after', 'init');
        Observer.Expect('hits_after', '1');
        Observer.Expect('seen', 'init=init;');
        Observer.Verify();
    end;

    [Test]
    procedure Triggers_Run_SubscriberChangesMarker()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT P84 RptSnd Sub";
        Rpt: Report "LT P84 Sender Rpt";
    begin
        Seed();
        SenderLog.Take();
        Sub.SetChangeMarker(true);
        BindSubscription(Sub);
        Rpt.Run();
        Observer.Observe('log', SenderLog.Take());
        Observer.Observe('marker_after', Rpt.GetMarker());
        Observer.Observe('hits_after', Format(Rpt.GetHits()));
        Observer.Observe('seen', Rpt.GetSeen());
        UnbindSubscription(Sub);
        Observer.Expect('log', 'init|marker=init|hits=1;pre|marker=pre|hits=2;get|marker=get1|hits=3;get|marker=get2|hits=4;post|marker=post|hits=5;');
        Observer.Expect('marker_after', 'sub-init');
        Observer.Expect('hits_after', '1');
        Observer.Expect('seen', 'init=sub-init;');
        Observer.Verify();
    end;

    [Test]
    procedure Triggers_StaticRun_SubscriberStillSeesSender()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT P84 RptSnd Sub";
    begin
        Seed();
        SenderLog.Take();
        Sub.SetChangeMarker(true);
        BindSubscription(Sub);
        Report.Run(Report::"LT P84 Sender Rpt");
        Observer.Observe('log', SenderLog.Take());
        UnbindSubscription(Sub);
        Observer.Expect('log', 'init|marker=init|hits=1;pre|marker=pre|hits=2;get|marker=get1|hits=3;get|marker=get2|hits=4;post|marker=post|hits=5;');
        Observer.Verify();
    end;

    [Test]
    procedure Triggers_Run_NoRows()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT P84 RptSnd Sub";
        Row: Record "LT P84 Row";
        Rpt: Report "LT P84 Sender Rpt";
    begin
        Row.DeleteAll();
        SenderLog.Take();
        BindSubscription(Sub);
        Rpt.Run();
        Observer.Observe('log', SenderLog.Take());
        Observer.Observe('seen', Rpt.GetSeen());
        UnbindSubscription(Sub);
        Observer.Expect('log', 'init|marker=init|hits=1;pre|marker=pre|hits=2;post|marker=post|hits=3;');
        Observer.Expect('seen', 'init=init;');
        Observer.Verify();
    end;

    [Test]
    procedure Triggers_Run_AfterUnbind()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT P84 RptSnd Sub";
        Rpt: Report "LT P84 Sender Rpt";
    begin
        Seed();
        SenderLog.Take();
        BindSubscription(Sub);
        UnbindSubscription(Sub);
        Rpt.Run();
        Observer.Observe('log', SenderLog.Take());
        Observer.Observe('seen', Rpt.GetSeen());
        Observer.Observe('hits', Format(Rpt.GetHits()));
        Observer.Expect('log', '');
        Observer.Expect('seen', 'init=init;');
        Observer.Expect('hits', '1');
        Observer.Verify();
    end;
}
