// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
//
// The shape of Base Application page 9807 "User Card" together with its pageextension 9807
// "User Card Perf. Factboxes", reduced to the triggers that matter:
//   - DelayedInsert, with the key assigned in OnInsertRecord;
//   - the name field's OnValidate saves the new row with CurrPage.Update();
//   - OnAfterGetCurrRecord calls CurrPage.Update(false) on every row that becomes current,
//     including the unsaved new row OpenNew starts.
// OnAfterGetRecord records the name it sees, so the test can tell which rows it ran for.

page 60992 "ALT Page Update New Row Card"
{
    PageType = Card;
    SourceTable = "ALT Page Update New Row";
    DelayedInsert = true;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdField; Rec.Id)
            {
                ApplicationArea = All;
                Visible = false;
            }
            field(NameField; Rec.Name)
            {
                ApplicationArea = All;

                trigger OnValidate()
                begin
                    CurrPage.Update();
                end;
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec.Id := CreateGuid();
    end;

    trigger OnAfterGetRecord()
    begin
        Trace.Note('AGR:' + Rec.Name);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Trace.Note('AGCR');
        CurrPage.Update(false);
    end;

    var
        Trace: Codeunit "ALT Page Update New Row Trace";
}
