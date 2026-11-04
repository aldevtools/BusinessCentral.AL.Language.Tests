// Fixture for TestPageOpenNewAfterGetCurrRecord.al (codeunit 60927).
//
// The shape of Base Application page 21 "Customer Card" (and 26 "Vendor Card", 30 "Item Card"):
// OnNewRecord only arms a flag, and it is OnAfterGetCurrRecord that acts on it — inserting the
// row from a template, copying it into Rec and calling CurrPage.Update(). So whether a page
// opened with OpenNew() runs OnAfterGetCurrRecord for its new record decides whether that page
// ever creates anything before the first field is typed.
page 60950 "ONG Card"
{
    PageType = Card;
    SourceTable = "ONG Row";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    var
        NewMode: Boolean;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Echo: Record "TRT Echo";
    begin
        Echo.Bump('ONG-NEWREC');
        NewMode := true;
    end;

    trigger OnAfterGetCurrRecord()
    var
        Echo: Record "TRT Echo";
    begin
        Echo.Bump('ONG-CURR');
        if NewMode then
            CreateFromTemplate();
    end;

    local procedure CreateFromTemplate()
    var
        Row: Record "ONG Row";
        Echo: Record "TRT Echo";
    begin
        NewMode := false;
        Echo.Bump('ONG-TEMPL');
        Row.Init();
        Row."No." := CopyStr('ONG-' + Format(Row.Count() + 1), 1, MaxStrLen(Row."No."));
        Row."Made By Template" := true;
        Row.Insert(true);
        Rec.Copy(Row);
        CurrPage.Update();
    end;
}
