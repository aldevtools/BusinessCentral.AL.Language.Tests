// Gap cycle 4, spec G4-10 (writer Y42): a ProcessingOnly report whose request page declares an empty `layout { }` (no Content
// area), as Base Application's "Remittance Advice - Journal". The reportextension that does addlast(Content) lives in
// tests/al-language/report/lt-y42-reportext-request-page/: that form compiles only across apps (same app: AL0270,
// tests/must-not-compile/cases/2525-reportext-addlast-content-empty-requestpage-same-app.al).
report 61101 "LT Y42 Xa Empty Rp"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
        }
    }

    requestpage
    {
        layout
        {
        }

        actions
        {
        }
    }
}
