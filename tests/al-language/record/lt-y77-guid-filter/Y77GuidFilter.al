// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table 94100 and query 94101 in Y77GuidFilterObjects.al
// Probe (writer Y77): a Guid value passed as the filter argument (Microsoft role-center pages do Rec.SetFilter(Field, GuidValue)).
codeunit 94100 "LT Y77 Guid Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";

    local procedure G1(): Guid
    var
        V: Guid;
    begin
        Evaluate(V, '{1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d}');
        exit(V);
    end;

    local procedure G2(): Guid
    var
        V: Guid;
    begin
        Evaluate(V, '{aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee}');
        exit(V);
    end;

    local procedure Seed()
    var
        Row: Record "LT Y77 Row";
        Blank: Guid;
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 'A';
        Row.G := G1();
        Row.T := Format(G1());
        Row.C := Format(G1());
        Row.Insert();
        Row.Init();
        Row."No." := 'B';
        Row.G := G2();
        Row.T := Format(G2());
        Row.C := Format(G2());
        Row.Insert();
        Row.Init();
        Row."No." := 'C';
        Row.G := Blank;
        Row.T := '';
        Row.C := '';
        Row.Insert();
        Row.Init();
        Row."No." := 'D';
        Row.G := G1();
        Row.T := LowerCase(DelChr(Format(G1()), '=', '{}'));
        Row.C := UpperCase(DelChr(Format(G1()), '=', '{}'));
        Row.Insert();
    end;

    local procedure Names(var Row: Record "LT Y77 Row"): Text
    var
        R: Text;
    begin
        if Row.FindSet() then
            repeat
                R += Row."No.";
            until Row.Next() = 0;
        exit('[' + R + ']');
    end;

    local procedure Apply(var Row: Record "LT Y77 Row"; Mode: Integer; Fld: Integer; V: Guid)
    begin
        case Fld of
            1:
                case Mode of
                    1:
                        Row.SetFilter(G, V);
                    2:
                        Row.SetFilter(G, '%1', V);
                    3:
                        Row.SetRange(G, V);
                    4:
                        Row.SetRange(G, V, V);
                end;
            2:
                case Mode of
                    1:
                        Row.SetFilter(T, V);
                    2:
                        Row.SetFilter(T, '%1', V);
                    3:
                        Row.SetRange(T, V);
                    4:
                        Row.SetRange(T, V, V);
                end;
            3:
                case Mode of
                    1:
                        Row.SetFilter(C, V);
                    2:
                        Row.SetFilter(C, '%1', V);
                    3:
                        Row.SetRange(C, V);
                    4:
                        Row.SetRange(C, V, V);
                end;
        end;
    end;

    [TryFunction]
    local procedure TryApply(var Row: Record "LT Y77 Row"; Mode: Integer; Fld: Integer; V: Guid)
    begin
        Apply(Row, Mode, Fld, V);
    end;

    local procedure FieldFilter(var Row: Record "LT Y77 Row"; Fld: Integer): Text
    begin
        case Fld of
            1:
                exit(Row.GetFilter(G));
            2:
                exit(Row.GetFilter(T));
            3:
                exit(Row.GetFilter(C));
        end;
    end;

    local procedure RecordCase(Name: Text; Mode: Integer; Fld: Integer; V: Guid)
    var
        Row: Record "LT Y77 Row";
        Ok: Boolean;
    begin
        Ok := TryApply(Row, Mode, Fld, V);
        if not Ok then begin
            Obs.Observe(Name, 'ERR ' + GetLastErrorCode() + ' / ' + GetLastErrorText());
            ClearLastError();
            exit;
        end;
        Obs.Observe(Name, 'gf=' + FieldFilter(Row, Fld) + ' gfs=' + Row.GetFilters() + ' rows=' + Names(Row));
    end;

    local procedure RecordSurface(Fld: Integer; Tag: Text)
    var
        Blank: Guid;
    begin
        Seed();
        RecordCase(Tag + '_sf_g1', 1, Fld, G1());
        RecordCase(Tag + '_sf_blank', 1, Fld, Blank);
        RecordCase(Tag + '_sf1_g1', 2, Fld, G1());
        RecordCase(Tag + '_sf1_blank', 2, Fld, Blank);
        RecordCase(Tag + '_sr_g1', 3, Fld, G1());
        RecordCase(Tag + '_sr_blank', 3, Fld, Blank);
        RecordCase(Tag + '_sr2_g1', 4, Fld, G1());
        RecordCase(Tag + '_sr2_blank', 4, Fld, Blank);
    end;

    [Test]
    procedure Record_GuidField()
    begin
        RecordSurface(1, 'g');
        Obs.Expect('g_sf_g1', 'gf={1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} gfs=G: {1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} rows=[AD]');
        Obs.Expect('g_sf_blank', 'gf={00000000-0000-0000-0000-000000000000} gfs=G: {00000000-0000-0000-0000-000000000000} rows=[C]');
        Obs.Expect('g_sf1_g1', 'gf={1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} gfs=G: {1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} rows=[AD]');
        Obs.Expect('g_sf1_blank', 'gf={00000000-0000-0000-0000-000000000000} gfs=G: {00000000-0000-0000-0000-000000000000} rows=[C]');
        Obs.Expect('g_sr_g1', 'gf={1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} gfs=G: {1A2B');
        Obs.Verify();
    end;

    [Test]
    procedure Record_TextField()
    begin
        RecordSurface(2, 't');
        Obs.Expect('t_sf_g1', 'gf={1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} gfs=T: {1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} rows=[A]');
        Obs.Expect('t_sf_blank', 'gf={00000000-0000-0000-0000-000000000000} gfs=T: {00000000-0000-0000-0000-000000000000} rows=[]');
        Obs.Expect('t_sf1_g1', 'gf={1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} gfs=T: {1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} rows=[A]');
        Obs.Expect('t_sf1_blank', 'gf={00000000-0000-0000-0000-000000000000} gfs=T: {00000000-0000-0000-0000-000000000000} rows=[]');
        Obs.Expect('t_sr_g1', 'gf={1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} gfs=T: {1A2B3C4D');
        Obs.Verify();
    end;

    [Test]
    procedure Record_CodeField()
    begin
        RecordSurface(3, 'c');
        Obs.Expect('c_sf_g1', 'gf={1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} gfs=C: {1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} rows=[A]');
        Obs.Expect('c_sf_blank', 'gf={00000000-0000-0000-0000-000000000000} gfs=C: {00000000-0000-0000-0000-000000000000} rows=[]');
        Obs.Expect('c_sf1_g1', 'gf={1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} gfs=C: {1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} rows=[A]');
        Obs.Expect('c_sf1_blank', 'gf={00000000-0000-0000-0000-000000000000} gfs=C: {00000000-0000-0000-0000-000000000000} rows=[]');
        Obs.Expect('c_sr_g1', 'gf={1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} gfs=C: {1A2B3C4D');
        Obs.Verify();
    end;

    // ---- Query
    local procedure QNames(var Q: Query "LT Y77 Query"): Text
    var
        R: Text;
    begin
        if Q.Open() then begin
            while Q.Read() do
                R += Q.No;
            Q.Close();
        end;
        exit('[' + R + ']');
    end;

    [TryFunction]
    local procedure TryQuery(Mode: Integer; Fld: Integer; V: Guid; var Result: Text)
    var
        Q: Query "LT Y77 Query";
    begin
        case Fld of
            1:
                case Mode of
                    1:
                        Q.SetFilter(G, V);
                    2:
                        Q.SetFilter(G, '%1', V);
                    3:
                        Q.SetRange(G, V);
                end;
            2:
                case Mode of
                    1:
                        Q.SetFilter(T, V);
                    2:
                        Q.SetFilter(T, '%1', V);
                    3:
                        Q.SetRange(T, V);
                end;
            3:
                case Mode of
                    1:
                        Q.SetFilter(C, V);
                    2:
                        Q.SetFilter(C, '%1', V);
                    3:
                        Q.SetRange(C, V);
                end;
        end;
        Result := 'rows=' + QNames(Q);
    end;

    local procedure QueryCase(Name: Text; Mode: Integer; Fld: Integer; V: Guid)
    var
        Result: Text;
    begin
        if TryQuery(Mode, Fld, V, Result) then
            Obs.Observe(Name, Result)
        else begin
            Obs.Observe(Name, 'ERR ' + GetLastErrorCode() + ' / ' + GetLastErrorText());
            ClearLastError();
        end;
    end;

    local procedure QuerySurface(Fld: Integer; Tag: Text)
    var
        Blank: Guid;
    begin
        Seed();
        QueryCase(Tag + '_sf_g1', 1, Fld, G1());
        QueryCase(Tag + '_sf_blank', 1, Fld, Blank);
        QueryCase(Tag + '_sf1_g1', 2, Fld, G1());
        QueryCase(Tag + '_sf1_blank', 2, Fld, Blank);
        QueryCase(Tag + '_sr_g1', 3, Fld, G1());
        QueryCase(Tag + '_sr_blank', 3, Fld, Blank);
    end;

    [Test]
    procedure Query_GuidColumn()
    begin
        QuerySurface(1, 'qg');
        Obs.Expect('qg_sf_g1', 'rows=[AD]');
        Obs.Expect('qg_sf_blank', 'rows=[C]');
        Obs.Expect('qg_sf1_g1', 'rows=[AD]');
        Obs.Expect('qg_sf1_blank', 'rows=[C]');
        Obs.Expect('qg_sr_g1', 'rows=[AD]');
        Obs.Expect('qg_sr_blank', 'rows=[C]');
        Obs.Verify();
    end;

    [Test]
    procedure Query_TextColumn()
    begin
        QuerySurface(2, 'qt');
        Obs.Expect('qt_sf_g1', 'rows=[A]');
        Obs.Expect('qt_sf_blank', 'rows=[]');
        Obs.Expect('qt_sf1_g1', 'rows=[A]');
        Obs.Expect('qt_sf1_blank', 'rows=[]');
        Obs.Expect('qt_sr_g1', 'rows=[A]');
        Obs.Expect('qt_sr_blank', 'rows=[]');
        Obs.Verify();
    end;

    [Test]
    procedure Query_CodeColumn()
    begin
        QuerySurface(3, 'qc');
        Obs.Expect('qc_sf_g1', 'rows=[A]');
        Obs.Expect('qc_sf_blank', 'rows=[]');
        Obs.Expect('qc_sf1_g1', 'rows=[A]');
        Obs.Expect('qc_sf1_blank', 'rows=[]');
        Obs.Expect('qc_sr_g1', 'rows=[A]');
        Obs.Expect('qc_sr_blank', 'rows=[]');
        Obs.Verify();
    end;

    // ---- FieldRef
    [TryFunction]
    local procedure TryFieldRef(Mode: Integer; Fld: Integer; V: Guid; var Result: Text)
    var
        Row: Record "LT Y77 Row";
        RRef: RecordRef;
        FRef: FieldRef;
        R: Text;
    begin
        RRef.GetTable(Row);
        FRef := RRef.Field(Fld + 1);
        case Mode of
            1:
                FRef.SetFilter(V);
            2:
                FRef.SetFilter('%1', V);
            3:
                FRef.SetRange(V);
            4:
                FRef.SetRange(V, V);
        end;
        if RRef.FindSet() then
            repeat
                R += Format(RRef.Field(1).Value);
            until RRef.Next() = 0;
        Result := 'gf=' + FRef.GetFilter() + ' rows=[' + R + ']';
    end;

    local procedure FieldRefCase(Name: Text; Mode: Integer; Fld: Integer; V: Guid)
    var
        Result: Text;
    begin
        if TryFieldRef(Mode, Fld, V, Result) then
            Obs.Observe(Name, Result)
        else begin
            Obs.Observe(Name, 'ERR ' + GetLastErrorCode() + ' / ' + GetLastErrorText());
            ClearLastError();
        end;
    end;

    local procedure FieldRefSurface(Fld: Integer; Tag: Text)
    var
        Blank: Guid;
    begin
        Seed();
        FieldRefCase(Tag + '_sf_g1', 1, Fld, G1());
        FieldRefCase(Tag + '_sf_blank', 1, Fld, Blank);
        FieldRefCase(Tag + '_sf1_g1', 2, Fld, G1());
        FieldRefCase(Tag + '_sf1_blank', 2, Fld, Blank);
        FieldRefCase(Tag + '_sr_g1', 3, Fld, G1());
        FieldRefCase(Tag + '_sr_blank', 3, Fld, Blank);
        FieldRefCase(Tag + '_sr2_g1', 4, Fld, G1());
        FieldRefCase(Tag + '_sr2_blank', 4, Fld, Blank);
    end;

    [Test]
    procedure FieldRef_GuidField()
    begin
        FieldRefSurface(1, 'fg');
        Obs.Expect('fg_sf_g1', 'gf={1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} rows=[AD]');
        Obs.Expect('fg_sf_blank', 'gf={00000000-0000-0000-0000-000000000000} rows=[C]');
        Obs.Expect('fg_sf1_g1', 'gf={1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} rows=[AD]');
        Obs.Expect('fg_sf1_blank', 'gf={00000000-0000-0000-0000-000000000000} rows=[C]');
        Obs.Expect('fg_sr_g1', 'gf={1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} rows=[AD]');
        Obs.Expect('fg_sr_blank', 'gf={00000000-0000-0000-0000-000000000000} rows=[C]');
        Obs.Expect('fg_sr2_g1', 'gf={1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} rows=[AD]');
        Obs.Expect('fg_sr2_blank', 'gf={00000000-0000-0000-0000-000000000000} r');
        Obs.Verify();
    end;

    [Test]
    procedure FieldRef_TextField()
    begin
        FieldRefSurface(2, 'ft');
        Obs.Expect('ft_sf_g1', 'gf={1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} rows=[A]');
        Obs.Expect('ft_sf_blank', 'gf={00000000-0000-0000-0000-000000000000} rows=[]');
        Obs.Expect('ft_sf1_g1', 'gf={1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} rows=[A]');
        Obs.Expect('ft_sf1_blank', 'gf={00000000-0000-0000-0000-000000000000} rows=[]');
        Obs.Expect('ft_sr_g1', 'gf={1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} rows=[A]');
        Obs.Expect('ft_sr_blank', 'gf={00000000-0000-0000-0000-000000000000} rows=[]');
        Obs.Expect('ft_sr2_g1', 'gf={1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} rows=[A]');
        Obs.Expect('ft_sr2_blank', 'gf={00000000-0000-0000-0000-000000000000} rows=[]');
        Obs.Verify();
    end;

    [Test]
    procedure FieldRef_CodeField()
    begin
        FieldRefSurface(3, 'fc');
        Obs.Expect('fc_sf_g1', 'gf={1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} rows=[A]');
        Obs.Expect('fc_sf_blank', 'gf={00000000-0000-0000-0000-000000000000} rows=[]');
        Obs.Expect('fc_sf1_g1', 'gf={1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} rows=[A]');
        Obs.Expect('fc_sf1_blank', 'gf={00000000-0000-0000-0000-000000000000} rows=[]');
        Obs.Expect('fc_sr_g1', 'gf={1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} rows=[A]');
        Obs.Expect('fc_sr_blank', 'gf={00000000-0000-0000-0000-000000000000} rows=[]');
        Obs.Expect('fc_sr2_g1', 'gf={1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} rows=[A]');
        Obs.Expect('fc_sr2_blank', 'gf={00000000-0000-0000-0000-000000000000} rows=[]');
        Obs.Verify();
    end;

    // ---- More Record shapes: two Guids, a Guid in a longer expression, a Guid next to a filter operator
    [TryFunction]
    local procedure TryShape(Shape: Integer; var Result: Text)
    var
        Row: Record "LT Y77 Row";
    begin
        case Shape of
            1:
                begin
                    Row.SetFilter(G, '%1|%2', G1(), G2());
                    Result := Row.GetFilter(G) + ' ' + Names(Row);
                end;
            2:
                begin
                    Row.SetFilter(G, '<>%1', G1());
                    Result := Row.GetFilter(G) + ' ' + Names(Row);
                end;
            3:
                begin
                    Row.SetFilter(T, '@%1', G1());
                    Result := Row.GetFilter(T) + ' ' + Names(Row);
                end;
            4:
                begin
                    Row.SetFilter(T, '@' + G1());
                    Result := Row.GetFilter(T) + ' ' + Names(Row);
                end;
            5:
                begin
                    Row.SetFilter(G, '@' + G1());
                    Result := Row.GetFilter(G) + ' ' + Names(Row);
                end;
            6:
                begin
                    Row.SetFilter(G, '<>' + G1());
                    Result := Row.GetFilter(G) + ' ' + Names(Row);
                end;
            7:
                begin
                    Row.SetFilter(C, G1(), G2());
                    Result := Row.GetFilter(C) + ' ' + Names(Row);
                end;
            8:
                begin
                    Row.SetFilter(G, DelChr(Format(G1()), '=', '{}'));
                    Result := Row.GetFilter(G) + ' ' + Names(Row);
                end;
            9:
                begin
                    Row.SetFilter(T, DelChr(Format(G1()), '=', '{}'));
                    Result := Row.GetFilter(T) + ' ' + Names(Row);
                end;
            10:
                begin
                    Row.SetFilter(T, '@' + DelChr(Format(G1()), '=', '{}'));
                    Result := Row.GetFilter(T) + ' ' + Names(Row);
                end;
            11:
                begin
                    Row.SetFilter(C, '%1', DelChr(Format(G1()), '=', '{}'));
                    Result := Row.GetFilter(C) + ' ' + Names(Row);
                end;
            12:
                begin
                    Row.SetFilter(T, '@%1', Format(G1()));
                    Result := Row.GetFilter(T) + ' ' + Names(Row);
                end;
        end;
    end;

    local procedure Shapes(FromShape: Integer; ToShape: Integer)
    var
        Shape: Integer;
        Result: Text;
    begin
        Seed();
        for Shape := FromShape to ToShape do begin
            Result := '';
            if TryShape(Shape, Result) then
                Obs.Observe('shape' + Format(Shape), Result)
            else begin
                Obs.Observe('shape' + Format(Shape), 'ERR ' + GetLastErrorCode() + ' / ' + GetLastErrorText());
                ClearLastError();
            end;
        end;
    end;

    [Test]
    procedure Record_Shapes1To4()
    begin
        Shapes(1, 4);
        Obs.Expect('shape1', '{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D}|{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE} [ABD]');
        Obs.Expect('shape2', '<>{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} [BC]');
        Obs.Expect('shape3', '@%1 []');
        Obs.Expect('shape4', '@{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} [A]');
        Obs.Verify();
    end;

    [Test]
    procedure Record_Shapes5To6()
    begin
        Shapes(5, 6);
        Obs.Expect('shape5', 'ERR Filter:CSide / The filter "@{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D}" is not valid for the G field on the LT Y77 Row table. Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Obs.Expect('shape6', '<>{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} [BC]');
        Obs.Verify();
    end;

    [Test]
    procedure Record_Shapes7To9()
    begin
        Shapes(7, 9);
        Obs.Expect('shape7', '{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} [A]');
        Obs.Expect('shape8', '{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D} [AD]');
        Obs.Expect('shape9', '1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D []');
        Obs.Verify();
    end;

    [Test]
    procedure Record_Shapes10To12()
    begin
        Shapes(10, 12);
        Obs.Expect('shape10', '@1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D [D]');
        Obs.Expect('shape11', '1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D [D]');
        Obs.Expect('shape12', '@%1 []');
        Obs.Verify();
    end;

    // ---- Topic 2: a text filter on a DateFormula field (Y70Probes FilterDateFormula_EmptyText pins only the code Filter:CSide)
    [TryFunction]
    local procedure TryDateFormulaFilter(Mode: Integer; FilterText: Text)
    var
        Row: Record "LT Y77 Row";
        RRef: RecordRef;
        FRef: FieldRef;
    begin
        case Mode of
            1:
                Row.SetFilter(DF, FilterText);
            3:
                begin
                    RRef.GetTable(Row);
                    FRef := RRef.Field(5);
                    FRef.SetFilter(FilterText);
                end;
        end;
    end;

    local procedure DateFormulaCase(Name: Text; Mode: Integer; FilterText: Text)
    begin
        if TryDateFormulaFilter(Mode, FilterText) then
            Obs.Observe(Name, 'ok')
        else begin
            Obs.Observe(Name, 'ERR ' + GetLastErrorCode() + ' / ' + GetLastErrorText());
            ClearLastError();
        end;
    end;

    [Test]
    procedure DateFormula_TextFilter_SetFilter()
    begin
        DateFormulaCase('sf_1M', 1, '<1M>');
        DateFormulaCase('sf_neg', 1, '<-CM+2D>');
        Obs.Expect('sf_1M', 'ERR Filter:CSide / The filter "<1M>" is not valid for the DF field on the LT Y77 Row table. An error occurred while interpreting the filter: Did not expect ''>''.\\For more information, see https://go.microsoft.com/fwlink/?linkid=2158058.');
        Obs.Expect('sf_neg', 'ERR Filter:CSide / The filter "<-CM+2D>" is not valid for the DF field on the LT Y77 Row table. An error occurred while interpreting the filter: Did not expect ''>''.\\For more information, see https://go.microsoft.com/fwlink/?linkid=2158058.');
        Obs.Verify();
    end;

    [Test]
    procedure DateFormula_TextFilter_SetFilterOther()
    begin
        DateFormulaCase('sf_plain', 1, 'abc');
        DateFormulaCase('sf_empty', 1, '');
        Obs.Expect('sf_plain', 'ERR Filter:CSide / The filter "abc" is not valid for the DF field on the LT Y77 Row table. The date formula ''ABC'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.');
        Obs.Expect('sf_empty', 'ok');
        Obs.Verify();
    end;

    [Test]
    procedure DateFormula_TextFilter_FieldRef()
    begin
        DateFormulaCase('fr_1M', 3, '<1M>');
        Obs.Expect('fr_1M', 'ERR Filter:CSide / The filter "<1M>" is not valid for the DF field on the LT Y77 Row table. An error occurred while interpreting the filter: Did not expect ''>''.\\For more information, see https://go.microsoft.com/fwlink/?linkid=2158058.');
        Obs.Verify();
    end;

    [Test]
    procedure DateFormula_TextFilter_FieldRefPlain()
    begin
        DateFormulaCase('fr_plain', 3, 'abc');
        Obs.Expect('fr_plain', 'ERR Filter:CSide / The filter "abc" is not valid for the DF field on the LT Y77 Row table. The date formula ''ABC'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.');
        Obs.Verify();
    end;
}
