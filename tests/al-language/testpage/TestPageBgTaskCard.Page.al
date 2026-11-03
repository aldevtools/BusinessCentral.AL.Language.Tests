// Fixture page for TestPageBgTask_Tests.al. Enqueues a page background task from
// OnAfterGetCurrRecord (the shape a FactBox-style computed field uses), and exposes the
// completion/error trigger outcomes through plain bound controls so a TestPage can read
// them back -- a TestPage only sees standard fields/actions, never custom procedures.

page 60792 "Test Page BgTask Card"
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
            field(Handle; Rec.Handle) { ApplicationArea = All; }
            field(CountTextCtl; CountText) { ApplicationArea = All; Caption = 'Count Text'; }
            field(LastErrorTextCtl; LastErrorText) { ApplicationArea = All; Caption = 'Last Error Text'; }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Args: Dictionary of [Text, Text];
    begin
        Clear(Args);
        Args.Add('No', Rec."No.");
        CurrPage.EnqueueBackgroundTask(TaskId, Codeunit::"Test Page BgTask Worker", Args, 5000);
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    begin
        Results.Get('Count', CountText);
    end;

    trigger OnPageBackgroundTaskError(TaskId: Integer; ErrorCode: Text; ErrorText: Text; ErrorCallStack: Text; var IsHandled: Boolean)
    begin
        LastErrorText := ErrorText;
        IsHandled := Rec.Handle;
    end;

    var
        TaskId: Integer;
        CountText: Text;
        LastErrorText: Text;
}
