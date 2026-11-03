// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-app-area
// Scope: in-scope
// Fixtures used: Assert (60021), and the table, page and codeunit declared below.
//
// CLAIM: a page control whose ApplicationArea is not enabled for the session is removed from
// the page, so a TestPage reports it as not found, while a control whose area IS enabled stays
// reachable. An empty application-area string enables every area, and then every control is
// reachable.
//
// Every test sets the session's application areas itself and restores the previous value
// BEFORE it asserts, because which areas a test session starts with depends on how the
// harness opened it (an empty string enables all; an experience tier such as Essential does
// not include #Service).
//
// Written by agent stma-auto2-15, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4750.

table 67530 "PAA Area Record"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "Basic Value"; Text[30]) { }
        field(3; "Service Value"; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 67530 "PAA Area Card"
{
    PageType = Card;
    SourceTable = "PAA Area Record";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeCtl; Rec."Code")
                {
                    ApplicationArea = Basic;
                }
                field(BasicCtl; Rec."Basic Value")
                {
                    ApplicationArea = Basic;
                }
                field(ServiceCtl; Rec."Service Value")
                {
                    ApplicationArea = Service;
                }
            }
        }
    }
}

codeunit 67530 "PAA Area Control Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure MakeRecord(var AreaRec: Record "PAA Area Record")
    begin
        AreaRec.DeleteAll();
        AreaRec.Init();
        AreaRec."Code" := 'PAA';
        AreaRec.Insert();
    end;

    [Test]
    procedure AreaNotEnabled_ControlIsNotFound()
    var
        AreaRec: Record "PAA Area Record";
        AreaPage: TestPage "PAA Area Card";
        PreviousAreas: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        asserterror AreaPage.ServiceCtl.SetValue('S');
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');
    end;

    [Test]
    procedure AreaNotEnabled_EnabledControlIsStillFoundAndWrites()
    var
        AreaRec: Record "PAA Area Record";
        AreaPage: TestPage "PAA Area Card";
        PreviousAreas: Text;
        ReadBack: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        AreaPage.BasicCtl.SetValue('B1');
        ReadBack := AreaPage.BasicCtl.Value();
        AreaPage.Close();
        ApplicationArea(PreviousAreas);

        AreaRec.Get('PAA');
        Assert.AreEqual('B1', ReadBack, 'the #Basic control must read back the value just set');
        Assert.AreEqual('B1', AreaRec."Basic Value", 'the #Basic control must write its field');
    end;

    [Test]
    procedure AreaEnabled_ControlIsFoundAndWrites()
    var
        AreaRec: Record "PAA Area Record";
        AreaPage: TestPage "PAA Area Card";
        PreviousAreas: Text;
        ReadBack: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Service');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        AreaPage.ServiceCtl.SetValue('S1');
        ReadBack := AreaPage.ServiceCtl.Value();
        AreaPage.Close();
        ApplicationArea(PreviousAreas);

        AreaRec.Get('PAA');
        Assert.AreEqual('S1', ReadBack, 'the #Service control must read back the value just set');
        Assert.AreEqual('S1', AreaRec."Service Value", 'the #Service control must write its field');
    end;

    [Test]
    procedure EmptyAreaString_EveryControlIsFound()
    var
        AreaRec: Record "PAA Area Record";
        AreaPage: TestPage "PAA Area Card";
        PreviousAreas: Text;
        ReadBack: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        AreaPage.ServiceCtl.SetValue('S2');
        ReadBack := AreaPage.ServiceCtl.Value();
        AreaPage.Close();
        ApplicationArea(PreviousAreas);

        Assert.AreEqual('S2', ReadBack, 'with every area enabled the #Service control must be found');
    end;
}
