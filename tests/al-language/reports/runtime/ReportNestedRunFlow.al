// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/reportinstance-skip-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); W3 Dataset (codeunit 67703); own table 96610, codeunit 96611, reports 96612-96613,
//   codeunit 96614.
// Probe: from the code-sweep issue al-runner 7621 (Skip, Break, Quit and UseRequestPage do not check which report asks; PrintOnlyIfDetail
//   after a nested run). Observation form: every test ends in Observer.Finish(), so its failure message holds BC's values.
// Area: report "Outer" runs and, in a trigger of its data item, either calls a procedure of a report variable "Inner" that is not running,
//   or runs "Inner" (a nested run). Observed:
//   - CurrReport.Skip, Break and Quit in a procedure of Inner, called from Outer's OnAfterGetRecord while Inner is not running;
//   - CurrReport.Quit in Inner's OnInitReport and in Inner's OnPreReport during a nested run: what Outer does next;
//   - UseRequestPage() read in Inner's OnPreReport (nested, Inner.UseRequestPage(false)) and in Outer's OnPreReport (Outer run with false);
//   - Outer's PrintOnlyIfDetail data item after a nested run of Inner (Inner's data item has PrintOnlyIfDetail = false).
//   Each case logs the triggers that ran and the rows Outer read, and for SaveAs the column lines of Outer's dataset.
// BC versions: 27.5, 28.5, 29.0 (to be measured by the corpus CI)

table 96610 "LT RNF Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 96611 "LT RNF Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        Mode: Text;

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

    procedure SetMode(NewMode: Text)
    begin
        Mode := NewMode;
    end;

    procedure GetMode(): Text
    begin
        exit(Mode);
    end;
}

report 96612 "LT RNF Outer"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT RNF Row")
        {
            PrintOnlyIfDetail = true;
            column(RowId; Id) { }

            dataitem(Detail; Integer)
            {
                column(DetailNo; Number) { }

                trigger OnPreDataItem()
                begin
                    // Row 1 has no detail row, row 2 and row 3 have one.
                    SetRange(Number, 1, Row.Id - 1);
                    if Row.Id > 1 then
                        SetRange(Number, 1, 1);
                end;
            }

            trigger OnAfterGetRecord()
            var
                Inner: Report "LT RNF Inner";
            begin
                Log.Add('outer row ' + Format(Id));
                if Id <> 2 then
                    exit;
                case Log.GetMode() of
                    'skip in other':
                        InnerVar.CallSkip();
                    'break in other':
                        InnerVar.CallBreak();
                    'quit in other':
                        InnerVar.CallQuit();
                    'nested quit init', 'nested quit pre', 'nested urp', 'nested run':
                        begin
                            Inner.UseRequestPage(false);
                            Inner.RunModal();
                            Log.Add('outer after nested');
                        end;
                end;
                Log.Add('outer row end ' + Format(Id));
            end;

            trigger OnPostDataItem()
            begin
                Log.Add('outer post item');
            end;
        }
    }

    trigger OnPreReport()
    begin
        Log.Add('outer pre urp=' + Format(CurrReport.UseRequestPage()));
    end;

    trigger OnPostReport()
    begin
        Log.Add('outer post report');
    end;

    var
        InnerVar: Report "LT RNF Inner";
        Log: Codeunit "LT RNF Log";
}

report 96613 "LT RNF Inner"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(IRow; "LT RNF Row")
        {
            PrintOnlyIfDetail = false;

            trigger OnAfterGetRecord()
            begin
                Log.Add('inner row ' + Format(Id));
            end;
        }
    }

    requestpage
    {
    }

    trigger OnInitReport()
    begin
        Log.Add('inner init');
        if Log.GetMode() = 'nested quit init' then
            CurrReport.Quit();
    end;

    trigger OnPreReport()
    begin
        Log.Add('inner pre urp=' + Format(CurrReport.UseRequestPage()));
        if Log.GetMode() = 'nested quit pre' then
            CurrReport.Quit();
    end;

    trigger OnPostReport()
    begin
        Log.Add('inner post report');
    end;

    var
        Log: Codeunit "LT RNF Log";

    procedure CallSkip()
    begin
        Log.Add('inner skip called');
        CurrReport.Skip();
    end;

    procedure CallBreak()
    begin
        Log.Add('inner break called');
        CurrReport.Break();
    end;

    procedure CallQuit()
    begin
        Log.Add('inner quit called');
        CurrReport.Quit();
    end;
}

codeunit 96614 "LT RNF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT RNF Log";

    local procedure SeedRows()
    var
        R: Record "LT RNF Row";
        I: Integer;
    begin
        R.DeleteAll();
        for I := 1 to 3 do begin
            R.Id := I;
            R.Insert();
        end;
    end;

    [TryFunction]
    local procedure TryRun()
    begin
        Report.Run(Report::"LT RNF Outer", false);
    end;

    local procedure RunCase(var Observer: Codeunit "Probe Observer"; Mode: Text)
    var
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
        Ok: Boolean;
    begin
        SeedRows();
        Log.SetMode(Mode);
        Log.Take();
        ClearLastError();
        Ok := TryRun();
        Observer.Observe(Mode + ' run ok', Format(Ok));
        if not Ok then
            Observer.ObserveError(Mode + ' run');
        Observer.Observe(Mode + ' run log', Log.Take());
        Ok := Dataset.Save(Report::"LT RNF Outer", '', Xml);
        Observer.Observe(Mode + ' saveas ok', Format(Ok));
        if not Ok then
            Observer.ObserveError(Mode + ' saveas');
        Observer.Observe(Mode + ' saveas log', Log.Take());
        if Ok then
            Observer.Observe(Mode + ' columns', Dataset.ColumnLines(Xml));
        Log.SetMode('');
    end;

    [Test]
    procedure RNF_SkipBreakQuit_InAProcedureOfAnotherReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'skip in other');
        RunCase(Observer, 'break in other');
        RunCase(Observer, 'quit in other');
        Observer.Expect('skip in other run ok', 'No');
        Observer.Expect('skip in other run|text', 'Report 96612 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('skip in other run|code', 'ReportNoLayout');
        Observer.Expect('skip in other run log', '');
        Observer.Expect('skip in other saveas ok', 'Yes');
        Observer.Expect('skip in other saveas log', 'outer pre urp=No;outer row 1;outer row 2;inner init;inner skip called;outer row 3;outer post item;outer post report;');
        Observer.Expect('skip in other columns', '<Column name="RowId">3</Column>|<Column name="DetailNo">1</Column>|');
        Observer.Expect('break in other run ok', 'No');
        Observer.Expect('break in other run|text', 'Report 96612 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('break in other run|code', 'ReportNoLayout');
        Observer.Expect('break in other run log', '');
        Observer.Expect('break in other saveas ok', 'Yes');
        Observer.Expect('break in other saveas log', 'outer pre urp=No;outer row 1;outer row 2;inner init;inner break called;outer post item;outer post report;');
        Observer.Expect('break in other columns', '');
        Observer.Expect('quit in other run ok', 'No');
        Observer.Expect('quit in other run|text', 'Report 96612 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('quit in other run|code', 'ReportNoLayout');
        Observer.Expect('quit in other run log', '');
        Observer.Expect('quit in other saveas ok', 'No');
        Observer.Expect('quit in other saveas|text', '');
        Observer.Expect('quit in other saveas|code', '');
        Observer.Expect('quit in other saveas log', 'outer pre urp=No;outer row 1;outer row 2;inner init;inner quit called;');
        Observer.Verify();
    end;

    [Test]
    procedure RNF_NestedRun_QuitInInnerTriggers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'nested quit init');
        RunCase(Observer, 'nested quit pre');
        Observer.Expect('nested quit init run ok', 'No');
        Observer.Expect('nested quit init run|text', 'Report 96612 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('nested quit init run|code', 'ReportNoLayout');
        Observer.Expect('nested quit init run log', '');
        Observer.Expect('nested quit init saveas ok', 'Yes');
        Observer.Expect('nested quit init saveas log', 'outer pre urp=No;outer row 1;outer row 2;inner init;outer after nested;outer row end 2;outer row 3;outer post item;outer post report;');
        Observer.Expect('nested quit init columns', '<Column name="RowId">2</Column>|<Column name="DetailNo">1</Column>|<Column name="RowId">3</Column>|<Column name="DetailNo">1</Column>|');
        Observer.Expect('nested quit pre run ok', 'No');
        Observer.Expect('nested quit pre run|text', 'Report 96612 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('nested quit pre run|code', 'ReportNoLayout');
        Observer.Expect('nested quit pre run log', '');
        Observer.Expect('nested quit pre saveas ok', 'Yes');
        Observer.Expect('nested quit pre saveas log', 'outer pre urp=No;outer row 1;outer row 2;inner init;inner pre urp=No;outer after nested;outer row end 2;outer row 3;outer post item;outer post report;');
        Observer.Expect('nested quit pre columns', '<Column name="RowId">2</Column>|<Column name="DetailNo">1</Column>|<Column name="RowId">3</Column>|<Column name="DetailNo">1</Column>|');
        Observer.Verify();
    end;

    [Test]
    procedure RNF_NestedRun_UseRequestPageAndPrintOnlyIfDetail()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'nested urp');
        RunCase(Observer, 'nested run');
        RunCase(Observer, 'no nested run');
        Observer.Expect('nested urp run ok', 'No');
        Observer.Expect('nested urp run|text', 'Report 96612 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('nested urp run|code', 'ReportNoLayout');
        Observer.Expect('nested urp run log', '');
        Observer.Expect('nested urp saveas ok', 'Yes');
        Observer.Expect('nested urp saveas log', 'outer pre urp=No;outer row 1;outer row 2;inner init;inner pre urp=No;inner row 1;inner row 2;inner row 3;inner post report;outer after nested;outer row end 2;outer row 3;outer post item;outer post report;');
        Observer.Expect('nested urp columns', '<Column name="RowId">2</Column>|<Column name="DetailNo">1</Column>|<Column name="RowId">3</Column>|<Column name="DetailNo">1</Column>|');
        Observer.Expect('nested run run ok', 'No');
        Observer.Expect('nested run run|text', 'Report 96612 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('nested run run|code', 'ReportNoLayout');
        Observer.Expect('nested run run log', '');
        Observer.Expect('nested run saveas ok', 'Yes');
        Observer.Expect('nested run saveas log', 'outer pre urp=No;outer row 1;outer row 2;inner init;inner pre urp=No;inner row 1;inner row 2;inner row 3;inner post report;outer after nested;outer row end 2;outer row 3;outer post item;outer post report;');
        Observer.Expect('nested run columns', '<Column name="RowId">2</Column>|<Column name="DetailNo">1</Column>|<Column name="RowId">3</Column>|<Column name="DetailNo">1</Column>|');
        Observer.Expect('no nested run run ok', 'No');
        Observer.Expect('no nested run run|text', 'Report 96612 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('no nested run run|code', 'ReportNoLayout');
        Observer.Expect('no nested run run log', '');
        Observer.Expect('no nested run saveas ok', 'Yes');
        Observer.Expect('no nested run saveas log', 'outer pre urp=No;outer row 1;outer row 2;outer row end 2;outer row 3;outer post item;outer post report;');
        Observer.Expect('no nested run columns', '<Column name="RowId">2</Column>|<Column name="DetailNo">1</Column>|<Column name="RowId">3</Column>|<Column name="DetailNo">1</Column>|');
        Observer.Verify();
    end;
}
