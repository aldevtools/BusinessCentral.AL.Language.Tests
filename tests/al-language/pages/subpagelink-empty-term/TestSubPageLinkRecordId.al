// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpagelink-property
// Scope: Cloud-compatible TestPage behavior.
// local object: the child table has the RecordId field and the pages define the link under test.
table 69992 "PAG RecordId Link Row"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Target; RecordId) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

page 69993 "PAG RecordId Link Part"
{
    PageType = ListPart;
    SourceTable = "PAG RecordId Link Row";
    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
    }
}

page 69994 "PAG RecordId Link Card"
{
    PageType = Card;
    SourceTable = "ALT Universal";
    layout
    {
        area(Content)
        {
            part(Lines; "PAG RecordId Link Part")
            {
                ApplicationArea = All;
                SubPageLink = Target = const();
            }
        }
    }
}

codeunit 69995 "PAG RecordId Link Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SubPageLink_BlankRecordId_SelectsBlankRow()
    var
        Host: Record "ALT Universal";
        Line: Record "PAG RecordId Link Row";
        Card: TestPage "PAG RecordId Link Card";
    begin
        Initialize();
        Host."Entry No." := 101;
        Host.Insert(false);
        Line.Id := 202;
        Line.Insert(false);
        Line.Id := 303;
        Line.Target := Host.RecordId();
        Line.Insert(false);
        Card.OpenView();
        Card.Lines.First();
        Card.Lines.Id.AssertEquals(202);
        if Card.Lines.Next() then
            Error('Expected just the row with a blank RecordId.');
        Card.Close();
    end;

    local procedure Initialize()
    var
        Cleanup: Codeunit ALTFixtureCleanup;
        Line: Record "PAG RecordId Link Row";
    begin
        Cleanup.Initialize();
        Line.DeleteAll(false);
    end;
}
