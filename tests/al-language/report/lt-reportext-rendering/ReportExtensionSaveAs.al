// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (System Application); reports 72955 / 72957 and their report extensions in ReportExtensionRendering.al
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced.
// Facts: the static Report.SaveAs (report id, request parameters, format, stream, optional RecordRef) of a report that has a report extension with a
//   rendering section: Xml and Pdf of the base report that declares its own RDLC layout (the extension adds two RDLC layouts), the same for a base
//   report without a rendering section whose extension is the only one that declares a layout, Word and Excel on an RDLC default layout, and a
//   call with a RecordRef. Each case records the answer, whether the stream got bytes, the start of the stream and the error text.
// BC versions: 27, 28, 29
report 91212 "LT SC SaveAs Plain"
{
    UsageCategory = None;
    Caption = 'LT SC SaveAs plain';
    DefaultRenderingLayout = PlainRdlc;

    dataset
    {
        dataitem(Item; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(Num; Number) { }
        }
    }

    rendering
    {
        layout(PlainRdlc)
        {
            Type = RDLC;
            LayoutFile = './FixtureLayout_14.rdlc';
            Caption = 'SaveAs plain layout';
        }
    }
}

codeunit 91210 "LT SC ReportExt SaveAs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySave(ReportId: Integer; Fmt: ReportFormat; WithRecordRef: Boolean; var Saved: Boolean; var Size: Integer; var Head: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        OutS: OutStream;
        InS: InStream;
    begin
        Saved := false;
        Size := 0;
        Head := '';
        TempBlob.CreateOutStream(OutS);
        if WithRecordRef then begin
            RecRef.Open(Database::Integer);
            Saved := Report.SaveAs(ReportId, '', Fmt, OutS, RecRef);
        end else
            Saved := Report.SaveAs(ReportId, '', Fmt, OutS);
        Size := TempBlob.Length();
        if Size > 0 then begin
            TempBlob.CreateInStream(InS, TextEncoding::UTF8);
            InS.Read(Head, 20);
        end;
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; ReportId: Integer; Fmt: ReportFormat; WithRecordRef: Boolean)
    var
        Saved: Boolean;
        Size: Integer;
        Head: Text;
        Completed: Boolean;
    begin
        ClearLastError();
        Completed := TrySave(ReportId, Fmt, WithRecordRef, Saved, Size, Head);
        Observer.Observe(Name + ' completed', Format(Completed));
        Observer.Observe(Name + ' saved', Format(Saved));
        Observer.Observe(Name + ' has bytes', Format(Size > 0));
        Observer.Observe(Name + ' head', Head);
        Observer.ObserveError(Name + ' err');
    end;

    [Test]
    procedure ControlReportWithoutExtension_Xml_Pdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'xml', 91212, ReportFormat::Xml, false);
        Probe(Observer, 'pdf', 91212, ReportFormat::Pdf, false);
        Observer.Finish();
    end;

    [Test]
    procedure BaseWithOwnLayout_Xml_Pdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'xml', 72955, ReportFormat::Xml, false);
        Probe(Observer, 'pdf', 72955, ReportFormat::Pdf, false);
        Probe(Observer, 'xml recref', 72955, ReportFormat::Xml, true);
        Observer.Finish();
    end;

    [Test]
    procedure BaseWithOwnLayout_Word_Excel_Html()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'word', 72955, ReportFormat::Word, false);
        Probe(Observer, 'excel', 72955, ReportFormat::Excel, false);
        Probe(Observer, 'html', 72955, ReportFormat::Html, false);
        Observer.Finish();
    end;

    [Test]
    procedure BaseWithoutRendering_ExtensionOnlyLayout()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'xml', 72957, ReportFormat::Xml, false);
        Probe(Observer, 'pdf', 72957, ReportFormat::Pdf, false);
        Probe(Observer, 'word', 72957, ReportFormat::Word, false);
        Observer.Finish();
    end;
}
