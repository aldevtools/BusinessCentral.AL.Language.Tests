// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALTFixtureCleanup (60019), shared Assert (60021),
//                ALT Run Tx None Card (60414), ALT Run Tx None Inserter (60879)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// "Test Write Tx Test Boundary" (60878) pins that a direct Insert from a TransactionModel::None
// test body is refused. This codeunit pins the rest of the write family: Modify, Delete,
// DeleteAll, ModifyAll, Rename and Truncate are refused with the same text and the same error
// code, and the page constructs that begin a transaction of their own (TestPage operations,
// Page.Run and Page.RunModal driven through a handler) are allowed. After a TestPage operation
// no write transaction is left open, so a guarded Codeunit.Run is allowed.
//
// Declaration-ordered: the first test (default model, committed at its boundary) seeds the
// rows and the later tests rely on them.
// BC versions: 27.5

codeunit 68102 "Probe Write Tx None Model"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        HandlerLog: Text;

    local procedure Refused(): Text
    begin
        exit('A transaction must be started before changes can be made to the database.');
    end;

    local procedure Count(EntryNo: Integer): Integer
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.SetRange("Entry No.", EntryNo);
        exit(ALTUniversal.Count());
    end;

    [Test]
    procedure NoneModel_Test01_SeedsTheRows()
    var
        ALTUniversal: Record "ALT Universal";
        EntryNo: Integer;
    begin
        Cleanup.Initialize();
        for EntryNo := 101 to 104 do begin
            ALTUniversal.Init();
            ALTUniversal."Entry No." := EntryNo;
            ALTUniversal."Text Field" := 'seed';
            ALTUniversal.Insert();
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::None)]
    procedure NoneModel_Test02_Modify_IsRefused()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Get(101);
        ALTUniversal."Text Field" := 'changed';

        asserterror ALTUniversal.Modify();

        Assert.AreEqual(Refused(), GetLastErrorText(), 'text of the refused Modify');
        Assert.AreEqual('DB:BWTMissing', GetLastErrorCode(), 'code of the refused Modify');
        ALTUniversal.Get(101);
        Assert.AreEqual('seed', ALTUniversal."Text Field", 'the refused Modify changed nothing');
    end;

    [Test]
    [TransactionModel(TransactionModel::None)]
    procedure NoneModel_Test03_Delete_IsRefused()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Get(102);

        asserterror ALTUniversal.Delete();

        Assert.AreEqual(Refused(), GetLastErrorText(), 'text of the refused Delete');
        Assert.AreEqual('DB:BWTMissing', GetLastErrorCode(), 'code of the refused Delete');
        Assert.AreEqual(1, Count(102), 'the refused Delete removed nothing');
    end;

    [Test]
    [TransactionModel(TransactionModel::None)]
    procedure NoneModel_Test04_DeleteAll_IsRefused()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.SetRange("Entry No.", 103);

        asserterror ALTUniversal.DeleteAll();

        Assert.AreEqual(Refused(), GetLastErrorText(), 'text of the refused DeleteAll');
        Assert.AreEqual('DB:BWTMissing', GetLastErrorCode(), 'code of the refused DeleteAll');
        Assert.AreEqual(1, Count(103), 'the refused DeleteAll removed nothing');
    end;

    [Test]
    [TransactionModel(TransactionModel::None)]
    procedure NoneModel_Test05_ModifyAll_IsRefused()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.SetRange("Entry No.", 103);

        asserterror ALTUniversal.ModifyAll("Text Field", 'changed');

        Assert.AreEqual(Refused(), GetLastErrorText(), 'text of the refused ModifyAll');
        Assert.AreEqual('DB:BWTMissing', GetLastErrorCode(), 'code of the refused ModifyAll');
    end;

    [Test]
    [TransactionModel(TransactionModel::None)]
    procedure NoneModel_Test06_Rename_IsRefused()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Get(104);

        asserterror ALTUniversal.Rename(204);

        Assert.AreEqual(Refused(), GetLastErrorText(), 'text of the refused Rename');
        Assert.AreEqual('DB:BWTMissing', GetLastErrorCode(), 'code of the refused Rename');
        Assert.AreEqual(1, Count(104), 'the refused Rename left the old key');
        Assert.AreEqual(0, Count(204), 'the refused Rename created no new key');
    end;

    [Test]
    [TransactionModel(TransactionModel::None)]
    procedure NoneModel_Test07_Truncate_IsRefused()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        asserterror ALTUniversal.Truncate();

        Assert.AreEqual(Refused(), GetLastErrorText(), 'text of the refused Truncate');
        Assert.AreEqual('DB:BWTMissing', GetLastErrorCode(), 'code of the refused Truncate');
        Assert.AreEqual(1, Count(101), 'the refused Truncate removed nothing');
        Assert.IsFalse(Database.IsInWriteTransaction(), 'a refused write leaves no write transaction');
    end;

    [Test]
    [TransactionModel(TransactionModel::None)]
    [HandlerFunctions('EditThroughModalHandler')]
    procedure NoneModel_Test08_RunModal_HandlerEditsAndWrites()
    var
        ALTUniversal: Record "ALT Universal";
        Card: Page "ALT Run Tx None Card";
    begin
        ALTUniversal.Get(101);
        Card.SetRecord(ALTUniversal);

        Card.RunModal();

        Assert.AreEqual('modal-entered;modal-set;', HandlerLog, 'the modal handler ran to the end');
        ALTUniversal.Get(101);
        Assert.AreEqual('MODAL', ALTUniversal."Text Field", 'the page row Modify is allowed under None');
        Assert.AreEqual(1, Count(9414), 'the field OnValidate marker is written');
        Assert.IsFalse(Database.IsInWriteTransaction(), 'the transaction the page began has ended');
    end;

    [Test]
    procedure NoneModel_Test09_ClearsTheMarker()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        // Default model: the OnValidate marker would collide with the next arm.
        ALTUniversal.Get(9414);
        ALTUniversal.Delete();
    end;

    [Test]
    [TransactionModel(TransactionModel::None)]
    [HandlerFunctions('EditThroughPageHandler')]
    procedure NoneModel_Test10_PageRun_HandlerEditsAndWrites()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Get(101);

        Page.Run(Page::"ALT Run Tx None Card", ALTUniversal);

        Assert.AreEqual('page-entered;page-set;', HandlerLog, 'the page handler ran to the end');
        ALTUniversal.Get(101);
        Assert.AreEqual('PAGE', ALTUniversal."Text Field", 'the page row Modify is allowed under None');
        Assert.AreEqual(1, Count(9414), 'the field OnValidate marker is written');
        Assert.IsFalse(Database.IsInWriteTransaction(), 'the transaction the page began has ended');
    end;

    [Test]
    procedure NoneModel_Test11_ClearsTheMarkerAgain()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Get(9414);
        ALTUniversal.Delete();
    end;

    [Test]
    [TransactionModel(TransactionModel::None)]
    procedure NoneModel_Test12_TestPageOperations_LeaveNoWriteTransaction()
    var
        Card: TestPage "ALT Run Tx None Card";
    begin
        Card.OpenEdit();
        Assert.IsFalse(Database.IsInWriteTransaction(), 'after OpenEdit');
        Card.GoToKey(102);
        Assert.IsFalse(Database.IsInWriteTransaction(), 'after GoToKey');

        Card."Text Field".SetValue('EDITED');

        Assert.AreEqual(1, Count(9414), 'the OnValidate marker written by SetValue is visible');
        Assert.IsFalse(Database.IsInWriteTransaction(), 'after SetValue the transaction the page began has ended');
        Assert.IsTrue(Codeunit.Run(Codeunit::"ALT Run Tx None Inserter"), 'so a guarded Codeunit.Run is allowed straight after SetValue');

        Card.Close();
        Assert.IsFalse(Database.IsInWriteTransaction(), 'after Close');
    end;

    [Test]
    procedure NoneModel_Test13_ClearsTheFixture()
    begin
        Cleanup.Initialize();
        Assert.AreEqual(0, Count(9414), 'the fixture is empty again');
        Assert.AreEqual(0, Count(9879), 'the fixture is empty again');
    end;

    [ModalPageHandler]
    procedure EditThroughModalHandler(var Card: TestPage "ALT Run Tx None Card")
    begin
        HandlerLog += 'modal-entered;';
        Card."Text Field".SetValue('MODAL');
        HandlerLog += 'modal-set;';
    end;

    [PageHandler]
    procedure EditThroughPageHandler(var Card: TestPage "ALT Run Tx None Card")
    begin
        HandlerLog := 'page-entered;';
        Card."Text Field".SetValue('PAGE');
        HandlerLog += 'page-set;';
    end;
}
