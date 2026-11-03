// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/query/query-data-type
//   dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: QJF Assignment (60785), QJF Ledger (60786), QJF Value Entry (60787),
//   QJF Valuation (60788); shared Assert (60021)
//
// TestQueryFlowFieldColumn.al proved a JOIN query can select a FlowField column on its
// non-driving dataitem. TestQueryJoin.al (JoinWithAggregatedColumn_GroupsJoinedRows) proved a
// JOIN query's aggregated (Method = Sum) column implicitly groups the joined rows by every
// other column. This suite proves the two compose: a JOIN query selecting BOTH an aggregated
// column on the driving dataitem AND a FlowField column on the joined dataitem groups
// correctly, with the FlowField calculated per joined row and carried into the group like any
// other non-aggregated column — real BC's SQL executes the FlowField's OuterApply sub-query
// per outer row independent of the application-level GROUP BY.
//
// Reduced from a real AL project's valuation query (assigned quantity summed per project/item,
// joined to a ledger table to read a "Cost Amount" FlowField) that triggered this gap.
codeunit 60789 "QJF Join FF GroupBy Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Assignment: Record "QJF Assignment";
        Ledger: Record "QJF Ledger";
        ValueEntry: Record "QJF Value Entry";
    begin
        Assignment.DeleteAll();
        Ledger.DeleteAll();
        ValueEntry.DeleteAll();
    end;

    // Ledger 1 (item A) has two assignments (qty 2 and 3, total 5) and value entries summing
    // to 10 (4 + 6). Ledger 2 (item B) has one assignment (qty 5) and a value entry of 7. The
    // query must return exactly two groups — one per (project, ledger entry) pair, which here
    // coincides with one per item — each carrying the summed assigned quantity and the
    // per-group FlowField-calculated cost amount.
    [Test]
    procedure JoinWithSumAndFlowFieldColumn_ReadsBothPerGroup()
    var
        Assignment: Record "QJF Assignment";
        Ledger: Record "QJF Ledger";
        ValueEntry: Record "QJF Value Entry";
        Query: Query "QJF Valuation";
        RowCount: Integer;
        SawItemA, SawItemB : Boolean;
    begin
        Initialize();

        Ledger.Init(); Ledger."Entry No." := 1; Ledger."Item No." := 'A'; Ledger.Insert();
        Ledger.Init(); Ledger."Entry No." := 2; Ledger."Item No." := 'B'; Ledger.Insert();

        ValueEntry.Init(); ValueEntry."Entry No." := 1; ValueEntry."Ledger Entry No." := 1; ValueEntry."Cost Amount" := 4; ValueEntry.Insert();
        ValueEntry.Init(); ValueEntry."Entry No." := 2; ValueEntry."Ledger Entry No." := 1; ValueEntry."Cost Amount" := 6; ValueEntry.Insert();
        ValueEntry.Init(); ValueEntry."Entry No." := 3; ValueEntry."Ledger Entry No." := 2; ValueEntry."Cost Amount" := 7; ValueEntry.Insert();

        Assignment.Init(); Assignment."Entry No." := 1; Assignment."Project No." := 'P1'; Assignment."Ledger Entry No." := 1; Assignment.Quantity := 2; Assignment.Insert();
        Assignment.Init(); Assignment."Entry No." := 2; Assignment."Project No." := 'P1'; Assignment."Ledger Entry No." := 1; Assignment.Quantity := 3; Assignment.Insert();
        Assignment.Init(); Assignment."Entry No." := 3; Assignment."Project No." := 'P1'; Assignment."Ledger Entry No." := 2; Assignment.Quantity := 5; Assignment.Insert();

        Query.Open();
        while Query.Read() do begin
            RowCount += 1;
            case Query.ItemNo of
                'A':
                    begin
                        SawItemA := true;
                        Assert.AreEqual(5, Query.AssignedQuantity, 'Item A group must sum both its assignments (2+3)');
                        Assert.AreEqual(10, Query.CostAmount, 'Item A group''s FlowField must sum both its value entries (4+6)');
                    end;
                'B':
                    begin
                        SawItemB := true;
                        Assert.AreEqual(5, Query.AssignedQuantity, 'Item B group must equal its single assignment');
                        Assert.AreEqual(7, Query.CostAmount, 'Item B group''s FlowField must equal its single value entry');
                    end;
                else
                    Error('Unexpected ItemNo %1 - grouping over the join produced an extra or wrong group', Query.ItemNo);
            end;
        end;
        Query.Close();

        Assert.IsTrue(SawItemA, 'Item A group must be present');
        Assert.IsTrue(SawItemB, 'Item B group must be present');
        Assert.AreEqual(2, RowCount, 'The join must group to one row per (project, ledger entry), not one row per assignment');
    end;

    // Negative sibling: with no assignments/ledgers/value entries at all, the grouped join
    // must return zero rows — proving the group-by-FlowField path doesn't fabricate a row.
    [Test]
    procedure JoinWithSumAndFlowFieldColumn_NoRows_ReturnsEmpty()
    var
        Query: Query "QJF Valuation";
    begin
        Initialize();

        Query.Open();
        Assert.IsFalse(Query.Read(), 'No assignment/ledger rows exist, so the grouped join must return no rows');
        Query.Close();
    end;
}
