page 60334 "TBA Prompt Bare"
{
    Caption = 'TBA Prompt Bare';
    PageType = PromptDialog;
    ApplicationArea = All;
    UsageCategory = None;
    Extensible = false;
    SourceTable = "TBA Trace";
    SourceTableTemporary = true;

    layout
    {
        area(Prompt)
        {
            field(InputText; Rec."Input Text")
            {
                ApplicationArea = All;
                ShowCaption = false;
                MultiLine = true;
            }
        }
        area(Content)
        {
            field(OutputText; Rec."Output Text")
            {
                ApplicationArea = All;
                Caption = 'Output Text';
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.PromptMode := PromptMode::Prompt;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Trace: Record "TBA Trace";
    begin
        Trace.Log('QUERYCLOSE:' + Format(CloseAction));
        exit(true);
    end;
}
