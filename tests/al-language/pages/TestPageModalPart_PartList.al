// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subpages-overview
// Scope: in-scope
// Fixtures used: Test Page Modal Handler Row (60702)
//
// The subpage for the modal-part suite: an ordinary ListPart over its own source table.
// Neither hosting page declares a SubPageLink for it, so nothing about this part depends
// on a parent record — which is exactly what the no-SourceTable host tests rely on.

page 60731 "Test Page Modal PartList"
{
    PageType = ListPart;
    SourceTable = "Test Page Modal Handler Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(RowNo; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption = 'No.';
                }
                field(Descr; Rec.Descr)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                }
            }
        }
    }

    // The "parent field OnValidate pushes state into the part page" pattern (a Worksheet
    // header driving its lines part). Writing through to the table is what proves the
    // part page's own AL ran — the same durable-proof convention the rest of this suite uses.
    procedure SetTag(NewTag: Text)
    var
        Echo: Record "Test Page Modal Handler Row";
    begin
        Echo.Init();
        Echo."No." := 'PART-TAG';
        Echo.Descr := CopyStr(NewTag, 1, MaxStrLen(Echo.Descr));
        if not Echo.Insert() then
            Echo.Modify();
    end;
}
