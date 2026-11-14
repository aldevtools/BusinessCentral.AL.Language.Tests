// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-sendnotificationhandler-attribute
// Scope: in-scope
// Fixtures used: Probe Observer (69160); codeunit 71972 (the sender), test codeunit 71973
// Probe: DRAFT, observe form, not yet run on BC (al-runner issue 7835). Every value is observed; the pipeline turns them into Expect lines.
// Facts: a [SendNotificationHandler] whose code sends a second notification, directly and through a called codeunit:
//   whether the handler runs again for the second notification (nested, before the first handler returns), the order of the
//   handler log, what the second Send returns, the message each run sees, and a third level (the second run sends again);
//   a [RecallNotificationHandler] that sends a notification; and a SendNotificationHandler that raises a Message with a
//   [MessageHandler] declared.
// BC versions: 27, 28, 29 by CI

// local object: the sender codeunit is the code path under test (Send from a codeunit the handler calls)
codeunit 71972 "UIH Notif Nested Sender"
{
    procedure SendOne(Msg: Text): Boolean
    var
        N: Notification;
    begin
        N.Message := Msg;
        exit(N.Send());
    end;
}

codeunit 71973 "UIH Notif Nested Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Text;
        Depth: Integer;
        Seen: Integer;
        Levels: Integer;

    local procedure Initialize()
    begin
        Log := '';
        Depth := 0;
        Seen := 0;
        Levels := 0;
    end;

    [Test]
    [HandlerFunctions('SendAgainHandler')]
    procedure SendHandler_SendsSecond_ThroughCodeunit()
    var
        S: Codeunit "UIH Notif Nested Sender";
    begin
        Initialize();
        Levels := 2;
        Observer.Observe('first send', Format(S.SendOne('first')));
        Observer.Observe('log', Log);
        Observer.Observe('runs', Format(Seen));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('SendAgainDirectHandler')]
    procedure SendHandler_SendsSecond_Directly()
    var
        S: Codeunit "UIH Notif Nested Sender";
    begin
        Initialize();
        Levels := 2;
        Observer.Observe('first send', Format(S.SendOne('first')));
        Observer.Observe('log', Log);
        Observer.Observe('runs', Format(Seen));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('SendAgainHandler')]
    procedure SendHandler_SendsThreeLevels()
    var
        S: Codeunit "UIH Notif Nested Sender";
    begin
        Initialize();
        Levels := 3;
        Observer.Observe('first send', Format(S.SendOne('first')));
        Observer.Observe('log', Log);
        Observer.Observe('runs', Format(Seen));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RecallSendsHandler,SendLogHandler')]
    procedure RecallHandler_SendsNotification()
    var
        N: Notification;
    begin
        Initialize();
        N.Message := 'to recall';
        N.Send();
        Observer.Observe('recall', Format(N.Recall()));
        Observer.Observe('log', Log);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('SendMessagesHandler,MsgHandler')]
    procedure SendHandler_RaisesMessage()
    var
        S: Codeunit "UIH Notif Nested Sender";
    begin
        Initialize();
        Observer.Observe('send', Format(S.SendOne('with message')));
        Observer.Observe('log', Log);
        Observer.Finish();
    end;

    [SendNotificationHandler]
    procedure SendAgainHandler(var Notification: Notification): Boolean
    var
        S: Codeunit "UIH Notif Nested Sender";
    begin
        Seen += 1;
        Depth += 1;
        Log += 'enter ' + Format(Depth) + ' ' + Notification.Message + ';';
        if Seen < Levels then
            Log += 'inner send=' + Format(S.SendOne('level ' + Format(Seen + 1))) + ';';
        Log += 'leave ' + Format(Depth) + ' ' + Notification.Message + ';';
        Depth -= 1;
        exit(true);
    end;

    [SendNotificationHandler]
    procedure SendAgainDirectHandler(var Notification: Notification): Boolean
    var
        Second: Notification;
    begin
        Seen += 1;
        Depth += 1;
        Log += 'enter ' + Format(Depth) + ' ' + Notification.Message + ';';
        if Seen < Levels then begin
            Second.Message := 'level ' + Format(Seen + 1);
            Log += 'inner send=' + Format(Second.Send()) + ';';
        end;
        Log += 'leave ' + Format(Depth) + ' ' + Notification.Message + ';';
        Depth -= 1;
        exit(true);
    end;

    [SendNotificationHandler]
    procedure SendLogHandler(var Notification: Notification): Boolean
    begin
        Log += 'send ' + Notification.Message + ';';
        exit(true);
    end;

    [RecallNotificationHandler]
    procedure RecallSendsHandler(var Notification: Notification): Boolean
    var
        S: Codeunit "UIH Notif Nested Sender";
    begin
        Log += 'recall ' + Notification.Message + ';';
        Log += 'send from recall=' + Format(S.SendOne('from recall')) + ';';
        exit(true);
    end;

    [SendNotificationHandler]
    procedure SendMessagesHandler(var Notification: Notification): Boolean
    begin
        Log += 'send ' + Notification.Message + ';';
        Message('inside send handler');
        Log += 'after message;';
        exit(true);
    end;

    [MessageHandler]
    procedure MsgHandler(Msg: Text[1024])
    begin
        Log += 'message ' + Msg + ';';
    end;
}
