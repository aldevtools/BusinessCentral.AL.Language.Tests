// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-installation-codeunit
// Scope: in-scope
// Fixtures used: Install Seed (60617)
//
// Negative-direction control: a NORMAL (non-Install-subtype) codeunit with a
// public procedure that happens to be named like an install trigger. If a
// runtime's install step matched by method NAME instead of by codeunit
// Subtype=Install, this would insert a 'ROGUE' row — the tests assert it did
// NOT run (row absent, total count stays exactly 2).

codeunit 60619 "Not An Installer"
{
    procedure OnInstallAppPerCompany()
    var
        Seed: Record "Install Seed";
    begin
        Seed.Init();
        Seed."Code" := 'ROGUE';
        Seed."Value" := -1;
        Seed.Insert();
    end;
}
