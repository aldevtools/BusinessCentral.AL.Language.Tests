// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-execute-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained table 91554, report 91555, test codeunit 91556
// Probe (al-runner issue 6446, writer Y12): Report.Execute(Parameters) on a report whose request page has an OnInit trigger. The trigger order, the
// value OnInit sees for a control the parameters name, that value in OnOpenPage and OnPreReport, and a control the parameters do not name (it
// keeps the value OnInit gave it). Plain Execute and SetTableView + Execute. RptRequestPage.al (RunRequestPage_ThenExecute_AppliesValues) pins
// the same order for parameters that name every control.

table 91554 "LT Y12 RPI Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; No; Integer) { }
    }
    keys
    {
        key(PK; No) { Clustered = true; }
    }
}

report 91555 "LT Y12 RPI Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(R; "LT Y12 RPI Row")
        {
            trigger OnPreDataItem()
            begin
                Log += 'OnPreDataItem(' + R.GetFilters() + ');';
            end;

            trigger OnAfterGetRecord()
            begin
                Log += 'row ' + Format(R.No) + ';';
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(ValControl; Val) { ApplicationArea = All; }
                field(OtherControl; Other) { ApplicationArea = All; }
            }
        }

        trigger OnInit()
        begin
            SeenInInit := Val;
            Val := 'INIT';
            Other := 'INIT';
            Log += 'OnInit;';
        end;

        trigger OnOpenPage()
        begin
            Log += 'OnOpenPage(' + Val + '|' + Other + ');';
        end;

        trigger OnClosePage()
        begin
            Log += 'OnClosePage(' + Val + ');';
        end;
    }

    trigger OnInitReport()
    begin
        Log += 'OnInitReport(' + Val + ');';
    end;

    trigger OnPreReport()
    begin
        Log += 'OnPreReport;';
        AtPre := Val;
        OtherAtPre := Other;
    end;

    var
        Val, Other, SeenInInit, AtPre, OtherAtPre : Text[30];
        Log: Text;

    procedure Result(): Text
    begin
        exit(StrSubstNo('seenInInit=[%1] atPre=[%2] otherAtPre=[%3] log=%4', SeenInInit, AtPre, OtherAtPre, Log));
    end;
}

codeunit 91556 "LT Y12 Execute OnInit"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT Y12 RPI Row";
    begin
        Row.DeleteAll();
        Row.No := 1;
        Row.Insert();
        Row.No := 2;
        Row.Insert();
    end;

    local procedure Params(): Text
    begin
        exit('<?xml version="1.0" standalone="yes"?><ReportParameters name="LT Y12 RPI Report" id="91555"><Options><Field name="Val">PARAM</Field></Options></ReportParameters>');
    end;

    [Test]
    procedure Y12_Execute_ParamsAfterRequestPageOnInit()
    var
        A: Report "LT Y12 RPI Report";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        A.Execute(Params());
        Observer.Observe('plain', A.Result());
        Observer.Expect('plain', 'seenInInit=[] atPre=[PARAM] otherAtPre=[INIT] log=OnInitReport();OnInit;OnOpenPage(PARAM|INIT);OnClosePage(PARAM);OnPreReport;OnPreDataItem();row 1;row 2;');
        Observer.Verify();
    end;

    [Test]
    procedure Y12_SetTableView_Execute_ParamsAfterRequestPageOnInit()
    var
        Row: Record "LT Y12 RPI Row";
        B: Report "LT Y12 RPI Report";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.SetRange(No, 2);
        B.SetTableView(Row);
        B.Execute(Params());
        Observer.Observe('settableview', B.Result());
        Observer.Expect('settableview', 'seenInInit=[] atPre=[PARAM] otherAtPre=[INIT] log=OnInitReport();OnInit;OnOpenPage(PARAM|INIT);OnClosePage(PARAM);OnPreReport;OnPreDataItem(No: 2);row 2;');
        Observer.Verify();
    end;

    [Test]
    procedure Y12_Execute_EmptyParameters_OnInitValues()
    var
        C: Report "LT Y12 RPI Report";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        C.Execute('');
        Observer.Observe('empty', C.Result());
        Observer.Expect('empty', 'seenInInit=[] atPre=[INIT] otherAtPre=[INIT] log=OnInitReport();OnInit;OnPreReport;OnPreDataItem();row 1;row 2;');
        Observer.Verify();
    end;
}
