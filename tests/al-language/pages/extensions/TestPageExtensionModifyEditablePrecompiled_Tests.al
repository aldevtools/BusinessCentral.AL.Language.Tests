// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Assert (60021) -- and Base Application page "Location Card", which ships
//                PRECOMPILED in Base Application.
//
// CLAIM: when a pageextension compiled HERE uses modify(<control>) to set Editable on a control
// of a precompiled page, TestPage answers the EXTENSION's Editable, evaluated against a variable
// the extension owns and sets in its own OnAfterGetCurrRecord. Two shapes of base control:
//   - Name declares no Editable of its own on "Location Card";
//   - "Use As In-Transit" declares its own Editable = EditInTransit.
// The extension sets both to `not PXMELocked`, where PXMELocked is true while a Bin exists for
// the location -- a RELATED record, read in OnAfterGetCurrRecord, not a field of Rec.
// The same modify() shape is measured for Enabled, on the "Address 2" control and on the
// "Warehouse Employees" action, neither of which declares an Enabled of its own.
//
// Both directions are asserted on the same page: read-only for a location that has a bin, and
// editable for one that has none, so an answer of false (or true) for every row fails an arm.
// Address is not modified by the extension and must stay editable on the locked row too: that
// arm shows the page itself is editable and positioned, so a false on the two modified controls
// comes from the extension's Editable and not from the page being read-only.
//
// APPLICATION AREA: the page's controls use ApplicationArea Location; each arm enables it and
// restores the previous areas before it asserts (the same pattern as codeunit 67402).
//
// Written by agent stma-auto-8, an automated implementation agent acting on the account holder's
// behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#5139.

pageextension 68620 "PXME Location Card Ext" extends "Location Card"
{
    layout
    {
        modify(Name)
        {
            Editable = not PXMELocked;
        }
        modify("Use As In-Transit")
        {
            Editable = not PXMELocked;
        }
        modify("Address 2")
        {
            Enabled = not PXMELocked;
        }
    }

    actions
    {
        modify("Warehouse Employees")
        {
            Enabled = not PXMELocked;
        }
    }

    var
        PXMELocked: Boolean;

    trigger OnAfterGetCurrRecord()
    var
        Bin: Record Bin;
    begin
        Bin.SetRange("Location Code", Rec.Code);
        PXMELocked := not Bin.IsEmpty();
    end;
}

codeunit 68620 "PXME Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure EnableLocationAreas() Previous: Text
    begin
        Previous := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Location,#Warehouse');
    end;

    local procedure CreateLocation(LocationCode: Code[10]; WithBin: Boolean)
    var
        Location: Record Location;
        Bin: Record Bin;
    begin
        Bin.SetRange("Location Code", LocationCode);
        Bin.DeleteAll();
        if Location.Get(LocationCode) then
            Location.Delete();
        Location.Init();
        Location.Code := LocationCode;
        Location.Insert();
        if WithBin then begin
            Bin.Init();
            Bin."Location Code" := LocationCode;
            Bin.Code := 'PXME-BIN';
            Bin.Insert();
        end;
    end;

    local procedure ReadEditable(LocationCode: Code[10]; var Found: Boolean; var NameEditable: Boolean; var InTransitEditable: Boolean; var AddressEditable: Boolean; var Address2Enabled: Boolean; var EmployeesEnabled: Boolean)
    var
        Location: Record Location;
        LocationCard: TestPage "Location Card";
    begin
        Location.Get(LocationCode);
        LocationCard.OpenEdit();
        Found := LocationCard.GoToRecord(Location);
        if Found then begin
            NameEditable := LocationCard.Name.Editable();
            InTransitEditable := LocationCard."Use As In-Transit".Editable();
            AddressEditable := LocationCard.Address.Editable();
            Address2Enabled := LocationCard."Address 2".Enabled();
            EmployeesEnabled := LocationCard."Warehouse Employees".Enabled();
        end;
        LocationCard.Close();
    end;

    [Test]
    procedure SourcePageExtModifyEditable_LocationWithBin_ModifiedControlsAreReadOnly()
    var
        Found: Boolean;
        NameEditable: Boolean;
        InTransitEditable: Boolean;
        AddressEditable: Boolean;
        Address2Enabled: Boolean;
        EmployeesEnabled: Boolean;
        PreviousAreas: Text;
    begin
        PreviousAreas := EnableLocationAreas();
        CreateLocation('PXME-LOCK', true);
        ReadEditable('PXME-LOCK', Found, NameEditable, InTransitEditable, AddressEditable, Address2Enabled, EmployeesEnabled);
        ApplicationArea(PreviousAreas);

        Assert.IsTrue(Found, 'GoToRecord must position "Location Card" on the location just created.');
        Assert.IsTrue(AddressEditable, 'Address, which the pageextension does not modify, must stay editable: the page is open for edit.');
        Assert.IsFalse(NameEditable, 'Name (no Editable of its own; Editable = not PXMELocked set by modify() in pageextension "PXME Location Card Ext") must be read-only for a location that has a bin.');
        Assert.IsFalse(InTransitEditable, '"Use As In-Transit" (own Editable = EditInTransit; Editable = not PXMELocked set by modify() in pageextension "PXME Location Card Ext") must be read-only for a location that has a bin.');
        Assert.IsFalse(Address2Enabled, '"Address 2" (Enabled = not PXMELocked set by modify() in pageextension "PXME Location Card Ext") must be disabled for a location that has a bin.');
        Assert.IsFalse(EmployeesEnabled, 'Action "Warehouse Employees" (Enabled = not PXMELocked set by modify() in pageextension "PXME Location Card Ext") must be disabled for a location that has a bin.');
    end;

    [Test]
    procedure SourcePageExtModifyEditable_LocationWithoutBin_ModifiedControlsAreEditable()
    var
        Found: Boolean;
        NameEditable: Boolean;
        InTransitEditable: Boolean;
        AddressEditable: Boolean;
        Address2Enabled: Boolean;
        EmployeesEnabled: Boolean;
        PreviousAreas: Text;
    begin
        PreviousAreas := EnableLocationAreas();
        CreateLocation('PXME-OPEN', false);
        ReadEditable('PXME-OPEN', Found, NameEditable, InTransitEditable, AddressEditable, Address2Enabled, EmployeesEnabled);
        ApplicationArea(PreviousAreas);

        Assert.IsTrue(Found, 'GoToRecord must position "Location Card" on the location just created.');
        Assert.IsTrue(AddressEditable, 'Address, which the pageextension does not modify, must be editable: the page is open for edit.');
        Assert.IsTrue(NameEditable, 'Name (Editable = not PXMELocked set by modify() in pageextension "PXME Location Card Ext") must be editable for a location without a bin.');
        Assert.IsTrue(InTransitEditable, '"Use As In-Transit" (Editable = not PXMELocked set by modify() in pageextension "PXME Location Card Ext") must be editable for a location without a bin.');
        Assert.IsTrue(Address2Enabled, '"Address 2" (Enabled = not PXMELocked set by modify() in pageextension "PXME Location Card Ext") must be enabled for a location without a bin.');
        Assert.IsTrue(EmployeesEnabled, 'Action "Warehouse Employees" (Enabled = not PXMELocked set by modify() in pageextension "PXME Location Card Ext") must be enabled for a location without a bin.');
    end;
}
