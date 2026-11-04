// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Probe: written against BC 29 (observation only; the literals are measured later). Tag P91 (GitHub issue 91).
// BC versions: 29
// Fixtures used: tables and helper of P91Fix.al; SingleInstance log 71594 is used only by test codeunit 71610
// Facts: report instance members used from report triggers (CreateTotals, TotalsCausedBy, NewPage, ShowOutput, PrintOnlyIfDetail) and Run / RunModal on a report variable

codeunit 71594 "LT P91 Inst Log"
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

report 71595 "LT P91 Totals"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P91 Row")
        {
            trigger OnPreDataItem()
            begin
                TotVal := Row.Id;
                CurrReport.CreateTotals(TotVal);
                L.Add('pre showoutput=' + Format(CurrReport.ShowOutput));
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('row ' + Format(Row.Id) + ' tc=' + Format(CurrReport.TotalsCausedBy) + ' showoutput=' + Format(CurrReport.ShowOutput));
            end;

            trigger OnPostDataItem()
            begin
                L.Add('post tc=' + Format(CurrReport.TotalsCausedBy));
            end;
        }
    }

    trigger OnPreReport()
    begin
        L.Add('pre');
    end;

    trigger OnPostReport()
    begin
        L.Add('post');
    end;

    var
        L: Codeunit "LT P91 Inst Log";
        TotVal: Decimal;
}

report 71596 "LT P91 NewPage"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P91 Row")
        {
            trigger OnAfterGetRecord()
            begin
                CurrReport.NewPage();
                L.Add('row ' + Format(Row.Id) + ' pageno=' + Format(CurrReport.PageNo));
            end;
        }
    }

    trigger OnPreReport()
    begin
        L.Add('showoutput=' + Format(CurrReport.ShowOutput));
        L.Add('showoutput=' + Format(CurrReport.ShowOutput));
        L.Add('printonlyifdetail=' + Format(CurrReport.PrintOnlyIfDetail));
        CurrReport.PrintOnlyIfDetail := true;
        L.Add('printonlyifdetail=' + Format(CurrReport.PrintOnlyIfDetail));
        CurrReport.PrintOnlyIfDetail := false;
    end;

    var
        L: Codeunit "LT P91 Inst Log";
}

codeunit 71610 "LT P91 Inst Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT P91 Inst Log";
        Helper: Codeunit "LT P91 Helper";
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure Totals_RunViaVariable()
    var
        Rpt: Report "LT P91 Totals";
    begin
        Helper.Seed();
        L.Take();
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'pre;pre showoutput=No;row 1 tc=0 showoutput=No;row 2 tc=0 showoutput=No;row 3 tc=0 showoutput=No;row 4 tc=0 showoutput=No;post tc=0;post;');
        Observer.Verify();
    end;

    [Test]
    procedure Totals_RunModalViaVariable()
    var
        Rpt: Report "LT P91 Totals";
    begin
        Helper.Seed();
        L.Take();
        Rpt.RunModal();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'pre;pre showoutput=No;row 1 tc=0 showoutput=No;row 2 tc=0 showoutput=No;row 3 tc=0 showoutput=No;row 4 tc=0 showoutput=No;post tc=0;post;');
        Observer.Verify();
    end;

    [Test]
    procedure Totals_StaticRunAndRunModal()
    begin
        Helper.Seed();
        L.Take();
        Report.Run(Report::"LT P91 Totals");
        Observer.Observe('run', L.Take());
        Report.RunModal(Report::"LT P91 Totals");
        Observer.Observe('runmodal', L.Take());
        Observer.Expect('run', 'pre;pre showoutput=No;row 1 tc=0 showoutput=No;row 2 tc=0 showoutput=No;row 3 tc=0 showoutput=No;row 4 tc=0 showoutput=No;post tc=0;post;');
        Observer.Expect('runmodal', 'pre;pre showoutput=No;row 1 tc=0 showoutput=No;row 2 tc=0 showoutput=No;row 3 tc=0 showoutput=No;row 4 tc=0 showoutput=No;post tc=0;post;');
        Observer.Verify();
    end;

    [Test]
    procedure Totals_EmptyTable()
    var
        Row: Record "LT P91 Row";
    begin
        Helper.Seed();
        Row.DeleteAll();
        L.Take();
        Report.Run(Report::"LT P91 Totals");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'pre;pre showoutput=No;post tc=0;post;');
        Observer.Verify();
    end;

    [Test]
    procedure Totals_WithTableViewFilter()
    var
        Rpt: Report "LT P91 Totals";
        Row: Record "LT P91 Row";
    begin
        Helper.Seed();
        Row.SetRange(Grp, 2);
        L.Take();
        Rpt.SetTableView(Row);
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'pre;pre showoutput=No;row 3 tc=0 showoutput=No;row 4 tc=0 showoutput=No;post tc=0;post;');
        Observer.Verify();
    end;

    [Test]
    procedure NewPage_ShowOutput_PrintOnlyIfDetail()
    var
        Rpt: Report "LT P91 NewPage";
    begin
        Helper.Seed();
        L.Take();
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'showoutput=No;showoutput=No;printonlyifdetail=No;printonlyifdetail=Yes;row 1 pageno=1;row 2 pageno=1;row 3 pageno=1;row 4 pageno=1;');
        Observer.Verify();
    end;

    [Test]
    procedure NewPage_RunTwice_PageNoRestarts()
    var
        Rpt: Report "LT P91 NewPage";
    begin
        Helper.Seed();
        L.Take();
        Rpt.Run();
        Observer.Observe('first', L.Take());
        Rpt.Run();
        Observer.Observe('second', L.Take());
        Observer.Expect('first', 'showoutput=No;showoutput=No;printonlyifdetail=No;printonlyifdetail=Yes;row 1 pageno=1;row 2 pageno=1;row 3 pageno=1;row 4 pageno=1;');
        Observer.Expect('second', 'showoutput=No;showoutput=No;printonlyifdetail=No;printonlyifdetail=Yes;row 1 pageno=1;row 2 pageno=1;row 3 pageno=1;row 4 pageno=1;');
        Observer.Verify();
    end;
}
