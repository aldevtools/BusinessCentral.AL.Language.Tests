// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), non-test codeunits below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: IncludeSender on a codeunit publisher: what the Sender parameter is (same instance, state, a second instance, no sender)
// BC versions: 29 (27 and 28 by CI)

codeunit 72070 "LT P70 Publisher"
{
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

    procedure RaiseWithSender(Value: Integer)
    begin
        OnWithSender(Value);
    end;

    procedure RaiseWithoutSender(Value: Integer)
    begin
        OnWithoutSender(Value);
    end;

    procedure RaiseWithVar(var Value: Integer)
    begin
        OnWithVar(Value);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnWithSender(Value: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWithoutSender(Value: Integer)
    begin
    end;

    [BusinessEvent(true)]
    local procedure OnWithVar(var Value: Integer)
    begin
    end;
}

codeunit 72072 "LT P70 Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Count(): Integer
    begin
        exit(Lines.Count());
    end;

    procedure Line(Index: Integer): Text
    begin
        exit(Lines.Get(Index));
    end;

    procedure Reset()
    begin
        Clear(Lines);
    end;
}

codeunit 72071 "LT P70 Subscriber"
{
    EventSubscriberInstance = Manual;

    var
        Log: Codeunit "LT P70 Log";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT P70 Publisher", 'OnWithSender', '', false, false)]
    local procedure HandleWithSender(Sender: Codeunit "LT P70 Publisher"; Value: Integer)
    begin
        Log.Add('sender|marker=' + Sender.GetMarker() + '|value=' + Format(Value));
        Sender.SetMarker(Sender.GetMarker() + '+touched');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT P70 Publisher", 'OnWithoutSender', '', false, false)]
    local procedure HandleWithoutSender(Value: Integer)
    begin
        Log.Add('nosender|value=' + Format(Value));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT P70 Publisher", 'OnWithVar', '', false, false)]
    local procedure HandleWithVar(Sender: Codeunit "LT P70 Publisher"; var Value: Integer)
    begin
        Log.Add('var|marker=' + Sender.GetMarker() + '|value=' + Format(Value));
        Value := Value * 2;
    end;
}

codeunit 72073 "LT P70 IncludeSender"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT P70 Log";

    [Test]
    procedure Sender_IsPublisherInstance()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT P70 Publisher";
        Subs: Codeunit "LT P70 Subscriber";
    begin
        Log.Reset();
        Pub.SetMarker('A');
        BindSubscription(Subs);
        Pub.RaiseWithSender(5);
        UnbindSubscription(Subs);
        Observer.Observe('log_count', Format(Log.Count()));
        Observer.Observe('log_1', Log.Line(1));
        Observer.Observe('marker_after', Pub.GetMarker());
        Observer.Expect('log_count', '1');
        Observer.Expect('log_1', 'sender|marker=A|value=5');
        Observer.Expect('marker_after', 'A+touched');
        Observer.Verify();
    end;

    [Test]
    procedure Sender_SecondInstanceDiffers()
    var
        Observer: Codeunit "Probe Observer";
        PubA: Codeunit "LT P70 Publisher";
        PubB: Codeunit "LT P70 Publisher";
        Subs: Codeunit "LT P70 Subscriber";
    begin
        Log.Reset();
        PubA.SetMarker('A');
        PubB.SetMarker('B');
        BindSubscription(Subs);
        PubB.RaiseWithSender(2);
        PubA.RaiseWithSender(1);
        UnbindSubscription(Subs);
        Observer.Observe('log_count', Format(Log.Count()));
        Observer.Observe('log_1', Log.Line(1));
        Observer.Observe('log_2', Log.Line(2));
        Observer.Observe('marker_a', PubA.GetMarker());
        Observer.Observe('marker_b', PubB.GetMarker());
        Observer.Expect('log_count', '2');
        Observer.Expect('log_1', 'sender|marker=B|value=2');
        Observer.Expect('log_2', 'sender|marker=A|value=1');
        Observer.Expect('marker_a', 'A+touched');
        Observer.Expect('marker_b', 'B+touched');
        Observer.Verify();
    end;

    [Test]
    procedure Sender_RaisedTwiceSeesChangedState()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT P70 Publisher";
        Subs: Codeunit "LT P70 Subscriber";
        i: Integer;
    begin
        Log.Reset();
        Pub.SetMarker('S');
        BindSubscription(Subs);
        for i := 1 to 3 do begin
            Pub.RaiseWithSender(i);
        end;
        UnbindSubscription(Subs);
        Observer.Observe('log_count', Format(Log.Count()));
        for i := 1 to Log.Count() do begin
            Observer.Observe('log_' + Format(i), Log.Line(i));
        end;
        Observer.Expect('log_count', '3');
        Observer.Expect('log_1', 'sender|marker=S|value=1');
        Observer.Expect('log_2', 'sender|marker=S+touched|value=2');
        Observer.Expect('log_3', 'sender|marker=S+touched+touched|value=3');
        Observer.Verify();
    end;

    [Test]
    procedure Sender_NoSenderEventAndUnbound()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT P70 Publisher";
        Subs: Codeunit "LT P70 Subscriber";
    begin
        Log.Reset();
        Pub.RaiseWithoutSender(9);
        Observer.Observe('unbound_count', Format(Log.Count()));
        BindSubscription(Subs);
        Pub.RaiseWithoutSender(9);
        Pub.RaiseWithSender(8);
        UnbindSubscription(Subs);
        Pub.RaiseWithSender(7);
        Observer.Observe('bound_count', Format(Log.Count()));
        Observer.Observe('log_1', Log.Line(1));
        Observer.Observe('log_2', Log.Line(2));
        Observer.Expect('unbound_count', '0');
        Observer.Expect('bound_count', '2');
        Observer.Expect('log_1', 'nosender|value=9');
        Observer.Expect('log_2', 'sender|marker=|value=8');
        Observer.Verify();
    end;

    [Test]
    procedure Sender_VarParameterWithSender()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT P70 Publisher";
        Subs: Codeunit "LT P70 Subscriber";
        V: Integer;
    begin
        Log.Reset();
        Pub.SetMarker('V');
        V := 21;
        BindSubscription(Subs);
        Pub.RaiseWithVar(V);
        UnbindSubscription(Subs);
        Observer.Observe('value_after', Format(V));
        Observer.Observe('log_1', Log.Line(1));
        Observer.Expect('value_after', '42');
        Observer.Expect('log_1', 'var|marker=V|value=21');
        Observer.Verify();
    end;
}
