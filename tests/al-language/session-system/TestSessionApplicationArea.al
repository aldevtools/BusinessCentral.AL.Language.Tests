// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-app-area
// Fixtures used: none — this exercises System Application codeunit 9179
// "Application Area Mgmt. Facade" against the company the tests run in.
//
// Setting the company's experience tier is the ordinary way AL changes which application
// areas the session has. It runs codeunit 9178 "Application Area Mgmt".SetupApplicationArea,
// which assigns the session's application-area string; the tier then reads back through the
// facade. Both directions are asserted here: a tier that exists round-trips, and a tier that
// does not is refused with a plain false rather than a changed setup.

codeunit 60700 "Test Session Application Area"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure SaveExperienceTier_Essential_ReadsBackAsTheCurrentTier()
    var
        AppAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        CurrentTier: Text;
    begin
        AppAreaMgmtFacade.SaveExperienceTierCurrentCompany('Essential');

        Assert.IsTrue(
          AppAreaMgmtFacade.GetExperienceTierCurrentCompany(CurrentTier),
          'A tier is selected for this company after saving one.');
        Assert.AreEqual('Essential', CurrentTier, 'The saved experience tier reads back.');
    end;

    [Test]
    procedure SaveExperienceTier_Premium_ReplacesTheEssentialTier()
    var
        AppAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        CurrentTier: Text;
    begin
        // Exactly one tier is selected at a time, so saving a second one must replace the
        // first rather than add to it.
        AppAreaMgmtFacade.SaveExperienceTierCurrentCompany('Essential');
        AppAreaMgmtFacade.SaveExperienceTierCurrentCompany('Premium');

        AppAreaMgmtFacade.GetExperienceTierCurrentCompany(CurrentTier);
        Assert.AreEqual('Premium', CurrentTier, 'The most recently saved tier is the current one.');
    end;

    [Test]
    procedure SaveExperienceTier_UnknownTier_IsRefusedAndChangesNothing()
    var
        AppAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        TierBefore: Text;
        TierAfter: Text;
    begin
        AppAreaMgmtFacade.SaveExperienceTierCurrentCompany('Essential');
        AppAreaMgmtFacade.GetExperienceTierCurrentCompany(TierBefore);

        Assert.IsFalse(
          AppAreaMgmtFacade.SaveExperienceTierCurrentCompany('NotAnExperienceTier'),
          'Saving a tier that does not exist reports that nothing changed.');

        AppAreaMgmtFacade.GetExperienceTierCurrentCompany(TierAfter);
        Assert.AreEqual(TierBefore, TierAfter, 'A refused save leaves the current tier alone.');
    end;

    [Test]
    procedure SetupApplicationArea_LeavesTheFoundationAreaEnabled()
    var
        AppAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        // SetupApplicationArea is the call that writes the session's application areas.
        // Essential includes the Basic foundation area, so the check below is a value, not
        // a "did not throw".
        AppAreaMgmtFacade.SaveExperienceTierCurrentCompany('Essential');
        AppAreaMgmtFacade.SetupApplicationArea();

        Assert.IsTrue(
          AppAreaMgmtFacade.IsFoundationEnabled(),
          'The Essential tier enables the foundation application area.');
    end;
}
