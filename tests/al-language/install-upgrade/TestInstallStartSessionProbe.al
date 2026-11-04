// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-startsession-method
// Scope: in-scope
// Fixtures used: Install StartSession Observation (60446), Install StartSession Worker (60448)
//
// A Subtype=Install codeunit that calls StartSession from OnInstallAppPerCompany, in both
// forms, and records what it saw. BC skips StartSession while an app install is running
// (ALSession.ALStartSessionAsyncImpl checks session.AppInstallationContext and returns false
// before it opens a session), so the worker never runs and SessionId is never written.
// TestInstallStartSession_Tests reads the observation back after install.
//
// SessionId starts at a sentinel (777) rather than 0, so "SessionId was left alone" cannot be
// satisfied by a default value.

codeunit 60445 "Install StartSession Probe"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        Observation: Record "Install StartSession Obs";
        SessionId: Integer;
    begin
        // Reinstall writes a fresh observation: drop the row a previous install left behind.
        if Observation.Get('STARTSESSION') then
            Observation.Delete();

        Observation.Init();
        Observation."Code" := 'STARTSESSION';

        // Form 1: the return value is consumed, so a refusal can only surface as false.
        SessionId := 777;
        Observation."Returned" := StartSession(SessionId, Codeunit::"Install StartSession Worker");
        Observation."Session Id After" := SessionId;

        // Form 2: the return value is ignored, so any error would propagate out of the install
        // trigger. Reaching the next line proves the refusal is not raised as an error.
        SessionId := 777;
        StartSession(SessionId, Codeunit::"Install StartSession Worker");
        Observation."Reached After Plain Call" := true;
        Observation."Plain Session Id After" := SessionId;

        Observation.Insert();
    end;
}

// Probe UM (ADR-046 Q1): see install/lt-um-install-order/UmInstallOrder.al. Writes only `if Insert() then;` into a DataPerCompany = false log.
codeunit 90435 "LT UM Zz Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        Writer: Codeunit "LT UM Install Writer";
    begin
        Writer.WriteRow('Zz', 'OnInstallAppPerCompany');
    end;

    trigger OnInstallAppPerDatabase()
    var
        Writer: Codeunit "LT UM Install Writer";
    begin
        Writer.WriteRow('Zz', 'OnInstallAppPerDatabase');
    end;
}
