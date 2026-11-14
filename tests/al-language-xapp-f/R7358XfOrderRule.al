// Cross-app fixture for al-runner issue 7358, the order rule, app F. See tests/al-language-xapp-a/R7358XaOrderRule.al.

reportextension 61198 "RPT Rule Ext 2" extends "RPT XA Order Rule"
{
    dataset
    {
        add(Head)
        {
            column(FCol; FValue) { }
        }
    }

    requestpage
    {
        layout
        {
            addafter(BaseOption)
            {
                field(FField; FFieldValue)
                {
                    ApplicationArea = All;
                    Caption = 'F field';
                }
            }
        }

        trigger OnOpenPage()
        begin
            Log.Add('F:rp open');
        end;

        trigger OnClosePage()
        begin
            Log.Add('F:rp close');
        end;
    }

    labels
    {
        FLabel = 'F';
    }

    trigger OnPreReport()
    begin
        FValue := 'F';
        Log.Add('F:pre');
    end;

    var
        Log: Codeunit "RPT XA Indep Log";
        FValue: Text;
        FFieldValue: Boolean;
}
