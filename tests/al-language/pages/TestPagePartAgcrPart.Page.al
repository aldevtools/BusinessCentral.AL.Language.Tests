// Fixture part page for TestPagePartAgcr_Tests.al. A FactBox-style CardPart with its OWN
// SourceTable, linked to the host's current row via SubPageLink -- the common shape a
// summary/usage-count FactBox uses. Appends to the shared trace codeunit on OnOpenPage and
// OnAfterGetCurrRecord so a test can observe WHETHER and WHEN this part's row gets fetched,
// without the test itself doing anything to force it.

page 60813 "Test Page Part Agcr Part"
{
    PageType = CardPart;
    SourceTable = "Test Page Part Agcr Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Trace: Codeunit "Test Page Part Agcr Trace";
    begin
        Trace.Append('PartOpen');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Trace: Codeunit "Test Page Part Agcr Trace";
    begin
        Trace.Append('PartAGCR:' + Rec."No.");
    end;
}
