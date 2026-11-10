// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-visible-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects below
// local object: the host page, its page extension and the part page are the objects under test (a part whose Visible is bound to a Boolean field of Rec)
// Probe: written against BC 27.5, 28.5 and 29.0 through the corpus CI; every literal asserted below is what those tiers produced (they agree).
// Facts: a part whose Visible is bound to a Boolean field of Rec (declared on the host page, and added by a page extension to the FactBoxes area) reports
//   Visible() false for the part, and for a control inside the part, when the field is false on the opened record, and true when it is true.
//   Filed from AL Runner issue 7455.
// BC versions: 27+ (tested by the corpus CI matrix)

table 96830 "LT PVR Host"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; "Show Part"; Boolean) { }
        field(3; Name; Text[30]) { }
    }
    keys { key(PK; Code) { Clustered = true; } }
}

table 96831 "LT PVR Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; "Line No."; Integer) { }
        field(3; Description; Text[30]) { }
    }
    keys { key(PK; Code, "Line No.") { Clustered = true; } }
}

page 96832 "LT PVR Lines"
{
    PageType = ListPart;
    SourceTable = "LT PVR Line";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rep)
            {
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }
}

page 96833 "LT PVR Host Card"
{
    PageType = Card;
    SourceTable = "LT PVR Host";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
        area(FactBoxes)
        {
            part(BasePart; "LT PVR Lines")
            {
                ApplicationArea = All;
                SubPageLink = Code = field(Code);
                Visible = Rec."Show Part";
            }
        }
    }
}

pageextension 96834 "LT PVR Host Card Ext" extends "LT PVR Host Card"
{
    layout
    {
        addlast(FactBoxes)
        {
            part(ExtPart; "LT PVR Lines")
            {
                ApplicationArea = All;
                SubPageLink = Code = field(Code);
                Visible = Rec."Show Part";
            }
        }
    }
}

codeunit 96830 "LT PVR Part Visible Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Host: Record "LT PVR Host";
        Line: Record "LT PVR Line";
    begin
        Host.DeleteAll();
        Line.DeleteAll();
        Host.Init();
        Host.Code := 'HIDDEN';
        Host."Show Part" := false;
        Host.Insert();
        Host.Code := 'SHOWN';
        Host."Show Part" := true;
        Host.Insert();
        Line.Code := 'HIDDEN';
        Line."Line No." := 1;
        Line.Description := 'hidden line';
        Line.Insert();
        Line.Code := 'SHOWN';
        Line.Description := 'shown line';
        Line.Insert();
    end;

    [Test]
    procedure PartVisibleBoundToFalseRecField_PartAndControlReportNotVisible()
    var
        Observer: Codeunit "Probe Observer";
        Host: Record "LT PVR Host";
        Card: TestPage "LT PVR Host Card";
    begin
        Seed();
        Host.Get('HIDDEN');
        Card.Trap();
        Page.Run(Page::"LT PVR Host Card", Host);
        Observer.Observe('base part Visible', Format(Card.BasePart.Visible()));
        Observer.Observe('base part control Visible', Format(Card.BasePart.Description.Visible()));
        Observer.Observe('extension part Visible', Format(Card.ExtPart.Visible()));
        Observer.Observe('extension part control Visible', Format(Card.ExtPart.Description.Visible()));
        Observer.Expect('base part Visible', 'No');
        Observer.Expect('base part control Visible', 'No');
        Observer.Expect('extension part Visible', 'No');
        Observer.Expect('extension part control Visible', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure PartVisibleBoundToTrueRecField_PartAndControlReportVisible()
    var
        Observer: Codeunit "Probe Observer";
        Host: Record "LT PVR Host";
        Card: TestPage "LT PVR Host Card";
    begin
        Seed();
        Host.Get('SHOWN');
        Card.Trap();
        Page.Run(Page::"LT PVR Host Card", Host);
        Observer.Observe('base part Visible', Format(Card.BasePart.Visible()));
        Observer.Observe('base part control Visible', Format(Card.BasePart.Description.Visible()));
        Observer.Observe('extension part Visible', Format(Card.ExtPart.Visible()));
        Observer.Observe('extension part control Visible', Format(Card.ExtPart.Description.Visible()));
        Observer.Expect('base part Visible', 'Yes');
        Observer.Expect('base part control Visible', 'Yes');
        Observer.Expect('extension part Visible', 'Yes');
        Observer.Expect('extension part control Visible', 'Yes');
        Observer.Verify();
    end;
}
