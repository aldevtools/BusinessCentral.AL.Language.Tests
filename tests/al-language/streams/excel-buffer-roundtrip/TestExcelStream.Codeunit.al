// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-excel-buffer
// Claim: a workbook created in a stream can be read back with the original non-empty cell value.
// Uses public Excel Buffer and Temp Blob APIs; contains no Microsoft implementation or workbook data.
// BC versions: 27.5, 28.5, 29.0. Requires the optional .NET helper and matching BC OpenXML dependencies.
codeunit 69048 "STR Excel Stream Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        FixtureCleanup: Codeunit ALTFixtureCleanup;
    [Test]
    procedure ExcelBuffer_StreamRoundTrip_PreservesCell()
    var
        Writer: Record "Excel Buffer" temporary;
        Reader: Record "Excel Buffer" temporary;
        Blob: Codeunit "Temp Blob";
        Output: OutStream;
        Input: InStream;
    begin
        Initialize();
        Writer.NewRow();
        Writer.AddColumn('EXCEL-PROBE-42', false, '', false, false, false, '', Writer."Cell Type"::Text);
        Writer.CreateNewBook('Probe');
        Writer.WriteSheet('', CompanyName(), UserId());
        Writer.CloseBook();
        Blob.CreateOutStream(Output);
        Writer.SaveToStream(Output, true);
        if not Blob.HasValue() then
            Error('Expected a non-empty workbook stream.');
        Blob.CreateInStream(Input);
        Reader.OpenBookStream(Input, 'Probe');
        Reader.ReadSheet();
        Reader.Get(1, 1);
        if Reader."Cell Value as Text" <> 'EXCEL-PROBE-42' then
            Error('Expected EXCEL-PROBE-42, got %1.', Reader."Cell Value as Text");
        Reader.CloseBook();
    end;
    local procedure Initialize()
    begin
        FixtureCleanup.Initialize();
        // All record buffers are local and temporary; no persistent records are used.
    end;
}
