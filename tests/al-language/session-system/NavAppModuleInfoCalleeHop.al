// Support codeunit for TestNavAppModuleInfoCallerIdentity.al. See NavAppModuleInfoCallee.al
// for the full same-app-adaptation note.
//
/// <summary>
/// A second codeunit, same app as "NavApp ModuleInfo Callee". Its only purpose is to put
/// one more method scope between the test codeunit and the GetCallerModuleInfo call, so
/// the test can assert the answer names the immediate caller ("NavApp ModuleInfo
/// Callee") rather than the more distant test codeunit.
/// </summary>
codeunit 60385 "NavApp ModuleInfo Callee Hop"
{
    procedure CallerNameSeenFromHere(): Text
    var
        Info: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(Info);
        exit(Info.Name());
    end;

    procedure CallerIdSeenFromHere(): Guid
    var
        Info: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(Info);
        exit(Info.Id());
    end;
}
