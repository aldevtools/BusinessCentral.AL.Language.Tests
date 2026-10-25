// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); tables and helper of P105Fix.al; own report 89243, test codeunit 89244 and its log 89260 (SingleInstance, text only: it survives asserterror and is used by codeunit 89244 alone)
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
        Log: Codeunit "LT SM LytInit Log";
    begin
        Log.Add('OnInitReport');
    end;

    trigger OnPreReport()
    var
        Log: Codeunit "LT SM LytInit Log";
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
        Log: Codeunit "LT SM LytInit Log";

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
        InStr: InStream;
    begin
        Helper.Seed();
        Log.Reset();
        asserterror Rpt.RdlcLayout(InStr);
        Observer.Observe('rdlc', GetLastErrorCode());
        Observer.Observe('rdlc-log', Log.Dump());
        Log.Reset();
        asserterror Rpt.WordLayout(InStr);
        Observer.Observe('word', GetLastErrorCode());
        Observer.Observe('word-log', Log.Dump());
        Log.Reset();
        asserterror Rpt.ExcelLayout(InStr);
        Observer.Observe('excel', GetLastErrorCode());
        Observer.Observe('excel-log', Log.Dump());
        Log.Reset();
        Observer.Observe('default', Format(Rpt.DefaultLayout()));
        Observer.Observe('default-log', Log.Dump());
        Log.Reset();
        Rpt.UseRequestPage(false);
        Rpt.Execute('');
        Observer.Observe('execute-log', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure FreshInstance_DefaultLayoutThenExecute_OnInitReport()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT SM LytInit Rep";
    begin
        Helper.Seed();
        Log.Reset();
        Observer.Observe('default', Format(Rpt.DefaultLayout()));
        Observer.Observe('default-log', Log.Dump());
        Log.Reset();
        Rpt.UseRequestPage(false);
        Rpt.Execute('');
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
        Observer.Expect('rdlc', 'No ReportNoLayout');
        Observer.Expect('rdlc-log', '');
        Observer.Expect('word', 'No ReportNoLayout');
        Observer.Expect('word-log', '');
        Observer.Expect('excel', 'No ReportNoLayout');
        Observer.Expect('excel-log', '');
        Observer.Expect('default', 'None');
        Observer.Expect('default-log', '');
        Observer.Verify();
    end;

    [Test]
    procedure MissingId_RdlcLayout_FromTestMethod()
    var
        Observer: Codeunit "Probe Observer";
        InStr: InStream;
    begin
        asserterror Report.RdlcLayout(89269, InStr);
        Observer.ObserveError('rdlc');
#if BC28PLUS
        Observer.Expect('rdlc|text', 'You tried to invoke the Report object with the ID 89269 from the object LT SM LytInit Tests. An object with that ID does not exist in the current application compiled with emit version n.');
#else
        Observer.Expect('rdlc|text', 'You tried to invoke the Report object with the ID 89269 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
#endif
        Observer.Expect('rdlc|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure MissingId_WordLayout_FromTestMethod()
    var
        Observer: Codeunit "Probe Observer";
        InStr: InStream;
    begin
        asserterror Report.WordLayout(89269, InStr);
        Observer.ObserveError('word');
#if BC28PLUS
        Observer.Expect('word|text', 'You tried to invoke the Report object with the ID 89269 from the object LT SM LytInit Tests. An object with that ID does not exist in the current application compiled with emit version n.');
#else
        Observer.Expect('word|text', 'You tried to invoke the Report object with the ID 89269 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
#endif
        Observer.Expect('word|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure MissingId_ExcelLayout_FromTestMethod()
    var
        Observer: Codeunit "Probe Observer";
        InStr: InStream;
    begin
        asserterror Report.ExcelLayout(89269, InStr);
        Observer.ObserveError('excel');
#if BC28PLUS
        Observer.Expect('excel|text', 'You tried to invoke the Report object with the ID 89269 from the object LT SM LytInit Tests. An object with that ID does not exist in the current application compiled with emit version n.');
#else
        Observer.Expect('excel|text', 'You tried to invoke the Report object with the ID 89269 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
#endif
        Observer.Expect('excel|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure MissingId_DefaultLayout_FromTestMethod()
    var
        Observer: Codeunit "Probe Observer";
        Lay: DefaultLayout;
    begin
        asserterror Lay := Report.DefaultLayout(89269);
        Observer.ObserveError('default');
#if BC28PLUS
        Observer.Expect('default|text', 'You tried to invoke the Report object with the ID 89269 from the object LT SM LytInit Tests. An object with that ID does not exist in the current application compiled with emit version n.');
#else
        Observer.Expect('default|text', 'You tried to invoke the Report object with the ID 89269 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
#endif
        Observer.Expect('default|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;
}

codeunit 89260 "LT SM LytInit Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Reset()
    begin
        Entries := '';
    end;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ';';
        Entries += Entry;
    end;

    procedure Dump(): Text
    begin
        exit(Entries);
    end;
}
