// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-app-area
// Scope: in-scope
// Fixtures used: Assert (60021), and the table, page, pageextension and codeunit declared below.
//
// CLAIM: application-area removal applies to the field controls a pageextension compiled in the
// same app adds to, or modifies on, a page, as it does to the page's own controls (codeunit
// 67530). A TestPage reports such a control as not found when the session's areas do not enable
// its ApplicationArea, where that area is:
//   * the control's own, when the extension states one ("PAA Ext Card Ext"'s ExtServiceCtl, #Service);
//   * nothing at all, when the extension control states none (ExtNoAreaCtl) -- it does NOT take
//     the base page's object-level ApplicationArea (#Basic), which only the base page's own
//     controls inherit (BaseInheritCtl). A pageextension cannot state ApplicationArea at object
//     level (AL0246);
//   * the modify()'s value, when a pageextension modify() states ApplicationArea: it REPLACES the
//     base control's area rather than adding to it (BaseServiceCtl, #Service on the page, #Suite
//     after the modify).
// Each negative arm pairs with a control on the same page that IS found under the same areas, so
// a page that failed to open cannot pass as "not found".
//
// Every test sets the session's application areas itself and restores the previous value BEFORE
// it asserts, as codeunit 67530 does.
//
// Written by agent stma-auto2-1, an automated implementation agent acting on the account holder's
// behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4866.

table 67535 "PAA Ext Record"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "Inherit Value"; Text[30]) { }
        field(3; "Service Value"; Text[30]) { }
        field(4; "Ext Basic Value"; Text[30]) { }
        field(5; "Ext Service Value"; Text[30]) { }
        field(6; "Ext No Area Value"; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 67535 "PAA Ext Card"
{
    PageType = Card;
    SourceTable = "PAA Ext Record";
    ApplicationArea = Basic;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeCtl; Rec."Code") { }
                field(BaseInheritCtl; Rec."Inherit Value") { }
                field(BaseServiceCtl; Rec."Service Value")
                {
                    ApplicationArea = Service;
                }
            }
        }
    }
}

pageextension 67535 "PAA Ext Card Ext" extends "PAA Ext Card"
{
    layout
    {
        addlast(General)
        {
            field(ExtBasicCtl; Rec."Ext Basic Value")
            {
                ApplicationArea = Basic;
            }
            field(ExtServiceCtl; Rec."Ext Service Value")
            {
                ApplicationArea = Service;
            }
            field(ExtNoAreaCtl; Rec."Ext No Area Value") { }
        }
        modify(BaseServiceCtl)
        {
            ApplicationArea = Suite;
        }
    }
}

codeunit 67535 "PAA Ext Area Control Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure MakeRecord(var AreaRec: Record "PAA Ext Record")
    begin
        AreaRec.DeleteAll();
        AreaRec.Init();
        AreaRec."Code" := 'PAAX';
        AreaRec.Insert();
    end;

    [Test]
    procedure ExtOwnArea_NotEnabled_IsNotFound()
    var
        AreaRec: Record "PAA Ext Record";
        AreaPage: TestPage "PAA Ext Card";
        PreviousAreas: Text;
        ReadBack: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        AreaPage.ExtBasicCtl.SetValue('XB');
        ReadBack := AreaPage.ExtBasicCtl.Value();
        asserterror AreaPage.ExtServiceCtl.SetValue('XS');
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');
        Assert.AreEqual('XB', ReadBack, 'the #Basic extension control must be found under #Basic,#Suite');
    end;

    [Test]
    procedure ExtOwnArea_Enabled_IsFoundAndWrites()
    var
        AreaRec: Record "PAA Ext Record";
        AreaPage: TestPage "PAA Ext Card";
        PreviousAreas: Text;
        ReadBack: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Service');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        AreaPage.ExtServiceCtl.SetValue('XS1');
        ReadBack := AreaPage.ExtServiceCtl.Value();
        AreaPage.Close();
        ApplicationArea(PreviousAreas);

        AreaRec.Get('PAAX');
        Assert.AreEqual('XS1', ReadBack, 'the #Service extension control must read back the value just set');
        Assert.AreEqual('XS1', AreaRec."Ext Service Value", 'the #Service extension control must write its field');
    end;

    [Test]
    procedure ExtNoArea_DoesNotInheritPageArea_IsNotFound()
    var
        AreaRec: Record "PAA Ext Record";
        AreaPage: TestPage "PAA Ext Card";
        PreviousAreas: Text;
        ReadBack: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        AreaPage.BaseInheritCtl.SetValue('I1');
        ReadBack := AreaPage.BaseInheritCtl.Value();
        asserterror AreaPage.ExtNoAreaCtl.SetValue('N1');
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');
        Assert.AreEqual('I1', ReadBack, 'the base control inheriting the page''s #Basic must be found under #Basic');
    end;

    [Test]
    procedure ExtNoArea_EmptyAreaString_IsFoundAndWrites()
    var
        AreaRec: Record "PAA Ext Record";
        AreaPage: TestPage "PAA Ext Card";
        PreviousAreas: Text;
        ReadBack: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        AreaPage.ExtNoAreaCtl.SetValue('N2');
        ReadBack := AreaPage.ExtNoAreaCtl.Value();
        AreaPage.Close();
        ApplicationArea(PreviousAreas);

        AreaRec.Get('PAAX');
        Assert.AreEqual('N2', ReadBack, 'with every area enabled the no-area extension control must be found');
        Assert.AreEqual('N2', AreaRec."Ext No Area Value", 'the no-area extension control must write its field');
    end;

    [Test]
    procedure ModifiedArea_ModifyValueEnabled_IsFoundAndWrites()
    var
        AreaRec: Record "PAA Ext Record";
        AreaPage: TestPage "PAA Ext Card";
        PreviousAreas: Text;
        ReadBack: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        AreaPage.BaseServiceCtl.SetValue('M1');
        ReadBack := AreaPage.BaseServiceCtl.Value();
        AreaPage.Close();
        ApplicationArea(PreviousAreas);

        AreaRec.Get('PAAX');
        Assert.AreEqual('M1', ReadBack, 'the control the modify() moved to #Suite must be found under #Basic,#Suite');
        Assert.AreEqual('M1', AreaRec."Service Value", 'the modified control must write its field');
    end;

    [Test]
    procedure ModifiedArea_BaseValueNoLongerApplies_IsNotFound()
    var
        AreaRec: Record "PAA Ext Record";
        AreaPage: TestPage "PAA Ext Card";
        PreviousAreas: Text;
        ReadBack: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Service');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        AreaPage.ExtServiceCtl.SetValue('S3');
        ReadBack := AreaPage.ExtServiceCtl.Value();
        asserterror AreaPage.BaseServiceCtl.SetValue('M2');
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');
        Assert.AreEqual('S3', ReadBack, 'the #Service extension control must be found under #Basic,#Service');
    end;
}
