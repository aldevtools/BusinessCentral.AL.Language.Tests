/// <summary>The same card as "CNH Confirm True", with the Confirm default answer FALSE. Two
/// pages rather than one parameterised page because a page trigger takes no arguments and a
/// setup row would not survive the rollback the trigger's own Error causes.</summary>
page 60364 "CNH Confirm False"
{
    PageType = Card;
    SourceTable = "CNH Row";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = Administration;
    Extensible = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    var
        CnhQst: Label 'CNH question. Do you want to go there now?';
        OutcomeErr: Label 'CNH OUTCOME GuiAllowed=%1 Reply=%2', Comment = '%1 = Yes/No, %2 = Yes/No';

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Reply: Boolean;
        GuiInTrigger: Boolean;
    begin
        GuiInTrigger := GuiAllowed();
        Reply := Confirm(CnhQst, false);
        Error(OutcomeErr, Format(GuiInTrigger), Format(Reply));
    end;
}
