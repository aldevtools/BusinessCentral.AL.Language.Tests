// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); tables and helper of P105Fix.al; LT P82 Log (71186, a plain table backed log) of pages/lt-page-runtime/P82Fixtures.al; own report 89243
// Facts: whether the layout members (RdlcLayout, WordLayout, ExcelLayout, DefaultLayout, instance and static) run OnInitReport / OnPreReport of a report without a layout,
// and the error text and code of the layout members and DefaultLayout for a missing report id called from the test method itself (not from a try function).
// BC versions: 27, 28, 29

report 89243 "LT SM LytInit Rep"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P105 Row")
        {
            column(Id; Id) { }
        }
    }

    trigger OnInitReport()
    var
        Log: Codeunit "LT P82 Log";
    begin
        Log.Add('OnInitReport');
    end;

    trigger OnPreReport()
    var
        Log: Codeunit "LT P82 Log";
    begin
        Log.Add('OnPreReport');
    end;
}

codeunit 89244 "LT SM LytInit Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT P105 Helper";
        Log: Codeunit "LT P82 Log";

    [TryFunction]
    local procedure TryInstRdlc(var Rpt: Report "LT SM LytInit Rep")
    var
        InStr: InStream;
    begin
        Rpt.RdlcLayout(InStr);
    end;

    [TryFunction]
    local procedure TryInstWord(var Rpt: Report "LT SM LytInit Rep")
    var
        InStr: InStream;
    begin
        Rpt.WordLayout(InStr);
    end;

    [TryFunction]
    local procedure TryInstExcel(var Rpt: Report "LT SM LytInit Rep")
    var
        InStr: InStream;
    begin
        Rpt.ExcelLayout(InStr);
    end;

    [TryFunction]
    local procedure TryStaticRdlc()
    var
        InStr: InStream;
    begin
        Report.RdlcLayout(Report::"LT SM LytInit Rep", InStr);
    end;

    [TryFunction]
    local procedure TryStaticWord()
    var
        InStr: InStream;
    begin
        Report.WordLayout(Report::"LT SM LytInit Rep", InStr);
    end;

    [TryFunction]
    local procedure TryStaticExcel()
    var
        InStr: InStream;
    begin
        Report.ExcelLayout(Report::"LT SM LytInit Rep", InStr);
    end;

    local procedure Step(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean)
    begin
        Observer.Observe(Name, Format(Ok) + ' ' + GetLastErrorCode());
        Observer.Observe(Name + '-log', Log.Dump());
        Log.Reset();
        ClearLastError();
    end;

    [Test]
    procedure InstanceLayoutMembers_OnInitReport()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT SM LytInit Rep";
        Rpt2: Report "LT SM LytInit Rep";
    begin
        Helper.Seed();
        Log.Reset();
        Step(Observer, 'rdlc', TryInstRdlc(Rpt));
        Step(Observer, 'word', TryInstWord(Rpt));
        Step(Observer, 'excel', TryInstExcel(Rpt));
        Observer.Observe('default', Format(Rpt.DefaultLayout()));
        Observer.Observe('default-log', Log.Dump());
        Log.Reset();
        Observer.Observe('fresh default', Format(Rpt2.DefaultLayout()));
        Observer.Observe('fresh default-log', Log.Dump());
        Log.Reset();
        Rpt2.UseRequestPage(false);
        Rpt2.Execute('');
        Observer.Observe('execute-log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure StaticLayoutMembers_OnInitReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        Log.Reset();
        Step(Observer, 'rdlc', TryStaticRdlc());
        Step(Observer, 'word', TryStaticWord());
        Step(Observer, 'excel', TryStaticExcel());
        Observer.Observe('default', Format(Report.DefaultLayout(Report::"LT SM LytInit Rep")));
        Observer.Observe('default-log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure MissingId_RdlcLayout_FromTestMethod()
    var
        Observer: Codeunit "Probe Observer";
        InStr: InStream;
    begin
        asserterror Report.RdlcLayout(89269, InStr);
        Observer.ObserveError('rdlc');
        Observer.Finish();
    end;

    [Test]
    procedure MissingId_WordLayout_FromTestMethod()
    var
        Observer: Codeunit "Probe Observer";
        InStr: InStream;
    begin
        asserterror Report.WordLayout(89269, InStr);
        Observer.ObserveError('word');
        Observer.Finish();
    end;

    [Test]
    procedure MissingId_ExcelLayout_FromTestMethod()
    var
        Observer: Codeunit "Probe Observer";
        InStr: InStream;
    begin
        asserterror Report.ExcelLayout(89269, InStr);
        Observer.ObserveError('excel');
        Observer.Finish();
    end;

    [Test]
    procedure MissingId_DefaultLayout_FromTestMethod()
    var
        Observer: Codeunit "Probe Observer";
        Lay: DefaultLayout;
    begin
        asserterror Lay := Report.DefaultLayout(89269);
        Observer.ObserveError('default');
        Observer.Finish();
    end;
}
