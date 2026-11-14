// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-permissions
// Scope: in-scope
// Fixtures used: Permissions Mock (131006) from the dependency.
// A wrapper of Permissions Mock for the OnPrem app (tests/al-language-onprem/permissions/SysFlowFieldPermFilter.al), which has no dependency on
// Permissions Mock of its own: start the mock, set one permission set (Set adds All Objects), clear and stop it again. Not a test codeunit.
// BC versions: 27, 28, 29

codeunit 76741 "SFF Mock Switch"
{
    var
        Mock: Codeunit "Permissions Mock";
        WasStarted: Boolean;

    procedure SetOnly(RoleId: Code[20])
    begin
        WasStarted := Mock.IsStarted();
        if not WasStarted then
            Mock.Start();
        Mock.ClearAssignments();
        Mock.Set(RoleId);
    end;

    procedure Restore()
    begin
        if not Mock.IsStarted() then
            exit;
        Mock.ClearAssignments();
        if not WasStarted then
            Mock.Stop();
    end;
}
