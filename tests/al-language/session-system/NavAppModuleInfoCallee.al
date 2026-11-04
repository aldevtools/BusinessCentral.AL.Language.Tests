// Support codeunit for TestNavAppModuleInfoCallerIdentity.al.
//
// NOTE — SAME-APP ADAPTATION OF A CROSS-APP-BOUNDARY TEST:
// The original runner-extras suite (navapp-moduleinfo-dep + navapp-moduleinfo-main) was
// a dependency-app / consumer-app PAIR: a separately-compiled dependency app exposed
// this codeunit (and "NavApp ModuleInfo Callee Hop"), and a consumer app's test
// codeunit called into it, asserting that NavApp.GetCurrentModuleInfo inside the
// dependency reports the DEPENDENCY's own module identity (not the consumer's), and
// that NavApp.GetCallerModuleInfo reports the IMMEDIATE caller's module — even when
// that immediate caller is another codeunit within the SAME app as the callee.
//
// This corpus has a single app.json for the whole repo, so a true cross-app-boundary
// compiled scenario cannot be reproduced here: "Callee" and "Callee Hop" live in the
// SAME app as the test codeunit that calls them, so
// NavApp.GetCurrentModuleInfo/GetCallerModuleInfo will all report the SAME module
// id/name everywhere in this suite. That is expected and different from the real
// cross-app case — it is an accepted degradation of test coverage, not a bug here.
//
// What still transfers faithfully to a single-app context, and is what
// TestNavAppModuleInfoCallerIdentity.al actually asserts:
//   - GetCurrentModuleInfo returns a non-empty Id/Name for the current module.
//   - GetCallerModuleInfo, called after a chain of same-app method scopes, correctly
//     identifies the IMMEDIATE caller (the previous method scope), not some more
//     distant frame further up the call chain. This pins the exact regression fixed in
//     AL Runner commit 57ef97a0 ("GetCallerModuleInfo must name the IMMEDIATE caller,
//     not the nearest foreign app") — the runner used to skip past same-app frames
//     looking for a "foreign" module, which is wrong: BC's own rule breaks on the very
//     next stack frame regardless of which app it belongs to.
//
/// <summary>
/// Stands in for the original dependency app's API codeunit. Reports this module's own
/// identity, and hops through a second same-app codeunit ("NavApp ModuleInfo Callee
/// Hop") before asking NavApp.GetCallerModuleInfo — pinning that the answer is the
/// IMMEDIATE caller (the hop codeunit), not some more distant frame.
/// </summary>
codeunit 60384 "NavApp ModuleInfo Callee"
{
    procedure OwnName(): Text
    var
        Info: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        exit(Info.Name());
    end;

    procedure OwnId(): Guid
    var
        Info: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        exit(Info.Id());
    end;

    /// <summary>Direct caller-module lookup with no intervening hop.</summary>
    procedure CallerName(): Text
    var
        Info: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(Info);
        exit(Info.Name());
    end;

    /// <summary>
    /// Hops through a second codeunit ("NavApp ModuleInfo Callee Hop") before asking for
    /// the caller. BC's ALGetCallerModuleInfo skips exactly ONE method scope and then
    /// takes the next stack frame, so the answer is the module of the IMMEDIATE caller
    /// (this codeunit, from the hop's point of view) — not the test codeunit further up
    /// the chain.
    /// </summary>
    procedure CallerNameAfterOwnHop(): Text
    var
        Hop: Codeunit "NavApp ModuleInfo Callee Hop";
    begin
        exit(Hop.CallerNameSeenFromHere());
    end;

    /// <summary>Same hop, reporting the caller's AppId so an empty GUID is visible.</summary>
    procedure CallerIdAfterOwnHop(): Guid
    var
        Hop: Codeunit "NavApp ModuleInfo Callee Hop";
    begin
        exit(Hop.CallerIdSeenFromHere());
    end;
}
