/// <summary>A card whose OnNewRecord raises Confirm(Question, TRUE) and then reports, in the
/// text of the error it raises, both what GuiAllowed() answers inside the trigger and what the
/// Confirm returned. The report travels in the error message on purpose: a test rolls back, so
/// a trace row written here would not survive for the caller to read.</summary>
page 60363 "CNH Confirm True"
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
        Reply := Confirm(CnhQst, true);
        Error(OutcomeErr, Format(GuiInTrigger), Format(Reply));
    end;
}
