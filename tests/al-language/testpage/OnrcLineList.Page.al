// Fixture TOP-LEVEL list for TestPagePartOnNewRecordCount.al: the same "ONRC Line" rows as the
// "ONRC Lines" part, as an ordinary editable, insert-allowed List page, so New() can be measured
// on a page that is not a subpage. OnNewRecord logs one "ONRC Log" row per firing, Source 'LIST'.
page 67001 "ONRC Line List"
{
    PageType = List;
    SourceTable = "ONRC Line";
    ApplicationArea = All;
    UsageCategory = Lists;
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

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Record "ONRC Log";
    begin
        Log.Init();
        Log.Source := 'LIST';
        Log."Below xRec" := BelowxRec;
        Log.Insert(true);
    end;
}
