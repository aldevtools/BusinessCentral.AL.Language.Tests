// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-triggers-auto-page-onaftergetrecord
// Scope: in-scope
//
// A card whose only observable behaviour lives in OnAfterGetRecord — deliberately NOT in
// OnOpenPage, because the two are raised by different mechanisms when a page is opened
// modally and handed to a [ModalPageHandler], and this suite is about the row-load one.
page 60402 "MRL Modal Card"
{
    PageType = Card;
    SourceTable = "MRL Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Descr; Rec.Descr) { ApplicationArea = All; }
        }
    }

    trigger OnAfterGetRecord()
    var
        Probe: Record "MRL Probe";
    begin
        // One row per distinct source row loaded; re-firing for the same row is not what this
        // suite measures, so it is deduplicated here rather than asserted on.
        if Probe.Get(Rec."No.") then
            exit;
        Probe.Init();
        Probe.Marker := Rec."No.";
        Probe.Seen := Rec.Descr;
        Probe.Insert();
    end;
}
