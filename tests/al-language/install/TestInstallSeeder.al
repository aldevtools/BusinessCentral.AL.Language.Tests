// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-installation-codeunit
// Scope: in-scope
// Fixtures used: Install Seed (60617), Install Seed Database (60621)
//
// The Subtype=Install codeunit under test. Real BC fires its lifecycle
// triggers on app install; each trigger inserts distinctly-marked rows so the
// tests can prove BOTH triggers fired (not just one). OnInstallAppPerDatabase
// fires once, globally, before any company exists, so it writes to the
// per-database table. OnInstallAppPerCompany fires once per EXISTING company,
// so it writes to the per-company table — otherwise a sandbox with more than
// one company would collide inserting the same Code twice.

codeunit 60618 "Install Seeder"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        Seed: Record "Install Seed Database";
    begin
        // Reinstall writes fresh rows: drop what a previous install left behind.
        if Seed.Get('DATABASE') then
            Seed.Delete();

        Seed.Init();
        Seed."Code" := 'DATABASE';
        Seed."Value" := 99;
        Seed."Exec Ctx Was Install" := Session.GetExecutionContext() = ExecutionContext::Install;
        Seed."Exec Ctx Text" := CopyStr(Format(Session.GetExecutionContext()), 1, MaxStrLen(Seed."Exec Ctx Text"));
        Seed.Insert();
    end;

    trigger OnInstallAppPerCompany()
    var
        Seed: Record "Install Seed";
        EventPublisher: Codeunit "Install Event Publisher";
    begin
        RecordWhatTheInstallTriggerCouldSee();

        // Reinstall writes fresh rows: drop what a previous install left behind.
        if Seed.Get('COMPANY1') then
            Seed.Delete();
        if Seed.Get('COMPANY2') then
            Seed.Delete();

        Seed.Init();
        Seed."Code" := 'COMPANY1';
        Seed."Value" := 11;
        Seed.Insert();

        Seed.Init();
        Seed."Code" := 'COMPANY2';
        Seed."Value" := 22;
        Seed.Insert();

        // Raise an integration event from inside the install trigger — the
        // ordinary way an app lets other code contribute setup rows while it
        // installs. Its subscriber writes to "Install Event Seed" (60832), a
        // DIFFERENT table, so the exact-count assertions over "Install Seed"
        // stay meaningful.
        EventPublisher.Discover();
    end;

    // What the environment looked like from inside the install trigger. An install trigger runs
    // in a company that already exists, under a session whose permissions are already in place,
    // so both questions have answers here. Read back by TestInstallEnvVisible_Tests.
    local procedure RecordWhatTheInstallTriggerCouldSee()
    var
        Observation: Record "Install Env Observation";
        Comp: Record Company;
        UserPermissions: Codeunit "User Permissions";
    begin
        // Reinstall writes a fresh observation: drop the row a previous install left behind.
        if Observation.Get('ENV') then
            Observation.Delete();

        Observation.Init();
        Observation."Code" := 'ENV';
        Observation."Observed Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(Observation."Observed Company Name"));

        Observation."Company Row Existed" := Comp.Get(CompanyName());
        if Observation."Company Row Existed" then
            Observation."Company Row Name" := Comp.Name;
        // Negative control, recorded from inside the same trigger: Get must consult the key here
        // too, or "Company Row Existed" would prove nothing.
        Observation."Other Company Row Existed" := Comp.Get('NO SUCH COMPANY');

        Observation."Session User Was Super" := UserPermissions.IsSuper(UserSecurityId());

        // The two calls are separate APIs and are recorded separately: the session-wide context
        // and the context of the module this code belongs to.
        Observation."Exec Ctx Was Install" := Session.GetExecutionContext() = ExecutionContext::Install;
        Observation."Exec Ctx Text" := CopyStr(Format(Session.GetExecutionContext()), 1, MaxStrLen(Observation."Exec Ctx Text"));
        Observation."Module Exec Ctx Was Install" := Session.GetCurrentModuleExecutionContext() = ExecutionContext::Install;
        Observation."Module Exec Ctx Text" := CopyStr(Format(Session.GetCurrentModuleExecutionContext()), 1, MaxStrLen(Observation."Module Exec Ctx Text"));
        Observation.Insert();
    end;
}

// Probe UM (ADR-046 Q1): see install/lt-um-install-order/UmInstallOrder.al. Writes only `if Insert() then;` into a DataPerCompany = false log.
codeunit 90431 "LT UM Mu Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        Writer: Codeunit "LT UM Install Writer";
    begin
        Writer.WriteRow('Mu', 'OnInstallAppPerCompany');
    end;

    trigger OnInstallAppPerDatabase()
    var
        Writer: Codeunit "LT UM Install Writer";
    begin
        Writer.WriteRow('Mu', 'OnInstallAppPerDatabase');
    end;
}
