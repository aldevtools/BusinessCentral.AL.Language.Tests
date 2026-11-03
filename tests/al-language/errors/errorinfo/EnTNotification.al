// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/notification/notification-data-type
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
//
// Notification: Id, Message, Scope, Send / Recall with handlers, SetData / GetData / HasData, AddAction, copy semantics.
// Fixtures used: Probe Observer (69160); self-contained codeunits 73029, 73030, 73031
// BC versions: 29 (27 and 28 by CI)

codeunit 73029 "LT EnT Notif Actions"
{
    procedure Act(Notif: Notification)
    begin
    end;
}

codeunit 73030 "LT EnT Notification"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SeenMessage: Text;
        SeenScope: Text;
        SeenCount: Integer;
        SeenRecallCount: Integer;
        SeenData: Text;
        SeenIdSame: Boolean;
        ExpectedId: Guid;

    [Test]
    procedure Defaults()
    var
        Observer: Codeunit "Probe Observer";
        N: Notification;
    begin
        Observer.Observe('message', N.Message());
        Observer.Observe('scope', Format(N.Scope));
        Observer.Observe('id null', Format(IsNullGuid(N.Id())));
        Observer.Observe('hasdata', Format(N.HasData('k')));
        Observer.Expect('message', '');
        Observer.Expect('scope', 'LocalScope');
        Observer.Expect('id null', 'Yes');
        Observer.Expect('hasdata', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Id_SetGet()
    var
        Observer: Codeunit "Probe Observer";
        N: Notification;
        N2: Notification;
        G: Guid;
    begin
        G := CreateGuid();
        N.Id := G;
        Observer.Observe('equal', Format(N.Id() = G));
        N2.Id := G;
        Observer.Observe('second equal', Format(N2.Id() = N.Id()));
        Clear(G);
        N.Id := G;
        Observer.Observe('null set', Format(IsNullGuid(N.Id())));
        N2 := N;
        Observer.Observe('copied id', Format(N2.Id() = N.Id()));
        Observer.Expect('equal', 'Yes');
        Observer.Expect('second equal', 'Yes');
        Observer.Expect('null set', 'Yes');
        Observer.Expect('copied id', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Message_Edge()
    var
        Observer: Codeunit "Probe Observer";
        N: Notification;
    begin
        N.Message := 'hello';
        Observer.Observe('set', N.Message());
        N.Message := '';
        Observer.Observe('empty', N.Message());
        N.Message := PadStr('', 5000, 'x');
        Observer.Observe('long len', Format(StrLen(N.Message())));
        N.Message := 'äöü ✓ %1';
        Observer.Observe('unicode', N.Message());
        Observer.Expect('set', 'hello');
        Observer.Expect('empty', '');
        Observer.Expect('long len', '5000');
        Observer.Expect('unicode', 'äöü ✓ %1');
        Observer.Verify();
    end;

    [Test]
    procedure Scope_Values()
    var
        Observer: Codeunit "Probe Observer";
        N: Notification;
    begin
        N.Scope := NotificationScope::LocalScope;
        Observer.Observe('local', Format(N.Scope));
        N.Scope := NotificationScope::GlobalScope;
        Observer.Observe('global', Format(N.Scope));
        Observer.Observe('local ord', Format(NotificationScope::LocalScope, 0, 2));
        Observer.Observe('global ord', Format(NotificationScope::GlobalScope, 0, 2));
        Observer.Expect('local', 'LocalScope');
        Observer.Expect('global', 'GlobalScope');
        Observer.Expect('local ord', '0');
        Observer.Expect('global ord', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Data_AllValueTypes()
    var
        Observer: Codeunit "Probe Observer";
        N: Notification;
    begin
        N.SetData('text', 'abc');
        N.SetData('int', Format(42));
        N.SetData('empty', '');
        N.SetData('long', PadStr('', 5000, 'y'));
        N.SetData('unicode', 'äö✓');
        N.SetData('', 'emptykey');
        Observer.Observe('text', N.GetData('text'));
        Observer.Observe('int', N.GetData('int'));
        Observer.Observe('empty', N.GetData('empty'));
        Observer.Observe('long len', Format(StrLen(N.GetData('long'))));
        Observer.Observe('unicode', N.GetData('unicode'));
        Observer.Observe('emptykey', N.GetData(''));
        Observer.Observe('has text', Format(N.HasData('text')));
        Observer.Observe('has empty', Format(N.HasData('empty')));
        Observer.Observe('has emptykey', Format(N.HasData('')));
        Observer.Expect('text', 'abc');
        Observer.Expect('int', '42');
        Observer.Expect('empty', '');
        Observer.Expect('long len', '5000');
        Observer.Expect('unicode', 'äö✓');
        Observer.Expect('emptykey', 'emptykey');
        Observer.Expect('has text', 'Yes');
        Observer.Expect('has empty', 'Yes');
        Observer.Expect('has emptykey', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Data_Missing_And_Overwrite()
    var
        Observer: Codeunit "Probe Observer";
        N: Notification;
    begin
        Observer.Observe('has missing', Format(N.HasData('nope')));
        Observer.Observe('get missing', N.GetData('nope'));
        Observer.Observe('get missing', 'no error');
        N.SetData('k', 'one');
        N.SetData('k', 'two');
        Observer.Observe('overwritten', N.GetData('k'));
        Observer.Observe('case differs', Format(N.HasData('K')));
        Observer.Observe('trailing space', Format(N.HasData('k ')));
        N.SetData('Key', 'x');
        Observer.Observe('case get', N.GetData('KEY'));
        Observer.Expect('has missing', 'No');
        Observer.Expect('get missing', '');
        Observer.Expect('get missing', 'no error');
        Observer.Expect('overwritten', 'two');
        Observer.Expect('case differs', 'No');
        Observer.Expect('trailing space', 'No');
        Observer.Expect('case get', '');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_Semantics()
    var
        Observer: Codeunit "Probe Observer";
        A: Notification;
        B: Notification;
    begin
        A.Message := 'one';
        A.SetData('k', 'a');
        B := A;
        B.Message := 'two';
        B.SetData('k', 'b');
        B.SetData('k2', 'c');
        Observer.Observe('a message', A.Message());
        Observer.Observe('a data', A.GetData('k'));
        Observer.Observe('a has k2', Format(A.HasData('k2')));
        Observer.Observe('b message', B.Message());
        Clear(A);
        Observer.Observe('cleared message', A.Message());
        Observer.Observe('cleared has', Format(A.HasData('k')));
        Observer.Observe('b kept', B.GetData('k'));
        Observer.Expect('a message', 'one');
        Observer.Expect('a data', 'a');
        Observer.Expect('a has k2', 'No');
        Observer.Expect('b message', 'two');
        Observer.Expect('cleared message', '');
        Observer.Expect('cleared has', 'No');
        Observer.Expect('b kept', 'b');
        Observer.Verify();
    end;

    [Test]
    procedure AddAction_Variants()
    var
        Observer: Codeunit "Probe Observer";
        N: Notification;
    begin
        N.AddAction('Do', Codeunit::"LT EnT Notif Actions", 'Act');
        Observer.Observe('one', 'ok');
        N.AddAction('Do 2', Codeunit::"LT EnT Notif Actions", 'Act', 'Description');
        Observer.Observe('with description', 'ok');
        N.AddAction('x', 0, 'Act');
        Observer.Observe('codeunit zero', 'no error');
        N.AddAction('x', 99999999, 'Act');
        Observer.Observe('codeunit missing', 'no error');
        N.AddAction('x', Codeunit::"LT EnT Notif Actions", 'Nope');
        Observer.Observe('method missing', 'no error');
        N.AddAction('', Codeunit::"LT EnT Notif Actions", 'Act');
        Observer.Observe('empty caption', 'ok');
        Observer.Expect('one', 'ok');
        Observer.Expect('with description', 'ok');
        Observer.Expect('codeunit zero', 'no error');
        Observer.Expect('codeunit missing', 'no error');
        Observer.Expect('method missing', 'no error');
        Observer.Expect('empty caption', 'ok');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SendHandler')]
    procedure Send_Handler()
    var
        Observer: Codeunit "Probe Observer";
        N: Notification;
        G: Guid;
    begin
        SeenCount := 0;
        G := CreateGuid();
        ExpectedId := G;
        N.Id := G;
        N.Message := 'to send';
        N.Scope := NotificationScope::LocalScope;
        N.SetData('k', 'v');
        N.Send();
        Observer.Observe('count', Format(SeenCount));
        Observer.Observe('message', SeenMessage);
        Observer.Observe('scope', SeenScope);
        Observer.Observe('data', SeenData);
        Observer.Observe('id same', Format(SeenIdSame));
        Observer.Expect('count', '1');
        Observer.Expect('message', 'to send');
        Observer.Expect('scope', 'LocalScope');
        Observer.Expect('data', 'v');
        Observer.Expect('id same', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SendHandler')]
    procedure Send_Twice_GlobalScope()
    var
        Observer: Codeunit "Probe Observer";
        N: Notification;
    begin
        SeenCount := 0;
        N.Message := 'global';
        N.Scope := NotificationScope::GlobalScope;
        N.Send();
        N.Send();
        Observer.Observe('count', Format(SeenCount));
        Observer.Observe('scope', SeenScope);
        Observer.Expect('count', '2');
        Observer.Expect('scope', 'GlobalScope');
        Observer.Verify();
    end;

    [Test]
    procedure Send_EmptyMessage()
    var
        Observer: Codeunit "Probe Observer";
        N: Notification;
    begin
        SeenCount := 0;
        asserterror N.Send();
        Observer.ObserveError('af234');
        Observer.Observe('count', Format(SeenCount));
        Observer.Observe('message', SeenMessage);
        Observer.Expect('af234|text', 'Message cannot be empty when sending a Notification.');
        Observer.Expect('af234|code', 'Notification');
        Observer.Expect('count', '0');
        Observer.Expect('message', 'global');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SendHandler,RecallHandler')]
    procedure Recall_Handler()
    var
        Observer: Codeunit "Probe Observer";
        N: Notification;
    begin
        SeenCount := 0;
        SeenRecallCount := 0;
        N.Message := 'recall me';
        N.Send();
        Observer.Observe('recall result', Format(N.Recall()));
        Observer.Observe('send count', Format(SeenCount));
        Observer.Observe('recall count', Format(SeenRecallCount));
        Observer.Observe('recall message', SeenMessage);
        Observer.Expect('recall result', 'Yes');
        Observer.Expect('send count', '1');
        Observer.Expect('recall count', '1');
        Observer.Expect('recall message', 'recall me');
        Observer.Verify();
    end;

    [Test]
    procedure Recall_NeverSent()
    var
        Observer: Codeunit "Probe Observer";
        N: Notification;
    begin
        SeenRecallCount := 0;
        N.Message := 'never sent';
        Observer.Observe('recall result', Format(N.Recall()));
        Observer.Observe('recall count', Format(SeenRecallCount));
        Observer.Expect('recall result', 'No');
        Observer.Expect('recall count', '0');
        Observer.Verify();
    end;

    [SendNotificationHandler]
    procedure SendHandler(var Notif: Notification): Boolean
    begin
        SeenCount += 1;
        SeenMessage := Notif.Message();
        SeenScope := Format(Notif.Scope);
        if Notif.HasData('k') then
            SeenData := Notif.GetData('k')
        else
            SeenData := '<none>';
        SeenIdSame := Notif.Id() = ExpectedId;
    end;

    [RecallNotificationHandler]
    procedure RecallHandler(var Notif: Notification): Boolean
    begin
        SeenRecallCount += 1;
        SeenMessage := Notif.Message();
    end;
}
