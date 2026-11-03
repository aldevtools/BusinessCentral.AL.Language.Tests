// Fixture host page for TestPagePartAgcr_Tests.al. A card whose layout declares a FactBox
// part (Test Page Part Agcr Part, 60813), linked to the host's current row -- the shape a
// usage-count/summary FactBox uses in practice. Appends to the shared trace codeunit on its
// OWN OnOpenPage and OnAfterGetCurrRecord so the test can order them against the part's.

page 60814 "Test Page Part Agcr Host"
{
    PageType = Card;
    SourceTable = "Test Page Part Agcr Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
        }
        area(FactBoxes)
        {
            part(AgcrPart; "Test Page Part Agcr Part")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
            }
        }
    }

    trigger OnOpenPage()
    var
        Trace: Codeunit "Test Page Part Agcr Trace";
    begin
        Trace.Append('HostOpen');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Trace: Codeunit "Test Page Part Agcr Trace";
    begin
        Trace.Append('HostAGCR:' + Rec."No.");
    end;
}
