// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-howto-report-layout
// Scope: in-scope
// Fixtures used: Probe Observer (69160); tables, reports, layouts and WR Helper of WrFixtures.al
// Probe: OBSERVE ROUND
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
        Observer.Finish();
    end;

    [Test]
    procedure Gate_ParagraphRepeater_TwoRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Gate(Observer, Report::"WR Gate Paras");
        Observer.Finish();
    end;

    [Test]
    procedure Gate_PlainBindingRepeater_TwoRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Gate(Observer, Report::"WR Gate Plain Binding");
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Repeater_OneRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Lines(1);
        WordText(Observer, Report::"WR Gate Rows");
        Observer.Finish();
    end;

    [Test]
    procedure Repeater_ParagraphItems_ZeroRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Lines(0);
        WordText(Observer, Report::"WR Gate Paras");
        Observer.Finish();
    end;

    [Test]
    procedure Values_TextCodeNumbersDateBooleanOption()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OneLine('WRTEXT', 'WRCODE1', 42, 1234.5, DMY2Date(17, 3, 2025), true, 2);
        WordText(Observer, Report::"WR Values");
        Observer.Finish();
    end;

    [Test]
    procedure Values_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OneLine('', '', 0, 0, 0D, false, 0);
        WordText(Observer, Report::"WR Values");
        Observer.Finish();
    end;

    [Test]
    procedure Values_NegativeAndFraction()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OneLine('WRNEG', 'A-1', -7, -0.125, DMY2Date(1, 1, 2000), false, 1);
        WordText(Observer, Report::"WR Values");
        Observer.Finish();
    end;

    [Test]
    procedure Values_MarkupCharacters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OneLine('A&B<C>D"E''F', '', 0, 0, 0D, false, 0);
        WordText(Observer, Report::"WR Values");
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure ParentChild_TwoByTwo()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HeadsAndLines(2, 2, 2);
        WordText(Observer, Report::"WR Parent Child");
        Observer.Finish();
    end;

    [Test]
    procedure ParentChild_ParentWithoutChildRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HeadsAndLines(2, 1, 1);
        WordText(Observer, Report::"WR Parent Child");
        Observer.Finish();
    end;

    [Test]
    procedure NoColumns_ChildRepeaterNotEmitted()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HeadsAndLines(1, 1, 2);
        WordText(Observer, Report::"WR No Columns");
        Observer.Finish();
    end;

    [Test]
    procedure Break_OnPreDataItem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HeadsAndLines(1, 1, 2);
        WordText(Observer, Report::"WR Break Pre");
        Observer.Finish();
    end;

    [Test]
    procedure Break_OnAfterGetRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HeadsAndLines(1, 1, 2);
        WordText(Observer, Report::"WR Break After");
        Observer.Finish();
    end;

    [Test]
    procedure TwoRepeaters_SideBySide()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HeadsAndLines(2, 1, 2);
        WordText(Observer, Report::"WR Two Items");
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Picture_EmptyBlob()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Doc: Text;
    begin
        PictureLine(false);
        if Helper.Save(Observer, Report::"WR Picture", ReportFormat::Word, TempBlob) then begin
            Doc := Helper.Part(TempBlob, 'word/document.xml');
            Observer.Observe('entries', Helper.Entries(TempBlob));
            Observer.Observe('drawings', Format(Helper.Occurrences(Doc, '<w:drawing')));
            Observer.Observe('text', Helper.Between(Helper.PlainText(Doc), 'WRBODYSTART', 'WRAFTER'));
        end;
        Observer.Finish();
    end;

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
        Observer.Finish();
    end;

    [Test]
    procedure Edge_DataPartWithoutNewerColumn()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Lines(1);
        WordText(Observer, Report::"WR Older Part");
        Observer.Finish();
    end;

    [Test]
    procedure Edge_DataPartOfAnotherReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Lines(1);
        WordText(Observer, Report::"WR Other Part");
        Observer.Finish();
    end;

    // The Word save raises a CLR exception that a TryFunction does not catch; asserterror records its code and the start of its text (the rest
    // is a .NET stack trace).
    [Test]
    procedure WordMergeDataItem_TwoRecords_Word()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        HeadsAndLines(2, 0, 0);
        TempBlob.CreateOutStream(OutS);
        asserterror Report.SaveAs(Report::"WR Merge Item", '', ReportFormat::Word, OutS);
        Observer.Observe('err code', GetLastErrorCode());
        Observer.Observe('err start', CopyStr(GetLastErrorText(), 1, 64));
        Observer.Observe('length > 0', Format(TempBlob.Length() > 0));
        Observer.Finish();
    end;

    // The same report shape whose layout has a page header and footer.
    [Test]
    procedure WordMergeDataItem_HeaderFooter_Word()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Body: Text;
    begin
        HeadsAndLines(2, 0, 0);
        if Helper.Save(Observer, Report::"WR Merge Item Parts", ReportFormat::Word, TempBlob) then begin
            Body := Helper.Body(TempBlob);
            Observer.Observe('WRBODYSTART occurrences', Format(Helper.Occurrences(Body, 'WRBODYSTART')));
            Observer.Observe('sections', Format(Helper.Occurrences(Helper.Part(TempBlob, 'word/document.xml'), '<w:sectPr')));
            Observer.Observe('text', Body);
            Observer.Observe('entries', Helper.Entries(TempBlob));
        end;
        Observer.Finish();
    end;

    [Test]
    procedure WordMergeDataItem_TwoRecords_Pdf()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
    begin
        HeadsAndLines(2, 0, 0);
        Helper.Save(Observer, Report::"WR Merge Item", ReportFormat::Pdf, TempBlob);
        Observer.Finish();
    end;

    [Test]
    procedure Pdf_TwoRows()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
    begin
        Helper.Lines(2);
        Helper.Save(Observer, Report::"WR Gate Rows", ReportFormat::Pdf, TempBlob);
        Observer.Finish();
    end;

    [Test]
    procedure Pdf_ZeroRows()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
    begin
        Helper.Lines(0);
        Helper.Save(Observer, Report::"WR Gate Rows", ReportFormat::Pdf, TempBlob);
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Layout_Default()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Lines(1);
        WordText(Observer, Report::"WR Two Layouts");
        Observer.Finish();
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
        Observer.Finish();
    end;
}
