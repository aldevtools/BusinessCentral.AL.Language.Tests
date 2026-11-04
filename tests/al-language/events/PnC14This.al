// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-this-keyword
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT PnC Log (71071)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: `this` "BindSubscription(this) and any this passed by reference ... a manual-subscriber codeunit that binds itself with BindSubscription(this), then raises its event" (probe batch 4)
// BC versions: 29 (27 and 28 by CI)

codeunit 71145 "LT PnC Log 6"
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

codeunit 71122 "LT PnC This Pub"
{
    [IntegrationEvent(false, false)]
    local procedure OnThing()
    begin
    end;

    procedure Raise()
    begin
        OnThing();
    end;
}

codeunit 71125 "LT PnC This Sub"
{
    EventSubscriberInstance = Manual;

    var
        Log: Codeunit "LT PnC Log 6";
        Hits: Integer;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT PnC This Pub", 'OnThing', '', false, false)]
    local procedure Handle()
    begin
        Hits += 1;
        Log.Add('hit' + Format(Hits));
    end;

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

    procedure PassSelf(): Integer
    begin
        exit(ReadHits(this));
    end;

    local procedure ReadHits(Other: Codeunit "LT PnC This Sub"): Integer
    begin
        exit(Other.GetHits());
    end;

    procedure BumpThroughReference()
    begin
        BumpOther(this);
    end;

    local procedure BumpOther(Other: Codeunit "LT PnC This Sub")
    begin
        Other.Add10();
    end;

    procedure Add10()
    begin
        Hits += 10;
    end;
}

codeunit 71123 "LT PnC This Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure BindSubscription_This()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnC Log 6";
        Pub: Codeunit "LT PnC This Pub";
        Sub: Codeunit "LT PnC This Sub";
    begin
        Log.Reset();
        Pub.Raise();
        Observer.Observe('beforeBind', Format(Sub.GetHits()));
        Sub.BindSelf();
        Pub.Raise();
        Observer.Observe('afterBind', Format(Sub.GetHits()));
        Observer.Observe('log', Log.Joined());
        Sub.UnbindSelf();
        Pub.Raise();
        Observer.Observe('afterUnbind', Format(Sub.GetHits()));
        Observer.Expect('beforeBind', '0');
        Observer.Expect('afterBind', '1');
        Observer.Expect('log', 'hit1');
        Observer.Expect('afterUnbind', '1');
        Observer.Verify();
    end;

    [Test]
    procedure This_PassedByReference()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT PnC This Sub";
    begin
        Observer.Observe('pass', Format(Sub.PassSelf()));
        Sub.BumpThroughReference();
        Observer.Observe('afterBump', Format(Sub.GetHits()));
        Observer.Observe('pass.after', Format(Sub.PassSelf()));
        Observer.Expect('pass', '0');
        Observer.Expect('afterBump', '10');
        Observer.Expect('pass.after', '10');
        Observer.Verify();
    end;
}
