// Cross-app fixtures for Report.WordXmlPart of a report changed by two reportextensions of apps that do not depend on each other
// (al-runner issue 7358). This app (A) owns the report. App B (depends on A, not on D) and app D (depends on A, not on B) each add
// columns, a nested data item and a label. Tests: tests/al-language/reports/WordXmlPartShapes.al.

report 94695 "LT WXP XA Report"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(BaseNum; Number) { }
        }
    }
}
