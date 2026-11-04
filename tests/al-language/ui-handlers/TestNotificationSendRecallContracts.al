// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/notification/notification-data-type
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-the-user-interface
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained codeunits 68480 (action target) and 68481 (tests)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins Notification in a test:
//  - A notification nobody set: Message '', Scope LocalScope, HasData false, GetData '' and Id the null Guid;
//    Send gives it an Id.
//  - Send returns true in every case: with no handler (nothing is shown, no error), with a
//    [SendNotificationHandler] that answers true and with one that answers false. The handler gets a notification
//    with the sender's message, scope and data, and what it changes in its var Notification (Message) is seen
//    by the sender afterwards.
//  - Recall of a sent notification returns true, with or without a [RecallNotificationHandler]; the handler
//    runs with the sender's current notification. Recall of a notification that was never sent returns false and
//    does not run the recall handler.
// BC versions: 27.5

codeunit 68480 "Probe Notification Action"
{
    procedure Run(Notif: Notification)
    begin
    end;
}

codeunit 68481 "Probe Notification Send"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        HandlerLog: Text;

    [SendNotificationHandler]
    procedure SendFalseHandler(var Notif: Notification): Boolean
    begin
        HandlerLog += 'send msg=' + Notif.Message() + ' scope=' + Format(Notif.Scope()) + ' data=' + Notif.GetData('k') + ' hasdata=' + Format(Notif.HasData('k')) + ';';
        Notif.Message('changed');
        exit(false);
    end;

    [SendNotificationHandler]
    procedure SendTrueHandler(var Notif: Notification): Boolean
    begin
        HandlerLog += 'send msg=' + Notif.Message() + ';';
        Notif.Message('changed too');
        exit(true);
    end;

    [RecallNotificationHandler]
    procedure RecallHandler(var Notif: Notification): Boolean
    begin
        HandlerLog += 'recall msg=' + Notif.Message() + ';';
        exit(true);
    end;

    [Test]
    procedure Notification_NothingSet_HasEmptyDefaults_AndSendGivesAnId()
    var
        Notif: Notification;
        NullGuid: Guid;
    begin
        Assert.AreEqual('', Notif.Message(), 'Message');
        Assert.AreEqual(NotificationScope::LocalScope, Notif.Scope(), 'Scope');
        Assert.IsFalse(Notif.HasData('k'), 'HasData');
        Assert.AreEqual('', Notif.GetData('k'), 'GetData');
        Assert.AreEqual(NullGuid, Notif.Id(), 'Id before');

        Notif.Message('no handler');
        Assert.IsTrue(Notif.Send(), 'Send without a handler');
        Assert.AreNotEqual(NullGuid, Notif.Id(), 'Id after Send');
        Assert.IsTrue(Notif.Recall(), 'Recall of a sent notification, no handler');
    end;

    [Test]
    [HandlerFunctions('SendFalseHandler')]
    procedure Send_HandlerAnsweringFalse_StillReturnsTrue_AndTheSenderSeesTheChange()
    var
        Notif: Notification;
    begin
        HandlerLog := '';
        Notif.Message('hello');
        Notif.Scope(NotificationScope::LocalScope);
        Notif.AddAction('act', Codeunit::"Probe Notification Action", 'Run');
        Notif.SetData('k', 'v');

        Assert.IsTrue(Notif.Send(), 'Send');

        Assert.AreEqual('send msg=hello scope=LocalScope data=v hasdata=Yes;', HandlerLog, 'handler saw');
        Assert.AreEqual('changed', Notif.Message(), 'message after');
    end;

    [Test]
    [HandlerFunctions('SendTrueHandler,RecallHandler')]
    procedure Recall_RunsTheRecallHandlerWithTheCurrentNotification()
    var
        Notif: Notification;
    begin
        HandlerLog := '';
        Notif.Message('hello');
        Assert.IsTrue(Notif.Send(), 'Send');
        Assert.AreEqual('changed too', Notif.Message(), 'message after Send');

        Assert.IsTrue(Notif.Recall(), 'Recall');

        Assert.AreEqual('send msg=hello;recall msg=changed too;', HandlerLog, 'handlers');
    end;

    [Test]
    [HandlerFunctions('SendTrueHandler')]
    procedure Recall_AfterSendWithNoRecallHandler_ReturnsTrue()
    var
        Notif: Notification;
    begin
        Notif.Message('hello');
        Notif.Send();

        Assert.IsTrue(Notif.Recall(), 'Recall');
    end;

    [Test]
    procedure Recall_NeverSent_ReturnsFalse()
    var
        Notif: Notification;
    begin
        Notif.Message('never sent');

        Assert.IsFalse(Notif.Recall(), 'Recall');
    end;
}
