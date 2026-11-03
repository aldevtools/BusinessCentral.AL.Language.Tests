// Fixture line part for TestPagePartOnNewRecordCount.al: an ordinary editable, insert-allowed
// repeater, so it shows the implicit blank draft line past its data exactly as "TPDL Lines"
// (60997) and every Base Application line grid do. AutoSplitKey is on for the same reason it is
// there -- a row promoted out of the draft line has to be numbered past the rows already
// present.
page 60356 "ONRC Lines"
{
    PageType = ListPart;
    SourceTable = "ONRC Line";
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
            }
        }
    }

    // ONE LOG ROW PER FIRING. This is the only thing this fixture does that "TPDL Lines" does
    // not, and it is the point: an assignment witness cannot count, an inserted row can.
    //
    // The Insert goes to a table the page does not own, so it survives both hazards that would
    // destroy a counter kept on Rec: NavForm.NewRecord's own ALInit, which wipes the buffer this
    // trigger runs against, and the client discarding a draft line nobody typed into.
    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Record "ONRC Log";
    begin
        Log.Init();
        Log.Source := 'LINES';
        Log."Below xRec" := BelowxRec;
        Log.Insert(true);
    end;
}
