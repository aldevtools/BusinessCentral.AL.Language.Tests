// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-formatregion-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT Y Helper (75500, report/lt-y-report-props/YHelper.al); objects of BdRegionReports.al and BdRegionFixtures.al
// Probe: corpus issue 657. Every literal asserted below is what the BC tiers of the corpus matrix produced.
// Facts: a report with the FormatRegion property: the header of its SaveAs Xml dataset, its dataset columns and Format() in OnInitReport, OnPreReport,
// OnAfterGetRecord and OnPostReport for 14 property values; the same report started with Run, RunModal, Execute, SaveAs Pdf/Word/Excel/Html and
// through a request page; CurrReport.FormatRegion := for 14 values (SaveAs Xml and Run), after CurrReport.Language :=, and inside a report that has
// the property; the decimalformatter of Decimal columns; SummaryML of layouts in several languages.
// SaveAs Pdf/Word/Excel/Html: asserted with the Windows BC 27.5/28.5/29.0 values (Windows checks 2026-10-20; 29.0 gives the same values) and
// held on Linux (not compiled) until the bc-linux pin in ci.yml rendered RDLC to Word and Excel (bc-linux #144 on 27/28,
// #143 on 29, renderer off at boot).
// BC versions: 27-29

codeunit 81070 "BD Region Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "BD Region Helper";
        Log: Codeunit "BD Region Log";
        ReqLog: Text;

    [TryFunction]
    local procedure TrySaveAsXml(ReportId: Integer; var Xml: Text)
    begin
        Xml := Helper.SaveAsXml(ReportId);
    end;

    local procedure Dataset(var Observer: Codeunit "Probe Observer"; ReportId: Integer)
    var
        Xml: Text;
    begin
        ClearLastError();
        if TrySaveAsXml(ReportId, Xml) then begin
            Observer.Observe('header', Helper.HeaderFacts(Xml));
            Observer.Observe('columns', Helper.Columns(Xml));
        end else
            Observer.ObserveError('saveas');
        Observer.Observe('log', Log.Take());
    end;

    [TryFunction]
    local procedure TryRun(ReportId: Integer)
    begin
        Report.Run(ReportId, false);
    end;

    [TryFunction]
    local procedure TryRunModal(ReportId: Integer)
    begin
        Report.RunModal(ReportId, false);
    end;

    [TryFunction]
    local procedure TryExecute(ReportId: Integer)
    begin
        Report.Execute(ReportId, '');
    end;

    [TryFunction]
    local procedure TrySaveAs(ReportId: Integer; Fmt: ReportFormat; var Size: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(ReportId, '', Fmt, OutS);
        Size := TempBlob.Length();
    end;

    local procedure RunWay(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean)
    begin
        Observer.Observe(Name + ' ok', Format(Ok));
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' log', Log.Take());
    end;

    local procedure SaveAsWay(var Observer: Codeunit "Probe Observer"; Fmt: ReportFormat)
    var
        Size: Integer;
        Ok: Boolean;
    begin
        Log.Take();
        ClearLastError();
        Ok := TrySaveAs(Report::"BD Region De", Fmt, Size);
        Observer.Observe(Format(Fmt) + ' ok', Format(Ok));
        Observer.Observe(Format(Fmt) + ' has output', Format(Size > 0));
        Observer.ObserveError(Format(Fmt));
        Observer.Observe(Format(Fmt) + ' log', Log.Take());
    end;

    local procedure Setter(var Observer: Codeunit "Probe Observer"; Region: Text; RegionSet: Boolean; Language: Integer)
    begin
        Log.SetCulture(Region, RegionSet, Language);
        Dataset(Observer, Report::"BD Region Setter");
        Log.SetCulture(Region, RegionSet, Language);
        ClearLastError();
        RunWay(Observer, 'run', TryRun(Report::"BD Region Setter Proc"));
        Log.SetCulture('', false, 0);
    end;

    // Setter in two tests (the dataset part, then the run part) where one message would pass 1800 characters.
    local procedure SetterDataset(var Observer: Codeunit "Probe Observer"; Region: Text; RegionSet: Boolean; Language: Integer)
    begin
        Log.SetCulture(Region, RegionSet, Language);
        Dataset(Observer, Report::"BD Region Setter");
        Log.SetCulture('', false, 0);
    end;

    local procedure SetterRun(var Observer: Codeunit "Probe Observer"; Region: Text; RegionSet: Boolean; Language: Integer)
    begin
        Log.SetCulture(Region, RegionSet, Language);
        ClearLastError();
        RunWay(Observer, 'run', TryRun(Report::"BD Region Setter Proc"));
        Log.SetCulture('', false, 0);
    end;

    [Test]
    procedure BdProperty_De_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region De");
#if BC29PLUS
        Observer.Expect('header', '<ReportDataSet name="BD Region De id:81052 language="en-US formatRegion="de-DE">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region De</ReportName>|<ReportCaption>BD Region De</ReportCaption>|<Language>en-US</Language>|<FormatRegion>de-DE</FormatRegion>|');
#else
        Observer.Expect('header', '<ReportDataSet name="BD Region De id:81052 language="en-US formatRegion="de-DE">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region De</ReportName>|<Language>en-US</Language>|<FormatRegion>de-DE</FormatRegion>|');
#endif
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=-1234,5;D1Col=31.01.2025;D2Col=05.03.2024;DT1Col=31.01.2025 14:30:15;DT2Col=05.03.2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;IntCol=-1234567;TextsCol=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Expect('log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567 region=[de-DE];get=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567 region=[de-DE];post=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Verify();
    end;

    [Test]
    procedure BdProperty_Gb_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region Gb");
#if BC29PLUS
        // Windows BC 29.0 check 2026-10-20 (bump 34 queue): every key measured (Windows NLS culture data; U+00A0 is a no-break space).
        // The Linux image at dbee8022 gives the same values (corpus CI 2026-10-20), so BC 29 has no hold.
        Observer.Expect('header', '<ReportDataSet name="BD Region Gb id:81053 language="en-US formatRegion="en-GB">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Gb</ReportName>|<ReportCaption>BD Region Gb</ReportCaption>|<Language>en-US</Language>|<FormatRegion>en-GB</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567.891;NegCol[decimalformatter:#,##0.00=-1234.5;D1Col=31/01/2025;D2Col=05/03/2024;DT1Col=31/01/2025 14:30:15;DT2Col=05/03/2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;IntCol=-1234567;TextsCol=1,234,567.891#-1,234.5#31/01/25#05/03/24#05 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Expect('log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1,234,567.891#-1,234.5#31/01/25#05/03/24#05 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07#-1234567 region=[en-GB];get=1,234,567.891#-1,234.5#31/01/25#05/03/24#05 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07#-1234567 region=[en-GB];post=1,234,567.891#-1,234.5#31/01/25#05/03/24#05 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Verify();
#elif LT_HELD_BCLINUX_157
        // Held on Linux (LT_HELD_BCLINUX_157): these are the Linux values of the image before the bc-linux #157 fix. The image at dbee8022 formats
        // as Windows does, and the Windows runs (2026-10-20) differ from these values, but only the first difference was measured. Re-assert with
        // the full Windows values after the Windows check (windows-queue), then remove this hold; it does not end when bc-linux #157 closes.
        Observer.Expect('header', '<ReportDataSet name="BD Region Gb id:81053 language="en-US formatRegion="en-GB">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Gb</ReportName>|<Language>en-US</Language>|<FormatRegion>en-GB</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567.891;NegCol[decimalformatter:#,##0.00=-1234.5;D1Col=31/01/2025;D2Col=05/03/2024;DT1Col=31/01/2025 14:30:15;DT2Col=05/03/2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;IntCol=-1234567;TextsCol=1,234,567.891#-1,234.5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Expect('log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1,234,567.891#-1,234.5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07#-1234567 region=[en-GB];get=1,234,567.891#-1,234.5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07#-1234567 region=[en-GB];post=1,234,567.891#-1,234.5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Verify();
#else
        Observer.Discard();
#endif
    end;

    [Test]
    procedure BdProperty_Fr_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region Fr");
#if BC29PLUS
        // Windows BC 29.0 check 2026-10-20 (bump 34 queue): every key measured (Windows NLS culture data; U+00A0 is a no-break space).
        // It was held on Linux BC 29 under bc-linux #167 (LT_HELD_BCLINUX_167); lifted with the bc-linux pin bcc60c1c (corpus bump 42).
        Observer.Expect('header', '<ReportDataSet name="BD Region Fr id:81054 language="en-US formatRegion="fr-FR">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Fr</ReportName>|<ReportCaption>BD Region Fr</ReportCaption>|<Language>en-US</Language>|<FormatRegion>fr-FR</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=-1234,5;D1Col=31/01/2025;D2Col=05/03/2024;DT1Col=31/01/2025 14:30:15;DT2Col=05/03/2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;IntCol=-1234567;TextsCol=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Expect('log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07#-1234567 region=[fr-FR];get=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07#-1234567 region=[fr-FR];post=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Verify();
#else
        // BC 27 and 28: the fr-FR group separator is U+00A0 as on Windows BC 27.5 and 28.5 (Windows runs 2026-10-20 and 2026-10-22: only
        // U+00A0 occurs) and on bc-linux dc007079 (bc-linux #174); the older Linux image gave U+202F.
        Observer.Expect('header', '<ReportDataSet name="BD Region Fr id:81054 language="en-US formatRegion="fr-FR">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Fr</ReportName>|<Language>en-US</Language>|<FormatRegion>fr-FR</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=-1234,5;D1Col=31/01/2025;D2Col=05/03/2024;DT1Col=31/01/2025 14:30:15;DT2Col=05/03/2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;IntCol=-1234567;TextsCol=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Expect('log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07#-1234567 region=[fr-FR];get=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07#-1234567 region=[fr-FR];post=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure BdProperty_Jp_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region Jp");
#if BC29PLUS
        Observer.Expect('header', '<ReportDataSet name="BD Region Jp id:81055 language="en-US formatRegion="ja-JP">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Jp</ReportName>|<ReportCaption>BD Region Jp</ReportCaption>|<Language>en-US</Language>|<FormatRegion>ja-JP</FormatRegion>|');
#else
        Observer.Expect('header', '<ReportDataSet name="BD Region Jp id:81055 language="en-US formatRegion="ja-JP">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Jp</ReportName>|<Language>en-US</Language>|<FormatRegion>ja-JP</FormatRegion>|');
#endif
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567.891;NegCol[decimalformatter:#,##0.00=-1234.5;D1Col=2025/01/31;D2Col=2024/03/05;DT1Col=2025/01/31 14:30:15;DT2Col=2024/03/05 9:05:07;T1Col=14:30:15;T2Col=9:05:07;IntCol=-1234567;TextsCol=1,234,567.891#-1,234.5#25/01/31#24/03/05#2024年3月5日#25/01/31 14:30#24/03/05 09:05#14:30:15# 9:05:07#-1234567;');
        Observer.Expect('log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1,234,567.891#-1,234.5#25/01/31#24/03/05#2024年3月5日#25/01/31 14:30#24/03/05 09:05#14:30:15# 9:05:07#-1234567 region=[ja-JP];get=1,234,567.891#-1,234.5#25/01/31#24/03/05#2024年3月5日#25/01/31 14:30#24/03/05 09:05#14:30:15# 9:05:07#-1234567 region=[ja-JP];post=1,234,567.891#-1,234.5#25/01/31#24/03/05#2024年3月5日#25/01/31 14:30#24/03/05 09:05#14:30:15# 9:05:07#-1234567;');
        Observer.Verify();
    end;

    [Test]
    procedure BdProperty_Zz_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region Zz");
#if BC29PLUS
        // Windows BC 29.0 check 2026-10-20 (bump 34 queue): every key measured (Windows NLS culture data; U+00A0 is a no-break space).
        // It was held on Linux BC 29 under bc-linux #167 (LT_HELD_BCLINUX_167); lifted with the bc-linux pin bcc60c1c (corpus bump 42).
        Observer.Expect('header', '<ReportDataSet name="BD Region Zz id:81056 language="en-US formatRegion="zz-ZZ">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Zz</ReportName>|<ReportCaption>BD Region Zz</ReportCaption>|<Language>en-US</Language>|<FormatRegion>zz-ZZ</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567.891;NegCol[decimalformatter:#,##0.00=-1234.5;D1Col=01/31/2025;D2Col=03/05/2024;DT1Col=01/31/2025 14:30:15;DT2Col=03/05/2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;IntCol=-1234567;TextsCol=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567;');
        Observer.Expect('log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[zz-ZZ];get=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[zz-ZZ];post=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567;');
        Observer.Verify();
#else
        Observer.Expect('header', '<ReportDataSet name="BD Region Zz id:81056 language="en-US formatRegion="zz-ZZ">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Zz</ReportName>|<Language>en-US</Language>|<FormatRegion>zz-ZZ</FormatRegion>|');
        // BC 27 and 28: the date columns are 01/31/2025 and 03/05/2024, as on BC 29: Windows BC 27.5 and 28.5 (full corpus runs on the Windows
        // containers, 2026-10-20) and bc-linux bcc60c1c. Older bc-linux images gave 1/31/2025 and 3/5/2024.
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567.891;NegCol[decimalformatter:#,##0.00=-1234.5;D1Col=01/31/2025;D2Col=03/05/2024;DT1Col=01/31/2025 14:30:15;DT2Col=03/05/2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;IntCol=-1234567;TextsCol=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567;');
        Observer.Expect('log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[zz-ZZ];get=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[zz-ZZ];post=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567;');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure BdProperty_Dk_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region Dk");
#if BC29PLUS
        // Windows BC 29.0 check 2026-10-20 (bump 34 queue): every key measured (Windows NLS culture data; U+00A0 is a no-break space).
        // The Linux image at dbee8022 gives the same values (corpus CI 2026-10-20), so BC 29 has no hold.
        Observer.Expect('header', '<ReportDataSet name="BD Region Dk id:81057 language="en-US formatRegion="da-DK">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Dk</ReportName>|<ReportCaption>BD Region Dk</ReportCaption>|<Language>en-US</Language>|<FormatRegion>da-DK</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=-1234,5;D1Col=31-01-2025;D2Col=05-03-2024;DT1Col=31-01-2025 14:30:15;DT2Col=05-03-2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;IntCol=-1234567;TextsCol=1.234.567,891#-1.234,5#31-01-25#05-03-24#5. March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Expect('log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1.234.567,891#-1.234,5#31-01-25#05-03-24#5. March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07#-1234567 region=[da-DK];get=1.234.567,891#-1.234,5#31-01-25#05-03-24#5. March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07#-1234567 region=[da-DK];post=1.234.567,891#-1.234,5#31-01-25#05-03-24#5. March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Verify();
#elif LT_HELD_BCLINUX_157
        // Held on Linux (LT_HELD_BCLINUX_157): these are the Linux values of the image before the bc-linux #157 fix. The image at dbee8022 formats
        // as Windows does, and the Windows runs (2026-10-20) differ from these values, but only the first difference was measured. Re-assert with
        // the full Windows values after the Windows check (windows-queue), then remove this hold; it does not end when bc-linux #157 closes.
        Observer.Expect('header', '<ReportDataSet name="BD Region Dk id:81057 language="en-US formatRegion="da-DK">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Dk</ReportName>|<Language>en-US</Language>|<FormatRegion>da-DK</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=-1234,5;D1Col=31-01-2025;D2Col=05-03-2024;DT1Col=31-01-2025 14.30.15;DT2Col=05-03-2024 09.05.07;T1Col=14.30.15;T2Col=09.05.07;IntCol=-1234567;TextsCol=1.234.567,891#-1.234,5#31-01-25#05-03-24#5. March 2024#31-01-25 14.30#05-03-24 09.05#14.30.15#09.05.07#-1234567;');
        Observer.Expect('log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1.234.567,891#-1.234,5#31-01-25#05-03-24#5. March 2024#31-01-25 14.30#05-03-24 09.05#14.30.15#09.05.07#-1234567 region=[da-DK];get=1.234.567,891#-1.234,5#31-01-25#05-03-24#5. March 2024#31-01-25 14.30#05-03-24 09.05#14.30.15#09.05.07#-1234567 region=[da-DK];post=1.234.567,891#-1.234,5#31-01-25#05-03-24#5. March 2024#31-01-25 14.30#05-03-24 09.05#14.30.15#09.05.07#-1234567;');
        Observer.Verify();
#else
        Observer.Discard();
#endif
    end;

    [Test]
    procedure BdProperty_Us_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region Us");
#if BC29PLUS
        Observer.Expect('header', '<ReportDataSet name="BD Region Us id:81058 language="en-US formatRegion="en-US">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Us</ReportName>|<ReportCaption>BD Region Us</ReportCaption>|<Language>en-US</Language>|<FormatRegion>en-US</FormatRegion>|');
#else
        Observer.Expect('header', '<ReportDataSet name="BD Region Us id:81058 language="en-US formatRegion="en-US">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Us</ReportName>|<Language>en-US</Language>|<FormatRegion>en-US</FormatRegion>|');
#endif
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567.891;NegCol[decimalformatter:#,##0.00=-1234.5;D1Col=1/31/2025;D2Col=3/5/2024;DT1Col=1/31/2025 2:30:15 PM;DT2Col=3/5/2024 9:05:07 AM;T1Col=2:30:15 PM;T2Col=9:05:07 AM;IntCol=-1234567;TextsCol=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567;');
        Observer.Expect('log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];get=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];post=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567;');
        Observer.Verify();
    end;

    [Test]
    procedure BdProperty_Nl_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region Nl");
#if BC29PLUS
        // Windows BC 29.0 check 2026-10-20 (bump 34 queue): every key measured (Windows NLS culture data; U+00A0 is a no-break space).
        // The Linux image at dbee8022 gives the same values (corpus CI 2026-10-20), so BC 29 has no hold.
        Observer.Expect('header', '<ReportDataSet name="BD Region Nl id:81059 language="en-US formatRegion="nl-NL">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Nl</ReportName>|<ReportCaption>BD Region Nl</ReportCaption>|<Language>en-US</Language>|<FormatRegion>nl-NL</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=-1234,5;D1Col=31-1-2025;D2Col=5-3-2024;DT1Col=31-1-2025 14:30:15;DT2Col=5-3-2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;IntCol=-1234567;TextsCol=1.234.567,891#-1.234,5#31-01-25#05-03-24#5 March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Expect('log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1.234.567,891#-1.234,5#31-01-25#05-03-24#5 March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07#-1234567 region=[nl-NL];get=1.234.567,891#-1.234,5#31-01-25#05-03-24#5 March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07#-1234567 region=[nl-NL];post=1.234.567,891#-1.234,5#31-01-25#05-03-24#5 March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Verify();
#elif LT_HELD_BCLINUX_157
        // Held on Linux (LT_HELD_BCLINUX_157): these are the Linux values of the image before the bc-linux #157 fix. The image at dbee8022 formats
        // as Windows does, and the Windows runs (2026-10-20) differ from these values, but only the first difference was measured. Re-assert with
        // the full Windows values after the Windows check (windows-queue), then remove this hold; it does not end when bc-linux #157 closes.
        Observer.Expect('header', '<ReportDataSet name="BD Region Nl id:81059 language="en-US formatRegion="nl-NL">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Nl</ReportName>|<Language>en-US</Language>|<FormatRegion>nl-NL</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=-1234,5;D1Col=31-01-2025;D2Col=05-03-2024;DT1Col=31-01-2025 14:30:15;DT2Col=05-03-2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;IntCol=-1234567;TextsCol=1.234.567,891#-1.234,5#31-01-25#05-03-24#5 March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Expect('log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1.234.567,891#-1.234,5#31-01-25#05-03-24#5 March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07#-1234567 region=[nl-NL];get=1.234.567,891#-1.234,5#31-01-25#05-03-24#5 March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07#-1234567 region=[nl-NL];post=1.234.567,891#-1.234,5#31-01-25#05-03-24#5 March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Verify();
#else
        Observer.Discard();
#endif
    end;

    [Test]
    procedure BdProperty_Ch_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region Ch");
#if BC29PLUS
        Observer.Expect('header', '<ReportDataSet name="BD Region Ch id:81060 language="en-US formatRegion="de-CH">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Ch</ReportName>|<ReportCaption>BD Region Ch</ReportCaption>|<Language>en-US</Language>|<FormatRegion>de-CH</FormatRegion>|');
#else
        Observer.Expect('header', '<ReportDataSet name="BD Region Ch id:81060 language="en-US formatRegion="de-CH">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Ch</ReportName>|<Language>en-US</Language>|<FormatRegion>de-CH</FormatRegion>|');
#endif
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567.891;NegCol[decimalformatter:#,##0.00=-1234.5;D1Col=31.01.2025;D2Col=05.03.2024;DT1Col=31.01.2025 14:30:15;DT2Col=05.03.2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;IntCol=-1234567;TextsCol=1’234’567.891#-1’234.5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Expect('log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1’234’567.891#-1’234.5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567 region=[de-CH];get=1’234’567.891#-1’234.5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567 region=[de-CH];post=1’234’567.891#-1’234.5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Verify();
    end;

    [Test]
    procedure BdProperty_It_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region It");
#if BC29PLUS
        Observer.Expect('header', '<ReportDataSet name="BD Region It id:81061 language="en-US formatRegion="it-IT">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region It</ReportName>|<ReportCaption>BD Region It</ReportCaption>|<Language>en-US</Language>|<FormatRegion>it-IT</FormatRegion>|');
#else
        Observer.Expect('header', '<ReportDataSet name="BD Region It id:81061 language="en-US formatRegion="it-IT">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region It</ReportName>|<Language>en-US</Language>|<FormatRegion>it-IT</FormatRegion>|');
#endif
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=-1234,5;D1Col=31/01/2025;D2Col=05/03/2024;DT1Col=31/01/2025 14:30:15;DT2Col=05/03/2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;IntCol=-1234567;TextsCol=1.234.567,891#-1.234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Expect('log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1.234.567,891#-1.234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07#-1234567 region=[it-IT];get=1.234.567,891#-1.234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07#-1234567 region=[it-IT];post=1.234.567,891#-1.234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Verify();
    end;

    [Test]
    procedure BdProperty_Es_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region Es");
#if BC29PLUS
        // Windows BC 29.0 check 2026-10-20 (bump 34 queue): every key measured (Windows NLS culture data; U+00A0 is a no-break space).
        // The Linux image at dbee8022 gives the same values (corpus CI 2026-10-20), so BC 29 has no hold.
        Observer.Expect('header', '<ReportDataSet name="BD Region Es id:81062 language="en-US formatRegion="es-ES">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Es</ReportName>|<ReportCaption>BD Region Es</ReportCaption>|<Language>en-US</Language>|<FormatRegion>es-ES</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=-1234,5;D1Col=31/01/2025;D2Col=05/03/2024;DT1Col=31/01/2025 14:30:15;DT2Col=05/03/2024 9:05:07;T1Col=14:30:15;T2Col=9:05:07;IntCol=-1234567;TextsCol=1.234.567,891#-1.234,5#31/01/25#05/03/24#5 de March de 2024#31/01/25 14:30#05/03/24 09:05#14:30:15# 9:05:07#-1234567;');
        Observer.Expect('log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1.234.567,891#-1.234,5#31/01/25#05/03/24#5 de March de 2024#31/01/25 14:30#05/03/24 09:05#14:30:15# 9:05:07#-1234567 region=[es-ES];get=1.234.567,891#-1.234,5#31/01/25#05/03/24#5 de March de 2024#31/01/25 14:30#05/03/24 09:05#14:30:15# 9:05:07#-1234567 region=[es-ES];post=1.234.567,891#-1.234,5#31/01/25#05/03/24#5 de March de 2024#31/01/25 14:30#05/03/24 09:05#14:30:15# 9:05:07#-1234567;');
        Observer.Verify();
#elif LT_HELD_BCLINUX_157
        // Held on Linux (LT_HELD_BCLINUX_157): these are the Linux values of the image before the bc-linux #157 fix. The image at dbee8022 formats
        // as Windows does, and the Windows runs (2026-10-20) differ from these values, but only the first difference was measured. Re-assert with
        // the full Windows values after the Windows check (windows-queue), then remove this hold; it does not end when bc-linux #157 closes.
        Observer.Expect('header', '<ReportDataSet name="BD Region Es id:81062 language="en-US formatRegion="es-ES">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Es</ReportName>|<Language>en-US</Language>|<FormatRegion>es-ES</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=-1234,5;D1Col=31/1/2025;D2Col=5/3/2024;DT1Col=31/1/2025 14:30:15;DT2Col=5/3/2024 9:05:07;T1Col=14:30:15;T2Col=9:05:07;IntCol=-1234567;TextsCol=1.234.567,891#-1.234,5#31/01/25#05/03/24#5 de March de 2024#31/01/25 14:30#05/03/24 09:05#14:30:15# 9:05:07#-1234567;');
        Observer.Expect('log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1.234.567,891#-1.234,5#31/01/25#05/03/24#5 de March de 2024#31/01/25 14:30#05/03/24 09:05#14:30:15# 9:05:07#-1234567 region=[es-ES];get=1.234.567,891#-1.234,5#31/01/25#05/03/24#5 de March de 2024#31/01/25 14:30#05/03/24 09:05#14:30:15# 9:05:07#-1234567 region=[es-ES];post=1.234.567,891#-1.234,5#31/01/25#05/03/24#5 de March de 2024#31/01/25 14:30#05/03/24 09:05#14:30:15# 9:05:07#-1234567;');
        Observer.Verify();
#else
        Observer.Discard();
#endif
    end;

    [Test]
    procedure BdProperty_Se_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region Se");
#if BC29PLUS
        // Windows BC 29.0 check 2026-10-20 (bump 34 queue): every key measured (Windows NLS culture data; U+00A0 is a no-break space).
        // The Linux image at dbee8022 gives the same values (corpus CI 2026-10-20), so BC 29 has no hold.
        Observer.Expect('header', '<ReportDataSet name="BD Region Se id:81063 language="en-US formatRegion="sv-SE">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Se</ReportName>|<ReportCaption>BD Region Se</ReportCaption>|<Language>en-US</Language>|<FormatRegion>sv-SE</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=-1234,5;D1Col=2025-01-31;D2Col=2024-03-05;DT1Col=2025-01-31 14:30:15;DT2Col=2024-03-05 09:05:07;T1Col=14:30:15;T2Col=09:05:07;IntCol=-1234567;TextsCol=1 234 567,891#-1 234,5#25-01-31#24-03-05#den 5 March 2024#25-01-31 14:30#24-03-05 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Expect('log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1 234 567,891#-1 234,5#25-01-31#24-03-05#den 5 March 2024#25-01-31 14:30#24-03-05 09:05#14:30:15#09:05:07#-1234567 region=[sv-SE];get=1 234 567,891#-1 234,5#25-01-31#24-03-05#den 5 March 2024#25-01-31 14:30#24-03-05 09:05#14:30:15#09:05:07#-1234567 region=[sv-SE];post=1 234 567,891#-1 234,5#25-01-31#24-03-05#den 5 March 2024#25-01-31 14:30#24-03-05 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Verify();
#elif LT_HELD_BCLINUX_157
        // Held on Linux (LT_HELD_BCLINUX_157): these are the Linux values of the image before the bc-linux #157 fix. The image at dbee8022 formats
        // as Windows does, and the Windows runs (2026-10-20) differ from these values, but only the first difference was measured. Re-assert with
        // the full Windows values after the Windows check (windows-queue), then remove this hold; it does not end when bc-linux #157 closes.
        Observer.Expect('header', '<ReportDataSet name="BD Region Se id:81063 language="en-US formatRegion="sv-SE">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Se</ReportName>|<Language>en-US</Language>|<FormatRegion>sv-SE</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=−1234,5;D1Col=2025-01-31;D2Col=2024-03-05;DT1Col=2025-01-31 14:30:15;DT2Col=2024-03-05 09:05:07;T1Col=14:30:15;T2Col=09:05:07;IntCol=−1234567;TextsCol=1 234 567,891#-1 234,5#25-01-31#24-03-05#5 March 2024#25-01-31 14:30#24-03-05 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Expect('log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1 234 567,891#-1 234,5#25-01-31#24-03-05#5 March 2024#25-01-31 14:30#24-03-05 09:05#14:30:15#09:05:07#-1234567 region=[sv-SE];get=1 234 567,891#-1 234,5#25-01-31#24-03-05#5 March 2024#25-01-31 14:30#24-03-05 09:05#14:30:15#09:05:07#-1234567 region=[sv-SE];post=1 234 567,891#-1 234,5#25-01-31#24-03-05#5 March 2024#25-01-31 14:30#24-03-05 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Verify();
#else
        Observer.Discard();
#endif
    end;

    [Test]
    procedure BdProperty_No_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region No");
#if BC29PLUS
        // Windows BC 29.0 check 2026-10-20 (bump 34 queue): every key measured (Windows NLS culture data; U+00A0 is a no-break space).
        // The Linux image at dbee8022 gives the same values (corpus CI 2026-10-20), so BC 29 has no hold.
        Observer.Expect('header', '<ReportDataSet name="BD Region No id:81064 language="en-US formatRegion="nb-NO">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region No</ReportName>|<ReportCaption>BD Region No</ReportCaption>|<Language>en-US</Language>|<FormatRegion>nb-NO</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=-1234,5;D1Col=31.01.2025;D2Col=05.03.2024;DT1Col=31.01.2025 14:30:15;DT2Col=05.03.2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;IntCol=-1234567;TextsCol=1 234 567,891#-1 234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Expect('log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1 234 567,891#-1 234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567 region=[nb-NO];get=1 234 567,891#-1 234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567 region=[nb-NO];post=1 234 567,891#-1 234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Verify();
#elif LT_HELD_BCLINUX_157
        // Held on Linux (LT_HELD_BCLINUX_157): these are the Linux values of the image before the bc-linux #157 fix. The image at dbee8022 formats
        // as Windows does, and the Windows runs (2026-10-20) differ from these values, but only the first difference was measured. Re-assert with
        // the full Windows values after the Windows check (windows-queue), then remove this hold; it does not end when bc-linux #157 closes.
        Observer.Expect('header', '<ReportDataSet name="BD Region No id:81064 language="en-US formatRegion="nb-NO">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region No</ReportName>|<Language>en-US</Language>|<FormatRegion>nb-NO</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=−1234,5;D1Col=31.01.2025;D2Col=05.03.2024;DT1Col=31.01.2025 14:30:15;DT2Col=05.03.2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;IntCol=−1234567;TextsCol=1 234 567,891#-1 234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Expect('log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1 234 567,891#-1 234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567 region=[nb-NO];get=1 234 567,891#-1 234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567 region=[nb-NO];post=1 234 567,891#-1 234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Verify();
#else
        Observer.Discard();
#endif
    end;

    [Test]
    procedure BdProperty_NotSet_DatasetAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Dataset(Observer, Report::"BD Region Empty");
#if BC29PLUS
        Observer.Expect('header', '<ReportDataSet name="BD Region Empty id:81065 language="en-US formatRegion="en-US">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Empty</ReportName>|<ReportCaption>BD Region Empty</ReportCaption>|<Language>en-US</Language>|<FormatRegion>en-US</FormatRegion>|');
#else
        Observer.Expect('header', '<ReportDataSet name="BD Region Empty id:81065 language="en-US formatRegion="en-US">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Empty</ReportName>|<Language>en-US</Language>|<FormatRegion>en-US</FormatRegion>|');
#endif
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567.891;NegCol[decimalformatter:#,##0.00=-1234.5;D1Col=1/31/2025;D2Col=3/5/2024;DT1Col=1/31/2025 2:30:15 PM;DT2Col=3/5/2024 9:05:07 AM;T1Col=2:30:15 PM;T2Col=9:05:07 AM;IntCol=-1234567;TextsCol=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567;');
        Observer.Expect('log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];get=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];post=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567;');
        Observer.Verify();
    end;

    [Test]
    procedure BdProperty_De_RunRunModalExecute()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        ClearLastError();
        RunWay(Observer, 'run', TryRun(Report::"BD Region De Proc"));
        ClearLastError();
        RunWay(Observer, 'runmodal', TryRunModal(Report::"BD Region De Proc"));
        ClearLastError();
        RunWay(Observer, 'execute', TryExecute(Report::"BD Region De Proc"));
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567 region=[de-DE];get=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567 region=[de-DE];post=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Expect('runmodal ok', 'Yes');
        Observer.Expect('runmodal|text', '');
        Observer.Expect('runmodal|code', '');
        Observer.Expect('runmodal log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567 region=[de-DE];get=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567 region=[de-DE];post=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Expect('execute ok', 'Yes');
        Observer.Expect('execute|text', '');
        Observer.Expect('execute|code', '');
        Observer.Expect('execute log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567 region=[de-DE];get=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567 region=[de-DE];post=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Verify();
    end;

    // Windows BC 27.5, 28.5 and 29.0 (Windows BC 29.0 check 2026-10-20: same values as 27.5/28.5) give these values. Before the bc-linux fixes the Linux image
    // ended SaveAs Word/Excel of the RDLC layout in the Mono renderer error (bc-linux #144; BC 29.0: renderer off at boot,
    // bc-linux #143).
    [Test]
    procedure BdProperty_De_SaveAsPdfWord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SaveAsWay(Observer, ReportFormat::Pdf);
        SaveAsWay(Observer, ReportFormat::Word);
        Observer.Expect('Pdf ok', 'Yes');
        Observer.Expect('Pdf has output', 'Yes');
        Observer.Expect('Pdf|text', '');
        Observer.Expect('Pdf|code', '');
        Observer.Expect('Pdf log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567 region=[de-DE];get=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567 region=[de-DE];post=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Expect('Word ok', 'Yes');
        Observer.Expect('Word has output', 'Yes');
        Observer.Expect('Word|text', '');
        Observer.Expect('Word|code', '');
        Observer.Expect('Word log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567 region=[de-DE];get=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567 region=[de-DE];post=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Verify();
    end;

    // Windows BC 27.5, 28.5 and 29.0 (Windows BC 29.0 check 2026-10-20: same values as 27.5/28.5) give these values. Before the bc-linux fixes the Linux image
    // ended SaveAs Word/Excel of the RDLC layout in the Mono renderer error (bc-linux #144; BC 29.0: renderer off at boot,
    // bc-linux #143).
    [Test]
    procedure BdProperty_De_SaveAsExcelHtml()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SaveAsWay(Observer, ReportFormat::Excel);
        SaveAsWay(Observer, ReportFormat::Html);
        Observer.Expect('Excel ok', 'Yes');
        Observer.Expect('Excel has output', 'Yes');
        Observer.Expect('Excel|text', '');
        Observer.Expect('Excel|code', '');
        Observer.Expect('Excel log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];pre=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567 region=[de-DE];get=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567 region=[de-DE];post=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Expect('Html ok', 'No');
        Observer.Expect('Html has output', 'No');
        Observer.Expect('Html|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('Html|code', 'ReportUnsupportedFormat');
        Observer.Expect('Html log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryRequestSaveAsXml(var RP: TestRequestPage "BD Region De Req")
    begin
        RP.SaveAsXml('bdparams.xml', 'bddata.xml');
    end;

    [RequestPageHandler]
    procedure BdReqHandler(var RP: TestRequestPage "BD Region De Req")
    var
        Ok: Boolean;
    begin
        ReqLog := 'handler log=' + Log.Take() + ' amount=' + RP.ReqAmt.Value();
        ClearLastError();
        Ok := TryRequestSaveAsXml(RP);
        ReqLog += ' saveasxml ok=' + Format(Ok) + ' error=' + GetLastErrorText() + ' code=' + GetLastErrorCode() + ' log=' + Log.Take();
        ClearLastError();
    end;

    // Report.Run(Id, false) of the request-page report: no request page opens; the report has no layout, so the run ends in ReportNoLayout.
    [Test]
    procedure BdProperty_De_RunNoRequestPageNoLayout()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Log.Take();
        ReqLog := '';
        ClearLastError();
        Ok := TryRun(Report::"BD Region De Req");
        Observer.Observe('handler', ReqLog);
        Observer.Observe('run ok', Format(Ok));
        Observer.ObserveError('run');
        Observer.Observe('run log', Log.Take());
        Observer.Expect('handler', '');
        Observer.Expect('run ok', 'No');
        Observer.Expect('run|text', 'Report 81067 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('run|code', 'ReportNoLayout');
        Observer.Expect('run log', 'init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[];');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryRunWithRequestPage(ReportId: Integer)
    begin
        Report.Run(ReportId, true);
    end;

    // Report.Run(Id, true): the request page opens, the handler reads a request field and calls TestRequestPage.SaveAsXml.
    [Test]
    [HandlerFunctions('BdReqHandler')]
    procedure BdProperty_De_TestRequestPageSaveAsXml()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Log.Take();
        ReqLog := '';
        ClearLastError();
        Ok := TryRunWithRequestPage(Report::"BD Region De Req");
        Observer.Observe('handler', ReqLog);
        Observer.Observe('run ok', Format(Ok));
        Observer.ObserveError('run');
        Observer.Observe('run log', Log.Take());
        Observer.Expect('handler', 'handler log=init=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM#-1234567 region=[]; amount=1.234.567,89 saveasxml ok=Yes error= code= log=');
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'pre=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567 region=[de-DE];get=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567 region=[de-DE];post=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07#-1234567;');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryGlobalLanguage(Language: Integer)
    begin
        GlobalLanguage(Language);
    end;

    [Test]
    procedure BdSetter_EnGB()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'en-GB', true, 0);
#if BC29PLUS
        // Windows BC 29.0 check 2026-10-20 (bump 34 queue): every key measured (Windows NLS culture data; U+00A0 is a no-break space).
        // The Linux image at dbee8022 gives the same values (corpus CI 2026-10-20), so BC 29 has no hold.
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="en-US formatRegion="en-GB">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<ReportCaption>BD Region Setter</ReportCaption>|<Language>en-US</Language>|<FormatRegion>en-GB</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567.891;NegCol[decimalformatter:#,##0.00=-1234.5;D1Col=31/01/2025;D2Col=05/03/2024;DT1Col=31/01/2025 14:30:15;DT2Col=05/03/2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;TextsCol=1,234,567.891#-1,234.5#31/01/25#05/03/24#05 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;');
        Observer.Expect('log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1,234,567.891#-1,234.5#31/01/25#05/03/24#05 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07 language=1033 region=[en-GB];get=1,234,567.891#-1,234.5#31/01/25#05/03/24#05 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;post=1,234,567.891#-1,234.5#31/01/25#05/03/24#05 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;');
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1,234,567.891#-1,234.5#31/01/25#05/03/24#05 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07 language=1033 region=[en-GB];get=1,234,567.891#-1,234.5#31/01/25#05/03/24#05 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;post=1,234,567.891#-1,234.5#31/01/25#05/03/24#05 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;');
        Observer.Verify();
#elif LT_HELD_BCLINUX_157
        // Held on Linux (LT_HELD_BCLINUX_157): these are the Linux values of the image before the bc-linux #157 fix. The image at dbee8022 formats
        // as Windows does, and the Windows runs (2026-10-20) differ from these values, but only the first difference was measured. Re-assert with
        // the full Windows values after the Windows check (windows-queue), then remove this hold; it does not end when bc-linux #157 closes.
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="en-US formatRegion="en-GB">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<Language>en-US</Language>|<FormatRegion>en-GB</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567.891;NegCol[decimalformatter:#,##0.00=-1234.5;D1Col=31/01/2025;D2Col=05/03/2024;DT1Col=31/01/2025 14:30:15;DT2Col=05/03/2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;TextsCol=1,234,567.891#-1,234.5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;');
        Observer.Expect('log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1,234,567.891#-1,234.5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07 language=1033 region=[en-GB];get=1,234,567.891#-1,234.5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;post=1,234,567.891#-1,234.5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;');
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1,234,567.891#-1,234.5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07 language=1033 region=[en-GB];get=1,234,567.891#-1,234.5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;post=1,234,567.891#-1,234.5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;');
        Observer.Verify();
#else
        Observer.Discard();
#endif
    end;

    [Test]
    procedure BdSetter_JaJP()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'ja-JP', true, 0);
#if BC29PLUS
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="en-US formatRegion="ja-JP">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<ReportCaption>BD Region Setter</ReportCaption>|<Language>en-US</Language>|<FormatRegion>ja-JP</FormatRegion>|');
#else
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="en-US formatRegion="ja-JP">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<Language>en-US</Language>|<FormatRegion>ja-JP</FormatRegion>|');
#endif
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567.891;NegCol[decimalformatter:#,##0.00=-1234.5;D1Col=2025/01/31;D2Col=2024/03/05;DT1Col=2025/01/31 14:30:15;DT2Col=2024/03/05 9:05:07;T1Col=14:30:15;T2Col=9:05:07;TextsCol=1,234,567.891#-1,234.5#25/01/31#24/03/05#2024年3月5日#25/01/31 14:30#24/03/05 09:05#14:30:15# 9:05:07;');
        Observer.Expect('log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1,234,567.891#-1,234.5#25/01/31#24/03/05#2024年3月5日#25/01/31 14:30#24/03/05 09:05#14:30:15# 9:05:07 language=1033 region=[ja-JP];get=1,234,567.891#-1,234.5#25/01/31#24/03/05#2024年3月5日#25/01/31 14:30#24/03/05 09:05#14:30:15# 9:05:07;post=1,234,567.891#-1,234.5#25/01/31#24/03/05#2024年3月5日#25/01/31 14:30#24/03/05 09:05#14:30:15# 9:05:07;');
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1,234,567.891#-1,234.5#25/01/31#24/03/05#2024年3月5日#25/01/31 14:30#24/03/05 09:05#14:30:15# 9:05:07 language=1033 region=[ja-JP];get=1,234,567.891#-1,234.5#25/01/31#24/03/05#2024年3月5日#25/01/31 14:30#24/03/05 09:05#14:30:15# 9:05:07;post=1,234,567.891#-1,234.5#25/01/31#24/03/05#2024年3月5日#25/01/31 14:30#24/03/05 09:05#14:30:15# 9:05:07;');
        Observer.Verify();
    end;

    [Test]
    procedure BdSetter_NlNL()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'nl-NL', true, 0);
#if BC29PLUS
        // Windows BC 29.0 check 2026-10-20 (bump 34 queue): every key measured (Windows NLS culture data; U+00A0 is a no-break space).
        // The Linux image at dbee8022 gives the same values (corpus CI 2026-10-20), so BC 29 has no hold.
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="en-US formatRegion="nl-NL">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<ReportCaption>BD Region Setter</ReportCaption>|<Language>en-US</Language>|<FormatRegion>nl-NL</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=-1234,5;D1Col=31-1-2025;D2Col=5-3-2024;DT1Col=31-1-2025 14:30:15;DT2Col=5-3-2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;TextsCol=1.234.567,891#-1.234,5#31-01-25#05-03-24#5 March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07;');
        Observer.Expect('log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1.234.567,891#-1.234,5#31-01-25#05-03-24#5 March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07 language=1033 region=[nl-NL];get=1.234.567,891#-1.234,5#31-01-25#05-03-24#5 March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07;post=1.234.567,891#-1.234,5#31-01-25#05-03-24#5 March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07;');
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1.234.567,891#-1.234,5#31-01-25#05-03-24#5 March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07 language=1033 region=[nl-NL];get=1.234.567,891#-1.234,5#31-01-25#05-03-24#5 March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07;post=1.234.567,891#-1.234,5#31-01-25#05-03-24#5 March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07;');
        Observer.Verify();
#elif LT_HELD_BCLINUX_157
        // Held on Linux (LT_HELD_BCLINUX_157): these are the Linux values of the image before the bc-linux #157 fix. The image at dbee8022 formats
        // as Windows does, and the Windows runs (2026-10-20) differ from these values, but only the first difference was measured. Re-assert with
        // the full Windows values after the Windows check (windows-queue), then remove this hold; it does not end when bc-linux #157 closes.
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="en-US formatRegion="nl-NL">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<Language>en-US</Language>|<FormatRegion>nl-NL</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=-1234,5;D1Col=31-01-2025;D2Col=05-03-2024;DT1Col=31-01-2025 14:30:15;DT2Col=05-03-2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;TextsCol=1.234.567,891#-1.234,5#31-01-25#05-03-24#5 March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07;');
        Observer.Expect('log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1.234.567,891#-1.234,5#31-01-25#05-03-24#5 March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07 language=1033 region=[nl-NL];get=1.234.567,891#-1.234,5#31-01-25#05-03-24#5 March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07;post=1.234.567,891#-1.234,5#31-01-25#05-03-24#5 March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07;');
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1.234.567,891#-1.234,5#31-01-25#05-03-24#5 March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07 language=1033 region=[nl-NL];get=1.234.567,891#-1.234,5#31-01-25#05-03-24#5 March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07;post=1.234.567,891#-1.234,5#31-01-25#05-03-24#5 March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07;');
        Observer.Verify();
#else
        Observer.Discard();
#endif
    end;

    [Test]
    procedure BdSetter_DeCH()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'de-CH', true, 0);
#if BC29PLUS
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="en-US formatRegion="de-CH">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<ReportCaption>BD Region Setter</ReportCaption>|<Language>en-US</Language>|<FormatRegion>de-CH</FormatRegion>|');
#else
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="en-US formatRegion="de-CH">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<Language>en-US</Language>|<FormatRegion>de-CH</FormatRegion>|');
#endif
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567.891;NegCol[decimalformatter:#,##0.00=-1234.5;D1Col=31.01.2025;D2Col=05.03.2024;DT1Col=31.01.2025 14:30:15;DT2Col=05.03.2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;TextsCol=1’234’567.891#-1’234.5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07;');
        Observer.Expect('log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1’234’567.891#-1’234.5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07 language=1033 region=[de-CH];get=1’234’567.891#-1’234.5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07;post=1’234’567.891#-1’234.5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07;');
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1’234’567.891#-1’234.5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07 language=1033 region=[de-CH];get=1’234’567.891#-1’234.5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07;post=1’234’567.891#-1’234.5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07;');
        Observer.Verify();
    end;

    [Test]
    procedure BdSetter_ItIT()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'it-IT', true, 0);
#if BC29PLUS
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="en-US formatRegion="it-IT">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<ReportCaption>BD Region Setter</ReportCaption>|<Language>en-US</Language>|<FormatRegion>it-IT</FormatRegion>|');
#else
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="en-US formatRegion="it-IT">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<Language>en-US</Language>|<FormatRegion>it-IT</FormatRegion>|');
#endif
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=-1234,5;D1Col=31/01/2025;D2Col=05/03/2024;DT1Col=31/01/2025 14:30:15;DT2Col=05/03/2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;TextsCol=1.234.567,891#-1.234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;');
        Observer.Expect('log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1.234.567,891#-1.234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07 language=1033 region=[it-IT];get=1.234.567,891#-1.234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;post=1.234.567,891#-1.234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;');
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1.234.567,891#-1.234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07 language=1033 region=[it-IT];get=1.234.567,891#-1.234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;post=1.234.567,891#-1.234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;');
        Observer.Verify();
    end;

    [Test]
    procedure BdSetter_SvSE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'sv-SE', true, 0);
#if BC29PLUS
        // Windows BC 29.0 check 2026-10-20 (bump 34 queue): every key measured (Windows NLS culture data; U+00A0 is a no-break space).
        // The Linux image at dbee8022 gives the same values (corpus CI 2026-10-20), so BC 29 has no hold.
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="en-US formatRegion="sv-SE">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<ReportCaption>BD Region Setter</ReportCaption>|<Language>en-US</Language>|<FormatRegion>sv-SE</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=-1234,5;D1Col=2025-01-31;D2Col=2024-03-05;DT1Col=2025-01-31 14:30:15;DT2Col=2024-03-05 09:05:07;T1Col=14:30:15;T2Col=09:05:07;TextsCol=1 234 567,891#-1 234,5#25-01-31#24-03-05#den 5 March 2024#25-01-31 14:30#24-03-05 09:05#14:30:15#09:05:07;');
        Observer.Expect('log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1 234 567,891#-1 234,5#25-01-31#24-03-05#den 5 March 2024#25-01-31 14:30#24-03-05 09:05#14:30:15#09:05:07 language=1033 region=[sv-SE];get=1 234 567,891#-1 234,5#25-01-31#24-03-05#den 5 March 2024#25-01-31 14:30#24-03-05 09:05#14:30:15#09:05:07;post=1 234 567,891#-1 234,5#25-01-31#24-03-05#den 5 March 2024#25-01-31 14:30#24-03-05 09:05#14:30:15#09:05:07;');
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1 234 567,891#-1 234,5#25-01-31#24-03-05#den 5 March 2024#25-01-31 14:30#24-03-05 09:05#14:30:15#09:05:07 language=1033 region=[sv-SE];get=1 234 567,891#-1 234,5#25-01-31#24-03-05#den 5 March 2024#25-01-31 14:30#24-03-05 09:05#14:30:15#09:05:07;post=1 234 567,891#-1 234,5#25-01-31#24-03-05#den 5 March 2024#25-01-31 14:30#24-03-05 09:05#14:30:15#09:05:07;');
        Observer.Verify();
#elif LT_HELD_BCLINUX_157
        // Held on Linux (LT_HELD_BCLINUX_157): these are the Linux values of the image before the bc-linux #157 fix. The image at dbee8022 formats
        // as Windows does, and the Windows runs (2026-10-20) differ from these values, but only the first difference was measured. Re-assert with
        // the full Windows values after the Windows check (windows-queue), then remove this hold; it does not end when bc-linux #157 closes.
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="en-US formatRegion="sv-SE">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<Language>en-US</Language>|<FormatRegion>sv-SE</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=−1234,5;D1Col=2025-01-31;D2Col=2024-03-05;DT1Col=2025-01-31 14:30:15;DT2Col=2024-03-05 09:05:07;T1Col=14:30:15;T2Col=09:05:07;TextsCol=1 234 567,891#-1 234,5#25-01-31#24-03-05#5 March 2024#25-01-31 14:30#24-03-05 09:05#14:30:15#09:05:07;');
        Observer.Expect('log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1 234 567,891#-1 234,5#25-01-31#24-03-05#5 March 2024#25-01-31 14:30#24-03-05 09:05#14:30:15#09:05:07 language=1033 region=[sv-SE];get=1 234 567,891#-1 234,5#25-01-31#24-03-05#5 March 2024#25-01-31 14:30#24-03-05 09:05#14:30:15#09:05:07;post=1 234 567,891#-1 234,5#25-01-31#24-03-05#5 March 2024#25-01-31 14:30#24-03-05 09:05#14:30:15#09:05:07;');
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1 234 567,891#-1 234,5#25-01-31#24-03-05#5 March 2024#25-01-31 14:30#24-03-05 09:05#14:30:15#09:05:07 language=1033 region=[sv-SE];get=1 234 567,891#-1 234,5#25-01-31#24-03-05#5 March 2024#25-01-31 14:30#24-03-05 09:05#14:30:15#09:05:07;post=1 234 567,891#-1 234,5#25-01-31#24-03-05#5 March 2024#25-01-31 14:30#24-03-05 09:05#14:30:15#09:05:07;');
        Observer.Verify();
#else
        Observer.Discard();
#endif
    end;

    [Test]
    procedure BdSetter_EnUS()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterDataset(Observer, 'en-US', true, 0);
#if BC29PLUS
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="en-US formatRegion="en-US">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<ReportCaption>BD Region Setter</ReportCaption>|<Language>en-US</Language>|<FormatRegion>en-US</FormatRegion>|');
#else
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="en-US formatRegion="en-US">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<Language>en-US</Language>|<FormatRegion>en-US</FormatRegion>|');
#endif
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567.891;NegCol[decimalformatter:#,##0.00=-1234.5;D1Col=1/31/2025;D2Col=3/5/2024;DT1Col=1/31/2025 2:30:15 PM;DT2Col=3/5/2024 9:05:07 AM;T1Col=2:30:15 PM;T2Col=9:05:07 AM;TextsCol=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM;');
        Observer.Expect('log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];get=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM;post=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM;');
        Observer.Verify();
    end;

    [Test]
    procedure BdSetter_EnUS_Run()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterRun(Observer, 'en-US', true, 0);
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];get=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM;post=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM;');
        Observer.Verify();
    end;

    [Test]
    procedure BdSetter_ZzZZ()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'zz-ZZ', true, 0);
        Observer.Expect('saveas|text', 'An unsupported language was selected (''zz-ZZ'' - ''Requested culture is not supported by the current platform'').');
        Observer.Expect('saveas|code', 'ReportFormatCultureNotFound');
        Observer.Expect('log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];');
        Observer.Expect('run ok', 'No');
        Observer.Expect('run|text', 'An unsupported language was selected (''zz-ZZ'' - ''Requested culture is not supported by the current platform'').');
        Observer.Expect('run|code', 'ReportFormatCultureNotFound');
        Observer.Expect('run log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];');
        Observer.Verify();
    end;

    [Test]
    procedure BdSetter_Blank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, '', true, 0);
        Observer.Expect('saveas|text', 'Invalid language ID supplied: 0.');
        Observer.Expect('saveas|code', 'Argument');
        Observer.Expect('log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];');
        Observer.Expect('run ok', 'No');
        Observer.Expect('run|text', 'Invalid language ID supplied: 0.');
        Observer.Expect('run|code', 'Argument');
        Observer.Expect('run log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];');
        Observer.Verify();
    end;

    [Test]
    procedure BdSetter_DeDE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'de-DE', true, 0);
#if BC29PLUS
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="en-US formatRegion="de-DE">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<ReportCaption>BD Region Setter</ReportCaption>|<Language>en-US</Language>|<FormatRegion>de-DE</FormatRegion>|');
#else
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="en-US formatRegion="de-DE">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<Language>en-US</Language>|<FormatRegion>de-DE</FormatRegion>|');
#endif
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=-1234,5;D1Col=31.01.2025;D2Col=05.03.2024;DT1Col=31.01.2025 14:30:15;DT2Col=05.03.2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;TextsCol=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07;');
        Observer.Expect('log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07 language=1033 region=[de-DE];get=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07;post=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07;');
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07 language=1033 region=[de-DE];get=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07;post=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07;');
        Observer.Verify();
    end;

    [Test]
    procedure BdSetter_FrFR()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'fr-FR', true, 0);
#if BC29PLUS
        // Windows BC 29.0 check 2026-10-20 (bump 34 queue): every key measured (Windows NLS culture data; U+00A0 is a no-break space).
        // It was held on Linux BC 29 under bc-linux #167 (LT_HELD_BCLINUX_167); lifted with the bc-linux pin bcc60c1c (corpus bump 42).
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="en-US formatRegion="fr-FR">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<ReportCaption>BD Region Setter</ReportCaption>|<Language>en-US</Language>|<FormatRegion>fr-FR</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=-1234,5;D1Col=31/01/2025;D2Col=05/03/2024;DT1Col=31/01/2025 14:30:15;DT2Col=05/03/2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;TextsCol=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;');
        Observer.Expect('log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07 language=1033 region=[fr-FR];get=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;post=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;');
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07 language=1033 region=[fr-FR];get=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;post=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;');
        Observer.Verify();
#else
        // BC 27 and 28: the fr-FR group separator is U+00A0 as on Windows BC 27.5 and 28.5 (Windows runs 2026-10-20 and 2026-10-22: only
        // U+00A0 occurs) and on bc-linux dc007079 (bc-linux #174); the older Linux image gave U+202F.
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="en-US formatRegion="fr-FR">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<Language>en-US</Language>|<FormatRegion>fr-FR</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=-1234,5;D1Col=31/01/2025;D2Col=05/03/2024;DT1Col=31/01/2025 14:30:15;DT2Col=05/03/2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;TextsCol=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;');
        Observer.Expect('log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07 language=1033 region=[fr-FR];get=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;post=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;');
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07 language=1033 region=[fr-FR];get=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;post=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 March 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure BdSetter_DaDK()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'da-DK', true, 0);
#if BC29PLUS
        // Windows BC 29.0 check 2026-10-20 (bump 34 queue): every key measured (Windows NLS culture data; U+00A0 is a no-break space).
        // The Linux image at dbee8022 gives the same values (corpus CI 2026-10-20), so BC 29 has no hold.
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="en-US formatRegion="da-DK">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<ReportCaption>BD Region Setter</ReportCaption>|<Language>en-US</Language>|<FormatRegion>da-DK</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=-1234,5;D1Col=31-01-2025;D2Col=05-03-2024;DT1Col=31-01-2025 14:30:15;DT2Col=05-03-2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;TextsCol=1.234.567,891#-1.234,5#31-01-25#05-03-24#5. March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07;');
        Observer.Expect('log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1.234.567,891#-1.234,5#31-01-25#05-03-24#5. March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07 language=1033 region=[da-DK];get=1.234.567,891#-1.234,5#31-01-25#05-03-24#5. March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07;post=1.234.567,891#-1.234,5#31-01-25#05-03-24#5. March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07;');
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1.234.567,891#-1.234,5#31-01-25#05-03-24#5. March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07 language=1033 region=[da-DK];get=1.234.567,891#-1.234,5#31-01-25#05-03-24#5. March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07;post=1.234.567,891#-1.234,5#31-01-25#05-03-24#5. March 2024#31-01-25 14:30#05-03-24 09:05#14:30:15#09:05:07;');
        Observer.Verify();
#elif LT_HELD_BCLINUX_157
        // Held on Linux (LT_HELD_BCLINUX_157): these are the Linux values of the image before the bc-linux #157 fix. The image at dbee8022 formats
        // as Windows does, and the Windows runs (2026-10-20) differ from these values, but only the first difference was measured. Re-assert with
        // the full Windows values after the Windows check (windows-queue), then remove this hold; it does not end when bc-linux #157 closes.
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="en-US formatRegion="da-DK">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<Language>en-US</Language>|<FormatRegion>da-DK</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=-1234,5;D1Col=31-01-2025;D2Col=05-03-2024;DT1Col=31-01-2025 14.30.15;DT2Col=05-03-2024 09.05.07;T1Col=14.30.15;T2Col=09.05.07;TextsCol=1.234.567,891#-1.234,5#31-01-25#05-03-24#5. March 2024#31-01-25 14.30#05-03-24 09.05#14.30.15#09.05.07;');
        Observer.Expect('log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1.234.567,891#-1.234,5#31-01-25#05-03-24#5. March 2024#31-01-25 14.30#05-03-24 09.05#14.30.15#09.05.07 language=1033 region=[da-DK];get=1.234.567,891#-1.234,5#31-01-25#05-03-24#5. March 2024#31-01-25 14.30#05-03-24 09.05#14.30.15#09.05.07;post=1.234.567,891#-1.234,5#31-01-25#05-03-24#5. March 2024#31-01-25 14.30#05-03-24 09.05#14.30.15#09.05.07;');
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1.234.567,891#-1.234,5#31-01-25#05-03-24#5. March 2024#31-01-25 14.30#05-03-24 09.05#14.30.15#09.05.07 language=1033 region=[da-DK];get=1.234.567,891#-1.234,5#31-01-25#05-03-24#5. March 2024#31-01-25 14.30#05-03-24 09.05#14.30.15#09.05.07;post=1.234.567,891#-1.234,5#31-01-25#05-03-24#5. March 2024#31-01-25 14.30#05-03-24 09.05#14.30.15#09.05.07;');
        Observer.Verify();
#else
        Observer.Discard();
#endif
    end;

    [Test]
    procedure BdSetter_Lower()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'de-de', true, 0);
#if BC29PLUS
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="en-US formatRegion="de-de">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<ReportCaption>BD Region Setter</ReportCaption>|<Language>en-US</Language>|<FormatRegion>de-de</FormatRegion>|');
#else
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="en-US formatRegion="de-de">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<Language>en-US</Language>|<FormatRegion>de-de</FormatRegion>|');
#endif
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=-1234,5;D1Col=31.01.2025;D2Col=05.03.2024;DT1Col=31.01.2025 14:30:15;DT2Col=05.03.2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;TextsCol=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07;');
        Observer.Expect('log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07 language=1033 region=[de-de];get=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07;post=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07;');
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07 language=1033 region=[de-de];get=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07;post=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. March 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07;');
        Observer.Verify();
    end;

    [Test]
    procedure BdSetter_Neutral()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'de', true, 0);
        Observer.Expect('saveas|text', 'An unsupported language was selected (''de'' - ''Requested culture is not supported by the current platform'').');
        Observer.Expect('saveas|code', 'ReportFormatCultureNotFound');
        Observer.Expect('log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];');
        Observer.Expect('run ok', 'No');
        Observer.Expect('run|text', 'An unsupported language was selected (''de'' - ''Requested culture is not supported by the current platform'').');
        Observer.Expect('run|code', 'ReportFormatCultureNotFound');
        Observer.Expect('run log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];');
        Observer.Verify();
    end;

    [Test]
    procedure BdSetterLanguage_1031_EnUS()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterDataset(Observer, 'en-US', true, 1031);
#if BC29PLUS
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="de-DE formatRegion="en-US">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<ReportCaption>BD Region Setter</ReportCaption>|<Language>de-DE</Language>|<FormatRegion>en-US</FormatRegion>|');
#else
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="de-DE formatRegion="en-US">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<Language>de-DE</Language>|<FormatRegion>en-US</FormatRegion>|');
#endif
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567.891;NegCol[decimalformatter:#,##0.00=-1234.5;D1Col=1/31/2025;D2Col=3/5/2024;DT1Col=1/31/2025 2:30:15 PM;DT2Col=3/5/2024 9:05:07 AM;T1Col=2:30:15 PM;T2Col=9:05:07 AM;TextsCol=1,234,567.891#-1,234.5#01/31/25#03/05/24#März 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM;');
        Observer.Expect('log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1,234,567.891#-1,234.5#01/31/25#03/05/24#März 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1031 region=[];get=1,234,567.891#-1,234.5#01/31/25#03/05/24#März 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM;post=1,234,567.891#-1,234.5#01/31/25#03/05/24#März 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM;');
        Observer.Verify();
    end;

    [Test]
    procedure BdSetterLanguage_1031_EnUS_Run()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterRun(Observer, 'en-US', true, 1031);
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1,234,567.891#-1,234.5#01/31/25#03/05/24#März 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1031 region=[];get=1,234,567.891#-1,234.5#01/31/25#03/05/24#März 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM;post=1,234,567.891#-1,234.5#01/31/25#03/05/24#März 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM;');
        Observer.Verify();
    end;

    [Test]
    procedure BdSetterLanguage_1031_DeDE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'de-DE', true, 1031);
#if BC29PLUS
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="de-DE formatRegion="de-DE">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<ReportCaption>BD Region Setter</ReportCaption>|<Language>de-DE</Language>|<FormatRegion>de-DE</FormatRegion>|');
#else
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="de-DE formatRegion="de-DE">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<Language>de-DE</Language>|<FormatRegion>de-DE</FormatRegion>|');
#endif
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=-1234,5;D1Col=31.01.2025;D2Col=05.03.2024;DT1Col=31.01.2025 14:30:15;DT2Col=05.03.2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;TextsCol=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. März 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07;');
        Observer.Expect('log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. März 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07 language=1031 region=[de-DE];get=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. März 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07;post=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. März 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07;');
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. März 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07 language=1031 region=[de-DE];get=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. März 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07;post=1.234.567,891#-1.234,5#31.01.25#05.03.24#5. März 2024#31.01.25 14:30#05.03.24 09:05#14:30:15#09:05:07;');
        Observer.Verify();
    end;

    [Test]
    procedure BdSetterLanguage_1031_None()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterDataset(Observer, '', false, 1031);
#if BC29PLUS
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="de-DE formatRegion="en-US">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<ReportCaption>BD Region Setter</ReportCaption>|<Language>de-DE</Language>|<FormatRegion>en-US</FormatRegion>|');
#else
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="de-DE formatRegion="en-US">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<Language>de-DE</Language>|<FormatRegion>en-US</FormatRegion>|');
#endif
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567.891;NegCol[decimalformatter:#,##0.00=-1234.5;D1Col=1/31/2025;D2Col=3/5/2024;DT1Col=1/31/2025 2:30:15 PM;DT2Col=3/5/2024 9:05:07 AM;T1Col=2:30:15 PM;T2Col=9:05:07 AM;TextsCol=1,234,567.891#-1,234.5#01/31/25#03/05/24#März 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM;');
        Observer.Expect('log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1,234,567.891#-1,234.5#01/31/25#03/05/24#März 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1031 region=[];get=1,234,567.891#-1,234.5#01/31/25#03/05/24#März 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM;post=1,234,567.891#-1,234.5#01/31/25#03/05/24#März 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM;');
        Observer.Verify();
    end;

    [Test]
    procedure BdSetterLanguage_1031_None_Run()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterRun(Observer, '', false, 1031);
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1,234,567.891#-1,234.5#01/31/25#03/05/24#März 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1031 region=[];get=1,234,567.891#-1,234.5#01/31/25#03/05/24#März 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM;post=1,234,567.891#-1,234.5#01/31/25#03/05/24#März 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM;');
        Observer.Verify();
    end;

    [Test]
    procedure BdSetterLanguage_1036_Blank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, '', true, 1036);
        Observer.Expect('saveas|text', 'Invalid language ID supplied: 0.');
        Observer.Expect('saveas|code', 'Argument');
        Observer.Expect('log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];');
        Observer.Expect('run ok', 'No');
        Observer.Expect('run|text', 'Invalid language ID supplied: 0.');
        Observer.Expect('run|code', 'Argument');
        Observer.Expect('run log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];');
        Observer.Verify();
    end;

    [Test]
    procedure BdSetterLanguage_1036_EnUS()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterDataset(Observer, 'en-US', true, 1036);
#if BC29PLUS
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="fr-FR formatRegion="en-US">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<ReportCaption>BD Region Setter</ReportCaption>|<Language>fr-FR</Language>|<FormatRegion>en-US</FormatRegion>|');
#else
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="fr-FR formatRegion="en-US">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<Language>fr-FR</Language>|<FormatRegion>en-US</FormatRegion>|');
#endif
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567.891;NegCol[decimalformatter:#,##0.00=-1234.5;D1Col=1/31/2025;D2Col=3/5/2024;DT1Col=1/31/2025 2:30:15 PM;DT2Col=3/5/2024 9:05:07 AM;T1Col=2:30:15 PM;T2Col=9:05:07 AM;TextsCol=1,234,567.891#-1,234.5#01/31/25#03/05/24#mars 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM;');
        Observer.Expect('log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1,234,567.891#-1,234.5#01/31/25#03/05/24#mars 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1036 region=[];get=1,234,567.891#-1,234.5#01/31/25#03/05/24#mars 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM;post=1,234,567.891#-1,234.5#01/31/25#03/05/24#mars 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM;');
        Observer.Verify();
    end;

    [Test]
    procedure BdSetterLanguage_1036_EnUS_Run()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterRun(Observer, 'en-US', true, 1036);
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1,234,567.891#-1,234.5#01/31/25#03/05/24#mars 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1036 region=[];get=1,234,567.891#-1,234.5#01/31/25#03/05/24#mars 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM;post=1,234,567.891#-1,234.5#01/31/25#03/05/24#mars 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM;');
        Observer.Verify();
    end;

    [Test]
    procedure BdSetterLanguage_1033_EnUS()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterDataset(Observer, 'en-US', true, 1033);
#if BC29PLUS
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="en-US formatRegion="en-US">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<ReportCaption>BD Region Setter</ReportCaption>|<Language>en-US</Language>|<FormatRegion>en-US</FormatRegion>|');
#else
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="en-US formatRegion="en-US">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<Language>en-US</Language>|<FormatRegion>en-US</FormatRegion>|');
#endif
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567.891;NegCol[decimalformatter:#,##0.00=-1234.5;D1Col=1/31/2025;D2Col=3/5/2024;DT1Col=1/31/2025 2:30:15 PM;DT2Col=3/5/2024 9:05:07 AM;T1Col=2:30:15 PM;T2Col=9:05:07 AM;TextsCol=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM;');
        Observer.Expect('log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];get=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM;post=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM;');
        Observer.Verify();
    end;

    [Test]
    procedure BdSetterLanguage_1033_EnUS_Run()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterRun(Observer, 'en-US', true, 1033);
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];get=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM;post=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM;');
        Observer.Verify();
    end;

    [Test]
    procedure BdSetterLanguage_1030_FrFR()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setter(Observer, 'fr-FR', true, 1030);
#if BC29PLUS
        // Windows BC 29.0 check 2026-10-20 (bump 34 queue): every key measured (Windows NLS culture data; U+00A0 is a no-break space).
        // It was held on Linux BC 29 under bc-linux #167 (LT_HELD_BCLINUX_167); lifted with the bc-linux pin bcc60c1c (corpus bump 42).
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="da-DK formatRegion="fr-FR">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<ReportCaption>BD Region Setter</ReportCaption>|<Language>da-DK</Language>|<FormatRegion>fr-FR</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=-1234,5;D1Col=31/01/2025;D2Col=05/03/2024;DT1Col=31/01/2025 14:30:15;DT2Col=05/03/2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;TextsCol=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 marts 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;');
        Observer.Expect('log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 marts 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07 language=1030 region=[fr-FR];get=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 marts 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;post=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 marts 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;');
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 marts 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07 language=1030 region=[fr-FR];get=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 marts 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;post=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 marts 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;');
        Observer.Verify();
#else
        // BC 27 and 28: the fr-FR group separator is U+00A0 as on Windows BC 27.5 and 28.5 (Windows runs 2026-10-20 and 2026-10-22: only
        // U+00A0 occurs) and on bc-linux dc007079 (bc-linux #174); the older Linux image gave U+202F.
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter id:81068 language="da-DK formatRegion="fr-FR">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter</ReportName>|<Language>da-DK</Language>|<FormatRegion>fr-FR</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;NegCol[decimalformatter:#,##0.00=-1234,5;D1Col=31/01/2025;D2Col=05/03/2024;DT1Col=31/01/2025 14:30:15;DT2Col=05/03/2024 09:05:07;T1Col=14:30:15;T2Col=09:05:07;TextsCol=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 marts 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;');
        Observer.Expect('log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 marts 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07 language=1030 region=[fr-FR];get=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 marts 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;post=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 marts 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;');
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'before=1,234,567.891#-1,234.5#01/31/25#03/05/24#March 5, 2024#01/31/25 02:30 PM#03/05/24 09:05 AM# 2:30:15 PM# 9:05:07 AM language=1033 region=[];after=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 marts 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07 language=1030 region=[fr-FR];get=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 marts 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;post=1 234 567,891#-1 234,5#31/01/25#05/03/24#5 marts 2024#31/01/25 14:30#05/03/24 09:05#14:30:15#09:05:07;');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure BdSetterInPropertyReport_FrFR()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.SetCulture('fr-FR', true, 0);
        Dataset(Observer, Report::"BD Region Setter De");
        Log.SetCulture('', false, 0);
#if BC29PLUS
        // Windows BC 29.0 check 2026-10-20 (bump 34 queue): every key measured (Windows NLS culture data; U+00A0 is a no-break space).
        // It was held on Linux BC 29 under bc-linux #167 (LT_HELD_BCLINUX_167); lifted with the bc-linux pin bcc60c1c (corpus bump 42).
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter De id:81076 language="en-US formatRegion="fr-FR">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter De</ReportName>|<ReportCaption>BD Region Setter De</ReportCaption>|<Language>en-US</Language>|<FormatRegion>fr-FR</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;D2Col=05/03/2024;DT2Col=05/03/2024 09:05:07;TextsCol=1 234 567,891#05/03/24#05/03/24 09:05;');
        Observer.Expect('log', 'before=1.234.567,891#05.03.24#05.03.24 09:05 region=[de-DE];after=1 234 567,891#05/03/24#05/03/24 09:05 region=[fr-FR];get=1 234 567,891#05/03/24#05/03/24 09:05 region=[fr-FR];');
        Observer.Verify();
#else
        // BC 27 and 28: the fr-FR group separator is U+00A0 as on Windows BC 27.5 and 28.5 (Windows runs 2026-10-20 and 2026-10-22: only
        // U+00A0 occurs) and on bc-linux dc007079 (bc-linux #174); the older Linux image gave U+202F.
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter De id:81076 language="en-US formatRegion="fr-FR">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter De</ReportName>|<Language>en-US</Language>|<FormatRegion>fr-FR</FormatRegion>|');
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;D2Col=05/03/2024;DT2Col=05/03/2024 09:05:07;TextsCol=1 234 567,891#05/03/24#05/03/24 09:05;');
        Observer.Expect('log', 'before=1.234.567,891#05.03.24#05.03.24 09:05 region=[de-DE];after=1 234 567,891#05/03/24#05/03/24 09:05 region=[fr-FR];get=1 234 567,891#05/03/24#05/03/24 09:05 region=[fr-FR];');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure BdSetterInPropertyReport_EnUS()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.SetCulture('en-US', true, 0);
        Dataset(Observer, Report::"BD Region Setter De");
        Log.SetCulture('', false, 0);
#if BC29PLUS
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter De id:81076 language="en-US formatRegion="en-US">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter De</ReportName>|<ReportCaption>BD Region Setter De</ReportCaption>|<Language>en-US</Language>|<FormatRegion>en-US</FormatRegion>|');
#else
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter De id:81076 language="en-US formatRegion="en-US">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter De</ReportName>|<Language>en-US</Language>|<FormatRegion>en-US</FormatRegion>|');
#endif
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567.891;D2Col=3/5/2024;DT2Col=3/5/2024 9:05:07 AM;TextsCol=1,234,567.891#03/05/24#03/05/24 09:05 AM;');
        Observer.Expect('log', 'before=1.234.567,891#05.03.24#05.03.24 09:05 region=[de-DE];after=1,234,567.891#03/05/24#03/05/24 09:05 AM region=[en-US];get=1,234,567.891#03/05/24#03/05/24 09:05 AM region=[en-US];');
        Observer.Verify();
    end;

    [Test]
    procedure BdSetterInPropertyReport_Blank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.SetCulture('', true, 0);
        Dataset(Observer, Report::"BD Region Setter De");
        Log.SetCulture('', false, 0);
        Observer.Expect('saveas|text', 'Invalid language ID supplied: 0.');
        Observer.Expect('saveas|code', 'Argument');
        Observer.Expect('log', 'before=1.234.567,891#05.03.24#05.03.24 09:05 region=[de-DE];');
        Observer.Verify();
    end;

    [Test]
    procedure BdSetterInPropertyReport_None()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.SetCulture('', false, 0);
        Dataset(Observer, Report::"BD Region Setter De");
        Log.SetCulture('', false, 0);
#if BC29PLUS
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter De id:81076 language="en-US formatRegion="de-DE">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter De</ReportName>|<ReportCaption>BD Region Setter De</ReportCaption>|<Language>en-US</Language>|<FormatRegion>de-DE</FormatRegion>|');
#else
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter De id:81076 language="en-US formatRegion="de-DE">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter De</ReportName>|<Language>en-US</Language>|<FormatRegion>de-DE</FormatRegion>|');
#endif
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567,891;D2Col=05.03.2024;DT2Col=05.03.2024 09:05:07;TextsCol=1.234.567,891#05.03.24#05.03.24 09:05;');
        Observer.Expect('log', 'before=1.234.567,891#05.03.24#05.03.24 09:05 region=[de-DE];after=1.234.567,891#05.03.24#05.03.24 09:05 region=[de-DE];get=1.234.567,891#05.03.24#05.03.24 09:05 region=[de-DE];');
        Observer.Verify();
    end;

    [Test]
    procedure BdSetterInPropertyReport_JaJP()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.SetCulture('ja-JP', true, 0);
        Dataset(Observer, Report::"BD Region Setter De");
        Log.SetCulture('', false, 0);
#if BC29PLUS
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter De id:81076 language="en-US formatRegion="ja-JP">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter De</ReportName>|<ReportCaption>BD Region Setter De</ReportCaption>|<Language>en-US</Language>|<FormatRegion>ja-JP</FormatRegion>|');
#else
        Observer.Expect('header', '<ReportDataSet name="BD Region Setter De id:81076 language="en-US formatRegion="ja-JP">|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<ExtensionPublisher>AL Language</ExtensionPublisher>|<ReportName>BD Region Setter De</ReportName>|<Language>en-US</Language>|<FormatRegion>ja-JP</FormatRegion>|');
#endif
        Observer.Expect('columns', 'AmtCol[decimalformatter:#,##0.00=1234567.891;D2Col=2024/03/05;DT2Col=2024/03/05 9:05:07;TextsCol=1,234,567.891#24/03/05#24/03/05 09:05;');
        Observer.Expect('log', 'before=1.234.567,891#05.03.24#05.03.24 09:05 region=[de-DE];after=1,234,567.891#24/03/05#24/03/05 09:05 region=[ja-JP];get=1,234,567.891#24/03/05#24/03/05 09:05 region=[ja-JP];');
        Observer.Verify();
    end;

    [Test]
    procedure BdDecimalFormatter_Columns()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BD Amount Row";
        Xml: Text;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Plain := 1234.567;
        Row.Places25 := 1234.567;
        Row.Places00 := 1234.567;
        Row.Auto1 := 1234.567;
        Row.Auto2 := 1234.567;
        Row.Insert();
        Xml := Helper.SaveAsXml(Report::"BD Decimal Formatter");
        Observer.Observe('columns', Helper.Columns(Xml));
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Plain := 1234.5;
        Row.Places25 := 1234.5;
        Row.Places00 := 1234;
        Row.Auto1 := 1234.5;
        Row.Auto2 := 1234.5;
        Row.Insert();
        Xml := Helper.SaveAsXml(Report::"BD Decimal Formatter");
        Observer.Observe('columns short', Helper.Columns(Xml));
        Row.DeleteAll();
        Observer.Expect('columns', 'Plain[decimalformatter:#,##0.00=1234.567;Places25[decimalformatter:#,##0.00###=1234.567;Places00[decimalformatter:#,##0=1234.567;Auto1[decimalformatter:#,##0.00=1234.567;Auto2[decimalformatter:#,##0.00###=1234.567;V0[decimalformatter:#,##0.00=1234;V1[decimalformatter:#,##0.00=1234.5;V2[decimalformatter:#,##0.00=1234.56;V3[decimalformatter:#,##0.00=1234.567;V4[decimalformatter:#,##0.00=1234.5678;V5[decimalformatter:#,##0.00=1234.56789;V6[decimalformatter:#,##0.00=1234.567891;VNeg3[decimalformatter:#,##0.00=-1234.567;VSmall[decimalformatter:#,##0.00=0.125;VExpr[decimalformatter:#,##0.00=2469.134;VExpr2[decimalformatter:#,##0.00=1235.567;');
        Observer.Expect('columns short', 'Plain[decimalformatter:#,##0.00=1234.5;Places25[decimalformatter:#,##0.00###=1234.5;Places00[decimalformatter:#,##0=1234;Auto1[decimalformatter:#,##0.00=1234.5;Auto2[decimalformatter:#,##0.00###=1234.5;V0[decimalformatter:#,##0.00=1234;V1[decimalformatter:#,##0.00=1234.5;V2[decimalformatter:#,##0.00=1234.56;V3[decimalformatter:#,##0.00=1234.567;V4[decimalformatter:#,##0.00=1234.5678;V5[decimalformatter:#,##0.00=1234.56789;V6[decimalformatter:#,##0.00=1234.567891;VNeg3[decimalformatter:#,##0.00=-1234.567;VSmall[decimalformatter:#,##0.00=0.125;VExpr[decimalformatter:#,##0.00=2469.134;VExpr2[decimalformatter:#,##0.00=1235.5;');
        Observer.Verify();
    end;

    [Test]
    procedure BdSummaryML_1033()
    var
        Observer: Codeunit "Probe Observer";
        YHelper: Codeunit "LT Y Helper";
        Original: Integer;
        Result: Text;
    begin
        Original := GlobalLanguage();
        if not TryGlobalLanguage(1033) then
            Observer.ObserveError('globallanguage');
        Result := YHelper.LayoutSummaries(Report::"BD Summary Langs");
        GlobalLanguage(Original);
        Observer.Observe('layouts', Result);
        Observer.Expect('layouts', 'SumAll=English all;SumDanOnly=SumDanOnly;SumNoEnu=SumNoEnu;');
        Observer.Verify();
    end;

    [Test]
    procedure BdSummaryML_1031()
    var
        Observer: Codeunit "Probe Observer";
        YHelper: Codeunit "LT Y Helper";
        Original: Integer;
        Result: Text;
    begin
        Original := GlobalLanguage();
        if not TryGlobalLanguage(1031) then
            Observer.ObserveError('globallanguage');
        Result := YHelper.LayoutSummaries(Report::"BD Summary Langs");
        GlobalLanguage(Original);
        Observer.Observe('layouts', Result);
        Observer.Expect('layouts', 'SumAll=Deutsch alle;SumDanOnly=SumDanOnly;SumNoEnu=Deutsch ohne;');
        Observer.Verify();
    end;

    [Test]
    procedure BdSummaryML_1036()
    var
        Observer: Codeunit "Probe Observer";
        YHelper: Codeunit "LT Y Helper";
        Original: Integer;
        Result: Text;
    begin
        Original := GlobalLanguage();
        if not TryGlobalLanguage(1036) then
            Observer.ObserveError('globallanguage');
        Result := YHelper.LayoutSummaries(Report::"BD Summary Langs");
        GlobalLanguage(Original);
        Observer.Observe('layouts', Result);
        Observer.Expect('layouts', 'SumAll=Francais tous;SumDanOnly=SumDanOnly;SumNoEnu=Francais sans;');
        Observer.Verify();
    end;

    [Test]
    procedure BdSummaryML_1030()
    var
        Observer: Codeunit "Probe Observer";
        YHelper: Codeunit "LT Y Helper";
        Original: Integer;
        Result: Text;
    begin
        Original := GlobalLanguage();
        if not TryGlobalLanguage(1030) then
            Observer.ObserveError('globallanguage');
        Result := YHelper.LayoutSummaries(Report::"BD Summary Langs");
        GlobalLanguage(Original);
        Observer.Observe('layouts', Result);
        Observer.Expect('layouts', 'SumAll=Dansk alle;SumDanOnly=Kun dansk;SumNoEnu=SumNoEnu;');
        Observer.Verify();
    end;

    [Test]
    procedure BdSummaryML_1043()
    var
        Observer: Codeunit "Probe Observer";
        YHelper: Codeunit "LT Y Helper";
        Original: Integer;
        Result: Text;
    begin
        Original := GlobalLanguage();
        if not TryGlobalLanguage(1043) then
            Observer.ObserveError('globallanguage');
        Result := YHelper.LayoutSummaries(Report::"BD Summary Langs");
        GlobalLanguage(Original);
        Observer.Observe('layouts', Result);
        Observer.Expect('layouts', 'SumAll=Nederlands alle;SumDanOnly=SumDanOnly;SumNoEnu=SumNoEnu;');
        Observer.Verify();
    end;

    [Test]
    procedure BdSummaryML_1040()
    var
        Observer: Codeunit "Probe Observer";
        YHelper: Codeunit "LT Y Helper";
        Original: Integer;
        Result: Text;
    begin
        Original := GlobalLanguage();
        if not TryGlobalLanguage(1040) then
            Observer.ObserveError('globallanguage');
        Result := YHelper.LayoutSummaries(Report::"BD Summary Langs");
        GlobalLanguage(Original);
        Observer.Observe('layouts', Result);
        Observer.Expect('layouts', 'SumAll=English all;SumDanOnly=SumDanOnly;SumNoEnu=SumNoEnu;');
        Observer.Verify();
    end;

    // Y17 (gap cycle 1, G3b): CurrReport.FormatRegion := a region after CurrReport.Language := its own language (not en-US), dataset
    // part and Run part in separate tests; and es-ES_tradnl alone. Measured on Windows (SaaS BC 29) first: NLS culture data.

    [Test]
    procedure BdSetterLanguage_1034_EsEsTradnl()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterDataset(Observer, 'es-ES_tradnl', true, 1034);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetterLanguage_1034_EsEsTradnl_Run()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterRun(Observer, 'es-ES_tradnl', true, 1034);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetterLanguage_2057_EnGB()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterDataset(Observer, 'en-GB', true, 2057);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetterLanguage_2057_EnGB_Run()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterRun(Observer, 'en-GB', true, 2057);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetterLanguage_1043_NlNL()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterDataset(Observer, 'nl-NL', true, 1043);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetterLanguage_1043_NlNL_Run()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterRun(Observer, 'nl-NL', true, 1043);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetterLanguage_1030_DaDK()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterDataset(Observer, 'da-DK', true, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetterLanguage_1030_DaDK_Run()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterRun(Observer, 'da-DK', true, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure BdSetter_EsEsTradnl()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetterDataset(Observer, 'es-ES_tradnl', true, 0);
        Observer.Finish();
    end;
}
