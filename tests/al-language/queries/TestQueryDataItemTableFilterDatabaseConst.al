// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-dataitemtablefilter-property
//   dev-itpro/developer/methods-auto/query/query-data-type
// Scope: in-scope
// Fixtures used: QDB Row (69980), QDB Kind Filtered (69980), QDB Entry (69981), QDB Scalar Join
//   (69981); shared Assert (60021). Base Application query "Qty. Reserved From Item Ledger" (522),
//   a query in a dependency.
//
// A query dataitem's DataItemTableFilter may name an OBJECT through Database::, e.g.
//   "Source Type" = const(Database::"Item Ledger Entry")
// The compiler replaces it with the object id, so the filter is an ordinary integer comparison by
// the time a service tier reads the query. It is carried by:
//   - a query compiled from source in this app (QDB Kind Filtered, QDB Scalar Join), and
//   - a query shipped PRECOMPILED in a dependency: Base Application's query 522 filters its second
//     dataitem with Database::"Item Ledger Entry" among two further const conditions.
// Query 522 and QDB Scalar Join share a second shape: one Sum column and a filter() element over a
// dataitem joined to a second dataitem of the same table, so a query that selects no row is a
// SCALAR aggregate and still returns its one defaulted row.
//
// What each test pins:
//   - the precompiled query accepts its own filter procedure (SetSourceFilter);
//   - it applies all three conditions of its table filter: a row passes only if its Source Type is
//     the Item Ledger Entry table id AND its Reservation Status is Reservation AND it is the
//     positive side of the pair, and each other row is excluded by exactly one of them;
//   - a filter on its filter() element that selects no joined row still reads one row, with the
//     Sum defaulted to 0, rather than raising;
//   - the source-compiled queries select exactly the rows whose Source Type / Kind equals their
//     Database:: const, and sum only those.
codeunit 69980 "QDB Table Filter Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure InsertReservationPair(EntryNo: Integer; ItemNo: Code[20]; QtyBase: Decimal; FromSourceType: Integer; FromStatus: Enum "Reservation Status")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        // The demand side: Positive = false, the row Query 522's root dataitem selects.
        ReservationEntry.Init();
        ReservationEntry."Entry No." := EntryNo;
        ReservationEntry.Positive := false;
        ReservationEntry."Item No." := ItemNo;
        ReservationEntry."Quantity (Base)" := -QtyBase;
        ReservationEntry."Source Type" := Database::"Sales Line";
        ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Reservation;
        ReservationEntry.Insert(false);

        // The supply side, linked by the same Entry No.: the row the table filter qualifies.
        ReservationEntry.Init();
        ReservationEntry."Entry No." := EntryNo;
        ReservationEntry.Positive := true;
        ReservationEntry."Item No." := ItemNo;
        ReservationEntry."Quantity (Base)" := QtyBase;
        ReservationEntry."Source Type" := FromSourceType;
        ReservationEntry."Reservation Status" := FromStatus;
        ReservationEntry.Insert(false);
    end;

    local procedure NextReservationEntryNo(): Integer
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        if ReservationEntry.FindLast() then
            exit(ReservationEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure ResetQdbEntries()
    var
        Entry: Record "QDB Entry";
    begin
        Entry.DeleteAll();
    end;

    local procedure InsertQdbPair(EntryNo: Integer; ItemNo: Code[20]; Qty: Decimal; SupplySourceType: Integer)
    var
        Entry: Record "QDB Entry";
    begin
        Entry.Init();
        Entry."Entry No." := EntryNo;
        Entry.Positive := false;
        Entry."Item No." := ItemNo;
        Entry.Quantity := Qty;
        Entry.Insert();

        Entry.Positive := true;
        Entry."Source Type" := SupplySourceType;
        Entry.Insert();
    end;

    [Test]
    procedure PrecompiledQuery_SetSourceFilter_NoThrow()
    var
        ReservationEntry: Record "Reservation Entry";
        QtyReserved: Query "Qty. Reserved From Item Ledger";
    begin
        // [GIVEN] A Reservation Entry whose source fields the query is asked to filter on.
        ReservationEntry."Source Type" := Database::"Sales Line";
        ReservationEntry."Source ID" := 'ALT-QDB-NOSUCH';

        // [WHEN] [THEN] The query's own filter procedure runs without raising. The claim is only
        // that it does not raise.
        QtyReserved.SetSourceFilter(ReservationEntry);
    end;

    [Test]
    procedure PrecompiledQuery_AppliesEveryConditionOfItsTableFilter()
    var
        QtyReserved: Query "Qty. Reserved From Item Ledger";
        ItemNo: Code[20];
        EntryNo: Integer;
    begin
        // [GIVEN] Three demand/supply pairs for one item; only the first supply row satisfies the
        // query's table filter (Positive, Source Type = Item Ledger Entry, Status = Reservation).
        ItemNo := 'ALT-QDB-001';
        EntryNo := NextReservationEntryNo();
        InsertReservationPair(EntryNo, ItemNo, 5, Database::"Item Ledger Entry", Enum::"Reservation Status"::Reservation);
        // Supply side from another source table: excluded by the Database:: const alone.
        InsertReservationPair(EntryNo + 1, ItemNo, 3, Database::"Item Journal Line", Enum::"Reservation Status"::Reservation);
        // Supply side from the right table but not a reservation: excluded by the status const alone.
        InsertReservationPair(EntryNo + 2, ItemNo, 7, Database::"Item Ledger Entry", Enum::"Reservation Status"::Surplus);

        // [WHEN] The query is read for that item.
        QtyReserved.SetRange(Item_No_, ItemNo);
        QtyReserved.Open();

        // [THEN] One summed row, and it holds the quantity of the qualifying pair only.
        Assert.IsTrue(QtyReserved.Read(), 'The qualifying pair must produce a row');
        Assert.AreEqual(5, QtyReserved.Quantity__Base_, 'Only the Item Ledger Entry supply in status Reservation counts: 5, not 5+3+7');
        Assert.IsFalse(QtyReserved.Read(), 'The query sums into one row');
        QtyReserved.Close();
    end;

    [Test]
    procedure PrecompiledQuery_NoQualifyingRow_ReadsOneRowSummingZero()
    var
        QtyReserved: Query "Qty. Reserved From Item Ledger";
        ItemNo: Code[20];
    begin
        // [GIVEN] A pair whose supply side is NOT an Item Ledger Entry.
        ItemNo := 'ALT-QDB-002';
        InsertReservationPair(NextReservationEntryNo(), ItemNo, 4, Database::"Item Journal Line", Enum::"Reservation Status"::Reservation);

        // [WHEN] The query is read for that item.
        QtyReserved.SetRange(Item_No_, ItemNo);
        QtyReserved.Open();

        // [THEN] No supply row satisfies Database::"Item Ledger Entry", and the query, which has
        // only an aggregated column, still returns its one row with the Sum defaulted to 0.
        Assert.IsTrue(QtyReserved.Read(), 'A scalar aggregate returns one row even when no joined row qualifies');
        Assert.AreEqual(0, QtyReserved.Quantity__Base_, 'The Sum over no qualifying row defaults to 0');
        Assert.IsFalse(QtyReserved.Read(), 'The scalar aggregate returns exactly one row');
        QtyReserved.Close();
    end;

    [Test]
    procedure SourceCompiledQuery_DatabaseConstSelectsRowsOfItsOwnTableId()
    var
        Row: Record "QDB Row";
        KindFiltered: Query "QDB Kind Filtered";
    begin
        // [GIVEN] Rows whose Kind is this table's own id, and others.
        Row.DeleteAll();
        Row.Init();
        Row.Code := 'A-OTHER';
        Row.Kind := 1;
        Row.Insert();
        Row.Code := 'B-OWN';
        Row.Kind := Database::"QDB Row";
        Row.Insert();
        Row.Code := 'C-OWN';
        Row.Kind := 69980;
        Row.Insert();
        Row.Code := 'D-ZERO';
        Row.Kind := 0;
        Row.Insert();

        // [WHEN] The query with DataItemTableFilter = Kind = const(Database::"QDB Row") is read.
        KindFiltered.Open();

        // [THEN] Exactly the rows of Kind 69980 come back, in key order.
        Assert.IsTrue(KindFiltered.Read(), 'First own-kind row');
        Assert.AreEqual('B-OWN', KindFiltered.RowCode, 'First row is B-OWN');
        Assert.IsTrue(KindFiltered.Read(), 'Second own-kind row');
        Assert.AreEqual('C-OWN', KindFiltered.RowCode, 'Second row is C-OWN');
        Assert.IsFalse(KindFiltered.Read(), 'The rows of other kinds are excluded');
        KindFiltered.Close();
    end;

    [Test]
    procedure SourceCompiledScalarJoin_FilterSumsOnlyQualifyingPairs()
    var
        ScalarJoin: Query "QDB Scalar Join";
    begin
        // [GIVEN] Two pairs for item 'I-1': one whose supply side has the Database:: source type, one
        // that has not; and a pair for another item.
        ResetQdbEntries();
        InsertQdbPair(1, 'I-1', 10, Database::"QDB Row");
        InsertQdbPair(2, 'I-1', 20, 1);
        InsertQdbPair(3, 'I-2', 40, Database::"QDB Row");

        // [WHEN] The query is read for item 'I-1'.
        ScalarJoin.SetRange(ItemNo, 'I-1');
        ScalarJoin.Open();

        // [THEN] The Sum counts the qualifying pair of that item only.
        Assert.IsTrue(ScalarJoin.Read(), 'The scalar aggregate returns one row');
        Assert.AreEqual(10, ScalarJoin.TotalQuantity, 'Only the I-1 pair whose supply side has the Database:: source type counts');
        Assert.IsFalse(ScalarJoin.Read(), 'The scalar aggregate returns exactly one row');
        ScalarJoin.Close();
    end;

    [Test]
    procedure SourceCompiledScalarJoin_FilterSelectingNoRow_ReadsOneRowSummingZero()
    var
        ScalarJoin: Query "QDB Scalar Join";
    begin
        // [GIVEN] A qualifying pair for item 'I-1' only.
        ResetQdbEntries();
        InsertQdbPair(1, 'I-1', 10, Database::"QDB Row");

        // [WHEN] The query is filtered to an item no row carries.
        ScalarJoin.SetRange(ItemNo, 'I-NONE');
        ScalarJoin.Open();

        // [THEN] The one defaulted row of a scalar aggregate is still returned.
        Assert.IsTrue(ScalarJoin.Read(), 'A scalar aggregate returns one row even when the filter selects no joined row');
        Assert.AreEqual(0, ScalarJoin.TotalQuantity, 'The Sum over no row defaults to 0');
        Assert.IsFalse(ScalarJoin.Read(), 'The scalar aggregate returns exactly one row');
        ScalarJoin.Close();
    end;
}
