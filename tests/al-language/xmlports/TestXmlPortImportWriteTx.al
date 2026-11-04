// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-import-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-instance-import-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Blob (60008), ALTFixtureCleanup (60019),
//                ALT Universal XmlPort (60023), ALT Run Tx Inserter (60253)
// Note: the XmlPort.Import counterpart of "Test Codeunit Run Write Tx" (60254). Whether the
// Boolean result is consumed decides which branch the platform takes: the statement form
// joins the caller's transaction and is allowed while an uncommitted write is pending; the
// value-consuming form opens a transaction world of its own, which the platform will not do
// while the caller holds an uncommitted write.
//
// The two spellings of the value-consuming form are asked separately because they need not
// agree: the STATIC XmlPort.Import(Id, InStream) traps errors raised inside it and turns them
// into a false result, while the INSTANCE XmlPortVar.Import() has no such wrapper. So the
// static form is expected to answer false without raising, and the instance form to raise.
// In both refused arms the xmlport never runs, so its rows do not exist.
//
// Asked by StefanMaron/BusinessCentral.AL.Runner#2184.
//
// The FailingImport tests ask the other half of the value-consuming form: when the import
// itself fails part-way (the second element carries a value its field cannot hold), is the
// row the first element already wrote rolled back with the transaction the import opened?
// A row committed by the caller before the import must survive either way.
// Asked by StefanMaron/BusinessCentral.AL.Runner#4643.
// BC versions: 24+

codeunit 60041 "Test XmlPort Import Write Tx"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
        // Cleanup deletes rows, which itself opens a write transaction. Close it so each
        // test below starts from a known state and controls its own pending write.
        Commit();
    end;

    local procedure InsertPendingRow()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 1;
        ALTUniversal.Insert();
    end;

    local procedure ImportedRowCount(): Integer
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Reset();
        ALTUniversal.SetRange("Entry No.", 9301, 9302);
        exit(ALTUniversal.Count());
    end;

    local procedure SecondImportRowCount(): Integer
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Reset();
        ALTUniversal.SetRange("Entry No.", 9311, 9312);
        exit(ALTUniversal.Count());
    end;

    local procedure OpenPayload(var BlobRec: Record "ALT Blob" temporary; var InStr: InStream)
    begin
        OpenPayloadFrom(BlobRec, InStr, 9301);
    end;

    local procedure OpenPayloadFrom(var BlobRec: Record "ALT Blob" temporary; var InStr: InStream; FirstEntryNo: Integer)
    var
        OutStr: OutStream;
    begin
        BlobRec.Reset();
        BlobRec.DeleteAll();
        BlobRec.Init();
        BlobRec.Code := 'TMP';
        BlobRec.Insert();
        BlobRec.Data.CreateOutStream(OutStr);
        OutStr.WriteText('<?xml version="1.0" encoding="UTF-8"?><Universals>' +
            StrSubstNo('<Universal><EntryNo>%1</EntryNo><IntegerValue>10</IntegerValue><TextValue>First</TextValue></Universal>', FirstEntryNo) +
            StrSubstNo('<Universal><EntryNo>%1</EntryNo><IntegerValue>20</IntegerValue><TextValue>Second</TextValue></Universal>', FirstEntryNo + 1) +
            '</Universals>');
        BlobRec.Data.CreateInStream(InStr);
    end;

    local procedure FailingImportRowCount(): Integer
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Reset();
        ALTUniversal.SetRange("Entry No.", 9321, 9322);
        exit(ALTUniversal.Count());
    end;

    local procedure OpenFailingPayload(var BlobRec: Record "ALT Blob" temporary; var InStr: InStream)
    var
        OutStr: OutStream;
    begin
        // The first element is valid and imports; the second carries a non-integer in an
        // Integer field, so the import fails after the first row has been written.
        BlobRec.Reset();
        BlobRec.DeleteAll();
        BlobRec.Init();
        BlobRec.Code := 'TMP';
        BlobRec.Insert();
        BlobRec.Data.CreateOutStream(OutStr);
        OutStr.WriteText('<?xml version="1.0" encoding="UTF-8"?><Universals>' +
            '<Universal><EntryNo>9321</EntryNo><IntegerValue>10</IntegerValue><TextValue>First</TextValue></Universal>' +
            '<Universal><EntryNo>9322</EntryNo><IntegerValue>NotAnInteger</IntegerValue><TextValue>Second</TextValue></Universal>' +
            '</Universals>');
        BlobRec.Data.CreateInStream(InStr);
    end;

    [Test]
    procedure StaticGuardedImport_WithUncommittedWrite_ReturnsFalse_AndImportsNothing()
    var
        BlobRec: Record "ALT Blob" temporary;
        InStr: InStream;
        Ok: Boolean;
    begin
        Initialize();
        OpenPayload(BlobRec, InStr);

        // [GIVEN] an uncommitted write, so the session holds an open write transaction
        InsertPendingRow();

        // [WHEN] the static XmlPort.Import is called with its Boolean result consumed
        Ok := XmlPort.Import(XmlPort::"ALT Universal XmlPort", InStr);

        // [THEN] it reports failure rather than raising, and the xmlport never ran
        Assert.IsFalse(Ok, 'A value-consuming static XmlPort.Import inside a write transaction must return false.');
        Assert.AreEqual(0, ImportedRowCount(),
            'The refused static XmlPort.Import must not have imported any row.');
    end;

    [Test]
    procedure InstanceGuardedImport_WithUncommittedWrite_IsRefused_AndImportsNothing()
    var
        BlobRec: Record "ALT Blob" temporary;
        UniversalXmlPort: XmlPort "ALT Universal XmlPort";
        InStr: InStream;
        Ok: Boolean;
    begin
        Initialize();
        OpenPayload(BlobRec, InStr);

        // [GIVEN] an uncommitted write, so the session holds an open write transaction
        InsertPendingRow();

        // [WHEN] the instance Import is called with its Boolean result consumed
        UniversalXmlPort.SetSource(InStr);
        asserterror Ok := UniversalXmlPort.Import();

        // [THEN] the platform refuses the call and the error reaches the caller
        Assert.ExpectedError('the transaction is stopped');
        Assert.IsFalse(Ok, 'A refused XmlPort Import must not assign a result.');
        Assert.AreEqual(0, ImportedRowCount(),
            'The refused instance XmlPort Import must not have imported any row.');
    end;

    [Test]
    procedure StaticStatementImport_WithUncommittedWrite_IsAllowed_AndImportsRows()
    var
        BlobRec: Record "ALT Blob" temporary;
        InStr: InStream;
    begin
        Initialize();
        OpenPayload(BlobRec, InStr);

        // [GIVEN] the same uncommitted write
        InsertPendingRow();

        // [WHEN] the static XmlPort.Import is called as a statement (result discarded)
        XmlPort.Import(XmlPort::"ALT Universal XmlPort", InStr);

        // [THEN] the call is allowed and both rows were imported
        Assert.AreEqual(2, ImportedRowCount(),
            'Statement-form XmlPort.Import is allowed in a write transaction and must import both rows.');
    end;

    [Test]
    procedure InstanceStatementImport_WithUncommittedWrite_IsAllowed_AndImportsRows()
    var
        BlobRec: Record "ALT Blob" temporary;
        UniversalXmlPort: XmlPort "ALT Universal XmlPort";
        InStr: InStream;
    begin
        Initialize();
        OpenPayload(BlobRec, InStr);

        // [GIVEN] the same uncommitted write
        InsertPendingRow();

        // [WHEN] the instance Import is called as a statement (result discarded)
        UniversalXmlPort.SetSource(InStr);
        UniversalXmlPort.Import();

        // [THEN] the call is allowed and both rows were imported
        Assert.AreEqual(2, ImportedRowCount(),
            'Statement-form XmlPort Import is allowed in a write transaction and must import both rows.');
    end;

    [Test]
    procedure StaticGuardedImport_AfterCommit_ReturnsTrue_AndImportsRows()
    var
        BlobRec: Record "ALT Blob" temporary;
        InStr: InStream;
        Ok: Boolean;
    begin
        Initialize();
        OpenPayload(BlobRec, InStr);

        // [GIVEN] a write that IS committed, so no write transaction is open
        InsertPendingRow();
        Commit();

        // [WHEN] the static XmlPort.Import is called with its Boolean result consumed
        Ok := XmlPort.Import(XmlPort::"ALT Universal XmlPort", InStr);

        // [THEN] it succeeds and both rows were imported
        Assert.IsTrue(Ok, 'A value-consuming static XmlPort.Import must succeed once Commit() has closed the write transaction.');
        Assert.AreEqual(2, ImportedRowCount(),
            'A value-consuming static XmlPort.Import after Commit() must import both rows.');
    end;

    [Test]
    procedure InstanceGuardedImport_AfterCommit_ReturnsTrue_AndImportsRows()
    var
        BlobRec: Record "ALT Blob" temporary;
        UniversalXmlPort: XmlPort "ALT Universal XmlPort";
        InStr: InStream;
        Ok: Boolean;
    begin
        Initialize();
        OpenPayload(BlobRec, InStr);

        // [GIVEN] a write that IS committed, so no write transaction is open
        InsertPendingRow();
        Commit();

        // [WHEN] the instance Import is called with its Boolean result consumed
        UniversalXmlPort.SetSource(InStr);
        Ok := UniversalXmlPort.Import();

        // [THEN] it succeeds and both rows were imported
        Assert.IsTrue(Ok, 'A value-consuming XmlPort Import must succeed once Commit() has closed the write transaction.');
        Assert.AreEqual(2, ImportedRowCount(),
            'A value-consuming XmlPort Import after Commit() must import both rows.');
    end;

    [Test]
    procedure GuardedImport_LeavingImportedRows_DoesNotBlockTheNextGuardedImport()
    var
        FirstBlob: Record "ALT Blob" temporary;
        SecondBlob: Record "ALT Blob" temporary;
        UniversalXmlPort: XmlPort "ALT Universal XmlPort";
        FirstInStr: InStream;
        SecondInStr: InStream;
        FirstOk: Boolean;
        SecondOk: Boolean;
        ThirdOk: Boolean;
    begin
        Initialize();
        OpenPayload(FirstBlob, FirstInStr);
        OpenPayloadFrom(SecondBlob, SecondInStr, 9311);

        // [GIVEN] no pending write in the caller, so the first value-consuming import is allowed
        FirstOk := XmlPort.Import(XmlPort::"ALT Universal XmlPort", FirstInStr);
        Assert.IsTrue(FirstOk, 'The first value-consuming XmlPort.Import must succeed.');
        Assert.AreEqual(2, ImportedRowCount(), 'The first import must have written its rows.');

        // [THEN] a SECOND value-consuming import is still allowed: the rows the first one wrote
        //        belong to the transaction it opened and ended, not to the caller, so the caller
        //        holds no open write transaction here.
        UniversalXmlPort.SetSource(SecondInStr);
        SecondOk := UniversalXmlPort.Import();
        Assert.IsTrue(SecondOk,
            'A value-consuming XmlPort Import must still be allowed after an earlier one wrote rows.');
        Assert.AreEqual(2, SecondImportRowCount(), 'The second import must have written its rows.');

        // [THEN] the guard itself is intact: a write made by the CALLER, uncommitted, still
        //        refuses the next value-consuming call.
        InsertPendingRow();
        asserterror ThirdOk := Codeunit.Run(Codeunit::"ALT Run Tx Inserter");
        Assert.ExpectedError('the transaction is stopped');
        Assert.IsFalse(ThirdOk, 'A refused Codeunit.Run must not assign a result.');
    end;

    [Test]
    procedure StaticGuardedImport_FailingSecondElement_ReturnsFalse_AndRollsBackTheFirstRow()
    var
        BlobRec: Record "ALT Blob" temporary;
        ALTUniversal: Record "ALT Universal";
        InStr: InStream;
        Ok: Boolean;
    begin
        Initialize();
        OpenFailingPayload(BlobRec, InStr);

        // [GIVEN] a row the caller wrote and committed, so no write transaction is open
        InsertPendingRow();
        Commit();

        // [WHEN] a value-consuming static XmlPort.Import fails on its second element
        Ok := XmlPort.Import(XmlPort::"ALT Universal XmlPort", InStr);

        // [THEN] it reports failure, the row its first element wrote is rolled back,
        //        and the caller's committed row is untouched
        Assert.IsFalse(Ok, 'A value-consuming static XmlPort.Import whose payload fails must return false.');
        Assert.AreEqual(0, FailingImportRowCount(),
            'A failed value-consuming static XmlPort.Import must roll back the row its first element wrote.');
        Assert.IsTrue(ALTUniversal.Get(1), 'The row the caller committed before the import must survive the failed import.');
    end;

    [Test]
    procedure InstanceGuardedImport_FailingSecondElement_ReturnsFalse_AndRollsBackTheFirstRow()
    var
        BlobRec: Record "ALT Blob" temporary;
        ALTUniversal: Record "ALT Universal";
        UniversalXmlPort: XmlPort "ALT Universal XmlPort";
        InStr: InStream;
        Ok: Boolean;
    begin
        Initialize();
        OpenFailingPayload(BlobRec, InStr);

        // [GIVEN] a row the caller wrote and committed, so no write transaction is open
        InsertPendingRow();
        Commit();

        // [WHEN] a value-consuming instance Import fails on its second element
        UniversalXmlPort.SetSource(InStr);
        Ok := UniversalXmlPort.Import();

        // [THEN] it reports failure, the row its first element wrote is rolled back,
        //        and the caller's committed row is untouched
        Assert.IsFalse(Ok, 'A value-consuming XmlPort Import whose payload fails must return false.');
        Assert.AreEqual(0, FailingImportRowCount(),
            'A failed value-consuming XmlPort Import must roll back the row its first element wrote.');
        Assert.IsTrue(ALTUniversal.Get(1), 'The row the caller committed before the import must survive the failed import.');
    end;
}
