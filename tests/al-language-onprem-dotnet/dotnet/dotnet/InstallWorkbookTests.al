// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-excel-buffer
// Matrix: SaveToStream delete=true/false x plain/styled cell with a comment.
// All four workbooks are made during installation and read in the later test session.
// Existing 69048 pins the within-test stream roundtrip; this measures the installation boundary.
codeunit 99463 "LT Install Workbook Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    var
        Observation: Record "LT Install Workbook Obs";
        Snapshot: Record "LT Install Workbook Obs" temporary;

    [Test]
    procedure InstallWorkbook_DeletePlain_PreservesCell()
    begin
        Initialize();
        AssertWorkbook('DELETE-PLAIN');
    end;

    [Test]
    procedure InstallWorkbook_KeepPlain_PreservesCellAfterCleanup()
    begin
        Initialize();
        AssertWorkbook('KEEP-PLAIN');
    end;

    [Test]
    procedure InstallWorkbook_DeleteStyled_PreservesCell()
    begin
        Initialize();
        AssertWorkbook('DELETE-STYLED');
    end;

    [Test]
    procedure InstallWorkbook_KeepStyled_PreservesCellAfterCleanup()
    begin
        Initialize();
        AssertWorkbook('KEEP-STYLED');
    end;

    local procedure AssertWorkbook(ProbeCode: Code[20])
    var
        Reader: Record "Excel Buffer" temporary;
        Input: InStream;
    begin
        Observation.Get(ProbeCode);
        if Observation."Probe Error" <> '' then Error('Installation capture failed: %1', Observation."Probe Error");
        Observation.CalcFields(Workbook);
        if not Observation.Workbook.HasValue() then Error('Expected installed workbook data.');
        Observation.Workbook.CreateInStream(Input);
        Reader.OpenBookStream(Input, 'InstallProbe');
        Reader.ReadSheet();
        Reader.Get(1, 1);
        if Reader."Cell Value as Text" <> ProbeCode then Error('Expected %1, got %2.', ProbeCode, Reader."Cell Value as Text");
        Reader.CloseBook();
    end;

    local procedure Initialize()
    begin
        Snapshot.Reset();
        Snapshot.DeleteAll();
        Observation.Reset();
        if Observation.FindSet() then repeat
            CopyObservation(Observation, Snapshot);
        until Observation.Next() = 0;
        Observation.DeleteAll();
        if Snapshot.FindSet() then repeat
            CopyObservation(Snapshot, Observation);
        until Snapshot.Next() = 0;
    end;

    local procedure CopyObservation(var Source: Record "LT Install Workbook Obs"; var Destination: Record "LT Install Workbook Obs")
    var
        Input: InStream;
        Output: OutStream;
    begin
        Source.CalcFields(Workbook);
        Destination.Init();
        Destination."Code" := Source."Code";
        Destination."Probe Error" := Source."Probe Error";
        if Source.Workbook.HasValue() then begin
            Source.Workbook.CreateInStream(Input);
            Destination.Workbook.CreateOutStream(Output);
            CopyStream(Output, Input);
        end;
        Destination.Insert(false);
    end;

    [Test]
    procedure Workbook_IdenticalCellsAcrossTime_HaveDifferentPackageBytes()
    var
        First: Codeunit "Temp Blob";
        Second: Codeunit "Temp Blob";
        Base64: Codeunit "Base64 Convert";
        Input: InStream;
        FirstBytes: Text;
        SecondBytes: Text;
    begin
        Initialize();
        BuildIdenticalWorkbook(First);
        Sleep(2500);
        BuildIdenticalWorkbook(Second);
        AssertRepeatedCell(First);
        AssertRepeatedCell(Second);
        First.CreateInStream(Input);
        FirstBytes := Base64.ToBase64(Input);
        Second.CreateInStream(Input);
        SecondBytes := Base64.ToBase64(Input);
        if (FirstBytes = '') or (SecondBytes = '') then Error('Expected non-empty package bytes.');
        if FirstBytes = SecondBytes then Error('Expected independently generated packages across time to differ in bytes.');
    end;

    local procedure BuildIdenticalWorkbook(var Blob: Codeunit "Temp Blob")
    var
        Writer: Record "Excel Buffer" temporary;
        Output: OutStream;
    begin
        Writer.NewRow();
        Writer.AddColumn('REPEATED-CELL-42', false, '', false, false, false, '', Writer."Cell Type"::Text);
        Writer.CreateNewBook('RepeatProbe');
        Writer.WriteSheet('', CompanyName(), UserId());
        Writer.CloseBook();
        Blob.CreateOutStream(Output);
        Writer.SaveToStream(Output, true);
    end;

    local procedure AssertRepeatedCell(var Blob: Codeunit "Temp Blob")
    var
        Reader: Record "Excel Buffer" temporary;
        Input: InStream;
    begin
        Blob.CreateInStream(Input);
        Reader.OpenBookStream(Input, 'RepeatProbe');
        Reader.ReadSheet();
        Reader.Get(1, 1);
        if Reader."Cell Value as Text" <> 'REPEATED-CELL-42' then Error('Expected repeated cell value.');
        Reader.CloseBook();
    end;
}
