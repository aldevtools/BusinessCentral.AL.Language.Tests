// Cross-app fixture for al-runner issue 7358, the order rule, app D. See tests/al-language-xapp-a/R7358XaOrderRule.al.

reportextension 61166 "RPT Rule Ext 1" extends "RPT XA Order Rule"
{
    dataset
    {
        add(Head)
        {
            column(DCol; DValue) { }
        }
    }

    requestpage
    {
        layout
        {
            addafter(BaseOption)
            {
                field(DField; DFieldValue)
                {
                    ApplicationArea = All;
                    Caption = 'D field';
                }
            }
        }

        trigger OnOpenPage()
        begin
            Log.Add('D:rp open');
        end;

        trigger OnClosePage()
        begin
            Log.Add('D:rp close');
        end;
    }

    labels
    {
        DLabel = 'D';
    }

    trigger OnPreReport()
    begin
        DValue := 'D';
        Log.Add('D:pre');
    end;

    var
        Log: Codeunit "RPT XA Indep Log";
        DValue: Text;
        DFieldValue: Boolean;
}
