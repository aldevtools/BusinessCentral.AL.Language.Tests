// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-subscriber-instances
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), log 71067, publisher 71068, manual subscriber 71069, test codeunit 71070 (the only user of the log)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: EventSubscriberInstance = Manual, BindSubscription / UnbindSubscription, order of bound instances, state of an instance
// BC versions: 29 (27 and 28 by CI)

codeunit 71067 "LT OjT Manual Log"
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

    procedure Count(): Integer
    begin
        exit(Lines.Count());
    end;

    procedure Get(Index: Integer): Text
    begin
        exit(Lines.Get(Index));
    end;
}

codeunit 71068 "LT OjT Manual Pub"
{
    procedure Raise(var Value: Integer)
    begin
        OnManual(Value);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnManual(var Value: Integer)
    begin
    end;
}

codeunit 71069 "LT OjT Manual Subs"
{
    EventSubscriberInstance = Manual;

    var
        Log: Codeunit "LT OjT Manual Log";
        Tag: Text;
        Hits: Integer;

    procedure SetTag(NewTag: Text)
    begin
        Tag := NewTag;
    end;

    procedure GetHits(): Integer
    begin
        exit(Hits);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT OjT Manual Pub", 'OnManual', '', false, false)]
    local procedure OnManualSub(var Value: Integer)
    begin
        Hits += 1;
        Log.Add(Tag + ' hit ' + Format(Hits) + ' value ' + Format(Value));
        Value += 1;
    end;
}

codeunit 71070 "LT OjT Events Manual"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT OjT Manual Log";

    local procedure Dump(var Observer: Codeunit "Probe Observer")
    var
        i: Integer;
    begin
        Observer.Observe('logCount', Format(Log.Count()));
        for i := 1 to Log.Count() do begin
            Observer.Observe('log' + Format(i), Log.Get(i));
        end;
    end;

    [Test]
    procedure NotBound_NoEffect()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT OjT Manual Pub";
        Subs: Codeunit "LT OjT Manual Subs";
        V: Integer;
    begin
        Log.Reset();
        V := 0;
        Pub.Raise(V);
        Observer.Observe('value', Format(V));
        Observer.Observe('hits', Format(Subs.GetHits()));
        Dump(Observer);
        Observer.Expect('value', '0');
        Observer.Expect('hits', '0');
        Observer.Expect('logCount', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Bind_ThenUnbind()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT OjT Manual Pub";
        Subs: Codeunit "LT OjT Manual Subs";
        V: Integer;
    begin
        Log.Reset();
        Subs.SetTag('S');
        BindSubscription(Subs);
        V := 0;
        Pub.Raise(V);
        Observer.Observe('afterBind', Format(V));
        Pub.Raise(V);
        Observer.Observe('afterBind2', Format(V));
        UnbindSubscription(Subs);
        Pub.Raise(V);
        Observer.Observe('afterUnbind', Format(V));
        Observer.Observe('hits', Format(Subs.GetHits()));
        Dump(Observer);
        Observer.Expect('afterBind', '1');
        Observer.Expect('afterBind2', '2');
        Observer.Expect('afterUnbind', '2');
        Observer.Expect('hits', '2');
        Observer.Expect('logCount', '2');
        Observer.Expect('log1', 'S hit 1 value 0');
        Observer.Expect('log2', 'S hit 2 value 1');
        Observer.Verify();
    end;

    [Test]
    procedure Bind_TwoInstances_Order()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT OjT Manual Pub";
        First: Codeunit "LT OjT Manual Subs";
        Second: Codeunit "LT OjT Manual Subs";
        V: Integer;
    begin
        Log.Reset();
        First.SetTag('first');
        Second.SetTag('second');
        BindSubscription(First);
        BindSubscription(Second);
        V := 0;
        Pub.Raise(V);
        Observer.Observe('value', Format(V));
        UnbindSubscription(First);
        Pub.Raise(V);
        Observer.Observe('valueAfterUnbindFirst', Format(V));
        UnbindSubscription(Second);
        Dump(Observer);
        Observer.Expect('value', '2');
        Observer.Expect('valueAfterUnbindFirst', '3');
        Observer.Expect('logCount', '3');
        Observer.Expect('log1', 'first hit 1 value 0');
        Observer.Expect('log2', 'second hit 1 value 1');
        Observer.Expect('log3', 'second hit 2 value 2');
        Observer.Verify();
    end;

    [Test]
    procedure Bind_ReverseOrder()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT OjT Manual Pub";
        First: Codeunit "LT OjT Manual Subs";
        Second: Codeunit "LT OjT Manual Subs";
        V: Integer;
    begin
        Log.Reset();
        First.SetTag('first');
        Second.SetTag('second');
        BindSubscription(Second);
        BindSubscription(First);
        Pub.Raise(V);
        UnbindSubscription(First);
        UnbindSubscription(Second);
        Dump(Observer);
        Observer.Expect('logCount', '2');
        Observer.Expect('log1', 'second hit 1 value 0');
        Observer.Expect('log2', 'first hit 1 value 1');
        Observer.Verify();
    end;

    [Test]
    procedure Bind_RebindKeepsInstanceState()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT OjT Manual Pub";
        Subs: Codeunit "LT OjT Manual Subs";
        V: Integer;
    begin
        Log.Reset();
        Subs.SetTag('R');
        BindSubscription(Subs);
        Pub.Raise(V);
        UnbindSubscription(Subs);
        BindSubscription(Subs);
        Pub.Raise(V);
        UnbindSubscription(Subs);
        Observer.Observe('hits', Format(Subs.GetHits()));
        Dump(Observer);
        Observer.Expect('hits', '2');
        Observer.Expect('logCount', '2');
        Observer.Expect('log1', 'R hit 1 value 0');
        Observer.Expect('log2', 'R hit 2 value 1');
        Observer.Verify();
    end;

    [Test]
    procedure Bind_SameInstanceTwice()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT OjT Manual Pub";
        Subs: Codeunit "LT OjT Manual Subs";
        V: Integer;
    begin
        Log.Reset();
        Subs.SetTag('twice');
        BindSubscription(Subs);
        asserterror BindSubscription(Subs);
        Observer.ObserveError('af214');
        Pub.Raise(V);
        Observer.Observe('value', Format(V));
        UnbindSubscription(Subs);
        Pub.Raise(V);
        Observer.Observe('valueAfterOneUnbind', Format(V));
        Dump(Observer);
        Observer.Expect('af214|text', 'The binding of codeunit 71069 was unsuccessful. The codeunit has already been bound.');
        Observer.Expect('af214|code', 'EventBinding');
        Observer.Expect('value', '1');
        Observer.Expect('valueAfterOneUnbind', '1');
        Observer.Expect('logCount', '1');
        Observer.Expect('log1', 'twice hit 1 value 0');
        Observer.Verify();
    end;

    [Test]
    procedure Unbind_NeverBound()
    var
        Observer: Codeunit "Probe Observer";
        Subs: Codeunit "LT OjT Manual Subs";
        Ok: Boolean;
    begin
        Log.Reset();
        Ok := UnbindSubscription(Subs);
        Observer.Observe('result', Format(Ok));
        Observer.Expect('result', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Unbind_ReturnValueAfterBind()
    var
        Observer: Codeunit "Probe Observer";
        Subs: Codeunit "LT OjT Manual Subs";
        Ok: Boolean;
    begin
        Log.Reset();
        BindSubscription(Subs);
        Ok := UnbindSubscription(Subs);
        Observer.Observe('first', Format(Ok));
        Ok := UnbindSubscription(Subs);
        Observer.Observe('second', Format(Ok));
        Observer.Expect('first', 'Yes');
        Observer.Expect('second', 'Yes');
        Observer.Verify();
    end;
}
