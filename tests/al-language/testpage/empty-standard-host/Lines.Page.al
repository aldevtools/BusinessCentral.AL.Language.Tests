// local object: the field shape, enum members or page layout/trigger definition is the behavior under test.
page 69039 "TPG Empty Lines"
{
    PageType = ListPart;
    SourceTable = "TPG Empty Line";
    DelayedInsert = true;
    AutoSplitKey = true;
    layout { area(Content) { repeater(Lines) { field(Description; Rec.Description) { ApplicationArea = All; } } } }
    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Description := 'New-line marker';
    end;
}
