// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/notification/notification-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: Notification "Not pinned: a second Recall, a recall handler that answers false" (batch 5)
// BC versions: 29 (27 and 28 by CI)

codeunit 71112 "LT PnC Notification"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        RecallAnswer: Boolean;
        RecallSeen: Text;

    [Test]
    [HandlerFunctions('SendTrue')]
    procedure Recall_Twice_NoRecallHandler()
    var
        Observer: Codeunit "Probe Observer";
        N: Notification;
    begin
        N.Message := 'one';
        N.Send();
        Observer.Observe('first', Format(N.Recall()));
        Observer.Observe('second', Format(N.Recall()));
        Observer.Expect('first', 'Yes');
        Observer.Expect('second', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SendTrue,RecallHandlerVar')]
    procedure Recall_HandlerAnswersFalse()
    var
        Observer: Codeunit "Probe Observer";
        N: Notification;
    begin
        RecallAnswer := false;
        RecallSeen := '';
        N.Message := 'two';
        N.Send();
        Observer.Observe('recallHandlerFalse', Format(N.Recall()));
        Observer.Observe('seen', RecallSeen);
        RecallAnswer := true;
        RecallSeen := '';
        Observer.Observe('recallHandlerTrueSecond', Format(N.Recall()));
        Observer.Observe('seenSecond', RecallSeen);
        Observer.Expect('recallHandlerFalse', 'Yes');
        Observer.Expect('seen', 'two');
        Observer.Expect('recallHandlerTrueSecond', 'Yes');
        Observer.Expect('seenSecond', 'two');
        Observer.Verify();
    end;

    [Test]
    procedure Recall_NeverSent()
    var
        Observer: Codeunit "Probe Observer";
        N: Notification;
    begin
        Observer.Observe('neverSent', Format(N.Recall()));
        Observer.Observe('idIsNull', Format(IsNullGuid(N.Id())));
        Observer.Observe('message', N.Message());
        Observer.Observe('scope', Format(N.Scope()));
        Observer.Observe('hasData', Format(N.HasData('k')));
        Observer.Expect('neverSent', 'No');
        Observer.Expect('idIsNull', 'Yes');
        Observer.Expect('message', '');
        Observer.Expect('scope', 'LocalScope');
        Observer.Expect('hasData', 'No');
        Observer.Verify();
    end;

    [SendNotificationHandler]
    procedure SendTrue(var Notif: Notification): Boolean
    begin
        exit(true);
    end;

    [RecallNotificationHandler]
    procedure RecallHandlerVar(var Notif: Notification): Boolean
    begin
        RecallSeen := Notif.Message();
        exit(RecallAnswer);
    end;
}
