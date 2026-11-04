// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-dataset
// Scope: in-scope
// Fixtures used: none
//
// Two SIBLING data items over the Integer virtual table — the shape that can produce nothing
// if a report's dataset only accounts for the first data item.

report 60537 "Test Report MultiDI Siblings"
{
    ProcessingOnly = false;

    dataset
    {
        dataitem(First; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 3));
            column(FirstTag; 'FIRST-' + Format(Number)) { }
        }
        dataitem(Second; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 2));
            column(SecondTag; 'SECOND-' + Format(Number)) { }
        }
    }
}
