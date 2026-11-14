// Cross-app fixture for al-runner issue 7358, the order rule, app B. See tests/al-language-xapp-a/R7358XaOrderRule.al.

reportextension 61385 "RPT Rule Ext 3" extends "RPT XA Order Rule"
{
    dataset
    {
        add(Head)
        {
            column(BCol; BValue) { }
        }
    }

    requestpage
    {
        layout
        {
            addafter(BaseOption)
            {
                field(BField; BFieldValue)
                {
                    ApplicationArea = All;
                    Caption = 'B field';
                }
            }
        }

        trigger OnOpenPage()
        begin
            Log.Add('B:rp open');
        end;

        trigger OnClosePage()
        begin
            Log.Add('B:rp close');
        end;
    }

    labels
    {
        BLabel = 'B';
    }

    trigger OnPreReport()
    begin
        BValue := 'B';
        Log.Add('B:pre');
    end;

    var
        Log: Codeunit "RPT XA Indep Log";
        BValue: Text;
        BFieldValue: Boolean;
}
