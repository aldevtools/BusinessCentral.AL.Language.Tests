// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-messagehandler-attribute
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P133 Row (74032) from P133PageTypedHandlers.al; declares page 74038
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a Message, Confirm or StrMenu raised from inside a page handler, a confirm handler or a StrMenu handler (directly, or by an action the handler invokes): whether the matching [MessageHandler] / [ConfirmHandler] / [StrMenuHandler] is called, the order, and the error when none is declared
// BC versions: 29 (27 and 28 by CI)

page 74038 "LT P133 Msg Card"
{
    PageType = Card;
    SourceTable = "LT P133 Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActMsg)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Message('from page action');
                end;
            }
            action(ActConfirm)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    if Confirm('page question?') then
                        Message('page confirmed')
                    else
                        Message('page declined');
                end;
            }
        }
    }
}

codeunit 74039 "LT P133 Msg In Handlers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seen: Text;

    local procedure Seed()
    var
        Row: Record "LT P133 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Seen := '';
    end;

    [MessageHandler]
    procedure MsgH(Msg: Text[1024])
    begin
        Seen += 'msg:' + Msg + ';';
    end;

    [ConfirmHandler]
    procedure ConfYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Seen += 'confirm:' + Question + ';';
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Seen += 'confirm:' + Question + ';';
        Reply := false;
    end;

    [ConfirmHandler]
    procedure ConfYesThenMessage(Question: Text[1024]; var Reply: Boolean)
    begin
        Seen += 'confirm:' + Question + ';';
        Message('from confirm handler');
        Seen += 'confirm after message;';
        Reply := true;
    end;

    [StrMenuHandler]
    procedure MenuSecond(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Seen += 'menu:' + Options + ';';
        Choice := 2;
    end;

    [StrMenuHandler]
    procedure MenuThenMessage(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Seen += 'menu:' + Options + ';';
        Message('from menu handler');
        Seen += 'menu after message;';
        Choice := 3;
    end;

    [ModalPageHandler]
    procedure ModalInvokesMessageAction(var P: TestPage "LT P133 Msg Card")
    begin
        Seen += 'modal:before;';
        P.ActMsg.Invoke();
        Seen += 'modal:after;';
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ModalMessageDirect(var P: TestPage "LT P133 Msg Card")
    begin
        Seen += 'modal:before;';
        Message('direct from modal handler');
        Seen += 'modal:after;';
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ModalConfirmDirect(var P: TestPage "LT P133 Msg Card")
    begin
        Seen += 'modal:before;';
        Seen += 'confirm result=' + Format(Confirm('direct from modal handler?')) + ';';
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ModalInvokesConfirmAction(var P: TestPage "LT P133 Msg Card")
    begin
        Seen += 'modal:before;';
        P.ActConfirm.Invoke();
        Seen += 'modal:after;';
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ModalMessageThenCancel(var P: TestPage "LT P133 Msg Card")
    begin
        Message('then cancel');
        P.Cancel().Invoke();
    end;

    [PageHandler]
    procedure PageMessageDirect(var P: TestPage "LT P133 Msg Card")
    begin
        Seen += 'page:before;';
        Message('direct from page handler');
        Seen += 'page:after;';
    end;

    [PageHandler]
    procedure PageInvokesMessageAction(var P: TestPage "LT P133 Msg Card")
    begin
        Seen += 'page:before;';
        P.ActMsg.Invoke();
        Seen += 'page:after;';
    end;

    [Test]
    [HandlerFunctions('ModalInvokesMessageAction,MsgH')]
    procedure P133_ModalHandler_InvokesActionThatRaisesMessage()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
        Result: Action;
    begin
        Seed();
        Row.Get(1);
        Result := Page.RunModal(Page::"LT P133 Msg Card", Row);
        Observer.Observe('result', Format(Result));
        Observer.Observe('seen', Seen);
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('seen', 'modal:before;msg:from page action;modal:after;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModalMessageDirect,MsgH')]
    procedure P133_ModalHandler_RaisesMessageDirectly()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
        Result: Action;
    begin
        Seed();
        Row.Get(1);
        Result := Page.RunModal(Page::"LT P133 Msg Card", Row);
        Observer.Observe('result', Format(Result));
        Observer.Observe('seen', Seen);
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('seen', 'modal:before;msg:direct from modal handler;modal:after;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModalMessageDirect')]
    procedure P133_ModalHandler_RaisesMessage_NoMessageHandlerDeclared()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.RunModal(Page::"LT P133 Msg Card", Row);
        Observer.ObserveError('run modal');
        Observer.Observe('seen', Seen);
        Observer.Expect('run modal|text', 'Unhandled UI: Message direct from modal handler');
        Observer.Expect('run modal|code', 'MissingUIHandler');
        Observer.Expect('seen', 'modal:before;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModalInvokesMessageAction')]
    procedure P133_ModalHandler_ActionRaisesMessage_NoMessageHandlerDeclared()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.RunModal(Page::"LT P133 Msg Card", Row);
        Observer.ObserveError('run modal');
        Observer.Observe('seen', Seen);
        Observer.Expect('run modal|text', 'Unhandled UI: Message from page action');
        Observer.Expect('run modal|code', 'TestWrapped:MissingUIHandler');
        Observer.Expect('seen', 'modal:before;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModalConfirmDirect,ConfYes')]
    procedure P133_ModalHandler_RaisesConfirmDirectly()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
        Result: Action;
    begin
        Seed();
        Row.Get(1);
        Result := Page.RunModal(Page::"LT P133 Msg Card", Row);
        Observer.Observe('result', Format(Result));
        Observer.Observe('seen', Seen);
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('seen', 'modal:before;confirm result=Yes;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModalInvokesConfirmAction,ConfYes,MsgH')]
    procedure P133_ModalHandler_ActionConfirmsThenMessages_Yes()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
    begin
        Seed();
        Row.Get(1);
        Page.RunModal(Page::"LT P133 Msg Card", Row);
        Observer.Observe('seen', Seen);
        Observer.Expect('seen', 'modal:before;confirm:page question?;msg:page confirmed;modal:after;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModalInvokesConfirmAction,ConfNo,MsgH')]
    procedure P133_ModalHandler_ActionConfirmsThenMessages_No()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
    begin
        Seed();
        Row.Get(1);
        Page.RunModal(Page::"LT P133 Msg Card", Row);
        Observer.Observe('seen', Seen);
        Observer.Expect('seen', 'modal:before;confirm:page question?;msg:page declined;modal:after;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModalMessageThenCancel,MsgH')]
    procedure P133_ModalHandler_MessageThenCancel()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
        Result: Action;
    begin
        Seed();
        Row.Get(1);
        Result := Page.RunModal(Page::"LT P133 Msg Card", Row);
        Observer.Observe('result', Format(Result));
        Observer.Observe('seen', Seen);
        Observer.Expect('result', 'LookupCancel');
        Observer.Expect('seen', 'msg:then cancel;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PageMessageDirect,MsgH')]
    procedure P133_PageHandler_RaisesMessageDirectly()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
    begin
        Seed();
        Row.Get(1);
        Page.Run(Page::"LT P133 Msg Card", Row);
        Observer.Observe('seen', Seen);
        Observer.Expect('seen', 'page:before;msg:direct from page handler;page:after;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PageInvokesMessageAction,MsgH')]
    procedure P133_PageHandler_InvokesActionThatRaisesMessage()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
    begin
        Seed();
        Row.Get(1);
        Page.Run(Page::"LT P133 Msg Card", Row);
        Observer.Observe('seen', Seen);
        Observer.Expect('seen', 'page:before;msg:from page action;page:after;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PageMessageDirect')]
    procedure P133_PageHandler_RaisesMessage_NoMessageHandlerDeclared()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
    begin
        Seed();
        Row.Get(1);
        asserterror Page.Run(Page::"LT P133 Msg Card", Row);
        Observer.ObserveError('run');
        Observer.Observe('seen', Seen);
        Observer.Expect('run|text', 'Unhandled UI: Message direct from page handler');
        Observer.Expect('run|code', 'MissingUIHandler');
        Observer.Expect('seen', 'page:before;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ConfYesThenMessage,MsgH')]
    procedure P133_ConfirmHandler_RaisesMessage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('reply', Format(Confirm('body question?')));
        Observer.Observe('seen', Seen);
        Observer.Expect('reply', 'Yes');
        Observer.Expect('seen', 'confirm:body question?;msg:from confirm handler;confirm after message;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ConfYesThenMessage')]
    procedure P133_ConfirmHandler_RaisesMessage_NoMessageHandlerDeclared()
    var
        Observer: Codeunit "Probe Observer";
        Reply: Boolean;
    begin
        Seed();
        asserterror Reply := Confirm('body question?');
        Observer.ObserveError('confirm');
        Observer.Observe('seen', Seen);
        Observer.Expect('confirm|text', 'Unhandled UI: Message from confirm handler');
        Observer.Expect('confirm|code', 'MissingUIHandler');
        Observer.Expect('seen', 'confirm:body question?;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MenuThenMessage,MsgH')]
    procedure P133_StrMenuHandler_RaisesMessage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('choice', Format(StrMenu('a,b,c')));
        Observer.Observe('seen', Seen);
        Observer.Expect('choice', '3');
        Observer.Expect('seen', 'menu:a,b,c;msg:from menu handler;menu after message;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MenuSecond,MsgH')]
    procedure P133_Control_StrMenuHandler_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('choice', Format(StrMenu('a,b,c')));
        Message('body message');
        Observer.Observe('seen', Seen);
        Observer.Expect('choice', '2');
        Observer.Expect('seen', 'menu:a,b,c;msg:body message;');
        Observer.Verify();
    end;

    // ---- Writer SH, al-runner issue 5943: a Message raised in the test body (directly, or from a procedure of another codeunit) by a
    // test that declares no [MessageHandler]. Does the test go on, and is any error recorded?

    [Test]
    procedure P133_TestBody_Message_NoMessageHandlerDeclared()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Message('body message without a handler');
        Observer.ObserveError('Message');
        Observer.Observe('reached after asserterror', 'yes');
        Observer.Expect('Message|text', 'Unhandled UI: Message body message without a handler');
        Observer.Expect('Message|code', 'MissingUIHandler');
        Observer.Expect('reached after asserterror', 'yes');
        Observer.Verify();
    end;

    [Test]
    procedure P133_CalledCodeunit_Message_NoMessageHandlerDeclared()
    var
        Observer: Codeunit "Probe Observer";
        Messenger: Codeunit "LT SH P133 Messenger";
    begin
        asserterror Messenger.ShowRestored('101022');
        Observer.ObserveError('ShowRestored');
        Observer.Expect('ShowRestored|text', 'Unhandled UI: Message Order 101022 has been restored.');
        Observer.Expect('ShowRestored|code', 'MissingUIHandler');
        Observer.Verify();
    end;
}

codeunit 89421 "LT SH P133 Messenger"
{
    procedure ShowRestored(No: Code[20])
    begin
        Message('Order %1 has been restored.', No);
    end;
}
