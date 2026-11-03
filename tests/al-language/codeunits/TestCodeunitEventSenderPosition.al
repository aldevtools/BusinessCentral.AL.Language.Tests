// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-publisher-subscriber
// Scope: in-scope
// Fixtures used: ALT Sender Position Pub (60970), ALT Sender Position Sub (60971), Assert (60021)
//
// Coverage for [IntegrationEvent(true, false)] — IncludeSender=true — where the subscriber's
// sender parameter is NOT the first parameter. Every existing IncludeSender fixture in this
// corpus ("ALT IncludeSender Table Pub"/"ALT IncludeSender Cu Pub", see
// TestManualTableIncludeSenderEvent.al) declares the sender FIRST; this file proves the AL
// compiler and platform bind the sender wherever it is declared — first, middle, or last —
// and that an error raised through the sender still propagates to the publisher's caller.
//
// The SenderFirstOmit/SenderLastOmit cases additionally prove the sender still binds when
// the subscriber omits a TRAILING publisher parameter entirely (StefanMaron/
// BusinessCentral.AL.Runner#2348's follow-up finding: a subscriber's parameter count is not
// reliably "publisher arity + 1" once omission is legal, so a runner cannot use that as its
// discriminator for "this parameter is the sender").

codeunit 60973 "Test Codeunit Evt SenderPos"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure CodeunitEvent_IncludeSender_SenderFirst_SubscriberReceivesPublisherInstance()
    var
        Pub: Codeunit "ALT Sender Position Pub";
        Value: Integer;
    begin
        // [GIVEN] a subscriber whose Sender parameter is declared FIRST (control)
        Initialize();

        // [WHEN] the publisher raises its IncludeSender=true event
        Value := Pub.ComputeSenderFirst('FIRST');

        // [THEN] the subscriber read GetSeed() through Sender and wrote through Sender.SetMarker
        Assert.AreEqual(110, Value, 'subscriber must read the seed through a usable Sender');
        Assert.AreEqual('FIRST', Pub.GetMarker(), 'subscriber must write through the same Sender instance');
    end;

    [Test]
    procedure CodeunitEvent_IncludeSender_SenderMiddle_SubscriberReceivesPublisherInstance()
    var
        Pub: Codeunit "ALT Sender Position Pub";
        Value: Integer;
    begin
        // [GIVEN] a subscriber whose Sender parameter is declared in the MIDDLE of the list
        Initialize();

        // [WHEN] the publisher raises its IncludeSender=true event
        Value := Pub.ComputeSenderMiddle('MIDDLE');

        // [THEN] the sender still binds correctly regardless of its declared position
        Assert.AreEqual(110, Value, 'subscriber must read the seed through a usable Sender declared mid-list');
        Assert.AreEqual('MIDDLE', Pub.GetMarker(), 'subscriber must write through the same Sender instance');
    end;

    [Test]
    procedure CodeunitEvent_IncludeSender_SenderLast_SubscriberReceivesPublisherInstance()
    var
        Pub: Codeunit "ALT Sender Position Pub";
        Value: Integer;
    begin
        // [GIVEN] a subscriber whose Sender parameter is declared LAST — the shape Base
        // Application's MfgItemJnlPostLine.OnPostOutput uses
        Initialize();

        // [WHEN] the publisher raises its IncludeSender=true event
        Value := Pub.ComputeSenderLast('LAST');

        // [THEN] the sender still binds correctly even as the trailing parameter
        Assert.AreEqual(110, Value, 'subscriber must read the seed through a usable Sender declared last');
        Assert.AreEqual('LAST', Pub.GetMarker(), 'subscriber must write through the same Sender instance');
    end;

    [Test]
    procedure CodeunitEvent_IncludeSender_SenderLast_ErrorRaisedThroughSenderPropagates()
    var
        Pub: Codeunit "ALT Sender Position Pub";
    begin
        // [GIVEN] the same last-position sender shape
        Initialize();

        // [WHEN] the subscriber calls Sender.FailWith(), which raises an error THROUGH the
        // trailing sender parameter
        asserterror Pub.ComputeSenderLast('FAIL');

        // [THEN] the error text raised through Sender propagates unchanged to the caller
        Assert.ExpectedError('ALT sender position fail FAIL');
    end;

    [Test]
    procedure CodeunitEvent_IncludeSender_SenderFirst_TrailingParamOmitted_SenderStillBinds()
    var
        Pub: Codeunit "ALT Sender Position Pub";
        Value: Integer;
    begin
        // [GIVEN] a subscriber whose Sender parameter is declared FIRST, and which omits
        // the publisher's trailing "Tag" parameter entirely (legal AL: a subscriber may
        // declare only a prefix of the publisher's parameters)
        Initialize();

        // [WHEN] the publisher raises its IncludeSender=true event
        Value := Pub.ComputeSenderFirstOmit('OMIT-FIRST');

        // [THEN] the sender still binds even though the subscriber's own parameter count is
        // one short of "publisher arity + 1"
        Assert.AreEqual(110, Value, 'subscriber must read the seed through a usable Sender even with a trailing parameter omitted');
    end;

    [Test]
    procedure CodeunitEvent_IncludeSender_SenderLast_TrailingParamOmitted_SenderStillBinds()
    var
        Pub: Codeunit "ALT Sender Position Pub";
        Value: Integer;
    begin
        // [GIVEN] a subscriber whose Sender parameter is declared LAST, and which likewise
        // omits the publisher's trailing "Tag" parameter
        Initialize();

        // [WHEN] the publisher raises its IncludeSender=true event
        Value := Pub.ComputeSenderLastOmit('OMIT-LAST');

        // [THEN] same claim, sender-last shape: the subscriber's own parameter count (2) is
        // one short of "publisher arity (2) + 1" and the sender must still bind
        Assert.AreEqual(110, Value, 'subscriber must read the seed through a usable Sender even with a trailing parameter omitted');
    end;

    local procedure Initialize()
    begin
    end;
}
