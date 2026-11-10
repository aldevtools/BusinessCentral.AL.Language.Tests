// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160), W3 Dataset (67703); cross-app fixtures tests/al-language-xapp-a/R7358XaIndependentReports.al
//   (reports 97994 and 97995, log 97993), xapp-b/R7358XbIndependentReportExts.al (extensions 96296 and 96297),
//   xapp-d/R7358XdIndependentReportExts.al (extensions 96306 and 61165).
// Area: two report extensions of one report from apps that do not depend on each other (al-runner issue 7358; B and D both depend
//   on A only). Each extension adds a column with add(), a data item with addfirst, addlast,
//   addbefore and addafter, the six modify() triggers, a request page field after the same base field, a label, OnPreReport and
//   OnPostReport.
//   Observed for both reports: Report.WordXmlPart (the order of the added data items), the data items and columns of the
//   SaveAs Xml dataset in document order, the trigger log of that run, and for the request page the OnOpenPage and OnClosePage
//   order and the order of the fields in the parameters text.
//   The two reports swap the order of the extension object ids and of the extension names (see the fixture file of app A), so
//   the results tell an order by app from an order by extension id or name.
// Already pinned elsewhere: extensions of apps that a dependency path orders (reports/extensions/Y64XappRunOrder.al).
// BC versions: 27-29
codeunit 62360 "RPT Indep Ext Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "RPT XA Indep Log";

    // The DataItem and Column names of a dataset in document order: 'Head[' for a data item, 'HeadNo,' for a column.
    local procedure Names(Xml: Text): Text
    var
        Dataset: Codeunit "W3 Dataset";
        Line: Text;
        Result: Text;
    begin
        foreach Line in Xml.Split(Dataset.Lf()) do begin
            Line := Line.Trim();
            if Line.StartsWith('<DataItem ') then
                Result += ' ' + Between(Line, 'name="', '"') + '[';
            if Line.StartsWith('<Column ') then
                Result += Between(Line, 'name="', '"') + ',';
            if Line.StartsWith('</DataItem>') then
                Result += ']';
        end;
        exit(Result);
    end;

    local procedure Between(Value: Text; StartTag: Text; EndTag: Text): Text
    var
        At: Integer;
    begin
        At := Value.IndexOf(StartTag);
        if At = 0 then
            exit('');
        Value := Value.Substring(At + StrLen(StartTag));
        At := Value.IndexOf(EndTag);
        if At = 0 then
            exit(Value);
        exit(Value.Substring(1, At - 1));
    end;

    local procedure ObserveDataset(ReportId: Integer)
    var
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
        Ok: Boolean;
    begin
        Log.Take();
        Ok := Dataset.Save(ReportId, '', Xml);
        Observer.Observe('saved', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('dataset names', Names(Xml));
        Observer.Observe('log', Log.Take());
    end;

    local procedure ObserveRequestPage(ReportId: Integer)
    var
        Parameters: Text;
    begin
        Log.Take();
        Parameters := Report.RunRequestPage(ReportId);
        Observer.Observe('log', Log.Take());
        Observer.Observe('options', Between(Parameters, '<Options>', '</Options>'));
    end;

    [Test]
    procedure IndependentApps_ReportOne_WordXmlPart()
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"RPT XA Indep One"));
        Observer.Ignore('part'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

    [Test]
    procedure IndependentApps_ReportOne_WordXmlPart_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure IndependentApps_ReportOne_DatasetAndTriggerOrder()
    begin
        ObserveDataset(Report::"RPT XA Indep One");
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('dataset names', ' Head[HeadNo,HeadText,BCol,DCol, DFirst[DFirstNo,] BFirst[BFirstNo,] BBefore[BBeforeNo,] DBefore[DBeforeNo,] Inner[InnerNo,] DAfter[DAfterNo,] BAfter[BAfterNo,] BLast[BLastNo,] DLast[DLastNo,]] Tail[TailNo,]');
        Observer.Expect('log', 'A:init;A:pre;B:pre;D:pre;B:Head OnBeforePreDataItem;D:Head OnBeforePreDataItem;A:Head pre;B:Head OnAfterPreDataItem;D:Head OnAfterPreDataItem;B:Head OnBeforeAfterGetRecord;D:Head OnBeforeAfterGetRecord;A:Head row;B:Head OnAfterAfterGetRecord;D:Head OnAfterAfterGetRecord;D:First row;B:First row;B:Before row;D:Before row;A:Inner row;D:After row;B:After row;B:Last row;D:Last row;B:Head OnBeforePostDataItem;D:Head OnBeforePostDataItem;A:Head post;B:Head OnAfterPostDataItem;D:Head OnAfterPostDataItem;A:Tail row;A:post;B:post;D:post;');
        Observer.Verify();
    end;

    [Test]
    procedure IndependentApps_ReportOne_DatasetAndTriggerOrder_More1()
    begin
        Observer.More();
    end;

    [Test]
    [HandlerFunctions('OneHandler')]
    procedure IndependentApps_ReportOne_RequestPageOrder()
    begin
        ObserveRequestPage(Report::"RPT XA Indep One");
        Observer.Expect('log', 'A:init;A:rp open;B:rp open;D:rp open;A:rp close;B:rp close;D:rp close;');
        Observer.Expect('options', '<Field name="BaseOptionValue">false</Field><Field name="BFieldValue">false</Field><Field name="DFieldValue">false</Field>');
        Observer.Verify();
    end;

    [Test]
    procedure IndependentApps_ReportTwo_WordXmlPart()
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"RPT XA Indep Two"));
        Observer.Ignore('part'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

    [Test]
    procedure IndependentApps_ReportTwo_WordXmlPart_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure IndependentApps_ReportTwo_DatasetAndTriggerOrder()
    begin
        ObserveDataset(Report::"RPT XA Indep Two");
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('dataset names', ' Head[HeadNo,HeadText,BCol,DCol, DFirst[DFirstNo,] BFirst[BFirstNo,] BBefore[BBeforeNo,] DBefore[DBeforeNo,] Inner[InnerNo,] DAfter[DAfterNo,] BAfter[BAfterNo,] BLast[BLastNo,] DLast[DLastNo,]] Tail[TailNo,]');
        Observer.Expect('log', 'A:init;A:pre;B:pre;D:pre;B:Head OnBeforePreDataItem;D:Head OnBeforePreDataItem;A:Head pre;B:Head OnAfterPreDataItem;D:Head OnAfterPreDataItem;B:Head OnBeforeAfterGetRecord;D:Head OnBeforeAfterGetRecord;A:Head row;B:Head OnAfterAfterGetRecord;D:Head OnAfterAfterGetRecord;D:First row;B:First row;B:Before row;D:Before row;A:Inner row;D:After row;B:After row;B:Last row;D:Last row;B:Head OnBeforePostDataItem;D:Head OnBeforePostDataItem;A:Head post;B:Head OnAfterPostDataItem;D:Head OnAfterPostDataItem;A:Tail row;A:post;B:post;D:post;');
        Observer.Verify();
    end;

    [Test]
    procedure IndependentApps_ReportTwo_DatasetAndTriggerOrder_More1()
    begin
        Observer.More();
    end;

    [Test]
    [HandlerFunctions('TwoHandler')]
    procedure IndependentApps_ReportTwo_RequestPageOrder()
    begin
        ObserveRequestPage(Report::"RPT XA Indep Two");
        Observer.Expect('log', 'A:init;A:rp open;B:rp open;D:rp open;A:rp close;B:rp close;D:rp close;');
        Observer.Expect('options', '<Field name="BaseOptionValue">false</Field><Field name="BFieldValue">false</Field><Field name="DFieldValue">false</Field>');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure OneHandler(var RP: TestRequestPage "RPT XA Indep One")
    begin
        RP.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure TwoHandler(var RP: TestRequestPage "RPT XA Indep Two")
    begin
        RP.OK().Invoke();
    end;
}
