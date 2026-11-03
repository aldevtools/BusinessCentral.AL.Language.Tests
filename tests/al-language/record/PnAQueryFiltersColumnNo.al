// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); objects of PnAQueryObjects.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: Query: Query.GetFilters ... Probe wanted: three filters on a query whose OrderBy column is an Integer and which has a Text column; ColumnNo is 4001 + 97 * position
// Facts: Query.GetFilters order for three and four filters (OrderBy on an Integer column, a Text column, a Decimal column and a filter element); Query.ColumnNo of every column
// BC versions: 29 (27 and 28 by CI)

codeunit 70127 "LT PnA Q Filters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ThreeFilters_EntryTxtQty_AllOrders()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT PnA Q Plain";
    begin
        Q.SetRange(Entry, 1);
        Q.SetRange(Txt, 'a');
        Q.SetRange(Qty, 3);
        Observer.Observe('entry-txt-qty', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Entry, 1);
        Q.SetRange(Qty, 3);
        Q.SetRange(Txt, 'a');
        Observer.Observe('entry-qty-txt', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Txt, 'a');
        Q.SetRange(Entry, 1);
        Q.SetRange(Qty, 3);
        Observer.Observe('txt-entry-qty', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Txt, 'a');
        Q.SetRange(Qty, 3);
        Q.SetRange(Entry, 1);
        Observer.Observe('txt-qty-entry', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Qty, 3);
        Q.SetRange(Entry, 1);
        Q.SetRange(Txt, 'a');
        Observer.Observe('qty-entry-txt', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Qty, 3);
        Q.SetRange(Txt, 'a');
        Q.SetRange(Entry, 1);
        Observer.Observe('qty-txt-entry', Q.GetFilters());
        Observer.Expect('entry-txt-qty', 'Entry: 1, Name: a, Qty: 3');
        Observer.Expect('entry-qty-txt', 'Entry: 1, Name: a, Qty: 3');
        Observer.Expect('txt-entry-qty', 'Entry: 1, Name: a, Qty: 3');
        Observer.Expect('txt-qty-entry', 'Entry: 1, Name: a, Qty: 3');
        Observer.Expect('qty-entry-txt', 'Entry: 1, Name: a, Qty: 3');
        Observer.Expect('qty-txt-entry', 'Entry: 1, Name: a, Qty: 3');
        Observer.Verify();
    end;

    [Test]
    procedure FilterElement_And_OtherColumns()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT PnA Q Plain";
    begin
        Q.SetRange(Grp, 'G');
        Q.SetRange(Entry, 1);
        Q.SetRange(Qty, 3);
        Observer.Observe('grp-entry-qty', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Entry, 1);
        Q.SetRange(Qty, 3);
        Q.SetRange(Grp, 'G');
        Observer.Observe('entry-qty-grp', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Txt, 'a');
        Q.SetRange(Grp, 'G');
        Q.SetRange(Qty, 3);
        Observer.Observe('txt-grp-qty', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Qty, 3);
        Q.SetRange(Txt, 'a');
        Q.SetRange(Grp, 'G');
        Observer.Observe('qty-txt-grp', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Amt, 1.5);
        Q.SetRange(Txt, 'a');
        Q.SetRange(Qty, 3);
        Observer.Observe('amt-txt-qty', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Txt, 'a');
        Q.SetRange(Amt, 1.5);
        Q.SetRange(Qty, 3);
        Observer.Observe('txt-amt-qty', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Qty, 3);
        Q.SetRange(Amt, 1.5);
        Q.SetRange(Txt, 'a');
        Observer.Observe('qty-amt-txt', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Qty, 3);
        Q.SetRange(Txt, 'a');
        Q.SetRange(Amt, 1.5);
        Observer.Observe('qty-txt-amt', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Amt, 1.5);
        Q.SetRange(Entry, 1);
        Observer.Observe('amt-entry', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Txt, 'a');
        Q.SetRange(Entry, 1);
        Observer.Observe('txt-entry', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Txt, 'a');
        Q.SetRange(Amt, 1.5);
        Observer.Observe('txt-amt', Q.GetFilters());
        Observer.Expect('grp-entry-qty', 'Grp: G, Entry: 1, Qty: 3');
        Observer.Expect('entry-qty-grp', 'Entry: 1, Grp: G, Qty: 3');
        Observer.Expect('txt-grp-qty', 'Grp: G, Name: a, Qty: 3');
        Observer.Expect('qty-txt-grp', 'Grp: G, Name: a, Qty: 3');
        Observer.Expect('amt-txt-qty', 'Name: a, Qty: 3, Amt: 1.5');
        Observer.Expect('txt-amt-qty', 'Name: a, Qty: 3, Amt: 1.5');
        Observer.Expect('qty-amt-txt', 'Name: a, Qty: 3, Amt: 1.5');
        Observer.Expect('qty-txt-amt', 'Name: a, Qty: 3, Amt: 1.5');
        Observer.Expect('amt-entry', 'Entry: 1, Amt: 1.5');
        Observer.Expect('txt-entry', 'Entry: 1, Name: a');
        Observer.Expect('txt-amt', 'Name: a, Amt: 1.5');
        Observer.Verify();
    end;

    [Test]
    procedure ColumnNo_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT PnA Q Plain";
    begin
        Observer.Observe('Entry', Format(Q.ColumnNo(Entry)));
        Observer.Observe('Txt', Format(Q.ColumnNo(Txt)));
        Observer.Observe('Qty', Format(Q.ColumnNo(Qty)));
        Observer.Observe('Amt', Format(Q.ColumnNo(Amt)));
        Observer.Observe('Grp-filter', Format(Q.ColumnNo(Grp)));
        Observer.Observe('Txt-minus-Entry', Format(Q.ColumnNo(Txt) - Q.ColumnNo(Entry)));
        Observer.Observe('Qty-minus-Txt', Format(Q.ColumnNo(Qty) - Q.ColumnNo(Txt)));
        Observer.Observe('Amt-minus-Qty', Format(Q.ColumnNo(Amt) - Q.ColumnNo(Qty)));
        Observer.Expect('Entry', '1327805081');
        Observer.Expect('Txt', '1619476965');
        Observer.Expect('Qty', '352015135');
        Observer.Expect('Amt', '84079987');
        Observer.Expect('Grp-filter', '322288688');
        Observer.Expect('Txt-minus-Entry', '291671884');
        Observer.Expect('Qty-minus-Txt', '-1267461830');
        Observer.Expect('Amt-minus-Qty', '-267935148');
        Observer.Verify();
    end;

    [Test]
    procedure ColumnNo_Aggregated()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT PnA Q Agg";
    begin
        Observer.Observe('Grp', Format(Q.ColumnNo(Grp)));
        Observer.Observe('Cnt', Format(Q.ColumnNo(Cnt)));
        Observer.Observe('SumQty', Format(Q.ColumnNo(SumQty)));
        Observer.Observe('AvgQty', Format(Q.ColumnNo(AvgQty)));
        Observer.Observe('SumAmt', Format(Q.ColumnNo(SumAmt)));
        Observer.Observe('AvgAmt', Format(Q.ColumnNo(AvgAmt)));
        Observer.Observe('MinAmt', Format(Q.ColumnNo(MinAmt)));
        Observer.Observe('MaxAmt', Format(Q.ColumnNo(MaxAmt)));
        Observer.Expect('Grp', '322288688');
        Observer.Expect('Cnt', '1839419148');
        Observer.Expect('SumQty', '1324748874');
        Observer.Expect('AvgQty', '846325095');
        Observer.Expect('SumAmt', '2021249418');
        Observer.Expect('AvgAmt', '80119067');
        Observer.Expect('MinAmt', '359261017');
        Observer.Expect('MaxAmt', '1123027737');
        Observer.Verify();
    end;
    // Writer PW: failure-triage "Query GetFilters order" (FilterElement_And_OtherColumns: the order found fits that data but is a hypothesis).
    // GetFilters after every order of three SetRange calls with one filter element, on LT PnA Q Plain (columns Entry, Txt, Qty, Amt, then the
    // filter element Grp) and on LT PW Q Mixed (filter FGrp, columns Qty, Entry, filter FAmt, column Txt), and a few longer orders.
    [Test]
    procedure PW_GetFilters_Order_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT PnA Q Plain";
    begin
        Clear(Q);
        Q.SetRange(Grp, 'G');
        Q.SetRange(Entry, 1);
        Q.SetRange(Qty, 3);
        Observer.Observe('plain:Grp-Entry-Qty', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Grp, 'G');
        Q.SetRange(Qty, 3);
        Q.SetRange(Entry, 1);
        Observer.Observe('plain:Grp-Qty-Entry', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Entry, 1);
        Q.SetRange(Grp, 'G');
        Q.SetRange(Qty, 3);
        Observer.Observe('plain:Entry-Grp-Qty', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Entry, 1);
        Q.SetRange(Qty, 3);
        Q.SetRange(Grp, 'G');
        Observer.Observe('plain:Entry-Qty-Grp', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Qty, 3);
        Q.SetRange(Grp, 'G');
        Q.SetRange(Entry, 1);
        Observer.Observe('plain:Qty-Grp-Entry', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Qty, 3);
        Q.SetRange(Entry, 1);
        Q.SetRange(Grp, 'G');
        Observer.Observe('plain:Qty-Entry-Grp', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Grp, 'G');
        Q.SetRange(Txt, 'a');
        Observer.Observe('plain:Grp-Txt', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Txt, 'a');
        Q.SetRange(Grp, 'G');
        Observer.Observe('plain:Txt-Grp', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Grp, 'G');
        Q.SetRange(Amt, 1.5);
        Observer.Observe('plain:Grp-Amt', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Amt, 1.5);
        Q.SetRange(Grp, 'G');
        Observer.Observe('plain:Amt-Grp', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Qty, 3);
        Q.SetRange(Grp, 'G');
        Q.SetRange(Entry, 1);
        Q.SetRange(Txt, 'a');
        Q.SetRange(Amt, 1.5);
        Observer.Observe('plain:Qty-Grp-Entry-Txt-Amt', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Amt, 1.5);
        Q.SetRange(Txt, 'a');
        Q.SetRange(Entry, 1);
        Q.SetRange(Grp, 'G');
        Q.SetRange(Qty, 3);
        Observer.Observe('plain:Amt-Txt-Entry-Grp-Qty', Q.GetFilters());
        Observer.Expect('plain:Grp-Entry-Qty', 'Grp: G, Entry: 1, Qty: 3');
        Observer.Expect('plain:Grp-Qty-Entry', 'Grp: G, Entry: 1, Qty: 3');
        Observer.Expect('plain:Entry-Grp-Qty', 'Entry: 1, Grp: G, Qty: 3');
        Observer.Expect('plain:Entry-Qty-Grp', 'Entry: 1, Grp: G, Qty: 3');
        Observer.Expect('plain:Qty-Grp-Entry', 'Grp: G, Entry: 1, Qty: 3');
        Observer.Expect('plain:Qty-Entry-Grp', 'Entry: 1, Grp: G, Qty: 3');
        Observer.Expect('plain:Grp-Txt', 'Grp: G, Name: a');
        Observer.Expect('plain:Txt-Grp', 'Grp: G, Name: a');
        Observer.Expect('plain:Grp-Amt', 'Grp: G, Amt: 1.5');
        Observer.Expect('plain:Amt-Grp', 'Grp: G, Amt: 1.5');
        Observer.Expect('plain:Qty-Grp-Entry-Txt-Amt', 'Grp: G, Entry: 1, Name: a, Qty: 3, Amt: 1.5');
        Observer.Expect('plain:Amt-Txt-Entry-Grp-Qty', 'Entry: 1, Grp: G, Name: a, Qty: 3, Amt: 1.5');
        Observer.Verify();
    end;

    [Test]
    procedure PW_GetFilters_Order_Mixed()
    var
        Observer: Codeunit "Probe Observer";
        M: Query "LT PW Q Mixed";
    begin
        Clear(M);
        M.SetRange(FGrp, 'G');
        M.SetRange(Qty, 3);
        M.SetRange(Entry, 1);
        Observer.Observe('mixed:FGrp-Qty-Entry', M.GetFilters());
        Clear(M);
        M.SetRange(FGrp, 'G');
        M.SetRange(Entry, 1);
        M.SetRange(Qty, 3);
        Observer.Observe('mixed:FGrp-Entry-Qty', M.GetFilters());
        Clear(M);
        M.SetRange(Qty, 3);
        M.SetRange(FGrp, 'G');
        M.SetRange(Entry, 1);
        Observer.Observe('mixed:Qty-FGrp-Entry', M.GetFilters());
        Clear(M);
        M.SetRange(Qty, 3);
        M.SetRange(Entry, 1);
        M.SetRange(FGrp, 'G');
        Observer.Observe('mixed:Qty-Entry-FGrp', M.GetFilters());
        Clear(M);
        M.SetRange(Entry, 1);
        M.SetRange(FGrp, 'G');
        M.SetRange(Qty, 3);
        Observer.Observe('mixed:Entry-FGrp-Qty', M.GetFilters());
        Clear(M);
        M.SetRange(Entry, 1);
        M.SetRange(Qty, 3);
        M.SetRange(FGrp, 'G');
        Observer.Observe('mixed:Entry-Qty-FGrp', M.GetFilters());
        Clear(M);
        M.SetRange(FGrp, 'G');
        M.SetRange(FAmt, 1.5);
        Observer.Observe('mixed:FGrp-FAmt', M.GetFilters());
        Clear(M);
        M.SetRange(FAmt, 1.5);
        M.SetRange(FGrp, 'G');
        Observer.Observe('mixed:FAmt-FGrp', M.GetFilters());
        Clear(M);
        M.SetRange(FAmt, 1.5);
        M.SetRange(Entry, 1);
        Observer.Observe('mixed:FAmt-Entry', M.GetFilters());
        Clear(M);
        M.SetRange(Entry, 1);
        M.SetRange(FAmt, 1.5);
        Observer.Observe('mixed:Entry-FAmt', M.GetFilters());
        Clear(M);
        M.SetRange(Txt, 'a');
        M.SetRange(FAmt, 1.5);
        M.SetRange(Qty, 3);
        Observer.Observe('mixed:Txt-FAmt-Qty', M.GetFilters());
        Clear(M);
        M.SetRange(Qty, 3);
        M.SetRange(FAmt, 1.5);
        M.SetRange(Txt, 'a');
        Observer.Observe('mixed:Qty-FAmt-Txt', M.GetFilters());
        Clear(M);
        M.SetRange(FAmt, 1.5);
        M.SetRange(Txt, 'a');
        M.SetRange(FGrp, 'G');
        M.SetRange(Entry, 1);
        M.SetRange(Qty, 3);
        Observer.Observe('mixed:FAmt-Txt-FGrp-Entry-Qty', M.GetFilters());
        Observer.Expect('mixed:FGrp-Qty-Entry', 'Grp: G, Qty: 3, Entry: 1');
        Observer.Expect('mixed:FGrp-Entry-Qty', 'Grp: G, Qty: 3, Entry: 1');
        Observer.Expect('mixed:Qty-FGrp-Entry', 'Qty: 3, Grp: G, Entry: 1');
        Observer.Expect('mixed:Qty-Entry-FGrp', 'Qty: 3, Grp: G, Entry: 1');
        Observer.Expect('mixed:Entry-FGrp-Qty', 'Grp: G, Qty: 3, Entry: 1');
        Observer.Expect('mixed:Entry-Qty-FGrp', 'Qty: 3, Grp: G, Entry: 1');
        Observer.Expect('mixed:FGrp-FAmt', 'Grp: G, Amt: 1.5');
        Observer.Expect('mixed:FAmt-FGrp', 'Amt: 1.5, Grp: G');
        Observer.Expect('mixed:FAmt-Entry', 'Amt: 1.5, Entry: 1');
        Observer.Expect('mixed:Entry-FAmt', 'Amt: 1.5, Entry: 1');
        Observer.Expect('mixed:Txt-FAmt-Qty', 'Amt: 1.5, Qty: 3, Name: a');
        Observer.Expect('mixed:Qty-FAmt-Txt', 'Qty: 3, Amt: 1.5, Name: a');
        Observer.Expect('mixed:FAmt-Txt-FGrp-Entry-Qty', 'Amt: 1.5, Grp: G, Qty: 3, Entry: 1, Name: a');
        Observer.Verify();
    end;

    // Writer PW: a filter set again on a column moves it or keeps its place; SetFilter in place of SetRange.
    [Test]
    procedure PW_GetFilters_SetAgain()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT PnA Q Plain";
        M: Query "LT PW Q Mixed";
    begin
        Q.SetRange(Grp, 'G');
        Q.SetRange(Entry, 1);
        Q.SetRange(Qty, 3);
        Q.SetRange(Grp, 'H');
        Observer.Observe('plain:grp-entry-qty-grpAgain', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Entry, 1);
        Q.SetRange(Grp, 'G');
        Q.SetRange(Entry, 2);
        Observer.Observe('plain:entry-grp-entryAgain', Q.GetFilters());
        Clear(Q);
        Q.SetFilter(Qty, '>2');
        Q.SetFilter(Grp, 'G*');
        Q.SetFilter(Entry, '1..5');
        Observer.Observe('plain:setfilter-qty-grp-entry', Q.GetFilters());
        Clear(Q);
        Q.SetRange(Entry, 1);
        Q.SetRange(Grp, 'G');
        Q.SetRange(Entry);
        Observer.Observe('plain:entry-grp-entryCleared', Q.GetFilters());
        M.SetRange(Entry, 1);
        M.SetRange(FGrp, 'G');
        M.SetRange(Entry);
        M.SetRange(Entry, 1);
        Observer.Observe('mixed:entry-fgrp-entryClearedAndSet', M.GetFilters());
        Observer.Expect('plain:grp-entry-qty-grpAgain', 'Entry: 1, Grp: H, Qty: 3');
        Observer.Expect('plain:entry-grp-entryAgain', 'Grp: G, Entry: 2');
        Observer.Expect('plain:setfilter-qty-grp-entry', 'Grp: G*, Entry: 1..5, Qty: >2');
        Observer.Expect('plain:entry-grp-entryCleared', 'Grp: G');
        Observer.Expect('mixed:entry-fgrp-entryClearedAndSet', 'Grp: G, Entry: 1');
        Observer.Verify();
    end;
}
