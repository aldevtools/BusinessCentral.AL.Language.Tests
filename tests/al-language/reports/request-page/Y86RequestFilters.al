// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-savevalues-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 94583, reports 94584-94585, test codeunit 94586
// Probe (writer Y86, al-runtime-rs assumptions report-procedure-filter-under-request-page, report-view-over-stored-request-filters and
// request-page-cancel-keeps-saved-filters): data item filters from a report procedure, from SetTableView and from the record of
// Report.RunModal, against what the request page shows and what a SaveValues page stored; an OK that stores a filter and a Cancel after it.
// BC versions: 27, 28, 29

table 94583 "LT Y86 Row"
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

report 94584 "LT Y86 Plain Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(RowDi; "LT Y86 Row")
        {
            RequestFilterFields = Code, Name;

            trigger OnPreDataItem()
            begin
                RunLog += 'pre[' + RowDi.GetFilters() + '];';
            end;

            trigger OnAfterGetRecord()
            begin
                RunLog += RowDi.Code + ',';
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Marker; Marker)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        RunLog: Text;
        Marker: Text[10];

    procedure SetCallerFilter(CodeFilter: Text)
    begin
        RowDi.SetFilter(Code, CodeFilter);
    end;

    procedure GetRunLog(): Text
    begin
        exit(RunLog);
    end;
}

report 94585 "LT Y86 Saved Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(RowDi; "LT Y86 Row")
        {
            RequestFilterFields = Code, Name;

            trigger OnPreDataItem()
            begin
                RunLog += 'pre[' + RowDi.GetFilters() + '];';
            end;

            trigger OnAfterGetRecord()
            begin
                RunLog += RowDi.Code + ',';
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                field(Marker; Marker)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        RunLog: Text;
        Marker: Text[10];

    procedure SetCallerFilter(CodeFilter: Text)
    begin
        RowDi.SetFilter(Code, CodeFilter);
    end;

    procedure GetRunLog(): Text
    begin
        exit(RunLog);
    end;

    procedure GetMarker(): Text
    begin
        exit(Marker);
    end;
}

codeunit 94586 "LT Y86 Filter Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Mode: Integer; // 0 read and Cancel, 1 read and OK, 2 set A* on Code and OK, 3 set B* on Code and Cancel, 4 clear Code and Cancel,
                       // 5 set Code B* and Marker 'm2' then Cancel, 6 set Code C* and OK, 7 clear Code filter and Marker and OK
        SeenCode: Text;
        SeenName: Text;
        SeenMarker: Text;

    local procedure Seed()
    begin
        Row('A1');
        Row('A2');
        Row('B1');
        Row('B2');
        Row('C1');
        Commit();
    end;

    local procedure Row(NewCode: Code[20])
    var
        R: Record "LT Y86 Row";
    begin
        if not R.Get(NewCode) then begin
            R.Code := NewCode;
            R.Insert();
        end;
    end;

    local procedure ObservePage(var Obs: Codeunit "Probe Observer"; Name: Text)
    begin
        Obs.Observe(Name + '|page', 'code=[' + SeenCode + '] name=[' + SeenName + '] marker=[' + SeenMarker + ']');
    end;

    // Clears what an earlier test stored in the SaveValues request page.
    local procedure ResetStored()
    var
        Rep: Report "LT Y86 Saved Report";
    begin
        Mode := 7;
        Rep.RunModal();
    end;

    // ---- report-procedure-filter-under-request-page (report without SaveValues)

    [Test]
    [HandlerFunctions('FilterHandler')]
    procedure Y86_ProcedureFilter_OkWithoutChange()
    var
        Obs: Codeunit "Probe Observer";
        Rep: Report "LT Y86 Plain Report";
    begin
        Seed();
        Rep.SetCallerFilter('B*');
        Mode := 1;
        Rep.RunModal();
        ObservePage(Obs, 'ok');
        Obs.Observe('ok|run', Rep.GetRunLog());
        Obs.Expect('ok|page', 'code=[] name=[] marker=[]');
        Obs.Expect('ok|run', 'pre[];A1,A2,B1,B2,C1,');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('FilterHandler')]
    procedure Y86_ProcedureFilter_HandlerSetsOtherAndOk()
    var
        Obs: Codeunit "Probe Observer";
        Rep: Report "LT Y86 Plain Report";
    begin
        Seed();
        Rep.SetCallerFilter('B*');
        Mode := 6;
        Rep.RunModal();
        ObservePage(Obs, 'set C*');
        Obs.Observe('set C*|run', Rep.GetRunLog());
        Obs.Expect('set C*|page', 'code=[] name=[] marker=[]');
        Obs.Expect('set C*|run', 'pre[Code: C*];C1,');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('FilterHandler')]
    procedure Y86_ProcedureFilter_HandlerClearsAndOk()
    var
        Obs: Codeunit "Probe Observer";
        Rep: Report "LT Y86 Plain Report";
    begin
        Seed();
        Rep.SetCallerFilter('B*');
        Mode := 8;
        Rep.RunModal();
        ObservePage(Obs, 'cleared');
        Obs.Observe('cleared|run', Rep.GetRunLog());
        Obs.Expect('cleared|page', 'code=[] name=[] marker=[]');
        Obs.Expect('cleared|run', 'pre[];A1,A2,B1,B2,C1,');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('FilterHandler')]
    procedure Y86_ProcedureFilter_Cancel()
    var
        Obs: Codeunit "Probe Observer";
        Rep: Report "LT Y86 Plain Report";
    begin
        Seed();
        Rep.SetCallerFilter('B*');
        Mode := 0;
        Rep.RunModal();
        ObservePage(Obs, 'cancel');
        Obs.Observe('cancel|run', Rep.GetRunLog());
        Obs.Expect('cancel|page', 'code=[] name=[] marker=[]');
        Obs.Expect('cancel|run', '');
        Obs.Verify();
    end;

    [Test]
    procedure Y86_ProcedureFilter_NoRequestPage()
    var
        Obs: Codeunit "Probe Observer";
        Rep: Report "LT Y86 Plain Report";
    begin
        Seed();
        Rep.SetCallerFilter('B*');
        Rep.UseRequestPage(false);
        Rep.RunModal();
        Obs.Observe('nopage|run', Rep.GetRunLog());
        Obs.Expect('nopage|run', 'pre[];A1,A2,B1,B2,C1,');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('FilterHandler')]
    procedure Y86_ProcedureFilter_TwoRunsOneVariable()
    var
        Obs: Codeunit "Probe Observer";
        Rep: Report "LT Y86 Plain Report";
    begin
        Seed();
        Rep.SetCallerFilter('B*');
        Mode := 1;
        Rep.RunModal();
        ObservePage(Obs, 'first');
        Mode := 1;
        asserterror Rep.RunModal();
        Obs.ObserveError('second run of the same variable');
        Obs.Observe('first|run', Rep.GetRunLog());
        Obs.Expect('first|page', 'code=[] name=[] marker=[]');
        Obs.Expect('second run of the same variable|text', 'The object has been run. Use the function CLEAR(Report).');
        Obs.Expect('second run of the same variable|code', 'ObjectHasAlreadyBeenRun');
        Obs.Expect('first|run', '');
        Obs.Verify();
    end;

    // ---- report-view-over-stored-request-filters (SaveValues)

    [Test]
    [HandlerFunctions('SavedHandler')]
    procedure Y86_StoredFilter_SetTableViewKeepsView()
    var
        Obs: Codeunit "Probe Observer";
        Rep: Report "LT Y86 Saved Report";
        Plain: Report "LT Y86 Saved Report";
        View: Record "LT Y86 Row";
    begin
        Seed();
        ResetStored();
        Mode := 2;
        Plain.RunModal();
        Obs.Observe('stored A*|run', Plain.GetRunLog());
        View.SetFilter(Code, 'C*');
        Rep.SetTableView(View);
        Mode := 1;
        Rep.RunModal();
        ObservePage(Obs, 'view C*');
        Obs.Observe('view C*|run', Rep.GetRunLog());
        Mode := 0;
        Clear(Plain);
        Plain.RunModal();
        ObservePage(Obs, 'plain after view');
        ResetStored();
        Obs.Expect('stored A*|run', 'pre[Code: A*];A1,A2,');
        Obs.Expect('view C*|page', 'code=[C*] name=[] marker=[]');
        Obs.Expect('view C*|run', 'pre[Code: C*];C1,');
        Obs.Expect('plain after view|page', 'code=[C*] name=[] marker=[]');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('SavedHandler')]
    procedure Y86_StoredFilter_RecordOfRunModalKeepsView()
    var
        Obs: Codeunit "Probe Observer";
        Plain: Report "LT Y86 Saved Report";
        View: Record "LT Y86 Row";
    begin
        Seed();
        ResetStored();
        Mode := 2;
        Plain.RunModal();
        View.SetFilter(Code, 'C*');
        Mode := 1;
        Report.RunModal(Report::"LT Y86 Saved Report", true, false, View);
        ObservePage(Obs, 'RunModal(id, true, false, C*)');
        Mode := 0;
        Clear(Plain);
        Plain.RunModal();
        ObservePage(Obs, 'plain after');
        ResetStored();
        Obs.Expect('RunModal(id, true, false, C*)|page', 'code=[C*] name=[] marker=[]');
        Obs.Expect('plain after|page', 'code=[C*] name=[] marker=[]');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('SavedHandler')]
    procedure Y86_StoredFilter_RecordOfRunKeepsView()
    var
        Obs: Codeunit "Probe Observer";
        Plain: Report "LT Y86 Saved Report";
        View: Record "LT Y86 Row";
    begin
        Seed();
        ResetStored();
        Mode := 2;
        Plain.RunModal();
        View.SetFilter(Code, 'B*');
        Mode := 1;
        Report.Run(Report::"LT Y86 Saved Report", true, false, View);
        ObservePage(Obs, 'Run(id, true, false, B*)');
        Mode := 0;
        Clear(Plain);
        Plain.RunModal();
        ObservePage(Obs, 'plain after');
        ResetStored();
        Obs.Expect('Run(id, true, false, B*)|page', 'code=[B*] name=[] marker=[]');
        Obs.Expect('plain after|page', 'code=[B*] name=[] marker=[]');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('SavedHandler')]
    procedure Y86_StoredFilter_ProcedureFilterVsStored()
    var
        Obs: Codeunit "Probe Observer";
        Rep: Report "LT Y86 Saved Report";
        Plain: Report "LT Y86 Saved Report";
    begin
        Seed();
        ResetStored();
        Mode := 2;
        Plain.RunModal();
        Rep.SetCallerFilter('C*');
        Mode := 1;
        Rep.RunModal();
        ObservePage(Obs, 'procedure C*');
        Obs.Observe('procedure C*|run', Rep.GetRunLog());
        ResetStored();
        Obs.Expect('procedure C*|page', 'code=[A*] name=[] marker=[]');
        Obs.Expect('procedure C*|run', 'pre[Code: A*];A1,A2,');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('SavedHandler')]
    procedure Y86_StoredFilter_ViewWithCancel()
    var
        Obs: Codeunit "Probe Observer";
        Rep: Report "LT Y86 Saved Report";
        Plain: Report "LT Y86 Saved Report";
        View: Record "LT Y86 Row";
    begin
        Seed();
        ResetStored();
        Mode := 2;
        Plain.RunModal();
        View.SetFilter(Code, 'C*');
        Rep.SetTableView(View);
        Mode := 0;
        Rep.RunModal();
        ObservePage(Obs, 'view C*, cancel');
        Clear(Plain);
        Mode := 0;
        Plain.RunModal();
        ObservePage(Obs, 'plain after cancel');
        ResetStored();
        Obs.Expect('view C*, cancel|page', 'code=[C*] name=[] marker=[]');
        Obs.Expect('plain after cancel|page', 'code=[A*] name=[] marker=[]');
        Obs.Verify();
    end;

    // ---- request-page-cancel-keeps-saved-filters

    [Test]
    [HandlerFunctions('SavedHandler')]
    procedure Y86_CancelKeeps_FilterChangedThenCancel()
    var
        Obs: Codeunit "Probe Observer";
        First: Report "LT Y86 Saved Report";
        Second: Report "LT Y86 Saved Report";
        Third: Report "LT Y86 Saved Report";
    begin
        Seed();
        ResetStored();
        Mode := 2;
        First.RunModal();
        Mode := 3;
        Second.RunModal();
        ObservePage(Obs, 'second (B* typed, cancel)');
        Mode := 1;
        Third.RunModal();
        ObservePage(Obs, 'third');
        Obs.Observe('third|run', Third.GetRunLog());
        ResetStored();
        Obs.Expect('second (B* typed, cancel)|page', 'code=[A*] name=[] marker=[]');
        Obs.Expect('third|page', 'code=[A*] name=[] marker=[]');
        Obs.Expect('third|run', 'pre[Code: A*];A1,A2,');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('SavedHandler')]
    procedure Y86_CancelKeeps_FilterClearedThenCancel()
    var
        Obs: Codeunit "Probe Observer";
        First: Report "LT Y86 Saved Report";
        Second: Report "LT Y86 Saved Report";
        Third: Report "LT Y86 Saved Report";
    begin
        Seed();
        ResetStored();
        Mode := 2;
        First.RunModal();
        Mode := 4;
        Second.RunModal();
        ObservePage(Obs, 'second (cleared, cancel)');
        Mode := 1;
        Third.RunModal();
        ObservePage(Obs, 'third');
        Obs.Observe('third|run', Third.GetRunLog());
        ResetStored();
        Obs.Expect('second (cleared, cancel)|page', 'code=[A*] name=[] marker=[]');
        Obs.Expect('third|page', 'code=[A*] name=[] marker=[]');
        Obs.Expect('third|run', 'pre[Code: A*];A1,A2,');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('SavedHandler')]
    procedure Y86_CancelKeeps_VariableAndFilterTogether()
    var
        Obs: Codeunit "Probe Observer";
        First: Report "LT Y86 Saved Report";
        Second: Report "LT Y86 Saved Report";
        Third: Report "LT Y86 Saved Report";
    begin
        Seed();
        ResetStored();
        Mode := 9;
        First.RunModal();
        Mode := 5;
        Second.RunModal();
        ObservePage(Obs, 'second (B*, m2, cancel)');
        Mode := 1;
        Third.RunModal();
        ObservePage(Obs, 'third');
        Obs.Observe('third|marker', Third.GetMarker());
        ResetStored();
        Obs.Expect('second (B*, m2, cancel)|page', 'code=[A*] name=[] marker=[m1]');
        Obs.Expect('third|page', 'code=[A*] name=[] marker=[m1]');
        Obs.Expect('third|marker', 'm1');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('SavedHandler')]
    procedure Y86_CancelKeeps_OkStoresTheChangeThatCancelDid_Not()
    var
        Obs: Codeunit "Probe Observer";
        First: Report "LT Y86 Saved Report";
        Second: Report "LT Y86 Saved Report";
        Third: Report "LT Y86 Saved Report";
    begin
        Seed();
        ResetStored();
        Mode := 2;
        First.RunModal();
        Mode := 6;
        Second.RunModal();
        ObservePage(Obs, 'second (C*, ok)');
        Mode := 1;
        Third.RunModal();
        ObservePage(Obs, 'third');
        ResetStored();
        Obs.Expect('second (C*, ok)|page', 'code=[A*] name=[] marker=[m1]');
        Obs.Expect('third|page', 'code=[C*] name=[] marker=[m1]');
        Obs.Verify();
    end;

    [RequestPageHandler]
    procedure FilterHandler(var RP: TestRequestPage "LT Y86 Plain Report")
    begin
        SeenCode := RP.RowDi.GetFilter(Code);
        SeenName := RP.RowDi.GetFilter(Name);
        SeenMarker := RP.Marker.Value();
        case Mode of
            0:
                RP.Cancel().Invoke();
            1:
                RP.OK().Invoke();
            2, 6:
                begin
                    if Mode = 2 then
                        RP.RowDi.SetFilter(Code, 'A*')
                    else
                        RP.RowDi.SetFilter(Code, 'C*');
                    RP.OK().Invoke();
                end;
            3:
                begin
                    RP.RowDi.SetFilter(Code, 'B*');
                    RP.Cancel().Invoke();
                end;
            4:
                begin
                    RP.RowDi.SetFilter(Code, '');
                    RP.Cancel().Invoke();
                end;
            5:
                begin
                    RP.RowDi.SetFilter(Code, 'B*');
                    RP.Marker.SetValue('m2');
                    RP.Cancel().Invoke();
                end;
            7, 8:
                begin
                    RP.RowDi.SetFilter(Code, '');
                    RP.RowDi.SetFilter(Name, '');
                    RP.OK().Invoke();
                end;
            9:
                begin
                    RP.RowDi.SetFilter(Code, 'A*');
                    RP.Marker.SetValue('m1');
                    RP.OK().Invoke();
                end;
        end;
    end;

    [RequestPageHandler]
    procedure SavedHandler(var RP: TestRequestPage "LT Y86 Saved Report")
    begin
        SeenCode := RP.RowDi.GetFilter(Code);
        SeenName := RP.RowDi.GetFilter(Name);
        SeenMarker := RP.Marker.Value();
        case Mode of
            0:
                RP.Cancel().Invoke();
            1:
                RP.OK().Invoke();
            2, 6:
                begin
                    if Mode = 2 then
                        RP.RowDi.SetFilter(Code, 'A*')
                    else
                        RP.RowDi.SetFilter(Code, 'C*');
                    RP.OK().Invoke();
                end;
            3:
                begin
                    RP.RowDi.SetFilter(Code, 'B*');
                    RP.Cancel().Invoke();
                end;
            4:
                begin
                    RP.RowDi.SetFilter(Code, '');
                    RP.Cancel().Invoke();
                end;
            5:
                begin
                    RP.RowDi.SetFilter(Code, 'B*');
                    RP.Marker.SetValue('m2');
                    RP.Cancel().Invoke();
                end;
            7, 8:
                begin
                    RP.RowDi.SetFilter(Code, '');
                    RP.RowDi.SetFilter(Name, '');
                    RP.OK().Invoke();
                end;
            9:
                begin
                    RP.RowDi.SetFilter(Code, 'A*');
                    RP.Marker.SetValue('m1');
                    RP.OK().Invoke();
                end;
        end;
    end;
}
