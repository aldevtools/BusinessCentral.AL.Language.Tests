// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-howto-report-layout
// Scope: in-scope
// Fixtures used: Probe Observer (69160); tables WR Head and WR Line, reports 91110-91126, report extension 91127, the Wr*.docx layouts and WR Helper
//   (codeunit 91139) of WrFixtures.al
// Probe: written for the al-runtime-rs ADR-040 amendment of 2026-11-13b (Word layouts rendered by BC's own merger). Each test seeds its rows, saves a
//   report with a hand-made Word layout through Report.SaveAs into a Temp Blob, and reads back what AL code can see: whether the save completed, what
//   it returned, the error, the first four bytes, whether the stream is not empty, and for Word the text of word/document.xml (or another part)
//   without markup (WR Helper.PlainText: element text as it stands in the XML, '/' per paragraph end, '~' per tab, '^' per break), cut between
//   static markers WRBODYSTART and WRAFTER. Never lengths, hashes or PDF content.
// Facts (observed on BC 27.5, 28.5 and 29.0):
//   Gate: a table row repeating section over a data item with static text and a bound column gives one row per record with its value; the same
//   repeater made of body paragraphs is removed (no item, no static text); w:dataBinding without storeItemID on the repeater binds as well.
//   A report without rows does not save (ReportResultEmpty) for Word and Pdf.
//   Values use the dataset's formatted text (Decimal with two decimals and a thousands separator, Date as M/D/YYYY, Boolean True/False, the option
//   caption, -0.125 as -0.13); &, < and > are escaped in document.xml, " and ' are not; CR LF and LF become a break, a tab a tab element. A label
//   binds its text; an IncludeCaption caption binds the field caption. A control bound to a path without a column, a data part that lacks a newer
//   column, and a data part named for another report save without error (the unknown path stays empty, the other part's bindings still bind).
//   Pictures: a picture control bound to a BLOB with an image saves with the image as media/image2.png beside the layout's own placeholder image;
//   with an empty BLOB it saves with the placeholder only.
//   Reporter's merge notes (al-runner issue 7977): a child data item without columns is not emitted, so its repeater is removed; a parent column bound
//   inside a child repeater stays empty; CurrReport.Break in OnPreDataItem and in OnAfterGetRecord (first record) removes the repeater.
//   Parts: the header and footer keep their part names and get the first record's value; the output drops customXml/item.xml and keeps item2.xml;
//   it has a GUID-named core properties entry under package/services/metadata/core-properties/ (folded to *.psmdcp here) whose dc:title is the
//   report name; docProps/app.xml has an empty Company. Html of the same layout holds the merged values and the static text per row, escaped.
//   A temporary layout selection picks the other Word layout; a report extension's Word layout binds the column the extension adds.
//   Picture_EmptyBlob is held (a comment, not a test): BC on Linux (the corpus CI) throws an uncatchable System.NullReferenceException there while Windows
//   completes (values in the comment at the test); the runtime must refuse that shape on Linux. Entry lists are sorted by char code (WR Helper.Entries).
//   Measured on the local Windows BC containers 27.5, 28.5 and 29.0 (same values on all three); the corpus CI legs run BC on Linux.
//   WordMergeDataItem = Head, layout without section breaks, 2 records: Pdf saves. The Word save is not a test here: on 27.5, 28.5 and 29.0 it
//   raised "Unexpected CLR exception thrown.: System.NullReferenceException" in OfficeWordSectionHandler.GenerateHeadersFootersAndSection, which
//   neither a TryFunction nor asserterror catches (the test fails), with and without a page header and footer in the layout.
// BC versions: 27 - 29

codeunit 91140 "WR Merge Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "WR Helper";

    local procedure Gate(var Observer: Codeunit "Probe Observer"; ReportId: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        Body: Text;
    begin
        Helper.Lines(2);
        if not Helper.Save(Observer, ReportId, ReportFormat::Word, TempBlob) then
            exit;
        Body := Helper.Body(TempBlob);
        Observer.Observe('WRSTATIC occurrences', Format(Helper.Occurrences(Body, 'WRSTATIC')));
        Observer.Observe('text', Helper.Between(Body, 'WRBODYSTART', 'WRAFTER'));
    end;

    [Test]
    procedure Gate_TableRowRepeater_TwoRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Gate(Observer, Report::"WR Gate Rows");
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '80,75,3,4,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Expect('WRSTATIC occurrences', '2');
        Observer.Expect('text', 'WRBODYSTART/WRSTATIC WRROW1 WREND/WRSTATIC WRROW2 WREND/WRAFTER');
        Observer.Verify();
    end;

    [Test]
    procedure Gate_ParagraphRepeater_TwoRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Gate(Observer, Report::"WR Gate Paras");
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '80,75,3,4,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Expect('WRSTATIC occurrences', '0');
        Observer.Expect('text', 'WRBODYSTART/WRAFTER');
        Observer.Verify();
    end;

    [Test]
    procedure Gate_PlainBindingRepeater_TwoRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Gate(Observer, Report::"WR Gate Plain Binding");
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '80,75,3,4,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Expect('WRSTATIC occurrences', '2');
        Observer.Expect('text', 'WRBODYSTART/WRSTATIC WRROW1 WREND/WRSTATIC WRROW2 WREND/WRAFTER');
        Observer.Verify();
    end;

    // Seeds WR Head rows 1..H named WRHEAD<h> and, for each head up to WithLines, N lines with Txt WRH<h>L<i>.
    local procedure HeadsAndLines(H: Integer; WithLines: Integer; N: Integer)
    var
        Head: Record "WR Head";
        Line: Record "WR Line";
        I: Integer;
        J: Integer;
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        for I := 1 to H do begin
            Head.Init();
            Head.Id := I;
            Head.Name := 'WRHEAD' + Format(I);
            Head.Insert();
            if I <= WithLines then
                for J := 1 to N do begin
                    Line.Init();
                    Line.HeadId := I;
                    Line.LineNo := J;
                    Line.Txt := 'WRH' + Format(I) + 'L' + Format(J);
                    Line.Insert();
                end;
        end;
    end;

    local procedure OneLine(Txt: Text[100]; Cd: Code[20]; Qty: Integer; Amt: Decimal; Dt: Date; Flag: Boolean; Opt: Option)
    var
        Line: Record "WR Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line.HeadId := 1;
        Line.LineNo := 1;
        Line.Txt := Txt;
        Line.Cd := Cd;
        Line.Qty := Qty;
        Line.Amt := Amt;
        Line.Dt := Dt;
        Line.Flag := Flag;
        Line.Opt := Opt;
        Line.Insert();
    end;

    // Saves as Word and observes the plain text of word/document.xml from WRBODYSTART to WRAFTER.
    local procedure WordText(var Observer: Codeunit "Probe Observer"; ReportId: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        if Helper.Save(Observer, ReportId, ReportFormat::Word, TempBlob) then
            Observer.Observe('text', Helper.Between(Helper.Body(TempBlob), 'WRBODYSTART', 'WRAFTER'));
    end;

    [Test]
    procedure Repeater_ZeroRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Lines(0);
        WordText(Observer, Report::"WR Gate Rows");
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'No');
        Observer.Expect('err|text', 'The report couldn’t be generated, because it was empty. Adjust your filters and try again.');
        Observer.Expect('err|code', 'ReportResultEmpty');
        Observer.Expect('head', 'empty');
        Observer.Expect('length > 0', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Repeater_OneRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Lines(1);
        WordText(Observer, Report::"WR Gate Rows");
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '80,75,3,4,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Expect('text', 'WRBODYSTART/WRSTATIC WRROW1 WREND/WRAFTER');
        Observer.Verify();
    end;

    [Test]
    procedure Repeater_ParagraphItems_ZeroRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Lines(0);
        WordText(Observer, Report::"WR Gate Paras");
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'No');
        Observer.Expect('err|text', 'The report couldn’t be generated, because it was empty. Adjust your filters and try again.');
        Observer.Expect('err|code', 'ReportResultEmpty');
        Observer.Expect('head', 'empty');
        Observer.Expect('length > 0', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Values_TextCodeNumbersDateBooleanOption()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OneLine('WRTEXT', 'WRCODE1', 42, 1234.5, DMY2Date(17, 3, 2025), true, 2);
        WordText(Observer, Report::"WR Values");
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '80,75,3,4,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Expect('text', 'WRBODYSTART/WRLA WRLABELTEXT WRLB Txt WRLZ/WRVA WRTEXT WRV1 WRCODE1 WRV2 42 WRV3 1,234.50 WRV4 1,234.50 WRV5 3/17/2025 WRV6 True WRV7 Gamma Cap WRV8 WRVZ/WRAFTER');
        Observer.Verify();
    end;

    [Test]
    procedure Values_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OneLine('', '', 0, 0, 0D, false, 0);
        WordText(Observer, Report::"WR Values");
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '80,75,3,4,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Expect('text', 'WRBODYSTART/WRLA WRLABELTEXT WRLB Txt WRLZ/WRVA  WRV1  WRV2 0 WRV3 0.00 WRV4 0.00 WRV5  WRV6 False WRV7 Alpha Cap WRV8 WRVZ/WRAFTER');
        Observer.Verify();
    end;

    [Test]
    procedure Values_NegativeAndFraction()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OneLine('WRNEG', 'A-1', -7, -0.125, DMY2Date(1, 1, 2000), false, 1);
        WordText(Observer, Report::"WR Values");
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '80,75,3,4,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Expect('text', 'WRBODYSTART/WRLA WRLABELTEXT WRLB Txt WRLZ/WRVA WRNEG WRV1 A-1 WRV2 -7 WRV3 -0.13 WRV4 -0.13 WRV5 1/1/2000 WRV6 False WRV7 Beta Cap WRV8 WRVZ/WRAFTER');
        Observer.Verify();
    end;

    [Test]
    procedure Values_MarkupCharacters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OneLine('A&B<C>D"E''F', '', 0, 0, 0D, false, 0);
        WordText(Observer, Report::"WR Values");
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '80,75,3,4,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Expect('text', 'WRBODYSTART/WRLA WRLABELTEXT WRLB Txt WRLZ/WRVA A&amp;B&lt;C&gt;D"E''F WRV1  WRV2 0 WRV3 0.00 WRV4 0.00 WRV5  WRV6 False WRV7 Alpha Cap WRV8 WRVZ/WRAFTER');
        Observer.Verify();
    end;

    [Test]
    procedure Values_LineBreaks()
    var
        Observer: Codeunit "Probe Observer";
        Cr: Char;
        Lf: Char;
        Tab: Char;
    begin
        Cr := 13;
        Lf := 10;
        Tab := 9;
        OneLine('WRL1' + Format(Cr) + Format(Lf) + 'WRL2' + Format(Lf) + 'WRL3' + Format(Tab) + 'WRL4', '', 0, 0, 0D, false, 0);
        WordText(Observer, Report::"WR Values");
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '80,75,3,4,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Expect('text', 'WRBODYSTART/WRLA WRLABELTEXT WRLB Txt WRLZ/WRVA WRL1^WRL2^WRL3~WRL4 WRV1  WRV2 0 WRV3 0.00 WRV4 0.00 WRV5  WRV6 False WRV7 Alpha Cap WRV8 WRVZ/WRAFTER');
        Observer.Verify();
    end;

    [Test]
    procedure ParentChild_TwoByTwo()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HeadsAndLines(2, 2, 2);
        WordText(Observer, Report::"WR Parent Child");
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '80,75,3,4,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Expect('text', 'WRBODYSTART/WRH WRHEAD1 WRHE/WRL WRH1L1 WRP  WRLE/WRL WRH1L2 WRP  WRLE/WRHZ/WRH WRHEAD2 WRHE/WRL WRH2L1 WRP  WRLE/WRL WRH2L2 WRP  WRLE/WRHZ/WRAFTER');
        Observer.Verify();
    end;

    [Test]
    procedure ParentChild_ParentWithoutChildRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HeadsAndLines(2, 1, 1);
        WordText(Observer, Report::"WR Parent Child");
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '80,75,3,4,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Expect('text', 'WRBODYSTART/WRH WRHEAD1 WRHE/WRL WRH1L1 WRP  WRLE/WRHZ/WRH WRHEAD2 WRHE/WRHZ/WRAFTER');
        Observer.Verify();
    end;

    [Test]
    procedure NoColumns_ChildRepeaterNotEmitted()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HeadsAndLines(1, 1, 2);
        WordText(Observer, Report::"WR No Columns");
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '80,75,3,4,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Expect('text', 'WRBODYSTART/WRH WRHEAD1 WRHE/WRHZ/WRAFTER');
        Observer.Verify();
    end;

    [Test]
    procedure Break_OnPreDataItem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HeadsAndLines(1, 1, 2);
        WordText(Observer, Report::"WR Break Pre");
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '80,75,3,4,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Expect('text', 'WRBODYSTART/WRH WRHEAD1 WRHE/WRMID/WRAFTER');
        Observer.Verify();
    end;

    [Test]
    procedure Break_OnAfterGetRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HeadsAndLines(1, 1, 2);
        WordText(Observer, Report::"WR Break After");
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '80,75,3,4,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Expect('text', 'WRBODYSTART/WRH WRHEAD1 WRHE/WRMID/WRAFTER');
        Observer.Verify();
    end;

    [Test]
    procedure TwoRepeaters_SideBySide()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HeadsAndLines(2, 1, 2);
        WordText(Observer, Report::"WR Two Items");
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '80,75,3,4,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Expect('text', 'WRBODYSTART/WRH WRHEAD1 WRHE/WRH WRHEAD2 WRHE/WRMID/WRL WRH1L1 WRLE/WRL WRH1L2 WRLE/WRAFTER');
        Observer.Verify();
    end;

    // Header and footer parts of the output and the text of each.
    [Test]
    procedure Parts_HeaderAndFooter()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Rels: Text;
    begin
        HeadsAndLines(2, 0, 0);
        if Helper.Save(Observer, Report::"WR Parts", ReportFormat::Word, TempBlob) then begin
            Rels := Helper.Part(TempBlob, 'word/_rels/document.xml.rels');
            Observer.Observe('header relationships', Format(Helper.Occurrences(Rels, '/relationships/header"')));
            Observer.Observe('footer relationships', Format(Helper.Occurrences(Rels, '/relationships/footer"')));
            Observer.Observe('header1 text', Helper.PlainText(Helper.Part(TempBlob, 'word/header1.xml')));
            Observer.Observe('footer1 text', Helper.PlainText(Helper.Part(TempBlob, 'word/footer1.xml')));
            Observer.Observe('text', Helper.Between(Helper.Body(TempBlob), 'WRBODYSTART', 'WRAFTER'));
        end;
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '80,75,3,4,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Expect('header relationships', '1');
        Observer.Expect('footer relationships', '1');
        Observer.Expect('header1 text', 'WRHDR WRHEAD1 WRHDRZ/');
        Observer.Expect('footer1 text', 'WRFTR WRHEAD1 WRFTRZ/');
        Observer.Expect('text', 'WRBODYSTART/WRH WRHEAD1 WRHE/WRH WRHEAD2 WRHE/WRAFTER');
        Observer.Verify();
    end;

    // The entry list of the output package, with the GUID-named core properties entry folded.
    [Test]
    procedure Parts_EntryList()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
    begin
        HeadsAndLines(1, 0, 0);
        if Helper.Save(Observer, Report::"WR Parts", ReportFormat::Word, TempBlob) then
            Observer.Observe('entries', Helper.Entries(TempBlob));
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '80,75,3,4,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Expect('entries', '[Content_Types].xml;_rels/.rels;customXml/item2.xml;docProps/app.xml;package/services/metadata/core-properties/*.psmdcp;word/_rels/document.xml.rels;word/document.xml;word/footer1.xml;word/header1.xml;word/settings.xml;');
        Observer.Verify();
    end;

    // The document properties the merger writes: title, and whether the company is the current company name.
    [Test]
    procedure Parts_TitleAndCompanyProperties()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        App: Text;
        Core: Text;
    begin
        HeadsAndLines(1, 0, 0);
        if Helper.Save(Observer, Report::"WR Parts", ReportFormat::Word, TempBlob) then begin
            App := Helper.Part(TempBlob, 'docProps/app.xml');
            Core := Helper.CoreProperties(TempBlob);
            Observer.Observe('app Company = CompanyName()', Format(Helper.Between(App, '<Company>', '</Company>') = '<Company>' + CompanyName() + '</Company>'));
            Observer.Observe('app has Company', Format(App.Contains('Company>')));
            App := App.Replace(CompanyName(), '{COMPANYNAME}');
            if CompanyProperty.DisplayName() <> '' then
                App := App.Replace(CompanyProperty.DisplayName(), '{DISPLAYNAME}');
            Observer.Observe('app.xml', App);
            Observer.Observe('core title', Helper.Between(Core, '<dc:title>', '</dc:title>'));
            Observer.Observe('core has title', Format(Core.Contains('title')));
        end;
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '80,75,3,4,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Expect('app Company = CompanyName()', 'No');
        Observer.Expect('app has Company', 'Yes');
        Observer.Expect('app.xml', '<?xml version="1.0" encoding="utf-8"?><ap:Properties xmlns:ap="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"><ap:Company></ap:Company></ap:Properties>');
        Observer.Expect('core title', '<dc:title>WR Parts</dc:title>');
        Observer.Expect('core has title', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Picture_BlobWithImage()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Doc: Text;
    begin
        PictureLine(true);
        if Helper.Save(Observer, Report::"WR Picture", ReportFormat::Word, TempBlob) then begin
            Doc := Helper.Part(TempBlob, 'word/document.xml');
            Observer.Observe('entries', Helper.Entries(TempBlob));
            Observer.Observe('drawings', Format(Helper.Occurrences(Doc, '<w:drawing')));
            Observer.Observe('text', Helper.Between(Helper.PlainText(Doc), 'WRBODYSTART', 'WRAFTER'));
        end;
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '80,75,3,4,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Expect('entries', '[Content_Types].xml;_rels/.rels;customXml/item2.xml;docProps/app.xml;media/image2.png;package/services/metadata/core-properties/*.psmdcp;word/_rels/document.xml.rels;word/document.xml;word/media/wrplaceholder.png;word/settings.xml;');
        Observer.Expect('drawings', '1');
        Observer.Expect('text', 'WRBODYSTART/WRP WRPICROW WRPE//WRAFTER');
        Observer.Verify();
    end;

    // Held (not a test): Picture_EmptyBlob. On the Linux CI containers (27.5, 28.5, 29.0) BC ends the test with the uncatchable
    // 'Unexpected CLR exception thrown.: System.NullReferenceException' (server log: NullReferenceException in IsInstanceOfClass) when a picture control
    // is bound to an empty BLOB and the report is saved as Word. On the local Windows containers (27.5, 28.5, 29.0) the same test passes with exactly the
    // values below. The runtime must refuse this shape on Linux. Not a test here, see docs/nightly-windows-authority.md.
    //
    // [Test]
    // procedure Picture_EmptyBlob()
    // var
    //     Observer: Codeunit "Probe Observer";
    //     TempBlob: Codeunit "Temp Blob";
    //     Doc: Text;
    // begin
    //     PictureLine(false);
    //     if Helper.Save(Observer, Report::"WR Picture", ReportFormat::Word, TempBlob) then begin
    //         Doc := Helper.Part(TempBlob, 'word/document.xml');
    //         Observer.Observe('entries', Helper.Entries(TempBlob));
    //         Observer.Observe('drawings', Format(Helper.Occurrences(Doc, '<w:drawing')));
    //         Observer.Observe('text', Helper.Between(Helper.PlainText(Doc), 'WRBODYSTART', 'WRAFTER'));
    //     end;
    //     Observer.Expect('completed', 'Yes');
    //     Observer.Expect('returned', 'Yes');
    //     Observer.Expect('err|text', '');
    //     Observer.Expect('err|code', '');
    //     Observer.Expect('head', '80,75,3,4,');
    //     Observer.Expect('length > 0', 'Yes');
    //     Observer.Expect('entries', '[Content_Types].xml;_rels/.rels;customXml/item2.xml;docProps/app.xml;package/services/metadata/core-properties/*.psmdcp;word/_rels/document.xml.rels;word/document.xml;word/media/wrplaceholder.png;word/settings.xml;');
    //     Observer.Expect('drawings', '1');
    //     Observer.Expect('text', 'WRBODYSTART/WRP WRPICROW WRPE//WRAFTER');
    //     Observer.Verify();
    // end;

    local procedure PictureLine(WithImage: Boolean)
    var
        Line: Record "WR Line";
        Base64: Codeunit "Base64 Convert";
        OutS: OutStream;
    begin
        Line.DeleteAll();
        Line.Init();
        Line.HeadId := 1;
        Line.LineNo := 1;
        Line.Txt := 'WRPICROW';
        if WithImage then begin
            Line.Pic.CreateOutStream(OutS);
            Base64.FromBase64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==', OutS);
        end;
        Line.Insert();
    end;

    [Test]
    procedure Edge_PathWithoutColumn()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Lines(1);
        WordText(Observer, Report::"WR Unknown Path");
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '80,75,3,4,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Expect('text', 'WRBODYSTART/WRU WRROW1 WRUM  WRUE/WRAFTER');
        Observer.Verify();
    end;

    [Test]
    procedure Edge_DataPartWithoutNewerColumn()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Lines(1);
        WordText(Observer, Report::"WR Older Part");
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '80,75,3,4,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Expect('text', 'WRBODYSTART/WRO WRROW1 WROE/WRAFTER');
        Observer.Verify();
    end;

    [Test]
    procedure Edge_DataPartOfAnotherReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Lines(1);
        WordText(Observer, Report::"WR Other Part");
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '80,75,3,4,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Expect('text', 'WRBODYSTART/WRSTATIC WRROW1 WREND/WRAFTER');
        Observer.Verify();
    end;

    [Test]
    procedure WordMergeDataItem_TwoRecords_Pdf()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
    begin
        HeadsAndLines(2, 0, 0);
        Helper.Save(Observer, Report::"WR Merge Item", ReportFormat::Pdf, TempBlob);
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '37,80,68,70,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Pdf_TwoRows()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
    begin
        Helper.Lines(2);
        Helper.Save(Observer, Report::"WR Gate Rows", ReportFormat::Pdf, TempBlob);
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '37,80,68,70,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Pdf_ZeroRows()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
    begin
        Helper.Lines(0);
        Helper.Save(Observer, Report::"WR Gate Rows", ReportFormat::Pdf, TempBlob);
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'No');
        Observer.Expect('err|text', 'The report couldn’t be generated, because it was empty. Adjust your filters and try again.');
        Observer.Expect('err|code', 'ReportResultEmpty');
        Observer.Expect('head', 'empty');
        Observer.Expect('length > 0', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Html_TwoRows()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Html: Text;
    begin
        Helper.Lines(2);
        if Helper.Save(Observer, Report::"WR Gate Rows", ReportFormat::Html, TempBlob) then begin
            Html := Helper.WholeText(TempBlob);
            Observer.Observe('WRSTATIC occurrences', Format(Helper.Occurrences(Html, 'WRSTATIC')));
            Observer.Observe('contains WRROW1', Format(Html.Contains('WRROW1')));
            Observer.Observe('contains WRROW2', Format(Html.Contains('WRROW2')));
            Observer.Observe('contains WRAFTER', Format(Html.Contains('WRAFTER')));
            Observer.Observe('contains LineTxt placeholder', Format(Html.Contains('>LineTxt<')));
        end;
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '60,104,116,109,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Expect('WRSTATIC occurrences', '2');
        Observer.Expect('contains WRROW1', 'Yes');
        Observer.Expect('contains WRROW2', 'Yes');
        Observer.Expect('contains WRAFTER', 'Yes');
        Observer.Expect('contains LineTxt placeholder', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Html_MarkupCharacters()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Html: Text;
    begin
        OneLine('A&B<C>D', '', 0, 0, 0D, false, 0);
        if Helper.Save(Observer, Report::"WR Values", ReportFormat::Html, TempBlob) then begin
            Html := Helper.WholeText(TempBlob);
            Observer.Observe('contains A&amp;B&lt;C&gt;D', Format(Html.Contains('A&amp;B&lt;C&gt;D')));
            Observer.Observe('contains A&B<C>D', Format(Html.Contains('A&B<C>D')));
            Observer.Observe('contains WRLABELTEXT', Format(Html.Contains('WRLABELTEXT')));
        end;
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '60,104,116,109,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Expect('contains A&amp;B&lt;C&gt;D', 'Yes');
        Observer.Expect('contains A&B<C>D', 'No');
        Observer.Expect('contains WRLABELTEXT', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Layout_TemporarySelection()
    var
        Observer: Codeunit "Probe Observer";
        Selection: Record "Report Layout Selection";
        Info: ModuleInfo;
    begin
        Helper.Lines(1);
        NavApp.GetCurrentModuleInfo(Info);
        Selection.SetTempLayoutSelectedName('WrAltLayout', Info.Id());
        WordText(Observer, Report::"WR Two Layouts");
        Selection.ClearTempLayoutSelected();
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '80,75,3,4,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Expect('text', 'WRBODYSTART WRALTLAYOUT/WRALT WRROW1 WREND/WRAFTER');
        Observer.Verify();
    end;

    [Test]
    procedure Layout_Default()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Lines(1);
        WordText(Observer, Report::"WR Two Layouts");
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '80,75,3,4,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Expect('text', 'WRBODYSTART WRMAINLAYOUT/WRSTATIC WRROW1 WREND/WRAFTER');
        Observer.Verify();
    end;

    [Test]
    procedure Extension_LayoutBindsAddedColumn()
    var
        Observer: Codeunit "Probe Observer";
        Selection: Record "Report Layout Selection";
        Line: Record "WR Line";
        Info: ModuleInfo;
    begin
        Helper.Lines(1);
        Line.FindFirst();
        Line.Cd := 'WREXTRA1';
        Line.Modify();
        NavApp.GetCurrentModuleInfo(Info);
        Selection.SetTempLayoutSelectedName('WrExtLayout', Info.Id());
        WordText(Observer, Report::"WR Ext Base");
        Selection.ClearTempLayoutSelected();
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('head', '80,75,3,4,');
        Observer.Expect('length > 0', 'Yes');
        Observer.Expect('text', 'WRBODYSTART WREXTLAYOUT/WRX WRROW1 WRXM WREXTRA1 WRXE/WRAFTER');
        Observer.Verify();
    end;
}
