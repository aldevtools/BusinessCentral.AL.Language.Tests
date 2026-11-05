// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/
//   dev-itpro/developer/methods-auto/record/record-calcfields-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Blob (60008)
// BC versions: 27.5+
//
// CLAIM (one per codeunit): CalcFields(BlobField) does NOT discard an in-memory
// Blob write that has not yet been persisted with Modify(). Writing through
// CreateOutStream leaves the bytes on the record buffer, and a subsequent
// CalcFields on that same Blob field must leave them there — it must not
// re-fetch the (still empty) stored value over the top of them.
//
// The complementary lazy-load direction — after Get(), an untouched Blob reads
// empty until CalcFields loads it — is already covered by TestBlob.al
// (Blob_Get_WithoutCalcFields_InStreamReadsEmpty). This file covers the case
// where the buffer is dirty when CalcFields runs.

codeunit 60915 "Test Blob CalcFields Uncomm"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Blob_CalcFields_AfterUncommittedWriteWithoutModify_KeepsWrite()
    // CLAIM: Insert() with an empty Blob, then write bytes through CreateOutStream
    //        WITHOUT Modify(), then CalcFields — the written bytes survive.
    var
        BlobRec: Record "ALT Blob";
        OutStr: OutStream;
        InStr: InStream;
        ReadBack: Text;
    begin
        Initialize();

        BlobRec.Init();
        BlobRec.Code := 'UNCOMMITTED';
        BlobRec.Insert(true);

        Clear(BlobRec.Data);
        BlobRec.Data.CreateOutStream(OutStr);
        OutStr.WriteText('HELLO-BYTES');

        BlobRec.CalcFields(Data);

        BlobRec.Data.CreateInStream(InStr);
        InStr.ReadText(ReadBack);

        Assert.AreEqual('HELLO-BYTES', ReadBack, 'CalcFields must not discard an uncommitted in-memory Blob write');
    end;

    [Test]
    procedure Blob_CalcFields_AfterModify_KeepsWrite()
    // CLAIM: control for the case above — the same sequence WITH Modify() before
    //        CalcFields also reads the written bytes back.
    var
        BlobRec: Record "ALT Blob";
        OutStr: OutStream;
        InStr: InStream;
        ReadBack: Text;
    begin
        Initialize();

        BlobRec.Init();
        BlobRec.Code := 'COMMITTED';
        BlobRec.Insert(true);

        Clear(BlobRec.Data);
        BlobRec.Data.CreateOutStream(OutStr);
        OutStr.WriteText('HELLO-BYTES');
        BlobRec.Modify(true);

        BlobRec.CalcFields(Data);

        BlobRec.Data.CreateInStream(InStr);
        InStr.ReadText(ReadBack);

        Assert.AreEqual('HELLO-BYTES', ReadBack, 'CalcFields after Modify must read back the persisted Blob write');
    end;

    [Test]
    procedure Blob_CalcFields_TwoUncommittedRecords_KeepsBothWrites()
    // CLAIM: the behavior is per-record and not order-dependent — two records each
    //        written and CalcFields'd without Modify keep their own distinct bytes.
    var
        FirstRec: Record "ALT Blob";
        SecondRec: Record "ALT Blob";
        OutStr: OutStream;
        InStr: InStream;
        FirstReadBack: Text;
        SecondReadBack: Text;
    begin
        Initialize();

        FirstRec.Init();
        FirstRec.Code := 'FIRST';
        FirstRec.Insert(true);
        Clear(FirstRec.Data);
        FirstRec.Data.CreateOutStream(OutStr);
        OutStr.WriteText('FIRST-RECORD');
        FirstRec.CalcFields(Data);

        SecondRec.Init();
        SecondRec.Code := 'SECOND';
        SecondRec.Insert(true);
        Clear(SecondRec.Data);
        SecondRec.Data.CreateOutStream(OutStr);
        OutStr.WriteText('SECOND-RECORD');
        SecondRec.CalcFields(Data);

        FirstRec.Data.CreateInStream(InStr);
        InStr.ReadText(FirstReadBack);
        SecondRec.Data.CreateInStream(InStr);
        InStr.ReadText(SecondReadBack);

        Assert.AreEqual('FIRST-RECORD', FirstReadBack, 'First record must keep its own uncommitted Blob write');
        Assert.AreEqual('SECOND-RECORD', SecondReadBack, 'Second record must keep its own uncommitted Blob write');
    end;

    [Test]
    procedure Blob_CalcFields_NoWriteAtAll_ReadsEmpty()
    // CLAIM (negative direction): CalcFields does not invent content. A row inserted
    //        with an untouched Blob still reads empty after Get() + CalcFields.
    var
        BlobRec: Record "ALT Blob";
        ReaderRec: Record "ALT Blob";
        InStr: InStream;
        ReadBack: Text;
    begin
        Initialize();

        BlobRec.Init();
        BlobRec.Code := 'EMPTY';
        BlobRec.Insert(true);

        ReaderRec.Get('EMPTY');
        ReaderRec.CalcFields(Data);

        Assert.IsFalse(ReaderRec.Data.HasValue(), 'A Blob never written to must have no value after CalcFields');

        ReaderRec.Data.CreateInStream(InStr);
        InStr.ReadText(ReadBack);
        Assert.AreEqual('', ReadBack, 'CalcFields on a never-written Blob must read back empty');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    // Tests below (al-runner issue 6791): a Blob written through CreateOutStream after Insert, without Modify, read back with
    // CalcFields + CreateInStream. Matrix: a database row of ALT Blob, a temporary variable of ALT Blob, a table with
    // TableType = Temporary (table 95782 at the end of this file); with and without Clear(Blob) before CreateOutStream; with and
    // without a Get between the write and CalcFields; with and without HasValue before CalcFields. Each observation:
    // hv=<HasValue before CalcFields, or -> read=<text read back> after=<HasValue after CalcFields>.

    [Test]
    procedure BlobRoundTrip_DatabaseRow_Matrix()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        Initialize();
        for i := 0 to 7 do
            Observer.Observe(CellName(i), DbCell(i));
        Observer.Finish();
    end;

    [Test]
    procedure BlobRoundTrip_TemporaryVariable_Matrix()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        Initialize();
        for i := 0 to 7 do
            Observer.Observe(CellName(i), TempVarCell(i));
        Observer.Finish();
    end;

    [Test]
    procedure BlobRoundTrip_TemporaryTable_Matrix()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        Initialize();
        for i := 0 to 7 do
            Observer.Observe(CellName(i), TempTableCell(i));
        Observer.Finish();
    end;

    [Test]
    procedure BlobRoundTrip_TableMethods()
    // The reporter's shape: SetContent and GetContent are procedures of the table and work on Rec.
    var
        TempTable: Record "STR Blob Temp Row";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        TempTable.Init();
        TempTable."Entry No." := 1;
        TempTable.Insert(false);
        TempTable.SetContent('ROUNDTRIP');
        Observer.Observe('temporary table', TempTable.GetContent());
        Observer.Finish();
    end;

    local procedure CellName(i: Integer): Text
    var
        Name: Text;
    begin
        if i mod 2 = 1 then
            Name := 'clear'
        else
            Name := 'noclear';
        if (i div 2) mod 2 = 1 then
            Name += '+get'
        else
            Name += '+noget';
        if i div 4 = 1 then
            Name += '+hasvalue'
        else
            Name += '+nohasvalue';
        exit(Name);
    end;

    local procedure DbCell(i: Integer): Text
    var
        BlobRec: Record "ALT Blob";
    begin
        exit(AltBlobCell(BlobRec, i));
    end;

    local procedure TempVarCell(i: Integer): Text
    var
        TempBlobRec: Record "ALT Blob" temporary;
    begin
        exit(AltBlobCell(TempBlobRec, i));
    end;

    local procedure AltBlobCell(var BlobRec: Record "ALT Blob"; i: Integer): Text
    var
        OutS: OutStream;
        InS: InStream;
        HasBefore: Text;
        ReadBack: Text;
    begin
        BlobRec.Init();
        BlobRec.Code := 'CELL' + Format(i);
        BlobRec.Insert(true);
        if i mod 2 = 1 then
            Clear(BlobRec.Data);
        BlobRec.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('ROUNDTRIP');
        if (i div 2) mod 2 = 1 then
            BlobRec.Get(BlobRec.Code);
        HasBefore := '-';
        if i div 4 = 1 then
            HasBefore := Format(BlobRec.Data.HasValue());
        BlobRec.CalcFields(Data);
        BlobRec.Data.CreateInStream(InS, TextEncoding::UTF8);
        InS.Read(ReadBack);
        exit(StrSubstNo('hv=%1 read=%2 after=%3', HasBefore, ReadBack, BlobRec.Data.HasValue()));
    end;

    local procedure TempTableCell(i: Integer): Text
    var
        Row: Record "STR Blob Temp Row";
        OutS: OutStream;
        InS: InStream;
        HasBefore: Text;
        ReadBack: Text;
    begin
        Row.Init();
        Row."Entry No." := 100 + i;
        Row.Insert(false);
        if i mod 2 = 1 then
            Clear(Row.Content);
        Row.Content.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('ROUNDTRIP');
        if (i div 2) mod 2 = 1 then
            Row.Get(Row."Entry No.");
        HasBefore := '-';
        if i div 4 = 1 then
            HasBefore := Format(Row.Content.HasValue());
        Row.CalcFields(Content);
        Row.Content.CreateInStream(InS, TextEncoding::UTF8);
        InS.Read(ReadBack);
        exit(StrSubstNo('hv=%1 read=%2 after=%3', HasBefore, ReadBack, Row.Content.HasValue()));
    end;
}

// local object: the test checks a table with TableType = Temporary (al-runner issue 6791).
table 95782 "STR Blob Temp Row"
{
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(10; Content; Blob) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }

    procedure SetContent(ContentP: Text)
    var
        OutStreamL: OutStream;
    begin
        Clear(Rec.Content);
        if ContentP = '' then
            exit;
        Rec.Content.CreateOutStream(OutStreamL, TextEncoding::UTF8);
        OutStreamL.WriteText(ContentP);
    end;

    procedure GetContent() ResultR: Text
    var
        InStreamL: InStream;
    begin
        if not Rec.Content.HasValue() then
            exit('');
        Rec.CalcFields(Content);
        Rec.Content.CreateInStream(InStreamL, TextEncoding::UTF8);
        InStreamL.Read(ResultR);
    end;
}
