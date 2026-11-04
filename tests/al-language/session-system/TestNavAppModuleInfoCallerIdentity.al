// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/navapp/navapp-getcallermoduleinfo-method
// Scope: in-scope
// Fixtures used: "NavApp ModuleInfo Callee" (60384), "NavApp ModuleInfo Callee Hop" (60385)
//
// SAME-APP ADAPTATION OF A CROSS-APP-BOUNDARY TEST — see NavAppModuleInfoCallee.al for
// the full note. In short: the original suite spanned a dependency app and a consumer
// app; this corpus has one app.json, so every codeunit below is compiled into the SAME
// module. That means GetCurrentModuleInfo/GetCallerModuleInfo report the SAME module
// id/name everywhere here — the true cross-app "dependency sees its own identity vs.
// the consumer's" case cannot be expressed and is NOT covered by this file. That is
// expected and accepted degradation, not a bug.
//
// What DOES still transfer, and is what this file actually pins: NavApp.GetCallerModuleInfo
// must name the IMMEDIATE caller — the previous method scope on the call chain — not a
// more distant frame further up. See AL Runner commit 57ef97a0 for the regression this
// protects against: the runner used to skip past same-app frames hunting for a
// "foreign" module, which disagrees with BC's own rule (break on the very next stack
// frame, regardless of app).

codeunit 60383 "Test NavApp Caller Identity"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure NavApp_GetCurrentModuleInfo_ReturnsNonEmptyIdentity()
    var
        Callee: Codeunit "NavApp ModuleInfo Callee";
        EmptyId: Guid;
    begin
        Initialize();

        Assert.AreNotEqual('', Callee.OwnName(), 'GetCurrentModuleInfo must populate a non-empty module name.');
        Assert.AreNotEqual(EmptyId, Callee.OwnId(), 'GetCurrentModuleInfo must populate a non-empty module Id.');
    end;

    [Test]
    procedure NavApp_GetCallerModuleInfo_DirectCall_NamesTheCurrentModule()
    var
        Callee: Codeunit "NavApp ModuleInfo Callee";
    begin
        Initialize();

        // In this single-app adaptation, "the caller" and "the callee" are compiled
        // into the same module, so the caller-module name equals this module's own
        // name — different from the real cross-app case (see file-header note), but
        // still proves the call resolves to a real, non-empty module rather than
        // silently defaulting.
        Assert.AreEqual(Callee.OwnName(), Callee.CallerName(),
            'Caller module in this single-app adaptation must equal the current module''s own name.');
    end;

    /// <summary>
    /// THE REGRESSION THIS SUITE EXISTS TO PIN (AL Runner 57ef97a0). GetCallerModuleInfo
    /// must name the IMMEDIATE caller's module, even when that immediate caller sits in
    /// the same app as a MORE DISTANT frame further up the call chain. BC's own
    /// GetCallingAppId(excludeCurrentMethod: true) skips exactly ONE method scope and
    /// then breaks on the very next stack frame — it never walks further looking for a
    /// "different" app.
    ///
    /// A runner that instead answers "the nearest frame from a DIFFERENT app" would, in
    /// the real cross-app original, name the far-away consumer bundle instead of the
    /// dependency's own immediate caller. In this same-app adaptation every frame
    /// belongs to the same module, so the observable proof is narrower: the answer must
    /// still be a real, resolvable module identity after a same-app hop through TWO
    /// intervening method scopes (Callee -> Callee Hop), not an empty/default value that
    /// a broken "skip past same-app frames" search could produce if it ran out of
    /// foreign frames to find.
    /// </summary>
    [Test]
    procedure NavApp_GetCallerModuleInfo_AfterSameAppHop_StillNamesARealModule()
    var
        Callee: Codeunit "NavApp ModuleInfo Callee";
    begin
        Initialize();

        Assert.AreEqual(Callee.OwnName(), Callee.CallerNameAfterOwnHop(),
            'Caller module after a same-app hop must still resolve to this module''s own identity, not go empty or wrong.');
    end;

    /// <summary>
    /// Same hop, by AppId — pins that the answer carries the real module Id and not an
    /// empty GUID, which is the shape that would silently produce unusable rows for any
    /// caller keying data on GetCallerModuleInfo().Id().
    /// </summary>
    [Test]
    procedure NavApp_GetCallerModuleInfo_AfterSameAppHop_CarriesARealAppId()
    var
        Callee: Codeunit "NavApp ModuleInfo Callee";
        EmptyId: Guid;
    begin
        Initialize();

        Assert.AreNotEqual(EmptyId, Callee.CallerIdAfterOwnHop(),
            'Caller module id across a same-app hop must not be an empty GUID.');
        Assert.AreEqual(Callee.OwnId(), Callee.CallerIdAfterOwnHop(),
            'Caller module id across a same-app hop must equal this module''s own id.');
    end;

    local procedure Initialize()
    begin
        // No persistent tables used — module identity lookups have no fixture state.
    end;
}
