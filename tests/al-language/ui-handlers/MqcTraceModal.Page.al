// Fixture for TestPageModalQueryClose_Tests.al.
/// <summary>
/// A page with NO SourceTable — the ordinary AL shape for a prompt whose state lives in page
/// globals — that records nothing except which close-lifecycle triggers fired and with what
/// CloseAction. No persistence, so a test reading its trace is reading the platform's trigger
/// order and nothing else.
/// </summary>
page 60273 "MQC Trace Modal"
{
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'MQC Trace Modal';

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
