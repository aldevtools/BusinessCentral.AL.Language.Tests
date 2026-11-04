// Fixture for TestPageModalSelfClose_Tests.al.
/// <summary>
/// The footer-button shape: the page carries its OWN action captioned OK, and that action's
/// OnAction closes the page with CurrPage.Close(). A handler drives it by name -- Page.OK, the
/// page's action -- not the built-in OK() the platform synthesises. Markers are logged on both
/// sides of the Close call so a test can see whether the close runs inside OnAction or is
/// deferred until it returns.
/// </summary>
page 60294 "MQC Self Close Modal"
{
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'MQC Self Close Modal';

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
                var
                    Trace: Record "MQC Trace";
                begin
                    Trace.Log('ACTION');
                    CurrPage.Close();
                    Trace.Log('AFTER-CLOSE');
                end;
            }
        }
    }

    var
        DummyVar: Text[10];

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Trace: Record "MQC Trace";
    begin
        Trace.Log(CopyStr('QUERYCLOSE:' + Format(CloseAction), 1, 50));
        exit(true);
    end;

    trigger OnClosePage()
    var
        Trace: Record "MQC Trace";
    begin
        Trace.Log('CLOSEPAGE');
    end;
}
