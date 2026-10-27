// Probe: subscriber instance sharing and order within one codeunit and across manual codeunits; BindSubscription(this);
// events of a duplicate-key insert.
codeunit 69461 "Probe Ev Publisher"
{
    SingleInstance = true;

    [IntegrationEvent(false, false)]
    procedure OnProbe(var Log: Text)
    begin
    end;

    procedure Raise(): Text
    var
        Log: Text;
    begin
        OnProbe(Log);
        exit(Log);
    end;
}

codeunit 69462 "Probe Ev Static Subscribers"
{
    var
        InstanceCounter: Integer;

    // declared in this order on purpose: Zeta first, then Alpha, then Mid
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Probe Ev Publisher", 'OnProbe', '', false, false)]
    local procedure Zeta(var Log: Text)
    begin
        InstanceCounter += 1;
        Log += 'Zeta(c=' + Format(InstanceCounter) + ');';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Probe Ev Publisher", 'OnProbe', '', false, false)]
    local procedure Alpha(var Log: Text)
    begin
        InstanceCounter += 1;
        Log += 'Alpha(c=' + Format(InstanceCounter) + ');';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Probe Ev Publisher", 'OnProbe', '', false, false)]
    local procedure Mid(var Log: Text)
    begin
        InstanceCounter += 1;
        Log += 'Mid(c=' + Format(InstanceCounter) + ');';
    end;
}

codeunit 69463 "Probe Ev Manual High"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Probe Ev Publisher", 'OnProbe', '', false, false)]
    local procedure OnProbe(var Log: Text)
    begin
        Log += 'ManualHigh;';
    end;
}

codeunit 69464 "Probe Ev Manual Low"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Probe Ev Publisher", 'OnProbe', '', false, false)]
    local procedure OnProbe(var Log: Text)
    begin
        Log += 'ManualLow;';
    end;
}

codeunit 69465 "Probe Ev Self Binder"
{
    EventSubscriberInstance = Manual;

    var
        Hits: Integer;

    procedure BindSelf()
    begin
        BindSubscription(this);
    end;

    procedure UnbindSelf()
    begin
        UnbindSubscription(this);
    end;

    procedure GetHits(): Integer
    begin
        exit(Hits);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Probe Ev Publisher", 'OnProbe', '', false, false)]
    local procedure OnProbe(var Log: Text)
    begin
        Hits += 1;
        Log += 'SelfBound(h=' + Format(Hits) + ');';
    end;
}

codeunit 69466 "Probe Ev Insert Counter"
{
    SingleInstance = true;

    var
        AfterInsertHits: Integer;
        AfterInsertIdSeen: Integer;

    procedure Hits(): Integer
    begin
        exit(AfterInsertHits);
    end;

    procedure Reset()
    begin
        AfterInsertHits := 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Probe Pf Row", 'OnAfterInsertEvent', '', false, false)]
    local procedure AfterInsert(var Rec: Record "Probe Pf Row")
    begin
        if Rec.Id = 69450002 then
            AfterInsertHits += 1;
    end;
}

codeunit 69467 "Probe Event Order Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure StaticSubscribers_OneCodeunit_OrderAndSharedInstance()
    var
        Publisher: Codeunit "Probe Ev Publisher";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('firstRaise', Publisher.Raise());
        Observer.Observe('secondRaise', Publisher.Raise());
        Observer.Expect('firstRaise', 'Alpha(c=1);Mid(c=1);Zeta(c=1);');
        Observer.Expect('secondRaise', 'Alpha(c=1);Mid(c=1);Zeta(c=1);');
        Observer.Verify();
    end;

    [Test]
    procedure ManualSubscribers_BoundHighThenLow_OrderOfCalls()
    var
        High: Codeunit "Probe Ev Manual High";
        Low: Codeunit "Probe Ev Manual Low";
        Publisher: Codeunit "Probe Ev Publisher";
        Observer: Codeunit "Probe Observer";
    begin
        BindSubscription(High);
        BindSubscription(Low);
        Observer.Observe('boundHighThenLow', Publisher.Raise());
        UnbindSubscription(High);
        UnbindSubscription(Low);
        BindSubscription(Low);
        BindSubscription(High);
        Observer.Observe('boundLowThenHigh', Publisher.Raise());
        UnbindSubscription(High);
        UnbindSubscription(Low);
        Observer.Expect('boundHighThenLow', 'Alpha(c=1);Mid(c=1);Zeta(c=1);ManualHigh;ManualLow;');
        Observer.Expect('boundLowThenHigh', 'Alpha(c=1);Mid(c=1);Zeta(c=1);ManualHigh;ManualLow;');
        Observer.Verify();
    end;

    [Test]
    procedure BindSubscription_This_BindsOwnInstance()
    var
        Binder: Codeunit "Probe Ev Self Binder";
        Publisher: Codeunit "Probe Ev Publisher";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('beforeBind', Publisher.Raise());
        Binder.BindSelf();
        Observer.Observe('afterBind', Publisher.Raise());
        Observer.Observe('hitsOnVariable', Format(Binder.GetHits()));
        Binder.UnbindSelf();
        Observer.Observe('afterUnbind', Publisher.Raise());
        Observer.Expect('beforeBind', 'Alpha(c=1);Mid(c=1);Zeta(c=1);');
        Observer.Expect('afterBind', 'Alpha(c=1);Mid(c=1);Zeta(c=1);SelfBound(h=1);');
        Observer.Expect('hitsOnVariable', '1');
        Observer.Expect('afterUnbind', 'Alpha(c=1);Mid(c=1);Zeta(c=1);');
        Observer.Verify();
    end;

    [Test]
    procedure BindSubscription_This_TwiceBinds_OneOrTwoCalls()
    var
        Binder: Codeunit "Probe Ev Self Binder";
        Publisher: Codeunit "Probe Ev Publisher";
        Observer: Codeunit "Probe Observer";
    begin
        Binder.BindSelf();
        asserterror Binder.BindSelf();
        Observer.ObserveError('secondBind');
        Observer.Observe('afterDoubleBind', Publisher.Raise());
        Binder.UnbindSelf();
        Observer.Observe('afterOneUnbind', Publisher.Raise());
        Observer.Expect('secondBind|text', 'The binding of codeunit 69465 was unsuccessful. The codeunit has already been bound.');
        Observer.Expect('secondBind|code', 'EventBinding');
        Observer.Expect('afterDoubleBind', 'Alpha(c=1);Mid(c=1);Zeta(c=1);SelfBound(h=1);');
        Observer.Expect('afterOneUnbind', 'Alpha(c=1);Mid(c=1);Zeta(c=1);');
        Observer.Verify();
    end;


    [TryFunction]
    local procedure TryInsertUnused(var R: Record "Probe Pf Row")
    begin
        R.Insert(true);
    end;

    [TryFunction]
    local procedure TryCount(var R: Record "Probe Pf Row")
    var
        N: Integer;
    begin
        N := R.Count();
    end;

    [TryFunction]
    local procedure TryCommit()
    begin
        Commit();
    end;

    [Test]
    procedure DuplicateKeyInsert_ResultUsed_AfterInsertEvent()
    var
        Row: Record "Probe Pf Row";
        Dup: Record "Probe Pf Row";
        Counter: Codeunit "Probe Ev Insert Counter";
        Ok: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Counter.Reset();
        Row.Id := 69450002;
        Row.Insert(true);
        Dup.Id := 69450002;
        Ok := Dup.Insert(true);
        Observer.Observe('insertReturned', Format(Ok));
        Observer.Observe('hitsAfterDuplicate', Format(Counter.Hits()));
        Observer.Expect('insertReturned', 'No');
        Observer.Expect('hitsAfterDuplicate', '1');
        Observer.Verify();
    end;

    // Writer SH, al-runner issue 5941: a manual subscriber instance unbinds itself in its first subscriber method. Is its second method
    // (same event, same instance) still called in that raise, and is anything of it called in the next raise?
    [Test]
    procedure ManualSubscriber_UnbindsItselfInFirstMethod_SecondMethodInSameRaise()
    var
        Unbinder: Codeunit "LT SH Ev Self Unbinder";
        Publisher: Codeunit "Probe Ev Publisher";
        Observer: Codeunit "Probe Observer";
    begin
        BindSubscription(Unbinder);
        Observer.Observe('raiseThatUnbinds', Publisher.Raise());
        Observer.Observe('nextRaise', Publisher.Raise());
        Observer.Observe('unbindAgain returns', Format(UnbindSubscription(Unbinder)));
        Observer.Finish();
    end;
}

codeunit 89420 "LT SH Ev Self Unbinder"
{
    // Two subscriber methods on one event; the first one (in the alphabetical order the publisher calls them, see
    // StaticSubscribers_OneCodeunit_OrderAndSharedInstance) unbinds this instance.
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Probe Ev Publisher", 'OnProbe', '', false, false)]
    local procedure A_OnProbe(var Log: Text)
    begin
        Log += 'A;';
        UnbindSubscription(this);
        Log += 'A after unbind;';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Probe Ev Publisher", 'OnProbe', '', false, false)]
    local procedure B_OnProbe(var Log: Text)
    begin
        Log += 'B;';
    end;
}
