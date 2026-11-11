// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); Temp Blob (System Application); own report 96780 and codeunit 96785.
// Probe: al-runner 7608 (f): a data item name that starts with a digit other than 1 or 2. Names that start with 1 and 2 are pinned
//   (reports/W3ReportDataset.al:395 `_x0032_nd_item`, reports/WordXmlPartNames.al:450). This file measures data items whose
//   names start with 0, 3 and 9 (a column name may not start with a digit: AL0379), in the Xml dataset of SaveAs and in Report.WordXmlPart (plain and extended).
// Area: report dataset and Word XML part names.
// BC versions: 27.5, 28.5, 29.0 (to be measured by the corpus CI). Observation form: every test ends in Observer.Finish().

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
        Observer.Finish();
    end;

    [Test]
    procedure DLD_WordXmlPart_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT DLD Rpt"));
        Observer.Finish();
    end;

    [Test]
    procedure DLD_WordXmlPart_Extended()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT DLD Rpt", true));
        Observer.Finish();
    end;
}
