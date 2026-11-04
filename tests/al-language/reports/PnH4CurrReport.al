// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/reportinstance/reportinstance-data-type
// Scope: in-scope
// Fixtures used: tables and helper of PnH1Fix.al; SingleInstance log 70610 is used only by test codeunit 70613
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Probes-needed row: Report | `CurrReport.Skip`/`Break`/`Quit` ... `Language` and `FormatRegion` (the setter form changes the culture of `Format`),
// `Preview` outside a `Run` or `RunModal`, layout accessors and page-number methods.
// The CurrReport members read in each way of starting a report (Run, RunModal, Execute, SaveAs) and the effect of Language / FormatRegion on Format.
// BC versions: 29 (27 and 28 by CI)

codeunit 70610 "LT PnH CurrRpt Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        Region: Text;
        LanguageId: Integer;

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

    procedure SetCulture(NewRegion: Text; NewLanguage: Integer)
    begin
        Region := NewRegion;
        LanguageId := NewLanguage;
    end;

    procedure GetRegion(): Text
    begin
        exit(Region);
    end;

    procedure GetLanguage(): Integer
    begin
        exit(LanguageId);
    end;
}

report 70611 "LT PnH CurrRpt"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT PnH Row")
        {
            DataItemTableView = sorting(Id) where(Id = const(1));

            trigger OnAfterGetRecord()
            begin
                L.Add('get pageno=' + Format(CurrReport.PageNo()) + ' preview=' + Format(CurrReport.Preview()) + ' showoutput=' + Format(CurrReport.ShowOutput()));
            end;
        }
    }

    trigger OnPreReport()
    begin
        L.Add('pre preview=' + Format(CurrReport.Preview()));
        L.Add('pre objectid false=' + CurrReport.ObjectId(false));
        L.Add('pre objectid true=' + CurrReport.ObjectId(true));
        L.Add('pre pageno=' + Format(CurrReport.PageNo()));
        L.Add('pre language=' + Format(CurrReport.Language()));
        L.Add('pre region=[' + CurrReport.FormatRegion() + ']');
        L.Add('pre targetformat=' + Format(CurrReport.TargetFormat()));
        L.Add('pre readonly=' + Format(CurrReport.IsReadOnly()));
    end;

    trigger OnPostReport()
    begin
        L.Add('post preview=' + Format(CurrReport.Preview()));
        L.Add('post pageno=' + Format(CurrReport.PageNo()));
    end;

    var
        L: Codeunit "LT PnH CurrRpt Log";
}

// Sets Language and FormatRegion from the log and logs what Format makes of a few values.
report 70612 "LT PnH CurrRptCulture"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT PnH Row")
        {
            DataItemTableView = sorting(Id) where(Id = const(1));

            trigger OnAfterGetRecord()
            begin
                L.Add('get dec=' + Format(1234.5) + ' date=' + Format(DMY2Date(5, 3, 2024)) + ' bool=' + Format(true));
            end;
        }
    }

    trigger OnPreReport()
    begin
        L.Add('before dec=' + Format(1234.5) + ' date=' + Format(DMY2Date(5, 3, 2024)) + ' bool=' + Format(true));
        if L.GetLanguage() <> 0 then
            CurrReport.Language := L.GetLanguage();
        if L.GetRegion() <> '' then
            CurrReport.FormatRegion := L.GetRegion();
        L.Add('language=' + Format(CurrReport.Language()) + ' region=[' + CurrReport.FormatRegion() + ']');
        L.Add('after dec=' + Format(1234.5) + ' date=' + Format(DMY2Date(5, 3, 2024)) + ' bool=' + Format(true));
    end;

    trigger OnPostReport()
    begin
        L.Add('post dec=' + Format(1234.5) + ' bool=' + Format(true));
    end;

    var
        L: Codeunit "LT PnH CurrRpt Log";
}

codeunit 70613 "LT PnH CurrRpt Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT PnH CurrRpt Log";
        Helper: Codeunit "LT PnH Helper";

    local procedure Start()
    begin
        Helper.Seed();
        L.Take();
        L.SetCulture('', 0);
    end;

    local procedure SaveAs(ReportId: Integer): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        exit(Report.SaveAs(ReportId, '', ReportFormat::Xml, OutS));
    end;

    [Test]
    procedure Members_Run()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Report.Run(Report::"LT PnH CurrRpt");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'pre preview=No;pre objectid false=Report 70611;pre objectid true=Report LT PnH CurrRpt;pre pageno=1;pre language=1033;pre region=[];pre targetformat=None;pre readonly=No;get pageno=1 preview=No showoutput=No;post preview=No;post pageno=1;');
        Observer.Verify();
    end;

    [Test]
    procedure Members_RunModal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Report.RunModal(Report::"LT PnH CurrRpt");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'pre preview=No;pre objectid false=Report 70611;pre objectid true=Report LT PnH CurrRpt;pre pageno=1;pre language=1033;pre region=[];pre targetformat=None;pre readonly=No;get pageno=1 preview=No showoutput=No;post preview=No;post pageno=1;');
        Observer.Verify();
    end;

    [Test]
    procedure Members_Execute()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Report.Execute(Report::"LT PnH CurrRpt", '');
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'pre preview=Yes;pre objectid false=Report 70611;pre objectid true=Report LT PnH CurrRpt;pre pageno=1;pre language=1033;pre region=[];pre targetformat=None;pre readonly=No;get pageno=1 preview=Yes showoutput=No;post preview=Yes;post pageno=1;');
        Observer.Verify();
    end;

    [Test]
    procedure Members_SaveAs()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Observer.Observe('saveas', Format(SaveAs(Report::"LT PnH CurrRpt")));
        Observer.Observe('log', L.Take());
        Observer.Expect('saveas', 'No');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    procedure Members_VariableRun()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT PnH CurrRpt";
    begin
        Start();
        Rpt.Run();
        Observer.Observe('run', L.Take());
        Rpt.RunModal();
        Observer.Observe('runmodal', L.Take());
        Observer.Expect('run', 'pre preview=No;pre objectid false=Report 70611;pre objectid true=Report LT PnH CurrRpt;pre pageno=1;pre language=1033;pre region=[];pre targetformat=None;pre readonly=No;get pageno=1 preview=No showoutput=No;post preview=No;post pageno=1;');
        Observer.Expect('runmodal', 'pre preview=No;pre objectid false=Report 70611;pre objectid true=Report LT PnH CurrRpt;pre pageno=1;pre language=1033;pre region=[];pre targetformat=None;pre readonly=No;get pageno=1 preview=No showoutput=No;post preview=No;post pageno=1;');
        Observer.Verify();
    end;

    [Test]
    procedure Culture_FormatRegion_ChangesFormat()
    var
        Observer: Codeunit "Probe Observer";
        Regions: List of [Text];
        Region: Text;
    begin
        Start();
        Regions.Add('de-DE');
        Regions.Add('en-US');
        Regions.Add('fr-FR');
        Regions.Add('da-DK');
        foreach Region in Regions do begin
            L.SetCulture(Region, 0);
            Report.Run(Report::"LT PnH CurrRptCulture");
            Observer.Observe('af227', 'no error');
            Observer.Observe('af227', 'no error');
            Observer.Observe(Region, L.Take());
        end;
        Observer.Observe('after', Format(1234.5) + '|' + Format(DMY2Date(5, 3, 2024)));
        Observer.Expect('af227', 'no error');
        Observer.Expect('af227', 'no error');
        Observer.Expect('de-DE', 'before dec=1,234.5 date=03/05/24 bool=Yes;language=1033 region=[de-DE];after dec=1.234,5 date=05.03.24 bool=Yes;get dec=1.234,5 date=05.03.24 bool=Yes;post dec=1.234,5 bool=Yes;');
        Observer.Expect('af227', 'no error');
        Observer.Expect('af227', 'no error');
        Observer.Expect('en-US', 'before dec=1,234.5 date=03/05/24 bool=Yes;language=1033 region=[];after dec=1,234.5 date=03/05/24 bool=Yes;get dec=1,234.5 date=03/05/24 bool=Yes;post dec=1,234.5 bool=Yes;');
        Observer.Expect('af227', 'no error');
        Observer.Expect('af227', 'no error');
        // The fr-FR group separator is U+00A0 (no-break space) on Windows BC 27.5, 28.5 and 29.0 (full corpus runs on the Windows
        // containers, 2026-10-20) and on bc-linux dc007079 for BC 27, 28 and 29 (bc-linux #174; the older image gave U+202F on BC 27/28).
        Observer.Expect('fr-FR', 'before dec=1,234.5 date=03/05/24 bool=Yes;language=1033 region=[fr-FR];after dec=1 234,5 date=05/03/24 bool=Yes;get dec=1 234,5 date=05/03/24 bool=Yes;post dec=1 234,5 bool=Yes;');
        Observer.Expect('af227', 'no error');
        Observer.Expect('af227', 'no error');
        Observer.Expect('da-DK', 'before dec=1,234.5 date=03/05/24 bool=Yes;language=1033 region=[da-DK];after dec=1.234,5 date=05-03-24 bool=Yes;get dec=1.234,5 date=05-03-24 bool=Yes;post dec=1.234,5 bool=Yes;');
        Observer.Expect('after', '1,234.5|03/05/24');
        Observer.Verify();
    end;

    [Test]
    procedure Culture_Language_ChangesFormat()
    var
        Observer: Codeunit "Probe Observer";
        Ids: List of [Integer];
        Id: Integer;
    begin
        Start();
        Ids.Add(1031);
        Ids.Add(1036);
        Ids.Add(1033);
        Ids.Add(0);
        foreach Id in Ids do begin
            L.SetCulture('', Id);
            Report.Run(Report::"LT PnH CurrRptCulture");
            Observer.Observe('af251', 'no error');
            Observer.Observe('af250', 'no error');
            Observer.Observe('language ' + Format(Id), L.Take());
        end;
        Observer.Observe('after', Format(1234.5) + '|' + Format(DMY2Date(5, 3, 2024)));
        Observer.Expect('af251', 'no error');
        Observer.Expect('af250', 'no error');
        Observer.Expect('language 1031', 'before dec=1,234.5 date=03/05/24 bool=Yes;language=1031 region=[];after dec=1,234.5 date=03/05/24 bool=Ja;get dec=1,234.5 date=03/05/24 bool=Ja;post dec=1,234.5 bool=Ja;');
        Observer.Expect('af251', 'no error');
        Observer.Expect('af250', 'no error');
        Observer.Expect('language 1036', 'before dec=1,234.5 date=03/05/24 bool=Yes;language=1036 region=[];after dec=1,234.5 date=03/05/24 bool=Oui;get dec=1,234.5 date=03/05/24 bool=Oui;post dec=1,234.5 bool=Oui;');
        Observer.Expect('af251', 'no error');
        Observer.Expect('af250', 'no error');
        Observer.Expect('language 1033', 'before dec=1,234.5 date=03/05/24 bool=Yes;language=1033 region=[];after dec=1,234.5 date=03/05/24 bool=Yes;get dec=1,234.5 date=03/05/24 bool=Yes;post dec=1,234.5 bool=Yes;');
        Observer.Expect('af251', 'no error');
        Observer.Expect('af250', 'no error');
        Observer.Expect('language 0', 'before dec=1,234.5 date=03/05/24 bool=Yes;language=1033 region=[];after dec=1,234.5 date=03/05/24 bool=Yes;get dec=1,234.5 date=03/05/24 bool=Yes;post dec=1,234.5 bool=Yes;');
        Observer.Expect('after', '1,234.5|03/05/24');
        Observer.Verify();
    end;

    [Test]
    procedure Culture_LanguageAndRegion_Together()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        L.SetCulture('de-DE', 1036);
        Report.Run(Report::"LT PnH CurrRptCulture");
        Observer.Observe('de-DE + 1036', L.Take());
        L.SetCulture('fr-FR', 1031);
        Report.Run(Report::"LT PnH CurrRptCulture");
        Observer.Observe('fr-FR + 1031', L.Take());
        L.SetCulture('', 0);
        Observer.Expect('de-DE + 1036', 'before dec=1,234.5 date=03/05/24 bool=Yes;language=1036 region=[de-DE];after dec=1.234,5 date=05.03.24 bool=Oui;get dec=1.234,5 date=05.03.24 bool=Oui;post dec=1.234,5 bool=Oui;');
        // The fr-FR group separator is U+00A0 (no-break space) on Windows BC 27.5, 28.5 and 29.0 (full corpus runs on the Windows
        // containers, 2026-10-20) and on bc-linux dc007079 for BC 27, 28 and 29 (bc-linux #174; the older image gave U+202F on BC 27/28).
        Observer.Expect('fr-FR + 1031', 'before dec=1,234.5 date=03/05/24 bool=Yes;language=1031 region=[fr-FR];after dec=1 234,5 date=05/03/24 bool=Ja;get dec=1 234,5 date=05/03/24 bool=Ja;post dec=1 234,5 bool=Ja;');
        Observer.Verify();
    end;
}
