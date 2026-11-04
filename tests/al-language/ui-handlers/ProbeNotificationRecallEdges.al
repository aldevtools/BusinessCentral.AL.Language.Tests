// Probe: Notification.Recall edges not pinned yet: a second Recall, a recall handler answering false, Recall after
// a Send whose handler answered false.
codeunit 69533 "Probe Notification Edges"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        HandlerLog: Text;

    [SendNotificationHandler]
    procedure SendTrue(var Notif: Notification): Boolean
    begin
        HandlerLog += 'send;';
        exit(true);
    end;

    [SendNotificationHandler]
    procedure SendFalse(var Notif: Notification): Boolean
    begin
        HandlerLog += 'sendFalse;';
        exit(false);
    end;

    [RecallNotificationHandler]
    procedure RecallFalse(var Notif: Notification): Boolean
    begin
        HandlerLog += 'recallFalse;';
        exit(false);
    end;

    [RecallNotificationHandler]
    procedure RecallTrue(var Notif: Notification): Boolean
    begin
        HandlerLog += 'recallTrue;';
        exit(true);
    end;

    [Test]
    [HandlerFunctions('SendTrue,RecallTrue')]
    procedure Recall_Twice_AfterOneSend()
    var
        Notif: Notification;
        Observer: Codeunit "Probe Observer";
    begin
        HandlerLog := '';
        Notif.Message('m');
        Notif.Send();
        Observer.Observe('firstRecall', Format(Notif.Recall()));
        Observer.Observe('secondRecall', Format(Notif.Recall()));
        Observer.Observe('handlerLog', HandlerLog);
        Observer.Expect('firstRecall', 'Yes');
        Observer.Expect('secondRecall', 'Yes');
        Observer.Expect('handlerLog', 'send;recallTrue;recallTrue;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SendTrue,RecallFalse')]
    procedure Recall_HandlerAnsweringFalse()
    var
        Notif: Notification;
        Observer: Codeunit "Probe Observer";
    begin
        HandlerLog := '';
        Notif.Message('m');
        Notif.Send();
        Observer.Observe('recallReturn', Format(Notif.Recall()));
        Observer.Observe('recallAgain', Format(Notif.Recall()));
        Observer.Observe('handlerLog', HandlerLog);
        Observer.Expect('recallReturn', 'Yes');
        Observer.Expect('recallAgain', 'Yes');
        Observer.Expect('handlerLog', 'send;recallFalse;recallFalse;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SendFalse,RecallTrue')]
    procedure Recall_AfterSendWhoseHandlerAnsweredFalse()
    var
        Notif: Notification;
        Observer: Codeunit "Probe Observer";
    begin
        HandlerLog := '';
        Notif.Message('m');
        Observer.Observe('sendReturn', Format(Notif.Send()));
        Observer.Observe('recallReturn', Format(Notif.Recall()));
        Observer.Observe('handlerLog', HandlerLog);
        Observer.Expect('sendReturn', 'Yes');
        Observer.Expect('recallReturn', 'Yes');
        Observer.Expect('handlerLog', 'sendFalse;recallTrue;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SendTrue,RecallTrue')]
    procedure Send_Twice_SameNotification_RecallAfter()
    var
        Notif: Notification;
        Observer: Codeunit "Probe Observer";
    begin
        HandlerLog := '';
        Notif.Message('m');
        Notif.Send();
        Notif.Send();
        Observer.Observe('idUnchanged', Format(IsNullGuid(Notif.Id)));
        Observer.Observe('recall', Format(Notif.Recall()));
        Observer.Observe('handlerLog', HandlerLog);
        Observer.Expect('idUnchanged', 'No');
        Observer.Expect('recall', 'Yes');
        Observer.Expect('handlerLog', 'send;send;recallTrue;');
        Observer.Verify();
    end;
}
