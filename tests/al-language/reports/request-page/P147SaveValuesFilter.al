// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-savevalues-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 70099, report 70111, test codeunit 70122
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// variable then sets a data item filter itself (procedure on the report, and SetTableView) and runs the request page: does it show the stored filter or the caller's?
// BC versions: 29 (27 and 28 by CI)

table 70099 "LT P147 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

report 70111 "LT P147 Saved Filter"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(RowDi; "LT P147 Row")
        {
            RequestFilterFields = Code, Name;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                field(Marker; MarkerTxt)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    procedure SetCallerFilter(CodeFilter: Text)
    begin
        RowDi.SetFilter(Code, CodeFilter);
    end;

    var
        MarkerTxt: Text[10];
}

codeunit 70122 "LT P147 SaveValues Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Mode: Integer; // 0 read and Cancel, 1 set 'A*' on Code and OK, 2 read and OK
        SeenCode: Text;
        SeenName: Text;

    local procedure ObserveSeen(var Observer: Codeunit "Probe Observer"; Name: Text)
    begin
        Observer.Observe(Name + ' code filter', '[' + SeenCode + ']');
        Observer.Observe(Name + ' name filter', '[' + SeenName + ']');
    end;

    local procedure Seed()
    var
        Rep: Report "LT P147 Saved Filter";
    begin
        Mode := 1;
        Rep.RunModal();
    end;

    [Test]
    [HandlerFunctions('SavedFilterHandler')]
    procedure P147_Filter_ProcedureFilterVsStored()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P147 Row";
        Plain: Report "LT P147 Saved Filter";
        Caller: Report "LT P147 Saved Filter";
        Caller2: Report "LT P147 Saved Filter";
    begin
        Row.DeleteAll();
        asserterror Seed();
        Observer.ObserveError('af97');

        Mode := 0;
        Plain.RunModal();
        ObserveSeen(Observer, 'plain after seed');

        Caller.SetCallerFilter('B*');
        Caller.RunModal();
        ObserveSeen(Observer, 'procedure filter B*');

        Caller2.SetCallerFilter('');
        Caller2.RunModal();
        ObserveSeen(Observer, 'procedure filter blank');
        Observer.Expect('af97|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('af97|code', 'DB:Ok');
        Observer.Expect('plain after seed code filter', '[]');
        Observer.Expect('plain after seed name filter', '[]');
        Observer.Expect('procedure filter B* code filter', '[]');
        Observer.Expect('procedure filter B* name filter', '[]');
        Observer.Expect('procedure filter blank code filter', '[]');
        Observer.Expect('procedure filter blank name filter', '[]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SavedFilterHandler')]
    procedure P147_Filter_SetTableViewVsStored()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P147 Row";
        View: Record "LT P147 Row";
        Caller: Report "LT P147 Saved Filter";
        Caller2: Report "LT P147 Saved Filter";
    begin
        Row.DeleteAll();
        asserterror Seed();
        Observer.ObserveError('af125');

        View.SetFilter(Code, 'C*');
        Caller.SetTableView(View);
        Mode := 2;
        Caller.RunModal();
        ObserveSeen(Observer, 'SetTableView C*, OK');

        Mode := 0;
        Caller2.RunModal();
        ObserveSeen(Observer, 'plain after OK on the SetTableView run');
        Observer.Expect('af125|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('af125|code', 'DB:Ok');
        Observer.Expect('SetTableView C*, OK code filter', '[C*]');
        Observer.Expect('SetTableView C*, OK name filter', '[]');
        Observer.Expect('plain after OK on the SetTableView run code filter', '[C*]');
        Observer.Expect('plain after OK on the SetTableView run name filter', '[]');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure SavedFilterHandler(var RequestPage: TestRequestPage "LT P147 Saved Filter")
    begin
        if Mode = 1 then begin
            RequestPage.RowDi.SetFilter(Code, 'A*');
            RequestPage.OK().Invoke();
        end else begin
            SeenCode := RequestPage.RowDi.GetFilter(Code);
            SeenName := RequestPage.RowDi.GetFilter(Name);
            if Mode = 2 then
                RequestPage.OK().Invoke()
            else
                RequestPage.Cancel().Invoke();
        end;
    end;
}
