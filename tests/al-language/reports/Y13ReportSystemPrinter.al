// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-usesystemprinter-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 91610, reports 91611-91612, codeunit 91613 (log), processing-only reports 91615-91616, codeunit 91614 (tests)
// Probe: observe probe (writer Y13, 2026-10-31, runtime asks from partner-app triage); every literal asserted below is what the BC service tier produced.
// Facts: two identical reports that differ only in UseSystemPrinter (true and false), run from a test through Report.Run, Report.RunModal,
//   Report.RunRequestPage, Report.SaveAs (Xml), Report.Execute and Report.Print: the events that fire (init, request page, data item, pre and post
//   report), and the error when one is raised. The property is also read back from the Report Metadata table.
// BC versions: 27, 28, 29

table 91610 "LT Y13 SP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; No; Integer) { }
        field(2; Data; Blob) { }
    }
    keys
    {
        key(PK; No) { Clustered = true; }
    }
}

codeunit 91613 "LT Y13 SP Log"
{
    SingleInstance = true;

    var
        Text: Text;

    procedure Add(Entry: Text)
    begin
        Text += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Text;
        Text := '';
        exit(Result);
    end;
}

report 91611 "LT Y13 SP On"
{
    UseSystemPrinter = true;
    UseRequestPage = true;

    dataset
    {
        dataitem(R; "LT Y13 SP Row")
        {
            column(No; No) { }

            trigger OnPreDataItem()
            begin
                Log.Add('pre-di');
            end;

            trigger OnAfterGetRecord()
            begin
                Log.Add('rec' + Format(R.No));
            end;

            trigger OnPostDataItem()
            begin
                Log.Add('post-di');
            end;
        }
    }

    requestpage
    {
        trigger OnOpenPage()
        begin
            Log.Add('rp-open');
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            Log.Add('rp-close');
            exit(true);
        end;
    }

    var
        Log: Codeunit "LT Y13 SP Log";

    trigger OnInitReport()
    begin
        Log.Add('init');
    end;

    trigger OnPreReport()
    begin
        Log.Add('pre');
    end;

    trigger OnPostReport()
    begin
        Log.Add('post');
    end;
}

report 91612 "LT Y13 SP Off"
{
    UseSystemPrinter = false;
    UseRequestPage = true;

    dataset
    {
        dataitem(R; "LT Y13 SP Row")
        {
            column(No; No) { }

            trigger OnPreDataItem()
            begin
                Log.Add('pre-di');
            end;

            trigger OnAfterGetRecord()
            begin
                Log.Add('rec' + Format(R.No));
            end;

            trigger OnPostDataItem()
            begin
                Log.Add('post-di');
            end;
        }
    }

    requestpage
    {
        trigger OnOpenPage()
        begin
            Log.Add('rp-open');
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            Log.Add('rp-close');
            exit(true);
        end;
    }

    var
        Log: Codeunit "LT Y13 SP Log";

    trigger OnInitReport()
    begin
        Log.Add('init');
    end;

    trigger OnPreReport()
    begin
        Log.Add('pre');
    end;

    trigger OnPostReport()
    begin
        Log.Add('post');
    end;
}

report 91615 "LT Y13 SP Proc On"
{
    UseSystemPrinter = true;
    UseRequestPage = true;
    ProcessingOnly = true;

    dataset
    {
        dataitem(R; "LT Y13 SP Row")
        {
            trigger OnPreDataItem()
            begin
                Log.Add('pre-di');
            end;

            trigger OnAfterGetRecord()
            begin
                Log.Add('rec' + Format(R.No));
            end;

            trigger OnPostDataItem()
            begin
                Log.Add('post-di');
            end;
        }
    }

    requestpage
    {
        trigger OnOpenPage()
        begin
            Log.Add('rp-open');
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            Log.Add('rp-close');
            exit(true);
        end;
    }

    var
        Log: Codeunit "LT Y13 SP Log";

    trigger OnInitReport()
    begin
        Log.Add('init');
    end;

    trigger OnPreReport()
    begin
        Log.Add('pre');
    end;

    trigger OnPostReport()
    begin
        Log.Add('post');
    end;
}

report 91616 "LT Y13 SP Proc Off"
{
    UseSystemPrinter = false;
    UseRequestPage = true;
    ProcessingOnly = true;

    dataset
    {
        dataitem(R; "LT Y13 SP Row")
        {
            trigger OnPreDataItem()
            begin
                Log.Add('pre-di');
            end;

            trigger OnAfterGetRecord()
            begin
                Log.Add('rec' + Format(R.No));
            end;

            trigger OnPostDataItem()
            begin
                Log.Add('post-di');
            end;
        }
    }

    requestpage
    {
        trigger OnOpenPage()
        begin
            Log.Add('rp-open');
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            Log.Add('rp-close');
            exit(true);
        end;
    }

    var
        Log: Codeunit "LT Y13 SP Log";

    trigger OnInitReport()
    begin
        Log.Add('init');
    end;

    trigger OnPreReport()
    begin
        Log.Add('pre');
    end;

    trigger OnPostReport()
    begin
        Log.Add('post');
    end;
}

codeunit 91614 "LT Y13 SP Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [RequestPageHandler]
    procedure OkOn(var Request: TestRequestPage "LT Y13 SP On")
    begin
        Request.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure OkOff(var Request: TestRequestPage "LT Y13 SP Off")
    begin
        Request.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure OkProcOn(var Request: TestRequestPage "LT Y13 SP Proc On")
    begin
        Request.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure OkProcOff(var Request: TestRequestPage "LT Y13 SP Proc Off")
    begin
        Request.OK().Invoke();
    end;

    local procedure Seed()
    var
        Row: Record "LT Y13 SP Row";
    begin
        Row.DeleteAll();
        Row.No := 1;
        Row.Insert();
        Row.No := 2;
        Row.Insert();
        Commit();
    end;

    local procedure RunMode(Mode: Text; ReportId: Integer)
    var
        Rep: Report "LT Y13 SP On";
        RepOff: Report "LT Y13 SP Off";
        OutS: OutStream;
        Holder: Record "LT Y13 SP Row" temporary;
        Parameters: Text;
    begin
        Holder.Data.CreateOutStream(OutS);
        case Mode of
            'run':
                Report.Run(ReportId);
            'run norequest':
                Report.Run(ReportId, false);
            'runmodal':
                Report.RunModal(ReportId);
            'requestpage':
                Parameters := Report.RunRequestPage(ReportId);
            'saveas xml':
                Report.SaveAs(ReportId, '', ReportFormat::Xml, OutS);
            'saveas instance xml':
                if ReportId = 91611 then
                    Rep.SaveAs('', ReportFormat::Xml, OutS)
                else
                    RepOff.SaveAs('', ReportFormat::Xml, OutS);
            'execute':
                Report.Execute(ReportId, '');
            'print':
                Report.Print(ReportId, '');
        end;
    end;

    local procedure Outcome(Mode: Text; ReportId: Integer): Text
    var
        Log: Codeunit "LT Y13 SP Log";
        Head: Text;
    begin
        Seed();
        Log.Take();
        asserterror begin
            RunMode(Mode, ReportId);
            Error('LT-NOERROR');
        end;
        if GetLastErrorText() = 'LT-NOERROR' then
            Head := 'ok'
        else
            Head := 'error ' + GetLastErrorText() + ' (' + GetLastErrorCode() + ')';
        exit(Head + ' / ' + Log.Take());
    end;

    [Test]
    [HandlerFunctions('OkProcOn,OkProcOff')]
    procedure Y13_SP_Proc_Run()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('on', Outcome('run', 91615));
        Observer.Observe('off', Outcome('run', 91616));
        Observer.Expect('on', 'ok / init;rp-open;rp-close;pre;pre-di;rec1;rec2;post-di;post;');
        Observer.Expect('off', 'ok / init;rp-open;rp-close;pre;pre-di;rec1;rec2;post-di;post;');
        Observer.Verify();
    end;

    [Test]
    procedure Y13_SP_Proc_RunNoRequest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('on', Outcome('run norequest', 91615));
        Observer.Observe('off', Outcome('run norequest', 91616));
        Observer.Expect('on', 'ok / init;pre;pre-di;rec1;rec2;post-di;post;');
        Observer.Expect('off', 'ok / init;pre;pre-di;rec1;rec2;post-di;post;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkProcOn,OkProcOff')]
    procedure Y13_SP_Proc_RunModal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('on', Outcome('runmodal', 91615));
        Observer.Observe('off', Outcome('runmodal', 91616));
        Observer.Expect('on', 'ok / init;rp-open;rp-close;pre;pre-di;rec1;rec2;post-di;post;');
        Observer.Expect('off', 'ok / init;rp-open;rp-close;pre;pre-di;rec1;rec2;post-di;post;');
        Observer.Verify();
    end;

    [Test]
    procedure Y13_SP_Proc_Execute()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('on', Outcome('execute', 91615));
        Observer.Observe('off', Outcome('execute', 91616));
        Observer.Expect('on', 'ok / init;pre;pre-di;rec1;rec2;post-di;post;');
        Observer.Expect('off', 'ok / init;pre;pre-di;rec1;rec2;post-di;post;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkProcOn,OkProcOff')]
    procedure Y13_SP_Proc_RunRequestPage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('on', Outcome('requestpage', 91615));
        Observer.Observe('off', Outcome('requestpage', 91616));
        Observer.Expect('on', 'ok / init;rp-open;rp-close;');
        Observer.Expect('off', 'ok / init;rp-open;rp-close;');
        Observer.Verify();
    end;

    [Test]
    procedure Y13_SP_Data_SaveAsXml()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('on', Outcome('saveas xml', 91611));
        Observer.Observe('off', Outcome('saveas xml', 91612));
        Observer.Expect('on', 'ok / init;pre;pre-di;rec1;rec2;post-di;post;');
        Observer.Expect('off', 'ok / init;pre;pre-di;rec1;rec2;post-di;post;');
        Observer.Verify();
    end;

    [Test]
    procedure Y13_SP_Data_SaveAsInstance()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('on', Outcome('saveas instance xml', 91611));
        Observer.Observe('off', Outcome('saveas instance xml', 91612));
        Observer.Expect('on', 'ok / init;pre;pre-di;rec1;rec2;post-di;post;');
        Observer.Expect('off', 'ok / init;pre;pre-di;rec1;rec2;post-di;post;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkOn,OkOff')]
    procedure Y13_SP_Data_RunRequestPage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('on', Outcome('requestpage', 91611));
        Observer.Observe('off', Outcome('requestpage', 91612));
        Observer.Expect('on', 'ok / init;rp-open;rp-close;');
        Observer.Expect('off', 'ok / init;rp-open;rp-close;');
        Observer.Verify();
    end;

    [Test]
    procedure Y13_SP_Data_RunNoRequest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('on', Outcome('run norequest', 91611));
        Observer.Observe('off', Outcome('run norequest', 91612));
        Observer.Expect('on', 'error Report 91611 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom. (ReportNoLayout) / init;');
        Observer.Expect('off', 'error Report 91612 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom. (ReportNoLayout) / init;');
        Observer.Verify();
    end;

    [Test]
    procedure Y13_SP_Data_Execute()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('on', Outcome('execute', 91611));
        Observer.Observe('off', Outcome('execute', 91612));
        Observer.Expect('on', 'error Report 91611 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom. (ReportNoLayout) / init;');
        Observer.Expect('off', 'error Report 91612 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom. (ReportNoLayout) / init;');
        Observer.Verify();
    end;

    [Test]
    procedure Y13_SP_Proc_Print()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('on', Outcome('print', 91615));
        Observer.Observe('off', Outcome('print', 91616));
        Observer.Expect('on', 'ok / init;pre;pre-di;rec1;rec2;post-di;post;');
        Observer.Expect('off', 'ok / init;pre;pre-di;rec1;rec2;post-di;post;');
        Observer.Verify();
    end;

    local procedure MetaValue(ReportId: Integer): Text
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.Open(2000000139);
        FldRef := RecRef.Field(1);
        FldRef.SetRange(ReportId);
        if not RecRef.FindFirst() then
            exit('not found');
        exit(Format(RecRef.Field(5).Value()) + '|' + Format(RecRef.Field(4).Value()));
    end;

    [Test]
    procedure Y13_SP_Metadata()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('on', MetaValue(91611));
        Observer.Observe('off', MetaValue(91612));
        Observer.Observe('proc on', MetaValue(91615));
        Observer.Observe('proc off', MetaValue(91616));
        Observer.Expect('on', 'Yes|Yes');
        Observer.Expect('off', 'No|Yes');
        Observer.Expect('proc on', 'Yes|Yes');
        Observer.Expect('proc off', 'No|Yes');
        Observer.Verify();
    end;
}

