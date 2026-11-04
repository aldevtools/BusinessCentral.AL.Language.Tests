// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-codecoveragelog-method
// Scope: in-scope
// Fixtures used: none (the table and its tableextension are declared in this file)
// Note: pins that a procedure declared in a TABLEEXTENSION, and the trigger and procedure of a
//       PAGEEXTENSION and a REPORTEXTENSION, run normally while code coverage is recording. The platform's recorder resolves the metadata of every object whose
//       method scope it enters, tableextensions included, so a call into an extension's
//       procedure must neither fail nor change the procedure's result.
//
//       Written for AlRunner#5384, where the runner answered "the TableExtension object with
//       the ID ... does not exist" for that call (the same for the other two kinds), and, because recording stayed on after the
//       failed test, for every later call into a tableextension procedure in the same
//       process. The second test pins that the recording state does not poison what runs next.
// BC versions: 24+

table 69960 "Cov Ext Table"
{
    fields
    {
        field(1; "No."; Code[20]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

tableextension 69961 "Cov Ext Table Ext" extends "Cov Ext Table"
{
    fields
    {
        field(69960; Extra; Integer) { }
    }

    procedure Twice(Value: Integer): Integer
    begin
        exit(Value * 2);
    end;
}

codeunit 69963 "Cov Ext Probe"
{
    SingleInstance = true;

    var
        Marker: Text;

    procedure Mark(Value: Text)
    begin
        Marker := Value;
    end;

    procedure Read(): Text
    begin
        exit(Marker);
    end;
}

page 69964 "Cov Ext Page"
{
    PageType = Card;
    SourceTable = "Cov Ext Table";
    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
        }
    }
}

pageextension 69965 "Cov Ext Page Ext" extends "Cov Ext Page"
{
    trigger OnOpenPage()
    begin
        MarkFromPageExtension('page-ext-ran');
    end;

    local procedure MarkFromPageExtension(Value: Text)
    var
        Probe: Codeunit "Cov Ext Probe";
    begin
        Probe.Mark(Value);
    end;
}

report 69966 "Cov Ext Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;
    dataset
    {
        dataitem(Item; Integer)
        {
            DataItemTableView = where(Number = const(1));
        }
    }
}

reportextension 69967 "Cov Ext Report Ext" extends "Cov Ext Report"
{
    trigger OnPreReport()
    begin
        MarkFromReportExtension('report-ext-ran');
    end;

    local procedure MarkFromReportExtension(Value: Text)
    var
        Probe: Codeunit "Cov Ext Probe";
    begin
        Probe.Mark(Value);
    end;
}

codeunit 69962 "Test Code Cov Table Extension"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure TableExtensionProcedure_WhileRecordingCoverage_ReturnsItsResult()
    var
        Rec: Record "Cov Ext Table";
        Result: Integer;
    begin
        // [GIVEN] code coverage is recording
        CodeCoverageLog(true, false);

        // [WHEN] a procedure declared in a tableextension is called
        Result := Rec.Twice(21);
        CodeCoverageLog(false, false);

        // [THEN] it runs and returns its own result
        Assert.AreEqual(42, Result, 'the tableextension procedure must run while recording.');
    end;

    [Test]
    procedure TableExtensionProcedure_AfterRecordingStopped_StillReturnsItsResult()
    var
        Rec: Record "Cov Ext Table";
    begin
        // [GIVEN] a recording that started and stopped around a tableextension call
        CodeCoverageLog(true, false);
        Assert.AreEqual(10, Rec.Twice(5), 'the tableextension procedure must run while recording.');
        CodeCoverageLog(false, false);

        // [WHEN] the procedure is called again with nothing recording
        // [THEN] it still returns its own result, with a different argument
        Assert.AreEqual(14, Rec.Twice(7), 'the tableextension procedure must run once recording has stopped.');
        Assert.IsFalse(CodeCoverageLog(), 'recording must be off after it was stopped.');
    end;

    local procedure HitCodeLines(var CodeCoverage: Record "Code Coverage"; ObjectId: Integer): Integer
    begin
        CodeCoverage.SetRange("Object ID", ObjectId);
        CodeCoverage.SetRange("Line Type", CodeCoverage."Line Type"::Code);
        CodeCoverage.SetFilter("No. of Hits", '>0');
        exit(CodeCoverage.Count());
    end;

    [Test]
    procedure PageExtensionTrigger_WhileRecordingCoverage_Runs()
    var
        Probe: Codeunit "Cov Ext Probe";
        CovPage: TestPage "Cov Ext Page";
    begin
        // [GIVEN] code coverage is recording
        Probe.Mark('');
        CodeCoverageLog(true, false);

        // [WHEN] a page opens whose pageextension has an OnOpenPage trigger calling a procedure
        CovPage.OpenView();
        CovPage.Close();
        CodeCoverageLog(false, false);

        // [THEN] the trigger and the procedure ran
        Assert.AreEqual('page-ext-ran', Probe.Read(), 'the pageextension trigger and procedure must run while recording.');
    end;

    [Test]
    procedure ReportExtensionTrigger_WhileRecordingCoverage_Runs()
    var
        Probe: Codeunit "Cov Ext Probe";
    begin
        // [GIVEN] code coverage is recording
        Probe.Mark('');
        CodeCoverageLog(true, false);

        // [WHEN] a report runs whose reportextension has an OnPreReport trigger calling a procedure
        Report.Run(Report::"Cov Ext Report");
        CodeCoverageLog(false, false);

        // [THEN] the trigger and the procedure ran
        Assert.AreEqual('report-ext-ran', Probe.Read(), 'the reportextension trigger and procedure must run while recording.');
    end;

    [Test]
    procedure TableExtensionProcedure_WhileRecordingCoverage_LeavesHitCodeLines()
    var
        Rec: Record "Cov Ext Table";
        CodeCoverage: Record "Code Coverage";
    begin
        CodeCoverageLog(true, false);
        Rec.Twice(21);
        CodeCoverageLog(false, false);

        CodeCoverage.SetRange("Object Type", CodeCoverage."Object Type"::TableExtension);
        Assert.IsTrue(HitCodeLines(CodeCoverage, 69961) > 0, 'the tableextension must have a Code line with hits.');
    end;

    [Test]
    procedure PageExtensionTrigger_WhileRecordingCoverage_LeavesHitCodeLines()
    var
        CodeCoverage: Record "Code Coverage";
        CovPage: TestPage "Cov Ext Page";
    begin
        CodeCoverageLog(true, false);
        CovPage.OpenView();
        CovPage.Close();
        CodeCoverageLog(false, false);

        CodeCoverage.SetRange("Object Type", CodeCoverage."Object Type"::PageExtension);
        Assert.IsTrue(HitCodeLines(CodeCoverage, 69965) > 0, 'the pageextension must have a Code line with hits.');
    end;

    [Test]
    procedure ReportExtensionTrigger_WhileRecordingCoverage_LeavesHitCodeLines()
    var
        CodeCoverage: Record "Code Coverage";
    begin
        CodeCoverageLog(true, false);
        Report.Run(Report::"Cov Ext Report");
        CodeCoverageLog(false, false);

        CodeCoverage.SetRange("Object Type", CodeCoverage."Object Type"::ReportExtension);
        Assert.IsTrue(HitCodeLines(CodeCoverage, 69967) > 0, 'the reportextension must have a Code line with hits.');
    end;
}
