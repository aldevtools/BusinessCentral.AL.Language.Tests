// Fixture for TestPageQueryCloseError_Tests.al.
/// <summary>
/// A modal page that writes a row in OnOpenPage and, when armed with SetFail(true), raises an
/// AL error from OnQueryClosePage. Both halves are needed: the write is what the rollback arm
/// observes, and the error is what the envelope arm observes. Unarmed the page closes normally,
/// which is the negative control that stops "always fail" from passing the suite.
/// </summary>
page 60676 "QCE Error Modal"
{
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'QCE Error Modal';

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
        FailOnQueryClose: Boolean;
        CloseRefusedErr: Label 'QCE close refused by OnQueryClosePage';

    procedure SetFail(NewFailOnQueryClose: Boolean)
    begin
        FailOnQueryClose := NewFailOnQueryClose;
    end;

    trigger OnOpenPage()
    var
        Row: Record "QCE Row";
    begin
        MarkerVar := 'OPENED';
        if not Row.Get('OPENED') then begin
            Row.Init();
            Row."No." := 'OPENED';
            Row."Set ID" := 42;
            Row.Insert();
        end;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if FailOnQueryClose then
            Error(CloseRefusedErr);
        exit(true);
    end;
}
