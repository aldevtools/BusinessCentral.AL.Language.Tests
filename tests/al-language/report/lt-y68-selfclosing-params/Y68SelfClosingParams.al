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
            Log.Add('init ' + Values());
        end;

        trigger OnOpenPage()
        begin
            Log.Add('open ' + Values());
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
        exit('txt=[' + TxtVal + '] code=[' + CodeVal + '] date=[' + Format(DateVal, 0, 9) + '] time=[' + Format(TimeVal, 0, 9) + '] dt=[' + Format(DtVal, 0, 9) +
            '] int=' + Format(IntVal) + ' dec=' + Format(DecVal) + ' bool=' + Format(BoolVal) + ' opt=' + Format(OptVal) + ' enum=' + Format(EnumVal) + ' big=' + Format(BigVal));
    end;

    trigger OnPreReport()
    begin
        Log.Add('pre ' + Values());
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
        HandlerOptions: Text;

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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Q1_SaveAs_SelfClosing()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'saveas text', Report::"LT Y68 SC Rpt", Xml1('<Field name="TxtVal" />'), 2);
        RunCase(Observer, 'saveas all five', Report::"LT Y68 SC Rpt", Xml1('<Field name="TxtVal" /><Field name="CodeVal" /><Field name="DateVal" /><Field name="TimeVal" /><Field name="DtVal" />'), 2);
        RunCase(Observer, 'saveas mixed', Report::"LT Y68 SC Rpt", Xml1('<Field name="TxtVal">given</Field><Field name="CodeVal" /><Field name="DateVal">2024-05-06</Field>'), 2);
        RunCase(Observer, 'saveas init report', Report::"LT Y68 SC Init Rpt", Xml('LT Y68 SC Init Rpt', Report::"LT Y68 SC Init Rpt", '<Field name="TxtVal" />'), 2);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ParamsHandler')]
    procedure Q1_RunRequestPage_WithSelfClosing_AndRoundTrip()
    var
        Observer: Codeunit "Probe Observer";
        Returned: Text;
    begin
        Log.Take();
        HandlerOptions := '';
        Returned := Report.RunRequestPage(Report::"LT Y68 SC Rpt", Xml1('<Field name="TxtVal" /><Field name="CodeVal">abc</Field><Field name="DateVal" />'));
        Observer.Observe('seeded log', Log.Take());
        Observer.Observe('seeded returned', Returned);
        Returned := Report.RunRequestPage(Report::"LT Y68 SC Rpt");
        Observer.Observe('plain log', Log.Take());
        Observer.Observe('plain returned', Returned);
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure ParamsHandler(var RP: TestRequestPage "LT Y68 SC Rpt")
    begin
        Log.Add('handler txt=' + RP.TxtCtl.Value() + ' code=' + RP.CodeCtl.Value() + ' date=' + RP.DateCtl.Value() + ' time=' + RP.TimeCtl.Value() + ' dt=' + RP.DtCtl.Value());
        RP.OK().Invoke();
    end;
}
