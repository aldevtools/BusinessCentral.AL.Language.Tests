page 60335 "TBA Navigate"
{
    Caption = 'TBA Navigate';
    PageType = NavigatePage;
    ApplicationArea = All;
    UsageCategory = None;
    Extensible = false;
    SourceTable = "TBA Trace";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            field(OutputText; Rec."Output Text")
            {
                ApplicationArea = All;
                Caption = 'Output Text';
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Trace: Record "TBA Trace";
    begin
        Trace.Log('QUERYCLOSE:' + Format(CloseAction));
        exit(true);
    end;
}
