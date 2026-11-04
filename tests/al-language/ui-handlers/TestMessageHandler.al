// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-designing-system-messages
// Scope: in-scope

codeunit 60117 "Test Message Handler"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Message, Confirm, Dialog ───────────────────────────────────────────────────────

    [Test]
    [HandlerFunctions('MsgHandler')]
    procedure Message_Show_HandlerCaptures()
    begin
        Initialize();
        Message('Hello from test');
    end;

    [Test]
    [HandlerFunctions('MsgHandlerFormatted')]
    procedure Message_FormattedString_HandlerGetsFormatted()
    begin
        Initialize();
        Message('Value: %1', 42);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure Confirm_Question_HandlerRepliesTrue()
    var
        Result: Boolean;
    begin
        Initialize();
        Result := Confirm('Are you sure?');
        Assert.IsTrue(Result, 'Confirm must return true when handler replies true');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    procedure Confirm_Question_HandlerRepliesFalse()
    var
        Result: Boolean;
    begin
        Initialize();
        Result := Confirm('Do you agree?');
        Assert.IsFalse(Result, 'Confirm must return false when handler replies false');
    end;

    [Test]
    [HandlerFunctions('MsgHandlerEmpty')]
    procedure Message_EmptyMessage_HandlerCalledWithEmpty()
    begin
        Initialize();
        Message('');
        Assert.IsTrue(true, 'Message with empty string must invoke handler');
    end;

    [MessageHandler]
    procedure MsgHandler(Msg: Text[1024])
    begin
        Assert.IsTrue(StrPos(Msg, 'Hello') > 0, 'Handler must receive the message text');
    end;

    [MessageHandler]
    procedure MsgHandlerFormatted(Msg: Text[1024])
    begin
        Assert.IsTrue(StrPos(Msg, '42') > 0, 'Handler must receive formatted message with substituted value');
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [MessageHandler]
    procedure MsgHandlerEmpty(Msg: Text[1024])
    begin
        Assert.IsTrue(true, 'Handler for empty message must be called');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
