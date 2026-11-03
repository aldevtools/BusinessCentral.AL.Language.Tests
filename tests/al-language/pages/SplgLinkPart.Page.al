// Fixture for "SPLG Tests" (60232): a CardPart linked on two fields. It reads its link the way
// Base Application page 1286 "Payment Rec Match Details" does -- Rec.FilterGroup(4) then
// GetFilter -- and records what group 4 and group 0 each answer.
page 60232 "SPLG Link Part"
{
    PageType = CardPart;
    SourceTable = "SPLG Line";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field("Line No."; Rec."Line No.") { ApplicationArea = All; }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Probe: Codeunit "SPLG Probe";
        G0Line: Text;
        G0Header: Text;
        G4Line: Text;
        G4Header: Text;
        SavedGroup: Integer;
    begin
        SavedGroup := Rec.FilterGroup();
        Rec.FilterGroup(0);
        G0Line := Rec.GetFilter("Line No.");
        G0Header := Rec.GetFilter("Header Code");
        Rec.FilterGroup(4);
        G4Line := Rec.GetFilter("Line No.");
        G4Header := Rec.GetFilter("Header Code");
        Rec.FilterGroup(SavedGroup);
        Probe.ObserveLink(G4Line, G4Header, G0Line, G0Header);
    end;
}
