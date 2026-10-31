//sub:report
// Gap cycle 4, spec G4-06: a RequestPageHandler that returns without OK, Cancel or another close action, for shapes the
// base pins (report/W3ReportRequestPageRun.al:322-370, report/lt-report-requestpage/RptRequestPage.al:750-772) do not
// cover: a report variable's Run of a report that is not ProcessingOnly, a ProcessingOnly report with RequestFilterFields
// and SaveValues, a report run from another report's OnInitReport, what SaveValues stores after the implicit close,
// RunModal, RunRequestPage after a SetValue, RunModal with a record, an OnQueryClosePage that answers false, and
// RunRequestPage of a report that is not ProcessingOnly (with and without a layout).
// Every run goes through Codeunit.Run (LT Y42 Rq Runner), so an error is observed, not fatal.
// BC 27.5, 28.5 and 29.0 (Linux CI and Windows 27.5/28.5 alike): every shape closes the page with Cancel (OnQueryClosePage sees the
// handler's SetValue, then OnClosePage), the report does not run, no error; the Cancel close stores nothing for SaveValues;
// RunRequestPage returns '' and opens on the defaults, not on saved values. An OnQueryClosePage that answers false leaves the last
// error 'The page cannot be closed at this time.' (FormCloseNotAllowed) without failing the call, skips OnClosePage and RUNS the report.

table 92820 "LT Y42 Rq Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Code[10]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 92820 "LT Y42 Rq Log"
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

// Not ProcessingOnly, no layout, SaveValues.
report 92820 "LT Y42 Rq NotProc"
{
    ProcessingOnly = false;
    UsageCategory = None;

    dataset
    {
        dataitem(D; "LT Y42 Rq Row")
        {
            column(Id; Id) { }

            trigger OnPreDataItem()
            begin
                L.Add('D pre');
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
                field(TextCtl; TextVal) { ApplicationArea = All; }
                field(IntCtl; IntVal) { ApplicationArea = All; }
            }
        }

        trigger OnInit()
        begin
            L.Add('rp init text=' + TextVal);
            TextVal := 'init';
        end;

        trigger OnOpenPage()
        begin
            L.Add('rp open text=' + TextVal + ' flag=' + Format(Flag));
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            L.Add('rp qc ' + Format(CloseAction) + ' text=' + TextVal);
            exit(true);
        end;

        trigger OnClosePage()
        begin
            L.Add('rp close text=' + TextVal);
        end;
    }

    var
        L: Codeunit "LT Y42 Rq Log";
        TextVal: Text[30];
        IntVal: Integer;
        Flag: Boolean;

    procedure SetFlag()
    begin
        Flag := true;
        L.Add('set flag');
    end;

    trigger OnInitReport()
    begin
        L.Add('init');
    end;

    trigger OnPreReport()
    begin
        L.Add('pre text=' + TextVal + ' filter=[' + D.GetFilters() + ']');
    end;

    trigger OnPostReport()
    begin
        L.Add('post');
    end;
}

// ProcessingOnly, RequestFilterFields, SaveValues, a control hidden by OnOpenPage (the Batch Post shape).
report 92821 "LT Y42 Rq Proc"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(D; "LT Y42 Rq Row")
        {
            RequestFilterFields = Id, Grp;

            trigger OnPreDataItem()
            begin
                L.Add('D pre');
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
                field(TextCtl; TextVal) { ApplicationArea = All; }
                field(IntCtl; IntVal) { ApplicationArea = All; }
                field(HiddenCtl; HiddenVal) { ApplicationArea = All; Visible = ShowHidden; }
            }
        }

        trigger OnInit()
        begin
            L.Add('rp init text=' + TextVal);
            TextVal := 'init';
            ShowHidden := true;
        end;

        trigger OnOpenPage()
        begin
            ShowHidden := false;
            L.Add('rp open text=' + TextVal);
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            L.Add('rp qc ' + Format(CloseAction) + ' text=' + TextVal);
            exit(true);
        end;

        trigger OnClosePage()
        begin
            L.Add('rp close text=' + TextVal);
        end;
    }

    var
        L: Codeunit "LT Y42 Rq Log";
        TextVal: Text[30];
        IntVal: Integer;
        HiddenVal: Boolean;
        ShowHidden: Boolean;

    trigger OnInitReport()
    begin
        L.Add('init');
    end;

    trigger OnPreReport()
    begin
        L.Add('pre text=' + TextVal + ' filter=[' + D.GetFilters() + ']');
    end;

    trigger OnPostReport()
    begin
        L.Add('post');
    end;
}

// ProcessingOnly, no request page; OnInitReport runs a report variable of the not-ProcessingOnly report (the Balance Sheet shape).
report 92822 "LT Y42 Rq Wrapper"
{
    ProcessingOnly = true;
    UseRequestPage = false;
    UsageCategory = None;

    dataset
    {
        dataitem(W; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
        }
    }

    var
        L: Codeunit "LT Y42 Rq Log";

    trigger OnInitReport()
    var
        Rpt: Report "LT Y42 Rq NotProc";
    begin
        L.Add('wrapper init');
        Rpt.SetFlag();
        Rpt.Run();
        L.Add('wrapper after');
    end;

    trigger OnPreReport()
    begin
        L.Add('wrapper pre');
    end;
}

// ProcessingOnly, SaveValues, OnQueryClosePage answers false for Cancel.
report 92823 "LT Y42 Rq QcFalse"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(D; "LT Y42 Rq Row")
        {
            RequestFilterFields = Id;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                field(TextCtl; TextVal) { ApplicationArea = All; }
            }
        }

        trigger OnInit()
        begin
            TextVal := 'init';
        end;

        trigger OnOpenPage()
        begin
            L.Add('rp open text=' + TextVal);
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            L.Add('rp qc ' + Format(CloseAction) + ' text=' + TextVal);
            exit(CloseAction <> Action::Cancel);
        end;

        trigger OnClosePage()
        begin
            L.Add('rp close text=' + TextVal);
        end;
    }

    var
        L: Codeunit "LT Y42 Rq Log";
        TextVal: Text[30];

    trigger OnInitReport()
    begin
        L.Add('init');
    end;

    trigger OnPreReport()
    begin
        L.Add('pre text=' + TextVal);
    end;
}

// Not ProcessingOnly, no layout, two data items with RequestFilterFields (the Detailed Calculation shape, step 9).
report 92824 "LT Y42 Rq NotProc Two"
{
    ProcessingOnly = false;
    UsageCategory = None;

    dataset
    {
        dataitem(D; "LT Y42 Rq Row")
        {
            RequestFilterFields = Id;
            column(Id; Id) { }
        }
        dataitem(D2; "LT Y42 Rq Row")
        {
            RequestFilterFields = Grp;
            column(Grp; Grp) { }
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                field(TextCtl; TextVal) { ApplicationArea = All; }
            }
        }

        trigger OnInit()
        begin
            TextVal := 'init';
        end;

        trigger OnOpenPage()
        begin
            L.Add('rp open text=' + TextVal);
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            L.Add('rp qc ' + Format(CloseAction) + ' text=' + TextVal);
            exit(true);
        end;

        trigger OnClosePage()
        begin
            L.Add('rp close text=' + TextVal);
        end;
    }

    var
        L: Codeunit "LT Y42 Rq Log";
        TextVal: Text[30];

    trigger OnInitReport()
    begin
        L.Add('init');
    end;

    trigger OnPreReport()
    begin
        L.Add('pre text=' + TextVal);
    end;
}

// The same as "LT Y42 Rq NotProc Two" with an RDLC layout (step 9, second half).
report 92825 "LT Y42 Rq NotProc Layout"
{
    ProcessingOnly = false;
    UsageCategory = None;
    DefaultRenderingLayout = Y42RqLayout;

    dataset
    {
        dataitem(D; "LT Y42 Rq Row")
        {
            RequestFilterFields = Id;
            column(Id; Id) { }
        }
        dataitem(D2; "LT Y42 Rq Row")
        {
            RequestFilterFields = Grp;
            column(Grp; Grp) { }
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                field(TextCtl; TextVal) { ApplicationArea = All; }
            }
        }

        trigger OnInit()
        begin
            TextVal := 'init';
        end;

        trigger OnOpenPage()
        begin
            L.Add('rp open text=' + TextVal);
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            L.Add('rp qc ' + Format(CloseAction) + ' text=' + TextVal);
            exit(true);
        end;

        trigger OnClosePage()
        begin
            L.Add('rp close text=' + TextVal);
        end;
    }

    rendering
    {
        layout(Y42RqLayout)
        {
            Type = RDLC;
            LayoutFile = './Y42RqLeftOpenLayout.rdl';
        }
    }

    var
        L: Codeunit "LT Y42 Rq Log";
        TextVal: Text[30];

    trigger OnInitReport()
    begin
        L.Add('init');
    end;

    trigger OnPreReport()
    begin
        L.Add('pre text=' + TextVal);
    end;
}

// Runs one report call inside Codeunit.Run, so an error ends here and the test observes it.
codeunit 92821 "LT Y42 Rq Runner"
{
    var
        Kind: Integer;
        ReportId: Integer;
        Result: Text;

    procedure Prepare(NewKind: Integer; NewReportId: Integer)
    begin
        Kind := NewKind;
        ReportId := NewReportId;
        Result := '';
    end;

    procedure GetResult(): Text
    begin
        exit(Result);
    end;

    trigger OnRun()
    var
        NotProc: Report "LT Y42 Rq NotProc";
        Proc: Report "LT Y42 Rq Proc";
        Row: Record "LT Y42 Rq Row";
    begin
        case Kind of
            0:
                Report.Run(ReportId);
            1:
                Report.RunModal(ReportId);
            2:
                Result := Report.RunRequestPage(ReportId);
            3:
                NotProc.Run();
            4:
                Proc.Run();
            5:
                NotProc.RunModal();
            6:
                begin
                    Row.SetRange(Id, 2);
                    Report.RunModal(ReportId, true, false, Row);
                end;
        end;
    end;
}

codeunit 92822 "LT Y42 Rq Left Open"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT Y42 Rq Log";
        // 0: read and return (page left open); 1: SetValue 'typed' and return; 2: log the text and OK; 3: SetValue 'prime' and OK.
        HMode: Integer;

    local procedure Seed()
    var
        Row: Record "LT Y42 Rq Row";
        I: Integer;
    begin
        Row.DeleteAll();
        for I := 1 to 3 do begin
            Row.Id := I;
            Row.Grp := 'G' + Format(I);
            Row.Insert();
        end;
        Commit();
        L.Take();
    end;

    local procedure Exec(var Observer: Codeunit "Probe Observer"; Name: Text; Kind: Integer; ReportId: Integer)
    var
        Runner: Codeunit "LT Y42 Rq Runner";
        Ok: Boolean;
    begin
        ClearLastError();
        Runner.Prepare(Kind, ReportId);
        Ok := Runner.Run();
        Observer.Observe(Name + ' ok', Format(Ok));
        Observer.ObserveError(Name + ' error');
        Observer.Observe(Name + ' log', L.Take());
    end;

    local procedure ExecResult(var Observer: Codeunit "Probe Observer"; Name: Text; Kind: Integer; ReportId: Integer)
    var
        Runner: Codeunit "LT Y42 Rq Runner";
        Ok: Boolean;
    begin
        ClearLastError();
        Runner.Prepare(Kind, ReportId);
        Ok := Runner.Run();
        Observer.Observe(Name + ' ok', Format(Ok));
        Observer.ObserveError(Name + ' error');
        Observer.Observe(Name + ' log', L.Take());
        Observer.Observe(Name + ' result', Runner.GetResult());
    end;

    local procedure Rows(): Text
    var
        Row: Record "LT Y42 Rq Row";
    begin
        exit(Format(Row.Count()));
    end;

    // T1: a report variable's Run of a report that is not ProcessingOnly (the Account Schedule shape).
    [Test]
    [HandlerFunctions('NotProcHandler')]
    procedure RqOpen_ReportVar_NotProcessing_Run()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        HMode := 0;
        Exec(Observer, 'var run', 3, 0);
        Observer.Observe('rows', Rows());
        Observer.Expect('var run ok', 'Yes');
        Observer.Expect('var run error|text', '');
        Observer.Expect('var run error|code', '');
        Observer.Expect('var run log', 'init;rp init text=;rp open text=init flag=No;h text=init;rp qc Cancel text=init;rp close text=init;');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;

    // T2: a report variable's Run of a ProcessingOnly report with RequestFilterFields and SaveValues (the Batch Post shape).
    [Test]
    [HandlerFunctions('ProcHandler')]
    procedure RqOpen_ReportVar_ProcessingOnly_Run()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        HMode := 3;
        Exec(Observer, 'prime', 0, Report::"LT Y42 Rq Proc");
        HMode := 0;
        Exec(Observer, 'var run', 4, 0);
        Observer.Observe('rows', Rows());
        Observer.Expect('prime ok', 'Yes');
        Observer.Expect('prime error|text', '');
        Observer.Expect('prime error|code', '');
        Observer.Expect('prime log', 'init;rp init text=;rp open text=init;h text=init textvis=Yes hiddenvis=No;rp qc OK text=prime;rp close text=prime;pre text=prime filter=[];D pre;post;');
        Observer.Expect('var run ok', 'Yes');
        Observer.Expect('var run error|text', '');
        Observer.Expect('var run error|code', '');
        Observer.Expect('var run log', 'init;rp init text=;rp open text=prime;h text=prime textvis=Yes hiddenvis=No;rp qc Cancel text=prime;rp close text=prime;');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;

    // T3: Report.Run of a report whose OnInitReport runs a report variable of a not-ProcessingOnly report.
    [Test]
    [HandlerFunctions('NotProcHandler')]
    procedure RqOpen_Wrapper_ReportVarFromOnInitReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        HMode := 0;
        Exec(Observer, 'wrapper', 0, Report::"LT Y42 Rq Wrapper");
        Observer.Expect('wrapper ok', 'Yes');
        Observer.Expect('wrapper error|text', '');
        Observer.Expect('wrapper error|code', '');
        Observer.Expect('wrapper log', 'wrapper init;init;rp init text=;set flag;rp open text=init flag=Yes;h text=init;rp qc Cancel text=init;rp close text=init;wrapper after;wrapper pre;');
        Observer.Verify();
    end;

    // T4: RunModal by id and on a report variable.
    [Test]
    [HandlerFunctions('NotProcHandler')]
    procedure RqOpen_RunModal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        HMode := 0;
        Exec(Observer, 'runmodal id', 1, Report::"LT Y42 Rq NotProc");
        Exec(Observer, 'runmodal var', 5, 0);
        Observer.Expect('runmodal id ok', 'Yes');
        Observer.Expect('runmodal id error|text', '');
        Observer.Expect('runmodal id error|code', '');
        Observer.Expect('runmodal id log', 'init;rp init text=;rp open text=init flag=No;h text=init;rp qc Cancel text=init;rp close text=init;');
        Observer.Expect('runmodal var ok', 'Yes');
        Observer.Expect('runmodal var error|text', '');
        Observer.Expect('runmodal var error|code', '');
        Observer.Expect('runmodal var log', 'init;rp init text=;rp open text=init flag=No;h text=init;rp qc Cancel text=init;rp close text=init;');
        Observer.Verify();
    end;

    // T6: Report.RunModal(Id, true, false, Rec), the print path.
    [Test]
    [HandlerFunctions('NotProcHandler')]
    procedure RqOpen_RunModalWithRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        HMode := 0;
        Exec(Observer, 'runmodal rec', 6, Report::"LT Y42 Rq NotProc");
        Observer.Expect('runmodal rec ok', 'Yes');
        Observer.Expect('runmodal rec error|text', '');
        Observer.Expect('runmodal rec error|code', '');
        Observer.Expect('runmodal rec log', 'init;rp init text=;rp open text=init flag=No;h text=init;rp qc Cancel text=init;rp close text=init;');
        Observer.Verify();
    end;

    // T3 (SaveValues), not ProcessingOnly: a SetValue in a handler that leaves the page open, then the next run shows ...
    [Test]
    [HandlerFunctions('NotProcHandler')]
    procedure RqOpen_SaveValues_NextRunShows_NotProcessing()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        HMode := 1;
        Exec(Observer, 'set and leave', 0, Report::"LT Y42 Rq NotProc");
        HMode := 0;
        Exec(Observer, 'next run', 0, Report::"LT Y42 Rq NotProc");
        Observer.Expect('set and leave ok', 'Yes');
        Observer.Expect('set and leave error|text', '');
        Observer.Expect('set and leave error|code', '');
        Observer.Expect('set and leave log', 'init;rp init text=;rp open text=init flag=No;h text=init;rp qc Cancel text=typed;rp close text=typed;');
        Observer.Expect('next run ok', 'Yes');
        Observer.Expect('next run error|text', '');
        Observer.Expect('next run error|code', '');
        Observer.Expect('next run log', 'init;rp init text=;rp open text=init flag=No;h text=init;rp qc Cancel text=init;rp close text=init;');
        Observer.Verify();
    end;

    // T3 (SaveValues), ProcessingOnly.
    [Test]
    [HandlerFunctions('ProcHandler')]
    procedure RqOpen_SaveValues_NextRunShows_ProcessingOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        HMode := 3;
        Exec(Observer, 'prime', 0, Report::"LT Y42 Rq Proc");
        HMode := 1;
        Exec(Observer, 'set and leave', 0, Report::"LT Y42 Rq Proc");
        HMode := 2;
        Exec(Observer, 'next run', 0, Report::"LT Y42 Rq Proc");
        Observer.Expect('prime ok', 'Yes');
        Observer.Expect('prime error|text', '');
        Observer.Expect('prime error|code', '');
        Observer.Expect('prime log', 'init;rp init text=;rp open text=prime;h text=prime textvis=Yes hiddenvis=No;rp qc OK text=prime;rp close text=prime;pre text=prime filter=[];D pre;post;');
        Observer.Expect('set and leave ok', 'Yes');
        Observer.Expect('set and leave error|text', '');
        Observer.Expect('set and leave error|code', '');
        Observer.Expect('set and leave log', 'init;rp init text=;rp open text=prime;h text=prime textvis=Yes hiddenvis=No;rp qc Cancel text=typed;rp close text=typed;');
        Observer.Expect('next run ok', 'Yes');
        Observer.Expect('next run error|text', '');
        Observer.Expect('next run error|code', '');
        Observer.Expect('next run log', 'init;rp init text=;rp open text=prime;h text=prime textvis=Yes hiddenvis=No;rp qc OK text=prime;rp close text=prime;pre text=prime filter=[];D pre;post;');
        Observer.Verify();
    end;

    // T5: RunRequestPage on a SaveValues page with a SetValue, page left open: the returned text, and what the next run shows.
    [Test]
    [HandlerFunctions('ProcHandler')]
    procedure RqOpen_RunRequestPage_SetValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        HMode := 3;
        Exec(Observer, 'prime', 0, Report::"LT Y42 Rq Proc");
        HMode := 1;
        ExecResult(Observer, 'rrp', 2, Report::"LT Y42 Rq Proc");
        HMode := 2;
        Exec(Observer, 'next run', 0, Report::"LT Y42 Rq Proc");
        Observer.Expect('prime ok', 'Yes');
        Observer.Expect('prime error|text', '');
        Observer.Expect('prime error|code', '');
        Observer.Expect('prime log', 'init;rp init text=;rp open text=prime;h text=prime textvis=Yes hiddenvis=No;rp qc OK text=prime;rp close text=prime;pre text=prime filter=[];D pre;post;');
        Observer.Expect('rrp ok', 'Yes');
        Observer.Expect('rrp error|text', '');
        Observer.Expect('rrp error|code', '');
        Observer.Expect('rrp log', 'init;rp init text=;rp open text=init;h text=init textvis=Yes hiddenvis=No;rp qc Cancel text=typed;rp close text=typed;');
        Observer.Expect('rrp result', '');
        Observer.Expect('next run ok', 'Yes');
        Observer.Expect('next run error|text', '');
        Observer.Expect('next run error|code', '');
        Observer.Expect('next run log', 'init;rp init text=;rp open text=prime;h text=prime textvis=Yes hiddenvis=No;rp qc OK text=prime;rp close text=prime;pre text=prime filter=[];D pre;post;');
        Observer.Verify();
    end;

    // T7: OnQueryClosePage answers false when the page is left open.
    [Test]
    [HandlerFunctions('QcFalseHandler')]
    procedure RqOpen_QueryCloseAnswersFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        HMode := 0;
        Exec(Observer, 'run', 0, Report::"LT Y42 Rq QcFalse");
        HMode := 0;
        ExecResult(Observer, 'rrp', 2, Report::"LT Y42 Rq QcFalse");
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run error|text', 'The page cannot be closed at this time.');
        Observer.Expect('run error|code', 'FormCloseNotAllowed');
        Observer.Expect('run log', 'init;rp open text=init;h text=init;rp qc Cancel text=init;pre text=init;');
        Observer.Expect('rrp ok', 'Yes');
        Observer.Expect('rrp error|text', 'The page cannot be closed at this time.');
        Observer.Expect('rrp error|code', 'FormCloseNotAllowed');
        Observer.Expect('rrp log', 'init;rp open text=init;h text=init;rp qc Cancel text=init;pre text=init;');
        Observer.Expect('rrp result', '<?xml version="1.0" standalone="yes"?><ReportParameters name="LT Y42 Rq QcFalse" id="92823"><DataItems><DataItem name="D">VERSION(1) SORTING(Field1)</DataItem></DataItems></ReportParameters>');
        Observer.Verify();
    end;

    // T9: RunRequestPage of a report that is not ProcessingOnly, two data items with RequestFilterFields, no layout.
    [Test]
    [HandlerFunctions('NotProcTwoHandler')]
    procedure RqOpen_RunRequestPage_NotProcessing()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        HMode := 0;
        ExecResult(Observer, 'rrp', 2, Report::"LT Y42 Rq NotProc Two");
        Observer.Expect('rrp ok', 'Yes');
        Observer.Expect('rrp error|text', '');
        Observer.Expect('rrp error|code', '');
        Observer.Expect('rrp log', 'init;rp open text=init;h text=init;rp qc Cancel text=init;rp close text=init;');
        Observer.Expect('rrp result', '');
        Observer.Verify();
    end;

    // T9 with an RDLC layout.
    [Test]
    [HandlerFunctions('NotProcLayoutHandler')]
    procedure RqOpen_RunRequestPage_NotProcessing_Layout()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        HMode := 0;
        ExecResult(Observer, 'rrp', 2, Report::"LT Y42 Rq NotProc Layout");
        Observer.Expect('rrp ok', 'Yes');
        Observer.Expect('rrp error|text', '');
        Observer.Expect('rrp error|code', '');
        Observer.Expect('rrp log', 'init;rp open text=init;h text=init;rp qc Cancel text=init;rp close text=init;');
        Observer.Expect('rrp result', '');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure NotProcHandler(var RP: TestRequestPage "LT Y42 Rq NotProc")
    begin
        L.Add('h text=' + RP.TextCtl.Value());
        case HMode of
            1:
                RP.TextCtl.SetValue('typed');
            2:
                RP.OK().Invoke();
            3:
                begin
                    RP.TextCtl.SetValue('prime');
                    RP.OK().Invoke();
                end;
        end;
    end;

    [RequestPageHandler]
    procedure ProcHandler(var RP: TestRequestPage "LT Y42 Rq Proc")
    begin
        L.Add('h text=' + RP.TextCtl.Value() + ' textvis=' + Format(RP.TextCtl.Visible()) + ' hiddenvis=' + Format(RP.HiddenCtl.Visible()));
        case HMode of
            1:
                RP.TextCtl.SetValue('typed');
            2:
                RP.OK().Invoke();
            3:
                begin
                    RP.TextCtl.SetValue('prime');
                    RP.OK().Invoke();
                end;
        end;
    end;

    [RequestPageHandler]
    procedure QcFalseHandler(var RP: TestRequestPage "LT Y42 Rq QcFalse")
    begin
        L.Add('h text=' + RP.TextCtl.Value());
    end;

    [RequestPageHandler]
    procedure NotProcTwoHandler(var RP: TestRequestPage "LT Y42 Rq NotProc Two")
    begin
        L.Add('h text=' + RP.TextCtl.Value());
    end;

    [RequestPageHandler]
    procedure NotProcLayoutHandler(var RP: TestRequestPage "LT Y42 Rq NotProc Layout")
    begin
        L.Add('h text=' + RP.TextCtl.Value());
    end;
}
