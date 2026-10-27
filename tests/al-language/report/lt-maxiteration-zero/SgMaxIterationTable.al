// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-maxiteration-property
// Scope: in-scope
// Fixtures used: table 71405 and log codeunit 71404 (MaxIterationZero.al); reports 89366-89369 (writer SG); tests SG_* in codeunit 71408
// Probe: MaxIteration > 0 on a table data item: how many rows it reads, which triggers run per row and around the item, where the record
// stands in OnPostDataItem, with CurrReport.Skip on a row, with a filter that leaves fewer rows than MaxIteration, with descending order,
// and with a child data item. Observed on the corpus CI matrix (27.5, 28.5, 29.0).
// BC versions: 27, 28, 29

report 89366 "LT SG MaxIter Table Two"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT MaxIterZero Row")
        {
            DataItemTableView = sorting(Id);
            MaxIteration = 2;

            trigger OnPreDataItem()
            begin
                L.Add('pre count ' + Format(Row.Count()));
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('row ' + Format(Row.Id));
            end;

            trigger OnPostDataItem()
            begin
                L.Add('post at ' + Format(Row.Id));
            end;
        }
    }

    trigger OnPostReport()
    begin
        L.Add('report post');
    end;

    var
        L: Codeunit "LT MaxIterZero Log";
}

report 89367 "LT SG MaxIter Table Skip"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT MaxIterZero Row")
        {
            DataItemTableView = sorting(Id);
            MaxIteration = 2;

            trigger OnAfterGetRecord()
            begin
                L.Add('row ' + Format(Row.Id));
                if Row.Id = 1 then
                    CurrReport.Skip();
                L.Add('kept ' + Format(Row.Id));
            end;

            trigger OnPostDataItem()
            begin
                L.Add('post');
            end;
        }
    }

    var
        L: Codeunit "LT MaxIterZero Log";
}

report 89368 "LT SG MaxIter Table Few Desc"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Few; "LT MaxIterZero Row")
        {
            DataItemTableView = sorting(Id) where(Id = filter(2 .. 3));
            MaxIteration = 10;

            trigger OnAfterGetRecord()
            begin
                L.Add('few ' + Format(Few.Id));
            end;
        }
        dataitem(Desc; "LT MaxIterZero Row")
        {
            DataItemTableView = sorting(Id) order(descending);
            MaxIteration = 2;

            trigger OnAfterGetRecord()
            begin
                L.Add('desc ' + Format(Desc.Id));
            end;
        }
    }

    var
        L: Codeunit "LT MaxIterZero Log";
}

report 89369 "LT SG MaxIter Table Child"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Parent; "LT MaxIterZero Row")
        {
            DataItemTableView = sorting(Id);
            MaxIteration = 2;

            trigger OnAfterGetRecord()
            begin
                L.Add('parent ' + Format(Parent.Id));
            end;

            dataitem(Child; "LT MaxIterZero Row")
            {
                DataItemTableView = sorting(Id);
                MaxIteration = 1;

                trigger OnAfterGetRecord()
                begin
                    L.Add('child ' + Format(Child.Id));
                end;
            }
        }
    }

    var
        L: Codeunit "LT MaxIterZero Log";
}
