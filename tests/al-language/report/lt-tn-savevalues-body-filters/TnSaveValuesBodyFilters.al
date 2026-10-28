// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-savevalues-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 89980-89981, report 89980, log codeunit 89980, test codeunit 89981
// Probe: observed on a BC 29.0 SaaS sandbox (hub test runner); other BC versions are checked by the corpus CI matrix (al-runner issue 6065).
// Facts: a report whose request page has SaveValues = true and two nested data items. The child data item's OnPreDataItem sets
// filters of its own (SetRange/SetFilter on fields that are not request filter fields). What the request page and OnPreReport of
// the next report instance see: (1) after a run whose body set filters, on a fresh variable; (2) after the user confirmed a filter
// with OK; (3) after an edit closed with Cancel; (4) after Clear(ReportVar), and on fresh variables in two test procedures;
// (5) on a second RunModal of the same variable (refused: the object has been run). Also what the report variable still holds after
// its run, and after a run whose request page was edited and then cancelled.
// BC versions: 27-29

table 89980 "LT TN SV Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 89981 "LT TN SV Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentCode; Code[10]) { }
        field(20; Code; Code[10]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 89980 "LT TN SV Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

report 89980 "LT TN SV Body Filters"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(ParentItem; "LT TN SV Parent")
        {
            RequestFilterFields = Code;

            dataitem(ChildItem; "LT TN SV Child")
            {
                RequestFilterFields = Code;

                trigger OnPreDataItem()
                begin
                    Log.Add('child before body=[' + ChildItem.GetFilters() + ']');
                    ChildItem.SetRange(ParentCode, 'P');
                    ChildItem.SetFilter(Id, '%1..%2', 1, 5);
                    BodyRan := true;
                end;
            }
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content) { }
        }
    }

    trigger OnPreReport()
    begin
        Log.Add('pre parent=[' + ParentItem.GetFilters() + '] child=[' + ChildItem.GetFilters() + ']');
    end;

    procedure State(): Text
    begin
        exit('ran=' + Format(BodyRan) + ' parent=[' + ParentItem.GetFilters() + '] child=[' + ChildItem.GetFilters() + ']');
    end;

    var
        Log: Codeunit "LT TN SV Log";
        BodyRan: Boolean;
}

codeunit 89981 "LT TN SV Body Filter Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT TN SV Log";
        Mode: Integer; // 0 clear both Code filters and OK, 1 set parent Code 'P' and OK, 2 set parent Code 'OTHER' and Cancel, 3 read and OK

    local procedure Seed()
    var
        Parent: Record "LT TN SV Parent";
        Child: Record "LT TN SV Child";
    begin
        Child.DeleteAll();
        Parent.DeleteAll();
        Parent.Code := 'P';
        Parent.Insert();
        // A report run with a write transaction open stops with "An error occurred and the transaction is stopped" (P147SaveValuesFilter.al).
        Commit();
        Log.Take();
    end;

    // Leaves the saved request page values with no filter, whatever the test before left there.
    local procedure ResetSaved()
    var
        Rep: Report "LT TN SV Body Filters";
    begin
        Mode := 0;
        Rep.RunModal();
        Log.Take();
    end;

    [Test]
    [HandlerFunctions('BodyFilterHandler')]
    procedure BodyFilters_TwoFreshVariables()
    var
        Observer: Codeunit "Probe Observer";
        First: Report "LT TN SV Body Filters";
        Second: Report "LT TN SV Body Filters";
    begin
        Seed();
        Mode := 0;
        First.RunModal();
        Observer.Observe('first run', Log.Take());
        Observer.Observe('first after run', First.State());
        Second.RunModal();
        Observer.Observe('second run', Log.Take());
        Observer.Observe('second after run', Second.State());
        Observer.Observe('first after second run', First.State());
        Observer.Expect('first run', 'page parent.code=[] child.code=[] child.parentcode=[] child.id=[];pre parent=[] child=[];child before body=[];');
        Observer.Expect('first after run', 'ran=Yes parent=[] child=[Id: 1..5, ParentCode: P]');
        Observer.Expect('second run', 'page parent.code=[] child.code=[] child.parentcode=[] child.id=[];pre parent=[] child=[];child before body=[];');
        Observer.Expect('second after run', 'ran=Yes parent=[] child=[Id: 1..5, ParentCode: P]');
        Observer.Expect('first after second run', 'ran=Yes parent=[] child=[Id: 1..5, ParentCode: P]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BodyFilterHandler')]
    procedure ConfirmedFilter_NextInstanceSeesIt()
    var
        Observer: Codeunit "Probe Observer";
        Confirm: Report "LT TN SV Body Filters";
        Next: Report "LT TN SV Body Filters";
    begin
        Seed();
        ResetSaved();
        Mode := 1;
        Confirm.RunModal();
        Observer.Observe('confirm run', Log.Take());
        Mode := 3;
        Next.RunModal();
        Observer.Observe('next run', Log.Take());
        ResetSaved();
        Observer.Expect('confirm run', 'page parent.code=[] child.code=[] child.parentcode=[] child.id=[];pre parent=[Code: P] child=[];child before body=[];');
        Observer.Expect('next run', 'page parent.code=[P] child.code=[] child.parentcode=[] child.id=[];pre parent=[Code: P] child=[];child before body=[];');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BodyFilterHandler')]
    procedure CancelledEdit_KeepsTheSavedFilter()
    var
        Observer: Codeunit "Probe Observer";
        Confirm: Report "LT TN SV Body Filters";
        Cancelled: Report "LT TN SV Body Filters";
        Last: Report "LT TN SV Body Filters";
    begin
        Seed();
        ResetSaved();
        Mode := 1;
        Confirm.RunModal();
        Log.Take();
        Mode := 2;
        Cancelled.RunModal();
        Observer.Observe('cancelled run', Log.Take());
        Observer.Observe('cancelled after run', Cancelled.State());
        Mode := 3;
        Last.RunModal();
        Observer.Observe('last run', Log.Take());
        ResetSaved();
        Observer.Expect('cancelled run', 'page parent.code=[P] child.code=[] child.parentcode=[] child.id=[];');
        Observer.Expect('cancelled after run', 'ran=No parent=[Code: OTHER] child=[]');
        Observer.Expect('last run', 'page parent.code=[P] child.code=[] child.parentcode=[] child.id=[];pre parent=[Code: P] child=[];child before body=[];');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BodyFilterHandler')]
    procedure ClearSameVariable_SecondRunSeesNoBodyFilter()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT TN SV Body Filters";
    begin
        Seed();
        Mode := 0;
        Rep.RunModal();
        Observer.Observe('first run', Log.Take());
        Clear(Rep);
        Observer.Observe('after Clear', Rep.State());
        Rep.RunModal();
        Observer.Observe('second run', Log.Take());
        Observer.Observe('second after run', Rep.State());
        Observer.Expect('first run', 'page parent.code=[] child.code=[] child.parentcode=[] child.id=[];pre parent=[] child=[];child before body=[];');
        Observer.Expect('after Clear', 'ran=No parent=[] child=[]');
        Observer.Expect('second run', 'page parent.code=[] child.code=[] child.parentcode=[] child.id=[];pre parent=[] child=[];child before body=[];');
        Observer.Expect('second after run', 'ran=Yes parent=[] child=[Id: 1..5, ParentCode: P]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BodyFilterHandler')]
    procedure RunModalTwice_SameVariable_SecondIsRefused()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT TN SV Body Filters";
    begin
        Seed();
        Mode := 0;
        Rep.RunModal();
        Observer.Observe('first run', Log.Take());
        asserterror Rep.RunModal();
        Observer.ObserveError('second RunModal');
        Observer.Observe('second run', Log.Take());
        Observer.Observe('after the refused run', Rep.State());
        Observer.Expect('first run', 'page parent.code=[] child.code=[] child.parentcode=[] child.id=[];pre parent=[] child=[];child before body=[];');
        Observer.Expect('second RunModal|text', 'The object has been run. Use the function CLEAR(Report).');
        Observer.Expect('second RunModal|code', 'ObjectHasAlreadyBeenRun');
        Observer.Expect('second run', '');
        Observer.Expect('after the refused run', 'ran=Yes parent=[] child=[Id: 1..5, ParentCode: P]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BodyFilterHandler')]
    procedure FreshVariable_1_FirstProcedure()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT TN SV Body Filters";
    begin
        Seed();
        Mode := 0;
        Rep.RunModal();
        Observer.Observe('run', Log.Take());
        Observer.Expect('run', 'page parent.code=[] child.code=[] child.parentcode=[] child.id=[];pre parent=[] child=[];child before body=[];');
        Observer.Verify();
    end;

    // Runs after FreshVariable_1_FirstProcedure: the body filters that run set are not seen here.
    [Test]
    [HandlerFunctions('BodyFilterHandler')]
    procedure FreshVariable_2_SecondProcedure()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT TN SV Body Filters";
    begin
        Seed();
        Mode := 0;
        Rep.RunModal();
        Observer.Observe('run', Log.Take());
        Observer.Expect('run', 'page parent.code=[] child.code=[] child.parentcode=[] child.id=[];pre parent=[] child=[];child before body=[];');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure BodyFilterHandler(var RP: TestRequestPage "LT TN SV Body Filters")
    begin
        Log.Add('page parent.code=[' + RP.ParentItem.GetFilter(Code) + '] child.code=[' + RP.ChildItem.GetFilter(Code) +
            '] child.parentcode=[' + RP.ChildItem.GetFilter(ParentCode) + '] child.id=[' + RP.ChildItem.GetFilter(Id) + ']');
        case Mode of
            0:
                begin
                    RP.ParentItem.SetFilter(Code, '');
                    RP.ChildItem.SetFilter(Code, '');
                    RP.OK().Invoke();
                end;
            1:
                begin
                    RP.ParentItem.SetFilter(Code, 'P');
                    RP.OK().Invoke();
                end;
            2:
                begin
                    RP.ParentItem.SetFilter(Code, 'OTHER');
                    RP.Cancel().Invoke();
                end;
            else
                RP.OK().Invoke();
        end;
    end;
}
