// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/query/query-data-type
//   dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: IQ Item Rows (60982) — a source-defined query over Base Application's Item
// table (a dependency, not an application-local table).
//
// A source-defined Query whose only dataitem's table comes from a DEPENDENCY application
// (here, Base Application's Item) must support SetRange, Open and Read exactly like a Query
// over an application-local table.
codeunit 60990 "Test Query Dependency Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure QueryOverDependencyTable_Open_Read_ReturnsInsertedRow()
    var
        Item: Record Item;
        ItemRows: Query "IQ Item Rows";
    begin
        // [GIVEN] An Item exists with a known "No.".
        Item."No." := 'ALT-QDT-001';
        Item.Insert(true);

        // [WHEN] The query over the dependency table is opened.
        ItemRows.SetRange(No, Item."No.");
        ItemRows.Open();

        // [THEN] It returns exactly the inserted row.
        Assert.IsTrue(ItemRows.Read(), 'Query over a dependency table must return the matching row');
        Assert.AreEqual(Item."No.", ItemRows.No, 'Query column must read the item''s No.');
        Assert.IsFalse(ItemRows.Read(), 'Query must only return the one matching row');
        ItemRows.Close();
    end;

    [Test]
    procedure QueryOverDependencyTable_SetRange_ExcludingValue_ReturnsNoRows()
    var
        Item: Record Item;
        ItemRows: Query "IQ Item Rows";
    begin
        // [GIVEN] An Item exists with a known "No.".
        Item."No." := 'ALT-QDT-002';
        Item.Insert(true);

        // [WHEN] The query is filtered to a value that does not match any Item.
        ItemRows.SetRange(No, 'ALT-QDT-NO-SUCH-ITEM');
        ItemRows.Open();

        // [THEN] It returns no rows.
        Assert.IsFalse(ItemRows.Read(), 'Query over a dependency table must exclude non-matching rows');
        ItemRows.Close();
    end;
}
