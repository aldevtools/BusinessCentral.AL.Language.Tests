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

    trigger OnPreReport()
    begin
        FValue := 'F';
        Log.Add('F:pre');
    end;

    var
        Log: Codeunit "RPT XA Indep Log";
        FValue: Text;
}
