// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-ext-object
// Scope: in-scope
// Fixtures used: Assert (60021), and the codeunit, reports and reportextensions declared below.
//
// CLAIM: a reportextension's report-level triggers and the data items it adds are part of the
// report it extends, however the report is run:
//   * its OnPreReport / OnPostReport run, each AFTER the base report's own trigger of that name;
//   * a child data item it adds (addlast) runs its OnPreDataItem, OnAfterGetRecord (once per
//     row) and OnPostDataItem, once for every row of its parent;
//   * a modify() of a base data item runs its OnBeforeAfterGetRecord before, and its
//     OnAfterAfterGetRecord after, the base data item's OnAfterGetRecord, row by row;
//   * the rows of an added data item, and a column added to a base data item, reach the
//     dataset Report.SaveAs(Xml) writes;
//   * an error raised in the extension's OnPreReport fails the run, on Report.Run and on
//     Report.SaveAs alike.
//
// Every trigger appends to a SingleInstance log, so each test asserts an exact sequence rather
// than "something ran".
//
// Written by agent stma-auto-5, an automated implementation agent acting on the account holder's
// behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4918.

codeunit 68000 "RXT Log"
{
    SingleInstance = true;

    var
        Entries: Dictionary of [Text, Text];
        FailExtPreReport: Boolean;

    procedure Reset()
    begin
        Clear(Entries);
        FailExtPreReport := false;
    end;

    procedure Add(Category: Text; Entry: Text)
    var
        Existing: Text;
    begin
        if Entries.Get(Category, Existing) then
            Entries.Set(Category, Existing + '|' + Entry)
        else
            Entries.Add(Category, Entry);
    end;

    procedure Read(Category: Text): Text
    var
        Existing: Text;
    begin
        if Entries.Get(Category, Existing) then
            exit(Existing);
        exit('');
    end;

    procedure SetFailExtPreReport(Fail: Boolean)
    begin
        FailExtPreReport := Fail;
    end;

    procedure ShouldFailExtPreReport(): Boolean
    begin
        exit(FailExtPreReport);
    end;
}

report 68000 "RXT Proc Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(BaseItem; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 2));

            trigger OnAfterGetRecord()
            begin
                Log.Add('Modify', 'base-' + Format(Number));
            end;
        }
    }

    trigger OnPreReport()
    begin
        Log.Add('Report', 'base-pre');
    end;

    trigger OnPostReport()
    begin
        Log.Add('Report', 'base-post');
    end;

    var
        Log: Codeunit "RXT Log";
}

reportextension 68000 "RXT Proc Report Ext" extends "RXT Proc Report"
{
    dataset
    {
        modify(BaseItem)
        {
            trigger OnBeforeAfterGetRecord()
            begin
                Log.Add('Modify', 'ext-before-' + Format(BaseItem.Number));
            end;

            trigger OnAfterAfterGetRecord()
            begin
                Log.Add('Modify', 'ext-after-' + Format(BaseItem.Number));
            end;
        }
        addlast(BaseItem)
        {
            dataitem(ExtItem; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 .. 3));

                trigger OnPreDataItem()
                begin
                    Log.Add('Added', 'pre');
                end;

                trigger OnAfterGetRecord()
                begin
                    Log.Add('Added', 'row-' + Format(Number));
                end;

                trigger OnPostDataItem()
                begin
                    Log.Add('Added', 'post');
                end;
            }
        }
    }

    trigger OnPreReport()
    begin
        Log.Add('Report', 'ext-pre');
        if Log.ShouldFailExtPreReport() then
            Error('RXT extension OnPreReport failed');
    end;

    trigger OnPostReport()
    begin
        Log.Add('Report', 'ext-post');
    end;

    var
        Log: Codeunit "RXT Log";
}

report 68001 "RXT Data Report"
{
    ProcessingOnly = false;

    dataset
    {
        dataitem(DataBaseItem; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 2));
            column(BaseTag; 'RXTBASE-' + Format(Number)) { }
        }
    }

    trigger OnPreReport()
    begin
        Log.Add('Data', 'base-pre');
    end;

    var
        Log: Codeunit "RXT Log";
}

reportextension 68001 "RXT Data Report Ext" extends "RXT Data Report"
{
    dataset
    {
        add(DataBaseItem)
        {
            column(AddedTag; 'RXTADDCOL-' + Format(DataBaseItem.Number)) { }
        }
        addlast(DataBaseItem)
        {
            dataitem(DataExtItem; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 .. 3));
                column(ExtTag; 'RXTEXT-' + Format(Number)) { }
            }
        }
    }

    trigger OnPreReport()
    begin
        Log.Add('Data', 'ext-pre');
        if Log.ShouldFailExtPreReport() then
            Error('RXT extension OnPreReport failed');
    end;

    var
        Log: Codeunit "RXT Log";
}

codeunit 68001 "RXT Report Extension Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Log: Codeunit "RXT Log";

    local procedure RenderXml(ReportId: Integer) Xml: Text
    var
        TempBlob: Codeunit "Temp Blob";
        DataOut: OutStream;
        DataIn: InStream;
        Line: Text;
    begin
        TempBlob.CreateOutStream(DataOut);
        Assert.IsTrue(Report.SaveAs(ReportId, '', ReportFormat::Xml, DataOut), 'Report.SaveAs(Xml) returned false');
        TempBlob.CreateInStream(DataIn);
        while not DataIn.EOS() do begin
            DataIn.ReadText(Line);
            Xml += Line;
        end;
    end;

    local procedure CountOccurrences(Haystack: Text; Needle: Text) Total: Integer
    var
        Pos: Integer;
    begin
        Pos := StrPos(Haystack, Needle);
        while Pos > 0 do begin
            Total += 1;
            Haystack := CopyStr(Haystack, Pos + StrLen(Needle));
            Pos := StrPos(Haystack, Needle);
        end;
    end;

    [Test]
    procedure ReportRun_ExtPreAndPostReport_RunAfterTheBaseTriggers()
    begin
        Log.Reset();
        Report.Run(Report::"RXT Proc Report", false);
        Assert.AreEqual('base-pre|ext-pre|base-post|ext-post', Log.Read('Report'),
            'the extension''s OnPreReport and OnPostReport must each run after the base report''s');
    end;

    [Test]
    procedure ReportRun_AddedDataItem_RunsItsTriggersOverItsRows()
    begin
        Log.Reset();
        Report.Run(Report::"RXT Proc Report", false);
        Assert.AreEqual('pre|row-1|row-2|row-3|post|pre|row-1|row-2|row-3|post', Log.Read('Added'),
            'the child data item the extension adds must run OnPreDataItem, OnAfterGetRecord per row, then OnPostDataItem, once per parent row');
    end;

    [Test]
    procedure ReportRun_ModifiedDataItem_ExtTriggersBracketTheBaseAfterGetRecord()
    begin
        Log.Reset();
        Report.Run(Report::"RXT Proc Report", false);
        Assert.AreEqual('ext-before-1|base-1|ext-after-1|ext-before-2|base-2|ext-after-2', Log.Read('Modify'),
            'modify() OnBeforeAfterGetRecord / OnAfterAfterGetRecord must bracket the base OnAfterGetRecord, row by row');
    end;

    [Test]
    procedure ReportRun_ExtPreReportError_FailsTheRun()
    begin
        Log.Reset();
        Log.SetFailExtPreReport(true);
        asserterror Report.Run(Report::"RXT Proc Report", false);
        Log.SetFailExtPreReport(false);
        Assert.ExpectedError('RXT extension OnPreReport failed');
        Assert.AreEqual('base-pre|ext-pre', Log.Read('Report'),
            'the run must stop at the extension''s OnPreReport, after the base one ran');
    end;

    [Test]
    procedure SaveAsXml_ExtensionRowsAndColumns_ReachTheDataset()
    var
        Xml: Text;
    begin
        Log.Reset();
        Xml := RenderXml(Report::"RXT Data Report");
        Assert.AreEqual(2, CountOccurrences(Xml, 'RXTBASE-'), 'rows of the base data item');
        Assert.AreEqual(2, CountOccurrences(Xml, 'RXTADDCOL-'), 'the column the extension adds to the base data item, once per base row');
        Assert.AreEqual(6, CountOccurrences(Xml, 'RXTEXT-'), 'rows of the child data item the extension adds: 3 per base row');
        Assert.AreEqual('base-pre|ext-pre', Log.Read('Data'),
            'Report.SaveAs must run the extension''s OnPreReport after the base report''s');
    end;

    [Test]
    procedure SaveAsXml_ExtPreReportError_FailsTheSave()
    var
        TempBlob: Codeunit "Temp Blob";
        DataOut: OutStream;
    begin
        Log.Reset();
        Log.SetFailExtPreReport(true);
        TempBlob.CreateOutStream(DataOut);
        asserterror Report.SaveAs(Report::"RXT Data Report", '', ReportFormat::Xml, DataOut);
        Log.SetFailExtPreReport(false);
        Assert.ExpectedError('RXT extension OnPreReport failed');
    end;
}
