// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/attributes/devenv-sendnotificationhandler-attribute
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); log codeunit 84102 (CaObjects.al, used by this codeunit only)
// Settles corpus issue 667 (odd AL behavior leads, part B), item 14: a SendNotificationHandler or RecallNotificationHandler declared with
// HandlerIsOptional = true lets the test pass when no notification is sent or recalled. The other half of the lead (a handler that is not
// optional and never runs fails the test with "The following UI handlers were not executed") is a failure of the test itself and cannot be
// asserted from AL.
// BC versions: 27, 28, 29
codeunit 84111 "LT CA Notification Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [HandlerFunctions('OptionalSend')]
    procedure Ca14_OptionalSendHandler_NothingSent()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT CA Notif Log";
    begin
        Log.Take();
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OptionalRecall')]
    procedure Ca14_OptionalRecallHandler_NothingRecalled()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT CA Notif Log";
    begin
        Log.Take();
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OptionalSend,OptionalRecall')]
    procedure Ca14_OptionalHandlers_SentAndRecalled()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT CA Notif Log";
        N: Notification;
    begin
        Log.Take();
        N.Id := '{8E0B1E64-1D5B-4C8B-9E55-5F1D0C0A6671}';
        N.Message('LT CA message');
        N.Scope(NotificationScope::LocalScope);
        N.Send();
        Observer.Observe('log-after-send', Log.Take());
        N.Recall();
        Observer.Observe('log-after-recall', Log.Take());
        Observer.Expect('log-after-send', 'send:LT CA message;');
        Observer.Expect('log-after-recall', 'recall:LT CA message;');
        Observer.Verify();
    end;

    [SendNotificationHandler(true)]
    procedure OptionalSend(var N: Notification): Boolean
    var
        Log: Codeunit "LT CA Notif Log";
    begin
        Log.Add('send:' + N.Message());
        exit(true);
    end;

    [RecallNotificationHandler(true)]
    procedure OptionalRecall(var N: Notification): Boolean
    var
        Log: Codeunit "LT CA Notif Log";
    begin
        Log.Add('recall:' + N.Message());
        exit(true);
    end;
}
