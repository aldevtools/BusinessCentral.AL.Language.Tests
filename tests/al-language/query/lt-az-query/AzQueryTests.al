// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects 80660-80669 (AzQueryObjects.al)
// Probe: corpus issue 651 (queries and event subscribers), items 1, 3, 5 and 8, writer AZ (item 7 is a Linux suspect, see FilterElement_ReadInQueryProcedure).
// Already pinned: items 2, 4 and 6 (query/lt-query-live-write, query/lt-query-read-to-end, query/PRQueryOpenColumn.al); Method = Count on a
// field column does not compile (must-not-compile case 0102).
// BC versions: 27, 28, 29

codeunit 80670 "LT AZ Query Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure AddRow(Id: Integer; Cat: Code[10]; Sub: Code[10]; Amount: Decimal; Kind: Code[10])
    var
        Row: Record "LT AZ Q Row";
    begin
        Row.Id := Id;
        Row.Cat := Cat;
        Row.Sub := Sub;
        Row.Amount := Amount;
        Row.Kind := Kind;
        Row.Insert();
    end;

    local procedure ReadTwoGroups(): Text
    var
        Q: Query "LT AZ Q Two Groups";
        R: Text;
    begin
        Q.Open();
        while Q.Read() do
            R += Q.Cat + '/' + Q.Sub + '=' + Format(Q.Total) + ';';
        exit(R);
    end;

    local procedure ReadOneGroup(): Text
    var
        Q: Query "LT AZ Q One Group";
        R: Text;
    begin
        Q.Open();
        while Q.Read() do
            R += Q.Cat + '=' + Format(Q.Total) + '/' + Format(Q.N) + ';';
        exit(R);
    end;

    // ---- item 1: aggregated query without OrderBy, groups equal in the first group column ----

    [Test]
    procedure NoOrderBy_TwoGroupsSameCat()
    var
        Row: Record "LT AZ Q Row";
    begin
        Row.DeleteAll();
        AddRow(1, 'A', 'Z', 1, '');
        AddRow(2, 'A', 'B', 2, '');
        AddRow(3, 'B', 'A', 4, '');
        AddRow(4, 'A', 'Z', 8, '');
        Observer.Observe('z_first', ReadTwoGroups());
        Row.DeleteAll();
        AddRow(1, 'A', 'B', 2, '');
        AddRow(2, 'A', 'Z', 1, '');
        AddRow(3, 'B', 'A', 4, '');
        Observer.Observe('b_first', ReadTwoGroups());
        Observer.Expect('z_first', 'A/B=2;A/Z=9;B/A=4;');
        Observer.Expect('b_first', 'A/B=2;A/Z=1;B/A=4;');
        Observer.Verify();
    end;

    [Test]
    procedure NoOrderBy_EqualSums()
    var
        Row: Record "LT AZ Q Row";
    begin
        Row.DeleteAll();
        AddRow(1, 'B', 'X', 5, '');
        AddRow(2, 'A', 'Y', 5, '');
        AddRow(3, 'C', 'X', 5, '');
        Observer.Observe('order', ReadOneGroup());
        Observer.Expect('order', 'A=5/1;B=5/1;C=5/1;');
        Observer.Verify();
    end;

    // ---- item 3: Sum over a count FlowField, filtered and unfiltered ----

    local procedure SeedHeads()
    var
        Row: Record "LT AZ Q Row";
        Head: Record "LT AZ Q Head";
    begin
        Row.DeleteAll();
        Head.DeleteAll();
        Head.Cat := 'A';
        Head.Grp := 'G1';
        Head.Insert();
        Head.Cat := 'B';
        Head.Grp := 'G1';
        Head.Insert();
        Head.Cat := 'C';
        Head.Grp := 'G2';
        Head.Insert();
        AddRow(1, 'A', '', 1, 'K1');
        AddRow(2, 'A', '', 1, 'K1');
        AddRow(3, 'A', '', 1, 'K2');
        AddRow(4, 'B', '', 1, 'K2');
    end;

    local procedure ReadSumCount(KindFilter: Text): Text
    var
        Q: Query "LT AZ Q Sum Count FF";
        R: Text;
    begin
        if KindFilter <> '' then
            Q.SetFilter(KindFilter, KindFilter);
        Q.Open();
        while Q.Read() do
            R += Q.Grp + '=' + Format(Q.SumLines) + '/' + Format(Q.N) + ';';
        exit(R);
    end;

    local procedure ReadSumCountAll(KindFilter: Text; CatFilter: Text): Text
    var
        Q: Query "LT AZ Q Sum Count FF All";
        R: Text;
    begin
        if KindFilter <> '' then
            Q.SetFilter(KindFilter, KindFilter);
        if CatFilter <> '' then
            Q.SetFilter(CatFilter, CatFilter);
        Q.Open();
        while Q.Read() do
            R += Format(Q.SumLines) + ';';
        exit(R);
    end;

    local procedure PerRow(KindFilter: Text): Text
    var
        Head: Record "LT AZ Q Head";
        R: Text;
    begin
        if KindFilter <> '' then
            Head.SetFilter("Kind Filter", KindFilter);
        if Head.FindSet() then
            repeat
                Head.CalcFields(Lines);
                R += Head.Cat + '=' + Format(Head.Lines) + ';';
            until Head.Next() = 0;
        exit(R);
    end;

    [Test]
    procedure SumOverCountFlowField()
    begin
        SeedHeads();
        Observer.Observe('perrow', PerRow(''));
        Observer.Observe('perrow_k1', PerRow('K1'));
        Observer.Observe('grouped', ReadSumCount(''));
        Observer.Observe('grouped_k1', ReadSumCount('K1'));
        Observer.Observe('grouped_k2', ReadSumCount('K2'));
        Observer.Observe('all', ReadSumCountAll('', ''));
        Observer.Observe('all_k1', ReadSumCountAll('K1', ''));
        Observer.Observe('all_cat_a', ReadSumCountAll('', 'A'));
        Observer.Observe('all_cat_c', ReadSumCountAll('', 'C'));
        Observer.Expect('perrow', 'A=3;B=1;C=0;');
        Observer.Expect('perrow_k1', 'A=2;B=0;C=0;');
        Observer.Expect('grouped', 'G1=4/2;G2=0/1;');
        Observer.Expect('grouped_k1', 'G1=2/2;G2=0/1;');
        Observer.Expect('grouped_k2', 'G1=2/2;G2=0/1;');
        Observer.Expect('all', '4;');
        Observer.Expect('all_k1', '2;');
        Observer.Expect('all_cat_a', '3;');
        Observer.Expect('all_cat_c', '0;');
        Observer.Verify();
    end;

    // ---- item 5: a RecordId column: grouping, OrderBy, SetFilter and SaveAsCsv ----

    local procedure SeedRefs(var HeadA: Record "LT AZ Q Head"; var HeadB: Record "LT AZ Q Head")
    var
        Row: Record "LT AZ Q Row";
    begin
        SeedHeads();
        HeadA.Get('A');
        HeadB.Get('B');
        Row.Get(1);
        Row.Ref := HeadA.RecordId;
        Row.Modify();
        Row.Get(2);
        Row.Ref := HeadB.RecordId;
        Row.Modify();
        Row.Get(3);
        Row.Ref := HeadA.RecordId;
        Row.Modify();
    end;

    [TryFunction]
    local procedure TryReadRidPlain(Filter: Text; var R: Text)
    var
        Q: Query "LT AZ Q Rid Plain";
    begin
        Q.SetFilter(Ref, Filter);
        Q.Open();
        while Q.Read() do
            R += Format(Q.Id) + ';';
    end;

    [Test]
    procedure RecordIdColumn_GroupAndOrderBy()
    var
        HeadA: Record "LT AZ Q Head";
        HeadB: Record "LT AZ Q Head";
        Q: Query "LT AZ Q Rid Group";
        R: Text;
    begin
        SeedRefs(HeadA, HeadB);
        Q.Open();
        while Q.Read() do
            R += Format(Q.Ref) + '=' + Format(Q.N) + ';';
        Observer.Observe('groups', R);
        Observer.Expect('groups', 'LT AZ Q Head: B=1;LT AZ Q Head: A=2;=1;');
        Observer.Verify();
    end;

    [Test]
    procedure RecordIdColumn_SetFilter()
    var
        HeadA: Record "LT AZ Q Head";
        HeadB: Record "LT AZ Q Head";
        R: Text;
        TextOk: Boolean;
        TextErr: Text;
        TextCode: Text;
    begin
        SeedRefs(HeadA, HeadB);
        Observer.Observe('format_a', Format(HeadA.RecordId));
        R := '';
        Observer.Observe('eq_ok', Format(TryReadRidPlain(Format(HeadA.RecordId), R)));
        Observer.Observe('eq_rows', R);
        Observer.ObserveError('eq');
        R := '';
        Observer.Observe('quoted_ok', Format(TryReadRidPlain('''' + Format(HeadA.RecordId) + '''', R)));
        Observer.Observe('quoted_rows', R);
        Observer.ObserveError('quoted');
        R := '';
        Observer.Observe('blank_ok', Format(TryReadRidPlain('''''', R)));
        Observer.Observe('blank_rows', R);
        Observer.ObserveError('blank');
        R := '';
        Observer.Observe('notblank_ok', Format(TryReadRidPlain('<>''''', R)));
        Observer.Observe('notblank_rows', R);
        Observer.ObserveError('notblank');
        R := '';
        // A filter text that is not a record id: BC 28.5 and 29.0 accept it and return no rows; BC 27.5 raises an error.
        ClearLastError();
        TextOk := TryReadRidPlain('abc', R);
        TextErr := GetLastErrorText();
        TextCode := GetLastErrorCode();
#if BC28PLUS
        Observer.Observe('text_ok', Format(TextOk));
        Observer.Observe('text_rows', R);
        Observer.ObserveError('text');
#endif
        Observer.Expect('format_a', 'LT AZ Q Head: A');
        Observer.Expect('eq_ok', 'Yes');
        Observer.Expect('eq_rows', '1;3;');
        Observer.Expect('eq|text', '');
        Observer.Expect('eq|code', '');
        Observer.Expect('quoted_ok', 'Yes');
        Observer.Expect('quoted_rows', '1;3;');
        Observer.Expect('quoted|text', '');
        Observer.Expect('quoted|code', '');
        Observer.Expect('blank_ok', 'Yes');
        Observer.Expect('blank_rows', '4;');
        Observer.Expect('blank|text', '');
        Observer.Expect('blank|code', '');
        Observer.Expect('notblank_ok', 'Yes');
        Observer.Expect('notblank_rows', '1;2;3;');
        Observer.Expect('notblank|text', '');
        Observer.Expect('notblank|code', '');
#if BC28PLUS
        Observer.Expect('text_ok', 'Yes');
        Observer.Expect('text_rows', '');
        Observer.Expect('text|text', '');
        Observer.Expect('text|code', '');
#endif
        Observer.Verify();
#if BC28PLUS
#else
        if TextOk then
            Error('expected the plain-text filter to fail on BC 27.5');
        if R <> '' then
            Error('expected no rows but was [%1]', R);
        if TextCode <> 'InvalidFilterExpression:Evaluate' then
            Error('expected code [InvalidFilterExpression:Evaluate] but was [%1]', TextCode);
        if TextErr <> 'The value "abc" can''t be evaluated into type RecordID.' then
            Error('expected text [The value "abc" can''t be evaluated into type RecordID.] but was [%1]', TextErr);
#endif
    end;

    [Test]
    procedure RecordIdColumn_SaveAsCsv()
    var
        HeadA: Record "LT AZ Q Head";
        HeadB: Record "LT AZ Q Head";
        TempBlob: Codeunit "Temp Blob";
        Q: Query "LT AZ Q Rid Plain";
        Out: OutStream;
        Ins: InStream;
        Line: Text;
        R: Text;
    begin
        SeedRefs(HeadA, HeadB);
        TempBlob.CreateOutStream(Out);
        Observer.Observe('save', Format(Q.SaveAsCsv(Out)));
        TempBlob.CreateInStream(Ins);
        while not Ins.EOS() do begin
            Ins.ReadText(Line);
            R += Line + '|';
        end;
        Observer.Observe('csv', R);
        Observer.Expect('save', 'Yes');
        Observer.Expect('csv', 'Id,Ref|1,LT AZ Q Head: A|2,LT AZ Q Head: B|3,LT AZ Q Head: A|4,|');
        Observer.Verify();
    end;

    // ---- item 7: a query procedure that reads a filter element by its bare name ----

    [TryFunction]
    local procedure TryReadKindF(var Q: Query "LT AZ Q Filter Proc"; var R: Text)
    begin
        R := Q.ReadKindF();
    end;

    local procedure ObserveKindF(var Q: Query "LT AZ Q Filter Proc"; Name: Text)
    var
        R: Text;
    begin
        R := '-';
        Observer.Observe(Name + '_ok', Format(TryReadKindF(Q, R)));
        Observer.Observe(Name, R);
        Observer.ObserveError(Name);
    end;

    // Linux suspect (not asserted, kept as probe source; no [Test] attribute): on BC 29.0 the first call of ReadKindF (no filter, query not
    // open) ended the test with an uncatchable "Unexpected CLR exception thrown.: System.InvalidCastException: Unable to cast object of type
    // 'Microsoft.Dynamics.Nav.Runtime.NavInteger' to type 'Microsoft.Dynamics.Nav.Runtime.NavCode'." raised in Query80668.ReadKindF().
    procedure FilterElement_ReadInQueryProcedure()
    var
        Q: Query "LT AZ Q Filter Proc";
        Q2: Query "LT AZ Q Filter Proc";
    begin
        SeedHeads();
        ObserveKindF(Q, 'nofilter_closed');
        Q.SetRange(KindF, 'K1');
        ObserveKindF(Q, 'setrange_closed');
        Q.Open();
        ObserveKindF(Q, 'setrange_open');
        Q.Read();
        ObserveKindF(Q, 'setrange_read');
        Observer.Observe('getfilter', Q.GetFilter(KindF));
        Q2.SetFilter(KindF, 'K1|K2');
        Q2.Open();
        Q2.Read();
        ObserveKindF(Q2, 'setfilter_read');
        Observer.Finish();
    end;

    // ---- item 8: TopNumberOfRows and SecurityFiltering set after Open ----

    [TryFunction]
    local procedure TryReadAll(var Q: Query "LT AZ Q Rows"; var R: Text)
    begin
        while Q.Read() do
            R += Format(Q.Id) + ';';
    end;

    local procedure ObserveRead(var Q: Query "LT AZ Q Rows"; Name: Text)
    var
        R: Text;
    begin
        Observer.Observe(Name + '_ok', Format(TryReadAll(Q, R)));
        Observer.Observe(Name + '_rows', R);
        Observer.ObserveError(Name);
    end;

    [Test]
    procedure TopNumberOfRows_AfterOpen()
    var
        Q: Query "LT AZ Q Rows";
        Q2: Query "LT AZ Q Rows";
    begin
        SeedHeads();
        Q.Open();
        Q.TopNumberOfRows(2);
        ObserveRead(Q, 'before_first_read');
        Q.Open();
        ObserveRead(Q, 'reopen');
        Q2.Open();
        Q2.Read();
        Q2.TopNumberOfRows(1);
        ObserveRead(Q2, 'after_first_read');
        Observer.Observe('top_value', Format(Q2.TopNumberOfRows()));
        Observer.Expect('before_first_read_ok', 'No');
        Observer.Expect('before_first_read_rows', '');
        Observer.Expect('before_first_read|text', 'The READ function is called on a query after query metadata has been changed by one of the following: SETFILTER, SETRANGE, SECURITYFILTERING, or TOPNUMBEROFROWS. After metadata changes, you must reopen the query by calling the OPEN function before calling the READ function.');
        Observer.Expect('before_first_read|code', 'Query');
        Observer.Expect('reopen_ok', 'Yes');
        Observer.Expect('reopen_rows', '1;2;');
        Observer.Expect('reopen|text', '');
        Observer.Expect('reopen|code', '');
        Observer.Expect('after_first_read_ok', 'No');
        Observer.Expect('after_first_read_rows', '');
        Observer.Expect('after_first_read|text', 'The READ function is called on a query after query metadata has been changed by one of the following: SETFILTER, SETRANGE, SECURITYFILTERING, or TOPNUMBEROFROWS. After metadata changes, you must reopen the query by calling the OPEN function before calling the READ function.');
        Observer.Expect('after_first_read|code', 'Query');
        Observer.Expect('top_value', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SecurityFiltering_AfterOpen()
    var
        Q: Query "LT AZ Q Rows";
        Q2: Query "LT AZ Q Rows";
    begin
        SeedHeads();
        Q.Open();
        Q.SecurityFiltering(SecurityFilter::Filtered);
        ObserveRead(Q, 'before_first_read');
        Q2.Open();
        Q2.Read();
        Q2.SecurityFiltering(SecurityFilter::Ignored);
        ObserveRead(Q2, 'after_first_read');
        Observer.Observe('value', Format(Q2.SecurityFiltering()));
        Observer.Expect('before_first_read_ok', 'Yes');
        Observer.Expect('before_first_read_rows', '1;2;3;4;');
        Observer.Expect('before_first_read|text', '');
        Observer.Expect('before_first_read|code', '');
        Observer.Expect('after_first_read_ok', 'No');
        Observer.Expect('after_first_read_rows', '');
        Observer.Expect('after_first_read|text', 'The READ function is called on a query after query metadata has been changed by one of the following: SETFILTER, SETRANGE, SECURITYFILTERING, or TOPNUMBEROFROWS. After metadata changes, you must reopen the query by calling the OPEN function before calling the READ function.');
        Observer.Expect('after_first_read|code', 'Query');
        Observer.Expect('value', 'Ignored');
        Observer.Verify();
    end;

    // ---- writer SG (al-runtime-rs assumption grouped-query-ties-in-grouping-order): groups that tie on every OrderBy column ----
    // Results (BC 27.5, 28.5, 29.0 on CI): tied groups come in the order of the grouping columns as declared, each ascending, for an
    // ascending and a descending OrderBy on a column and on a Sum; the insert order does not matter.

    local procedure SgSeedTies(Reverse: Boolean)
    var
        Row: Record "LT AZ Q Row";
        Ids: List of [Integer];
        Cats: List of [Code[10]];
        Subs: List of [Code[10]];
        Kinds: List of [Code[10]];
        i: Integer;
        n: Integer;
    begin
        Row.DeleteAll();
        // Ids, Cat, Sub, Kind: neither the Id order nor the insert order follows the grouping columns.
        Ids.Add(4); Cats.Add('B'); Subs.Add('Y'); Kinds.Add('K');
        Ids.Add(2); Cats.Add('A'); Subs.Add('Z'); Kinds.Add('K');
        Ids.Add(7); Cats.Add('C'); Subs.Add('X'); Kinds.Add('K');
        Ids.Add(1); Cats.Add('A'); Subs.Add('X'); Kinds.Add('K');
        Ids.Add(6); Cats.Add('B'); Subs.Add('X'); Kinds.Add('J');
        Ids.Add(3); Cats.Add('C'); Subs.Add('Z'); Kinds.Add('K');
        Ids.Add(5); Cats.Add('A'); Subs.Add('Y'); Kinds.Add('K');
        n := Ids.Count();
        for i := 1 to n do
            if Reverse then
                AddRow(Ids.Get(n + 1 - i) + 10, Cats.Get(n + 1 - i), Subs.Get(n + 1 - i), 1, Kinds.Get(n + 1 - i))
            else
                AddRow(Ids.Get(i), Cats.Get(i), Subs.Get(i), 1, Kinds.Get(i));
    end;

    local procedure SgReadSubCat(): Text
    var
        Q: Query "LT SG Q Ties SubCat";
        R: Text;
    begin
        Q.Open();
        while Q.Read() do
            R += Q.Kind + ':' + Q.Sub + '/' + Q.Cat + ';';
        exit(R);
    end;

    local procedure SgReadCatSub(): Text
    var
        Q: Query "LT SG Q Ties CatSub";
        R: Text;
    begin
        Q.Open();
        while Q.Read() do
            R += Q.Kind + ':' + Q.Cat + '/' + Q.Sub + ';';
        exit(R);
    end;

    local procedure SgReadSumDesc(): Text
    var
        Q: Query "LT SG Q Ties SumDesc";
        R: Text;
    begin
        Q.Open();
        while Q.Read() do
            R += Format(Q.Total) + ':' + Q.Sub + '/' + Q.Cat + ';';
        exit(R);
    end;

    local procedure SgReadKindDesc(): Text
    var
        Q: Query "LT SG Q Ties KindDesc";
        R: Text;
    begin
        Q.Open();
        while Q.Read() do
            R += Q.Kind + ':' + Q.Sub + '/' + Q.Cat + ';';
        exit(R);
    end;

    [Test]
    procedure SG_OrderByTies_GroupingSubThenCat()
    begin
        SgSeedTies(false);
        Observer.Observe('subcat', SgReadSubCat());
        Observer.Observe('subcat_again', SgReadSubCat());
        SgSeedTies(true);
        Observer.Observe('subcat_reverse', SgReadSubCat());
        Observer.Expect('subcat', 'J:X/B;K:X/A;K:X/C;K:Y/A;K:Y/B;K:Z/A;K:Z/C;');
        Observer.Expect('subcat_again', 'J:X/B;K:X/A;K:X/C;K:Y/A;K:Y/B;K:Z/A;K:Z/C;');
        Observer.Expect('subcat_reverse', 'J:X/B;K:X/A;K:X/C;K:Y/A;K:Y/B;K:Z/A;K:Z/C;');
        Observer.Verify();
    end;

    [Test]
    procedure SG_OrderByTies_GroupingCatThenSub()
    begin
        SgSeedTies(false);
        Observer.Observe('catsub', SgReadCatSub());
        SgSeedTies(true);
        Observer.Observe('catsub_reverse', SgReadCatSub());
        Observer.Expect('catsub', 'J:B/X;K:A/X;K:A/Y;K:A/Z;K:B/Y;K:C/X;K:C/Z;');
        Observer.Expect('catsub_reverse', 'J:B/X;K:A/X;K:A/Y;K:A/Z;K:B/Y;K:C/X;K:C/Z;');
        Observer.Verify();
    end;

    [Test]
    procedure SG_OrderByTies_DescendingKind()
    begin
        SgSeedTies(false);
        Observer.Observe('kinddesc', SgReadKindDesc());
        SgSeedTies(true);
        Observer.Observe('kinddesc_reverse', SgReadKindDesc());
        Observer.Expect('kinddesc', 'K:X/A;K:X/C;K:Y/A;K:Y/B;K:Z/A;K:Z/C;J:X/B;');
        Observer.Expect('kinddesc_reverse', 'K:X/A;K:X/C;K:Y/A;K:Y/B;K:Z/A;K:Z/C;J:X/B;');
        Observer.Verify();
    end;

    [Test]
    procedure SG_OrderByTies_DescendingSum()
    begin
        SgSeedTies(false);
        AddRow(20, 'C', 'Z', 5, 'K');
        Observer.Observe('sumdesc', SgReadSumDesc());
        Observer.Expect('sumdesc', '6:Z/C;1:X/A;1:X/B;1:X/C;1:Y/A;1:Y/B;1:Z/A;');
        Observer.Verify();
    end;
}
