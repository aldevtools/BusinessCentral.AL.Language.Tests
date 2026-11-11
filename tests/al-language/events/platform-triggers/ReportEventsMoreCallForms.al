// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-execute-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); Temp Blob (System Application); from events/platform-triggers: codeunit "LT V Log",
//   report "LT V Report A" (RDLC layout) with its automatic Reporting Triggers subscribers, the manual subscriber codeunit "LT PW V Arg Subs";
//   table "Probe Rep Parent" (text/TestReportSaveAsDatasetContracts.al); report "LT AM Word Rpt" (reports/layouts-saveas, a Word layout);
//   own codeunit 96630.
// Probe: from the code-sweep issues al-runner 7634 and 7608 (cell d): which Reporting Triggers events the call forms raise that
//   events/platform-triggers/PeVTests.al does not pin, and the RecordRef SubstituteReport gets. Observation form: every test ends in
//   Observer.Finish(), so its failure message holds BC's values.
// Area (Xml only, so the Linux tier renders nothing):
//   - Report.Execute(Number, '', RecordRef) and Report.Execute(Number, Parameters, RecordRef): SubstituteReport's RunMode, RequestPageXml and
//     RecordRef.Number, then the events raised;
//   - the variable form ReportVariable.SaveAs(Parameters, Xml, OutStream) with the parameters RunRequestPage returned;
//   - Report.SaveAs Xml of a report whose default layout is Word.
// BC versions: 27.5, 28.5, 29.0 (to be measured by the corpus CI)

codeunit 96630 "LT REV More Forms"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT V Log";

    local procedure Seed()
    var
        Parent: Record "Probe Rep Parent";
    begin
        Parent.DeleteAll();
        Parent.Id := 1;
        Parent.Name := 'one';
        Parent.Insert();
        Parent.Id := 2;
        Parent.Name := 'two';
        Parent.Insert();
        Commit();
    end;

    [TryFunction]
    local procedure TryCall(Which: Text; Parameters: Text)
    var
        Rep: Report "LT V Report A";
        Parent: Record "Probe Rep Parent";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        Parent.SetRange(Id, 1);
        RecRef.GetTable(Parent);
        case Which of
            'execute static empty recref':
                Report.Execute(Report::"LT V Report A", '', RecRef);
            'execute static params recref':
                Report.Execute(Report::"LT V Report A", Parameters, RecRef);
            'saveas var params xml':
                Rep.SaveAs(Parameters, ReportFormat::Xml, OutStr);
            'saveas static word layout xml':
                Report.SaveAs(Report::"LT AM Word Rpt", '', ReportFormat::Xml, OutStr);
        end;
    end;

    local procedure CallCase(var Observer: Codeunit "Probe Observer"; Which: Text; Parameters: Text)
    var
        ArgSubs: Codeunit "LT PW V Arg Subs";
        Ok: Boolean;
    begin
        BindSubscription(ArgSubs);
        Log.Start();
        Log.SetValue('pwcollect', 'yes');
        ClearLastError();
        Ok := TryCall(Which, Parameters);
        Observer.Observe(Which + ' ok', Format(Ok));
        if not Ok then
            Observer.ObserveError(Which);
        Observer.Observe(Which + ' args', Log.GetValue('pwargs'));
        Observer.Observe(Which + ' events', Log.Take());
        Log.Stop();
        UnbindSubscription(ArgSubs);
    end;

    [Test]
    [HandlerFunctions('RequestPageA')]
    procedure REV_Execute_WithRecordRef_SubstituteArgsAndEvents()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"LT V Report A");
        CallCase(Observer, 'execute static empty recref', '');
        CallCase(Observer, 'execute static params recref', Parameters);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RequestPageA')]
    procedure REV_SaveAs_VariableWithParameters_AndWordLayoutXml()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"LT V Report A");
        CallCase(Observer, 'saveas var params xml', Parameters);
        CallCase(Observer, 'saveas static word layout xml', '');
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure RequestPageA(var Request: TestRequestPage "LT V Report A")
    begin
        Request.OK().Invoke();
    end;
}
