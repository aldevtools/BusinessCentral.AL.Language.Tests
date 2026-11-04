// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/notification/notification-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); codeunits 74880 (publisher), 74881 (subscriber), 74882 (tests)
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: a Notification passed to a procedure that calls SetData and sets the Message; the caller reads HasData, GetData and Message() afterwards, for a by-value
//   parameter, a var parameter, and an event publisher argument (by value and var) whose subscriber changes it. Assignment copies (already pinned elsewhere); here the
//   question is whether by-value passing shares the notification. Settles the assumption notification-by-value-shares.
// BC versions: all (CI)

codeunit 74880 "LT NBV Publisher"
{
    procedure ByValue(N: Notification)
    begin
        N.SetData('key', 'inCallee');
        N.Message('messageInCallee');
    end;

    procedure ByVar(var N: Notification)
    begin
        N.SetData('key', 'inCallee');
        N.Message('messageInCallee');
    end;

    procedure ByValueReadOnly(N: Notification): Text
    begin
        exit(N.Message() + '/' + Format(N.HasData('key')));
    end;

    procedure Raise(N: Notification)
    begin
        OnNotify(N);
    end;

    procedure RaiseVar(var N: Notification)
    begin
        OnNotifyVar(N);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNotify(N: Notification)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNotifyVar(var N: Notification)
    begin
    end;
}

codeunit 74881 "LT NBV Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT NBV Publisher", 'OnNotify', '', false, false)]
    local procedure HandleOnNotify(N: Notification)
    begin
        N.SetData('key', 'inSubscriber');
        N.Message('messageInSubscriber');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT NBV Publisher", 'OnNotifyVar', '', false, false)]
    local procedure HandleOnNotifyVar(var N: Notification)
    begin
        N.SetData('key', 'inSubscriberVar');
        N.Message('messageInSubscriberVar');
    end;
}

codeunit 74882 "LT NBV Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Describe(var Observer: Codeunit "Probe Observer"; Tag: Text; N: Notification)
    begin
        Observer.Observe(Tag + '.hasData', Format(N.HasData('key')));
        if N.HasData('key') then
            Observer.Observe(Tag + '.data', N.GetData('key'));
        Observer.Observe(Tag + '.message', N.Message());
    end;

    [Test]
    procedure ByValue_CalleeSetsDataAndMessage()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT NBV Publisher";
        N: Notification;
    begin
        N.Message('original');
        Pub.ByValue(N);
        Describe(Observer, 'afterByValue', N);
        Observer.Expect('afterByValue.hasData', 'Yes');
        Observer.Expect('afterByValue.data', 'inCallee');
        Observer.Expect('afterByValue.message', 'messageInCallee');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_CalleeSetsData_CallerHadData()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT NBV Publisher";
        N: Notification;
    begin
        N.Message('original');
        N.SetData('key', 'original');
        Pub.ByValue(N);
        Describe(Observer, 'afterByValue', N);
        Observer.Expect('afterByValue.hasData', 'Yes');
        Observer.Expect('afterByValue.data', 'inCallee');
        Observer.Expect('afterByValue.message', 'messageInCallee');
        Observer.Verify();
    end;

    [Test]
    procedure ByVar_CalleeSetsDataAndMessage()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT NBV Publisher";
        N: Notification;
    begin
        N.Message('original');
        Pub.ByVar(N);
        Describe(Observer, 'afterByVar', N);
        Observer.Expect('afterByVar.hasData', 'Yes');
        Observer.Expect('afterByVar.data', 'inCallee');
        Observer.Expect('afterByVar.message', 'messageInCallee');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_CalleeReads()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT NBV Publisher";
        N: Notification;
    begin
        N.Message('original');
        N.SetData('key', 'x');
        Observer.Observe('calleeSees', Pub.ByValueReadOnly(N));
        Observer.Expect('calleeSees', 'original/Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Assignment_Copies()
    var
        Observer: Codeunit "Probe Observer";
        N: Notification;
        Copy2: Notification;
    begin
        N.Message('original');
        N.SetData('key', 'original');
        Copy2 := N;
        Copy2.SetData('key', 'changedCopy');
        Copy2.Message('changedCopyMessage');
        Describe(Observer, 'original', N);
        Describe(Observer, 'copy', Copy2);
        Observer.Expect('original.hasData', 'Yes');
        Observer.Expect('original.data', 'original');
        Observer.Expect('original.message', 'original');
        Observer.Expect('copy.hasData', 'Yes');
        Observer.Expect('copy.data', 'changedCopy');
        Observer.Expect('copy.message', 'changedCopyMessage');
        Observer.Verify();
    end;

    [Test]
    procedure Event_ByValueArgument_SubscriberChanges()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT NBV Publisher";
        N: Notification;
    begin
        N.Message('original');
        Pub.Raise(N);
        Describe(Observer, 'afterEvent', N);
        Observer.Expect('afterEvent.hasData', 'Yes');
        Observer.Expect('afterEvent.data', 'inSubscriber');
        Observer.Expect('afterEvent.message', 'messageInSubscriber');
        Observer.Verify();
    end;

    [Test]
    procedure Event_VarArgument_SubscriberChanges()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT NBV Publisher";
        N: Notification;
    begin
        N.Message('original');
        Pub.RaiseVar(N);
        Describe(Observer, 'afterEventVar', N);
        Observer.Expect('afterEventVar.hasData', 'Yes');
        Observer.Expect('afterEventVar.data', 'inSubscriberVar');
        Observer.Expect('afterEventVar.message', 'messageInSubscriberVar');
        Observer.Verify();
    end;
}
