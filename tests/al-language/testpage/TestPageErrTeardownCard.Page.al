page 60797 "TestPage ErrTeardown Card"
{
    PageType = Card;
    SourceTable = "TestPage ErrTeardown Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(content)
        {
            field(NoCtl; Rec."No.")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field(NameCtl; Rec.Name)
            {
                ApplicationArea = All;

                trigger OnValidate()
                begin
                    if Rec.FailOnValidate then
                        Error('Deliberate OnValidate failure for %1', Rec."No.");
                end;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(FailAction)
            {
                ApplicationArea = All;
                Caption = 'FailAction';
                Image = Action;

                trigger OnAction()
                begin
                    Error('Deliberate OnAction failure');
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Rec.FailOnGet then
            Error('Deliberate OnAfterGetRecord failure for %1', Rec."No.");
    end;
}
