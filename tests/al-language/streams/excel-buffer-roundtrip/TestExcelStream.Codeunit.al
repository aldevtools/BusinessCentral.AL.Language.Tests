// BC versions: 27.5, 28.5, 29.0.
// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-excel-buffer
// Claim: a workbook created in a stream can be read back with the original non-empty cell value.
// Uses public Excel Buffer and Temp Blob APIs; contains no Microsoft implementation or workbook data.
// Scope: Cloud-compatible public Excel Buffer API. BC versions: 27.5, 28.5, 29.0.
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

    [Test]
    procedure ExcelBuffer_SelectSheetThenRead_TempBlob_SameStream_PreservesCell()
    var
        Blob: Codeunit "Temp Blob";
    begin
        Initialize();
        BuildRemainingWorkbook(Blob, false);
        ReadRemainingWorkbook(Blob, false);
    end;

    [Test]
    procedure ExcelBuffer_SelectSheetThenRead_TempBlob_FreshStream_PreservesCell()
    var
        Blob: Codeunit "Temp Blob";
    begin
        Initialize();
        BuildRemainingWorkbook(Blob, false);
        ReadRemainingWorkbook(Blob, true);
    end;

    [Test]
    procedure ExcelBuffer_SelectSheetThenRead_StoredBlob_SameStream_PreservesCell()
    var
        Blob: Codeunit "Temp Blob";
    begin
        Initialize();
        BuildRemainingWorkbook(Blob, true);
        ReadRemainingWorkbook(Blob, false);
    end;

    [Test]
    procedure ExcelBuffer_SelectSheetThenRead_StoredBlob_FreshStream_PreservesCell()
    var
        Blob: Codeunit "Temp Blob";
    begin
        Initialize();
        BuildRemainingWorkbook(Blob, true);
        ReadRemainingWorkbook(Blob, true);
    end;

    // Same public stream and FromRecord APIs as the reported path; generated synthetic content only.
    local procedure BuildRemainingWorkbook(var Blob: Codeunit "Temp Blob"; StoreInRecord: Boolean)
    var
        Writer: Record "Excel Buffer" temporary;
        Row: Record "ALT Blob";

        Output: OutStream;
        Input: InStream;
    begin
        Writer.NewRow();
        Writer.AddColumn('STREAM-42', false, '', false, false, false, '', Writer."Cell Type"::Text);
        Writer.CreateNewBook('StreamProbe');
        Writer.WriteSheet('', CompanyName(), UserId());
        Writer.CloseBook();
        Blob.CreateOutStream(Output);
        Writer.SaveToStream(Output, true);
        if StoreInRecord then begin
            Blob.CreateInStream(Input);
            Row.Code := 'NEUTRAL42';
            Row.Data.CreateOutStream(Output);
            CopyStream(Output, Input);
            Row.Insert(false);
            Clear(Row);
            Row.Get('NEUTRAL42');
            Row.CalcFields(Data);
            Clear(Blob);
            Blob.FromRecord(Row, Row.FieldNo(Data));
        end;
    end;
    local procedure ReadRemainingWorkbook(var Blob: Codeunit "Temp Blob"; FreshStream: Boolean)
    var
        Reader: Record "Excel Buffer" temporary;
        Input: InStream;
        Sheet: Text;
    begin
        Blob.CreateInStream(Input);
        Sheet := Reader.SelectSheetsNameStream(Input);
        if Sheet <> 'StreamProbe' then
            Error('Expected StreamProbe, actual %1.', Sheet);
        if FreshStream then
            Blob.CreateInStream(Input);
        Reader.OpenBookStream(Input, Sheet);
        Reader.ReadSheet();
        Reader.Get(1, 1);
        if Reader."Cell Value as Text" <> 'STREAM-42' then
            Error('Expected STREAM-42, actual %1.', Reader."Cell Value as Text");
        Reader.CloseBook();
    end;

}
