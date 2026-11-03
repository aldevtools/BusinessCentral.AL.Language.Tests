// @expect AL0161 | 'RequestOptionsPage' is inaccessible due to its protection level
// CurrReport.RequestOptionsPage.Update(false) in a report trigger (OnPreReport), outside the request page. Inside the
// request page (control, action and request page triggers, a request page procedure) it compiles:
// tests/al-language/report/lt-request-options-page-access/RequestOptionsPageAccess.al. A report procedure: case 2514.
report 50000 "MNC Y55 ROP"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Int; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Direction; Direction)
                {
                    ApplicationArea = All;

                }
            }
        }

        actions
        {
            area(Processing)
            {
                action(Act)
                {
                    ApplicationArea = All;
                    Caption = 'Act';
                }
            }
        }

    }
    trigger OnPreReport()
    begin
        CurrReport.RequestOptionsPage.Update(false);
    end;
    var
        Direction: Option Export,Import;
}
