// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-excel-buffer
// Scope: Cloud-compatible. Fixtures used: Probe Observer (69160); own test codeunit 95989; Base Application Excel Buffer,
// System Application Temp Blob.
// Probe: (al-runner issue 7134) where an AL InStream stands after Excel Buffer's SelectSheetsNameStream and OpenBookStream read
// the workbook from it (both hand the stream to .NET code): EOS after each call on the same stream, and the cell the sheet
// then gives. The same-stream read itself is pinned in TestExcelStream.Codeunit.al.
// BC versions: 27.5+

codeunit 95989 "LT R7134 Excel Stream Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ExcelBuffer_SameStream_EosAfterEachRead()
    var
        Observer: Codeunit "Probe Observer";
        Writer: Record "Excel Buffer" temporary;
        Reader: Record "Excel Buffer" temporary;
        Blob: Codeunit "Temp Blob";
        Output: OutStream;
        Input: InStream;
        Sheet: Text;
    begin
        Writer.NewRow();
        Writer.AddColumn('POS-7134', false, '', false, false, false, '', Writer."Cell Type"::Text);
        Writer.CreateNewBook('PosProbe');
        Writer.WriteSheet('', CompanyName(), UserId());
        Writer.CloseBook();
        Blob.CreateOutStream(Output);
        Writer.SaveToStream(Output, true);
        Blob.CreateInStream(Input);
        Observer.Observe('eos_before', Format(Input.EOS()));
        Sheet := Reader.SelectSheetsNameStream(Input);
        Observer.Observe('sheet', Sheet);
        Observer.Observe('eos_after_select', Format(Input.EOS()));
        Reader.OpenBookStream(Input, Sheet);
        Observer.Observe('eos_after_open', Format(Input.EOS()));
        Reader.ReadSheet();
        Reader.Get(1, 1);
        Observer.Observe('cell', Reader."Cell Value as Text");
        Reader.CloseBook();
        Observer.Finish();
    end;
}
