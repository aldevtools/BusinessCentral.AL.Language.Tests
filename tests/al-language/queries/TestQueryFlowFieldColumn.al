// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/query/query-data-type
//   dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: QFF Line (60974), QFF Header (60975), QFF Header FlowField (60979),
//   QFF Link (60953), QFF Join Header FlowField (60955), QFF Header Dated (60271),
//   QFF Join Header Dated (60272)
//
// A query column selecting a FlowField reads the FlowField's calculated value, the same
// value Record.CalcFields would compute for that row — not the field's raw/unset storage,
// and not zero when no source rows exist yet to sum. That holds even when the FlowField
// column's dataitem also participates in a multi-dataitem JOIN — real BC's SQL executes the
// FlowField's OuterApply sub-query per outer row regardless of any application-level JOIN.
//
// It also holds when the FlowField's CalcFormula narrows its aggregate with a FLOW FILTER
// (`where(... "Posting Date" = field("Date Filter"))`). A query supplies that flow filter
// through a `filter()` element on the FlowFilter field, and setting it constrains the
// FlowField column exactly the way Record.SetRange("Date Filter", ...) constrains
// Record.CalcFields. Leaving it unset constrains nothing — an unset flow filter contributes
// no condition, so the column reads the whole aggregate.
codeunit 60987 "QFF Query FlowField Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        QffHeader: Record "QFF Header";
        QffLine: Record "QFF Line";
    begin
        QffLine.DeleteAll();
        QffHeader.DeleteAll();
    end;

    [Test]
    procedure FlowFieldColumn_ReadsCalculatedValue()
    var
        QffHeader: Record "QFF Header";
        QffLine: Record "QFF Line";
        Q: Query "QFF Header FlowField";
    begin
        Initialize();

        QffHeader.Init();
        QffHeader."No." := 'H1';
        QffHeader.Insert();

        QffLine.Init();
        QffLine."Entry No." := 1;
        QffLine."Header No." := 'H1';
        QffLine.Amount := 10.5;
        QffLine.Insert();

        QffLine.Init();
        QffLine."Entry No." := 2;
        QffLine."Header No." := 'H1';
        QffLine.Amount := 4.5;
        QffLine.Insert();

        Q.SetRange(No, 'H1');
        Q.Open();

        Assert.IsTrue(Q.Read(), 'Query must return the one matching header row');
        Assert.AreEqual(15, Q.TotalAmount, 'Query FlowField column must read the sum of matching QFF Line rows');
        Assert.IsFalse(Q.Read(), 'Query must only return one row');
        Q.Close();
    end;

    [Test]
    procedure FlowFieldColumn_NoMatchingSourceRows_ReadsZero()
    var
        QffHeader: Record "QFF Header";
        Q: Query "QFF Header FlowField";
    begin
        Initialize();

        QffHeader.Init();
        QffHeader."No." := 'H2';
        QffHeader.Insert();

        Q.SetRange(No, 'H2');
        Q.Open();

        Assert.IsTrue(Q.Read(), 'Query must return the one matching header row');
        Assert.AreEqual(0, Q.TotalAmount, 'Query FlowField column with no matching source rows must read 0, not fail');
        Q.Close();
    end;

    [Test]
    procedure JoinFlowFieldColumn_ReadsCalculatedValue()
    var
        QffHeader: Record "QFF Header";
        QffLine: Record "QFF Line";
        QffLink: Record "QFF Link";
        Q: Query "QFF Join Header FlowField";
    begin
        Initialize();
        QffLink.DeleteAll();

        QffHeader.Init();
        QffHeader."No." := 'H3';
        QffHeader.Insert();

        QffLine.Init();
        QffLine."Entry No." := 1;
        QffLine."Header No." := 'H3';
        QffLine.Amount := 7.25;
        QffLine.Insert();

        QffLink.Init();
        QffLink."Entry No." := 1;
        QffLink."Header No." := 'H3';
        QffLink.Insert();

        Q.Open();

        Assert.IsTrue(Q.Read(), 'Query must return the one joined row');
        Assert.AreEqual(7.25, Q.TotalAmount, 'A JOIN that also selects a FlowField column must read the FlowField''s calculated value for the joined row');
        Assert.IsFalse(Q.Read(), 'Query must only return one row');
        Q.Close();
    end;

    [Test]
    procedure FlowFilterFlowFieldColumn_NoFilterSet_ReadsWholeAggregate()
    var
        QffHeader: Record "QFF Header";
        Q: Query "QFF Header Dated";
    begin
        Initialize();
        SeedDatedHeader('H4');

        Q.SetRange(No, 'H4');
        Q.Open();

        Assert.IsTrue(Q.Read(), 'Query must return the one matching header row');
        Assert.AreEqual(15, Q.DatedAmount,
          'An UNSET flow filter contributes no condition, so the FlowField column must read the whole aggregate');
        Q.Close();

        // Same claim through Record.CalcFields, so the query answer is pinned against the
        // record answer rather than only against itself.
        QffHeader.Get('H4');
        QffHeader.CalcFields("Dated Amount");
        Assert.AreEqual(15, QffHeader."Dated Amount",
          'Record.CalcFields with no flow filter set must read the same whole aggregate');
    end;

    [Test]
    procedure FlowFilterFlowFieldColumn_FilterSet_NarrowsAggregate()
    var
        QffHeader: Record "QFF Header";
        Q: Query "QFF Header Dated";
    begin
        Initialize();
        SeedDatedHeader('H5');

        Q.SetRange(No, 'H5');
        Q.SetFilter(DateFilter, '%1..%2', 20240101D, 20240215D);
        Q.Open();

        Assert.IsTrue(Q.Read(), 'Query must return the one matching header row');
        Assert.AreEqual(14, Q.DatedAmount,
          'A flow filter set through the query''s filter() element must narrow the FlowField column''s aggregate');
        Assert.IsFalse(Q.Read(), 'Query must only return one row');
        Q.Close();

        QffHeader.Get('H5');
        QffHeader.SetRange("Date Filter", 20240101D, 20240215D);
        QffHeader.CalcFields("Dated Amount");
        Assert.AreEqual(14, QffHeader."Dated Amount",
          'Record.CalcFields under the same flow filter must read the same narrowed aggregate');
    end;

    [Test]
    procedure JoinFlowFilterFlowFieldColumn_FilterSet_NarrowsAggregate()
    var
        QffLink: Record "QFF Link";
        Q: Query "QFF Join Header Dated";
    begin
        Initialize();
        QffLink.DeleteAll();
        SeedDatedHeader('H6');

        QffLink.Init();
        QffLink."Entry No." := 1;
        QffLink."Header No." := 'H6';
        QffLink.Insert();

        Q.SetFilter(DateFilter, '%1..%2', 20240101D, 20240215D);
        Q.Open();

        Assert.IsTrue(Q.Read(), 'Query must return the one joined row');
        Assert.AreEqual(1, Q.EntryNo, 'The joined row must be the one QFF Link row');
        Assert.AreEqual(14, Q.DatedAmount,
          'A JOIN that selects a flow-filtered FlowField column must apply the query''s flow filter to it');
        Assert.IsFalse(Q.Read(), 'Query must only return one row');
        Q.Close();
    end;

    /// <summary>
    /// One header with three lines — 10 on 2024-01-10, 4 on 2024-02-10, 1 on 2024-03-10.
    /// The whole aggregate is 15; the 2024-01-01..2024-02-15 window is 14.
    /// </summary>
    local procedure SeedDatedHeader(HeaderNo: Code[20])
    var
        QffHeader: Record "QFF Header";
        QffLine: Record "QFF Line";
    begin
        QffHeader.Init();
        QffHeader."No." := HeaderNo;
        QffHeader.Insert();

        QffLine.Init();
        QffLine."Entry No." := 1;
        QffLine."Header No." := HeaderNo;
        QffLine."Posting Date" := 20240110D;
        QffLine.Amount := 10;
        QffLine.Insert();

        QffLine.Init();
        QffLine."Entry No." := 2;
        QffLine."Header No." := HeaderNo;
        QffLine."Posting Date" := 20240210D;
        QffLine.Amount := 4;
        QffLine.Insert();

        QffLine.Init();
        QffLine."Entry No." := 3;
        QffLine."Header No." := HeaderNo;
        QffLine."Posting Date" := 20240310D;
        QffLine.Amount := 1;
        QffLine.Insert();
    end;
}
