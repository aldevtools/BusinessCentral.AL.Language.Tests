// Cross-app fixtures of the WordXmlPart probe for al-runner issue 7358, app D (depends on A, not on B). See tests/al-language-xapp-a/WxXaObjects.al.

reportextension 61194 "LT WXP XD Report Ext" extends "LT WXP XA Report"
{
    dataset
    {
        add(Row)
        {
            column(AlphaD; Number) { }
        }
        addlast(Row)
        {
            dataitem(NestAD; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(NestADNum; Number) { }
            }
        }
    }

    labels
    {
        ALabelD = 'Label from D';
    }
}
