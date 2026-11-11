// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); Temp Blob (System Application); own report 96780 and codeunit 96785.
// Probe: al-runner 7608 (f): a data item name that starts with a digit other than 1 or 2. Names that start with 1 and 2 are pinned
//   (reports/W3ReportDataset.al:395 `_x0032_nd_item`, reports/WordXmlPartNames.al:450). This file measures data items whose
//   names start with 0, 3 and 9 (a column name may not start with a digit: AL0379), in the Xml dataset of SaveAs and in Report.WordXmlPart (plain and extended).
// Area: report dataset and Word XML part names.
// BC versions: 27.5, 28.5, 29.0. The expected values are what the corpus CI legs returned (BC28PLUS where 27.5 differs).

report 96780 "LT DLD Rpt"
{
    UsageCategory = None;

    dataset
    {
        dataitem("0x item"; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(C0; Number)
            {
            }
            column(C7; Number)
            {
            }
            dataitem("3x item"; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(2));
                column(C3; Number)
                {
                }
            }
        }
        dataitem("9x"; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(3));
            column(C9; Number)
            {
            }
        }
    }
}

codeunit 96785 "LT DLD Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Lines(Xml: Text; Marker: Text): Text
    var
        Line: Text;
        Lf: Text[1];
        Result: Text;
    begin
        Lf[1] := 10;
        foreach Line in Xml.Split(Lf) do
            if Line.Contains(Marker) then
                Result += Line.Trim() + '|';
        exit(Result);
    end;

    [Test]
    procedure DLD_SaveAsXml_NamesWithLeadingDigit()
    var
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
        Xml: Text;
        Part: Text;
        Lf: Text[1];
    begin
        Lf[1] := 10;
        TempBlob.CreateOutStream(OutS);
        Observer.Observe('saved', Format(Report.SaveAs(Report::"LT DLD Rpt", '', ReportFormat::Xml, OutS)));
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.ReadText(Part);
            Xml += Part + Lf;
        end;
        Observer.Observe('items', Lines(Xml, '<DataItem '));
        Observer.Observe('columns', Lines(Xml, '<Column '));
        Observer.Expect('saved', 'Yes');
#if BC28PLUS
        Observer.Expect('items', '<DataItem language="en-US" formatRegion="en-US" name="_x0030_x_item" tableId="2000000026">|<DataItem name="_x0033_x_item" tableId="2000000026">|<DataItem language="en-US" formatRegion="en-US" name="_x0039_x" tableId="2000000026">|');
#else
        Observer.Expect('items', '<DataItem language="en-US" formatRegion="en-US" name="_x0030_x_item">|<DataItem name="_x0033_x_item">|<DataItem language="en-US" formatRegion="en-US" name="_x0039_x">|');
#endif
        Observer.Expect('columns', '<Column name="C0">1</Column>|<Column name="C7">1</Column>|<Column name="C3">2</Column>|<Column name="C9">3</Column>|');
        Observer.Verify();
    end;

    [Test]
    procedure DLD_WordXmlPart_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT DLD Rpt"));
        Observer.Expect('part', '<?xml version="1.0" encoding="utf-16"?>\r\n<NavWordReportXmlPart xmlns="urn:microsoft-dynamics-nav/reports/LT_DLD_Rpt/96780/">\r\n  <BCReportInformation>x</BCReportInformation>\r\n  <_x0030_x_item>\r\n    <C0>C0</C0>\r\n    <C7>C7</C7>\r\n    <_x0033_x_item>\r\n      <C3>C3</C3>\r\n    </_x0033_x_item>\r\n  </_x0030_x_item>\r\n  <_x0039_x>\r\n    <C9>C9</C9>\r\n  </_x0039_x>\r\n</NavWordReportXmlPart>');
        Observer.Verify();
    end;

    [Test]
    procedure DLD_WordXmlPart_Extended()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT DLD Rpt", true));
        Observer.Expect('part', '<?xml version="1.0" encoding="utf-16"?>\r\n<NavWordReportXmlPart xmlns="urn:microsoft-dynamics-businesscentral/internal/extended/reports/LT_DLD_Rpt/96780/">\r\n  <BCReportInformation>x</BCReportInformation>\r\n  <Tooltips />\r\n  <_x0030_x_item ElementType="DataItem" ElementId="1600254248">\r\n    <C0 ElementType="Column" ElementId="1882946614" DataType="Integer">C0</C0>\r\n    <C7 ElementType="Column" ElementId="1305536471" DataType="Integer">C7</C7>\r\n    <_x0033_x_item ElementType="DataItem" ElementId="390959709">\r\n      <C3 ElementType="Column" ElementId="1245249997" DataType="Integer">C3</C3>\r\n    </_x0033_x_item>\r\n  </_x0030_x_item>\r\n  <_x0039_x ElementType="DataItem" ElementId="881638084">\r\n    <C9 ElementType="Column" ElementId="967718425" DataType="Integer">C9</C9>\r\n  </_x0039_x>\r\n</NavWordReportXmlPart>');
        Observer.Verify();
    end;
}
