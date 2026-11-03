// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/exit-method
// Scope: in-scope
//
// AL's implicit default return: a method declared with a return type whose body
// completes without an `exit(<value>)` returns that type's default — false for
// Boolean, 0 for Integer, '' for Text. This is not a corner case in Microsoft's own
// code: 23 Boolean-returning Base Application methods (28.1) have no `exit` anywhere
// in their bodies and rely on it, including Codeunit 2000 "Time Series Management"
// .GetMLForecastCredentials, whose false return is what makes Cash Flow report
// "You must specify an API URL and an API Key" rather than the Azure ML quota error.
//
// The cases below vary ONE thing: what the body does before falling off the end.
// The interesting variants call into another codeunit first — including one that
// discards a TRUE the callee returned — because a value crossing that boundary must
// not reach the caller's return slot.

codeunit 60048 "Test CU Implicit Def Return"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Probe: Codeunit "ALTImplicitReturnProbe";
        Callee: Codeunit "ALTImplicitReturnCallee";

    [Test]
    procedure ImplicitReturn_EmptyBody_IsFalse()
    begin
        Assert.IsFalse(Probe.BoolEmptyBody(),
          'A Boolean method with an empty body must return false.');
    end;

    [Test]
    procedure ImplicitReturn_LocalWorkOnly_IsFalse()
    begin
        Assert.IsFalse(Probe.BoolLocalWorkOnly(),
          'A Boolean method doing only local work and no exit must return false.');
    end;

    [Test]
    procedure ImplicitReturn_AfterCallingVoidOnAnotherCodeunit_IsFalse()
    begin
        Assert.IsFalse(Probe.BoolAfterCallingVoidOnAnotherCodeunit(),
          'Calling a void method on another codeunit must not change the implicit false return.');
    end;

    [Test]
    procedure ImplicitReturn_AfterCallOutThenByRefWrite_IsFalse()
    var
        Sink: Text;
        Result: Boolean;
    begin
        Sink := 'base';
        Result := Probe.BoolAfterCallOutThenByRefWrite(Sink);

        // The byref output must still be written -- this pins that the call really ran,
        // so a false return cannot be mistaken for the method having been skipped.
        Assert.AreEqual('base/suffix', Sink,
          'The byref parameter must carry the value written after the cross-codeunit call.');
        Assert.IsFalse(Result,
          'Writing a byref parameter after a cross-codeunit call must not change the implicit false return.');
    end;

    [Test]
    procedure ImplicitReturn_AfterDiscardingTrueFromAnotherCodeunit_IsFalse()
    begin
        // The callee returns TRUE and the probe discards it. That discarded true must
        // not surface as the probe's own return value.
        Assert.IsTrue(Callee.ReturnsTrue(),
          'Guard: the callee really does return true, so the next assertion is about discarding it.');
        Assert.IsFalse(Probe.BoolAfterDiscardingTrueFromAnotherCodeunit(),
          'A discarded true from another codeunit must not become this method''s implicit return.');
    end;

    [Test]
    procedure ImplicitReturn_AfterCalleeWritesSeveralByRefs_IsFalse()
    var
        A: Text;
        B: Integer;
        C: Decimal;
        Result: Boolean;
    begin
        A := 'x';
        Result := Probe.BoolAfterCalleeWritesSeveralByRefs(A, B, C);

        Assert.AreEqual('written/suffix', A, 'Text byref must carry the callee write plus the local append.');
        Assert.AreEqual(42, B, 'Integer byref must carry the callee write.');
        Assert.AreEqual(3.5, C, 'Decimal byref must carry the callee write.');
        Assert.IsFalse(Result,
          'Several byref writes across a codeunit boundary must not change the implicit false return.');
    end;

    [Test]
    procedure ImplicitReturn_Integer_AfterCallOut_IsZero()
    begin
        Assert.AreEqual(0, Probe.IntegerAfterCallOut(),
          'An Integer method with no exit must return 0 after a cross-codeunit call.');
    end;

    [Test]
    procedure ImplicitReturn_Text_AfterCallOut_IsEmpty()
    begin
        Assert.AreEqual('', Probe.TextAfterCallOut(),
          'A Text method with no exit must return the empty string after a cross-codeunit call.');
    end;
}
