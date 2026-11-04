// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-error-handling
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/query/query-open-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-import-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000, database-backed), ALT Universal Query (60022),
//                ALT Universal XmlPort (60023)
//
// TestAssertErrorRollback.al (Codeunit 60943) pins what an unrelated asserterror rolls back
// for plain AL writes. This suite pins the same question when a BC API that opens its OWN
// nested transaction runs BETWEEN the write and the later, unrelated error: Query.Open() and
// the STATEMENT-FORM XmlPort.Import(...) (its return value not captured — AL's compiler picks
// DataError.ThrowError for that shape) both run inside a PLAIN nested transaction
// (Session.BeginTransaction() / Session.EndTransaction(commit: true)) that only joins the
// caller's already-open transaction — it is not a commit boundary. A write made before either
// of them, with no intervening Commit(), must still be rolled back by a later, unrelated
// asserterror exactly as if the nested API had never run.
codeunit 60945 "Test AssertError Rollback NTx"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Modify_QueryOpen_UnrelatedAssertError_NoCommit_ModifyIsRolledBack()
    var
        Rec: Record "ALT Universal";
        UniversalQuery: Query "ALT Universal Query";
    begin
        Initialize();

        Rec."Entry No." := 1;
        Rec."Integer Field" := 10;
        Rec.Insert(false);
        Commit();

        Rec.Get(1);
        Rec."Integer Field" := 99;
        Rec.Modify(false);

        UniversalQuery.Open();
        UniversalQuery.Read();
        UniversalQuery.Close();

        asserterror Error('unrelated error after an uncommitted modify and a Query.Open()');
        Assert.ExpectedError('unrelated error after an uncommitted modify and a Query.Open()');

        Clear(Rec);
        Rec.Get(1);
        Assert.AreEqual(10, Rec."Integer Field",
            'a Query.Open() between the uncommitted Modify and the unrelated error must NOT become a commit point — the Modify must still roll back');
    end;

    [Test]
    procedure Insert_QueryOpen_UnrelatedAssertError_NoCommit_InsertIsRolledBack()
    var
        Rec: Record "ALT Universal";
        UniversalQuery: Query "ALT Universal Query";
    begin
        Initialize();

        Rec."Entry No." := 7;
        Rec.Insert(false);

        UniversalQuery.Open();
        UniversalQuery.Read();
        UniversalQuery.Close();

        asserterror Error('unrelated error after an uncommitted insert and a Query.Open()');
        Assert.ExpectedError('unrelated error after an uncommitted insert and a Query.Open()');

        Assert.IsFalse(Rec.Get(7),
            'a Query.Open() between the uncommitted Insert and the unrelated error must NOT become a commit point — the Insert must still roll back');
        Assert.AreEqual(0, Rec.Count(), 'no trace of the insert may remain');
    end;

    [Test]
    procedure Insert_QueryOpenInline_UnrelatedAssertError_NoCommit_InsertIsRolledBack()
    var
        Rec: Record "ALT Universal";
        UniversalQuery: Query "ALT Universal Query";
    begin
        Initialize();

        Rec."Entry No." := 8;
        Rec.Insert(false);
        UniversalQuery.Open();
        UniversalQuery.Read();
        UniversalQuery.Close();

        asserterror Error('unrelated error, no BC-API call frame between the Query.Open() and the error');
        Assert.ExpectedError('unrelated error, no BC-API call frame between the Query.Open() and the error');

        Assert.IsFalse(Rec.Get(8),
            'a Query.Open() called directly in the test procedure (not inside a helper) must behave the same as one called from a subscriber or helper call frame');
        Assert.AreEqual(0, Rec.Count(), 'no trace of the insert may remain');
    end;

    [Test]
    procedure Insert_StatementFormXmlPortImport_UnrelatedAssertError_NoCommit_InsertIsRolledBack()
    var
        Rec: Record "ALT Universal";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
    begin
        Initialize();

        Rec."Entry No." := 11;
        Rec.Insert(false);

        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText(
            '<?xml version="1.0" encoding="utf-8"?><Universals><Universal><EntryNo>21</EntryNo><IntegerValue>0</IntegerValue><TextValue>x</TextValue></Universal></Universals>');
        TempBlob.CreateInStream(InStr);
        XmlPort.Import(XmlPort::"ALT Universal XmlPort", InStr);

        asserterror Error('unrelated error after an uncommitted insert and a statement-form XmlPort.Import');
        Assert.ExpectedError('unrelated error after an uncommitted insert and a statement-form XmlPort.Import');

        Assert.IsFalse(Rec.Get(11),
            'a statement-form XmlPort.Import (Boolean result not captured) between the uncommitted Insert and the unrelated error must NOT become a commit point — the Insert must still roll back');
        Assert.IsFalse(Rec.Get(21),
            'the row the statement-form XmlPort.Import itself inserted must ALSO roll back — it ran inside the same plain nested transaction as the caller, not a durable transaction world');
        Assert.AreEqual(0, Rec.Count(), 'no trace of either insert may remain');
    end;

    local procedure Initialize()
    var
        Rec: Record "ALT Universal";
    begin
        Rec.DeleteAll(false);
        // Commit the cleanup itself — see TestAssertErrorRollback.al's Initialize() for why:
        // TestIsolation = Codeunit does not reset table state between test methods, so an
        // uncommitted DeleteAll() would itself be rolled back by a later test's own unrelated
        // asserterror, resurrecting a leftover row under the same "Entry No.".
        Commit();
    end;
}
