// Fixture for TestPageQueryCloseError_Tests.al.
/// <summary>
/// The TestPage-driven twin of "QCE Error Modal": a page a test opens itself and closes itself,
/// whose OnQueryClosePage always raises the same AL error. Separate object rather than a flag on
/// the modal, because a TestPage variable cannot call the page's own procedures — the trigger
/// has to decide on its own.
/// </summary>
page 60678 "QCE Error Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'QCE Error Card';

    layout
    {
        area(Content)
        {
            field(Marker; MarkerVar)
            {
                ApplicationArea = All;
                Caption = 'Marker';
            }
        }
    }

    var
        MarkerVar: Text[10];
        CloseRefusedErr: Label 'QCE close refused by OnQueryClosePage';

    trigger OnOpenPage()
    begin
        MarkerVar := 'OPENED';
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Error(CloseRefusedErr);
    end;
}
