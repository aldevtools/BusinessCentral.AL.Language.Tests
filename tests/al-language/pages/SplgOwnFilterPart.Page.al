// Fixture for "SPLG Tests" (60232): a ListPart linked on "Header Code" only, which sets its OWN
// filter on "Line No." in filter group 0 when it opens. The rows it shows must satisfy both.
page 60233 "SPLG Own Filter Part"
{
    PageType = ListPart;
    SourceTable = "SPLG Line";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(0);
        Rec.SetFilter("Line No.", '>=%1', 20000);
    end;

    trigger OnAfterGetCurrRecord()
    var
        Probe: Codeunit "SPLG Probe";
        G0Line: Text;
        G4Header: Text;
        G4Line: Text;
        SavedGroup: Integer;
    begin
        SavedGroup := Rec.FilterGroup();
        Rec.FilterGroup(0);
        G0Line := Rec.GetFilter("Line No.");
        Rec.FilterGroup(4);
        G4Header := Rec.GetFilter("Header Code");
        G4Line := Rec.GetFilter("Line No.");
        Rec.FilterGroup(SavedGroup);
        Probe.ObserveOwn(G4Header, G4Line, G0Line);
    end;
}
