// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autoformattype-property
// Scope: in-scope
// Fixtures used: ALT AutoFormat Row (60603)
//
// Five controls over the SAME Decimal field, differing only in how the page asks for it to be
// formatted. Pairing them on one field is what makes the suite a statement about the page-side
// formatting properties: the stored value is identical in every arm, so any difference between
// two controls' TestPage Value is attributable to the property and nothing else.
//
//   Plain      — AutoFormatType = 0, no DecimalPlaces: the control arm. Whatever BC does here
//                is the "no page-side formatting asked for" baseline every other arm is read
//                against.
//   Currency   — AutoFormatType = 1 with AutoFormatExpression = the row's currency code. This
//                is the route that reaches the platform's AutoFormat resolution (BC's
//                ALCompiler.InvokeAutoFormatTranslate → the AutoFormat system codeunit).
//   CurrBlank  — AutoFormatType = 1 with an AutoFormatExpression that evaluates to '' (the row
//                field is left empty). BC treats a blank expression under type 1 specially, so
//                this separates "type 1 was applied" from "the expression happened to be
//                honoured".
//   Custom     — AutoFormatType = 11, whose AutoFormatExpression is a literal format string
//                rather than a currency code. If the suite only had type 1, a platform that
//                ignored AutoFormatExpression entirely could still look right.
//   DecPlaces  — DecimalPlaces = 3 : 3 and no AutoFormatType at all. The sibling property in
//                BC's own formatting cascade; included so the suite says which of the two
//                properties a given control's output came from.

page 60604 "ALT AutoFormat Card"
{
    PageType = Card;
    SourceTable = "ALT AutoFormat Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }

                field(Plain; Rec.Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Plain';
                    AutoFormatType = 0;
                }

                field(Currency; Rec.Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Currency';
                    AutoFormatType = 1;
                    AutoFormatExpression = Rec."Currency Code";
                }

                field(CurrBlank; Rec.Amount)
                {
                    ApplicationArea = All;
                    Caption = 'CurrBlank';
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                }

                field(Custom; Rec.Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Custom';
                    AutoFormatType = 11;
                    AutoFormatExpression = '<Precision,3:3><Standard Format,0>';
                }

                field(DecPlaces; Rec.Amount)
                {
                    ApplicationArea = All;
                    Caption = 'DecPlaces';
                    DecimalPlaces = 3 : 3;
                }
            }
        }
    }
}
