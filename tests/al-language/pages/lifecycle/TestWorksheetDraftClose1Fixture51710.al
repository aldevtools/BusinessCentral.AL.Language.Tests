// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
page 51710 "Draft Probe Worksheet"
{
    PageType = Worksheet;
    SourceTable = "Draft Probe Header";
    DelayedInsert = true;
    AutoSplitKey = true;
    MultipleNewLines = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Item; Rec.Item) { }
                field(Quantity; Rec.Quantity) { }
            }
        }
        area(FactBoxes)
        {
            part(Details; "Draft Probe Detail Part")
            {
                SubPageLink = "Header Code" = field(Item);
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange(Batch, 'PLAN');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Batch := 'PLAN';
    end;
}
