// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sqljointype-property
//   dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: QJ Customer (60861), QJ Order (60862), QJ Cust Orders Implicit (60601),
//   QJ Cust Orders Left (60864), QJ Cust Orders Inner (60863); shared Assert (60021)
//
// What SqlJoinType defaults to when a nested dataitem does not declare it.
//
// TestQueryJoin.al already covers both joins where the query SPELLS THE PROPERTY OUT:
// "QJ Cust Orders Inner" declares InnerJoin and drops Carol, "QJ Cust Orders Left" declares
// LeftOuterJoin and keeps her. Neither can answer what the property defaults to, because
// both state it. "QJ Cust Orders Implicit" (60601) is the same join with the property
// omitted, so the row count IS the default.
//
// Seed data is identical to TestQueryJoin.al's, deliberately, so the three row counts are
// directly comparable against each other:
//   QJ Customer:  C1 "Alice", C2 "Bob", C3 "Carol"
//   QJ Order:     1 -> C1 amount 100
//                 2 -> C1 amount 200
//                 3 -> C2 amount 300
//   C3 "Carol" has NO order row, so she is the discriminator: an InnerJoin default drops
//   her (3 rows) and a LeftOuterJoin default keeps her (4 rows).
codeunit 60603 "QJ Query Join Default Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Cust: Record "QJ Customer";
        Ord: Record "QJ Order";
    begin
        Cust.DeleteAll();
        Ord.DeleteAll();

        InsertCust(Cust, 'C1', 'Alice');
        InsertCust(Cust, 'C2', 'Bob');
        InsertCust(Cust, 'C3', 'Carol');

        InsertOrder(Ord, 1, 'C1', 100);
        InsertOrder(Ord, 2, 'C1', 200);
        InsertOrder(Ord, 3, 'C2', 300);
    end;

    local procedure InsertCust(var Cust: Record "QJ Customer"; No: Code[20]; Name: Text[50])
    begin
        Cust.Init();
        Cust."No." := No;
        Cust.Name := Name;
        Cust.Insert();
    end;

    local procedure InsertOrder(var Ord: Record "QJ Order"; EntryNo: Integer; CustNo: Code[20]; Amount: Decimal)
    begin
        Ord.Init();
        Ord."Entry No." := EntryNo;
        Ord."Customer No." := CustNo;
        Ord.Amount := Amount;
        Ord.Insert();
    end;

    // The claim: a nested dataitem with no SqlJoinType behaves as LeftOuterJoin, so the
    // unmatched parent Carol is KEPT with default child columns. An InnerJoin default would
    // give 3 rows and no Carol.
    [Test]
    procedure OmittedSqlJoinType_DefaultsToLeftOuterJoin_KeepsUnmatchedParent()
    var
        Q: Query "QJ Cust Orders Implicit";
        RowCount: Integer;
        SawCarol: Boolean;
    begin
        Initialize();
        Q.Open();
        RowCount := 0;
        SawCarol := false;

        while Q.Read() do begin
            RowCount += 1;
            if Q.CustNo = 'C3' then begin
                SawCarol := true;
                Assert.AreEqual('Carol', Q.CustName, 'The unmatched parent keeps its own column values');
                Assert.AreEqual(0, Q.EntryNo, 'The unmatched parent gets the default child entry no');
                Assert.AreEqual(0, Q.Amount, 'The unmatched parent gets the default child amount');
            end;
        end;
        Q.Close();

        Assert.IsTrue(SawCarol, 'An omitted SqlJoinType must still emit the unmatched parent (Carol)');
        Assert.AreEqual(4, RowCount, 'An omitted SqlJoinType joins as LeftOuterJoin → 4 rows, not InnerJoin''s 3');
    end;

    // The negative direction, and the reason the count above is not a coincidence: the SAME
    // seed data through a query that DECLARES InnerJoin drops Carol and returns 3 rows. If
    // the default were InnerJoin, both counts would be 3 and the test above could not tell
    // the two apart.
    [Test]
    procedure DeclaredInnerJoin_OverTheSameData_DropsTheUnmatchedParent()
    var
        Q: Query "QJ Cust Orders Inner";
        RowCount: Integer;
        SawCarol: Boolean;
    begin
        Initialize();
        Q.Open();
        RowCount := 0;
        SawCarol := false;

        while Q.Read() do begin
            RowCount += 1;
            if Q.CustNo = 'C3' then
                SawCarol := true;
        end;
        Q.Close();

        Assert.IsFalse(SawCarol, 'A declared InnerJoin drops the unmatched parent (Carol)');
        Assert.AreEqual(3, RowCount, 'A declared InnerJoin over this data returns 3 rows');
    end;

    // And the positive control: the query that DECLARES LeftOuterJoin agrees with the
    // omitted-property query row for row, which is what "the default is LeftOuterJoin" means.
    [Test]
    procedure OmittedSqlJoinType_AgreesRowForRowWithDeclaredLeftOuterJoin()
    var
        QImplicit: Query "QJ Cust Orders Implicit";
        QDeclared: Query "QJ Cust Orders Left";
        ImplicitRows: Text;
        DeclaredRows: Text;
    begin
        Initialize();

        QImplicit.Open();
        while QImplicit.Read() do
            ImplicitRows += StrSubstNo('%1/%2/%3;', QImplicit.CustNo, QImplicit.EntryNo, QImplicit.Amount);
        QImplicit.Close();

        QDeclared.Open();
        while QDeclared.Read() do
            DeclaredRows += StrSubstNo('%1/%2/%3;', QDeclared.CustNo, QDeclared.EntryNo, QDeclared.Amount);
        QDeclared.Close();

        Assert.AreEqual('C1/1/100;C1/2/200;C2/3/300;C3/0/0;', DeclaredRows, 'The declared LeftOuterJoin produces these four rows');
        Assert.AreEqual(DeclaredRows, ImplicitRows, 'Omitting SqlJoinType must produce exactly the declared-LeftOuterJoin result');
    end;
}
