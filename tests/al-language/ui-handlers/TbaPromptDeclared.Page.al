page 60333 "TBA Prompt Declared"
{
    Caption = 'TBA Prompt Declared';
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

    actions
    {
        area(SystemActions)
        {
            systemaction(Generate)
            {
                Caption = 'Generate';

                trigger OnAction()
                var
                    Trace: Record "TBA Trace";
                begin
                    Trace.Log('GENERATE');
                end;
            }
            systemaction(OK)
            {
                Caption = 'Keep it';
            }
            systemaction(Cancel)
            {
                Caption = 'Discard';
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
