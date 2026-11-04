//sub:report
// Report Metadata, Report Data Items and Report Layout List (md:353, md:355, md:524).

report 67764 "W3 Meta Default"
{
    dataset
    {
        dataitem(Row; "W3 Row")
        {
            column(Id; Id) { }
        }
    }
}

report 67765 "W3 Meta Flags"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
        }
    }
}

report 67766 "W3 Meta Items"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(A; "W3 Row")
        {
            DataItemTableView = sorting(Name, Id) order(descending);
            RequestFilterFields = Id;

            dataitem(B; "W3 Child")
            {
                DataItemLink = ParentId = field(Id);
                DataItemTableView = where(Id = filter(1..9));
            }
        }
        dataitem(C; "W3 Row")
        {
            DataItemTableView = sorting(Name, Id);
        }
        dataitem(D; "W3 Row")
        {
            DataItemTableView = where(Id = const(7));
        }
        dataitem(E; "W3 Row")
        {
            DataItemTableView = where(Id = const(7), Flag = const(true));
        }
        dataitem(F; "W3 Marker")
        {
        }
    }
}

codeunit 67767 "W3 Meta Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Metadata_ReportWithNoFlagProperties()
    var
        Observer: Codeunit "Probe Observer";
        Meta: Record "Report Metadata";
    begin
        Observer.Observe('row exists', Format(Meta.Get(Report::"W3 Meta Default")));
        Observer.Observe('UseRequestPage', Format(Meta.UseRequestPage));
        Observer.Observe('ProcessingOnly', Format(Meta.ProcessingOnly));
        Observer.Observe('FirstDataItemTableID is the table', Format(Meta.FirstDataItemTableID = Database::"W3 Row"));
        Observer.Expect('row exists', 'Yes');
        Observer.Expect('UseRequestPage', 'Yes');
        Observer.Expect('ProcessingOnly', 'No');
        Observer.Expect('FirstDataItemTableID is the table', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Metadata_ReportWithBothFlagsSet()
    var
        Observer: Codeunit "Probe Observer";
        Meta: Record "Report Metadata";
    begin
        Observer.Observe('row exists', Format(Meta.Get(Report::"W3 Meta Flags")));
        Observer.Observe('UseRequestPage', Format(Meta.UseRequestPage));
        Observer.Observe('ProcessingOnly', Format(Meta.ProcessingOnly));
        Observer.Expect('row exists', 'Yes');
        Observer.Expect('UseRequestPage', 'No');
        Observer.Expect('ProcessingOnly', 'Yes');
        Observer.Verify();
    end;

    // md:353: Data Item ID against the position, Sorting Fields and Data Item Table View for every form above. The id is shown as id / 10 when it is a multiple of ten.
    // md:524: the Layout column of the Report Layout List for a built-in layout of the Base Application (report 1306 Standard Sales - Invoice).
}
