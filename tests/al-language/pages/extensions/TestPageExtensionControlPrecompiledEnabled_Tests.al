// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Assert (60021) -- and Base Application page "Location Card" with its pageextension
//                99000756 "Mfg. Location Card", both of which ship PRECOMPILED in Base Application.
//
// CLAIM: a control that a precompiled pageextension adds to a precompiled page answers the
// Enabled property the EXTENSION declares, not the AL default of true. Base Application's
// "Mfg. Location Card" adds "Prod. Consumption Whse. Handling" to "Location Card" with
// Enabled = ProdPickWhseHandlingEnable. The page sets that global in OnAfterGetRecord to
// not "Use As In-Transit" and not "Directed Put-away and Pick", so the control is disabled on an
// in-transit location and enabled on an ordinary one.
//
// Each arm creates its own location, so neither depends on what the company already holds, and
// asserts GoToRecord's result first, so a page that did not position on the row fails there
// rather than on the control.
//
// APPLICATION AREA: the control declares ApplicationArea = Warehouse; the page's own controls
// use Location. Each arm enables both and restores the previous areas before it asserts (the
// same pattern as codeunit 67400).
//
// Written by agent stma-auto2-14, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4749.

codeunit 67402 "PXCE Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure EnableWarehouseAreas() Previous: Text
    begin
        Previous := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Location,#Warehouse');
    end;

    local procedure CreateLocation(LocationCode: Code[10]; InTransit: Boolean)
    var
        Location: Record Location;
    begin
        if Location.Get(LocationCode) then
            Location.Delete();
        Location.Init();
        Location.Code := LocationCode;
        Location."Use As In-Transit" := InTransit;
        Location.Insert();
    end;

    local procedure ProdConsumptionHandlingEnabled(LocationCode: Code[10]; var Found: Boolean) Enabled: Boolean
    var
        Location: Record Location;
        LocationCard: TestPage "Location Card";
    begin
        Location.Get(LocationCode);
        LocationCard.OpenView();
        Found := LocationCard.GoToRecord(Location);
        if Found then
            Enabled := LocationCard."Prod. Consumption Whse. Handling".Enabled();
        LocationCard.Close();
    end;

    [Test]
    procedure PrecompiledPageExtControl_InTransitLocation_ProdConsumptionHandlingIsDisabled()
    var
        Enabled: Boolean;
        Found: Boolean;
        PreviousAreas: Text;
    begin
        PreviousAreas := EnableWarehouseAreas();
        CreateLocation('PXCE-TRANS', true);
        Enabled := ProdConsumptionHandlingEnabled('PXCE-TRANS', Found);
        ApplicationArea(PreviousAreas);

        Assert.IsTrue(Found, 'GoToRecord must position "Location Card" on the location just created.');
        Assert.IsFalse(Enabled, '"Prod. Consumption Whse. Handling" (Enabled = ProdPickWhseHandlingEnable, declared by pageextension "Mfg. Location Card") must be disabled on an in-transit location.');
    end;

    [Test]
    procedure PrecompiledPageExtControl_OrdinaryLocation_ProdConsumptionHandlingIsEnabled()
    var
        Enabled: Boolean;
        Found: Boolean;
        PreviousAreas: Text;
    begin
        PreviousAreas := EnableWarehouseAreas();
        CreateLocation('PXCE-PLAIN', false);
        Enabled := ProdConsumptionHandlingEnabled('PXCE-PLAIN', Found);
        ApplicationArea(PreviousAreas);

        Assert.IsTrue(Found, 'GoToRecord must position "Location Card" on the location just created.');
        Assert.IsTrue(Enabled, '"Prod. Consumption Whse. Handling" (Enabled = ProdPickWhseHandlingEnable, declared by pageextension "Mfg. Location Card") must be enabled on an ordinary location.');
    end;
}
