// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160), W3 Dataset (67703); cross-app fixtures tests/al-language-xapp-a/R7358XaOrderRule.al
//   (report 97996, log 97993) and the extensions R7358X<b,d,e,f>OrderRule.al in apps B, D, E and F.
// Area: the rule that orders the report extensions of apps with no dependency path between them (al-runner issue 7358). Four
//   apps extend one report; each candidate rule (app id as text, as Guid bytes, as a SQL Server uniqueidentifier, app name,
//   publisher, publish order, extension object id, extension name) predicts another order of the four (see the fixture file
//   of app A). Observed: the columns of the SaveAs Xml dataset in document order, the order of the OnPreReport triggers, the
//   order of the labels in the dataset, and for the request page the OnOpenPage and OnClosePage order and the order of the
//   fields in the parameters text (each app adds one field after the same base field).
//   Also the label order of the two-app reports 97994 and 97995 (B and D; their extensions each declare one label).
// Already pinned elsewhere: two apps, B before D, for the dataset, the triggers, the request page and Report.WordXmlPart
//   (reports/extensions/IndependentAppsReportExtensions.al).
// BC versions: 27-29
codeunit 62361 "RPT Order Rule Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The Column names of a dataset in document order, each followed by a comma.
    local procedure Columns(Xml: Text): Text
    var
        Dataset: Codeunit "W3 Dataset";
        Line: Text;
        Result: Text;
        At: Integer;
    begin
        foreach Line in Xml.Split(Dataset.Lf()) do begin
            Line := Line.Trim();
            if Line.StartsWith('<Column ') then begin
                At := Line.IndexOf('name="');
                if At > 0 then begin
                    Line := Line.Substring(At + StrLen('name="'));
                    Result += Line.Substring(1, Line.IndexOf('"') - 1) + ',';
                end;
            end;
        end;
        exit(Result);
    end;

    [Test]
    procedure OrderRule_DatasetColumns()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "RPT XA Indep Log";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        Log.Take();
        Observer.Observe('saved', Format(Dataset.Save(Report::"RPT XA Order Rule", '', Xml)));
        Observer.Observe('columns', Columns(Xml));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('columns', 'HeadNo,ECol,BCol,DCol,FCol,');
        Observer.Verify();
    end;

    [Test]
    procedure OrderRule_OnPreReportTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "RPT XA Indep Log";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        Log.Take();
        Observer.Observe('saved', Format(Dataset.Save(Report::"RPT XA Order Rule", '', Xml)));
        Observer.Observe('log', Log.Take());
        Observer.Expect('saved', 'Yes');
        Observer.Expect('log', 'A:pre;E:pre;B:pre;D:pre;F:pre;');
        Observer.Verify();
    end;

    // The Label names of a dataset in document order, each followed by a comma.
    local procedure LabelNames(Xml: Text): Text
    var
        Dataset: Codeunit "W3 Dataset";
        Line: Text;
        Result: Text;
        At: Integer;
    begin
        foreach Line in Xml.Split(Dataset.Lf()) do begin
            Line := Line.Trim();
            if Line.StartsWith('<Label ') then begin
                At := Line.IndexOf('name="');
                if At > 0 then begin
                    Line := Line.Substring(At + StrLen('name="'));
                    Result += Line.Substring(1, Line.IndexOf('"') - 1) + ',';
                end;
            end;
        end;
        exit(Result);
    end;

    local procedure ObserveLabels(ReportId: Integer; Expected: Text)
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        Observer.Observe('saved', Format(Dataset.Save(ReportId, '', Xml)));
        Observer.Observe('labels', LabelNames(Xml));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('labels', Expected);
        Observer.Verify();
    end;

    [Test]
    procedure OrderRule_Labels()
    begin
        ObserveLabels(Report::"RPT XA Order Rule", 'BaseLabel,ELabel,BLabel,DLabel,FLabel,');
    end;

    [Test]
    procedure TwoApps_ReportOne_Labels()
    begin
        ObserveLabels(Report::"RPT XA Indep One", 'BaseLabel,BLabel,DLabel,');
    end;

    [Test]
    procedure TwoApps_ReportTwo_Labels()
    begin
        ObserveLabels(Report::"RPT XA Indep Two", 'BaseLabel,BLabel,DLabel,');
    end;

    [Test]
    [HandlerFunctions('OrderRuleHandler')]
    procedure OrderRule_RequestPage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "RPT XA Indep Log";
        Parameters: Text;
        At: Integer;
    begin
        Log.Take();
        Parameters := Report.RunRequestPage(Report::"RPT XA Order Rule");
        Observer.Observe('log', Log.Take());
        At := Parameters.IndexOf('<Options>');
        if At > 0 then begin
            Parameters := Parameters.Substring(At + StrLen('<Options>'));
            At := Parameters.IndexOf('</Options>');
            if At > 0 then
                Parameters := Parameters.Substring(1, At - 1);
        end;
        Observer.Observe('options', Parameters);
        Observer.Expect('log', 'A:rp open;E:rp open;B:rp open;D:rp open;F:rp open;A:rp close;E:rp close;B:rp close;D:rp close;F:rp close;');
        Observer.Expect('options', '<Field name="BaseOptionValue">false</Field><Field name="EFieldValue">false</Field><Field name="BFieldValue">false</Field><Field name="DFieldValue">false</Field><Field name="FFieldValue">false</Field>');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure OrderRuleHandler(var RP: TestRequestPage "RPT XA Order Rule")
    begin
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('OkRunHandler')]
    procedure OrderRule_RunModal_RequestPageOk()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "RPT XA Indep Log";
    begin
        Log.Take();
        Report.RunModal(Report::"RPT XA Order Rule", true);
        Observer.Observe('until handler', HandlerLog);
        Observer.Observe('after handler', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CancelRunHandler')]
    procedure OrderRule_RunModal_RequestPageCancel()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "RPT XA Indep Log";
    begin
        Log.Take();
        Report.RunModal(Report::"RPT XA Order Rule", true);
        Observer.Observe('until handler', HandlerLog);
        Observer.Observe('after handler', Log.Take());
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure OkRunHandler(var RP: TestRequestPage "RPT XA Order Rule")
    var
        Log: Codeunit "RPT XA Indep Log";
    begin
        HandlerLog := Log.Take();
        RP.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CancelRunHandler(var RP: TestRequestPage "RPT XA Order Rule")
    var
        Log: Codeunit "RPT XA Indep Log";
    begin
        HandlerLog := Log.Take();
        RP.Cancel().Invoke();
    end;

    var
        HandlerLog: Text;
}
