// Fixture page for TestPageBgTaskTx_Tests.al. Enqueues Test Page BgTask TxWorker (67200)
// from OnAfterGetCurrRecord -- the FactBox shape the Base Application's Journal Errors
// factbox uses -- and exposes what the worker reported through plain controls. The worker
// reads only rows whose "No." starts with 'ENQ', the prefix of the one test using this page.

page 67203 "Test Page BgTask Tx Card"
{
    PageType = Card;
    SourceTable = "Test Page BgTask Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(KeysCtl; KeysText) { ApplicationArea = All; Caption = 'Keys'; }
            field(InWriteTxCtl; InWriteTxText) { ApplicationArea = All; Caption = 'In Write Tx'; }
            field(GuardedRunCtl; GuardedRunText) { ApplicationArea = All; Caption = 'Guarded Run'; }
            field(ErrorCtl; LastErrorText) { ApplicationArea = All; Caption = 'Error'; }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Args: Dictionary of [Text, Text];
    begin
        Args.Add('Prefix', 'ENQ');
        CurrPage.EnqueueBackgroundTask(TaskId, Codeunit::"Test Page BgTask TxWorker", Args);
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    begin
        Results.Get('Keys', KeysText);
        Results.Get('InWriteTx', InWriteTxText);
        Results.Get('GuardedRun', GuardedRunText);
    end;

    trigger OnPageBackgroundTaskError(TaskId: Integer; ErrorCode: Text; ErrorText: Text; ErrorCallStack: Text; var IsHandled: Boolean)
    begin
        LastErrorText := ErrorText;
        IsHandled := true;
    end;

    var
        TaskId: Integer;
        KeysText: Text;
        InWriteTxText: Text;
        GuardedRunText: Text;
        LastErrorText: Text;
}
