// Fixture for TestPageModalSelfClose_Tests.al.
/// <summary>
/// The self-closing variant of "MQC Persist Modal": the caller hands the page a copy of the
/// record it wants changed, the page's own action closes the page, and OnQueryClosePage writes
/// that copy back. The row carries a counter rather than a flag so a test can tell "written"
/// from "written twice" -- which is the whole point of the arm.
/// </summary>
page 60295 "MQC Self Close Persist"
{
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'MQC Self Close Persist';

    layout
    {
        area(Content)
        {
            field(Dummy; DummyVar)
            {
                ApplicationArea = All;
                Caption = 'Dummy';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CloseMe)
            {
                ApplicationArea = All;
                Caption = 'Close Me';

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
        }
    }

    var
        Target: Record "MQC Row";
        DummyVar: Text[10];

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        // Increment rather than assign: an implementation that runs this trigger twice writes
        // 2, and an assignment would hide that behind the same value.
        Target."Set ID" += 1;
        Target.Modify();
        exit(true);
    end;

    procedure SetTarget(var Row: Record "MQC Row")
    begin
        Target := Row;
    end;
}
