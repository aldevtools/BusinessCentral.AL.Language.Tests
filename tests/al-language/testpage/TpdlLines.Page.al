// Fixture line part for TestPagePartDraftLineLink.al: an ordinary editable, insert-allowed
// repeater, so it carries the implicit blank draft line past its data the way every Base
// Application line grid does. AutoSplitKey mirrors those grids too -- it is what gives a row
// started on the draft line a "Line No." that does not collide with the rows already there.
//
// "Header No." is shown as a control so a test can read what the draft line holds in the very
// column the SubPageLink constrains.
page 60997 "TPDL Lines"
{
    PageType = ListPart;
    SourceTable = "TPDL Line";
    ApplicationArea = All;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(HeaderNo; Rec."Header No.") { ApplicationArea = All; }
                field(LineNo; Rec."Line No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
                field(HeaderSeen; Rec."Header Seen By Validate") { ApplicationArea = All; }
                field(SetByOnNewRecord; Rec."Set By OnNewRecord") { ApplicationArea = All; }
            }
        }
    }

    // The page's own OnNewRecord. It fires for New(); whether it also fires when a row is
    // started by typing into the draft line is the second thing this fixture measures -- the
    // draft line becoming a record is either the same platform step New() runs, or it is not.
    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Set By OnNewRecord" := 'NEWREC';
    end;
}
