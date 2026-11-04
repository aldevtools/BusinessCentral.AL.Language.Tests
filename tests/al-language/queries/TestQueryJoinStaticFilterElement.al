// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-columnfilter-property
//   dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: QDB Row (69980), QDB Entry (69981), QDB Static Filter Join (69982); shared Assert (60021)
//
// A static ColumnFilter on a filter() element of an aggregated join is a WHERE condition: it keeps
// the joined rows inside the range, and the groups are then built from those rows only. It does not
// drop a group because one of the group's rows is outside the range, and it does not make the
// filter element a group key. Header A has three entries (1, 2, 3) of which two are in the range
// 2..3; header B has one entry (4), outside it.
codeunit 69982 "QDB Static Filter Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure InsertHeader(HeaderCode: Code[20])
    var
        Row: Record "QDB Row";
    begin
        Row.Init();
        Row.Code := HeaderCode;
        Row.Insert();
    end;

    local procedure InsertEntry(EntryNo: Integer; HeaderCode: Code[20]; Qty: Decimal)
    var
        Entry: Record "QDB Entry";
    begin
        Entry.Init();
        Entry."Entry No." := EntryNo;
        Entry.Positive := false;
        Entry."Item No." := HeaderCode;
        Entry.Quantity := Qty;
        Entry.Insert();
    end;

    local procedure Seed()
    var
        Row: Record "QDB Row";
        Entry: Record "QDB Entry";
    begin
        Row.DeleteAll();
        Entry.DeleteAll();
        InsertHeader('A');
        InsertHeader('B');
        // The entry outside the range comes first by key, so a filter evaluated against a group's
        // first row would drop group A instead of narrowing it.
        InsertEntry(1, 'A', 1000);
        InsertEntry(2, 'A', 100);
        InsertEntry(3, 'A', 50);
        InsertEntry(4, 'B', 9);
    end;

    [Test]
    procedure StaticColumnFilterOnAFilterElement_NarrowsEachGroupToItsRowsInRange()
    var
        Q: Query "QDB Static Filter Join";
        Rows: Text;
    begin
        Seed();

        Q.Open();
        while Q.Read() do
            Rows += StrSubstNo('%1:%2:%3;', Q.RowCode, Format(Q.TotalQuantity, 0, 9), Q.EntryCount);
        Q.Close();

        Assert.AreEqual('A:150:2;', Rows, 'Group A sums only its entries 2 and 3; group B has none in range and is absent');
    end;
}
