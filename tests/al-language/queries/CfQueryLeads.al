// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-totals-grouping
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 84400, queries 84401-84406, test codeunit 84409
// Probe: written against BC on CI; every literal asserted below is what BC produced. Corpus issue 667 items 91, 92, 93, 95, 96.
// Facts:
//   91: what a query column with Method = Day / Month / Year returns for a blank Date and a blank DateTime field, and for a set one.
//   92: ColumnName and ColumnCaption of a column with Method = Min / Max / Sum (the docs name the result "Min_Quantity"), before Open and after Read.
//   93: MaxStrLen of a query column (Text[30]) before Open, after Open and after Read (microsoft/AL issue 8037).
//   95: the run-time type of a column with Method = Count (microsoft/AL issue 7413: the designer showed type None).
//   96: a column over a Text field with ReverseSign = true compiles; what it returns at run time (BC 29 only, see the test).
//   OrderBy naming one column twice and a column over a FlowFilter field do not compile: must-not-compile cases 1640 and 1641.
// BC versions: 27, 28, 29 by CI

table 84400 "LT CF Q Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Department; Text[30]) { }
        field(3; "Posting Date"; Date) { }
        field(4; "Posted At"; DateTime) { }
        field(5; Quantity; Decimal) { Caption = 'Qty Caption'; }
        field(6; "Date Filter"; Date) { FieldClass = FlowFilter; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

query 84401 "LT CF Q Date Parts"
{
    OrderBy = ascending(DYear), ascending(TYear);
    elements
    {
        dataitem(Row; "LT CF Q Row")
        {
            column(DDay; "Posting Date") { Method = Day; }
            column(DMonth; "Posting Date") { Method = Month; }
            column(DYear; "Posting Date") { Method = Year; }
            column(TDay; "Posted At") { Method = Day; }
            column(TMonth; "Posted At") { Method = Month; }
            column(TYear; "Posted At") { Method = Year; }
            column(Cnt) { Method = Count; }
        }
    }
}

query 84402 "LT CF Q Totals"
{
    elements
    {
        dataitem(Row; "LT CF Q Row")
        {
            column(Department; Department) { }
            column(MinQty; Quantity) { Method = Min; }
            column(MaxQty; Quantity) { Method = Max; }
            column(SumQty; Quantity) { Method = Sum; }
            column(Qty; Quantity) { Method = Min; }
        }
    }
}

query 84403 "LT CF Q Departments"
{
    elements
    {
        dataitem(Row; "LT CF Q Row")
        {
            column(EntryNo; "Entry No.") { }
            column(Department; Department) { }
        }
    }
}

query 84405 "LT CF Q Count"
{
    elements
    {
        dataitem(Row; "LT CF Q Row")
        {
            column(Counter) { Method = Count; }
        }
    }
}

query 84406 "LT CF Q Reverse Text"
{
    OrderBy = ascending(EntryNo);
    elements
    {
        dataitem(Row; "LT CF Q Row")
        {
            column(EntryNo; "Entry No.") { }
            column(Department; Department) { ReverseSign = true; }
            column(Plain; Department) { }
        }
    }
}

codeunit 84409 "LT CF Query Leads"
{
    Subtype = Test;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Row: Record "LT CF Q Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."Entry No." := 1;
        Row.Department := 'SALES';
        Row.Quantity := 5;
        Row.Insert();
        Row.Init();
        Row."Entry No." := 2;
        Row.Department := 'SALES';
        Row."Posting Date" := DMY2Date(17, 3, 2024);
        Row."Posted At" := CreateDateTime(DMY2Date(9, 11, 2023), 120000T);
        Row.Quantity := -2;
        Row.Insert();
    end;

    [Test]
    procedure DayMonthYear_BlankAndSetDates()
    var
        Q: Query "LT CF Q Date Parts";
        N: Integer;
    begin
        Seed();
        Q.Open();
        while Q.Read() do begin
            N += 1;
            Observer.Observe(Format(N) + ' date', StrSubstNo('%1/%2/%3', Q.DDay, Q.DMonth, Q.DYear));
            Observer.Observe(Format(N) + ' datetime', StrSubstNo('%1/%2/%3', Q.TDay, Q.TMonth, Q.TYear));
            Observer.Observe(Format(N) + ' count', Format(Q.Cnt));
        end;
        Q.Close();
        Observer.Observe('rows', Format(N));
        Observer.Expect('1 date', '0/0/0');
        Observer.Expect('1 datetime', '0/0/0');
        Observer.Expect('1 count', '1');
        Observer.Expect('2 date', '17/3/2024');
        Observer.Expect('2 datetime', '9/11/2023');
        Observer.Expect('2 count', '1');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure TotalsColumns_NameAndCaption()
    var
        Q: Query "LT CF Q Totals";
    begin
        Seed();
        Observer.Observe('before open min name', Q.ColumnName(Q.MinQty));
        Observer.Observe('before open min caption', Q.ColumnCaption(Q.MinQty));
        Observer.Observe('before open qty name', Q.ColumnName(Q.Qty));
        Observer.Observe('before open qty caption', Q.ColumnCaption(Q.Qty));
        Q.Open();
        Q.Read();
        Observer.Observe('min name', Q.ColumnName(Q.MinQty));
        Observer.Observe('min caption', Q.ColumnCaption(Q.MinQty));
        Observer.Observe('max name', Q.ColumnName(Q.MaxQty));
        Observer.Observe('max caption', Q.ColumnCaption(Q.MaxQty));
        Observer.Observe('sum name', Q.ColumnName(Q.SumQty));
        Observer.Observe('sum caption', Q.ColumnCaption(Q.SumQty));
        Observer.Observe('qty name', Q.ColumnName(Q.Qty));
        Observer.Observe('qty caption', Q.ColumnCaption(Q.Qty));
        Observer.Observe('values', StrSubstNo('%1 %2 %3 %4', Q.MinQty, Q.MaxQty, Q.SumQty, Q.Qty));
        Q.Close();
        Observer.Expect('before open min name', 'MinQty');
        Observer.Expect('before open min caption', 'MinQty');
        Observer.Expect('before open qty name', 'Qty');
        Observer.Expect('before open qty caption', 'Qty');
        Observer.Expect('min name', 'MinQty');
        Observer.Expect('min caption', 'MinQty');
        Observer.Expect('max name', 'MaxQty');
        Observer.Expect('max caption', 'MaxQty');
        Observer.Expect('sum name', 'SumQty');
        Observer.Expect('sum caption', 'SumQty');
        Observer.Expect('qty name', 'Qty');
        Observer.Expect('qty caption', 'Qty');
        Observer.Expect('values', '-2 5 3 -2');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryMaxStrLen(var Q: Query "LT CF Q Departments"; var Len: Integer)
    begin
        Len := MaxStrLen(Q.Department);
    end;

    [TryFunction]
    local procedure TrySetFilterWithMaxStrLen(var Q: Query "LT CF Q Departments")
    begin
        Q.SetFilter(Department, '<>%1', CopyStr('HELPDESK', 1, MaxStrLen(Q.Department)));
    end;

    [Test]
    procedure MaxStrLen_OfQueryColumn_BeforeAndAfterOpen()
    var
        Q: Query "LT CF Q Departments";
        Len: Integer;
    begin
        Seed();
        ClearLastError();
        Observer.Observe('before open ok', Format(TryMaxStrLen(Q, Len)));
        Observer.Observe('before open len', Format(Len));
        Observer.ObserveError('before open');
        Observer.Observe('setfilter before open ok', Format(TrySetFilterWithMaxStrLen(Q)));
        Observer.ObserveError('setfilter before open');
        Len := 0;
        Q.Open();
        Observer.Observe('after open ok', Format(TryMaxStrLen(Q, Len)));
        Observer.Observe('after open len', Format(Len));
        Observer.ObserveError('after open');
        Len := 0;
        Q.Read();
        Observer.Observe('after read ok', Format(TryMaxStrLen(Q, Len)));
        Observer.Observe('after read len', Format(Len));
        Observer.ObserveError('after read');
        Q.Close();
        Observer.Expect('before open ok', 'No');
        Observer.Expect('before open len', '0');
        Observer.Expect('before open|text', 'You have not yet retrieved a data row for this query. The value for column ''Department'' can only be accessed after a row is retrieved with a call to the READ function.');
        Observer.Expect('before open|code', 'QueryNoDataSet');
        Observer.Expect('setfilter before open ok', 'No');
        Observer.Expect('setfilter before open|text', 'You have not yet retrieved a data row for this query. The value for column ''Department'' can only be accessed after a row is retrieved with a call to the READ function.');
        Observer.Expect('setfilter before open|code', 'QueryNoDataSet');
        Observer.Expect('after open ok', 'No');
        Observer.Expect('after open len', '0');
        Observer.Expect('after open|text', 'You have not yet retrieved a data row for this query. The value for column ''Department'' can only be accessed after a row is retrieved with a call to the READ function.');
        Observer.Expect('after open|code', 'QueryNoDataSet');
        Observer.Expect('after read ok', 'Yes');
        Observer.Expect('after read len', '30');
        Observer.Expect('after read|text', '');
        Observer.Expect('after read|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure CountColumn_RuntimeType()
    var
        Q: Query "LT CF Q Count";
        V: Variant;
        I: Integer;
        B: BigInteger;
    begin
        Seed();
        Q.Open();
        Observer.Observe('read', Format(Q.Read()));
        V := Q.Counter;
        Observer.Observe('is integer', Format(V.IsInteger()));
        Observer.Observe('is biginteger', Format(V.IsBigInteger()));
        Observer.Observe('is decimal', Format(V.IsDecimal()));
        Observer.Observe('format', Format(Q.Counter));
        Observer.Observe('format 9', Format(Q.Counter, 0, 9));
        I := Q.Counter;
        B := Q.Counter;
        Observer.Observe('as integer', Format(I));
        Observer.Observe('as biginteger', Format(B));
        Observer.Observe('column name', Q.ColumnName(Q.Counter));
        Observer.Observe('column caption', Q.ColumnCaption(Q.Counter));
        Q.Close();
        Observer.Expect('read', 'Yes');
        Observer.Expect('is integer', 'Yes');
        Observer.Expect('is biginteger', 'No');
        Observer.Expect('is decimal', 'No');
        Observer.Expect('format', '2');
        Observer.Expect('format 9', '2');
        Observer.Expect('as integer', '2');
        Observer.Expect('as biginteger', '2');
        Observer.Expect('column name', 'Counter');
        Observer.Expect('column caption', 'Counter');
        Observer.Verify();
    end;

    // BC 27.5 and 28.5 on the Linux CI container end this read with "An unexpected error occurred after a database command was cancelled."
    // which a TryFunction does not catch; BC 29 raises the catchable DB:SumOnNoneNumeric error asserted below. The 27/28 outcome is queued for
    // the Windows check (Linux suspect), so the test runs on BC 29 only until then.
#if BC29PLUS
    [TryFunction]
    local procedure TryReadReverseText(var Q: Query "LT CF Q Reverse Text"; var Got: Text)
    begin
        Q.Open();
        while Q.Read() do
            Got += StrSubstNo('[%1:%2:%3]', Q.EntryNo, Q.Department, Q.Plain);
        Q.Close();
    end;

    [Test]
    procedure ReverseSign_OnTextColumn_Runtime()
    var
        Q: Query "LT CF Q Reverse Text";
        Got: Text;
    begin
        Seed();
        ClearLastError();
        Observer.Observe('ok', Format(TryReadReverseText(Q, Got)));
        Observer.Observe('rows', Got);
        Observer.ObserveError('read');
        Observer.Expect('ok', 'No');
        Observer.Expect('rows', '');
        Observer.Expect('read|text', 'Cannot calculate a Sum or Average because the field is not a numeric field (Decimal, BigInteger, Integer or Duration data type). Review the FlowField, query, or analysis view that calculates this value.');
        Observer.Expect('read|code', 'DB:SumOnNoneNumeric');
        Observer.Verify();
    end;
#endif
}
