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

    trigger OnPreReport()
    begin
        EValue := 'E';
        Log.Add('E:pre');
    end;

    var
        Log: Codeunit "RPT XA Indep Log";
        EValue: Text;
}
