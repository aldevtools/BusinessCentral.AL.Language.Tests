// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Corpus issue 656 item 1: the Report Layout List columns whose name mentions Subtype, Part, Theme or HeaderFooter (on BC 29:
// "Layout Subtype", HeaderFooterPart, ThemePart) for layouts that declare no Subtype (YReportParts.al pins layouts with a Subtype).
// Report 80774: a Word and an RDLC layout, no parts. Report 80775 (BC 29 only, the part properties need app runtime 18): a Word
// layout without Subtype as the default layout of a report that declares DefaultHeaderFooterPart and DefaultThemePart.
// Probe: observed values; every literal asserted below is what the BC tier produced.
// BC versions: 27, 28, 29
report 80774 "LT BA NoSub Layouts"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = BaNoSubWord;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(NumCol; Number) { }
        }
    }

    rendering
    {
        layout(BaNoSubWord)
        {
            Type = Word;
            LayoutFile = './metadata/platform-tables/LtBaNoSubWord.docx';
        }
        layout(BaNoSubRdlc)
        {
            Type = RDLC;
            LayoutFile = './metadata/platform-tables/LtBaNoSubRdlc.rdl';
        }
    }
}

#if BC29PLUS
report 80775 "LT BA NoSub Default Parts"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = BaDefBody;
    DefaultHeaderFooterPart = BaDefHf;
    DefaultThemePart = BaDefTheme;
    WordMergeDataItem = Row;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(NumCol; Number) { }
        }
    }

    rendering
    {
        layout(BaDefBody)
        {
            Type = Word;
            LayoutFile = './metadata/platform-tables/LtBaDefBody.docx';
        }
        layout(BaDefHf)
        {
            Type = Word;
            Subtype = HeaderFooter;
            LayoutFile = './metadata/platform-tables/LtBaDefHf.docx';
        }
        layout(BaDefTheme)
        {
            Type = Word;
            Subtype = Theme;
            LayoutFile = './metadata/platform-tables/LtBaDefTheme.dotx';
        }
    }
}
#endif

codeunit 80776 "LT BA Layout NoSubtype"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure BaLayoutNoSubtype_WordAndRdlc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('rows', PartColumns(80774));
#if BC29PLUS
        Observer.Expect('rows', '[BaNoSubRdlc Layout Subtype=Default HeaderFooterPart= ThemePart=][BaNoSubWord Layout Subtype=Default HeaderFooterPart= ThemePart=]');
#else
        // Before BC 29 the Report Layout List has no Subtype or part columns (BC 28.5, run 39181445217).
        Observer.Expect('rows', '[BaNoSubRdlc][BaNoSubWord]');
#endif
        Observer.Verify();
    end;

#if BC29PLUS
    [Test]
    procedure BaLayoutNoSubtype_WithReportDefaultParts()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('rows', PartColumns(80775));
        Observer.Expect('rows', '[BaDefBody Layout Subtype=Default HeaderFooterPart= ThemePart=][BaDefHf Layout Subtype=Header/Footer HeaderFooterPart= ThemePart=][BaDefTheme Layout Subtype=Theme HeaderFooterPart= ThemePart=]');
        Observer.Verify();
    end;
#endif

    // Per layout of the report: its name, then every column whose name mentions Subtype, Part, Theme or HeaderFooter.
    local procedure PartColumns(ReportId: Integer): Text
    var
        LayoutList: Record "Report Layout List";
        RR: RecordRef;
        FR: FieldRef;
        i: Integer;
        Result: Text;
    begin
        LayoutList.SetRange("Report ID", ReportId);
        if LayoutList.FindSet() then
            repeat
                RR.GetTable(LayoutList);
                Result += '[' + LayoutList.Name;
                for i := 1 to RR.FieldCount() do begin
                    FR := RR.FieldIndex(i);
                    if FR.Name.Contains('Subtype') or FR.Name.Contains('Part') or FR.Name.Contains('Theme') or FR.Name.Contains('HeaderFooter') then
                        Result += ' ' + FR.Name + '=' + Format(FR.Value);
                end;
                Result += ']';
            until LayoutList.Next() = 0
        else
            Result := 'no layouts';
        exit(Result);
    end;
}
