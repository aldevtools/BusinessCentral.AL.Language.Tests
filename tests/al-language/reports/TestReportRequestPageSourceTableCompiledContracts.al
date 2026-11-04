// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetable-property
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained table 68410, codeunit 68411 (log), reports 68412 and
//                68413, codeunit 68414 (tests)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins the Rec of a request page that declares SourceTable, for a report compiled from source
// (handlers/TestReportRequestPageSourceTable.al covers a precompiled Base Application report, whose
// OnOpenPage copies the filters itself):
//  - Rec starts unfiltered and holds every row of the table whatever record, table view or filters the
//    report was run with (Report.RunModal(Id, true, false, Rec), Report.SetTableView, RunRequestPage):
//    OnOpenPage sees no filters and all three rows; the data item gets the filter.
//  - A field control bound to Rec shows the first row of the table (not of the filter), whether OnOpenPage
//    calls FindFirst or the report has no OnOpenPage at all.
// BC versions: 27.5

table 68410 "Probe RPS Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 68411 "Probe RPS Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

report 68412 "Probe RPS Find First Report"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(T; "Probe RPS Table")
        {
            trigger OnPreDataItem()
            begin
                RpsLog.Add('PreDataItem filters=[' + T.GetFilters() + ']');
            end;
        }
    }

    requestpage
    {
        SourceTable = "Probe RPS Table";

        layout
        {
            area(Content)
            {
                field(TxtField; Rec.Txt) { ApplicationArea = All; }
            }
        }

        trigger OnOpenPage()
        begin
            RpsLog.Add('OnOpenPage filters=[' + Rec.GetFilters() + '] count=' + Format(Rec.Count()));
            Rec.FindFirst();
            RpsLog.Add('first id=' + Format(Rec.Id));
        end;
    }

    var
        RpsLog: Codeunit "Probe RPS Log";
}

report 68413 "Probe RPS Plain Report"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(T; "Probe RPS Table")
        {
        }
    }

    requestpage
    {
        SourceTable = "Probe RPS Table";

        layout
        {
            area(Content)
            {
                field(TxtField; Rec.Txt) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 68414 "Probe RPS Source Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        RpsLog: Codeunit "Probe RPS Log";
        Seen: Text;

    local procedure Seed()
    var
        RpsRec: Record "Probe RPS Table";
    begin
        RpsRec.DeleteAll();
        RpsRec.Id := 1;
        RpsRec.Txt := 'a';
        RpsRec.Insert();
        RpsRec.Id := 2;
        RpsRec.Txt := 'b';
        RpsRec.Insert();
        RpsRec.Id := 3;
        RpsRec.Txt := 'c';
        RpsRec.Insert();
        Commit();
        RpsLog.Take();
        Seen := '<not run>';
    end;

    [RequestPageHandler]
    procedure FindFirstHandler(var RP: TestRequestPage "Probe RPS Find First Report")
    begin
        Seen := RP.TxtField.Value();
        RP.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure PlainHandler(var RP: TestRequestPage "Probe RPS Plain Report")
    begin
        Seen := RP.TxtField.Value();
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('FindFirstHandler')]
    procedure RunModalWithARecord_RequestPageRecIsUnfiltered()
    var
        RpsRec: Record "Probe RPS Table";
    begin
        Seed();
        RpsRec.SetFilter(Id, '>=2');

        Report.RunModal(Report::"Probe RPS Find First Report", true, false, RpsRec);

        Assert.AreEqual('OnOpenPage filters=[] count=3;first id=1;PreDataItem filters=[Id: >=2];', RpsLog.Take(), 'log');
        Assert.AreEqual('a', Seen, 'field bound to Rec');
    end;

    [Test]
    [HandlerFunctions('FindFirstHandler')]
    procedure RunModalWithoutARecord_RequestPageRecIsUnfiltered()
    begin
        Seed();

        Report.RunModal(Report::"Probe RPS Find First Report", true, false);

        Assert.AreEqual('OnOpenPage filters=[] count=3;first id=1;PreDataItem filters=[];', RpsLog.Take(), 'log');
        Assert.AreEqual('a', Seen, 'field bound to Rec');
    end;

    [Test]
    [HandlerFunctions('FindFirstHandler')]
    procedure SetTableViewOnAnInstance_RequestPageRecIsUnfiltered()
    var
        RpsReport: Report "Probe RPS Find First Report";
        RpsRec: Record "Probe RPS Table";
    begin
        Seed();
        RpsRec.SetRange(Id, 3);
        RpsReport.SetTableView(RpsRec);
        RpsReport.UseRequestPage(true);

        RpsReport.RunModal();

        Assert.AreEqual('OnOpenPage filters=[] count=3;first id=1;PreDataItem filters=[Id: 3];', RpsLog.Take(), 'log');
        Assert.AreEqual('a', Seen, 'field bound to Rec');
    end;

    [Test]
    [HandlerFunctions('FindFirstHandler')]
    procedure RunRequestPage_RequestPageRecIsUnfiltered()
    var
        Parameters: Text;
    begin
        Seed();

        Parameters := Report.RunRequestPage(Report::"Probe RPS Find First Report");

        Assert.AreEqual('OnOpenPage filters=[] count=3;first id=1;', RpsLog.Take(), 'log');
        Assert.AreEqual('a', Seen, 'field bound to Rec');
        Assert.AreEqual('<?xml version="1.0" standalone="yes"?><ReportParameters name="Probe RPS Find First Report" id="68412"><DataItems><DataItem name="T">VERSION(1) SORTING(Field1)</DataItem></DataItems></ReportParameters>', Parameters, 'parameters');
    end;

    [Test]
    [HandlerFunctions('PlainHandler')]
    procedure WithoutAnOnOpenPage_TheBoundFieldShowsTheFirstRowOfTheTable()
    begin
        Seed();

        Report.RunModal(Report::"Probe RPS Plain Report", true, false);

        Assert.AreEqual('a', Seen, 'field bound to Rec: the first row of the table');
    end;
}
