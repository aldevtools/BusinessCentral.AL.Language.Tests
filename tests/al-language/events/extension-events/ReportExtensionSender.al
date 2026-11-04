// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own report 67188, reportextension 67189, SingleInstance log 67190, subscribers 67191
// Probe: a reportextension publishes an event with IncludeSender = true and a subscriber takes `Sender: Report "LT RS Report"`. What the subscriber sees through Sender:
// a base report procedure, the state the caller set in a global variable of the base report before the raise, a procedure of the extension, and whether two
// report variables give the subscriber two different senders. Object ids 67188 - 67192.

report 67188 "LT RS Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    var
        Marker: Text;

    procedure SetMarker(NewMarker: Text)
    begin
        Marker := NewMarker;
    end;

    procedure GetMarker(): Text
    begin
        exit(Marker);
    end;
}

reportextension 67189 "LT RS Report Ext" extends "LT RS Report"
{
    var
        ExtMarker: Text;

    procedure SetExtMarker(NewMarker: Text)
    begin
        ExtMarker := NewMarker;
    end;

    procedure GetExtMarker(): Text
    begin
        exit(ExtMarker);
    end;

    procedure RaiseWithSender()
    begin
        OnWithSender(ExtMarker);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnWithSender(Argument: Text)
    begin
    end;
}

codeunit 67190 "LT RS Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Reset()
    begin
        Clear(Lines);
    end;

    procedure Text(): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Lines do
            Result += Line + ';';
        exit(Result);
    end;
}

codeunit 67191 "LT RS Subscribers"
{
    [EventSubscriber(ObjectType::Report, Report::"LT RS Report", 'OnWithSender', '', false, false)]
    local procedure OnWithSender(Sender: Report "LT RS Report"; Argument: Text)
    var
        Log: Codeunit "LT RS Log";
    begin
        Log.Add('argument=' + Argument + '|base_marker=' + Sender.GetMarker() + '|ext_marker=' + Sender.GetExtMarker());
        Sender.SetMarker('set by the subscriber');
    end;
}

codeunit 67192 "LT RS Report Extension Sender"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Sender_IsTheRaisingReportVariable()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT RS Log";
        Rep: Report "LT RS Report";
    begin
        Log.Reset();
        Rep.SetMarker('base state');
        Rep.SetExtMarker('extension state');
        Rep.RaiseWithSender();
        Observer.Observe('log', Log.Text());
        Observer.Observe('marker_after_subscriber', Rep.GetMarker());
        Observer.Observe('ext_marker_after_subscriber', Rep.GetExtMarker());
        Observer.Expect('log', 'argument=extension state|base_marker=base state|ext_marker=extension state;');
        Observer.Expect('marker_after_subscriber', 'set by the subscriber');
        Observer.Expect('ext_marker_after_subscriber', 'extension state');
        Observer.Verify();
    end;

    [Test]
    procedure Sender_TwoReportVariables()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT RS Log";
        First: Report "LT RS Report";
        Second: Report "LT RS Report";
    begin
        Log.Reset();
        First.SetMarker('first');
        First.SetExtMarker('first ext');
        Second.SetMarker('second');
        Second.SetExtMarker('second ext');
        Second.RaiseWithSender();
        First.RaiseWithSender();
        Observer.Observe('log', Log.Text());
        Observer.Observe('first_marker', First.GetMarker());
        Observer.Observe('second_marker', Second.GetMarker());
        Observer.Expect('log', 'argument=second ext|base_marker=second|ext_marker=second ext;argument=first ext|base_marker=first|ext_marker=first ext;');
        Observer.Expect('first_marker', 'set by the subscriber');
        Observer.Expect('second_marker', 'set by the subscriber');
        Observer.Verify();
    end;

    [Test]
    procedure Sender_FreshReportVariable()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT RS Log";
        Rep: Report "LT RS Report";
    begin
        Log.Reset();
        Rep.RaiseWithSender();
        Observer.Observe('log', Log.Text());
        Observer.Observe('marker_after', Rep.GetMarker());
        Observer.Expect('log', 'argument=|base_marker=|ext_marker=;');
        Observer.Expect('marker_after', 'set by the subscriber');
        Observer.Verify();
    end;
}
