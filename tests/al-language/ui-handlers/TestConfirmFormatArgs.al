// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-confirm-method
// Scope: in-scope
//
// CLAIM: Confirm(Question, Default, Args) does NOT substitute %1/%2/... placeholders
// in Question before the question reaches a declared [ConfirmHandler] — the handler
// receives the raw, literal format string, Args untouched. This was verified against
// real BC (27.5 and 28.3 CI): a first version of this test asserted the substituted
// text (matching the documented interactive-dialog behavior and StrSubstNo semantics)
// and failed on both versions with the raw '%1 ...' string as Actual.
//
// Each test below independently proves substitution DOES work for the same format
// string + args via StrSubstNo, then proves the [ConfirmHandler]'s captured Question
// is exactly the raw format string, NOT the StrSubstNo'd one and NOT equal to it —
// isolating the gap to the Confirm-handler dispatch path specifically, ruling out
// "args never bound" or "Assert helper compares the wrong thing" as explanations.
//
// This is an asymmetry with Message(Question, Args), which DOES substitute before its
// [MessageHandler] runs (see Message_FormattedString_HandlerGetsFormatted in
// TestMessageHandler.al) — substitution only happens on Confirm's interactive
// (non-test) dialog path, not on the [ConfirmHandler] test-dispatch path.
//
// Covers more than one argument, a non-text argument type (integer, decimal via date),
// and that Default is honored when the handler does not override the reply.

codeunit 60952 "Test Confirm Format Args"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        ConfirmFireCount: Integer;
        LastConfirmQuestion: Text;

    [Test]
    [HandlerFunctions('AnswerNo')]
    procedure Confirm_SingleFormatArg_HandlerReceivesRawUnsubstitutedQuestion()
    var
        FormatText: Text;
        SubstitutedText: Text;
    begin
        Initialize();
        FormatText := '%1 configurations are created. Do you want to view them?';
        SubstitutedText := StrSubstNo(FormatText, 2);

        // Prove StrSubstNo itself substitutes with these exact args, so the
        // comparison below is meaningful and not an artifact of a broken helper.
        Assert.AreEqual('2 configurations are created. Do you want to view them?', SubstitutedText,
            'StrSubstNo must substitute %1 with the given arg — sanity check for the assertions below');

        if Confirm(FormatText, true, 2) then;

        Assert.AreEqual(1, ConfirmFireCount, 'ConfirmHandler must fire exactly once');
        // The captured Question is the raw format string, not the substituted one.
        Assert.AreEqual(FormatText, LastConfirmQuestion,
            'ConfirmHandler must receive the literal, unsubstituted Question text');
        Assert.AreNotEqual(SubstitutedText, LastConfirmQuestion,
            'ConfirmHandler must NOT receive the StrSubstNo-substituted Question text');
    end;

    [Test]
    [HandlerFunctions('AnswerNo')]
    procedure Confirm_MultipleMixedTypeFormatArgs_HandlerReceivesRawUnsubstitutedQuestion()
    var
        SomeDate: Date;
        FormatText: Text;
        SubstitutedText: Text;
    begin
        Initialize();
        SomeDate := DMY2Date(15, 1, 2024);
        FormatText := 'Delete %1 records for %2 dated %3?';
        SubstitutedText := StrSubstNo(FormatText, 3, 'Customer', SomeDate);

        // Sanity check: StrSubstNo substitutes integer, text, and date args in order.
        Assert.AreEqual('Delete 3 records for Customer dated 01/15/24?', SubstitutedText,
            'StrSubstNo must substitute all three mixed-type args in order');

        if Confirm(FormatText, true, 3, 'Customer', SomeDate) then;

        Assert.AreEqual(1, ConfirmFireCount, 'ConfirmHandler must fire exactly once');
        Assert.AreEqual(FormatText, LastConfirmQuestion,
            'ConfirmHandler must receive the literal, unsubstituted Question text');
        Assert.AreNotEqual(SubstitutedText, LastConfirmQuestion,
            'ConfirmHandler must NOT receive the StrSubstNo-substituted Question text');
    end;

    [Test]
    [HandlerFunctions('AnswerReplyUnchanged')]
    procedure Confirm_DefaultChoiceHonored_WhenHandlerDoesNotOverrideReply()
    var
        ResultTrue: Boolean;
        ResultFalse: Boolean;
    begin
        Initialize();

        ResultTrue := Confirm('%1 records will be deleted. Continue?', true, 5);
        Assert.IsTrue(ResultTrue, 'Confirm must return the Default (true) when the handler leaves Reply unchanged');

        ResultFalse := Confirm('%1 records will be deleted. Continue?', false, 5);
        Assert.IsFalse(ResultFalse, 'Confirm must return the Default (false) when the handler leaves Reply unchanged');
    end;

    [ConfirmHandler]
    procedure AnswerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        ConfirmFireCount += 1;
        LastConfirmQuestion := Question;
        Reply := false;
    end;

    [ConfirmHandler]
    procedure AnswerReplyUnchanged(Question: Text[1024]; var Reply: Boolean)
    begin
        ConfirmFireCount += 1;
        LastConfirmQuestion := Question;
        // deliberately does not touch Reply — proves Default flows through untouched
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
        ConfirmFireCount := 0;
        LastConfirmQuestion := '';
    end;
}
