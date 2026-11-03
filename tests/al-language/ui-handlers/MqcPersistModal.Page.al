// Fixture for TestPageModalQueryClose_Tests.al.
/// <summary>
/// The "Manage X" worksheet shape: the caller hands the page a copy of the record it wants
/// changed, and the page writes that copy back in OnQueryClosePage when the user confirms.
/// Nothing else on the page persists anything, so the row only changes if OnQueryClosePage
/// ran with a confirming CloseAction.
/// </summary>
page 60274 "MQC Persist Modal"
{
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'MQC Persist Modal';

    layout
    {
        area(Content)
        {
            field(Combination; CombinationVar)
            {
                ApplicationArea = All;
                Caption = 'Combination';
            }
        }
    }

    var
        Target: Record "MQC Row";
        CombinationVar: Text[10];

    trigger OnOpenPage()
    begin
        CombinationVar := 'AND';
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Trace: Record "MQC Trace";
    begin
        Trace.Log(CopyStr('QUERYCLOSE:' + Format(CloseAction), 1, 50));
        if (CloseAction <> CloseAction::OK) and (CloseAction <> CloseAction::LookupOK) then
            exit(true);
        Target."Set ID" := 0;
        Target.Modify();
        exit(true);
    end;

    trigger OnClosePage()
    var
        Trace: Record "MQC Trace";
    begin
        Trace.Log('CLOSEPAGE');
    end;

    procedure SetTarget(var Row: Record "MQC Row")
    begin
        Target := Row;
    end;
}
