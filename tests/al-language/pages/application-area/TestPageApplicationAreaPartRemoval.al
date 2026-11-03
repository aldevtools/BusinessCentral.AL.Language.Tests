// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-app-area
// Scope: in-scope
// Fixtures used: Assert (60021), and the table, pages and codeunit declared below.
//
// CLAIM: a page PART whose ApplicationArea is not enabled for the session is removed from the
// page, so a TestPage reports it as not found, while a part whose area IS enabled stays
// reachable and shows its rows. That holds for a part in the content area and for a part in
// the FactBoxes area. An empty application-area string enables every area.
//
// Every test sets the session's application areas itself and restores the previous value
// BEFORE it asserts, so the result does not depend on which areas the harness opened the
// session with.
//
// Written by agent stma-auto2-1, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4830.

table 67532 "PAA Part Record"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Description; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 67533 "PAA Part Lines"
{
    PageType = ListPart;
    SourceTable = "PAA Part Record";

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(LineCode; Rec."Code")
                {
                    ApplicationArea = Basic;
                }
                field(LineDescription; Rec.Description)
                {
                    ApplicationArea = Basic;
                }
            }
        }
    }
}

page 67532 "PAA Part Card"
{
    PageType = Card;
    SourceTable = "PAA Part Record";

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
            }
            part(BasicPart; "PAA Part Lines")
            {
                ApplicationArea = Basic;
            }
            part(ServicePart; "PAA Part Lines")
            {
                ApplicationArea = Service;
            }
        }
        area(FactBoxes)
        {
            part(ServiceFactBox; "PAA Part Lines")
            {
                ApplicationArea = Service;
            }
        }
    }
}

codeunit 67532 "PAA Area Part Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure MakeRecord(var PartRec: Record "PAA Part Record")
    begin
        PartRec.DeleteAll();
        PartRec.Init();
        PartRec."Code" := 'P1';
        PartRec.Description := 'first line';
        PartRec.Insert();
    end;

    [Test]
    procedure AreaNotEnabled_ContentPartIsNotFound()
    var
        PartRec: Record "PAA Part Record";
        PartPage: TestPage "PAA Part Card";
        PreviousAreas: Text;
    begin
        MakeRecord(PartRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        PartPage.OpenView();
        PartPage.GoToRecord(PartRec);
        asserterror PartPage.ServicePart.First();
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('was not found on the page.');
    end;

    [Test]
    procedure AreaNotEnabled_FactBoxPartIsNotFound()
    var
        PartRec: Record "PAA Part Record";
        PartPage: TestPage "PAA Part Card";
        PreviousAreas: Text;
    begin
        MakeRecord(PartRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        PartPage.OpenView();
        PartPage.GoToRecord(PartRec);
        asserterror PartPage.ServiceFactBox.First();
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('was not found on the page.');
    end;

    [Test]
    procedure AreaNotEnabled_EnabledPartIsStillFound()
    var
        PartRec: Record "PAA Part Record";
        PartPage: TestPage "PAA Part Card";
        PreviousAreas: Text;
        ReadBack: Text;
    begin
        MakeRecord(PartRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        PartPage.OpenView();
        PartPage.GoToRecord(PartRec);
        PartPage.BasicPart.First();
        ReadBack := PartPage.BasicPart.LineDescription.Value();
        PartPage.Close();
        ApplicationArea(PreviousAreas);

        Assert.AreEqual('first line', ReadBack, 'the #Basic part must be found and show its row');
    end;

    [Test]
    procedure AreaEnabled_ServicePartIsFound()
    var
        PartRec: Record "PAA Part Record";
        PartPage: TestPage "PAA Part Card";
        PreviousAreas: Text;
        ReadBack: Text;
        FactBoxReadBack: Text;
    begin
        MakeRecord(PartRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Service');

        PartPage.OpenView();
        PartPage.GoToRecord(PartRec);
        PartPage.ServicePart.First();
        ReadBack := PartPage.ServicePart.LineDescription.Value();
        PartPage.ServiceFactBox.First();
        FactBoxReadBack := PartPage.ServiceFactBox.LineDescription.Value();
        PartPage.Close();
        ApplicationArea(PreviousAreas);

        Assert.AreEqual('first line', ReadBack, 'with #Service enabled the #Service part must be found');
        Assert.AreEqual('first line', FactBoxReadBack, 'with #Service enabled the #Service factbox must be found');
    end;

    [Test]
    procedure EmptyAreaString_ServicePartIsFound()
    var
        PartRec: Record "PAA Part Record";
        PartPage: TestPage "PAA Part Card";
        PreviousAreas: Text;
        ReadBack: Text;
    begin
        MakeRecord(PartRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('');

        PartPage.OpenView();
        PartPage.GoToRecord(PartRec);
        PartPage.ServicePart.First();
        ReadBack := PartPage.ServicePart.LineDescription.Value();
        PartPage.Close();
        ApplicationArea(PreviousAreas);

        Assert.AreEqual('first line', ReadBack, 'with every area enabled the #Service part must be found');
    end;
}
