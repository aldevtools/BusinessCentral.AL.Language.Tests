// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subtype-report-layout-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own reports 79730-79733, test codeunit 79754
// Probe: observed values; every literal asserted below is what the BC 29 tier produced (corpus issue 646, items 20, 21 and 24).
// Facts: BC 29 (runtime 18.0) only, the properties do not compile before (must-not-compile cases 0800-0805). Report.DefaultLayout and the
// Report Layout List rows of a report with DefaultHeaderFooterPart and DefaultThemePart, of a Word layout with Subtype omitted, and of reports whose
// DefaultRenderingLayout names a layout with Subtype HeaderFooter or Theme.
// BC versions: 29

#if BC29PLUS
report 79730 "LT AQ Parts Default"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = AqPartsBody;
    DefaultHeaderFooterPart = AqPartsHf;
    DefaultThemePart = AqPartsTheme;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(N; Number) { }
        }
    }

    rendering
    {
        layout(AqPartsBody)
        {
            Type = Word;
            LayoutFile = './reports/LtAqPartsBody.docx';
        }
        layout(AqPartsHf)
        {
            Type = Word;
            Subtype = HeaderFooter;
            LayoutFile = './reports/LtAqPartsHf.docx';
        }
        layout(AqPartsTheme)
        {
            Type = Word;
            Subtype = Theme;
            LayoutFile = './reports/LtAqPartsTheme.dotx';
        }
    }
}

report 79731 "LT AQ Default Is Hf"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = AqDefHf;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(N; Number) { }
        }
    }

    rendering
    {
        layout(AqDefHf)
        {
            Type = Word;
            Subtype = HeaderFooter;
            LayoutFile = './reports/LtAqDefHf.docx';
        }
    }
}

report 79732 "LT AQ Default Is Theme"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = AqDefTheme;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(N; Number) { }
        }
    }

    rendering
    {
        layout(AqDefTheme)
        {
            Type = Word;
            Subtype = Theme;
            LayoutFile = './reports/LtAqDefTheme.dotx';
        }
    }
}
codeunit 79754 "LT AQ Parts Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Per layout of the report: its name, then every column whose name mentions Subtype, Part or Format.
    local procedure LayoutRows(ReportId: Integer): Text
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
                    if FR.Name.Contains('Subtype') or FR.Name.Contains('Part') or FR.Name.Contains('Format') then
                        Result += ' ' + FR.Name + '=' + Format(FR.Value);
                end;
                Result += ']';
            until LayoutList.Next() = 0
        else
            Result := 'no layouts';
        exit(Result);
    end;

    [Test]
    procedure Parts_DefaultLayoutAndRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('default', Format(Report.DefaultLayout(Report::"LT AQ Parts Default")));
        Observer.Observe('rows', LayoutRows(Report::"LT AQ Parts Default"));
        Observer.Expect('default', 'Word');
        Observer.Expect('rows', '[AqPartsBody Layout Format=Word Layout Subtype=Default HeaderFooterPart= ThemePart=][AqPartsHf Layout Format=Word Layout Subtype=Header/Footer HeaderFooterPart= ThemePart=][AqPartsTheme Layout Format=Word Layout Subtype=Theme HeaderFooterPart= ThemePart=]');
        Observer.Verify();
    end;

    [Test]
    procedure DefaultIsHeaderFooter_DefaultLayoutAndRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('default', Format(Report.DefaultLayout(Report::"LT AQ Default Is Hf")));
        Observer.Observe('rows', LayoutRows(Report::"LT AQ Default Is Hf"));
        Observer.Expect('default', 'Word');
        Observer.Expect('rows', '[AqDefHf Layout Format=Word Layout Subtype=Header/Footer HeaderFooterPart= ThemePart=]');
        Observer.Verify();
    end;

    [Test]
    procedure DefaultIsTheme_DefaultLayoutAndRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('default', Format(Report.DefaultLayout(Report::"LT AQ Default Is Theme")));
        Observer.Observe('rows', LayoutRows(Report::"LT AQ Default Is Theme"));
        Observer.Expect('default', 'Word');
        Observer.Expect('rows', '[AqDefTheme Layout Format=Word Layout Subtype=Theme HeaderFooterPart= ThemePart=]');
        Observer.Verify();
    end;
}
#endif
