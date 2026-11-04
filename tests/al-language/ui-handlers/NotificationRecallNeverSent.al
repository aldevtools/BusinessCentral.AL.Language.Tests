// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/notification/notification-recall-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/attributes/devenv-recallnotificationhandler-attribute
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained test codeunit 95240
// Probe (al-runner issue 6924, item 3.3): Notification.Recall of a notification that this variable never sent, with a
//   [RecallNotificationHandler] bound. Base Application code gives a fresh Notification variable a fixed Id and calls Recall
//   without a Send (Purchase Header.RecallModifyAddressNotification), and Microsoft's tests bind a recall handler for it.
//   Observed: whether the handler runs, what it is handed, and what Recall answers, for an Id set and never sent, for no Id,
//   for a second variable with the Id of a sent notification, and without a handler. The handlers are optional
//   (HandlerIsOptional = true, pinned by testpage/notifications-and-control-values/CaNotificationTests.al) so a handler
//   that does not run is an observation, not a failure.
// BC versions: 27-29

codeunit 95240 "LT RN Recall Never Sent"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        HandlerLog: Text;

    [SendNotificationHandler(true)]
    procedure SendOptional(var Notif: Notification): Boolean
    begin
        HandlerLog += 'send msg=' + Notif.Message() + ';';
        exit(true);
    end;

    [RecallNotificationHandler(true)]
    procedure RecallOptional(var Notif: Notification): Boolean
    begin
        HandlerLog += 'recall msg=' + Notif.Message() + ' idnull=' + Format(IsNullGuid(Notif.Id())) + ';';
        exit(true);
    end;

    [Test]
    [HandlerFunctions('RecallOptional')]
    procedure Recall_IdSetNeverSent_HandlerBound()
    var
        Observer: Codeunit "Probe Observer";
        Notif: Notification;
    begin
        HandlerLog := '';
        Notif.Id := '{3F1A2B7C-6924-4C33-9A01-000000000001}';
        Notif.Message('never sent');
        Observer.Observe('recall', Format(Notif.Recall()));
        Observer.Observe('log', HandlerLog);
        Observer.Observe('second recall', Format(Notif.Recall()));
        Observer.Observe('log after second', HandlerLog);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RecallOptional')]
    procedure Recall_IdOnlyNeverSent_HandlerBound()
    var
        Observer: Codeunit "Probe Observer";
        Notif: Notification;
    begin
        HandlerLog := '';
        Notif.Id := '{3F1A2B7C-6924-4C33-9A01-000000000002}';
        Observer.Observe('recall', Format(Notif.Recall()));
        Observer.Observe('log', HandlerLog);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RecallOptional')]
    procedure Recall_NoIdNeverSent_HandlerBound()
    var
        Observer: Codeunit "Probe Observer";
        Notif: Notification;
    begin
        HandlerLog := '';
        Notif.Message('no id');
        Observer.Observe('recall', Format(Notif.Recall()));
        Observer.Observe('log', HandlerLog);
        Observer.Finish();
    end;

    [Test]
    procedure Recall_IdSetNeverSent_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
        Notif: Notification;
    begin
        Notif.Id := '{3F1A2B7C-6924-4C33-9A01-000000000003}';
        Notif.Message('never sent');
        Observer.Observe('recall', Format(Notif.Recall()));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('SendOptional,RecallOptional')]
    procedure Recall_OtherVariableWithIdOfSent_HandlerBound()
    var
        Observer: Codeunit "Probe Observer";
        Sent: Notification;
        Other: Notification;
    begin
        HandlerLog := '';
        Sent.Id := '{3F1A2B7C-6924-4C33-9A01-000000000004}';
        Sent.Message('sent');
        Sent.Send();
        Other.Id := '{3F1A2B7C-6924-4C33-9A01-000000000004}';
        Other.Message('other');
        Observer.Observe('recall other', Format(Other.Recall()));
        Observer.Observe('log', HandlerLog);
        Observer.Observe('recall sent', Format(Sent.Recall()));
        Observer.Observe('log after sent', HandlerLog);
        Observer.Finish();
    end;

    [Test]
    procedure Recall_OtherVariableWithIdOfSent_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
        Sent: Notification;
        Other: Notification;
    begin
        Sent.Id := '{3F1A2B7C-6924-4C33-9A01-000000000005}';
        Sent.Message('sent');
        Sent.Send();
        Other.Id := '{3F1A2B7C-6924-4C33-9A01-000000000005}';
        Observer.Observe('recall other', Format(Other.Recall()));
        Observer.Finish();
    end;
}
