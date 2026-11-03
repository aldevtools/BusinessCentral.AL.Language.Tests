// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Assert (60021) -- and Base Application page "VAT Rate Change Setup", its
//                pageextension 6478 "Serv. VAT Rate Change Setup" and its tableextension over
//                table "VAT Rate Change Setup", which ship PRECOMPILED in Base Application.
//
// CLAIM: "Page Control Field" (2000000192) lists a control that a pageextension adds to a page
// that ships precompiled as a row on the BASE page's id, resolved to the field it is bound to --
// both when the pageextension ships precompiled in the same app (Base Application's own
// "Ignore Status on Service Docs.") and when it is compiled here. Nothing is listed under the
// pageextension's own object id.
//
// TestPageControlFieldPageExtension (codeunit 60524) pins the same merge for a page and a
// pageextension that are both compiled here. This file is the precompiled-page half.
//
// APPLICATION AREA: the precompiled control is declared ApplicationArea = #Service. Each test
// sets the session's application areas to a value that includes #Service and restores the
// previous value before it asserts, the same way codeunit 67400 does, so the answer does not
// depend on which areas the harness opened the session with.
//
// Written by agent stma-auto2-14, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4749.

pageextension 67401 "PXCF VAT Setup Ext" extends "VAT Rate Change Setup"
{
    layout
    {
        addlast(content)
        {
            field(PXCFIgnoreStatus; Rec."Ignore Status on Service Docs.")
            {
                ApplicationArea = All;
            }
        }
    }
}

codeunit 67401 "PXCF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure EnableServiceArea() Previous: Text
    begin
        Previous := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Service');
    end;

    [Test]
    procedure PrecompiledPageExtControl_IsARowOnThePrecompiledBasePage()
    var
        Setup: Record "VAT Rate Change Setup";
        PageControlField: Record "Page Control Field";
        Found: Boolean;
        PreviousAreas: Text;
    begin
        PreviousAreas := EnableServiceArea();
        PageControlField.SetRange(PageNo, Page::"VAT Rate Change Setup");
        PageControlField.SetRange(ControlName, 'Ignore Status on Service Docs.');
        Found := PageControlField.FindFirst();
        ApplicationArea(PreviousAreas);

        Assert.IsTrue(Found, 'Page Control Field has no row for "Ignore Status on Service Docs.", the control precompiled pageextension 6478 adds to "VAT Rate Change Setup".');
        Assert.AreEqual(Database::"VAT Rate Change Setup", PageControlField.TableNo, 'Unexpected TableNo for "Ignore Status on Service Docs.".');
        Assert.AreEqual(Setup.FieldNo("Ignore Status on Service Docs."), PageControlField.FieldNo, 'Unexpected FieldNo for "Ignore Status on Service Docs." (a tableextension field).');
    end;

    [Test]
    procedure CompiledPageExtControl_IsARowOnThePrecompiledBasePage()
    var
        Setup: Record "VAT Rate Change Setup";
        PageControlField: Record "Page Control Field";
        Found: Boolean;
        PreviousAreas: Text;
    begin
        PreviousAreas := EnableServiceArea();
        PageControlField.SetRange(PageNo, Page::"VAT Rate Change Setup");
        PageControlField.SetRange(ControlName, 'PXCFIgnoreStatus');
        Found := PageControlField.FindFirst();
        ApplicationArea(PreviousAreas);

        Assert.IsTrue(Found, 'Page Control Field has no row for "PXCFIgnoreStatus", the control pageextension 67401 adds to precompiled page "VAT Rate Change Setup".');
        Assert.AreEqual(Database::"VAT Rate Change Setup", PageControlField.TableNo, 'Unexpected TableNo for "PXCFIgnoreStatus".');
        Assert.AreEqual(Setup.FieldNo("Ignore Status on Service Docs."), PageControlField.FieldNo, 'Unexpected FieldNo for "PXCFIgnoreStatus" (a tableextension field).');
    end;

    [Test]
    procedure PageExtControls_AreNotRowsOnThePageExtensionsOwnIds()
    // The negative direction: the rows belong to the page the extensions extend.
    var
        PageControlField: Record "Page Control Field";
        UnderPrecompiledExt: Integer;
        UnderCompiledExt: Integer;
        PreviousAreas: Text;
    begin
        PreviousAreas := EnableServiceArea();
        PageControlField.SetRange(PageNo, 6478);
        UnderPrecompiledExt := PageControlField.Count();
        PageControlField.SetRange(PageNo, 67401);
        UnderCompiledExt := PageControlField.Count();
        ApplicationArea(PreviousAreas);

        Assert.AreEqual(0, UnderPrecompiledExt, 'Page Control Field must report no rows under precompiled pageextension 6478''s own object id.');
        Assert.AreEqual(0, UnderCompiledExt, 'Page Control Field must report no rows under pageextension 67401''s own object id.');
    end;
}
