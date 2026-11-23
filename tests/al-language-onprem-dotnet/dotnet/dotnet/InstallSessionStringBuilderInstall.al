// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: OnPrem DotNet, installation and test-session object lifetime
// BC versions: 27.5, 28.5, 29.0
// local object: dedicated installation observation and SingleInstance owner keep this probe isolated.
// Related: AL Runner issue 8954. Native results pending.

// Installation safety: DotNet calls are inside TryCapture, which performs no database writes.
// Errors are recorded without escaping the trigger. The observation is upserted without table triggers.
codeunit 99452 "LT Install Builder"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        Observation: Record "LT Install Builder Obs";
        LocalText: Text;
        SessionText: Text;
        ProbeError: Text;
        ApiFlags: Text;
    begin
        if not TryCapture(LocalText, SessionText, ApiFlags) then
            ProbeError := CopyStr(GetLastErrorText(), 1, 250);
        ClearLastError();
        if not Observation.Get('BUILDER') then begin
            Observation.Init();
            Observation."Code" := 'BUILDER';
            Observation.Insert(false);
        end;
        Observation."Local Text" := CopyStr(LocalText, 1, 100);
        Observation."Session Text" := CopyStr(SessionText, 1, 100);
        Observation."Probe Error" := CopyStr(ProbeError, 1, 250);
        Observation."API Flags" := CopyStr(ApiFlags, 1, 10);
        Observation.Modify(false);
    end;

    [TryFunction]
    local procedure TryCapture(var LocalText: Text; var SessionText: Text; var ApiFlags: Text)
    var
        Builder: DotNet LtInstallSessionBuilder;
        State: Codeunit "LT Install Builder State";
        Settings: DotNet LtInstallSettings;
        UserAccount: DotNet LtInstallUserAccount;
    begin
        Builder := Builder.StringBuilder();
        Builder.Append('LOCAL-INSTALL');
        LocalText := Builder.ToString();
        State.SetValue('SESSION-INSTALL');
        SessionText := State.ReadValue();
        Settings := Settings.Instance;
        if Settings.ApiServicesEnabled then
            ApiFlags += 'S';
        if Settings.ApiSubscriptionsEnabled then
            ApiFlags += 'N';
        if UserAccount.IsAzure() then
            ApiFlags += 'A';
    end;
}
