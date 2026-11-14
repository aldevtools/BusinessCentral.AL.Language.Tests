// Cross-app fixture for al-runner issue 7358, the order rule, app E. See tests/al-language-xapp-a/R7358XaOrderRule.al.

reportextension 61195 "RPT Rule Ext 4" extends "RPT XA Order Rule"
{
    dataset
    {
        add(Head)
        {
            column(ECol; EValue) { }
        }
    }

    requestpage
    {
        layout
        {
            addafter(BaseOption)
            {
                field(EField; EFieldValue)
                {
                    ApplicationArea = All;
                    Caption = 'E field';
                }
            }
        }

        trigger OnOpenPage()
        begin
            Log.Add('E:rp open');
        end;

        trigger OnClosePage()
        begin
            Log.Add('E:rp close');
        end;
    }

    labels
    {
        ELabel = 'E';
    }

    trigger OnPreReport()
    begin
        EValue := 'E';
        Log.Add('E:pre');
    end;

    var
        Log: Codeunit "RPT XA Indep Log";
        EValue: Text;
        EFieldValue: Boolean;
}
