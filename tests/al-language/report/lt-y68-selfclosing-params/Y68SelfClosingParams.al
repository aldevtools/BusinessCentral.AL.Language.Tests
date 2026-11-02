// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-execute-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own reports 93650-93651, codeunits 93659-93660.
// Probe (writer Y68, NP lane probe Q1): Report.Execute, Report.SaveAs and Report.RunRequestPage(Id, Parameters) with request page parameters
//   whose empty values are self-closing elements (<Field name="TxtVal" />), as RunRequestPage writes them: for a Text, Code, Date, Time and
//   DateTime control, and for the other control types, alone and mixed with filled ones, on a report whose request page OnInit (report 93650) or
//   report OnInitReport (report 93651) sets a non-empty default. Observed in OnPreReport: each variable (blank, or the default kept).
// Probe: values recorded on the BC 29 SaaS sandbox; other BC versions are checked by the corpus CI matrix.

codeunit 93659 "LT Y68 SC Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        Verbose: Boolean;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure AddVerbose(Entry: Text)
    begin
        if Verbose then
            Add(Entry);
    end;

    procedure SetVerbose(NewVerbose: Boolean)
    begin
        Verbose := NewVerbose;
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

report 93650 "LT Y68 SC Rpt"
{
    ProcessingOnly = true;

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(TxtCtl; TxtVal) { ApplicationArea = All; }
                field(CodeCtl; CodeVal) { ApplicationArea = All; }
                field(DateCtl; DateVal) { ApplicationArea = All; }
                field(TimeCtl; TimeVal) { ApplicationArea = All; }
                field(DtCtl; DtVal) { ApplicationArea = All; }
                field(IntCtl; IntVal) { ApplicationArea = All; }
                field(DecCtl; DecVal) { ApplicationArea = All; }
                field(BoolCtl; BoolVal) { ApplicationArea = All; }
                field(OptCtl; OptVal) { ApplicationArea = All; }
                field(EnumCtl; EnumVal) { ApplicationArea = All; }
                field(BigCtl; BigVal) { ApplicationArea = All; }
            }
        }

        trigger OnInit()
        begin
            TxtVal := 'tinit';
            CodeVal := 'CINIT';
            DateVal := DMY2Date(15, 1, 2024);
            TimeVal := 101500T;
            DtVal := CreateDateTime(DMY2Date(2, 3, 2024), 080910T);
            IntVal := 7;
            DecVal := 2.5;
            BoolVal := true;
            OptVal := OptVal::Gamma;
            EnumVal := EnumVal::Second;
            BigVal := 99;
            Log.AddVerbose('init ' + Values());
        end;

        trigger OnOpenPage()
        begin
            Log.AddVerbose('open ' + Values());
        end;
    }

    var
        TxtVal: Text[30];
        CodeVal: Code[10];
        DateVal: Date;
        TimeVal: Time;
        DtVal: DateTime;
        IntVal: Integer;
        DecVal: Decimal;
        BoolVal: Boolean;
        OptVal: Option Alpha,Beta,Gamma;
        EnumVal: Enum "LT Y68 SC Enum";
        BigVal: BigInteger;
        Log: Codeunit "LT Y68 SC Log";

    local procedure Values(): Text
    begin
        exit('t=[' + TxtVal + '] c=[' + CodeVal + '] d=[' + Format(DateVal, 0, 9) + '] tm=[' + Format(TimeVal, 0, 9) + '] dt=[' + Format(DtVal, 0, 9) +
            '] i=' + Format(IntVal) + ' dc=' + Format(DecVal) + ' b=' + Format(BoolVal) + ' o=' + Format(OptVal) + ' e=' + Format(EnumVal) + ' bg=' + Format(BigVal));
    end;

    trigger OnPreReport()
    begin
        Log.Add('pre ' + Values());
    end;
}

// A report with a dataset and a layout setting, so SaveAs renders it.
report 93652 "LT Y68 SC Data Rpt"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;

    dataset
    {
        dataitem(Num; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            column(NumberCol; Number) { }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(TxtCtl; TxtVal) { ApplicationArea = All; }
                field(CodeCtl; CodeVal) { ApplicationArea = All; }
                field(DateCtl; DateVal) { ApplicationArea = All; }
                field(IntCtl; IntVal) { ApplicationArea = All; }
            }
        }

        trigger OnInit()
        begin
            TxtVal := 'tinit';
            CodeVal := 'CINIT';
            DateVal := DMY2Date(15, 1, 2024);
            IntVal := 7;
        end;
    }

    var
        TxtVal: Text[30];
        CodeVal: Code[10];
        DateVal: Date;
        IntVal: Integer;
        Log: Codeunit "LT Y68 SC Log";

    trigger OnPreReport()
    begin
        Log.Add('pre t=[' + TxtVal + '] c=[' + CodeVal + '] d=[' + Format(DateVal, 0, 9) + '] i=' + Format(IntVal));
    end;
}

report 93651 "LT Y68 SC Init Rpt"
{
    ProcessingOnly = true;

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(TxtCtl; TxtVal) { ApplicationArea = All; }
                field(DateCtl; DateVal) { ApplicationArea = All; }
            }
        }
    }

    var
        TxtVal: Text[30];
        DateVal: Date;
        Log: Codeunit "LT Y68 SC Log";

    trigger OnInitReport()
    begin
        TxtVal := 'rinit';
        DateVal := DMY2Date(15, 1, 2024);
        Log.Add('initreport');
    end;

    trigger OnPreReport()
    begin
        Log.Add('pre txt=[' + TxtVal + '] date=[' + Format(DateVal, 0, 9) + ']');
    end;
}

enum 93650 "LT Y68 SC Enum"
{
    Extensible = true;

    value(0; First) { }
    value(5; Second) { }
}

codeunit 93660 "LT Y68 SC Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y68 SC Log";

    local procedure Xml(Name: Text; Id: Integer; Options: Text): Text
    begin
        exit('<?xml version="1.0" standalone="yes"?><ReportParameters name="' + Name + '" id="' + Format(Id) + '"><Options>' + Options + '</Options></ReportParameters>');
    end;

    local procedure Xml1(Options: Text): Text
    begin
        exit(Xml('LT Y68 SC Rpt', Report::"LT Y68 SC Rpt", Options));
    end;

    [TryFunction]
    local procedure TryExecute(Id: Integer; Parameters: Text)
    begin
        Report.Execute(Id, Parameters);
    end;

    [TryFunction]
    local procedure TrySaveAs(Id: Integer; Parameters: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(Id, Parameters, ReportFormat::Xml, OutS);
    end;

    local procedure RunCase(var Observer: Codeunit "Probe Observer"; Name: Text; Id: Integer; Parameters: Text; Mode: Integer)
    var
        Ok: Boolean;
    begin
        Log.Take();
        ClearLastError();
        if Mode = 1 then
            Ok := TryExecute(Id, Parameters)
        else
            Ok := TrySaveAs(Id, Parameters);
        Observer.Observe(Name + ' ok', Format(Ok));
        if not Ok then begin
            Observer.Observe(Name + ' error', GetLastErrorText());
            Observer.Observe(Name + ' code', GetLastErrorCode());
            ClearLastError();
        end;
        Observer.Observe(Name + ' log', Log.Take());
    end;

    [Test]
    procedure Q1_Execute_SelfClosing_TextLike()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'baseline no fields', Report::"LT Y68 SC Rpt", Xml1(''), 1);
        RunCase(Observer, 'text', Report::"LT Y68 SC Rpt", Xml1('<Field name="TxtVal" />'), 1);
        RunCase(Observer, 'code', Report::"LT Y68 SC Rpt", Xml1('<Field name="CodeVal" />'), 1);
        RunCase(Observer, 'date', Report::"LT Y68 SC Rpt", Xml1('<Field name="DateVal" />'), 1);
        RunCase(Observer, 'time', Report::"LT Y68 SC Rpt", Xml1('<Field name="TimeVal" />'), 1);
        RunCase(Observer, 'datetime', Report::"LT Y68 SC Rpt", Xml1('<Field name="DtVal" />'), 1);
        RunCase(Observer, 'all five', Report::"LT Y68 SC Rpt", Xml1('<Field name="TxtVal" /><Field name="CodeVal" /><Field name="DateVal" /><Field name="TimeVal" /><Field name="DtVal" />'), 1);
        Observer.Expect('baseline no fields ok', 'Yes');
        Observer.Expect('baseline no fields log', 'pre t=[tinit] c=[CINIT] d=[2024-01-15] tm=[10:15:00] dt=[2024-03-02T08:09:10Z] i=7 dc=2.5 b=Yes o=Gamma e=Second bg=99;');
        Observer.Expect('text ok', 'Yes');
        Observer.Expect('text log', 'pre t=[] c=[CINIT] d=[2024-01-15] tm=[10:15:00] dt=[2024-03-02T08:09:10Z] i=7 dc=2.5 b=Yes o=Gamma e=Second bg=99;');
        Observer.Expect('code ok', 'Yes');
        Observer.Expect('code log', 'pre t=[tinit] c=[] d=[2024-01-15] tm=[10:15:00] dt=[2024-03-02T08:09:10Z] i=7 dc=2.5 b=Yes o=Gamma e=Second bg=99;');
        Observer.Expect('date ok', 'Yes');
        Observer.Expect('date log', 'pre t=[tinit] c=[CINIT] d=[] tm=[10:15:00] dt=[2024-03-02T08:09:10Z] i=7 dc=2.5 b=Yes o=Gamma e=Second bg=99;');
        Observer.Expect('time ok', 'Yes');
        Observer.Expect('time log', 'pre t=[tinit] c=[CINIT] d=[2024-01-15] tm=[] dt=[2024-03-02T08:09:10Z] i=7 dc=2.5 b=Yes o=Gamma e=Second bg=99;');
        Observer.Expect('datetime ok', 'Yes');
        Observer.Expect('datetime log', 'pre t=[tinit] c=[CINIT] d=[2024-01-15] tm=[10:15:00] dt=[] i=7 dc=2.5 b=Yes o=Gamma e=Second bg=99;');
        Observer.Expect('all five ok', 'Yes');
        Observer.Expect('all five log', 'pre t=[] c=[] d=[] tm=[] dt=[] i=7 dc=2.5 b=Yes o=Gamma e=Second bg=99;');
        Observer.Verify();
    end;

    [Test]
    procedure Q1_Execute_SelfClosing_OtherTypes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'integer', Report::"LT Y68 SC Rpt", Xml1('<Field name="IntVal" />'), 1);
        RunCase(Observer, 'decimal', Report::"LT Y68 SC Rpt", Xml1('<Field name="DecVal" />'), 1);
        RunCase(Observer, 'boolean', Report::"LT Y68 SC Rpt", Xml1('<Field name="BoolVal" />'), 1);
        RunCase(Observer, 'option', Report::"LT Y68 SC Rpt", Xml1('<Field name="OptVal" />'), 1);
        RunCase(Observer, 'enum', Report::"LT Y68 SC Rpt", Xml1('<Field name="EnumVal" />'), 1);
        RunCase(Observer, 'biginteger', Report::"LT Y68 SC Rpt", Xml1('<Field name="BigVal" />'), 1);
        Observer.Expect('integer ok', 'Yes');
        Observer.Expect('integer log', 'pre t=[tinit] c=[CINIT] d=[2024-01-15] tm=[10:15:00] dt=[2024-03-02T08:09:10Z] i=0 dc=2.5 b=Yes o=Gamma e=Second bg=99;');
        Observer.Expect('decimal ok', 'Yes');
        Observer.Expect('decimal log', 'pre t=[tinit] c=[CINIT] d=[2024-01-15] tm=[10:15:00] dt=[2024-03-02T08:09:10Z] i=7 dc=0 b=Yes o=Gamma e=Second bg=99;');
        Observer.Expect('boolean ok', 'Yes');
        Observer.Expect('boolean log', 'pre t=[tinit] c=[CINIT] d=[2024-01-15] tm=[10:15:00] dt=[2024-03-02T08:09:10Z] i=7 dc=2.5 b=No o=Gamma e=Second bg=99;');
        Observer.Expect('option ok', 'Yes');
        Observer.Expect('option log', 'pre t=[tinit] c=[CINIT] d=[2024-01-15] tm=[10:15:00] dt=[2024-03-02T08:09:10Z] i=7 dc=2.5 b=Yes o=Alpha e=Second bg=99;');
        Observer.Expect('enum ok', 'Yes');
        Observer.Expect('enum log', 'pre t=[tinit] c=[CINIT] d=[2024-01-15] tm=[10:15:00] dt=[2024-03-02T08:09:10Z] i=7 dc=2.5 b=Yes o=Gamma e=First bg=99;');
        Observer.Expect('biginteger ok', 'Yes');
        Observer.Expect('biginteger log', 'pre t=[tinit] c=[CINIT] d=[2024-01-15] tm=[10:15:00] dt=[2024-03-02T08:09:10Z] i=7 dc=2.5 b=Yes o=Gamma e=Second bg=0;');
        Observer.Verify();
    end;

    [Test]
    procedure Q1_Execute_EmptyWithEndTag_AndMixed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'end tag text', Report::"LT Y68 SC Rpt", Xml1('<Field name="TxtVal"></Field>'), 1);
        RunCase(Observer, 'end tag date', Report::"LT Y68 SC Rpt", Xml1('<Field name="DateVal"></Field>'), 1);
        RunCase(Observer, 'end tag integer', Report::"LT Y68 SC Rpt", Xml1('<Field name="IntVal"></Field>'), 1);
        RunCase(Observer, 'mixed filled and empty', Report::"LT Y68 SC Rpt",
            Xml1('<Field name="TxtVal">given</Field><Field name="CodeVal" /><Field name="DateVal">2024-05-06</Field><Field name="TimeVal" /><Field name="DtVal" /><Field name="IntVal">5</Field>'), 1);
        RunCase(Observer, 'empty first then filled', Report::"LT Y68 SC Rpt", Xml1('<Field name="TxtVal" /><Field name="CodeVal">xyz</Field>'), 1);
        RunCase(Observer, 'filled then empty last', Report::"LT Y68 SC Rpt", Xml1('<Field name="CodeVal">xyz</Field><Field name="TxtVal" />'), 1);
        Observer.Expect('end tag text ok', 'Yes');
        Observer.Expect('end tag text log', 'pre t=[] c=[CINIT] d=[2024-01-15] tm=[10:15:00] dt=[2024-03-02T08:09:10Z] i=7 dc=2.5 b=Yes o=Gamma e=Second bg=99;');
        Observer.Expect('end tag date ok', 'Yes');
        Observer.Expect('end tag date log', 'pre t=[tinit] c=[CINIT] d=[] tm=[10:15:00] dt=[2024-03-02T08:09:10Z] i=7 dc=2.5 b=Yes o=Gamma e=Second bg=99;');
        Observer.Expect('end tag integer ok', 'Yes');
        Observer.Expect('end tag integer log', 'pre t=[tinit] c=[CINIT] d=[2024-01-15] tm=[10:15:00] dt=[2024-03-02T08:09:10Z] i=0 dc=2.5 b=Yes o=Gamma e=Second bg=99;');
        Observer.Expect('mixed filled and empty ok', 'Yes');
        Observer.Expect('mixed filled and empty log', 'pre t=[given] c=[] d=[2024-05-06] tm=[] dt=[] i=5 dc=2.5 b=Yes o=Gamma e=Second bg=99;');
        Observer.Expect('empty first then filled ok', 'Yes');
        Observer.Expect('empty first then filled log', 'pre t=[] c=[XYZ] d=[2024-01-15] tm=[10:15:00] dt=[2024-03-02T08:09:10Z] i=7 dc=2.5 b=Yes o=Gamma e=Second bg=99;');
        Observer.Expect('filled then empty last ok', 'Yes');
        Observer.Expect('filled then empty last log', 'pre t=[] c=[XYZ] d=[2024-01-15] tm=[10:15:00] dt=[2024-03-02T08:09:10Z] i=7 dc=2.5 b=Yes o=Gamma e=Second bg=99;');
        Observer.Verify();
    end;

    [Test]
    procedure Q1_Execute_Filled_AllTypes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'filled all', Report::"LT Y68 SC Rpt",
            Xml1('<Field name="TxtVal">a b</Field><Field name="CodeVal">xy</Field><Field name="DateVal">2025-12-31</Field><Field name="TimeVal">23:59:58</Field><Field name="DtVal">2025-12-31T23:59:58Z</Field>' +
                '<Field name="IntVal">-3</Field><Field name="DecVal">0.75</Field><Field name="BoolVal">false</Field><Field name="OptVal">1</Field><Field name="EnumVal">0</Field><Field name="BigVal">5000000000</Field>'), 1);
        RunCase(Observer, 'filled by name', Report::"LT Y68 SC Rpt", Xml1('<Field name="OptVal">Beta</Field><Field name="EnumVal">Second</Field><Field name="BoolVal">Yes</Field>'), 1);
        RunCase(Observer, 'filled bad int', Report::"LT Y68 SC Rpt", Xml1('<Field name="IntVal">abc</Field>'), 1);
        Observer.Expect('filled all ok', 'Yes');
        Observer.Expect('filled all log', 'pre t=[a b] c=[XY] d=[2025-12-31] tm=[23:59:58] dt=[2025-12-31T23:59:58Z] i=-3 dc=0.75 b=No o=Beta e=First bg=5000000000;');
        Observer.Expect('filled by name ok', 'No');
#if BC28PLUS
        Observer.Expect('filled by name error', 'The value "Beta" can''t be evaluated into type Option.');
        Observer.Expect('filled by name code', 'Evaluate:Format');
#else
        Observer.Expect('filled by name error', 'The type NavOption is unknown.');
        Observer.Expect('filled by name code', 'NotSupportedType');
#endif
        Observer.Expect('filled by name log', '');
        Observer.Expect('filled bad int ok', 'No');
        Observer.Expect('filled bad int error', 'NavType');
        Observer.Expect('filled bad int code', 'Argument');
        Observer.Expect('filled bad int log', '');
        Observer.Verify();
    end;

    [Test]
    procedure Q1_Execute_SelfClosing_OptionsAndRoot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'options self-closing', Report::"LT Y68 SC Rpt",
            '<?xml version="1.0" standalone="yes"?><ReportParameters name="LT Y68 SC Rpt" id="' + Format(Report::"LT Y68 SC Rpt") + '"><Options /></ReportParameters>', 1);
        RunCase(Observer, 'no options element', Report::"LT Y68 SC Rpt",
            '<?xml version="1.0" standalone="yes"?><ReportParameters name="LT Y68 SC Rpt" id="' + Format(Report::"LT Y68 SC Rpt") + '"></ReportParameters>', 1);
        RunCase(Observer, 'root self-closing', Report::"LT Y68 SC Rpt",
            '<?xml version="1.0" standalone="yes"?><ReportParameters name="LT Y68 SC Rpt" id="' + Format(Report::"LT Y68 SC Rpt") + '" />', 1);
        RunCase(Observer, 'init report text', Report::"LT Y68 SC Init Rpt", Xml('LT Y68 SC Init Rpt', Report::"LT Y68 SC Init Rpt", '<Field name="TxtVal" /><Field name="DateVal" />'), 1);
        RunCase(Observer, 'init report filled', Report::"LT Y68 SC Init Rpt", Xml('LT Y68 SC Init Rpt', Report::"LT Y68 SC Init Rpt", '<Field name="TxtVal">given</Field><Field name="DateVal" />'), 1);
        RunCase(Observer, 'init report none', Report::"LT Y68 SC Init Rpt", Xml('LT Y68 SC Init Rpt', Report::"LT Y68 SC Init Rpt", ''), 1);
        Observer.Expect('options self-closing ok', 'Yes');
        Observer.Expect('options self-closing log', 'pre t=[tinit] c=[CINIT] d=[2024-01-15] tm=[10:15:00] dt=[2024-03-02T08:09:10Z] i=7 dc=2.5 b=Yes o=Gamma e=Second bg=99;');
        Observer.Expect('no options element ok', 'Yes');
        Observer.Expect('no options element log', 'pre t=[tinit] c=[CINIT] d=[2024-01-15] tm=[10:15:00] dt=[2024-03-02T08:09:10Z] i=7 dc=2.5 b=Yes o=Gamma e=Second bg=99;');
        Observer.Expect('root self-closing ok', 'Yes');
        Observer.Expect('root self-closing log', 'pre t=[tinit] c=[CINIT] d=[2024-01-15] tm=[10:15:00] dt=[2024-03-02T08:09:10Z] i=7 dc=2.5 b=Yes o=Gamma e=Second bg=99;');
        Observer.Expect('init report text ok', 'Yes');
        Observer.Expect('init report text log', 'initreport;pre txt=[] date=[];');
        Observer.Expect('init report filled ok', 'Yes');
        Observer.Expect('init report filled log', 'initreport;pre txt=[given] date=[];');
        Observer.Expect('init report none ok', 'Yes');
        Observer.Expect('init report none log', 'initreport;pre txt=[rinit] date=[2024-01-15];');
        Observer.Verify();
    end;

    local procedure DataXml(Options: Text): Text
    begin
        exit(Xml('LT Y68 SC Data Rpt', Report::"LT Y68 SC Data Rpt", Options));
    end;

    [Test]
    procedure Q1_SaveAs_SelfClosing_ProcessingOnlyIsRefused()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'saveas processing only', Report::"LT Y68 SC Rpt", Xml1('<Field name="TxtVal" />'), 2);
        Observer.Expect('saveas processing only ok', 'No');
        Observer.Expect('saveas processing only error', 'Report 93650 is a processing-only report. Output cannot be rendered and saved to a file.');
        Observer.Expect('saveas processing only code', 'ReportProcessingOnly');
        Observer.Expect('saveas processing only log', '');
        Observer.Verify();
    end;

    [Test]
    procedure Q1_SaveAs_SelfClosing_DataReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'baseline', Report::"LT Y68 SC Data Rpt", DataXml(''), 2);
        RunCase(Observer, 'text', Report::"LT Y68 SC Data Rpt", DataXml('<Field name="TxtVal" />'), 2);
        RunCase(Observer, 'text code date', Report::"LT Y68 SC Data Rpt", DataXml('<Field name="TxtVal" /><Field name="CodeVal" /><Field name="DateVal" />'), 2);
        RunCase(Observer, 'mixed', Report::"LT Y68 SC Data Rpt", DataXml('<Field name="TxtVal">given</Field><Field name="CodeVal" /><Field name="DateVal">2024-05-06</Field><Field name="IntVal" />'), 2);
        RunCase(Observer, 'execute text', Report::"LT Y68 SC Data Rpt", DataXml('<Field name="TxtVal" />'), 1);
        Observer.Expect('baseline ok', 'Yes');
        Observer.Expect('baseline log', 'pre t=[tinit] c=[CINIT] d=[2024-01-15] i=7;');
        Observer.Expect('text ok', 'Yes');
        Observer.Expect('text log', 'pre t=[] c=[CINIT] d=[2024-01-15] i=7;');
        Observer.Expect('text code date ok', 'Yes');
        Observer.Expect('text code date log', 'pre t=[] c=[] d=[] i=7;');
        Observer.Expect('mixed ok', 'Yes');
        Observer.Expect('mixed log', 'pre t=[given] c=[] d=[2024-05-06] i=0;');
        Observer.Expect('execute text ok', 'No');
        Observer.Expect('execute text error', 'Report 93652 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('execute text code', 'ReportNoLayout');
        Observer.Expect('execute text log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ParamsHandler')]
    procedure Q1_RunRequestPage_WithSelfClosing_AndRoundTrip()
    var
        Observer: Codeunit "Probe Observer";
        Returned: Text;
    begin
        Log.Take();
        Log.SetVerbose(true);
        Returned := Report.RunRequestPage(Report::"LT Y68 SC Rpt", Xml1('<Field name="TxtVal" /><Field name="CodeVal">abc</Field><Field name="DateVal" />'));
        Observer.Observe('seeded log', Log.Take());
        Observer.Observe('seeded returned', Returned);
        Returned := Report.RunRequestPage(Report::"LT Y68 SC Rpt");
        Observer.Observe('plain log', Log.Take());
        Observer.Observe('plain returned', Returned);
        Log.SetVerbose(false);
        Observer.Expect('seeded log', 'init t=[tinit] c=[CINIT] d=[2024-01-15] tm=[10:15:00] dt=[2024-03-02T08:09:10Z] i=7 dc=2.5 b=Yes o=Gamma e=Second bg=99;open t=[] c=[ABC] d=[] tm=[10:15:00] dt=[2024-03-02T08:09:10Z] i=7 dc=2.5 b=Yes o=Gamma e=Second bg=99;handler txt= code=ABC date= time=10:15:00 AM dt=3/2/2024 8:09 AM;');
        Observer.Expect('seeded returned', '<?xml version="1.0" standalone="yes"?><ReportParameters name="LT Y68 SC Rpt" id="93650"><Options><Field name="TxtVal" /><Field name="CodeVal">ABC</Field><Field name="DateVal" /><Field name="TimeVal">10:15:00</Field><Field name="DtVal">2024-03-02T08:09:10Z</Field><Field name="IntVal">7</Field><Field name="DecVal">2.5</Field><Field name="BoolVal">true</Field><Field name="OptVal">2</Field><Field name="EnumVal">5</Field><Field name="BigVal">99</Field></Options></ReportParameters>');
        Observer.Expect('plain log', 'init t=[tinit] c=[CINIT] d=[2024-01-15] tm=[10:15:00] dt=[2024-03-02T08:09:10Z] i=7 dc=2.5 b=Yes o=Gamma e=Second bg=99;open t=[tinit] c=[CINIT] d=[2024-01-15] tm=[10:15:00] dt=[2024-03-02T08:09:10Z] i=7 dc=2.5 b=Yes o=Gamma e=Second bg=99;handler txt=tinit code=CINIT date=1/15/2024 time=10:15:00 AM dt=3/2/2024 8:09 AM;');
        Observer.Expect('plain returned', '<?xml version="1.0" standalone="yes"?><ReportParameters name="LT Y68 SC Rpt" id="93650"><Options><Field name="TxtVal">tinit</Field><Field name="CodeVal">CINIT</Field><Field name="DateVal">2024-01-15</Field><Field name="TimeVal">10:15:00</Field><Field name="DtVal">2024-03-02T08:09:10Z</Field><Field name="IntVal">7</Field><Field name="DecVal">2.5</Field><Field name="BoolVal">true</Field><Field name="OptVal">2</Field><Field name="EnumVal">5</Field><Field name="BigVal">99</Field></Options></ReportParameters>');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure ParamsHandler(var RP: TestRequestPage "LT Y68 SC Rpt")
    begin
        Log.Add('handler txt=' + RP.TxtCtl.Value() + ' code=' + RP.CodeCtl.Value() + ' date=' + RP.DateCtl.Value() + ' time=' + RP.TimeCtl.Value() + ' dt=' + RP.DtCtl.Value());
        RP.OK().Invoke();
    end;
}
