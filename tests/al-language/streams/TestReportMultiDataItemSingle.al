// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-dataset
// Scope: in-scope
// Fixtures used: none
//
// The control: a single data item, which already works. Present so a regression in the
// simple case cannot hide behind the multi-data-item tests.

report 60539 "Test Report MultiDI Single"
{
    ProcessingOnly = false;

    dataset
    {
        dataitem(Only; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 3));
            column(OnlyTag; 'ONLY-' + Format(Number)) { }
        }
    }
}
