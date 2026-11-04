// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-dataset
// Scope: in-scope
// Fixtures used: none
//
// A NESTED data item — the inner one must re-iterate for every outer row.

report 60538 "Test Report MultiDI Nested"
{
    ProcessingOnly = false;

    dataset
    {
        dataitem(Outer; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 2));
            column(OuterTag; 'OUTER-' + Format(Number)) { }

            dataitem(Inner; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 .. 3));
                column(InnerTag; 'INNER-' + Format(Number)) { }
            }
        }
    }
}
