// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-run-method
// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-runmodal-method
// Scope: in-scope
// Fixtures used: RRE Row (60866), RRE Log (60867), RRE ProcessingOnly Report (60868), RRE Layout Report (60869)
//
// Migrated from AL Runner tests/runner-extras/report-run-execution (RreTests.Codeunit.al).
//
// LEAVE-BEHIND: the source test method InstanceRun_NonProcessingOnly_ThrowsOutOfScopeForRendering
// is deliberately NOT migrated — it pins a runner-specific OutOfScope-throwing contract
// (no service tier to render with) and stays untouched in
// tests/runner-extras/report-run-execution as a runner-specific behaviour test. The
// "RRE Layout Report" object it used is still migrated below because
// InstanceSaveAsXml_ExecutesTriggersAndBody (kept) also uses it.
//
// StaticRun_ExecutesTriggersAndBody / StaticRunModal_ExecutesTriggersAndBody added
// separately: the STATIC forms — Report.Run(Report::X, ...) / Report.RunModal(Report::X, ...),
// called without ever declaring a report variable — execute the same trigger lifecycle
// (OnPreReport, per-row data item body) as the instance form. A static call hands back no
// report reference, so the outcome cannot be read off report globals the way
// InstanceSaveAsXml_ExecutesTriggersAndBody reads DidPreReportRun()/RowsProcessed(); it is
// observed through the "RRE Log" table instead — a table write is visible regardless of
// which (unreachable, in the static case) instance executed it, same reasoning
// TestReportSetTableView.al documents for the SetTableView suite.
//
/// <summary>
/// Control experiment for report EXECUTION entry points.
///
/// Observed while fixing the Integer virtual table: a probe report did not execute
/// at all through Report.Run() — OnPreReport never fired, nothing was raised and
/// nothing was written. That is a silent no-op, and it matters because a report
/// that never runs produces no PDF and raises no error.
///
/// That probe was ProcessingOnly with no rendering layout, so the no-op might have
/// been specific to that shape rather than general. These tests separate the
/// possibilities over a REAL table with REAL stored rows, so no virtual-table
/// provider is involved:
///
///   shape A (ProcessingOnly, no layout)  vs  shape B (layout, columns)
///   instance .SaveAs(Xml)  vs  static Report.SaveAs(Xml)
///
/// Each assertion names the entry point, so a fix cannot repair one path while
/// silently leaving another a no-op.
/// </summary>
codeunit 60870 "RRE Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        Row: Record "RRE Row";
        Log: Record "RRE Log";
    begin
        Row.DeleteAll();
        Log.DeleteAll();
        Row.Init();
        Row."Entry No." := 1;
        Row.Name := 'first';
        Row.Insert();
        Row.Init();
        Row."Entry No." := 2;
        Row.Name := 'second';
        Row.Insert();
        Row.Init();
        Row."Entry No." := 3;
        Row.Name := 'third';
        Row.Insert();
    end;

    // Count of "RRE Log" rows carrying the given marker — read after execution, since it
    // is the one channel a STATIC call (no report reference to read globals off) leaves
    // behind.
    local procedure LogMarkerCount(Marker: Text[50]): Integer
    var
        Log: Record "RRE Log";
    begin
        Log.SetRange(Marker, Marker);
        exit(Log.Count());
    end;

    [Test]
    procedure InstanceSaveAsXml_ExecutesTriggersAndBody()
    var
        Probe: Report "RRE Layout Report";
        TempBlob: Codeunit "Temp Blob";
        ResultOutStream: OutStream;
    begin
        // The dataset (Xml) path is in scope and is what a real consumer drives.
        Initialize();
        Clear(Probe);
        TempBlob.CreateOutStream(ResultOutStream);
        Probe.SaveAs('', ReportFormat::Xml, ResultOutStream);

        if not Probe.DidPreReportRun() then
            Error('instance SaveAs(Xml): OnPreReport never fired — the report did not execute at all.');
        if Probe.RowsProcessed() <> 3 then
            Error('instance SaveAs(Xml): expected 3 body executions, got %1', Probe.RowsProcessed());
    end;

    [Test]
    procedure StaticSaveAsXml_ProducesADatasetNamingTheRows()
    var
        TempBlob: Codeunit "Temp Blob";
        ResultOutStream: OutStream;
        ResultInStream: InStream;
        Dataset: Text;
        Line: Text;
    begin
        // The static form cannot report through report globals, so assert on the OUTPUT:
        // a dataset that actually names a seeded row proves the body ran.
        Initialize();
        TempBlob.CreateOutStream(ResultOutStream);
        Report.SaveAs(Report::"RRE Layout Report", '', ReportFormat::Xml, ResultOutStream);

        TempBlob.CreateInStream(ResultInStream);
        while not ResultInStream.EOS() do begin
            ResultInStream.ReadText(Line);
            Dataset += Line;
        end;

        if Dataset = '' then
            Error('Report.SaveAs(Xml) wrote an EMPTY stream — the report produced no dataset at all.');
        if StrPos(Dataset, 'second') = 0 then
            Error('Report.SaveAs(Xml) dataset does not contain the seeded row "second" — the data item body did not run. Dataset was: %1', CopyStr(Dataset, 1, 300));
    end;

    [Test]
    procedure StaticRun_ExecutesTriggersAndBody()
    begin
        // Static Report.Run(Report::X, RequestWindow, SystemPrinter) — no report variable is
        // ever declared, so there is nothing to Clear() and nothing to read a global off
        // afterwards. RequestWindow=false: shape A carries no request page, so this only
        // controls whether one would have been raised.
        Initialize();

        Report.Run(Report::"RRE ProcessingOnly Report", false, false);

        if LogMarkerCount('A-pre') <> 1 then
            Error('static Report.Run: OnPreReport never fired (or fired more than once) — expected 1 "A-pre" log entry, got %1.', LogMarkerCount('A-pre'));
        if LogMarkerCount('A-row') <> 3 then
            Error('static Report.Run: expected 3 data item body executions ("A-row" log entries), got %1 — the report did not iterate all seeded rows.', LogMarkerCount('A-row'));
    end;

    [Test]
    procedure StaticRunModal_ExecutesTriggersAndBody()
    begin
        // Same claim as StaticRun_ExecutesTriggersAndBody, for the RunModal entry point —
        // the one #1771 (AL Runner) reported as a silent no-op: no dataset iteration, no
        // OnPostReport, no error, quiet success.
        Initialize();

        Report.RunModal(Report::"RRE ProcessingOnly Report", false, false);

        if LogMarkerCount('A-pre') <> 1 then
            Error('static Report.RunModal: OnPreReport never fired (or fired more than once) — expected 1 "A-pre" log entry, got %1.', LogMarkerCount('A-pre'));
        if LogMarkerCount('A-row') <> 3 then
            Error('static Report.RunModal: expected 3 data item body executions ("A-row" log entries), got %1 — the report did not iterate all seeded rows.', LogMarkerCount('A-row'));
    end;
}
