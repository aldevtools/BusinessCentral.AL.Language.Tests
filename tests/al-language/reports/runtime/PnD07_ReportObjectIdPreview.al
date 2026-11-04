// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-objectid-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained objects reports 72040 and 72041, codeunits 72042 and 72043
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles docs/probes-needed.md row: Builtins refused until a probe pins them: Report.ObjectId(UseNames) (and CurrReport.ObjectId) - Probe wanted: ObjectId(false) and ObjectId(true) of a report with and without a caption; AND Report.Preview() (CurrReport.Preview()) - Probe wanted: CurrReport.Preview() from OnPreReport in a run by Report.Execute, Report.SaveAs
// Facts: ObjectId(false) and ObjectId(true) from a Report variable and from CurrReport inside OnPreReport and OnAfterGetRecord, for a report with and without caption; CurrReport.Preview() when the report was started by Run, Execute and SaveAs. Language dependence of the text is not covered (one session language).
// BC versions: 29 (27 and 28 by CI)

codeunit 72042 "LT PnD Report Holder"
{
    SingleInstance = true;

    var
        Seen: Dictionary of [Text, Text];

    procedure ResetSeen()
    begin
        Clear(Seen);
    end;

    procedure Put(KeyName: Text; Value: Text)
    begin
        if Seen.ContainsKey(KeyName) then
            Seen.Set(KeyName, Value)
        else
            Seen.Add(KeyName, Value);
    end;

    procedure Get(KeyName: Text): Text
    begin
        if Seen.ContainsKey(KeyName) then
            exit(Seen.Get(KeyName));
        exit('<not set>');
    end;
}

report 72040 "LT PnD Rep Captioned"
{
    Caption = 'LT PnD Captioned Report';
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Item; Integer)
        {
            DataItemTableView = where(Number = const(1));

            trigger OnAfterGetRecord()
            var
                Holder: Codeunit "LT PnD Report Holder";
            begin
                Holder.Put('cap.item.false', CurrReport.ObjectId(false));
                Holder.Put('cap.item.true', CurrReport.ObjectId(true));
                Holder.Put('cap.item.preview', Format(CurrReport.Preview()));
            end;
        }
    }

    trigger OnPreReport()
    var
        Holder: Codeunit "LT PnD Report Holder";
    begin
        Holder.Put('cap.pre.false', CurrReport.ObjectId(false));
        Holder.Put('cap.pre.true', CurrReport.ObjectId(true));
        Holder.Put('cap.pre.default', CurrReport.ObjectId());
        Holder.Put('cap.pre.preview', Format(CurrReport.Preview()));
    end;
}

report 72041 "LT PnD Rep No Caption"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Item; Integer)
        {
            DataItemTableView = where(Number = const(1));
        }
    }

    trigger OnPreReport()
    var
        Holder: Codeunit "LT PnD Report Holder";
    begin
        Holder.Put('nocap.pre.false', CurrReport.ObjectId(false));
        Holder.Put('nocap.pre.true', CurrReport.ObjectId(true));
        Holder.Put('nocap.pre.preview', Format(CurrReport.Preview()));
    end;
}

codeunit 72043 "LT PnD Report ObjectId"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryExecute(ReportId: Integer)
    begin
        Report.Execute(ReportId, '');
    end;

    [TryFunction]
    local procedure TrySaveAs(ReportId: Integer; Fmt: ReportFormat)
    var
        Blob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        Blob.CreateOutStream(OutStr);
        Report.SaveAs(ReportId, '', Fmt, OutStr);
    end;

    local procedure Outcome(Ok: Boolean): Text
    begin
        if Ok then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure ObjectId_FromCurrReport_Captioned()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT PnD Report Holder";
        Rep: Report "LT PnD Rep Captioned";
    begin
        Holder.ResetSeen();
        Rep.UseRequestPage(false);
        Rep.Run();
        Observer.Observe('pre.false', Holder.Get('cap.pre.false'));
        Observer.Observe('pre.true', Holder.Get('cap.pre.true'));
        Observer.Observe('pre.default', Holder.Get('cap.pre.default'));
        Observer.Observe('item.false', Holder.Get('cap.item.false'));
        Observer.Observe('item.true', Holder.Get('cap.item.true'));
        Observer.Expect('pre.false', 'Report 72040');
        Observer.Expect('pre.true', 'Report LT PnD Captioned Report');
        Observer.Expect('pre.default', 'Report LT PnD Captioned Report');
        Observer.Expect('item.false', 'Report 72040');
        Observer.Expect('item.true', 'Report LT PnD Captioned Report');
        Observer.Verify();
    end;

    [Test]
    procedure ObjectId_FromCurrReport_NoCaption()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT PnD Report Holder";
        Rep: Report "LT PnD Rep No Caption";
    begin
        Holder.ResetSeen();
        Rep.UseRequestPage(false);
        Rep.Run();
        Observer.Observe('pre.false', Holder.Get('nocap.pre.false'));
        Observer.Observe('pre.true', Holder.Get('nocap.pre.true'));
        Observer.Expect('pre.false', 'Report 72041');
        Observer.Expect('pre.true', 'Report LT PnD Rep No Caption');
        Observer.Verify();
    end;

    [Test]
    procedure ObjectId_FromReportVariable()
    var
        Observer: Codeunit "Probe Observer";
        Cap: Report "LT PnD Rep Captioned";
        NoCap: Report "LT PnD Rep No Caption";
    begin
        Observer.Observe('cap.false', Cap.ObjectId(false));
        Observer.Observe('cap.true', Cap.ObjectId(true));
        Observer.Observe('cap.default', Cap.ObjectId());
        Observer.Observe('nocap.false', NoCap.ObjectId(false));
        Observer.Observe('nocap.true', NoCap.ObjectId(true));
        Observer.Observe('nocap.default', NoCap.ObjectId());
        Observer.Expect('cap.false', 'Report 72040');
        Observer.Expect('cap.true', 'Report LT PnD Captioned Report');
        Observer.Expect('cap.default', 'Report LT PnD Captioned Report');
        Observer.Expect('nocap.false', 'Report 72041');
        Observer.Expect('nocap.true', 'Report LT PnD Rep No Caption');
        Observer.Expect('nocap.default', 'Report LT PnD Rep No Caption');
        Observer.Verify();
    end;

    [Test]
    procedure Preview_InReportRun()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT PnD Report Holder";
        Rep: Report "LT PnD Rep Captioned";
    begin
        Holder.ResetSeen();
        Rep.UseRequestPage(false);
        Rep.Run();
        Observer.Observe('pre', Holder.Get('cap.pre.preview'));
        Observer.Observe('item', Holder.Get('cap.item.preview'));
        Observer.Expect('pre', 'No');
        Observer.Expect('item', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Preview_InReportExecute()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT PnD Report Holder";
    begin
        Holder.ResetSeen();
        Observer.Observe('execute', Outcome(TryExecute(Report::"LT PnD Rep Captioned")));
        Observer.Observe('pre', Holder.Get('cap.pre.preview'));
        Observer.Observe('item', Holder.Get('cap.item.preview'));
        Observer.Expect('execute', 'ok');
        Observer.Expect('pre', 'Yes');
        Observer.Expect('item', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Preview_InReportSaveAs()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT PnD Report Holder";
    begin
        Holder.ResetSeen();
        Observer.Observe('saveAsXml', Outcome(TrySaveAs(Report::"LT PnD Rep Captioned", ReportFormat::Xml)));
        Observer.Observe('pre', Holder.Get('cap.pre.preview'));
        Observer.Observe('item', Holder.Get('cap.item.preview'));
        Observer.Expect('saveAsXml', 'error:Report 72040 is a processing-only report. Output cannot be rendered and saved to a file.|ReportProcessingOnly');
        Observer.Expect('pre', '<not set>');
        Observer.Expect('item', '<not set>');
        Observer.Verify();
    end;

    [Test]
    procedure Preview_InReportSaveAs_Pdf_NoCaption()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT PnD Report Holder";
    begin
        Holder.ResetSeen();
        Observer.Observe('saveAsPdf', Outcome(TrySaveAs(Report::"LT PnD Rep No Caption", ReportFormat::Pdf)));
        Observer.Observe('pre', Holder.Get('nocap.pre.preview'));
        Observer.Observe('ids.false', Holder.Get('nocap.pre.false'));
        Observer.Expect('saveAsPdf', 'error:Report 72041 is a processing-only report. Output cannot be rendered and saved to a file.|ReportProcessingOnly');
        Observer.Expect('pre', '<not set>');
        Observer.Expect('ids.false', '<not set>');
        Observer.Verify();
    end;
}
