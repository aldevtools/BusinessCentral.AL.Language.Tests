// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-workdate-method
// Scope: in-scope
// Probe: AL Runner issue 5743 (writer RL). What WorkDate() is when a test codeunit starts, in the company the corpus runs in, without any
//   test code setting it. Base Application's LogInManagement (codeunit 40) sets WorkDate at company open when GuiAllowed and the client is
//   not Background: in a company with "Demo Company" = Yes to NormalDate of the last G/L Entry's Posting Date (GetDefaultWorkDate).
//   Microsoft's test runner keeps the WorkDate it saw when the run started and restores it after each test codeunit
//   ("ALTestRunner Reset Environment", codeunit 130453), so the value at the start of a codeunit does not depend on the codeunits before it.
// Pinned elsewhere, not repeated: GuiAllowed() is true in a test (session/W5SessionFacts.al:82), CompanyName() is 'CRONUS International Ltd.'
//   (session/TestEnvironmentUserTenantContracts.al:253), a WorkDate a test sets stays for the next test of the same codeunit
//   (session/TestProbeSessionMiscContracts.al:813-820). WorkDate during install: install/lt-outside-install-ui/RlInstallUi.al.
// No value below depends on the run date: only comparisons are observed.
// BC versions: 27 - 29

codeunit 88210 "LT RL WorkDate Start Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        OnRunWorkDateIsLastGL: Boolean;
        OnRunDone: Boolean;

    trigger OnRun()
    begin
        OnRunDone := true;
        OnRunWorkDateIsLastGL := WorkDate() = LastGLDate();
    end;

    [Test]
    procedure WorkDateAtCodeunitStart()
    var
        CompanyInformation: Record "Company Information";
        GLEntry: Record "G/L Entry";
        Observer: Codeunit "Probe Observer";
    begin
        if CompanyInformation.Get() then
            Observer.Observe('Demo Company', Format(CompanyInformation."Demo Company"))
        else
            Observer.Observe('Demo Company', '<no Company Information row>');
        Observer.Observe('G/L entries exist', Format(not GLEntry.IsEmpty()));
        Observer.Observe('OnRun ran', Format(OnRunDone));
        Observer.Observe('OnRun: WorkDate = NormalDate(last G/L Posting Date)', Format(OnRunWorkDateIsLastGL));
        Observer.Observe('test: WorkDate = NormalDate(last G/L Posting Date)', Format(WorkDate() = LastGLDate()));
        Observer.Observe('test: WorkDate = 0D', Format(WorkDate() = 0D));
        // Values of the CI legs 27.5, 28.5 and 29.0 (Linux), the same on all three. On those runs the last G/L entry was not dated today, so
        // WorkDate() was not today either; that comparison is left out because it would fail on the one day the two dates meet.
        Observer.Expect('Demo Company', 'Yes');
        Observer.Expect('G/L entries exist', 'Yes');
        Observer.Expect('OnRun ran', 'Yes');
        Observer.Expect('OnRun: WorkDate = NormalDate(last G/L Posting Date)', 'Yes');
        Observer.Expect('test: WorkDate = NormalDate(last G/L Posting Date)', 'Yes');
        Observer.Expect('test: WorkDate = 0D', 'No');
        Observer.Verify();
    end;

    local procedure LastGLDate(): Date
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetCurrentKey("Posting Date");
        if not GLEntry.FindLast() then
            exit(0D);
        exit(NormalDate(GLEntry."Posting Date"));
    end;
}
