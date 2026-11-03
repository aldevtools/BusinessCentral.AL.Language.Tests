// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-app-area
// Scope: in-scope
// Fixtures used: Assert (60021), and Base Application pages "VAT Rate Change Setup" (with its
//                pageextension 6478 "Serv. VAT Rate Change Setup"), "Reservation Wksh. Batches"
//                and "Integration Field Mapping List", all of which ship PRECOMPILED in Base
//                Application.
//
// CLAIM: application-area removal applies to the field controls of a page that ships precompiled,
// exactly as it does to a page compiled here (codeunit 67530). A TestPage reports a field control
// as not found when the session's areas do not enable its ApplicationArea, where that area is:
//   * the control's own (pageextension 6478's "Ignore Status on Service Docs.", #Service);
//   * the PAGE's, when the control states none ("Reservation Wksh. Batches" declares
//     ApplicationArea = Reservation at page level, and its "Name" control declares none);
//   * nothing at all, when neither the control nor the page states one ("Integration Field
//     Mapping List"'s "User Defined") -- such a control is removed whenever the session has
//     application areas set.
// Each negative arm pairs with a control on the same page that IS found under the same areas, so
// a page that failed to open cannot pass as "not found".
//
// Every test sets the session's application areas itself and restores the previous value BEFORE
// it asserts, as codeunit 67530 does.
//
// Written by agent stma-auto2-1, an automated implementation agent acting on the account holder's
// behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4796.

codeunit 67534 "PAA Precompiled Area Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure EnsureVatRateChangeSetup()
    var
        Setup: Record "VAT Rate Change Setup";
    begin
        if not Setup.Get() then begin
            Setup.Init();
            Setup.Insert();
        end;
    end;

    [Test]
    procedure PrecompiledExtControl_OwnAreaNotEnabled_IsNotFound()
    var
        SetupPage: TestPage "VAT Rate Change Setup";
        PreviousAreas: Text;
    begin
        EnsureVatRateChangeSetup();
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        SetupPage.OpenEdit();
        asserterror SetupPage."Ignore Status on Service Docs.".SetValue(true);
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('The field with ID = 1790009997 is not found on the page.');
    end;

    [Test]
    procedure PrecompiledPageControl_OwnAreaEnabled_IsFound()
    var
        Setup: Record "VAT Rate Change Setup";
        SetupPage: TestPage "VAT Rate Change Setup";
        PreviousAreas: Text;
        Shown: Text;
    begin
        EnsureVatRateChangeSetup();
        Setup.Get();
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        SetupPage.OpenEdit();
        Shown := SetupPage."Account Filter".Value();
        SetupPage.Close();
        ApplicationArea(PreviousAreas);
        Assert.AreEqual(Setup."Account Filter", Shown, 'the #Basic,#Suite control "Account Filter" must be found and show its field');
    end;

    [Test]
    procedure PrecompiledPageControl_PageAreaNotEnabled_IsNotFound()
    var
        Batches: TestPage "Reservation Wksh. Batches";
        PreviousAreas: Text;
    begin
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        Batches.OpenView();
        asserterror Batches.Name.SetValue('X');
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('The field with ID = 301776846 is not found on the page.');
    end;

    [Test]
    procedure PrecompiledPageControl_PageAreaEnabled_IsFound()
    var
        Batches: TestPage "Reservation Wksh. Batches";
        PreviousAreas: Text;
        Caption: Text;
    begin
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Reservation');

        Batches.OpenView();
        Caption := Batches.Name.Caption();
        Batches.Close();
        ApplicationArea(PreviousAreas);
        Assert.AreEqual('Name', Caption, 'with #Reservation enabled the "Name" control, which inherits the page''s area, must be found');
    end;

    [Test]
    procedure PrecompiledPageControl_NoAreaAnywhere_IsNotFoundWhenAreasAreSet()
    var
        Mappings: TestPage "Integration Field Mapping List";
        PreviousAreas: Text;
    begin
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        Mappings.OpenView();
        asserterror Mappings."User Defined".SetValue(true);
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('The field with ID = 104384132 is not found on the page.');
    end;

    [Test]
    procedure PrecompiledPageControl_SiblingWithEnabledArea_IsFound()
    var
        Mappings: TestPage "Integration Field Mapping List";
        PreviousAreas: Text;
        Caption: Text;
    begin
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        Mappings.OpenView();
        Caption := Mappings."Transformation Rule".Caption();
        Mappings.Close();
        ApplicationArea(PreviousAreas);
        Assert.AreNotEqual('', Caption, 'the #Basic,#Suite control "Transformation Rule" must be found on the same page');
    end;
}
