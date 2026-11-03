// Batch 7 probes: Query.GetFilters order, Query.ColumnNo numbers, Query Metadata API columns of a normal query. Observe only.
codeunit 68509 "W7 Query Filters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ApplyOrderBy(var Q: Query "W7 Q Filters"; Order: Text)
    var
        i: Integer;
    begin
        for i := 1 to StrLen(Order) do
            case Order[i] of
                'E':
                    Q.SetRange(Entry, 1);
                'I':
                    Q.SetRange(IntF, 3);
                'T':
                    Q.SetRange(Txt, 'a');
                'C':
                    Q.SetRange(Grp, 'G');
                'D':
                    Q.SetRange(DecF, 2.5);
                'A':
                    Q.SetRange(Dt, DMY2Date(5, 3, 2024));
                'B':
                    Q.SetRange(Flag, true);
            end;
    end;

    local procedure ApplyPlain(var Q: Query "W7 Q Filters Plain"; Order: Text)
    var
        i: Integer;
    begin
        for i := 1 to StrLen(Order) do
            case Order[i] of
                'E':
                    Q.SetRange(Entry, 1);
                'I':
                    Q.SetRange(IntF, 3);
                'T':
                    Q.SetRange(Txt, 'a');
                'C':
                    Q.SetRange(Grp, 'G');
                'D':
                    Q.SetRange(DecF, 2.5);
                'A':
                    Q.SetRange(Dt, DMY2Date(5, 3, 2024));
                'B':
                    Q.SetRange(Flag, true);
            end;
    end;

    local procedure ApplyTextOrder(var Q: Query "W7 Q Filters Text Order"; Order: Text)
    var
        i: Integer;
    begin
        for i := 1 to StrLen(Order) do
            case Order[i] of
                'E':
                    Q.SetRange(Entry, 1);
                'I':
                    Q.SetRange(IntF, 3);
                'T':
                    Q.SetRange(Txt, 'a');
                'C':
                    Q.SetRange(Grp, 'G');
                'D':
                    Q.SetRange(DecF, 2.5);
                'A':
                    Q.SetRange(Dt, DMY2Date(5, 3, 2024));
                'B':
                    Q.SetRange(Flag, true);
            end;
    end;

    // E Entry (Integer), I IntF (Integer), T Txt (Text), C Grp (Code), D DecF (Decimal), A Dt (Date), B Flag (Boolean)
    local procedure Orders(): List of [Text]
    var
        Result: List of [Text];
    begin
        Result.Add('EIT');
        Result.Add('ETI');
        Result.Add('TEI');
        Result.Add('TIE');
        Result.Add('IET');
        Result.Add('ITE');
        Result.Add('TCE');
        Result.Add('CTE');
        Result.Add('ECT');
        Result.Add('DAE');
        Result.Add('BAD');
        Result.Add('EIDTCAB');
        Result.Add('BACTDIE');
        exit(Result);
    end;

    [Test]
    procedure GetFilters_OrderByIsAnInteger_TextColumnPresent()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "W7 Q Filters";
        Order: Text;
    begin
        foreach Order in Orders() do begin
            Clear(Q);
            ApplyOrderBy(Q, Order);
            Observer.Observe('set ' + Order, Q.GetFilters());
        end;
        Observer.Expect('set EIT', 'Entry: 1, IntF: 3, Txt: a');
        Observer.Expect('set ETI', 'Entry: 1, IntF: 3, Txt: a');
        Observer.Expect('set TEI', 'Entry: 1, IntF: 3, Txt: a');
        Observer.Expect('set TIE', 'Entry: 1, IntF: 3, Txt: a');
        Observer.Expect('set IET', 'Entry: 1, IntF: 3, Txt: a');
        Observer.Expect('set ITE', 'Entry: 1, IntF: 3, Txt: a');
        Observer.Expect('set TCE', 'Entry: 1, Txt: a, Grp: G');
        Observer.Expect('set CTE', 'Entry: 1, Txt: a, Grp: G');
        Observer.Expect('set ECT', 'Entry: 1, Txt: a, Grp: G');
        Observer.Expect('set DAE', 'Entry: 1, DecF: 2.5, Dt: 03/05/24');
        Observer.Expect('set BAD', 'DecF: 2.5, Dt: 03/05/24, Flag: Yes');
        Observer.Expect('set EIDTCAB', 'Entry: 1, IntF: 3, Txt: a, DecF: 2.5, Grp: G, Dt: 03/05/24, Flag: Yes');
        Observer.Expect('set BACTDIE', 'Entry: 1, IntF: 3, Txt: a, DecF: 2.5, Grp: G, Dt: 03/05/24, Flag: Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GetFilters_OrderByIsTheTextColumn()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "W7 Q Filters Text Order";
        Order: Text;
    begin
        foreach Order in Orders() do begin
            Clear(Q);
            ApplyTextOrder(Q, Order);
            Observer.Observe('set ' + Order, Q.GetFilters());
        end;
        Observer.Expect('set EIT', 'Entry: 1, IntF: 3, Txt: a');
        Observer.Expect('set ETI', 'Entry: 1, IntF: 3, Txt: a');
        Observer.Expect('set TEI', 'Entry: 1, IntF: 3, Txt: a');
        Observer.Expect('set TIE', 'Entry: 1, IntF: 3, Txt: a');
        Observer.Expect('set IET', 'Entry: 1, IntF: 3, Txt: a');
        Observer.Expect('set ITE', 'Entry: 1, IntF: 3, Txt: a');
        Observer.Expect('set TCE', 'Entry: 1, Txt: a, Grp: G');
        Observer.Expect('set CTE', 'Entry: 1, Txt: a, Grp: G');
        Observer.Expect('set ECT', 'Entry: 1, Txt: a, Grp: G');
        Observer.Expect('set DAE', 'Entry: 1, DecF: 2.5, Dt: 03/05/24');
        Observer.Expect('set BAD', 'DecF: 2.5, Dt: 03/05/24, Flag: Yes');
        Observer.Expect('set EIDTCAB', 'Entry: 1, IntF: 3, Txt: a, DecF: 2.5, Grp: G, Dt: 03/05/24, Flag: Yes');
        Observer.Expect('set BACTDIE', 'Entry: 1, IntF: 3, Txt: a, DecF: 2.5, Grp: G, Dt: 03/05/24, Flag: Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GetFilters_NoOrderBy()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "W7 Q Filters Plain";
        Order: Text;
    begin
        foreach Order in Orders() do begin
            Clear(Q);
            ApplyPlain(Q, Order);
            Observer.Observe('set ' + Order, Q.GetFilters());
        end;
        Observer.Expect('set EIT', 'Entry: 1, IntF: 3, Txt: a');
        Observer.Expect('set ETI', 'Entry: 1, IntF: 3, Txt: a');
        Observer.Expect('set TEI', 'Entry: 1, IntF: 3, Txt: a');
        Observer.Expect('set TIE', 'Entry: 1, IntF: 3, Txt: a');
        Observer.Expect('set IET', 'Entry: 1, IntF: 3, Txt: a');
        Observer.Expect('set ITE', 'Entry: 1, IntF: 3, Txt: a');
        Observer.Expect('set TCE', 'Entry: 1, Txt: a, Grp: G');
        Observer.Expect('set CTE', 'Entry: 1, Txt: a, Grp: G');
        Observer.Expect('set ECT', 'Entry: 1, Txt: a, Grp: G');
        Observer.Expect('set DAE', 'Entry: 1, DecF: 2.5, Dt: 03/05/24');
        Observer.Expect('set BAD', 'DecF: 2.5, Dt: 03/05/24, Flag: Yes');
        Observer.Expect('set EIDTCAB', 'Entry: 1, IntF: 3, Txt: a, DecF: 2.5, Grp: G, Dt: 03/05/24, Flag: Yes');
        Observer.Expect('set BACTDIE', 'Entry: 1, IntF: 3, Txt: a, DecF: 2.5, Grp: G, Dt: 03/05/24, Flag: Yes');
        Observer.Verify();
    end;

    [Test]
    procedure QueryMetadata_NormalQuery_ApiColumnsAreBlank()
    var
        Observer: Codeunit "Probe Observer";
        Meta: Record "Query Metadata";
    begin
        Observer.Observe('found', Format(Meta.Get(Query::"W7 Q Plain")));
        Observer.Observe('APIPublisher', Meta.APIPublisher);
        Observer.Observe('APIGroup', Meta.APIGroup);
        Observer.Observe('APIVersion', Meta.APIVersion);
        Observer.Observe('EntityName', Meta.EntityName);
        Observer.Observe('EntitySetName', Meta.EntitySetName);
        Observer.Observe('Name', Meta.Name);
        Observer.Observe('Caption', Meta.Caption);
        Observer.Expect('found', 'Yes');
        Observer.Expect('APIPublisher', '');
        Observer.Expect('APIGroup', '');
        Observer.Expect('APIVersion', 'beta');
        Observer.Expect('EntityName', '');
        Observer.Expect('EntitySetName', '');
        Observer.Expect('Name', 'W7 Q Plain');
        Observer.Expect('Caption', 'W7 Q Plain');
        Observer.Verify();
    end;
}
