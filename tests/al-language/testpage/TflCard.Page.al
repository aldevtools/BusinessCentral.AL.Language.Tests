// Fixture card for TestPageFieldTableLookup.al. "Table Only" is deliberately a bare control
// with no trigger of its own, so the only OnLookup in reach is the one on the table field;
// Both carries a control trigger next to the table field's, which is what makes the
// precedence test a real question rather than a restatement of the first.
page 60315 "TFL Card"
{
    PageType = Card;
    SourceTable = "TFL Row";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field("Table Only"; Rec."Table Only") { ApplicationArea = All; }
            field(Both; Rec.Both)
            {
                ApplicationArea = All;
                trigger OnLookup(var Text: Text): Boolean
                begin
                    Text := 'FROM-CONTROL';
                    exit(true);
                end;
            }
        }
    }
}
