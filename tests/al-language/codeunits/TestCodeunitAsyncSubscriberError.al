// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: none (self-contained three-codeunit publish/relay/leaf chain,
// IDs 60220-60222)
// Note: an error raised two event-levels down must reach the original
// publisher's caller, even though the middle subscriber (which itself raises
// another event) is emitted by BC as an async state machine.
// BC versions: 24+

codeunit 60223 "Test Codeunit Async Sub Error"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ErrorRaisedUnderAnAsyncEmittedSubscriber_ReachesTheCaller()
    var
        Publisher: Codeunit "EASE Level1 Publisher";
    begin
        Initialize();
        // The leaf subscriber calls Error(). Between it and this test sits a
        // subscriber that raises its own event, which BC emits as an async state
        // machine — so the error surfaces on that state machine's returned task
        // rather than propagating out of the invocation. If the runner discards
        // that task, this call returns NORMALLY and the failure is invisible.
        asserterror Publisher.Publish('raise');

        if StrPos(GetLastErrorText(), 'LEAF-RAISED-THIS') = 0 then
            Error('Expected the leaf subscriber''s error to reach the caller, got: "%1"', GetLastErrorText());
    end;

    [Test]
    procedure SuccessfulChain_StillReportsItsResult()
    var
        Publisher: Codeunit "EASE Level1 Publisher";
    begin
        Initialize();
        // Positive control: the same two-level chain must still run to completion
        // and report back through the by-var parameter when nothing raises. Without
        // this, "make every dispatch throw" would pass the test above.
        if not Publisher.Publish('ok') then
            Error('The leaf subscriber set Handled := true, but the caller observed false — the two-level chain did not complete.');
    end;

    local procedure Initialize()
    begin
    end;
}
