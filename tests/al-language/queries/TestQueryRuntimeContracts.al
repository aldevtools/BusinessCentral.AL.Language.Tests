// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALTFixtureCleanup (60019), shared Assert (60021);
//                self-contained queries 68110..68115
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins query behaviour that the other query tests leave open: how Text columns sort and
// group (the database collation, not an ordinal comparison), the exact text of GetFilters,
// that ColumnNo is not a 1-based position, that Close keeps filters, the tie-break by the
// primary key of every dataitem, how Average rounds, scalar aggregates over no rows, and
// the state errors of Read, column access and SecurityFiltering.
// BC versions: 27.5

query 68110 "Probe Q Text"
{
    QueryType = Normal;
    OrderBy = ascending(Txt);

    elements
    {
        dataitem(U; "ALT Universal")
        {
            column(Entry; "Entry No.") { }
            column(Txt; "Text Field") { }
            filter(IntF; "Integer Field") { }
        }
    }
}

query 68111 "Probe Q Text Group"
{
    QueryType = Normal;
    OrderBy = ascending(Txt);

    elements
    {
        dataitem(U; "ALT Universal")
        {
            column(Txt; "Text Field") { }
            column(Cnt) { Method = Count; }
        }
    }
}

query 68112 "Probe Q Ties"
{
    QueryType = Normal;
    OrderBy = ascending(IntV);

    elements
    {
        dataitem(U; "ALT Universal")
        {
            column(IntV; "Integer Field") { }
            column(Entry; "Entry No.") { }
        }
    }
}

query 68113 "Probe Q Ties Join"
{
    QueryType = Normal;
    OrderBy = ascending(IntV);

    elements
    {
        dataitem(Outer; "ALT Universal")
        {
            column(IntV; "Integer Field") { }
            column(OuterEntry; "Entry No.") { }

            dataitem(Inner; "ALT Universal")
            {
                DataItemLink = "Integer Field" = Outer."Integer Field";
                SqlJoinType = InnerJoin;

                column(InnerEntry; "Entry No.") { }
            }
        }
    }
}

query 68114 "Probe Q Aggregates"
{
    QueryType = Normal;

    elements
    {
        dataitem(U; "ALT Universal")
        {
            column(Avg; "Integer Field") { Method = Average; }
            column(AvgDec; "Decimal Field") { Method = Average; }
            column(Sm; "Integer Field") { Method = Sum; }
            column(Mn; "Integer Field") { Method = Min; }
            column(Mx; "Integer Field") { Method = Max; }
            column(Cnt) { Method = Count; }
            filter(EntryF; "Entry No.") { }
        }
    }
}

query 68115 "Probe Q Captions"
{
    QueryType = Normal;

    elements
    {
        dataitem(U; "ALT Universal")
        {
            column(Entry; "Entry No.") { }
            column(Cust; "Text Field") { Caption = 'Custom Cap'; }
        }
    }
}

codeunit 68116 "Probe Query Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    local procedure Ins(EntryNo: Integer; TextValue: Text; IntegerValue: Integer; DecimalValue: Decimal)
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Init();
        ALTUniversal."Entry No." := EntryNo;
        ALTUniversal."Text Field" := CopyStr(TextValue, 1, 100);
        ALTUniversal."Integer Field" := IntegerValue;
        ALTUniversal."Decimal Field" := DecimalValue;
        ALTUniversal.Insert();
    end;

    local procedure InsertMixedCaseTexts()
    begin
        Ins(1, 'b', 0, 0);
        Ins(2, 'B', 0, 0);
        Ins(3, 'a', 0, 0);
        Ins(4, 'A', 0, 0);
        Ins(5, '_x', 0, 0);
        Ins(6, '1', 0, 0);
        Ins(7, 'Z', 0, 0);
        Ins(8, 'a b', 0, 0);
        Ins(9, 'ab', 0, 0);
        Ins(10, 'ä', 0, 0);
        Ins(11, 'a', 0, 0);
    end;

    [Test]
    procedure Query_OrderByText_UsesTheDatabaseCollation_NotOrdinalOrder()
    // CLAIM: text sorts by the database collation: punctuation, then digits, then letters with lower case before upper case and accents after the plain letter.
    var
        Q: Query "Probe Q Text";
        Rows: Text;
    begin
        Initialize();
        InsertMixedCaseTexts();

        Q.Open();
        while Q.Read() do
            Rows += Format(Q.Entry) + ':' + Q.Txt + ' ';
        Q.Close();

        Assert.AreEqual('5:_x 6:1 3:a 11:a 4:A 10:ä 8:a b 9:ab 1:b 2:B 7:Z ', Rows, 'row order for Text Field ascending');
    end;

    [Test]
    procedure Query_GroupByText_IsCaseSensitive()
    // CLAIM: a and A are different groups, and the groups come out in the collation order.
    var
        Q: Query "Probe Q Text Group";
        Groups: Text;
    begin
        Initialize();
        InsertMixedCaseTexts();

        Q.Open();
        while Q.Read() do
            Groups += Q.Txt + 'x' + Format(Q.Cnt) + ' ';
        Q.Close();

        Assert.AreEqual('_xx1 1x1 ax2 Ax1 äx1 a bx1 abx1 bx1 Bx1 Zx1 ', Groups, 'groups of Text Field with their row counts');
    end;

    [Test]
    procedure Query_GetFilters_TextForSingleAndCombinedFilters()
    // CLAIM: GetFilters is "<field caption>: <filter>" pairs joined by ", " and the filter text is as typed.
    var
        Q: Query "Probe Q Text";
    begin
        Initialize();

        Q.SetRange(Entry, 7);
        Assert.AreEqual('Entry No.: 7', Q.GetFilters(), 'single SetRange');
        Q.SetRange(Entry, 7, 9);
        Assert.AreEqual('Entry No.: 7..9', Q.GetFilters(), 'range');
        Q.SetFilter(Entry, '<>5');
        Assert.AreEqual('Entry No.: <>5', Q.GetFilters(), 'SetFilter');
        Q.SetFilter(Entry, '');
        Assert.AreEqual('', Q.GetFilters(), 'an empty SetFilter clears the filter');
        Assert.AreEqual('', Q.GetFilter(Txt), 'GetFilter of a column without a filter is empty');

        Q.SetRange(Entry, 2);
        Q.SetFilter(Txt, 'S*');
        Assert.AreEqual('Entry No.: 2, Text Field: S*', Q.GetFilters(), 'range and expression');
        Assert.AreEqual('2', Q.GetFilter(Entry), 'GetFilter of one column');
    end;

    [Test]
    procedure Query_GetFilters_ThreeFilters_OrderIsNotColumnOrder()
    // CLAIM: with filters on Entry (column 1), Txt (column 2) and IntF (filter 3), the pairs come out with Txt last and Entry and IntF in the order they were set. Measured, not derived: column order (Entry, Txt, IntF) and table field order (Entry, IntF, Txt) both fail it.
    var
        Q: Query "Probe Q Text";
    begin
        Initialize();

        Q.SetRange(Entry, 1);
        Q.SetRange(Txt, 'a');
        Q.SetRange(IntF, 3);
        Assert.AreEqual('Entry No.: 1, Integer Field: 3, Text Field: a', Q.GetFilters(), 'set Entry, Txt, IntF');
        Clear(Q);

        Q.SetRange(Entry, 1);
        Q.SetRange(IntF, 3);
        Q.SetRange(Txt, 'a');
        Assert.AreEqual('Entry No.: 1, Integer Field: 3, Text Field: a', Q.GetFilters(), 'set Entry, IntF, Txt');
        Clear(Q);

        Q.SetRange(Txt, 'a');
        Q.SetRange(Entry, 1);
        Q.SetRange(IntF, 3);
        Assert.AreEqual('Entry No.: 1, Integer Field: 3, Text Field: a', Q.GetFilters(), 'set Txt, Entry, IntF');
        Clear(Q);

        Q.SetRange(Txt, 'a');
        Q.SetRange(IntF, 3);
        Q.SetRange(Entry, 1);
        Assert.AreEqual('Integer Field: 3, Entry No.: 1, Text Field: a', Q.GetFilters(), 'set Txt, IntF, Entry');
        Clear(Q);

        Q.SetRange(IntF, 3);
        Q.SetRange(Entry, 1);
        Q.SetRange(Txt, 'a');
        Assert.AreEqual('Integer Field: 3, Entry No.: 1, Text Field: a', Q.GetFilters(), 'set IntF, Entry, Txt');
        Clear(Q);

        Q.SetRange(IntF, 3);
        Q.SetRange(Txt, 'a');
        Q.SetRange(Entry, 1);
        Assert.AreEqual('Integer Field: 3, Entry No.: 1, Text Field: a', Q.GetFilters(), 'set IntF, Txt, Entry');
        Clear(Q);

        Q.SetRange(Entry, 1);
        Q.SetRange(IntF, 3);
        Assert.AreEqual('Entry No.: 1, Integer Field: 3', Q.GetFilters(), 'set Entry, IntF');
        Clear(Q);

        Q.SetRange(IntF, 3);
        Q.SetRange(Entry, 1);
        Assert.AreEqual('Integer Field: 3, Entry No.: 1', Q.GetFilters(), 'set IntF, Entry');
    end;

    [Test]
    procedure Query_ColumnNo_IsNotAOneBasedPosition()
    // CLAIM: ColumnNo of the first and second column are neither 1 nor 2.
    var
        Q: Query "Probe Q Text";
    begin
        Initialize();

        Assert.AreNotEqual(1, Q.ColumnNo(Entry), 'the first column is not number 1');
        Assert.AreNotEqual(2, Q.ColumnNo(Txt), 'the second column is not number 2');
        Assert.AreNotEqual(Q.ColumnNo(Entry), Q.ColumnNo(Txt), 'the numbers differ per column');
        Assert.AreEqual('Integer Field', Q.ColumnCaption(IntF), 'a filter element has the field caption');
        Assert.AreEqual('IntF', Q.ColumnName(IntF), 'and its own name');
    end;

    [Test]
    procedure Query_Close_KeepsFiltersAndTopNumberOfRows()
    // CLAIM: Close does not clear what was set before Open; the next Open uses it.
    var
        Q: Query "Probe Q Text";
        RowCount: Integer;
    begin
        Initialize();
        Ins(1, 'x', 0, 0);
        Ins(2, 'x', 0, 0);
        Ins(3, 'x', 0, 0);

        Q.SetRange(Entry, 3);
        Q.Open();
        while Q.Read() do
            RowCount += 1;
        Q.Close();
        Assert.AreEqual(1, RowCount, 'first open');

        RowCount := 0;
        Q.Open();
        while Q.Read() do
            RowCount += 1;
        Q.Close();
        Assert.AreEqual(1, RowCount, 'the filter is still set after Close');
        Assert.AreEqual('Entry No.: 3', Q.GetFilters(), 'GetFilters after Close');

        Q.SetRange(Entry);
        Q.TopNumberOfRows(2);
        Q.Open();
        Q.Close();
        RowCount := 0;
        Q.Open();
        while Q.Read() do
            RowCount += 1;
        Q.Close();
        Assert.AreEqual(2, RowCount, 'TopNumberOfRows is still set after Close');
    end;

    [Test]
    procedure Query_Ties_BreakByPrimaryKeyOfEveryDataItem()
    // CLAIM: rows with equal OrderBy values come out in ascending primary key order, joined dataitems in dataitem order.
    var
        Q: Query "Probe Q Ties";
        J: Query "Probe Q Ties Join";
        Rows: Text;
    begin
        Initialize();
        Ins(30, 'x', 1, 0);
        Ins(10, 'x', 1, 0);
        Ins(20, 'x', 2, 0);
        Ins(5, 'x', 2, 0);
        Ins(1, 'x', 1, 0);

        Q.Open();
        while Q.Read() do
            Rows += Format(Q.IntV) + '/' + Format(Q.Entry) + ' ';
        Q.Close();
        Assert.AreEqual('1/1 1/10 1/30 2/5 2/20 ', Rows, 'ties of a single dataitem');

        Rows := '';
        J.Open();
        while J.Read() do
            Rows += Format(J.IntV) + '/' + Format(J.OuterEntry) + '-' + Format(J.InnerEntry) + ' ';
        J.Close();
        Assert.AreEqual('1/1-1 1/1-10 1/1-30 1/10-1 1/10-10 1/10-30 1/30-1 1/30-10 1/30-30 2/5-5 2/5-20 2/20-5 2/20-20 ', Rows, 'ties of a joined query');
    end;

    [Test]
    procedure Query_ScalarAggregates_OverNoRows_ReturnOneRowOfZeros()
    // CLAIM: Sum, Count, Average, Min and Max over no rows come back as one row with 0 each; none of them fails.
    var
        Q: Query "Probe Q Aggregates";
        RowCount: Integer;
    begin
        Initialize();

        Q.Open();
        while Q.Read() do begin
            RowCount += 1;
            Assert.AreEqual(0, Q.Avg, 'Average of Integer Field');
            Assert.AreEqual(0, Q.AvgDec, 'Average of Decimal Field');
            Assert.AreEqual(0, Q.Sm, 'Sum');
            Assert.AreEqual(0, Q.Mn, 'Min');
            Assert.AreEqual(0, Q.Mx, 'Max');
            Assert.AreEqual(0, Q.Cnt, 'Count');
        end;
        Q.Close();

        Assert.AreEqual(1, RowCount, 'one row');
    end;

    [Test]
    procedure Query_Average_IntegerColumnTruncates_DecimalColumnKeepsSeventeenPlaces()
    // CLAIM: Average of an Integer column is an integer (1.33 and 1.5 both give 1); Average of a Decimal column is the SQL decimal quotient.
    var
        Q: Query "Probe Q Aggregates";
    begin
        Initialize();
        Ins(1, 'x', 1, 1);
        Ins(2, 'x', 1, 1);
        Ins(3, 'x', 2, 2);

        Q.Open();
        Assert.IsTrue(Q.Read(), 'a row');
        Assert.AreEqual('1', Format(Q.Avg, 0, 9), 'Average of 1, 1, 2 over an Integer column');
        Assert.AreEqual('1.33333333333333333', Format(Q.AvgDec, 0, 9), 'Average of 1, 1, 2 over a Decimal column');
        Q.Close();

        Q.SetRange(EntryF, 2, 3);
        Q.Open();
        Assert.IsTrue(Q.Read(), 'a row');
        Assert.AreEqual('1', Format(Q.Avg, 0, 9), 'Average of 1, 2 over an Integer column');
        Assert.AreEqual('1.5', Format(Q.AvgDec, 0, 9), 'Average of 1, 2 over a Decimal column');
        Q.Close();
    end;

    [Test]
    procedure Query_ColumnRead_WithoutARow_ThrowsQueryNoDataSet()
    // CLAIM: reading a column before the first Read, or after the last, raises the same error.
    var
        Q: Query "Probe Q Captions";
        Value: Integer;
    begin
        Initialize();
        Ins(1, 'x', 0, 0);

        asserterror Value := Q.Entry;
        Assert.AreEqual('You have not yet retrieved a data row for this query. The value for column ''Entry'' can only be accessed after a row is retrieved with a call to the READ function.', GetLastErrorText(), 'before Open');
        Assert.AreEqual('QueryNoDataSet', GetLastErrorCode(), 'code before Open');

        Q.Open();
        asserterror Value := Q.Entry;
        Assert.AreEqual('You have not yet retrieved a data row for this query. The value for column ''Entry'' can only be accessed after a row is retrieved with a call to the READ function.', GetLastErrorText(), 'open, no Read yet');

        while Q.Read() do;
        asserterror Value := Q.Entry;
        Assert.AreEqual('QueryNoDataSet', GetLastErrorCode(), 'after the last row');
    end;

    [Test]
    procedure Query_StateMisuse_DoesNotThrow()
    // CLAIM: Read before Open, SetRange after Open, Open twice and Close without Open all pass silently.
    var
        Q: Query "Probe Q Captions";
    begin
        Initialize();

        Assert.IsFalse(Q.Read(), 'Read before Open returns false');
        Q.Open();
        Q.SetRange(Entry, 1);
        Q.Open();
        Q.Close();
        Q.Close();
        Assert.IsFalse(Q.Read(), 'Read after Close returns false');
    end;

    [Test]
    procedure Query_SecurityFiltering_DefaultAndValidated()
    // CLAIM: the default is Filtered; Validated is refused with a fixed text and code Argument.
    var
        Q: Query "Probe Q Captions";
    begin
        Initialize();

        Assert.AreEqual('Filtered', Format(Q.SecurityFiltering()), 'default');
        Q.SecurityFiltering(SecurityFilter::Filtered);
        Assert.AreEqual('Filtered', Format(Q.SecurityFiltering()), 'after setting Filtered');

        asserterror Q.SecurityFiltering(SecurityFilter::Validated);

        Assert.AreEqual('SECURITYFILTERING cannot be set to "Validated" on a Query.', GetLastErrorText(), 'text');
        Assert.AreEqual('Argument', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure Query_ColumnCaption_WithoutCaptionProperty_IsTheFieldCaption()
    // CLAIM: a column with no Caption property shows the source field's caption.
    var
        Q: Query "Probe Q Captions";
    begin
        Initialize();

        Assert.AreEqual('Entry No.', Q.ColumnCaption(Entry), 'no Caption property');
        Assert.AreEqual('Custom Cap', Q.ColumnCaption(Cust), 'with a Caption property');
    end;
}
