// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (System Application); own reports 91212, 91213, 91215 and report extensions 91214, 91216
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced.
// Facts: the static Report.SaveAs (report id, request parameters, format, stream, optional RecordRef) of a report that has a report extension with a
//   rendering section: Xml and Pdf of the base report that declares its own RDLC layout (the extension adds two RDLC layouts), the same for a base
//   report without a rendering section whose extension is the only one that declares a layout, Word and Excel on an RDLC default layout, and a
//   call with a RecordRef. Each case records the answer, whether the stream got bytes, the kind of content the stream starts with (pdf, xml, zip for Word and Excel) and the error text.
// BC versions: 27, 28, 29
report 91213 "LT SC Ext Base"
{
    UsageCategory = None;
    Caption = 'LT SC ext base';
    DefaultRenderingLayout = BaseRdlc;

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
        layout(BaseRdlc)
        {
            Type = RDLC;
            LayoutFile = './FixtureLayout_15.rdlc';
            Caption = 'SaveAs base layout';
        }
    }
}

report 91215 "LT SC Ext Base NoRender"
{
    UsageCategory = None;
    Caption = 'LT SC ext base no rendering';

    dataset
    {
        dataitem(Item; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(Num; Number) { }
        }
    }
}

reportextension 91214 "LT SC Ext Rendering" extends "LT SC Ext Base"
{
    rendering
    {
        layout(ExtRdlcA)
        {
            Type = RDLC;
            LayoutFile = './FixtureLayout_16.rdlc';
            Caption = 'SaveAs ext A';
        }
        layout(ExtRdlcB)
        {
            Type = RDLC;
            LayoutFile = './FixtureLayout_17.rdlc';
            Caption = 'SaveAs ext B';
        }
    }
}

reportextension 91216 "LT SC Ext NoRender Ext" extends "LT SC Ext Base NoRender"
{
    rendering
    {
        layout(ExtOnly)
        {
            Type = RDLC;
            LayoutFile = './FixtureLayout_18.rdlc';
            Caption = 'SaveAs ext only';
        }
    }
}

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
            TempBlob.CreateInStream(InS, TextEncoding::MSDos);
            InS.Read(Head, 20);
        end;
    end;

    local procedure Kind(Head: Text): Text
    begin
        if Head = '' then
            exit('empty');
        if Head.Contains('%PDF') then
            exit('pdf');
        if Head.Contains('<?xml') then
            exit('xml');
        if Head.StartsWith('PK') then
            exit('zip');
        exit('other');
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
        Observer.Observe(Name + ' content', Kind(Head));
        Observer.ObserveError(Name + ' err');
    end;

    [Test]
    procedure ControlReportWithoutExtension_Xml_Pdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'xml', 91212, ReportFormat::Xml, false);
        Probe(Observer, 'pdf', 91212, ReportFormat::Pdf, false);
        Observer.Expect('xml completed', 'Yes');
        Observer.Expect('xml saved', 'Yes');
        Observer.Expect('xml has bytes', 'Yes');
        Observer.Expect('xml content', 'xml');
        Observer.Expect('xml err|text', '');
        Observer.Expect('xml err|code', '');
        Observer.Expect('pdf completed', 'Yes');
        Observer.Expect('pdf saved', 'Yes');
        Observer.Expect('pdf has bytes', 'Yes');
        Observer.Expect('pdf content', 'pdf');
        Observer.Expect('pdf err|text', '');
        Observer.Expect('pdf err|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure BaseWithOwnLayout_Xml_Pdf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'xml', 91213, ReportFormat::Xml, false);
        Probe(Observer, 'pdf', 91213, ReportFormat::Pdf, false);
        Probe(Observer, 'xml recref', 91213, ReportFormat::Xml, true);
        Observer.Expect('xml completed', 'Yes');
        Observer.Expect('xml saved', 'Yes');
        Observer.Expect('xml has bytes', 'Yes');
        Observer.Expect('xml content', 'xml');
        Observer.Expect('xml err|text', '');
        Observer.Expect('xml err|code', '');
        Observer.Expect('pdf completed', 'Yes');
        Observer.Expect('pdf saved', 'Yes');
        Observer.Expect('pdf has bytes', 'Yes');
        Observer.Expect('pdf content', 'pdf');
        Observer.Expect('pdf err|text', '');
        Observer.Expect('pdf err|code', '');
        Observer.Expect('xml recref completed', 'Yes');
        Observer.Expect('xml recref saved', 'Yes');
        Observer.Expect('xml recref has bytes', 'Yes');
        Observer.Expect('xml recref content', 'xml');
        Observer.Expect('xml recref err|text', '');
        Observer.Expect('xml recref err|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure BaseWithOwnLayout_Word_Excel_Html()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'word', 91213, ReportFormat::Word, false);
        Probe(Observer, 'excel', 91213, ReportFormat::Excel, false);
        Probe(Observer, 'html', 91213, ReportFormat::Html, false);
        Observer.Expect('word completed', 'Yes');
        Observer.Expect('word saved', 'Yes');
        Observer.Expect('word has bytes', 'Yes');
        Observer.Expect('word content', 'zip');
        Observer.Expect('word err|text', '');
        Observer.Expect('word err|code', '');
        Observer.Expect('excel completed', 'Yes');
        Observer.Expect('excel saved', 'Yes');
        Observer.Expect('excel has bytes', 'Yes');
        Observer.Expect('excel content', 'zip');
        Observer.Expect('excel err|text', '');
        Observer.Expect('excel err|code', '');
        Observer.Expect('html completed', 'Yes');
        Observer.Expect('html saved', 'No');
        Observer.Expect('html has bytes', 'No');
        Observer.Expect('html content', 'empty');
        Observer.Expect('html err|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('html err|code', 'ReportUnsupportedFormat');
        Observer.Verify();
    end;

    [Test]
    procedure BaseWithoutRendering_ExtensionOnlyLayout()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'xml', 91215, ReportFormat::Xml, false);
        Probe(Observer, 'pdf', 91215, ReportFormat::Pdf, false);
        Probe(Observer, 'word', 91215, ReportFormat::Word, false);
        Observer.Expect('xml completed', 'Yes');
        Observer.Expect('xml saved', 'Yes');
        Observer.Expect('xml has bytes', 'Yes');
        Observer.Expect('xml content', 'xml');
        Observer.Expect('xml err|text', '');
        Observer.Expect('xml err|code', '');
        Observer.Expect('pdf completed', 'Yes');
        Observer.Expect('pdf saved', 'Yes');
        Observer.Expect('pdf has bytes', 'Yes');
        Observer.Expect('pdf content', 'pdf');
        Observer.Expect('pdf err|text', '');
        Observer.Expect('pdf err|code', '');
        Observer.Expect('word completed', 'Yes');
        Observer.Expect('word saved', 'Yes');
        Observer.Expect('word has bytes', 'Yes');
        Observer.Expect('word content', 'zip');
        Observer.Expect('word err|text', '');
        Observer.Expect('word err|code', '');
        Observer.Verify();
    end;
}
