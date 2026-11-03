// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-app-area
// Scope: in-scope
// Fixtures used: Assert (60021), Base Application page "Reservation Wksh. Batches" (ships
//                PRECOMPILED; its "Name" control states no area and takes the page's
//                ApplicationArea = Reservation), and the pageextension declared below.
//
// CLAIM: application-area removal applies to the field controls a pageextension compiled in
// THIS app adds to a page that ships precompiled, exactly as codeunit 67535 shows for a page
// compiled here. A TestPage reports such a control as not found when the session's areas do not
// enable the control's own ApplicationArea (PAAXServiceDesc, #Service), and a control that states
// no area (PAAXNoAreaDesc) is not found whenever the session has areas set -- it does not take
// the page's #Reservation. With the empty area string both are found.
//
// It also shows that a modify() stating ApplicationArea on a precompiled page's control REPLACES that
// control's area (pageextension 67537 over Base Application's "Standard Text Codes", whose "Code" and
// "Description" controls each state #Basic,#Suite): with only #Service enabled, "Description" (moved to
// #Service) is found while "Code" is not; with #Basic,#Suite enabled, "Code" is found and
// "Description" is not.
//
// Pageextension 67536 only ADDS controls; it modifies nothing on "Reservation Wksh. Batches", so
// codeunit 67534's assertions about that page are unaffected. No other corpus test opens "Standard
// Text Codes".
//
// Written by agent stma-auto2-1, an automated implementation agent acting on the account holder's
// behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4866.

pageextension 67536 "PAA Ext Resv Batches Ext" extends "Reservation Wksh. Batches"
{
    layout
    {
        addafter(Name)
        {
            field(PAAXServiceDesc; Rec.Description)
            {
                ApplicationArea = Service;
            }
            field(PAAXNoAreaDesc; Rec.Description) { }
        }
    }
}

pageextension 67537 "PAA Ext Std Text Codes Ext" extends "Standard Text Codes"
{
    layout
    {
        modify(Description)
        {
            ApplicationArea = Service;
        }
    }
}

codeunit 67536 "PAA Ext Precompiled Host Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure ExtOwnAreaOnPrecompiledPage_NotEnabled_IsNotFound()
    var
        Batches: TestPage "Reservation Wksh. Batches";
        PreviousAreas: Text;
        Caption: Text;
    begin
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Reservation');

        Batches.OpenView();
        Caption := Batches.Name.Caption();
        asserterror Batches.PAAXServiceDesc.SetValue('X');
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');
        Assert.AreEqual('Name', Caption, 'with #Reservation enabled the page''s own "Name" control must be found');
    end;

    [Test]
    procedure ExtOwnAreaOnPrecompiledPage_Enabled_IsFound()
    var
        Batches: TestPage "Reservation Wksh. Batches";
        PreviousAreas: Text;
        Caption: Text;
    begin
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Reservation,#Service');

        Batches.OpenView();
        Caption := Batches.PAAXServiceDesc.Caption();
        Batches.Close();
        ApplicationArea(PreviousAreas);
        Assert.AreEqual('Description', Caption, 'with #Service enabled the extension''s #Service control must be found');
    end;

    [Test]
    procedure ExtNoAreaOnPrecompiledPage_AreasSet_IsNotFound()
    var
        Batches: TestPage "Reservation Wksh. Batches";
        PreviousAreas: Text;
        Caption: Text;
    begin
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Reservation,#Service');

        Batches.OpenView();
        Caption := Batches.PAAXServiceDesc.Caption();
        asserterror Batches.PAAXNoAreaDesc.SetValue('X');
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');
        Assert.AreEqual('Description', Caption, 'the #Service extension control must be found under the same areas');
    end;

    [Test]
    procedure ExtNoAreaOnPrecompiledPage_EmptyAreaString_IsFound()
    var
        Batches: TestPage "Reservation Wksh. Batches";
        PreviousAreas: Text;
        Caption: Text;
    begin
        PreviousAreas := ApplicationArea();
        ApplicationArea('');

        Batches.OpenView();
        Caption := Batches.PAAXNoAreaDesc.Caption();
        Batches.Close();
        ApplicationArea(PreviousAreas);
        Assert.AreEqual('Description', Caption, 'with every area enabled the no-area extension control must be found');
    end;

    [Test]
    procedure ModifiedAreaOnPrecompiledPage_BaseValueNoLongerApplies_IsNotFound()
    var
        StdTextCodes: TestPage "Standard Text Codes";
        PreviousAreas: Text;
        Caption: Text;
    begin
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        StdTextCodes.OpenView();
        Caption := StdTextCodes.Code.Caption();
        asserterror StdTextCodes.Description.SetValue('X');
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');
        Assert.AreEqual('Code', Caption, 'the page''s own "Code" control must be found under #Basic,#Suite');
    end;

    [Test]
    procedure ModifiedAreaOnPrecompiledPage_ModifyValueEnabled_IsFound()
    var
        StdTextCodes: TestPage "Standard Text Codes";
        PreviousAreas: Text;
        Caption: Text;
    begin
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Service');

        StdTextCodes.OpenView();
        Caption := StdTextCodes.Description.Caption();
        asserterror StdTextCodes.Code.SetValue('X');
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');
        Assert.AreEqual('Description', Caption, 'the control the modify() moved to #Service must be found under #Service');
    end;
}
