// Migrated from AL Runner tests/runner-extras/testpage-record-triggers (TrtSrc.al).
/// <summary>
/// A page that establishes what it is looking at BEFORE anyone reads it — the shape that
/// matters in the wild. A caller fetches-or-creates a per-user singleton buffer in
/// OnOpenPage, and every action on the page then Modifies that row; without the trigger the
/// page sits on a blank record and the first Modify fails against a row that was never
/// fetched.
///
/// Kept separate from "TRT Card" on purpose: adding an OnOpenPage there would change what
/// every other test in this suite is looking at.
/// </summary>
page 60843 "TRT Singleton Card"
{
    PageType = Card;
    SourceTable = "TRT Row";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Note; Rec.Note) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Stamp)
            {
                ApplicationArea = All;
                Caption = 'Stamp';

                trigger OnAction()
                begin
                    // Exactly what a real action does: Modify the row OnOpenPage fetched.
                    Rec.Note := 'stamped';
                    Rec.Modify(true);
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Row: Record "TRT Row";
    begin
        if not Row.Get('SINGLETON') then begin
            Row.Init();
            Row."No." := 'SINGLETON';
            Row.Note := 'created-by-onopenpage';
            Row.Insert();
        end;
        Rec.Get('SINGLETON');
    end;

    trigger OnClosePage()
    var
        Echo: Record "TRT Echo";
    begin
        Echo.Bump('CLOSED');
    end;
}
