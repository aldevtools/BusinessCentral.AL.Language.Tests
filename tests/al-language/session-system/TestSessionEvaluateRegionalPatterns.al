// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/generalfunctions/evaluate-method
// Scope: in-scope
// Fixtures used: Assert (60021)
//
// A session's regional-settings patterns (ShortDatePattern / LongTimePattern / etc.) must be
// fully populated so that Evaluate into DateTime/Date/Time works correctly for both the
// invariant XML round-trip form and the session's own regional format. Evaluate must also
// correctly reject garbage input (return false, or raise a trappable AL error when the
// return value is ignored) rather than crash.

codeunit 60587 "Test Session Evaluate Regional"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    trigger OnRun()
    begin
    end;

    local procedure Initialize()
    begin
    end;

    [Test]
    procedure TestSession_EvaluateIntoDateTime_XmlFormatLiteral_Succeeds()
    var
        Dt: DateTime;
        Ok: Boolean;
    begin
        Initialize();

        // ISO-ish round-trip literal — Evaluate accepts the invariant "O" form regardless
        // of the session's regional patterns, but reaching that branch still walks the
        // pattern-based branch first.
        Ok := Evaluate(Dt, '2026-01-02T10:11:12.0000000Z', 9);
        Assert.IsTrue(Ok, 'Evaluate of an XML-format DateTime literal must succeed');
        Assert.IsFalse(Dt = 0DT, 'the evaluated DateTime must not be the null DateTime');
    end;

    [Test]
    procedure TestSession_EvaluateIntoDateTime_UsesSessionRegionalPatterns()
    var
        Dt: DateTime;
        Ok: Boolean;
    begin
        Initialize();

        // No format number → the session's ShortDatePattern / LongTimePattern drive parsing.
        Ok := Evaluate(Dt, Format(CurrentDateTime));
        Assert.IsTrue(Ok, 'Evaluate of a session-formatted DateTime must round-trip');
        Assert.IsFalse(Dt = 0DT, 'the round-tripped DateTime must not be the null DateTime');
    end;

    [Test]
    procedure TestSession_EvaluateIntoDateAndTime_Succeed()
    var
        D: Date;
        T: Time;
    begin
        Initialize();

        Assert.IsTrue(Evaluate(D, Format(Today)), 'Evaluate into a Date must succeed');
        Assert.IsTrue(D <> 0D, 'the evaluated Date must not be the null Date');
        Assert.IsTrue(Evaluate(T, Format(Time)), 'Evaluate into a Time must succeed');
    end;

    // Negative direction: garbage must be REJECTED (return false), not crash and not
    // silently produce a value.
    [Test]
    procedure TestSession_EvaluateIntoDateTime_NonDateTimeText_ReturnsFalse()
    var
        Dt: DateTime;
        Ok: Boolean;
    begin
        Initialize();

        Ok := Evaluate(Dt, 'not a datetime at all');
        Assert.IsFalse(Ok, 'Evaluate of non-date text must return false');
        Assert.IsTrue(Dt = 0DT, 'a rejected Evaluate must leave the DateTime at its null value');
    end;

    [Test]
    procedure TestSession_EvaluateIntoDateTime_NonDateTimeTextWithoutTrap_RaisesAlError()
    var
        Dt: DateTime;
    begin
        Initialize();

        // Ignoring Evaluate's return value makes it raise on failure. That error must be a
        // real, trappable AL error — Assert.ExpectedError('') asserts NO error text (it
        // requires GetLastErrorText = ''), so it would only pass here if the raise were a
        // vacuous no-message error. Assert on the actual real BC error text instead.
        asserterror Evaluate(Dt, 'not a datetime at all', 9);
        Assert.ExpectedError('can''t be evaluated');
    end;
}
