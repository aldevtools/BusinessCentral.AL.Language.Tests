// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; DotNet alias LtBgStringBuilder from BgRunOnClient.al; self-contained codeunit 99491
// Probe: the corrected pin of AC_DnRunOnClient_GlobalVariable (codeunit 61492, lt-ac/AcDnAttributes.al): a global [RunOnClient] System.Text.StringBuilder, constructed and appended to in a TryFunction.
// An official Windows container raised DotNetFromAlNotSupported on BC 27.5 and 29.0 (corpus runs 39216765049 and 39216768276, the same text on both). Codeunit 61492 pinned the earlier Linux answers
// ("A DotNet variable has not been instantiated" on 28+, "Cannot create an instance" on 27), which came from the Linux test runner's null handle; MsDyn365Bc.On.Linux PR #130 gives the Windows answer.
// BC versions: 27, 28, 29
codeunit 99491 "LT BG Dn RunOnClient Global"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        [RunOnClient]
        ClientBuilder: DotNet LtBgStringBuilder;

    [Test]
    procedure BG_DnRunOnClient_GlobalVariable_NotSupported()
    var
        Observer: Codeunit "Probe Observer";
        Text1: Text;
    begin
        if TryBuild(Text1) then
            Observer.Observe('built', Text1)
        else
            Observer.ObserveError('built');
        Observer.Expect('built|text', 'The operation cannot complete because it uses a feature that is not supported (.NET Framework Interoperability.)');
        Observer.Expect('built|code', 'DotNetFromAlNotSupported:DotNetFromAlNotSupported');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryBuild(var Result: Text)
    begin
        ClientBuilder := ClientBuilder.StringBuilder();
        ClientBuilder.Append('client');
        Result := ClientBuilder.ToString();
    end;
}
