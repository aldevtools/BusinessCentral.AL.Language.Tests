// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/trigger/devenv-tryfunction
// Scope: in-scope
//
// What a [TryFunction] with NO `exit` returns — and why that is the OPPOSITE of what
// a plain method with no `exit` returns.
//
// TestCodeunitImplicitDefaultReturn (codeunit 60048) pins AL's implicit default
// return: a method declared with a return type whose body falls off the end answers
// that type's default, so `false` for Boolean. This file pins the case that looks
// identical in source and answers the other way.
//
// A [TryFunction] declares NO return type in AL source. The attribute synthesizes a
// Boolean whose meaning is "the body completed without raising an error", so a body
// that falls off the end answers TRUE. Nothing in the source distinguishes the two
// shapes — neither declares a return type, neither contains an `exit` — and the only
// difference is the attribute line above the signature.
//
// The live instance this was written for is Codeunit 2000 "Time Series Management"
// .GetMLForecastCredentials, whose shipped AL reads:
//
//     [NonDebuggable]
//     [TryFunction]
//     [Scope('OnPrem')]
//     procedure GetMLForecastCredentials(var LocalApiUri: Text[250]; var "Key": SecretText;
//                                        var LimitType: Option; var Limit: Decimal)
//     begin
//         MachineLearningKeyVaultMgmt.GetMachineLearningCredentials(...);
//         LocalApiUri += '/execute?api-version=2.0&details=true';
//     end;
//
// Its SymbolReference carries `ReturnTypeDefinition: Boolean` NEXT TO an
// `Attributes: [ ..., TryFunction, ... ]` entry — the Boolean is the attribute's
// synthesized return, not a declared one. Reading the symbol's return type without
// reading its attributes says "Boolean method with no exit, so it must answer false",
// which is how AL Runner issue #3710 came to record a correct `true` as a defect.
// The probe reproduces [NonDebuggable] + [TryFunction] so the claim is measured
// rather than reasoned about. It does NOT reproduce [Scope('OnPrem')], which a
// Cloud-target app cannot call at all (AL0296, measured on this file); that is a
// compile-time visibility rule, not a statement about the return value.

codeunit 60349 "Test CU TryFunc NoExit Return"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Probe: Codeunit "ALTTryFunctionNoExitProbe";

    // ── A [TryFunction] that completes answers TRUE ─────────────────────────────

    [Test]
    procedure TryFuncNoExit_EmptyBody_IsTrue()
    begin
        Assert.IsTrue(Probe.TryEmptyBody(),
          'A [TryFunction] with an empty body raises nothing, so it must return true.');
    end;

    [Test]
    procedure TryFuncNoExit_AfterCallOutThenByRefWrite_IsTrue()
    var
        Sink: Text;
        Result: Boolean;
    begin
        Sink := 'base';
        Result := Probe.TryAfterCallOutThenByRefWrite(Sink);

        // The byref output pins that the body really ran, so the true cannot be
        // mistaken for the call having been skipped.
        Assert.AreEqual('base/suffix', Sink,
          'The byref parameter must carry the value written after the cross-codeunit call.');
        Assert.IsTrue(Result,
          'A [TryFunction] that falls off the end after a cross-codeunit call must return true.');
    end;

    // Codeunit 2000 also carries [NonDebuggable]. Measured separately from the bare
    // [TryFunction] above so a change in how [NonDebuggable] interacts with the
    // synthesized return is distinguishable from a change in [TryFunction]. Its
    // [Scope('OnPrem')] is not reproduced -- a Cloud-target app cannot call an
    // OnPrem-scoped method (AL0296); see the fixture.
    [Test]
    procedure TryFuncNoExit_NonDebuggable_IsTrue()
    var
        Sink: Text;
        Result: Boolean;
    begin
        Sink := 'base';
        Result := Probe.TryNonDebuggableAfterCallOut(Sink);

        Assert.AreEqual('base/suffix', Sink,
          'The byref parameter must carry the value written after the cross-codeunit call.');
        Assert.IsTrue(Result,
          '[NonDebuggable] + [TryFunction] with no exit must still return true.');
    end;

    [Test]
    procedure TryFuncNoExit_AfterDiscardingTrueFromAnotherCodeunit_IsTrue()
    begin
        Assert.IsTrue(Probe.TryAfterDiscardingTrueFromAnotherCodeunit(),
          'A [TryFunction] returns true because it completed, not because a callee returned true.');
    end;

    // ── A [TryFunction] that raises answers FALSE ───────────────────────────────
    //
    // The negative direction. Without it, every assertion above is also satisfied by
    // a runtime that answers true unconditionally.

    [Test]
    procedure TryFuncNoExit_BodyRaises_IsFalse()
    var
        Sink: Text;
        Result: Boolean;
    begin
        Sink := 'base';
        Result := Probe.TryRaisesAfterByRefWrite(Sink);

        Assert.IsFalse(Result,
          'A [TryFunction] whose body raises must return false, whatever it did beforehand.');
        Assert.AreEqual('ALTTryFunctionNoExitProbe deliberate failure', GetLastErrorText(),
          'The trapped error text must be the one the body raised.');
    end;

    // ── The SAME bodies WITHOUT the attribute answer FALSE ──────────────────────
    //
    // The discriminator. These pin that the true above is produced by [TryFunction]
    // and not by the body shape, the cross-codeunit call or the byref write — each
    // of which is held constant across the two.

    [Test]
    procedure PlainBoolNoExit_EmptyBody_IsFalse()
    begin
        Assert.IsFalse(Probe.PlainBoolEmptyBody(),
          'Without [TryFunction], a Boolean method with an empty body returns AL''s default false.');
    end;

    [Test]
    procedure PlainBoolNoExit_AfterCallOutThenByRefWrite_IsFalse()
    var
        Sink: Text;
        Result: Boolean;
    begin
        Sink := 'base';
        Result := Probe.PlainBoolAfterCallOutThenByRefWrite(Sink);

        Assert.AreEqual('base/suffix', Sink,
          'The byref parameter must carry the value written after the cross-codeunit call.');
        Assert.IsFalse(Result,
          'The identical body without [TryFunction] must return false — the attribute is the only difference.');
    end;
}
