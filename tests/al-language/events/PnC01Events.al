// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT PnC Log (71071)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: Events "Subscribers of one codeunit keep their declaration order; across codeunits ascending codeunit id, a bound manual one included"
// BC versions: 29 (27 and 28 by CI)

codeunit 71140 "LT PnC Log 1"
{
    SingleInstance = true;

    var
        Items: List of [Text];

    procedure Add(Value: Text)
    begin
        Items.Add(Value);
    end;

    procedure Reset()
    begin
        Clear(Items);
    end;

    procedure Joined(): Text
    var
        Result: Text;
        Item: Text;
    begin
        foreach Item in Items do begin
            if Result <> '' then
                Result += '|';
            Result += Item;
        end;
        exit(Result);
    end;

    procedure Count(): Integer
    begin
        exit(Items.Count());
    end;
}

codeunit 71072 "LT PnC Ev Pub"
{
    [IntegrationEvent(false, false)]
    local procedure OnFire()
    begin
    end;

    procedure Fire()
    begin
        OnFire();
    end;
}

codeunit 71076 "LT PnC Ev Sub High"
{
    var
        Log: Codeunit "LT PnC Log 1";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT PnC Ev Pub", 'OnFire', '', false, false)]
    local procedure Zeta()
    begin
        Log.Add('High.Zeta');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT PnC Ev Pub", 'OnFire', '', false, false)]
    local procedure Alpha()
    begin
        Log.Add('High.Alpha');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT PnC Ev Pub", 'OnFire', '', false, false)]
    local procedure Mid()
    begin
        Log.Add('High.Mid');
    end;
}

codeunit 71075 "LT PnC Ev Sub Man Mid"
{
    EventSubscriberInstance = Manual;

    var
        Log: Codeunit "LT PnC Log 1";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT PnC Ev Pub", 'OnFire', '', false, false)]
    local procedure Handle()
    begin
        Log.Add('ManMid');
    end;
}

codeunit 71074 "LT PnC Ev Sub Low"
{
    var
        Log: Codeunit "LT PnC Log 1";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT PnC Ev Pub", 'OnFire', '', false, false)]
    local procedure Handle()
    begin
        Log.Add('Low');
    end;
}

codeunit 71073 "LT PnC Ev Sub Man Low"
{
    EventSubscriberInstance = Manual;

    var
        Log: Codeunit "LT PnC Log 1";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT PnC Ev Pub", 'OnFire', '', false, false)]
    local procedure Handle()
    begin
        Log.Add('ManLow');
    end;
}

codeunit 71077 "LT PnC Events Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Order_StaticOnly()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnC Log 1";
        Pub: Codeunit "LT PnC Ev Pub";
    begin
        Log.Reset();
        Pub.Fire();
        Observer.Observe('order', Log.Joined());
        Observer.Observe('count', Format(Log.Count()));
        Observer.Expect('order', 'Low|High.Alpha|High.Mid|High.Zeta');
        Observer.Expect('count', '4');
        Observer.Verify();
    end;

    [Test]
    procedure Order_WithManualBound_MidThenLow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnC Log 1";
        Pub: Codeunit "LT PnC Ev Pub";
        ManMid: Codeunit "LT PnC Ev Sub Man Mid";
        ManLow: Codeunit "LT PnC Ev Sub Man Low";
    begin
        Log.Reset();
        BindSubscription(ManMid);
        BindSubscription(ManLow);
        Pub.Fire();
        Observer.Observe('bothBound', Log.Joined());
        UnbindSubscription(ManMid);
        Log.Reset();
        Pub.Fire();
        Observer.Observe('lowBound', Log.Joined());
        UnbindSubscription(ManLow);
        Log.Reset();
        Pub.Fire();
        Observer.Observe('noneBound', Log.Joined());
        Observer.Expect('bothBound', 'ManLow|Low|ManMid|High.Alpha|High.Mid|High.Zeta');
        Observer.Expect('lowBound', 'ManLow|Low|High.Alpha|High.Mid|High.Zeta');
        Observer.Expect('noneBound', 'Low|High.Alpha|High.Mid|High.Zeta');
        Observer.Verify();
    end;

    [Test]
    procedure Order_WithManualBound_LowThenMid()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnC Log 1";
        Pub: Codeunit "LT PnC Ev Pub";
        ManMid: Codeunit "LT PnC Ev Sub Man Mid";
        ManLow: Codeunit "LT PnC Ev Sub Man Low";
    begin
        Log.Reset();
        BindSubscription(ManLow);
        BindSubscription(ManMid);
        Pub.Fire();
        Observer.Observe('bothBoundOtherBindOrder', Log.Joined());
        UnbindSubscription(ManLow);
        UnbindSubscription(ManMid);
        Log.Reset();
        Pub.Fire();
        Observer.Observe('afterUnbind', Log.Joined());
        Observer.Expect('bothBoundOtherBindOrder', 'ManLow|Low|ManMid|High.Alpha|High.Mid|High.Zeta');
        Observer.Expect('afterUnbind', 'Low|High.Alpha|High.Mid|High.Zeta');
        Observer.Verify();
    end;
}
