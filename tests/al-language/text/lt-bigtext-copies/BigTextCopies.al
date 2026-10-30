// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/bigtext/bigtext-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own codeunits 90868 (holder and event publisher), 90869 (manual subscriber), 90870 (tests)
// Probe: written for al-runtime-rs assumption bigtext-value-copy (writer Y2). text/TestBigText.al pins assignment, by-value and var procedure
//        parameters and Clear of a copy. This file reads a BigText given to an event subscriber (by value and by var) that calls AddText, and a
//        BigText returned by a procedure that the caller then grows.
// Facts (BC 29 SaaS sandbox; the corpus CI legs check the other majors): a subscriber of an event with a BigText parameter by value grows its own
//        copy (the publisher keeps 'pub'); by var it grows the publisher's BigText. A BigText returned by a procedure is a copy: growing it leaves
//        the callee's global unchanged, and two results of the same procedure are independent.
// BC versions: 27, 28, 29

codeunit 90868 "LT Y2 BigText Holder"
{
    var
        Held: BigText;

    procedure Init(Start: Text)
    begin
        Clear(Held);
        Held.AddText(Start);
    end;

    procedure GetHeld(): BigText
    begin
        exit(Held);
    end;

    procedure HeldLength(): Integer
    begin
        exit(Held.Length());
    end;

    procedure RaiseByValue(var Value: BigText)
    begin
        OnByValue(Value);
    end;

    procedure RaiseByVar(var Value: BigText)
    begin
        OnByVar(Value);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnByValue(Value: BigText)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnByVar(var Value: BigText)
    begin
    end;
}

codeunit 90869 "LT Y2 BigText Subscriber"
{
    EventSubscriberInstance = Manual;

    var
        Seen: Integer;

    procedure SeenLength(): Integer
    begin
        exit(Seen);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT Y2 BigText Holder", 'OnByValue', '', false, false)]
    local procedure GrowByValue(Value: BigText)
    begin
        Value.AddText('-sub');
        Seen := Value.Length();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT Y2 BigText Holder", 'OnByVar', '', false, false)]
    local procedure GrowByVar(var Value: BigText)
    begin
        Value.AddText('-sub');
        Seen := Value.Length();
    end;
}

codeunit 90870 "LT Y2 BigText Copies"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure AsText(var Value: BigText): Text
    var
        T: Text;
    begin
        Value.GetSubText(T, 1, Value.Length());
        exit(T);
    end;

    [Test]
    procedure BigText_EventByValue_SubscriberAddText()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT Y2 BigText Holder";
        Sub: Codeunit "LT Y2 BigText Subscriber";
        Value: BigText;
    begin
        Value.AddText('pub');
        BindSubscription(Sub);
        Holder.RaiseByValue(Value);
        UnbindSubscription(Sub);
        Observer.Observe('subscriber length', Format(Sub.SeenLength()));
        Observer.Observe('publisher length', Format(Value.Length()));
        Observer.Observe('publisher text', AsText(Value));
        Observer.Expect('subscriber length', '7');
        Observer.Expect('publisher length', '3');
        Observer.Expect('publisher text', 'pub');
        Observer.Verify();
    end;

    [Test]
    procedure BigText_EventByVar_SubscriberAddText()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT Y2 BigText Holder";
        Sub: Codeunit "LT Y2 BigText Subscriber";
        Value: BigText;
    begin
        Value.AddText('pub');
        BindSubscription(Sub);
        Holder.RaiseByVar(Value);
        UnbindSubscription(Sub);
        Observer.Observe('subscriber length', Format(Sub.SeenLength()));
        Observer.Observe('publisher length', Format(Value.Length()));
        Observer.Observe('publisher text', AsText(Value));
        Observer.Expect('subscriber length', '7');
        Observer.Expect('publisher length', '7');
        Observer.Expect('publisher text', 'pub-sub');
        Observer.Verify();
    end;

    [Test]
    procedure BigText_ReturnValue_CallerGrows()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT Y2 BigText Holder";
        Got: BigText;
    begin
        Holder.Init('held');
        Got := Holder.GetHeld();
        Got.AddText('-caller');
        Observer.Observe('caller length', Format(Got.Length()));
        Observer.Observe('caller text', AsText(Got));
        Observer.Observe('held length', Format(Holder.HeldLength()));
        Observer.Expect('caller length', '11');
        Observer.Expect('caller text', 'held-caller');
        Observer.Expect('held length', '4');
        Observer.Verify();
    end;

    [Test]
    procedure BigText_ReturnValue_GrowTwoResults()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT Y2 BigText Holder";
        First: BigText;
        Second: BigText;
    begin
        Holder.Init('held');
        First := Holder.GetHeld();
        Second := Holder.GetHeld();
        First.AddText('-one');
        Observer.Observe('first', AsText(First));
        Observer.Observe('second', AsText(Second));
        Observer.Observe('held length', Format(Holder.HeldLength()));
        Observer.Expect('first', 'held-one');
        Observer.Expect('second', 'held');
        Observer.Expect('held length', '4');
        Observer.Verify();
    end;
}
