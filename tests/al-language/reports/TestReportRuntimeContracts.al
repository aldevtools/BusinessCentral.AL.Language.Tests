// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-triggers
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-data-type
// Scope: in-scope
// Fixtures used: ALT Parent (60004), ALT Child (60005), ALT Universal (60000), ALTFixtureCleanup (60019),
//                shared Assert (60021); its own log codeunit 68177 "Probe Report Log";
//                self-contained reports 68170..68175 and codeunit 68176
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins the trigger order of a processing-only report (also for a data item with no rows), the effect of
// CurrReport.Skip, Break and Quit, that a filter set on a data item in OnPreReport is discarded while one
// set in OnPreDataItem works, what SetTableView does, how a report variable behaves after Run, RunModal
// and Execute, when the request page opens, and how a report takes part in the caller's transaction.
// BC versions: 27.5

codeunit 68177 "Probe Report Log"
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

report 68170 "Probe Rep Order"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Parent; "ALT Parent")
        {
            DataItemTableView = sorting("Entry No.");

            dataitem(Child; "ALT Child")
            {
                DataItemLink = "Parent Entry No." = field("Entry No.");

                trigger OnPreDataItem()
                begin
                    PageLog.Add('Child.OnPreDataItem(filters=' + Child.GetFilters() + ')');
                end;

                trigger OnAfterGetRecord()
                begin
                    PageLog.Add('Child.AGR(' + Format(Child."Entry No.") + ',filters=' + Child.GetFilters() + ')');
                end;

                trigger OnPostDataItem()
                begin
                    PageLog.Add('Child.OnPostDataItem');
                end;
            }

            trigger OnPreDataItem()
            begin
                PageLog.Add('Parent.OnPreDataItem(filters=' + Parent.GetFilters() + ')');
            end;

            trigger OnAfterGetRecord()
            begin
                PageLog.Add('Parent.AGR(' + Format(Parent."Entry No.") + ')');
                if (Mode = 'skip') and (Parent."Entry No." = 1) then
                    CurrReport.Skip();
                if (Mode = 'break') and (Parent."Entry No." = 2) then
                    CurrReport.Break();
                if (Mode = 'quitrow') and (Parent."Entry No." = 1) then
                    CurrReport.Quit();
            end;

            trigger OnPostDataItem()
            begin
                PageLog.Add('Parent.OnPostDataItem(childFilters=' + Child.GetFilters() + ')');
            end;
        }
        dataitem(Empty; "ALT Universal")
        {
            DataItemTableView = where("Entry No." = const(-12345));

            trigger OnPreDataItem()
            begin
                PageLog.Add('Empty.OnPreDataItem');
            end;

            trigger OnAfterGetRecord()
            begin
                PageLog.Add('Empty.AGR');
            end;

            trigger OnPostDataItem()
            begin
                PageLog.Add('Empty.OnPostDataItem');
            end;
        }
    }

    var
        PageLog: Codeunit "Probe Report Log";
        Mode: Text;
        Marker: Text;

    procedure SetMode(NewMode: Text)
    begin
        Mode := NewMode;
    end;

    procedure SetMarker(NewMarker: Text)
    begin
        Marker := NewMarker;
    end;

    procedure GetMarker(): Text
    begin
        exit(Marker);
    end;

    trigger OnInitReport()
    begin
        PageLog.Add('OnInitReport(marker=' + Marker + ')');
    end;

    trigger OnPreReport()
    begin
        PageLog.Add('OnPreReport(parentFilters=' + Parent.GetFilters() + ')');
        if Mode = 'quitpre' then
            CurrReport.Quit();
    end;

    trigger OnPostReport()
    begin
        PageLog.Add('OnPostReport');
    end;
}

report 68171 "Probe Rep Request"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Parent; "ALT Parent")
        {
        }
    }
}

report 68172 "Probe Rep No Request"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Parent; "ALT Parent")
        {
        }
    }
}

report 68173 "Probe Rep Narrow"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Parent; "ALT Parent")
        {
            trigger OnPreDataItem()
            begin
                PageLog.Add('OnPreDataItem(filters=' + Parent.GetFilters() + ')');
                if Where = 'predataitem' then
                    Parent.SetRange("Entry No.", 2);
            end;

            trigger OnAfterGetRecord()
            begin
                PageLog.Add('AGR(' + Format(Parent."Entry No.") + ')');
            end;
        }
    }

    var
        PageLog: Codeunit "Probe Report Log";
        Where: Text;

    procedure SetWhere(NewWhere: Text)
    begin
        Where := NewWhere;
    end;

    trigger OnPreReport()
    begin
        if Where = 'prereport' then
            Parent.SetRange("Entry No.", 2);
        PageLog.Add('OnPreReport(after=' + Parent.GetFilters() + ')');
    end;
}

report 68174 "Probe Rep Snapshot"
{
    ProcessingOnly = true;
    UseRequestPage = false;
    TransactionType = Snapshot;

    dataset
    {
        dataitem(Parent; "ALT Parent")
        {
        }
    }
}

report 68175 "Probe Rep Writer"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Parent; "ALT Parent")
        {
        }
    }

    var
        FailAfterWrite: Boolean;

    procedure SetFail(Fail: Boolean)
    begin
        FailAfterWrite := Fail;
    end;

    trigger OnPostReport()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 777;
        ALTUniversal.Insert();
        if FailAfterWrite then
            Error('report failed after write');
    end;
}

// Writer BP (corpus issue 664, microsoft/AL issues 6513 and 6572): UsageCategory values written in the wrong case (`none`,
// `ReportsandAnalysis`). They compile; publishing once failed with "There is an error in the XML document". The test runs both reports.
report 82564 "LT BP Usage Lower None"
{
    ProcessingOnly = true;
    UseRequestPage = false;
    UsageCategory = none;
    ApplicationArea = All;

    dataset
    {
        dataitem(I; Integer)
        {
            DataItemTableView = where(Number = const(1));

            trigger OnAfterGetRecord()
            begin
                PageLog.Add('lower none row ' + Format(Number));
            end;
        }
    }

    var
        PageLog: Codeunit "Probe Report Log";
}

report 82565 "LT BP Usage Mixed Case"
{
    ProcessingOnly = true;
    UseRequestPage = false;
    UsageCategory = ReportsandAnalysis;
    ApplicationArea = All;

    dataset
    {
        dataitem(I; Integer)
        {
            DataItemTableView = where(Number = const(1));

            trigger OnAfterGetRecord()
            begin
                PageLog.Add('mixed case row ' + Format(Number));
            end;
        }
    }

    var
        PageLog: Codeunit "Probe Report Log";
}
codeunit 68176 "Probe Report Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        PageLog: Codeunit "Probe Report Log";

    local procedure Initialize()
    var
        ALTParent: Record "ALT Parent";
        ALTChild: Record "ALT Child";
    begin
        Cleanup.Initialize();
        ALTParent.Init();
        ALTParent."Entry No." := 1;
        ALTParent.Insert();
        ALTParent."Entry No." := 2;
        ALTParent.Insert();
        ALTParent."Entry No." := 3;
        ALTParent.Insert();
        ALTChild.Init();
        ALTChild."Entry No." := 1;
        ALTChild."Parent Entry No." := 1;
        ALTChild.Insert();
        ALTChild."Entry No." := 2;
        ALTChild.Insert();
        ALTChild."Entry No." := 3;
        ALTChild."Parent Entry No." := 3;
        ALTChild.Insert();
        Commit();
        PageLog.Take();
    end;

    local procedure FullOrder(): Text
    begin
        exit('OnInitReport(marker=);OnPreReport(parentFilters=);Parent.OnPreDataItem(filters=);' +
            'Parent.AGR(1);Child.OnPreDataItem(filters=);Child.AGR(1,filters=);Child.AGR(2,filters=);Child.OnPostDataItem;' +
            'Parent.AGR(2);Child.OnPreDataItem(filters=);Child.OnPostDataItem;' +
            'Parent.AGR(3);Child.OnPreDataItem(filters=);Child.AGR(3,filters=);Child.OnPostDataItem;' +
            'Parent.OnPostDataItem(childFilters=);Empty.OnPreDataItem;Empty.OnPostDataItem;OnPostReport;');
    end;

    [Test]
    procedure Report_Run_TriggerOrder_ParentRowThenItsChildren_EmptyItemStillRunsPreAndPost()
    var
        Rep: Report "Probe Rep Order";
    begin
        Initialize();

        Rep.Run();
        Assert.AreEqual(FullOrder(), PageLog.Take(), 'instance Run');

        Report.Run(Report::"Probe Rep Order");
        Assert.AreEqual(FullOrder(), PageLog.Take(), 'static Run');
    end;

    [Test]
    procedure Report_Skip_SkipsTheChildrenOfThatRow_Break_EndsTheItemButNotTheReport()
    var
        Rep: Report "Probe Rep Order";
        Entries: Text;
    begin
        Initialize();

        Rep.SetMode('skip');
        Rep.Run();
        Entries := PageLog.Take();
        Assert.IsTrue(Entries.Contains('Parent.AGR(1);Parent.AGR(2);Child.OnPreDataItem'), 'row 1 has no child items: ' + Entries);
        Assert.IsTrue(Entries.EndsWith('Parent.OnPostDataItem(childFilters=);Empty.OnPreDataItem;Empty.OnPostDataItem;OnPostReport;'), 'the report goes on: ' + Entries);

        Clear(Rep);
        Rep.SetMode('break');
        Rep.Run();
        Assert.AreEqual('OnInitReport(marker=);OnPreReport(parentFilters=);Parent.OnPreDataItem(filters=);Parent.AGR(1);' +
            'Child.OnPreDataItem(filters=);Child.AGR(1,filters=);Child.AGR(2,filters=);Child.OnPostDataItem;' +
            'Parent.AGR(2);Parent.OnPostDataItem(childFilters=);Empty.OnPreDataItem;Empty.OnPostDataItem;OnPostReport;', PageLog.Take(),
            'Break in row 2 ends the item, OnPostDataItem and the later item still run');
    end;

    [Test]
    procedure Report_Quit_StopsEverything_OnPostReportDoesNotRun()
    var
        Rep: Report "Probe Rep Order";
    begin
        Initialize();

        Rep.SetMode('quitpre');
        Rep.Run();
        Assert.AreEqual('OnInitReport(marker=);OnPreReport(parentFilters=);', PageLog.Take(), 'Quit in OnPreReport');

        Clear(Rep);
        Rep.SetMode('quitrow');
        Rep.Run();
        Assert.AreEqual('OnInitReport(marker=);OnPreReport(parentFilters=);Parent.OnPreDataItem(filters=);Parent.AGR(1);', PageLog.Take(), 'Quit in OnAfterGetRecord');
    end;

    [Test]
    procedure Report_FilterSetInOnPreReport_IsDiscarded_FilterSetInOnPreDataItem_Works()
    var
        Rep: Report "Probe Rep Narrow";
    begin
        Initialize();

        Rep.SetWhere('prereport');
        Rep.Run();
        Assert.AreEqual('OnPreReport(after=Entry No.: 2);OnPreDataItem(filters=);AGR(1);AGR(2);AGR(3);', PageLog.Take(), 'SetRange in OnPreReport: all three rows run');

        Clear(Rep);
        Rep.SetWhere('predataitem');
        Rep.Run();
        Assert.AreEqual('OnPreReport(after=);OnPreDataItem(filters=);AGR(2);', PageLog.Take(), 'SetRange in OnPreDataItem: one row');
    end;

    [Test]
    procedure Report_SetTableView_IsInForceInOnPreReport_AndKept()
    var
        Rep: Report "Probe Rep Order";
        ALTParent: Record "ALT Parent";
        Entries: Text;
    begin
        Initialize();
        ALTParent.SetRange("Entry No.", 2, 3);
        Rep.SetTableView(ALTParent);

        Rep.Run();

        Entries := PageLog.Take();
        Assert.IsTrue(Entries.StartsWith('OnInitReport(marker=);OnPreReport(parentFilters=Entry No.: 2..3);Parent.OnPreDataItem(filters=Entry No.: 2..3);Parent.AGR(2);'), Entries);
        Assert.IsFalse(Entries.Contains('Parent.AGR(1)'), 'row 1 is filtered out');
    end;

    [Test]
    procedure Report_Run_ResetsTheGlobals_NotOnInitReport_RunTwiceIsAllowed_ExecuteTwiceThrows()
    var
        Rep: Report "Probe Rep Order";
        Other: Report "Probe Rep Order";
    begin
        Initialize();

        Rep.SetMarker('first');
        Rep.Run();
        Assert.AreEqual('', Rep.GetMarker(), 'after Run the globals are back to their defaults');
        PageLog.Take();
        Rep.Run();
        Assert.AreEqual(CopyStr(FullOrder(), StrLen('OnInitReport(marker=);') + 1), PageLog.Take(), 'a second Run on the same variable does not run OnInitReport again');

        Other.SetMarker('a');
        Other.Execute('');
        Assert.AreEqual('a', Other.GetMarker(), 'Execute keeps the globals');
        asserterror Other.Execute('');
        Assert.AreEqual('The object has been run. Use the function CLEAR(Report).', GetLastErrorText(), 'text');
    end;

    [Test]
    procedure Report_RequestPage_OpensUnlessSwitchedOff()
    var
        WithPage: Report "Probe Rep Request";
        WithoutPage: Report "Probe Rep No Request";
    begin
        Initialize();

        asserterror WithPage.Run();
        Assert.AreEqual('Unhandled UI: RequestPage 68171', GetLastErrorText(), 'a report with no UseRequestPage property opens its page, even without a requestpage section');
        Assert.AreEqual('MissingUIHandler', GetLastErrorCode(), 'code');

        asserterror Report.Run(Report::"Probe Rep Request");
        Assert.AreEqual('Unhandled UI: RequestPage 68171', GetLastErrorText(), 'static form');

        WithPage.UseRequestPage(false);
        WithPage.Run();

        Assert.IsFalse(WithoutPage.UseRequestPage(), 'the getter on a report declaring UseRequestPage = false');
        WithoutPage.UseRequestPage(true);
        Assert.IsTrue(WithoutPage.UseRequestPage(), 'after UseRequestPage(true)');
        asserterror WithoutPage.Run();
        Assert.AreEqual('Unhandled UI: RequestPage 68172', GetLastErrorText(), 'and the page opens');
    end;

    [Test]
    procedure Report_Run_JoinsTheCallersTransaction_AndAllowsAPendingWrite()
    var
        Rep: Report "Probe Rep Writer";
        ALTUniversal: Record "ALT Universal";
    begin
        Initialize();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 1;
        ALTUniversal.Insert();

        Rep.Run();

        ALTUniversal.SetRange("Entry No.", 777);
        Assert.AreEqual(1, ALTUniversal.Count(), 'the report wrote its row');
        Assert.IsTrue(Database.IsInWriteTransaction(), 'and nothing was committed: a write transaction is still open');
    end;

    [Test]
    procedure Report_ErrorAfterAWrite_RollsTheWriteBack_AndSnapshotTypeRuns()
    var
        Rep: Report "Probe Rep Writer";
        Snapshot: Report "Probe Rep Snapshot";
        ALTUniversal: Record "ALT Universal";
    begin
        Initialize();

        Rep.SetFail(true);
        asserterror Rep.Run();
        Assert.AreEqual('report failed after write', GetLastErrorText(), 'text');
        Assert.AreEqual('Dialog', GetLastErrorCode(), 'code');
        ALTUniversal.SetRange("Entry No.", 777);
        Assert.AreEqual(0, ALTUniversal.Count(), 'the write is rolled back');

        Snapshot.Run();
    end;

    [Test]
    procedure Report_RunInsideATryFunction_WithNoPendingWrite_Succeeds()
    begin
        Initialize();

        Assert.IsTrue(TryRunReport(), 'the TryFunction returns true');
    end;

    [TryFunction]
    local procedure TryRunReport()
    var
        Rep: Report "Probe Rep Order";
    begin
        Rep.Run();
    end;

    // Writer BP (corpus issue 664): the two reports with UsageCategory in the wrong case are published and run.
    [Test]
    procedure Report_UsageCategoryInWrongCase_PublishesAndRuns_BP()
    begin
        Initialize();
        Report.Run(Report::"LT BP Usage Lower None");
        Report.Run(Report::"LT BP Usage Mixed Case");
        Assert.AreEqual('lower none row 1;mixed case row 1;', PageLog.Take(), 'both reports ran their one row');
    end;
}
