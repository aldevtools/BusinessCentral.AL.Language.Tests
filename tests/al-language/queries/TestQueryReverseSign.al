// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-reversesign-property
// Scope: in-scope
// Fixtures used: QJ Order (60862), QJ Order Reverse Sign (60935), QJ Order Sum Reverse Sign
// (60939); shared Assert (60021)
//
// A query column's ReverseSign property negates the value the column reads — independent of
// every OTHER column in the same query, and independent of whether the column is aggregated.
codeunit 60946 "QJ Query Reverse Sign Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Ord: Record "QJ Order";
    begin
        Ord.DeleteAll();
    end;

    local procedure InsertOrder(EntryNo: Integer; CustNo: Code[20]; Amount: Decimal)
    var
        Ord: Record "QJ Order";
    begin
        Ord.Init();
        Ord."Entry No." := EntryNo;
        Ord."Customer No." := CustNo;
        Ord.Amount := Amount;
        Ord.Insert();
    end;

    // A plain (non-aggregated) column with ReverseSign = true over a row whose Amount is 100
    // must read -100, not 100.
    [Test]
    procedure ReverseSignOnPlainColumn_NegatesTheValue()
    var
        Query: Query "QJ Order Reverse Sign";
        RowCount: Integer;
    begin
        Initialize();
        InsertOrder(1, 'C1', 100);

        Query.Open();
        while Query.Read() do begin
            RowCount += 1;
            Assert.AreEqual(-100, Query.ReversedAmount, 'ReverseSign = true must negate the column value');
        end;
        Query.Close();

        Assert.AreEqual(1, RowCount, 'The single inserted row must be returned');
    end;

    // Negative sibling, same query, same row: a SIBLING column over the SAME field WITHOUT
    // ReverseSign must keep reading the un-negated value — a runtime that negated every column
    // regardless of the property would fail this half instead.
    [Test]
    procedure PlainColumnWithoutReverseSign_KeepsTheOriginalSign()
    var
        Query: Query "QJ Order Reverse Sign";
        RowCount: Integer;
    begin
        Initialize();
        InsertOrder(1, 'C1', 100);

        Query.Open();
        while Query.Read() do begin
            RowCount += 1;
            Assert.AreEqual(100, Query.Amount, 'A sibling column without ReverseSign must not be negated');
        end;
        Query.Close();

        Assert.AreEqual(1, RowCount, 'The single inserted row must be returned');
    end;

    // Method = Sum with ReverseSign = true: two same-sign rows (100 and 40) for one customer
    // must read -140 — the negated total, not the total of two already-negated values summing
    // to a DIFFERENT-looking but arithmetically identical result (the point of this case is the
    // concrete value, not the ordering).
    [Test]
    procedure ReverseSignOnSumColumn_SameSignRows_NegatesTheTotal()
    var
        Query: Query "QJ Order Sum Reverse Sign";
        RowCount: Integer;
    begin
        Initialize();
        InsertOrder(1, 'C1', 100);
        InsertOrder(2, 'C1', 40);

        Query.Open();
        while Query.Read() do begin
            RowCount += 1;
            Assert.AreEqual('C1', Query.CustNo, 'Only C1 has rows');
            Assert.AreEqual(-140, Query.TotalAmount, 'ReverseSign on a Sum column must negate the group total (100 + 40 = 140, negated -140)');
        end;
        Query.Close();

        Assert.AreEqual(1, RowCount, 'C1''s two orders must group into exactly one row');
    end;

    // Mixed-sign sibling: rows 100 and -40 for one customer must read -60 (the negated total of
    // 60), proving the negation is applied to the RESULT and not, say, only to positive source
    // rows or only when every row shares one sign.
    [Test]
    procedure ReverseSignOnSumColumn_MixedSignRows_NegatesTheTotal()
    var
        Query: Query "QJ Order Sum Reverse Sign";
        RowCount: Integer;
    begin
        Initialize();
        InsertOrder(1, 'C1', 100);
        InsertOrder(2, 'C1', -40);

        Query.Open();
        while Query.Read() do begin
            RowCount += 1;
            Assert.AreEqual('C1', Query.CustNo, 'Only C1 has rows');
            Assert.AreEqual(-60, Query.TotalAmount, 'ReverseSign on a Sum column must negate the group total (100 + -40 = 60, negated -60)');
        end;
        Query.Close();

        Assert.AreEqual(1, RowCount, 'C1''s two orders must group into exactly one row');
    end;
}
