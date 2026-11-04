// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runobject-property
// Scope: in-scope
// Fixtures used: TPAROK Row (60550), TPAROK Log (60551), TPAROK Probe (60552),
//                TPAROK Host (60553), TPAROK Report (60554), TPAROK Silent Report (60555),
//                TPAROK Runner (60556), TPAROK XmlPort (60557), TPAROK Query (60558)
//
// Fixtures for "what does an action's RunObject do when it names something that is NOT a page".
//
// The RunObject property accepts five object kinds. The corpus already pins the page kind, in
// TestPageActionRunObject_Tests (codeunit 60455) and TestPageActionRunObjectNoHandler_Tests
// (codeunit 60285). The other four -- Report, Codeunit, XmlPort and Query -- have never been
// measured against a service tier, and they are not variations on the page case: BC's action
// builder dispatches each of them through a different entry point. So each gets its own target
// object here, and each target records its own execution where the test can read it.
//
// EVERY TARGET RECORDS ITSELF TWICE, for the same reason TPARONH Open Probe (60286) does. Some
// arms invoke inside an asserterror, and a refusal discards the uncommitted rows of the
// transaction it unwinds -- measured on all eight cloud legs while building that suite. So a
// missing log ROW on an arm that raised proves nothing. The SingleInstance probe is memory, not
// database, so no rollback reaches it, and every arm that has to distinguish "did not run" from
// "ran and was rolled back" reads the probe instead of the table.
//
// Written by agent stma-auto-32, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue 2943.

table 60550 "TPAROK Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Descr; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

// Separate from "TPAROK Row": a target runs WHILE the host page is open, and writing into the
// host's own source table mid-invoke would move the host's rowset under it.
table 60551 "TPAROK Log"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry"; Code[20]) { }
        field(2; Detail; Text[50]) { }
    }

    keys
    {
        key(PK; "Entry") { Clustered = true; }
    }
}

// The rollback-proof witness. See the note at the top of this file for why a log row is not
// enough on an arm that raises. Reset() is called from Initialize(), so every arm starts from
// a known state, and MarkSentinel/GetSentinel let an arm prove this probe's own state survived
// an error before trusting what the other getters report.
codeunit 60552 "TPAROK Probe"
{
    SingleInstance = true;

    var
        ReportRan: Boolean;
        ReportRowCount: Integer;
        RequestPageOpened: Boolean;
        CodeunitRan: Boolean;
        CodeunitRecSeen: Text[50];
        XmlPortRan: Boolean;
        Sentinel: Boolean;

    procedure Reset()
    begin
        ReportRan := false;
        ReportRowCount := 0;
        RequestPageOpened := false;
        CodeunitRan := false;
        CodeunitRecSeen := '';
        XmlPortRan := false;
        Sentinel := false;
    end;

    procedure MarkReportRan()
    begin
        ReportRan := true;
    end;

    procedure GetReportRan(): Boolean
    begin
        exit(ReportRan);
    end;

    procedure CountReportRow()
    begin
        ReportRowCount += 1;
    end;

    procedure GetReportRowCount(): Integer
    begin
        exit(ReportRowCount);
    end;

    procedure MarkRequestPageOpened()
    begin
        RequestPageOpened := true;
    end;

    procedure GetRequestPageOpened(): Boolean
    begin
        exit(RequestPageOpened);
    end;

    // The codeunit target records WHICH record it was handed, not merely that it ran. That is
    // the question the issue asks about a codeunit target: is it given the host's current row?
    procedure MarkCodeunitRan(CurrentDescr: Text[50])
    begin
        CodeunitRan := true;
        CodeunitRecSeen := CurrentDescr;
    end;

    procedure GetCodeunitRan(): Boolean
    begin
        exit(CodeunitRan);
    end;

    procedure GetCodeunitRecSeen(): Text[50]
    begin
        exit(CodeunitRecSeen);
    end;

    procedure MarkXmlPortRan()
    begin
        XmlPortRan := true;
    end;

    procedure GetXmlPortRan(): Boolean
    begin
        exit(XmlPortRan);
    end;

    procedure MarkSentinel()
    begin
        Sentinel := true;
    end;

    procedure GetSentinel(): Boolean
    begin
        exit(Sentinel);
    end;
}

// The report target. ProcessingOnly, so it has no rendering layout and its request page offers
// a plain OK -- the shape TestReportRunWithRequestPage (codeunit 60933) measured as the only
// confirmation a request page accepts when the report is ProcessingOnly.
//
// It records three separable things: that its request page opened, that its body started, and
// how many rows it iterated. An implementation that opened the request page and stopped is
// therefore distinguishable from one that ran the body, which is exactly the first open
// question in AL Runner issue 2943.
report 60554 "TPAROK Report"
{
    ProcessingOnly = true;
    UseRequestPage = true;
    Caption = 'TPAROK Report';

    dataset
    {
        dataitem(Row; "TPAROK Row")
        {
            trigger OnAfterGetRecord()
            var
                Probe: Codeunit "TPAROK Probe";
            begin
                Probe.CountReportRow();
            end;
        }
    }

    requestpage
    {
        layout
        {
        }

        actions
        {
        }

        trigger OnOpenPage()
        var
            Probe: Codeunit "TPAROK Probe";
        begin
            Probe.MarkRequestPageOpened();
        end;
    }

    trigger OnPreReport()
    var
        Log: Record "TPAROK Log";
        Probe: Codeunit "TPAROK Probe";
    begin
        Probe.MarkReportRan();

        Log.Init();
        Log.Entry := 'REPORT';
        Log.Detail := 'ran';
        if not Log.Insert() then
            Log.Modify();
    end;
}

// The same report with UseRequestPage = false. The issue asks whether a report with no request
// page differs from one with; two targets that differ ONLY in that property are what turns that
// into a testable claim instead of an assumption.
report 60555 "TPAROK Silent Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;
    Caption = 'TPAROK Silent Report';

    dataset
    {
        dataitem(Row; "TPAROK Row")
        {
            trigger OnAfterGetRecord()
            var
                Probe: Codeunit "TPAROK Probe";
            begin
                Probe.CountReportRow();
            end;
        }
    }

    trigger OnPreReport()
    var
        Log: Record "TPAROK Log";
        Probe: Codeunit "TPAROK Probe";
    begin
        Probe.MarkReportRan();

        Log.Init();
        Log.Entry := 'SILENT';
        Log.Detail := 'ran';
        if not Log.Insert() then
            Log.Modify();
    end;
}

// The codeunit target. TableNo is "TPAROK Row" so that OnRun has a Rec to read: that is how
// this suite finds out whether a codeunit RunObject is handed the host page's current record,
// which is the second open question in the issue.
codeunit 60556 "TPAROK Runner"
{
    TableNo = "TPAROK Row";

    trigger OnRun()
    var
        Log: Record "TPAROK Log";
        Probe: Codeunit "TPAROK Probe";
    begin
        Probe.MarkCodeunitRan(Rec.Descr);

        Log.Init();
        Log.Entry := 'CODEUNIT';
        Log.Detail := Rec.Descr;
        if not Log.Insert() then
            Log.Modify();
    end;
}

// The xmlport target. Direction = Export with no request page, so nothing is waiting on a
// stream that a test session cannot supply; the only thing it does is record that it ran.
xmlport 60557 "TPAROK XmlPort"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(RootNode)
        {
            tableelement(Row; "TPAROK Row")
            {
                fieldattribute(No; Row."No.") { }
                fieldattribute(Descr; Row.Descr) { }
            }
        }
    }

    trigger OnPreXmlPort()
    var
        Log: Record "TPAROK Log";
        Probe: Codeunit "TPAROK Probe";
    begin
        Probe.MarkXmlPortRan();

        Log.Init();
        Log.Entry := 'XMLPORT';
        Log.Detail := 'ran';
        if not Log.Insert() then
            Log.Modify();
    end;
}

// The query target. A query has no trigger of any kind, so nothing here can record its own
// execution -- which is itself part of the answer: "opening a query" from an action is a UI
// event with no AL surface behind it. The arm that invokes it asserts on what AL can observe.
query 60558 "TPAROK Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "TPAROK Row")
        {
            column(No; "No.") { }
            column(Descr; Descr) { }
        }
    }
}

page 60553 "TPAROK Host"
{
    PageType = List;
    SourceTable = "TPAROK Row";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Descr; Rec.Descr)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            // The four subjects. Each declares its effect; no AL runs on the host side.
            action(RunTheReport)
            {
                ApplicationArea = All;
                Caption = 'Run The Report';
                RunObject = Report "TPAROK Report";
            }

            action(RunTheSilentReport)
            {
                ApplicationArea = All;
                Caption = 'Run The Silent Report';
                RunObject = Report "TPAROK Silent Report";
            }

            action(RunTheCodeunit)
            {
                ApplicationArea = All;
                Caption = 'Run The Codeunit';
                RunObject = Codeunit "TPAROK Runner";
            }

            // The same codeunit target with RunPageOnRec declared alongside it. The issue asks
            // whether RunPageOnRec means anything for a codeunit target; two actions differing
            // only in that property are what makes the answer measurable rather than assumed.
            action(RunTheCodeunitOnRec)
            {
                ApplicationArea = All;
                Caption = 'Run The Codeunit On Rec';
                RunObject = Codeunit "TPAROK Runner";
                RunPageOnRec = true;
            }

            action(RunTheXmlPort)
            {
                ApplicationArea = All;
                Caption = 'Run The XmlPort';
                RunObject = XmlPort "TPAROK XmlPort";
            }

            action(RunTheQuery)
            {
                ApplicationArea = All;
                Caption = 'Run The Query';
                RunObject = Query "TPAROK Query";
            }

            // The control. The SAME report target, reached by an OnAction trigger calling
            // Report.Run instead of by a RunObject declaration. This is the only difference
            // between it and RunTheReport, so a run in which one behaves differently from the
            // other has isolated the declaration -- the same control shape TPARONH uses for
            // pages.
            action(RunTheReportViaTrigger)
            {
                ApplicationArea = All;
                Caption = 'Run The Report Via Trigger';

                trigger OnAction()
                begin
                    Report.Run(Report::"TPAROK Report");
                end;
            }
        }
    }
}
