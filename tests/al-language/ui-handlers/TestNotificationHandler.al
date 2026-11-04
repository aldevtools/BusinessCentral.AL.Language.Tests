// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-notifications-with-actions
// Scope: in-scope

codeunit 60114 "Test Notification Handler"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Notification ───────────────────────────────────────────────────────

    [Test]
    [HandlerFunctions('NotificationHandler')]
    procedure Notification_Send_WithMessage_HandlerCaptures()
    var
        Notif: Notification;
    begin
        Initialize();
        Notif.Id := CreateGuid();
        Notif.Message('Test notification from test');
        Notif.Scope(NotificationScope::LocalScope);
        Notif.Send();
    end;

    [Test]
    procedure Notification_Message_SetGet()
    var
        Notif: Notification;
    begin
        Initialize();
        Notif.Message('Hello');
        Assert.AreEqual('Hello', Notif.Message(), 'Notification.Message must return what was set');
    end;

    [Test]
    procedure Notification_Scope_SetLocalScope()
    var
        Notif: Notification;
    begin
        Initialize();
        Notif.Scope(NotificationScope::LocalScope);
        Assert.IsTrue(true, 'Notification.Scope(LocalScope) must not throw');
    end;

    [Test]
    procedure Notification_Id_SetGet()
    var
        Notif: Notification;
        TestGuid: Guid;
    begin
        Initialize();
        TestGuid := CreateGuid();
        Notif.Id := TestGuid;
        Assert.AreEqual(TestGuid, Notif.Id, 'Notification.Id must return the assigned GUID');
    end;

    [Test]
    [HandlerFunctions('NotificationHandlerForRecall')]
    procedure Notification_Recall_DoesNotThrow()
    var
        Notif: Notification;
    begin
        Initialize();
        Notif.Id := CreateGuid();
        Notif.Message('Message to recall');
        Notif.Scope(NotificationScope::LocalScope);
        Notif.Send();
        Notif.Recall();
        Assert.IsTrue(true, 'Notification.Recall must not throw');
    end;

    [SendNotificationHandler]
    procedure NotificationHandler(var Notification: Notification): Boolean
    begin
        Assert.IsTrue(Notification.Message() <> '', 'Notification message must not be empty');
        exit(true);
    end;

    [SendNotificationHandler]
    procedure NotificationHandlerForRecall(var Notification: Notification): Boolean
    begin
        Assert.IsTrue(Notification.Message() <> '', 'Notification for recall must contain message');
        exit(true);
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
