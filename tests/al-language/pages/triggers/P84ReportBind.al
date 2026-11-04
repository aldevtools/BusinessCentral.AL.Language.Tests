// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-bindsubscription-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 73036, report 73045, codeunits 73046-73048 (log 73047 used only by test codeunit 73049)
// Probe: written against BC 29 ...; observed values are added by the lead after measuring (tag P84, GitHub issue #84)
// Facts: BindSubscription / UnbindSubscription called inside report triggers (OnInitReport, OnPreReport, OnAfterGetRecord, OnPostReport) with a manual subscriber codeunit. BindSubscription(this) with the report itself is not possible (this is a report, BindSubscription takes a codeunit): skipped
// BC versions: 29

report 73045 "LT P84 Bind Rpt"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P84 Row")
        {
            trigger OnAfterGetRecord()
            begin
                Pub.Raise('get' + Format(Row.Id) + '-a');
                if Modes.Contains('bindget') then
                    TryBindNote();
                Pub.Raise('get' + Format(Row.Id) + '-b');
                if Modes.Contains('unbindget') then
                    UnbindSubscription(Sub);
                Pub.Raise('get' + Format(Row.Id) + '-c');
            end;
        }
    }

    trigger OnInitReport()
    begin
        Pub.Raise('init-1');
        if Modes.Contains('bindinit') then
            TryBindNote();
        Pub.Raise('init-2');
        if Modes.Contains('unbindinit') then
            UnbindSubscription(Sub);
        Pub.Raise('init-3');
    end;

    trigger OnPreReport()
    begin
        Pub.Raise('pre-1');
        if Modes.Contains('bindpre') then
            TryBindNote();
        Pub.Raise('pre-2');
        if Modes.Contains('unbindpre') then
            UnbindSubscription(Sub);
        Pub.Raise('pre-3');
    end;

    trigger OnPostReport()
    begin
        Pub.Raise('post-1');
        if Modes.Contains('bindpost') then
            TryBindNote();
        Pub.Raise('post-2');
        if Modes.Contains('unbindpost') then
            UnbindSubscription(Sub);
        Pub.Raise('post-3');
    end;

    var
        Pub: Codeunit "LT P84 Bind Pub";
        Sub: Codeunit "LT P84 Bind Sub";
        Modes: List of [Text];

    [TryFunction]
    local procedure TryBind()
    begin
        BindSubscription(Sub);
    end;

    local procedure TryBindNote()
    begin
        if not TryBind() then
            Pub.Raise('bindfail:' + GetLastErrorText());
    end;

    procedure AddMode(Mode: Text)
    begin
        Modes.Add(Mode);
    end;

    procedure BindOutside()
    begin
        BindSubscription(Sub);
    end;

    procedure CleanUp(): Integer
    var
        Count: Integer;
        I: Integer;
    begin
        for I := 1 to 3 do
            if UnbindSubscription(Sub) then
                Count += 1;
        exit(Count);
    end;
}

codeunit 73046 "LT P84 Bind Pub"
{
    procedure Raise(Where: Text)
    begin
        OnPing(Where);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPing(Where: Text)
    begin
    end;
}

codeunit 73047 "LT P84 Bind Log"
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

codeunit 73048 "LT P84 Bind Sub"
{
    EventSubscriberInstance = Manual;

    var
        BindLog: Codeunit "LT P84 Bind Log";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT P84 Bind Pub", 'OnPing', '', false, false)]
    local procedure HandlePing(Where: Text)
    begin
        BindLog.Add(Where);
    end;
}

codeunit 73049 "LT P84 Bind Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        BindLog: Codeunit "LT P84 Bind Log";

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

    local procedure RunWith(var Observer: Codeunit "Probe Observer"; Tag: Text; ModeList: Text; Outside: Boolean)
    var
        Pub: Codeunit "LT P84 Bind Pub";
        Rpt: Report "LT P84 Bind Rpt";
        Mode: Text;
    begin
        Seed();
        BindLog.Take();
        foreach Mode in ModeList.Split(',') do
            if Mode <> '' then
                Rpt.AddMode(Mode);
        if Outside then
            Rpt.BindOutside();
        Rpt.Run();
        Observer.Observe(Tag + '_run', BindLog.Take());
        Pub.Raise('after-1');
        Observer.Observe(Tag + '_after', BindLog.Take());
        Observer.Observe(Tag + '_unbinds', Format(Rpt.CleanUp()));
        Pub.Raise('after-2');
        Observer.Observe(Tag + '_cleaned', BindLog.Take());
    end;

    [Test]
    procedure Init_BindUnbind()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWith(Observer, 'bind', 'bindinit', false);
        Observer.Observe('af185', 'no error');
        RunWith(Observer, 'both', 'bindinit,unbindinit', false);
        Observer.Observe('af187', 'no error');
        RunWith(Observer, 'unbind_only', 'unbindinit', false);
        RunWith(Observer, 'outside_unbind', 'unbindinit', true);
        Observer.Expect('bind_run', '');
        Observer.Expect('bind_after', '');
        Observer.Expect('bind_unbinds', '3');
        Observer.Expect('bind_cleaned', '');
        Observer.Expect('af185', 'no error');
        Observer.Expect('both_run', '');
        Observer.Expect('both_after', '');
        Observer.Expect('both_unbinds', '3');
        Observer.Expect('both_cleaned', '');
        Observer.Expect('af187', 'no error');
        Observer.Expect('unbind_only_run', '');
        Observer.Expect('unbind_only_after', '');
        Observer.Expect('unbind_only_unbinds', '3');
        Observer.Expect('unbind_only_cleaned', '');
        Observer.Expect('outside_unbind_run', 'pre-1;pre-2;pre-3;get1-a;get1-b;get1-c;get2-a;get2-b;get2-c;post-1;post-2;post-3;');
        Observer.Expect('outside_unbind_after', '');
        Observer.Expect('outside_unbind_unbinds', '3');
        Observer.Expect('outside_unbind_cleaned', '');
        Observer.Verify();
    end;

    [Test]
    procedure Pre_BindUnbind()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWith(Observer, 'bind', 'bindpre', false);
        Observer.Observe('af198', 'no error');
        RunWith(Observer, 'both', 'bindpre,unbindpre', false);
        Observer.Observe('af201', 'no error');
        RunWith(Observer, 'unbind_only', 'unbindpre', false);
        RunWith(Observer, 'outside_unbind', 'unbindpre', true);
        Observer.Expect('bind_run', 'pre-2;pre-3;get1-a;get1-b;get1-c;get2-a;get2-b;get2-c;post-1;post-2;post-3;');
        Observer.Expect('bind_after', '');
        Observer.Expect('bind_unbinds', '3');
        Observer.Expect('bind_cleaned', '');
        Observer.Expect('af198', 'no error');
        Observer.Expect('both_run', 'pre-2;');
        Observer.Expect('both_after', '');
        Observer.Expect('both_unbinds', '3');
        Observer.Expect('both_cleaned', '');
        Observer.Expect('af201', 'no error');
        Observer.Expect('unbind_only_run', '');
        Observer.Expect('unbind_only_after', '');
        Observer.Expect('unbind_only_unbinds', '3');
        Observer.Expect('unbind_only_cleaned', '');
        Observer.Expect('outside_unbind_run', 'pre-1;pre-2;');
        Observer.Expect('outside_unbind_after', '');
        Observer.Expect('outside_unbind_unbinds', '3');
        Observer.Expect('outside_unbind_cleaned', '');
        Observer.Verify();
    end;

    [Test]
    procedure Get_BindUnbind()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWith(Observer, 'bind', 'bindget', false);
        Observer.Observe('af211', 'no error');
        RunWith(Observer, 'both', 'bindget,unbindget', false);
        Observer.Observe('af215', 'no error');
        RunWith(Observer, 'unbind_only', 'unbindget', false);
        RunWith(Observer, 'outside_unbind', 'unbindget', true);
        Observer.Expect('bind_run', 'get1-b;get1-c;get2-a;bindfail:The binding of codeunit 73048 was unsuccessful. The codeunit has already been bound.;get2-b;get2-c;post-1;post-2;post-3;');
        Observer.Expect('bind_after', '');
        Observer.Expect('bind_unbinds', '3');
        Observer.Expect('bind_cleaned', '');
        Observer.Expect('af211', 'no error');
        Observer.Expect('both_run', 'get1-b;get2-b;');
        Observer.Expect('both_after', '');
        Observer.Expect('both_unbinds', '3');
        Observer.Expect('both_cleaned', '');
        Observer.Expect('af215', 'no error');
        Observer.Expect('unbind_only_run', '');
        Observer.Expect('unbind_only_after', '');
        Observer.Expect('unbind_only_unbinds', '3');
        Observer.Expect('unbind_only_cleaned', '');
        Observer.Expect('outside_unbind_run', 'pre-1;pre-2;pre-3;get1-a;get1-b;');
        Observer.Expect('outside_unbind_after', '');
        Observer.Expect('outside_unbind_unbinds', '3');
        Observer.Expect('outside_unbind_cleaned', '');
        Observer.Verify();
    end;

    [Test]
    procedure Post_BindUnbind()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWith(Observer, 'bind', 'bindpost', false);
        Observer.Observe('af224', 'no error');
        RunWith(Observer, 'both', 'bindpost,unbindpost', false);
        Observer.Observe('af229', 'no error');
        RunWith(Observer, 'unbind_only', 'unbindpost', false);
        RunWith(Observer, 'outside_unbind', 'unbindpost', true);
        Observer.Expect('bind_run', 'post-2;post-3;');
        Observer.Expect('bind_after', '');
        Observer.Expect('bind_unbinds', '3');
        Observer.Expect('bind_cleaned', '');
        Observer.Expect('af224', 'no error');
        Observer.Expect('both_run', 'post-2;');
        Observer.Expect('both_after', '');
        Observer.Expect('both_unbinds', '3');
        Observer.Expect('both_cleaned', '');
        Observer.Expect('af229', 'no error');
        Observer.Expect('unbind_only_run', '');
        Observer.Expect('unbind_only_after', '');
        Observer.Expect('unbind_only_unbinds', '3');
        Observer.Expect('unbind_only_cleaned', '');
        Observer.Expect('outside_unbind_run', 'pre-1;pre-2;pre-3;get1-a;get1-b;get1-c;get2-a;get2-b;get2-c;post-1;post-2;');
        Observer.Expect('outside_unbind_after', '');
        Observer.Expect('outside_unbind_unbinds', '3');
        Observer.Expect('outside_unbind_cleaned', '');
        Observer.Verify();
    end;

    [Test]
    procedure DoubleBind_AcrossTriggers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWith(Observer, 'init_pre', 'bindinit,bindpre', false);
        Observer.Observe('af237', 'no error');
        RunWith(Observer, 'init_pre_unbind_pre', 'bindinit,bindpre,unbindpre', false);
        Observer.Observe('af243', 'no error');
        RunWith(Observer, 'init_post', 'bindinit,bindpost', false);
        RunWith(Observer, 'outside_init', 'bindinit', true);
        RunWith(Observer, 'outside_pre_unbind', 'bindpre,unbindpre', true);
        Observer.Observe('af249', 'no error');
        Observer.Expect('init_pre_run', 'pre-2;pre-3;get1-a;get1-b;get1-c;get2-a;get2-b;get2-c;post-1;post-2;post-3;');
        Observer.Expect('init_pre_after', '');
        Observer.Expect('init_pre_unbinds', '3');
        Observer.Expect('init_pre_cleaned', '');
        Observer.Expect('af237', 'no error');
        Observer.Expect('init_pre_unbind_pre_run', 'pre-2;');
        Observer.Expect('init_pre_unbind_pre_after', '');
        Observer.Expect('init_pre_unbind_pre_unbinds', '3');
        Observer.Expect('init_pre_unbind_pre_cleaned', '');
        Observer.Expect('af243', 'no error');
        Observer.Expect('init_post_run', 'post-2;post-3;');
        Observer.Expect('init_post_after', '');
        Observer.Expect('init_post_unbinds', '3');
        Observer.Expect('init_post_cleaned', '');
        Observer.Expect('outside_init_run', 'pre-1;pre-2;pre-3;get1-a;get1-b;get1-c;get2-a;get2-b;get2-c;post-1;post-2;post-3;');
        Observer.Expect('outside_init_after', '');
        Observer.Expect('outside_init_unbinds', '3');
        Observer.Expect('outside_init_cleaned', '');
        Observer.Expect('outside_pre_unbind_run', 'pre-1;bindfail:The binding of codeunit 73048 was unsuccessful. The codeunit has already been bound.;pre-2;');
        Observer.Expect('outside_pre_unbind_after', '');
        Observer.Expect('outside_pre_unbind_unbinds', '3');
        Observer.Expect('outside_pre_unbind_cleaned', '');
        Observer.Expect('af249', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure BindOutside_NoTriggerBinding()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWith(Observer, 'outside_plain', '', true);
        Observer.Observe('af251', 'no error');
        RunWith(Observer, 'none', '', false);
        Observer.Observe('af258', 'no error');
        Observer.Expect('outside_plain_run', 'pre-1;pre-2;pre-3;get1-a;get1-b;get1-c;get2-a;get2-b;get2-c;post-1;post-2;post-3;');
        Observer.Expect('outside_plain_after', '');
        Observer.Expect('outside_plain_unbinds', '3');
        Observer.Expect('outside_plain_cleaned', '');
        Observer.Expect('af251', 'no error');
        Observer.Expect('none_run', '');
        Observer.Expect('none_after', '');
        Observer.Expect('none_unbinds', '3');
        Observer.Expect('none_cleaned', '');
        Observer.Expect('af258', 'no error');
        Observer.Verify();
    end;
}
