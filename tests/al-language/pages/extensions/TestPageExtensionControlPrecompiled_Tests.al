// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Assert (60021) -- and Base Application page "VAT Rate Change Setup", its
//                pageextension 6478 "Serv. VAT Rate Change Setup" and its tableextension over
//                table "VAT Rate Change Setup", which ship PRECOMPILED in Base Application.
//
// CLAIM: a control a pageextension adds to a page that ships precompiled is reachable through
// a TestPage and writes the field it is bound to, when that field is one a tableextension adds
// to the page's source table -- both when the pageextension ships precompiled in the same app
// (Base Application's own "Ignore Status on Service Docs.") and when it is compiled here.
//
// Each arm writes the opposite of the stored value, so the assertion cannot pass on the value
// the setup record already held.
//
// APPLICATION AREA: Base Application declares "Ignore Status on Service Docs." with
// ApplicationArea = #Service, and BC removes a control from the page when its application area
// is not enabled for the session -- TestPage then reports it as not found. Which areas a test
// session starts with depends on how the harness opened it (an empty string enables all; an
// experience tier such as Essential does not include #Service), so every arm sets the session's
// application areas itself, to a value that includes #Service, and restores the previous value
// BEFORE it asserts, so a failing assertion does not leave the widened areas to later tests.
//
// Written by agent stma-auto2-14, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4660.

pageextension 67400 "PXCP VAT Setup Ext" extends "VAT Rate Change Setup"
{
    layout
    {
        addlast(content)
        {
            field(PXCPIgnoreStatus; Rec."Ignore Status on Service Docs.")
            {
                ApplicationArea = All;
            }
        }
    }
}

codeunit 67400 "PXCP Tests"
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

    local procedure StoredIgnoreStatus(): Boolean
    var
        Setup: Record "VAT Rate Change Setup";
    begin
        if not Setup.Get() then begin
            Setup.Init();
            Setup.Insert();
        end;
        exit(Setup."Ignore Status on Service Docs.");
    end;

    [Test]
    procedure PrecompiledPageExtControl_BoundToTableExtField_IsFoundAndWritesTheField()
    var
        Setup: Record "VAT Rate Change Setup";
        SetupPage: TestPage "VAT Rate Change Setup";
        Wanted: Boolean;
        ReadBack: Boolean;
        PreviousAreas: Text;
    begin
        PreviousAreas := EnableServiceArea();
        Wanted := not StoredIgnoreStatus();

        SetupPage.OpenEdit();
        SetupPage."Ignore Status on Service Docs.".SetValue(Wanted);
        ReadBack := SetupPage."Ignore Status on Service Docs.".AsBoolean();
        SetupPage.Close();

        Setup.Get();
        ApplicationArea(PreviousAreas);
        Assert.AreEqual(Wanted, ReadBack,
            'the precompiled pageextension control must read back the value just set');
        Assert.AreEqual(Wanted, Setup."Ignore Status on Service Docs.",
            'the precompiled pageextension control must write the tableextension field');
    end;

    [Test]
    procedure SourcePageExtControlOnPrecompiledPage_BoundToTableExtField_IsFoundAndWritesTheField()
    var
        Setup: Record "VAT Rate Change Setup";
        SetupPage: TestPage "VAT Rate Change Setup";
        Wanted: Boolean;
        ReadBack: Boolean;
        PreviousAreas: Text;
    begin
        PreviousAreas := EnableServiceArea();
        Wanted := not StoredIgnoreStatus();

        SetupPage.OpenEdit();
        SetupPage.PXCPIgnoreStatus.SetValue(Wanted);
        ReadBack := SetupPage.PXCPIgnoreStatus.AsBoolean();
        SetupPage.Close();

        Setup.Get();
        ApplicationArea(PreviousAreas);
        Assert.AreEqual(Wanted, ReadBack,
            'the pageextension control must read back the value just set');
        Assert.AreEqual(Wanted, Setup."Ignore Status on Service Docs.",
            'the pageextension control must write the tableextension field');
    end;

    [Test]
    procedure PrecompiledPageWithExtensions_UndeclaredControlId_IsNotFound()
    // The negative direction: folding extension controls in must not make every id resolve.
    var
        SetupPage: TestPage "VAT Rate Change Setup";
        PreviousAreas: Text;
    begin
        PreviousAreas := EnableServiceArea();
        SetupPage.OpenEdit();
        asserterror SetupPage.GetField(12345).SetValue(true);
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('The field with ID = 12345 is not found on the page.');
    end;
}
