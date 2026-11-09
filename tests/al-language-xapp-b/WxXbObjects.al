// Cross-app fixtures of the WordXmlPart probe for al-runner issue 7358, app B (depends on A, not on D). See tests/al-language-xapp-a/WxXaObjects.al.

reportextension 95525 "LT WXP XB Report Ext" extends "LT WXP XA Report"
{
    dataset
    {
        add(Row)
        {
            column(ZetaB; Number) { }
        }
        addlast(Row)
        {
            dataitem(NestZB; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(NestZBNum; Number) { }
            }
        }
    }

    labels
    {
        ZLabelB = 'Label from B';
    }
}
