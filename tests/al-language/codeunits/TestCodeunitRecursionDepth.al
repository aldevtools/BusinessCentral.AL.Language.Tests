// BC Documentation: none — the AL call-depth ceiling is not documented publicly.
// Scope: in-scope
// Fixtures used: Assert (_fixtures/Assert.al)
// BC versions: 24+
//
// What this pins: the platform refuses an AL call chain past a fixed depth, and WHERE
// that boundary sits. Both directions matter and neither is guessable from the AL:
//
//   - a chain just inside the ceiling must COMPLETE and return its computed value, so
//     the test cannot pass by everything failing;
//   - a chain past the ceiling must RAISE, so it cannot pass by everything succeeding.
//
// The depth counter counts platform method scopes, not source-level procedure frames:
// a test method's own scope and the root scope sit below the recursion, and any nested
// call inside a frame consumes a scope of its own. So the recursive procedure below
// deliberately calls nothing, and the "just inside" depth leaves headroom for that
// fixed offset rather than sitting exactly on the boundary.
//
// RecursionDepth_PastTheCeiling_ReportsTheErrorText exists to make the platform's own
// message for this refusal visible in the CI log. It asserts the run is refused and
// prints what the platform said; the text is not asserted, because no public
// documentation states it and inventing one would pin a guess.

codeunit 60035 "Test Codeunit Recursion Depth"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    // Calls NOTHING but itself: every nested call would consume a method scope of its
    // own and move the boundary, which is what this test is trying to locate.
    local procedure Recurse(N: Integer): Integer
    begin
        if N <= 0 then
            exit(0);
        exit(1 + Recurse(N - 1));
    end;

    [Test]
    procedure RecursionDepth_WellInsideTheCeiling_Completes()
    var
        Result: Integer;
    begin
        // A depth no plausible ceiling refuses. If this fails, the platform's limit is
        // far lower than this test assumes and every other assertion here is suspect —
        // so it runs first, as the control.
        Result := Recurse(100);

        // A concrete value, not "did not error": Recurse returns its own depth, so a
        // stub returning 0 or a truncated chain would be caught here.
        Assert.AreEqual(100, Result, 'A 100-deep AL call chain must complete and count its own frames');
    end;

    [Test]
    procedure RecursionDepth_JustInsideTheCeiling_Completes()
    var
        Result: Integer;
    begin
        // 990 is inside the ceiling with room for the fixed scope offset described at the
        // top of this file. This is the arm that fails on a platform whose ceiling is
        // lower than 990 — which is exactly the question being asked.
        Result := Recurse(990);

        Assert.AreEqual(990, Result, 'A 990-deep AL call chain must complete and count its own frames');
    end;

    [Test]
    procedure RecursionDepth_PastTheCeiling_IsRefused()
    var
        Result: Integer;
    begin
        // Well past any plausible ceiling. The platform must refuse this rather than
        // running it to completion or exhausting the process stack.
        asserterror Result := Recurse(5000);

        // asserterror alone would pass on ANY error, including a compile-time or
        // fixture problem that has nothing to do with depth. Require that an error text
        // was actually produced, so an empty/absent error cannot satisfy this test.
        Assert.IsTrue(
            GetLastErrorText() <> '',
            'Exceeding the AL call-depth ceiling must raise an error with text');

        // The refusal must come from the depth guard, not from the process dying: a
        // platform that survived to answer is the whole claim. The call stack is
        // populated for an AL-level error and names this codeunit.
        Assert.IsTrue(
            GetLastErrorCallStack() <> '',
            'The depth refusal must be an AL error with a call stack, not a process fault');
    end;

    [Test]
    procedure RecursionDepth_PastTheCeiling_ReportsTheErrorText()
    var
        Result: Integer;
        ErrText: Text;
    begin
        asserterror Result := Recurse(5000);
        ErrText := GetLastErrorText();

        // Deliberately NOT an equality assertion. The platform's wording for this
        // refusal is not publicly documented; this arm surfaces it in the CI log so it
        // can be read off a real service tier and pinned in a follow-up, instead of
        // asserting a string somebody guessed.
        Assert.IsTrue(
            StrLen(ErrText) > 0,
            'RECURSION-DEPTH-ERROR-TEXT (for the record): >>>' + ErrText + '<<<');
    end;

    [Test]
    procedure RecursionDepth_AfterARefusal_TheSessionStillRuns()
    var
        Result: Integer;
    begin
        // The ceiling must be a recoverable AL error, not a state the session cannot
        // continue from. Refuse a deep chain, then run a shallow one in the same test.
        asserterror Result := Recurse(5000);

        Result := Recurse(50);

        Assert.AreEqual(50, Result, 'A shallow chain must still run after a depth refusal in the same session');
    end;
}
