// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
//   dev-itpro/developer/devenv-query-totals-grouping, devenv-query-retrieve-date-data, devenv-query-accessing-columns
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); CgQueryFixtures.al (tables 84460-84462, table extensions 84460-84461, enum 84460, queries 84460-84474)
// Facts: corpus #667 query leads (writer CG): column types of Sum/Average/Min/Max over Integer and BigInteger, Day/Month/Year columns,
//   a column on a FlowField that sums a FlowField, Exist FlowField columns, DataItemLink on a FlowField (AL0910 warning), Date filters in
//   DataItemTableFilter, filters on Option and Enum columns, a query on a DataPerCompany = false table,
//   filters, links and joins on table extension fields, Query.SaveAsXml/Csv/Json with an object id that does not exist.
// Not here: Record.CopyFilter(Field, QueryVar.Column) (#667 item 106) compiles with AL 30.0.42, but publishing the app fails on BC 29.0
//   with "Unexpected value 'QueryElementAccess' of type 'Microsoft.Dynamics.Nav.CodeAnalysis.BoundKind'", so it cannot be part of this app.

codeunit 84475 "LT CG Query Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        H: Record "LT CG Q Header";
        L: Record "LT CG Q Line";
        S: Record "LT CG Q Shared";
    begin
        H.DeleteAll();
        L.DeleteAll();
        S.DeleteAll();
    end;

    local procedure AddHeader(No: Code[20]; Grp: Code[10]; Qty: Integer; Big: BigInteger; Kind: Option; ExtFlag: Boolean; ExtCode: Code[10])
    var
        H: Record "LT CG Q Header";
    begin
        H.Init();
        H."No." := No;
        H.Grp := Grp;
        H.Qty := Qty;
        H.Big := Big;
        H.Kind := Kind;
        H.EKind := "LT CG Q Kind Enum".FromInteger(Kind);
        H.ExtFlag := ExtFlag;
        H.ExtCode := ExtCode;
        H.Insert();
    end;

    local procedure AddLine(EntryNo: Integer; HeaderNo: Code[20]; Amount: Decimal; ExtA: Code[10]; ExtB: Decimal)
    var
        L: Record "LT CG Q Line";
    begin
        L.Init();
        L."Entry No." := EntryNo;
        L."Header No." := HeaderNo;
        L.Amount := Amount;
        L.ExtA := ExtA;
        L.ExtB := ExtB;
        L.Insert();
    end;

    local procedure TypeOf(V: Variant): Text
    begin
        if V.IsInteger() then
            exit('Integer');
        if V.IsBigInteger() then
            exit('BigInteger');
        if V.IsDecimal() then
            exit('Decimal');
        exit('other');
    end;

    local procedure SeedKinds()
    begin
        // Kind: 0 = ' ', 1 = Quote, 2 = Order, 3 = Invoice
        AddHeader('H1', 'A', 1, 1, 1, false, '');
        AddHeader('H2', 'A', 2, 2, 2, false, '');
        AddHeader('H3', 'B', 5, 5, 3, false, '');
        AddHeader('H4', 'B', 0, 0, 0, false, '');
    end;

    // #667 item 97 (and the integer Average of item 100): the AL type and value of Sum/Average/Min/Max columns over an Integer and a BigInteger field.
    [Test]
    procedure Aggregates_OverIntegerAndBigInteger_TypesAndValues()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT CG Q Agg";
        V: Variant;
        I: Integer;
        D: Decimal;
        N: Integer;
    begin
        Initialize();
        AddHeader('H1', 'A', 1, 1, 0, false, '');
        AddHeader('H2', 'A', 2, 2, 0, false, '');
        AddHeader('H3', 'B', 2, 2, 0, false, '');
        AddHeader('H4', 'B', 2, 2, 0, false, '');
        AddHeader('H5', 'B', 3, 3, 0, false, '');
        AddHeader('H6', 'C', 1, 1, 0, false, '');
        AddHeader('H7', 'C', 1, 1, 0, false, '');
        AddHeader('H8', 'C', 2, 2, 0, false, '');
        // D: 1, 2, 2 averages 1.67, so a rounding Average would give 2.
        AddHeader('H9', 'D', 1, 1, 0, false, '');
        AddHeader('HA', 'D', 2, 2, 0, false, '');
        AddHeader('HB', 'D', 2, 2, 0, false, '');
        Q.Open();
        while Q.Read() do begin
            N += 1;
            V := Q.SumQty;
            Observer.Observe(Q.Grp + ' sum', Format(Q.SumQty) + ' ' + TypeOf(V));
            V := Q.AvgQty;
            Observer.Observe(Q.Grp + ' avg', Format(Q.AvgQty) + ' ' + TypeOf(V));
            I := Q.AvgQty;
            D := Q.AvgQty;
            Observer.Observe(Q.Grp + ' avg as int, dec', Format(I) + ' ' + Format(D));
            V := Q.MinQty;
            Observer.Observe(Q.Grp + ' min', Format(Q.MinQty) + ' ' + TypeOf(V));
            V := Q.MaxQty;
            Observer.Observe(Q.Grp + ' max', Format(Q.MaxQty) + ' ' + TypeOf(V));
            V := Q.SumBig;
            Observer.Observe(Q.Grp + ' sum big', Format(Q.SumBig) + ' ' + TypeOf(V));
            V := Q.AvgBig;
            Observer.Observe(Q.Grp + ' avg big', Format(Q.AvgBig) + ' ' + TypeOf(V));
        end;
        Q.Close();
        Observer.Observe('rows', Format(N));
        Observer.Expect('A sum', '3 Integer');
        Observer.Expect('A avg', '1 Integer');
        Observer.Expect('A avg as int, dec', '1 1');
        Observer.Expect('A min', '1 Integer');
        Observer.Expect('A max', '2 Integer');
        Observer.Expect('A sum big', '3 BigInteger');
        Observer.Expect('A avg big', '1 BigInteger');
        Observer.Expect('B sum', '7 Integer');
        Observer.Expect('B avg', '2 Integer');
        Observer.Expect('B avg as int, dec', '2 2');
        Observer.Expect('B min', '2 Integer');
        Observer.Expect('B max', '3 Integer');
        Observer.Expect('B sum big', '7 BigInteger');
        Observer.Expect('B avg big', '2 BigInteger');
        Observer.Expect('C sum', '4 Integer');
        Observer.Expect('C avg', '1 Integer');
        Observer.Expect('C avg as int, dec', '1 1');
        Observer.Expect('C min', '1 Integer');
        Observer.Expect('C max', '2 Integer');
        Observer.Expect('C sum big', '4 BigInteger');
        Observer.Expect('C avg big', '1 BigInteger');
        Observer.Expect('D sum', '5 Integer');
        Observer.Expect('D avg', '1 Integer');
        Observer.Expect('D avg as int, dec', '1 1');
        Observer.Expect('D min', '1 Integer');
        Observer.Expect('D max', '2 Integer');
        Observer.Expect('D sum big', '5 BigInteger');
        Observer.Expect('D avg big', '1 BigInteger');
        Observer.Expect('rows', '4');
        Observer.Verify();
    end;

    // #667 item 100: Day/Month/Year columns over a DateTime and a Date field, also for blank values.
    // The test session runs in UTC, so this does not tell whether the DateTime columns use UTC or the session time zone;
    // it pins that they agree with DT2Date in that session (23:30 and 00:30 rows stay on their own day).
    [Test]
    procedure DateMethods_DayMonthYear_OnDateTimeDateAndBlank()
    var
        Observer: Codeunit "Probe Observer";
        H: Record "LT CG Q Header";
        Q: Query "LT CG Q DateM";
        LocalDt: DateTime;
    begin
        Initialize();
        H.Init();
        H."No." := 'D1';
        H.Posted := CreateDateTime(20240305D, 120000T);
        H.PDate := 20240305D;
        H.Insert();
        H.Init();
        H."No." := 'D2';
        H.Posted := CreateDateTime(20231231D, 233000T);
        H.PDate := 20231231D;
        H.Insert();
        H.Init();
        H."No." := 'D3';
        H.Posted := CreateDateTime(20240101D, 003000T);
        H.PDate := 20240101D;
        H.Insert();
        H.Init();
        H."No." := 'D4';
        H.Insert();
        Q.Open();
        while Q.Read() do begin
            H.Get(Q.No);
            LocalDt := H.Posted;
            Observer.Observe(Q.No + ' datetime', Format(Q.DtDay) + '/' + Format(Q.DtMonth) + '/' + Format(Q.DtYear));
            Observer.Observe(Q.No + ' date', Format(Q.DDay) + '/' + Format(Q.DMonth) + '/' + Format(Q.DYear));
            if LocalDt <> 0DT then
                Observer.Observe(Q.No + ' local date of datetime', Format(DT2Date(LocalDt), 0, 9));
        end;
        Q.Close();
        Observer.Expect('D1 datetime', '5/3/2024');
        Observer.Expect('D1 date', '5/3/2024');
        Observer.Expect('D1 local date of datetime', '2024-03-05');
        Observer.Expect('D2 datetime', '31/12/2023');
        Observer.Expect('D2 date', '31/12/2023');
        Observer.Expect('D2 local date of datetime', '2023-12-31');
        Observer.Expect('D3 datetime', '1/1/2024');
        Observer.Expect('D3 date', '1/1/2024');
        Observer.Expect('D3 local date of datetime', '2024-01-01');
        Observer.Expect('D4 datetime', '0/0/0');
        Observer.Expect('D4 date', '0/0/0');
        Observer.Verify();
    end;

    // #667 item 98: a column on a FlowField whose CalcFormula sums a FlowField of another table.
    [Test]
    procedure FlowFieldColumn_SumOfAFlowField_OpenRead()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT CG Q Deep";
        Ok: Boolean;
    begin
        Initialize();
        AddHeader('H1', 'A', 0, 0, 0, false, '');
        AddLine(1, 'H1', 10, '', 0);
        AddLine(2, 'H1', 5, '', 0);
        Ok := TryOpenReadDeep(Q);
        Observer.Observe('ok', Format(Ok));
        if Ok then
            Observer.Observe('row', Q.No + '|' + Format(Q.DeepSum))
        else
            Observer.ObserveError('error');
        Observer.Expect('ok', 'No');
        Observer.Expect('error|text', 'A flow field is part of the query column list, this is not supported');
        Observer.Expect('error|code', 'NotSupported');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryOpenReadDeep(var Q: Query "LT CG Q Deep")
    begin
        Q.Open();
        Q.Read();
    end;

    // #667 item 99: columns on Exist and -Exist (not exist) FlowFields.
    [Test]
    procedure FlowFieldColumn_ExistAndNotExist_Values()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT CG Q Exist";
    begin
        Initialize();
        AddHeader('H1', 'A', 0, 0, 0, false, '');
        AddHeader('H2', 'A', 0, 0, 0, false, '');
        AddLine(1, 'H1', 10, '', 0);
        AddLine(2, 'H1', 5, '', 0);
        Q.Open();
        while Q.Read() do
            Observer.Observe(Q.No, Format(Q.HasLines) + '|' + Format(Q.NoLines));
        Q.Close();
        Observer.Expect('H1', 'Yes|No');
        Observer.Expect('H2', 'No|Yes');
        Observer.Verify();
    end;

    // #667 item 99, the literal case of the issue: column(Assembly_BOM; "Assembly BOM") on Item. Every row read must agree with CalcFields.
    [Test]
    procedure FlowFieldColumn_ItemAssemblyBom_AgreesWithCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT CG Q Item BOM";
        Item: Record Item;
        Rows: Integer;
        Mismatches: Integer;
    begin
        Q.Open();
        while Q.Read() do begin
            Rows += 1;
            Item.Get(Q.No);
            Item.CalcFields("Assembly BOM");
            if Item."Assembly BOM" <> Q.Assembly_BOM then
                Mismatches += 1;
        end;
        Q.Close();
        Observer.Observe('rows equal item count', Format(Rows = Item.Count()));
        Observer.Observe('mismatches', Format(Mismatches));
        Observer.Expect('rows equal item count', 'Yes');
        Observer.Expect('mismatches', '0');
        Observer.Verify();
    end;

    // #667 item 102: DataItemLink with a FlowField on the parent side (compiles with warning AL0910 below runtime 30.0).
    // The SQL error is not caught by a [TryFunction]; asserterror catches it.
    [Test]
    procedure DataItemLink_OnAParentFlowField_OpenReadErrors()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT CG Q Link FF Parent";
    begin
        Initialize();
        SeedLinkFlowField();
        asserterror ReadAllParent(Q);
        Observer.ObserveError('parent error');
        Observer.Expect('parent error|text', 'An unexpected error occurred after a database command was cancelled.');
        Observer.Expect('parent error|code', 'Sql:Sql');
        Observer.Verify();
    end;

    // #667 item 102: DataItemLink with a FlowField on the child side (compiles with warning AL0910 below runtime 30.0).
    [Test]
    procedure DataItemLink_OnAChildFlowField_OpenReadErrors()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT CG Q Link FF Child";
    begin
        Initialize();
        SeedLinkFlowField();
        asserterror ReadAllChild(Q);
        Observer.ObserveError('child error');
        Observer.Expect('child error|text', 'An unexpected error occurred after a database command was cancelled.');
        Observer.Expect('child error|code', 'Sql:Sql');
        Observer.Verify();
    end;

    local procedure SeedLinkFlowField()
    begin
        AddHeader('H1', 'A', 15, 0, 0, false, '');
        AddHeader('H2', 'A', 7, 0, 0, false, '');
        AddLine(1, 'H1', 10, '', 0);
        AddLine(2, 'H1', 5, '', 0);
        AddLine(3, 'X', 15, '', 0);
        AddLine(4, 'X', 7, '', 0);
    end;

    local procedure ReadAllParent(var Q: Query "LT CG Q Link FF Parent")
    var
        Rows: Text;
    begin
        Q.Open();
        while Q.Read() do
            Rows += Q.No + ':' + Format(Q.EntryNo) + ' ';
        Error('rows: %1', Rows);
    end;

    local procedure ReadAllChild(var Q: Query "LT CG Q Link FF Child")
    var
        Rows: Text;
    begin
        Q.Open();
        while Q.Read() do
            Rows += Q.No + ':' + Format(Q.EntryNo) + ' ';
        Error('rows: %1', Rows);
    end;

    // #667 item 103: DataItemTableFilter = PDate = filter(29082018) (a number, not a date) and filter(20180829D).
    [Test]
    procedure DataItemTableFilter_DateAsNumberAndAsDateLiteral()
    var
        Observer: Codeunit "Probe Observer";
        H: Record "LT CG Q Header";
        QN: Query "LT CG Q Date Num Filter";
        QL: Query "LT CG Q Date Lit Filter";
        Ok: Boolean;
        Rows: Text;
    begin
        Initialize();
        H.Init();
        H."No." := 'D1';
        H.PDate := 20180829D;
        H.Insert();
        H.Init();
        H."No." := 'D2';
        H.PDate := 20180830D;
        H.Insert();
        ClearLastError();
        Ok := TryReadDateNum(QN, Rows);
        Observer.Observe('number ok', Format(Ok));
        if Ok then
            Observer.Observe('number rows', Rows)
        else
            Observer.ObserveError('number error');
        Rows := '';
        Ok := TryReadDateLit(QL, Rows);
        Observer.Observe('literal ok', Format(Ok));
        if Ok then
            Observer.Observe('literal rows', Rows)
        else
            Observer.ObserveError('literal error');
        Observer.Expect('number ok', 'No');
        Observer.Expect('number error|text', 'The format of the Date ''29082018'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('number error|code', 'InvalidFilterExpression:Evaluate');
        Observer.Expect('literal ok', 'No');
        Observer.Expect('literal error|text', 'The format of the Date ''20180829D'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('literal error|code', 'InvalidFilterExpression:Evaluate');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadDateNum(var Q: Query "LT CG Q Date Num Filter"; var Rows: Text)
    begin
        Q.Open();
        while Q.Read() do
            Rows += Q.No + ' ';
    end;

    [TryFunction]
    local procedure TryReadDateLit(var Q: Query "LT CG Q Date Lit Filter"; var Rows: Text)
    begin
        Q.Open();
        while Q.Read() do
            Rows += Q.No + ' ';
    end;

    local procedure ReadKinds(var Q: Query "LT CG Q Kind"): Text
    var
        Rows: Text;
    begin
        Q.Open();
        while Q.Read() do
            Rows += Q.No + ' ';
        Q.Close();
        exit(Rows.TrimEnd());
    end;

    // #667 items 104 and 110: SetRange on an Option column with the query's own member (Q.Kind::Quote) before Open.
    [Test]
    procedure OptionColumn_SetRangeWithQueryMember_BeforeOpen()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT CG Q Kind";
    begin
        Initialize();
        SeedKinds();
        Q.SetRange(Kind, Q.Kind::Quote);
        Observer.Observe('quote', ReadKinds(Q));
        Q.SetRange(Kind, Q.Kind::"Order", Q.Kind::Invoice);
        Observer.Observe('order..invoice', ReadKinds(Q));
        Observer.Observe('getfilter', Q.GetFilter(Kind));
        Q.SetRange(Kind, Q.Kind::" ");
        Observer.Observe('blank member', ReadKinds(Q));
        Observer.Expect('quote', 'H1');
        Observer.Expect('order..invoice', 'H2 H3');
        Observer.Expect('getfilter', 'Order..Invoice');
        Observer.Expect('blank member', 'H4');
        Observer.Verify();
    end;

    // #667 items 101 and 104: SetFilter on an Option column with option text, a | list, and an ordinal; SetRange with an Integer ordinal.
    [Test]
    procedure OptionColumn_SetFilterByTextAndOrdinal()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT CG Q Kind";
    begin
        Initialize();
        SeedKinds();
        Q.SetFilter(Kind, 'Quote|Order');
        Observer.Observe('text list', ReadKinds(Q));
        Observer.Observe('text list getfilter', Q.GetFilter(Kind));
        Q.SetFilter(Kind, '3');
        Observer.Observe('ordinal text', ReadKinds(Q));
        Observer.Observe('ordinal text getfilter', Q.GetFilter(Kind));
        Q.SetFilter(Kind, '%1', Q.Kind::Invoice);
        Observer.Observe('placeholder member', ReadKinds(Q));
        Q.SetRange(Kind, 2);
        Observer.Observe('setrange integer', ReadKinds(Q));
        Observer.Observe('setrange integer getfilter', Q.GetFilter(Kind));
        Q.SetFilter(Kind, '<>Quote');
        Observer.Observe('not quote', ReadKinds(Q));
        Observer.Expect('text list', 'H1 H2');
        Observer.Expect('text list getfilter', 'Quote|Order');
        Observer.Expect('ordinal text', 'H3');
        Observer.Expect('ordinal text getfilter', 'Invoice');
        Observer.Expect('placeholder member', 'H3');
        Observer.Expect('setrange integer', 'H2');
        Observer.Expect('setrange integer getfilter', 'Order');
        Observer.Expect('not quote', 'H2 H3 H4');
        Observer.Verify();
    end;

    // #667 item 104: the same filters on an Enum column.
    [Test]
    procedure EnumColumn_SetRangeAndSetFilter_BeforeOpen()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT CG Q Kind";
    begin
        Initialize();
        SeedKinds();
        Q.SetRange(EKind, "LT CG Q Kind Enum"::Quote);
        Observer.Observe('enum value', ReadKinds(Q));
        Q.SetFilter(EKind, 'Quote|Order');
        Observer.Observe('text list', ReadKinds(Q));
        Observer.Observe('text list getfilter', Q.GetFilter(EKind));
        Q.SetFilter(EKind, '3');
        Observer.Observe('ordinal text', ReadKinds(Q));
        Q.SetRange(EKind);
        Observer.Observe('cleared', ReadKinds(Q));
        Observer.Expect('enum value', 'H1');
        Observer.Expect('text list', 'H1 H2');
        Observer.Expect('text list getfilter', 'Quote|Order');
        Observer.Expect('ordinal text', 'H3');
        Observer.Expect('cleared', 'H1 H2 H3 H4');
        Observer.Verify();
    end;

    // #667 item 104: an invalid option text in SetFilter on an Option column.
    [Test]
    procedure OptionColumn_SetFilterUnknownText_Error()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT CG Q Kind";
        Ok: Boolean;
    begin
        Initialize();
        SeedKinds();
        ClearLastError();
        Ok := TrySetFilterAndRead(Q, 'Bogus');
        Observer.Observe('ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('error');
        Observer.Expect('ok', 'No');
        Observer.Expect('error|text', '''Bogus'' is not an option. The existing options are:  ,Quote,Order,Invoice');
        Observer.Expect('error|code', 'InvalidFilterExpression:InvalidOptionString');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySetFilterAndRead(var Q: Query "LT CG Q Kind"; FilterText: Text)
    begin
        Q.SetFilter(Kind, FilterText);
        Q.Open();
        Q.Read();
    end;

    // #667 item 105: a query on a DataPerCompany = false table.
    [Test]
    procedure DataPerCompanyFalseTable_OpenRead()
    var
        Observer: Codeunit "Probe Observer";
        S: Record "LT CG Q Shared";
        Q: Query "LT CG Q Shared";
        Ok: Boolean;
        Rows: Text;
    begin
        Initialize();
        S."No." := 'S1';
        S.Amount := 4.5;
        S.Insert();
        S."No." := 'S2';
        S.Amount := 1;
        S.Insert();
        ClearLastError();
        Ok := TryReadShared(Q, Rows);
        Observer.Observe('ok', Format(Ok));
        if Ok then
            Observer.Observe('rows', Rows)
        else
            Observer.ObserveError('error');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('rows', 'S1:4.5 S2:1 ');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadShared(var Q: Query "LT CG Q Shared"; var Rows: Text)
    begin
        Q.Open();
        while Q.Read() do
            Rows += Q.No + ':' + Format(Q.Amount) + ' ';
    end;

    // #667 item 107: DataItemTableFilter on a table extension field (ExtFlag = const(false)).
    [Test]
    procedure ExtensionField_DataItemTableFilter_FiltersRows()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT CG Q Ext Filter";
        Rows: Text;
    begin
        Initialize();
        AddHeader('H1', 'A', 0, 0, 0, false, 'X1');
        AddHeader('H2', 'A', 0, 0, 0, true, 'X2');
        AddHeader('H3', 'A', 0, 0, 0, false, 'X3');
        Q.Open();
        while Q.Read() do
            Rows += Q.No + ':' + Q.ExtCode + ' ';
        Q.Close();
        Observer.Observe('rows', Rows);
        Q.SetRange(ExtCode, 'X3');
        Rows := '';
        Q.Open();
        while Q.Read() do
            Rows += Q.No + ':' + Q.ExtCode + ' ';
        Q.Close();
        Observer.Observe('rows with runtime filter on ext column', Rows);
        Observer.Expect('rows', 'H1:X1 H3:X3 ');
        Observer.Expect('rows with runtime filter on ext column', 'H3:X3 ');
        Observer.Verify();
    end;

    // #667 item 107: DataItemLink between two table extension fields.
    [Test]
    procedure ExtensionField_DataItemLink_JoinsRows()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT CG Q Ext Link";
        Rows: Text;
    begin
        Initialize();
        AddHeader('H1', 'A', 0, 0, 0, false, 'K1');
        AddHeader('H2', 'A', 0, 0, 0, false, 'K2');
        AddLine(1, '', 0, 'K1', 0);
        AddLine(2, '', 0, 'K2', 0);
        AddLine(3, '', 0, 'K1', 0);
        AddLine(4, '', 0, 'K9', 0);
        Q.Open();
        while Q.Read() do
            Rows += Q.No + ':' + Format(Q.EntryNo) + ' ';
        Q.Close();
        Observer.Observe('rows', Rows);
        Observer.Expect('rows', 'H1:1 H2:2 H1:3 ');
        Observer.Verify();
    end;

    // #667 item 108: a join with a FlowField column on the parent and two extension field columns on the child.
    [Test]
    procedure Join_FlowFieldColumnAndExtensionFieldColumns()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT CG Q Ext Join";
        Ok: Boolean;
        Rows: Text;
    begin
        Initialize();
        AddHeader('H1', 'A', 0, 0, 3, false, '');
        AddHeader('H2', 'A', 0, 0, 1, false, '');
        AddLine(1, 'H1', 10, 'A1', 1.5);
        AddLine(2, 'H1', 5, 'A2', 2.5);
        AddLine(3, 'H2', 7, 'A3', 3.5);
        ClearLastError();
        Ok := TryReadExtJoin(Q, Rows);
        Observer.Observe('ok', Format(Ok));
        if Ok then
            Observer.Observe('rows', Rows)
        else
            Observer.ObserveError('error');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('rows', 'H1:15:1:A1:1.5 H1:15:2:A2:2.5 ');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadExtJoin(var Q: Query "LT CG Q Ext Join"; var Rows: Text)
    begin
        Q.Open();
        while Q.Read() do
            Rows += Q.No + ':' + Format(Q.LineSum) + ':' + Format(Q.EntryNo) + ':' + Q.ExtA + ':' + Format(Q.ExtB) + ' ';
    end;

    // #667 item 112: Query.SaveAsXml / SaveAsCsv / SaveAsJson to a stream with a query id that does not exist.
    [Test]
    procedure SaveAs_UnknownQueryId_Errors()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TrySaveXmlById(99999999);
        Observer.Observe('xml ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('xml error');
        Ok := TrySaveCsvById(99999999);
        Observer.Observe('csv ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('csv error');
        Ok := TrySaveJsonById(99999999);
        Observer.Observe('json ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('json error');
        Ok := TrySaveXmlById(0);
        Observer.Observe('xml id 0 ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('xml id 0 error');
        Observer.Expect('xml ok', 'No');
        Observer.Expect('xml error|text', 'You tried to invoke the Query object with the ID 99999999 from the object LT CG Query Leads. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('xml error|code', 'AL:MetadataNotFound');
        Observer.Expect('csv ok', 'No');
        Observer.Expect('csv error|text', 'You tried to invoke the Query object with the ID 99999999 from the object LT CG Query Leads. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('csv error|code', 'AL:MetadataNotFound');
        Observer.Expect('json ok', 'No');
        Observer.Expect('json error|text', 'You tried to invoke the Query object with the ID 99999999 from the object LT CG Query Leads. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('json error|code', 'AL:MetadataNotFound');
        Observer.Expect('xml id 0 ok', 'No');
        Observer.Expect('xml id 0 error|text', 'You tried to invoke the Query object with the ID 0 from the object LT CG Query Leads. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('xml id 0 error|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySaveXmlById(Id: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Query.SaveAsXml(Id, OutS);
    end;

    [TryFunction]
    local procedure TrySaveCsvById(Id: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Query.SaveAsCsv(Id, OutS);
    end;

    [TryFunction]
    local procedure TrySaveJsonById(Id: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Query.SaveAsJson(Id, OutS);
    end;

    // Writer QZ: a filter() element over a FlowField (fixtures in QzQueryFlowFieldFilter.al).
    // Headers: Q1 no lines; Q2 one line (5); Q3 two lines (2, 3); Q4 two lines (1, -1).
    local procedure QzSeed()
    var
        H: Record "LT QZ Q Header";
        L: Record "LT QZ Q Line";
    begin
        H.DeleteAll();
        L.DeleteAll();
        H."No." := 'Q1';
        H.Insert();
        H."No." := 'Q2';
        H.Insert();
        H."No." := 'Q3';
        H.Insert();
        H."No." := 'Q4';
        H.Insert();
        QzLine('Q2', 1, 5);
        QzLine('Q3', 1, 2);
        QzLine('Q3', 2, 3);
        QzLine('Q4', 1, 1);
        QzLine('Q4', 2, -1);
    end;

    local procedure QzLine(HeaderNo: Code[20]; LineNo: Integer; Amount: Decimal)
    var
        L: Record "LT QZ Q Line";
    begin
        L."Header No." := HeaderNo;
        L."Line No." := LineNo;
        L.Amount := Amount;
        L.Insert();
    end;

    [Test]
    procedure QZ_FilterElement_FlowField_ColumnFilter()
    var
        Observer: Codeunit "Probe Observer";
        NoLines: Query "LT QZ Q No Lines";
        Many: Query "LT QZ Q Many Lines";
        Rows: Text;
    begin
        QzSeed();
        NoLines.Open();
        while NoLines.Read() do
            Rows += NoLines.No + ' ';
        NoLines.Close();
        Observer.Observe('exist const(false)', Rows);
        Rows := '';
        Many.Open();
        while Many.Read() do
            Rows += Many.No + ' ';
        Many.Close();
        Observer.Observe('count > 1 and sum <> 0', Rows);
        Rows := '';
        NoLines.SetRange(HasLines, true);
        NoLines.Open();
        while NoLines.Read() do
            Rows += NoLines.No + ' ';
        NoLines.Close();
        Observer.Observe('exist SetRange(true) over const(false)', Rows);
        Observer.Expect('exist const(false)', 'Q1 ');
        Observer.Expect('count > 1 and sum <> 0', 'Q3 ');
        Observer.Expect('exist SetRange(true) over const(false)', 'Q2 Q3 Q4 ');
        Observer.Verify();
    end;

    [Test]
    procedure QZ_FilterElement_FlowField_RunTimeFilter()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QZ Q Open Filter";
        Rows: Text;
    begin
        QzSeed();
        Q.Open();
        while Q.Read() do
            Rows += Q.No + ' ';
        Q.Close();
        Observer.Observe('no filter', Rows);
        Rows := '';
        Q.SetRange(HasLines, true);
        Q.Open();
        while Q.Read() do
            Rows += Q.No + ' ';
        Q.Close();
        Observer.Observe('SetRange HasLines true', Rows);
        Rows := '';
        Q.SetRange(HasLines);
        Q.SetFilter(LineSum, '>%1', 2);
        Q.Open();
        while Q.Read() do
            Rows += Q.No + ' ';
        Q.Close();
        Observer.Observe('SetFilter LineSum > 2', Rows);
        Rows := '';
        Q.SetFilter(LineSum, '0');
        Q.Open();
        while Q.Read() do
            Rows += Q.No + ' ';
        Q.Close();
        Observer.Observe('SetFilter LineSum 0', Rows);
        Observer.Expect('no filter', 'Q1 Q2 Q3 Q4 ');
        Observer.Expect('SetRange HasLines true', 'Q2 Q3 Q4 ');
        Observer.Expect('SetFilter LineSum > 2', 'Q2 Q3 ');
        Observer.Expect('SetFilter LineSum 0', 'Q1 Q4 ');
        Observer.Verify();
    end;
}
