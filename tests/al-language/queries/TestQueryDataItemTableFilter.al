// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-dataitemtablefilter-property
//   dev-itpro/developer/methods-auto/query/query-data-type
// Scope: in-scope
// Fixtures used: QDTF Row (60497), QDTF Open Rows (60500), QDTF Two Field Filter (60501),
//   QDTF Status Filtered (60507), QDTF Self Join Status (60508); shared Assert (60021)
//   Writer SQ: Probe Observer (69160) and SqQdtfEmptyFilter.al (table 89589, queries 89590-89594)
//   Writer VQ (al-runner 6924): Probe Observer (69160) and VqQueryEnumFilter.al (enum 97120, tables 97121 97144, queries 97122-97133)
//
// A query dataitem's DataItemTableFilter property is a STATIC filter on the dataitem's own
// TABLE rows, applied before anything is projected. It differs from a column's ColumnFilter
// property in what it is keyed by: ColumnFilter names a QUERY COLUMN of the same query, so the
// filtered field must be projected; DataItemTableFilter names a TABLE FIELD of the dataitem's
// source table and needs no column at all. Both fixture queries here exploit that — neither
// projects the Status field they filter on.
//
// What each test pins:
//   - a single const(...) condition selects only matching rows, and the query's own columns
//     still project normally;
//   - two conditions on DIFFERENT fields both apply (an implicit AND), including the
//     filter(...) form with a comparison operator;
//   - a runtime SetRange on a projected column COMBINES with the static table filter rather
//     than replacing it — the opposite of ColumnFilter, where a runtime filter on the same
//     column replaces the static one (TestQueryColumnFilter.al pins that);
//   - a runtime SetRange on a column over the VERY FIELD the static table filter names combines
//     with it too, in both directions: agreeing conditions admit the rows, contradictory ones
//     admit none. The older runtime-filter tests above filter on a different field (RowCode),
//     so neither of them pins what happens when the two name one field;
//   - two dataitems of a self-join each filtering that one field keep their filters apart, so a
//     contradictory pair returns nothing rather than one condition standing for both.//
// Writer VQ: a qualified enum value "Enum"::Member in DataItemTableFilter compiles (filter, const, OR of two members, quoted member name, table
// field named like its enum) and selects the rows of that member. In ColumnFilter the same form does not compile (AL0118): must-not-compile
// cases 2980 to 2984. A plain member name (filter(Beta), const(Beta)) works in ColumnFilter.
codeunit 60503 "QDTF Table Filter Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "QDTF Row";
    begin
        Row.DeleteAll();
    end;

    local procedure InsertRow(RowCode: Code[20]; Status: Option Open,Closed,Held; Amount: Decimal)
    var
        Row: Record "QDTF Row";
    begin
        Row.Init();
        Row.Code := RowCode;
        Row.Status := Status;
        Row.Amount := Amount;
        Row.Insert();
    end;

    local procedure SeedThreeStatuses()
    var
        Row: Record "QDTF Row";
    begin
        Initialize();
        // Deliberately inserted so that the row a dropped filter would return FIRST (by primary
        // key) is a CLOSED one: a query that ignored the filter answers 'A-CLOSED' first, not
        // the expected 'B-OPEN'.
        InsertRow('A-CLOSED', Row.Status::Closed, 500);
        InsertRow('B-OPEN', Row.Status::Open, 150);
        InsertRow('C-HELD', Row.Status::Held, 500);
        InsertRow('D-OPEN', Row.Status::Open, 50);
    end;

    [Test]
    procedure DataItemTableFilterConstSelectsOnlyMatchingRows()
    var
        Q: Query "QDTF Open Rows";
        Seen: Integer;
        First: Code[20];
        Last: Code[20];
    begin
        // [SCENARIO] A dataitem whose DataItemTableFilter is `Status = const(Open)` returns only
        // the Open rows, on a field the query does not project.
        SeedThreeStatuses();

        Q.Open();
        while Q.Read() do begin
            Seen += 1;
            if Seen = 1 then
                First := Q.RowCode;
            Last := Q.RowCode;
        end;
        Q.Close();

        Assert.AreEqual(2, Seen, 'rows returned when the dataitem filters Status = const(Open)');
        Assert.AreEqual('B-OPEN', First, 'first row (OrderBy ascending RowCode)');
        Assert.AreEqual('D-OPEN', Last, 'last row');
    end;

    [Test]
    procedure DataItemTableFilterDoesNotSuppressOtherColumns()
    var
        Q: Query "QDTF Open Rows";
        Total: Decimal;
    begin
        // [SCENARIO] Filtering on an unprojected field leaves the projected columns intact —
        // the filter selects rows, it does not blank or drop columns.
        SeedThreeStatuses();

        Q.Open();
        while Q.Read() do
            Total += Q.RowAmount;
        Q.Close();

        // 150 + 50 from the two Open rows; the Closed and Held rows contribute 500 each and
        // must not be counted.
        Assert.AreEqual(200.0, Total, 'summed Amount over the rows the static filter admits');
    end;

    [Test]
    procedure DataItemTableFilterCombinesTwoConditionsOnDifferentFields()
    var
        Q: Query "QDTF Two Field Filter";
        Seen: Integer;
        Only: Code[20];
    begin
        // [SCENARIO] `Status = const(Open), Amount = filter(> 100)` applies BOTH conditions.
        // Of the two Open rows only B-OPEN (150) clears the Amount filter; D-OPEN (50) does not.
        // Honouring only the first condition returns 2 rows, only the second returns 3.
        SeedThreeStatuses();

        Q.Open();
        while Q.Read() do begin
            Seen += 1;
            Only := Q.RowCode;
        end;
        Q.Close();

        Assert.AreEqual(1, Seen, 'rows satisfying BOTH Status = const(Open) and Amount = filter(> 100)');
        Assert.AreEqual('B-OPEN', Only, 'the one row satisfying both conditions');
    end;

    [Test]
    procedure DataItemTableFilterStillExcludesARowARuntimeFilterSelects()
    var
        Q: Query "QDTF Open Rows";
        Seen: Integer;
    begin
        // [SCENARIO] A runtime SetRange on a projected column NARROWS the static table filter
        // rather than replacing it. 'A-CLOSED' satisfies the runtime filter and not the static
        // one, so a query that let the runtime filter replace the static one would return it.
        SeedThreeStatuses();

        Q.SetRange(RowCode, 'A-CLOSED');
        Q.Open();
        while Q.Read() do
            Seen += 1;
        Q.Close();

        Assert.AreEqual(0, Seen, 'rows returned for a runtime filter selecting a row the static table filter excludes');
    end;

    [Test]
    procedure DataItemTableFilterAdmitsARowBothFiltersSelect()
    var
        Q: Query "QDTF Open Rows";
        Seen: Integer;
        Only: Code[20];
    begin
        // [SCENARIO] The positive companion to the previous test, so the pair cannot both be
        // satisfied by a query that simply returns nothing: a row satisfying BOTH the runtime
        // filter and the static table filter is returned.
        SeedThreeStatuses();

        Q.SetRange(RowCode, 'B-OPEN');
        Q.Open();
        while Q.Read() do begin
            Seen += 1;
            Only := Q.RowCode;
        end;
        Q.Close();

        Assert.AreEqual(1, Seen, 'rows satisfying both the runtime filter and the static table filter');
        Assert.AreEqual('B-OPEN', Only, 'the surviving row');
    end;

    [Test]
    procedure DataItemTableFilterReturnsNoRowsWhenNothingMatches()
    var
        Row: Record "QDTF Row";
        Q: Query "QDTF Open Rows";
        Seen: Integer;
    begin
        // [SCENARIO] Negative direction: with no Open row at all the query is empty — the
        // filter genuinely excludes, rather than falling back to returning everything.
        Initialize();
        InsertRow('A-CLOSED', Row.Status::Closed, 500);
        InsertRow('C-HELD', Row.Status::Held, 500);

        Q.Open();
        while Q.Read() do
            Seen += 1;
        Q.Close();

        Assert.AreEqual(0, Seen, 'rows returned when no row satisfies the static table filter');
    end;

    [Test]
    procedure RuntimeFilterAgreeingWithTheTableFilterOnOneFieldAdmitsTheRows()
    var
        Row: Record "QDTF Row";
        Q: Query "QDTF Status Filtered";
        Seen: Integer;
        First: Code[20];
        Last: Code[20];
    begin
        // [SCENARIO] The static table filter says Status = Open and a runtime SetRange on
        // RowStatus — a column over that same field — says Open as well. Both Open rows come
        // back: naming one field twice is not an error and does not narrow to nothing.
        SeedThreeStatuses();

        Q.SetRange(RowStatus, Row.Status::Open);
        Q.Open();
        while Q.Read() do begin
            Seen += 1;
            if Seen = 1 then
                First := Q.RowCode;
            Last := Q.RowCode;
        end;
        Q.Close();

        Assert.AreEqual(2, Seen, 'rows when the static table filter and a runtime filter on the same field agree');
        Assert.AreEqual('B-OPEN', First, 'first row (OrderBy ascending RowCode)');
        Assert.AreEqual('D-OPEN', Last, 'last row');
    end;

    [Test]
    procedure RuntimeFilterContradictingTheTableFilterOnOneFieldAdmitsNothing()
    var
        Row: Record "QDTF Row";
        Q: Query "QDTF Status Filtered";
        Seen: Integer;
    begin
        // [SCENARIO] The discriminating direction of the test above. Static says Status = Open,
        // runtime says Status = Closed, and no row is both — so the answer is zero rows.
        // A query letting the runtime filter REPLACE the static one answers 1 ('A-CLOSED');
        // one letting the static filter win answers 2.
        SeedThreeStatuses();

        Q.SetRange(RowStatus, Row.Status::Closed);
        Q.Open();
        while Q.Read() do
            Seen += 1;
        Q.Close();

        Assert.AreEqual(0, Seen, 'rows when the static table filter and a runtime filter on the same field contradict');
    end;

    [Test]
    procedure SelfJoinFilteringOneFieldFromBothDataItemsAdmitsTheRows()
    var
        Row: Record "QDTF Row";
        Q: Query "QDTF Self Join Status";
        Seen: Integer;
    begin
        // [SCENARIO] Two dataitems over one table, linked on the primary key, each with its own
        // filter column over Status. With both set to Open the join returns the two Open rows.
        SeedThreeStatuses();

        Q.SetRange(OuterStatus, Row.Status::Open);
        Q.SetRange(InnerStatus, Row.Status::Open);
        Q.Open();
        while Q.Read() do
            Seen += 1;
        Q.Close();

        Assert.AreEqual(2, Seen, 'joined rows when both dataitems filter Status = Open');
    end;

    [Test]
    procedure SelfJoinFilteringOneFieldContradictorilyAdmitsNothing()
    var
        Row: Record "QDTF Row";
        Q: Query "QDTF Self Join Status";
        Seen: Integer;
    begin
        // [SCENARIO] The negative companion. The link is the primary key, so the two dataitems
        // are always the same row, and no row is Open and Closed at once. Anything other than
        // zero means one dataitem's filter was dropped or the two were folded into one.
        SeedThreeStatuses();

        Q.SetRange(OuterStatus, Row.Status::Open);
        Q.SetRange(InnerStatus, Row.Status::Closed);
        Q.Open();
        while Q.Read() do
            Seen += 1;
        Q.Close();

        Assert.AreEqual(0, Seen, 'joined rows when the two dataitems filter Status contradictorily');
    end;

    // Writer SQ (NP lane 2026-10-28): DataItemTableFilter and ColumnFilter with an empty filter term filter('') (SqQdtfEmptyFilter.al).
    local procedure SqSeed()
    var
        Row: Record "LT SQ Qf Row";
    begin
        Row.DeleteAll();
        SqInsert(1, '', '');
        SqInsert(2, 'A', 'a');
        SqInsert(3, 'B', '');
        SqInsert(4, '', 'b');
    end;

    local procedure SqInsert(Id: Integer; RowCode: Code[10]; Txt: Text[30])
    var
        Row: Record "LT SQ Qf Row";
    begin
        Row.Init();
        Row.Id := Id;
        Row.Code := RowCode;
        Row.Txt := Txt;
        Row.Insert();
    end;

    [TryFunction]
    local procedure SqTryRead(QueryId: Integer; var Ids: Text)
    var
        QCodeFilter: Query "LT SQ Qf Code Filter Empty";
        QTxtFilter: Query "LT SQ Qf Txt Filter Empty";
        QCodeConst: Query "LT SQ Qf Code Const Empty";
        QCodeOr: Query "LT SQ Qf Code Filter Or";
        QColumn: Query "LT SQ Qf Column Filter Empty";
    begin
        case QueryId of
            Query::"LT SQ Qf Code Filter Empty":
                begin
                    QCodeFilter.Open();
                    while QCodeFilter.Read() do
                        Ids += Format(QCodeFilter.RowId) + ',';
                end;
            Query::"LT SQ Qf Txt Filter Empty":
                begin
                    QTxtFilter.Open();
                    while QTxtFilter.Read() do
                        Ids += Format(QTxtFilter.RowId) + ',';
                end;
            Query::"LT SQ Qf Code Const Empty":
                begin
                    QCodeConst.Open();
                    while QCodeConst.Read() do
                        Ids += Format(QCodeConst.RowId) + ',';
                end;
            Query::"LT SQ Qf Code Filter Or":
                begin
                    QCodeOr.Open();
                    while QCodeOr.Read() do
                        Ids += Format(QCodeOr.RowId) + ',';
                end;
            Query::"LT SQ Qf Column Filter Empty":
                begin
                    QColumn.Open();
                    while QColumn.Read() do
                        Ids += Format(QColumn.RowId) + ',';
                end;
        end;
    end;

    local procedure SqRead(QueryId: Integer): Text
    var
        Ids: Text;
    begin
        ClearLastError();
        if SqTryRead(QueryId, Ids) then
            exit('ok:' + Ids);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Sq_EmptyFilterTerm_Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SqSeed();
        Observer.Observe('code filter empty', SqRead(Query::"LT SQ Qf Code Filter Empty"));
        Observer.Observe('txt filter empty', SqRead(Query::"LT SQ Qf Txt Filter Empty"));
        Observer.Observe('code const empty', SqRead(Query::"LT SQ Qf Code Const Empty"));
        Observer.Observe('code filter empty or A', SqRead(Query::"LT SQ Qf Code Filter Or"));
        Observer.Observe('column filter empty', SqRead(Query::"LT SQ Qf Column Filter Empty"));
        Observer.Expect('code filter empty', 'ok:1,4,');
        Observer.Expect('txt filter empty', 'ok:1,3,');
        Observer.Expect('code const empty', 'ok:1,4,');
        Observer.Expect('code filter empty or A', 'ok:1,2,4,');
        Observer.Expect('column filter empty', 'ok:1,4,');
        Observer.Verify();
    end;

    // Writer VQ (al-runner 6924): a qualified enum value in DataItemTableFilter and ColumnFilter (VqQueryEnumFilter.al).
    local procedure VqSeed()
    var
        Row: Record "LT VQ Q Row";
        SameRow: Record "LT VQ Q Same";
        Idx: Integer;
    begin
        Row.DeleteAll();
        SameRow.DeleteAll();
        // Kind: Alpha, Beta, Gamma Delta, Beta. In the other table the same-named field holds Beta, Alpha, Gamma Delta, Beta,
        // so a filter on the wrong field of that table shows.
        for Idx := 1 to 4 do begin
            Row.Init();
            Row.Id := Idx;
            SameRow.Init();
            SameRow.Id := Idx;
            case Idx of
                1:
                    begin
                        Row.Kind := Row.Kind::Alpha;
                        SameRow.Kind := SameRow.Kind::Alpha;
                        SameRow."LT VQ Q Kind" := SameRow."LT VQ Q Kind"::Beta;
                    end;
                2:
                    begin
                        Row.Kind := Row.Kind::Beta;
                        SameRow.Kind := SameRow.Kind::Beta;
                        SameRow."LT VQ Q Kind" := SameRow."LT VQ Q Kind"::Alpha;
                    end;
                3:
                    begin
                        Row.Kind := Row.Kind::"Gamma Delta";
                        SameRow.Kind := SameRow.Kind::"Gamma Delta";
                        SameRow."LT VQ Q Kind" := SameRow."LT VQ Q Kind"::"Gamma Delta";
                    end;
                4:
                    begin
                        Row.Kind := Row.Kind::Beta;
                        SameRow.Kind := SameRow.Kind::Beta;
                        SameRow."LT VQ Q Kind" := SameRow."LT VQ Q Kind"::Beta;
                    end;
            end;
            Row.Insert();
            SameRow.Insert();
        end;
    end;

    [TryFunction]
    local procedure VqTryRead(QueryId: Integer; var Ids: Text)
    var
        QDitFilter: Query "LT VQ Q Dit Filter";
        QDitConst: Query "LT VQ Q Dit Const";
        QDitOr: Query "LT VQ Q Dit Or";
        QDitQuoted: Query "LT VQ Q Dit Quoted";
        QDitSame: Query "LT VQ Q Dit Same";
        QDitSameConst: Query "LT VQ Q Dit SameConst";
        QColPlain: Query "LT VQ Q Col Plain";
        QColPlainConst: Query "LT VQ Q Col PlainConst";
        QDitPlain: Query "LT VQ Q Dit Plain";
    begin
        case QueryId of
            Query::"LT VQ Q Dit Filter":
                begin
                    QDitFilter.Open();
                    while QDitFilter.Read() do
                        Ids += Format(QDitFilter.RowId) + ',';
                end;
            Query::"LT VQ Q Dit Const":
                begin
                    QDitConst.Open();
                    while QDitConst.Read() do
                        Ids += Format(QDitConst.RowId) + ',';
                end;
            Query::"LT VQ Q Dit Or":
                begin
                    QDitOr.Open();
                    while QDitOr.Read() do
                        Ids += Format(QDitOr.RowId) + ',';
                end;
            Query::"LT VQ Q Dit Quoted":
                begin
                    QDitQuoted.Open();
                    while QDitQuoted.Read() do
                        Ids += Format(QDitQuoted.RowId) + ',';
                end;
            Query::"LT VQ Q Dit Same":
                begin
                    QDitSame.Open();
                    while QDitSame.Read() do
                        Ids += Format(QDitSame.RowId) + ',';
                end;
            Query::"LT VQ Q Dit SameConst":
                begin
                    QDitSameConst.Open();
                    while QDitSameConst.Read() do
                        Ids += Format(QDitSameConst.RowId) + ',';
                end;
            Query::"LT VQ Q Col Plain":
                begin
                    QColPlain.Open();
                    while QColPlain.Read() do
                        Ids += Format(QColPlain.RowId) + ',';
                end;
            Query::"LT VQ Q Col PlainConst":
                begin
                    QColPlainConst.Open();
                    while QColPlainConst.Read() do
                        Ids += Format(QColPlainConst.RowId) + ',';
                end;
            Query::"LT VQ Q Dit Plain":
                begin
                    QDitPlain.Open();
                    while QDitPlain.Read() do
                        Ids += Format(QDitPlain.RowId) + ',';
                end;
        end;
    end;

    local procedure VqRead(QueryId: Integer): Text
    var
        Ids: Text;
    begin
        ClearLastError();
        if VqTryRead(QueryId, Ids) then
            exit('ok:' + Ids);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Vq_QualifiedEnumValue_DataItemTableFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        VqSeed();
        Observer.Observe('dit filter', VqRead(Query::"LT VQ Q Dit Filter"));
        Observer.Observe('dit const', VqRead(Query::"LT VQ Q Dit Const"));
        Observer.Observe('dit or', VqRead(Query::"LT VQ Q Dit Or"));
        Observer.Observe('dit quoted', VqRead(Query::"LT VQ Q Dit Quoted"));
        Observer.Expect('dit filter', 'ok:2,4,');
        Observer.Expect('dit const', 'ok:2,4,');
        Observer.Expect('dit or', 'ok:1,2,4,');
        Observer.Expect('dit quoted', 'ok:3,');
        Observer.Verify();
    end;

    [Test]
    procedure Vq_PlainEnumMember_ColumnFilterAndDataItemFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        VqSeed();
        Observer.Observe('col plain', VqRead(Query::"LT VQ Q Col Plain"));
        Observer.Observe('col plainconst', VqRead(Query::"LT VQ Q Col PlainConst"));
        Observer.Observe('dit plain', VqRead(Query::"LT VQ Q Dit Plain"));
        Observer.Expect('col plain', 'ok:2,4,');
        Observer.Expect('col plainconst', 'ok:2,4,');
        Observer.Expect('dit plain', 'ok:2,4,');
        Observer.Verify();
    end;

    [Test]
    procedure Vq_QualifiedEnumValue_FieldNamedLikeTheEnum()
    var
        Observer: Codeunit "Probe Observer";
    begin
        VqSeed();
        Observer.Observe('dit same', VqRead(Query::"LT VQ Q Dit Same"));
        Observer.Observe('dit sameconst', VqRead(Query::"LT VQ Q Dit SameConst"));
        Observer.Expect('dit same', 'ok:1,4,');
        Observer.Expect('dit sameconst', 'ok:1,4,');
        Observer.Verify();
    end;
}
