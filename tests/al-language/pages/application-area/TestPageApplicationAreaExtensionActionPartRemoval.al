// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-app-area
// Scope: in-scope
// Fixtures used: Assert (60021), Base Application page "Inventory Posting Groups" (ships
//                PRECOMPILED; no other corpus test opens it), and the objects declared below.
//
// CLAIM: application-area removal applies to the ACTIONS and PARTS a pageextension compiled in
// this app adds to a page, and to a page action whose area its modify() sets, as it does to the
// page's own actions and parts (codeunits 67531 and 67532). A TestPage reports such an action or
// part as not found when the session's areas do not enable its ApplicationArea, where that area
// is:
//   * the element's own, when the extension states one;
//   * nothing at all, when an extension action states none -- it does not take the base page's
//     object-level ApplicationArea;
//   * the modify()'s value, which REPLACES the base action's area.
// An actionref the extension adds is not found when its target action is not (ExtServiceRef), and
// one stating no area of its own is found when its target is (ExtBasicRef). Invoking either
// actionref runs its target's OnAction.
// Codeunit 67538 asks this of a page compiled in this app, codeunit 67539 of a page that ships
// precompiled. Each negative arm pairs with an element on the same page that IS found under the
// same areas, so a page that failed to open cannot pass as "not found".
//
// Pageextension 67539 adds an action and a part to "Inventory Posting Groups" and moves its
// "&Setup" action to #Service. No other corpus test opens that page.
//
// Every test sets the session's application areas itself and restores the previous value BEFORE
// it asserts, as codeunit 67530 does.
//
// Written by agent stma-auto2-1, an automated implementation agent acting on the account holder's
// behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4871.

table 67538 "PAA ExtAct Record"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "Ran"; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 67538 "PAA ExtAct Card"
{
    PageType = Card;
    SourceTable = "PAA ExtAct Record";
    ApplicationArea = Basic;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec."Code") { }
        }
    }

    actions
    {
        area(Promoted)
        {
        }
        area(Processing)
        {
            action(BaseBasicAct)
            {
                ApplicationArea = Basic;
                trigger OnAction()
                begin
                    Rec."Ran" := 'BASE-BASIC';
                    Rec.Modify();
                end;
            }
            action(BaseServiceAct)
            {
                ApplicationArea = Service;
                trigger OnAction()
                begin
                    Rec."Ran" := 'BASE-MODIFIED';
                    Rec.Modify();
                end;
            }
        }
    }
}

page 67539 "PAA ExtAct Part"
{
    PageType = CardPart;
    SourceTable = "PAA ExtAct Record";

    layout
    {
        area(Content)
        {
            field(PartCode; Rec."Code") { ApplicationArea = All; }
        }
    }
}

pageextension 67538 "PAA ExtAct Card Ext" extends "PAA ExtAct Card"
{
    layout
    {
        addlast(Content)
        {
            part(ExtServicePart; "PAA ExtAct Part") { ApplicationArea = Service; }
            part(ExtBasicPart; "PAA ExtAct Part") { ApplicationArea = Basic; }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(ExtServiceAct)
            {
                ApplicationArea = Service;
                trigger OnAction()
                begin
                    Rec."Ran" := 'EXT-SERVICE';
                    Rec.Modify();
                end;
            }
            action(ExtNoAreaAct)
            {
                trigger OnAction()
                begin
                    Rec."Ran" := 'EXT-NOAREA';
                    Rec.Modify();
                end;
            }
            group(ExtGroup)
            {
                action(ExtGroupedServiceAct)
                {
                    ApplicationArea = Service;
                    trigger OnAction()
                    begin
                        Rec."Ran" := 'EXT-GROUPED';
                        Rec.Modify();
                    end;
                }
            }
        }
        addlast(Promoted)
        {
            actionref(ExtServiceRef; ExtServiceAct) { }
            actionref(ExtBasicRef; BaseBasicAct) { }
        }
        modify(BaseServiceAct)
        {
            ApplicationArea = Suite;
        }
    }
}

pageextension 67539 "PAA ExtAct Inv Post Grp Ext" extends "Inventory Posting Groups"
{
    layout
    {
        addlast(Content)
        {
            part(PAAXServicePart; "PAA ExtAct Part") { ApplicationArea = Service; }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(PAAXServiceAct)
            {
                ApplicationArea = Service;
                trigger OnAction()
                begin
                end;
            }
        }
        modify("&Setup")
        {
            ApplicationArea = Service;
        }
    }
}

codeunit 67538 "PAA Ext Action Part Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure MakeRecord(var AreaRec: Record "PAA ExtAct Record")
    begin
        AreaRec.DeleteAll();
        AreaRec.Init();
        AreaRec."Code" := 'PAAA';
        AreaRec.Insert();
    end;

    local procedure RanValue(): Text
    var
        AreaRec: Record "PAA ExtAct Record";
    begin
        AreaRec.Get('PAAA');
        exit(AreaRec."Ran");
    end;

    [Test]
    procedure ExtAction_OwnAreaNotEnabled_IsNotFound()
    var
        AreaRec: Record "PAA ExtAct Record";
        AreaPage: TestPage "PAA ExtAct Card";
        PreviousAreas: Text;
        Found: Boolean;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        Found := AreaPage.BaseBasicAct.Visible();
        asserterror AreaPage.ExtServiceAct.Invoke();
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');
        Assert.IsTrue(Found, 'the page''s own #Basic action must be found under #Basic,#Suite');
    end;

    [Test]
    procedure ExtAction_OwnAreaEnabled_IsFoundAndRuns()
    var
        AreaRec: Record "PAA ExtAct Record";
        AreaPage: TestPage "PAA ExtAct Card";
        PreviousAreas: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Service');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        AreaPage.ExtServiceAct.Invoke();
        AreaPage.Close();
        ApplicationArea(PreviousAreas);
        Assert.AreEqual('EXT-SERVICE', RanValue(), 'the extension''s #Service action must run with #Service enabled');
    end;

    [Test]
    procedure ExtAction_NoArea_DoesNotInheritPageArea_IsNotFound()
    var
        AreaRec: Record "PAA ExtAct Record";
        AreaPage: TestPage "PAA ExtAct Card";
        PreviousAreas: Text;
        Found: Boolean;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        Found := AreaPage.BaseBasicAct.Visible();
        asserterror AreaPage.ExtNoAreaAct.Invoke();
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');
        Assert.IsTrue(Found, 'the page''s own #Basic action must be found under #Basic');
    end;

    [Test]
    procedure ExtAction_NoArea_EmptyAreaString_IsFoundAndRuns()
    var
        AreaRec: Record "PAA ExtAct Record";
        AreaPage: TestPage "PAA ExtAct Card";
        PreviousAreas: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        AreaPage.ExtNoAreaAct.Invoke();
        AreaPage.Close();
        ApplicationArea(PreviousAreas);
        Assert.AreEqual('EXT-NOAREA', RanValue(), 'with every area enabled the no-area extension action must run');
    end;

    [Test]
    procedure ExtGroupedAction_OwnAreaNotEnabled_IsNotFound()
    var
        AreaRec: Record "PAA ExtAct Record";
        AreaPage: TestPage "PAA ExtAct Card";
        PreviousAreas: Text;
        Found: Boolean;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        Found := AreaPage.BaseBasicAct.Visible();
        asserterror AreaPage.ExtGroupedServiceAct.Invoke();
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');
        Assert.IsTrue(Found, 'the page''s own #Basic action must be found under #Basic,#Suite');
    end;

    [Test]
    procedure ModifiedAction_ModifyValueEnabled_IsFoundAndRuns()
    var
        AreaRec: Record "PAA ExtAct Record";
        AreaPage: TestPage "PAA ExtAct Card";
        PreviousAreas: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        AreaPage.BaseServiceAct.Invoke();
        AreaPage.Close();
        ApplicationArea(PreviousAreas);
        Assert.AreEqual('BASE-MODIFIED', RanValue(), 'the action the modify() moved to #Suite must run under #Basic,#Suite');
    end;

    [Test]
    procedure ModifiedAction_BaseValueNoLongerApplies_IsNotFound()
    var
        AreaRec: Record "PAA ExtAct Record";
        AreaPage: TestPage "PAA ExtAct Card";
        PreviousAreas: Text;
        Found: Boolean;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Service');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        Found := AreaPage.ExtServiceAct.Visible();
        asserterror AreaPage.BaseServiceAct.Invoke();
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');
        Assert.IsTrue(Found, 'the extension''s #Service action must be found under #Basic,#Service');
    end;

    [Test]
    procedure ExtActionRef_TargetNotEnabled_IsNotFound()
    var
        AreaRec: Record "PAA ExtAct Record";
        AreaPage: TestPage "PAA ExtAct Card";
        PreviousAreas: Text;
        Found: Boolean;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        Found := AreaPage.ExtBasicRef.Visible();
        asserterror AreaPage.ExtServiceRef.Invoke();
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');
        Assert.IsTrue(Found, 'the extension''s area-less actionref to a #Basic action must be found under #Basic,#Suite');
    end;

    [Test]
    procedure ExtActionRef_TargetEnabled_IsFound()
    var
        AreaRec: Record "PAA ExtAct Record";
        AreaPage: TestPage "PAA ExtAct Card";
        PreviousAreas: Text;
        Found: Boolean;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Service');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        Found := AreaPage.ExtServiceRef.Visible();
        AreaPage.Close();
        ApplicationArea(PreviousAreas);
        Assert.IsTrue(Found, 'the extension''s actionref to a #Service action must be found with #Service enabled');
    end;

    // Invoking the actionref runs its target's OnAction -- for a target the same pageextension
    // adds, and for a target the base page declares. Written for AL Runner issue
    // StefanMaron/BusinessCentral.AL.Runner#4878 by agent stma-auto2-4.
    [Test]
    procedure ExtActionRef_ToExtensionAction_InvokeRunsTheTargetsTrigger()
    var
        AreaRec: Record "PAA ExtAct Record";
        AreaPage: TestPage "PAA ExtAct Card";
        PreviousAreas: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Service');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        AreaPage.ExtServiceRef.Invoke();
        AreaPage.Close();
        ApplicationArea(PreviousAreas);
        Assert.AreEqual('EXT-SERVICE', RanValue(), 'invoking the extension''s actionref must run the OnAction of the action the same extension adds');
    end;

    [Test]
    procedure ExtActionRef_ToBasePageAction_InvokeRunsTheTargetsTrigger()
    var
        AreaRec: Record "PAA ExtAct Record";
        AreaPage: TestPage "PAA ExtAct Card";
        PreviousAreas: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        AreaPage.ExtBasicRef.Invoke();
        AreaPage.Close();
        ApplicationArea(PreviousAreas);
        Assert.AreEqual('BASE-BASIC', RanValue(), 'invoking the extension''s actionref must run the OnAction of the base page action it points at');
    end;

    [Test]
    procedure ExtPart_OwnAreaNotEnabled_IsNotFound()
    var
        AreaRec: Record "PAA ExtAct Record";
        AreaPage: TestPage "PAA ExtAct Card";
        PreviousAreas: Text;
        Shown: Text;
        Caption: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        AreaPage.OpenView();
        AreaPage.GoToRecord(AreaRec);
        Caption := AreaPage.CodeCtl.Caption();
        asserterror Shown := AreaPage.ExtServicePart.PartCode.Value();
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('was not found on the page.');
        Assert.AreEqual('Code', Caption, 'the page''s own control must be found under #Basic,#Suite');
    end;

    [Test]
    procedure ExtPart_OwnAreaEnabled_IsFound()
    var
        AreaRec: Record "PAA ExtAct Record";
        AreaPage: TestPage "PAA ExtAct Card";
        PreviousAreas: Text;
        Shown: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Service');

        AreaPage.OpenView();
        AreaPage.GoToRecord(AreaRec);
        Shown := AreaPage.ExtServicePart.PartCode.Value();
        AreaPage.Close();
        ApplicationArea(PreviousAreas);
        Assert.AreEqual('PAAA', Shown, 'the extension''s #Service part must be found with #Service enabled');
    end;
}

codeunit 67539 "PAA Ext Action Part Host Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure ExtActionOnPrecompiledPage_OwnAreaNotEnabled_IsNotFound()
    var
        Groups: TestPage "Inventory Posting Groups";
        PreviousAreas: Text;
        Caption: Text;
    begin
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        Groups.OpenView();
        Caption := Groups.Code.Caption();
        asserterror Groups.PAAXServiceAct.Invoke();
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');
        Assert.AreEqual('Code', Caption, 'the page''s own "Code" control must be found under #Basic,#Suite');
    end;

    [Test]
    procedure ExtActionOnPrecompiledPage_OwnAreaEnabled_IsFound()
    var
        Groups: TestPage "Inventory Posting Groups";
        PreviousAreas: Text;
        ActionVisible: Boolean;
    begin
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Service');

        Groups.OpenView();
        ActionVisible := Groups.PAAXServiceAct.Visible();
        Groups.Close();
        ApplicationArea(PreviousAreas);
        Assert.IsTrue(ActionVisible, 'the extension''s #Service action must be found with #Service enabled');
    end;

    [Test]
    procedure ModifiedActionOnPrecompiledPage_BaseValueNoLongerApplies_IsNotFound()
    var
        Groups: TestPage "Inventory Posting Groups";
        PreviousAreas: Text;
        Caption: Text;
        SetupVisible: Boolean;
    begin
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        Groups.OpenView();
        Caption := Groups.Code.Caption();
        asserterror SetupVisible := Groups."&Setup".Visible();
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');
        Assert.AreEqual('Code', Caption, 'the page''s own "Code" control must be found under #Basic,#Suite');
    end;

    [Test]
    procedure ModifiedActionOnPrecompiledPage_ModifyValueEnabled_IsFound()
    var
        Groups: TestPage "Inventory Posting Groups";
        PreviousAreas: Text;
        SetupVisible: Boolean;
    begin
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Service');

        Groups.OpenView();
        SetupVisible := Groups."&Setup".Visible();
        asserterror Groups.Code.SetValue('X');
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');
        Assert.IsTrue(SetupVisible, 'the action the modify() moved to #Service must be found under #Service');
    end;

    [Test]
    procedure ExtPartOnPrecompiledPage_OwnAreaNotEnabled_IsNotFound()
    var
        Groups: TestPage "Inventory Posting Groups";
        PreviousAreas: Text;
        Caption: Text;
        Shown: Text;
    begin
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        Groups.OpenView();
        Caption := Groups.Code.Caption();
        asserterror Shown := Groups.PAAXServicePart.PartCode.Value();
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('was not found on the page.');
        Assert.AreEqual('Code', Caption, 'the page''s own "Code" control must be found under #Basic,#Suite');
    end;

    [Test]
    procedure ExtPartOnPrecompiledPage_OwnAreaEnabled_IsFound()
    var
        Groups: TestPage "Inventory Posting Groups";
        PreviousAreas: Text;
        Caption: Text;
    begin
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Service');

        Groups.OpenView();
        Caption := Groups.PAAXServicePart.PartCode.Caption();
        Groups.Close();
        ApplicationArea(PreviousAreas);
        Assert.AreEqual('Code', Caption, 'the extension''s #Service part must be found with #Service enabled');
    end;
}
