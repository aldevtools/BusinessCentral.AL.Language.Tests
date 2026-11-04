// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testfield-setvalue-method
// Scope: in-scope
// Fixture for the QZ_* test in codeunit "LT P146 Page Expr SetValue" (P146PageExprSetValue.al): page 87695.
// Facts: TestPage field SetValue, Value and Editable on controls of a page with no source table that are bound to an expression that is not a
//   variable: a procedure call (Decimal), an arithmetic expression over two variables and a text function over a variable; a variable for contrast.

page 87695 "LT QZ Expr NoSource"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Total; GetTotal()) { ApplicationArea = All; }
            field(SumCtl; ValA + ValB) { ApplicationArea = All; }
            field(UpperCtl; UpperCase(PlainText)) { ApplicationArea = All; }
            field(Plain; PlainText) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    begin
        ValA := 2;
        ValB := 3;
        PlainText := 'abc';
    end;

    var
        ValA: Integer;
        ValB: Integer;
        PlainText: Text;

    local procedure GetTotal(): Decimal
    begin
        exit(42);
    end;
}
