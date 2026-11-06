// local object: the field shape, enum members or page layout/trigger definition is the behavior under test.
page 69039 "TPG Empty Lines"
{
    PageType = ListPart;
    SourceTable = "ALT Child";
    DelayedInsert = true;
    AutoSplitKey = true;
    layout { area(Content) { repeater(Lines) { field(Description; Rec.Code) { ApplicationArea = All; } } } }
    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Code := 'New-line marker';
    end;
}
