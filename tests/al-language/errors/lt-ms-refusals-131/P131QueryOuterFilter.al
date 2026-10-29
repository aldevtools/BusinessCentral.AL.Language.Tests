// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained tables 73650..73652, queries 73653..73655, codeunit 73657
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a query whose nested (left outer, default and explicit) data item carries a static ColumnFilter on one of its columns: a
//        non-aggregated column (<> ''), a Count column with ColumnFilter > 0, a filter() element; with an aggregated parent. Rows read.
// BC versions: 29 (27 and 28 by CI)

table 73650 "LT P131 QHead"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Country; Code[10]) { }
        field(3; Amt; Decimal) { }
        field(4; Owner; Code[10]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 73651 "LT P131 QKid"
{
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Eu; Code[10]) { }
    }
    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 73652 "LT P131 QLine"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; HeadId; Integer) { }
        field(3; Status; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

query 73653 "LT P131 Q Country"
{
    OrderBy = ascending(CountryCode);

    elements
    {
        dataitem(Head; "LT P131 QHead")
        {
            column(CountryCode; Country) { }
            column(SumAmt; Amt)
            {
                Method = Sum;
            }
            dataitem(Kid; "LT P131 QKid")
            {
                DataItemLink = Code = Head.Country;
                column(EuCode; Eu)
                {
                    ColumnFilter = EuCode = filter(<> '');
                }
            }
        }
    }
}

query 73654 "LT P131 Q Country Left"
{
    OrderBy = ascending(CountryCode);

    elements
    {
        dataitem(Head; "LT P131 QHead")
        {
            column(CountryCode; Country) { }
            column(SumAmt; Amt)
            {
                Method = Sum;
            }
            dataitem(Kid; "LT P131 QKid")
            {
                DataItemLink = Code = Head.Country;
                SqlJoinType = LeftOuterJoin;
                column(EuCode; Eu)
                {
                    ColumnFilter = EuCode = filter(<> '');
                }
            }
        }
    }
}

query 73655 "LT P131 Q Lines"
{
    OrderBy = ascending(HeadId);

    elements
    {
        dataitem(Head; "LT P131 QHead")
        {
            filter(FilterOwner; Owner) { }
            column(HeadId; Id) { }
            dataitem(Line; "LT P131 QLine")
            {
                DataItemLink = HeadId = Head.Id;
                SqlJoinType = LeftOuterJoin;
                filter(FilterStatus; Status) { }
                column(LineStatus; Status) { }
                column(LineCount)
                {
                    Method = Count;
                    ColumnFilter = LineCount = filter(> 0);
                }
            }
        }
    }
}

codeunit 73657 "LT P131 Query Outer"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        H: Record "LT P131 QHead";
        K: Record "LT P131 QKid";
        L: Record "LT P131 QLine";
    begin
        H.DeleteAll();
        K.DeleteAll();
        L.DeleteAll();
        AddHead(1, 'DE', 10, 'U1');
        AddHead(2, 'DE', 5, 'U2');
        AddHead(3, 'XX', 7, 'U1');
        AddHead(4, 'FR', 3, 'U2');
        K.Code := 'DE';
        K.Eu := 'DE';
        K.Insert();
        K.Code := 'FR';
        K.Eu := '';
        K.Insert();
        AddLine(1, 1, 0);
        AddLine(2, 1, 1);
        AddLine(3, 2, 1);
        AddLine(4, 4, 2);
    end;

    local procedure AddHead(Id: Integer; Country: Code[10]; Amt: Decimal; Owner: Code[10])
    var
        H: Record "LT P131 QHead";
    begin
        H.Id := Id;
        H.Country := Country;
        H.Amt := Amt;
        H.Owner := Owner;
        H.Insert();
    end;

    local procedure AddLine(Id: Integer; HeadId: Integer; Status: Integer)
    var
        L: Record "LT P131 QLine";
    begin
        L.Id := Id;
        L.HeadId := HeadId;
        L.Status := Status;
        L.Insert();
    end;

    local procedure DumpCountry(var Q: Query "LT P131 Q Country"): Text
    var
        Result: Text;
    begin
        Q.Open();
        while Q.Read() do
            Result += '[' + Q.CountryCode + '/' + Format(Q.SumAmt) + '/' + Q.EuCode + ']';
        Q.Close();
        exit(Result);
    end;

    local procedure DumpCountryLeft(var Q: Query "LT P131 Q Country Left"): Text
    var
        Result: Text;
    begin
        Q.Open();
        while Q.Read() do
            Result += '[' + Q.CountryCode + '/' + Format(Q.SumAmt) + '/' + Q.EuCode + ']';
        Q.Close();
        exit(Result);
    end;

    local procedure DumpLines(var Q: Query "LT P131 Q Lines"): Text
    var
        Result: Text;
    begin
        Q.Open();
        while Q.Read() do
            Result += '[' + Format(Q.HeadId) + '/' + Format(Q.LineStatus) + '/' + Format(Q.LineCount) + ']';
        Q.Close();
        exit(Result);
    end;

    [Test]
    procedure P131_Query_ColumnFilterOnDefaultJoinChild()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P131 Q Country";
    begin
        Seed();
        Observer.Observe('rows', DumpCountry(Q));
        Clear(Q);
        Q.SetRange(CountryCode, 'DE');
        Observer.Observe('country DE', DumpCountry(Q));
        Clear(Q);
        Q.SetRange(CountryCode, 'XX');
        Observer.Observe('country XX', DumpCountry(Q));
        Clear(Q);
        Q.SetRange(CountryCode, 'FR');
        Observer.Observe('country FR', DumpCountry(Q));
        Observer.Expect('rows', '[DE/15/DE]');
        Observer.Expect('country DE', '[DE/15/DE]');
        Observer.Expect('country XX', '');
        Observer.Expect('country FR', '');
        Observer.Verify();
    end;

    [Test]
    procedure P131_Query_ColumnFilterOnExplicitLeftOuterChild()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P131 Q Country Left";
    begin
        Seed();
        Observer.Observe('rows', DumpCountryLeft(Q));
        Clear(Q);
        Q.SetRange(CountryCode, 'XX');
        Observer.Observe('country XX', DumpCountryLeft(Q));
        Clear(Q);
        Q.SetRange(CountryCode, 'FR');
        Observer.Observe('country FR', DumpCountryLeft(Q));
        Observer.Expect('rows', '[DE/15/DE]');
        Observer.Expect('country XX', '');
        Observer.Expect('country FR', '');
        Observer.Verify();
    end;

    [Test]
    procedure P131_Query_CountColumnFilterOnLeftOuterChild()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P131 Q Lines";
    begin
        Seed();
        Observer.Observe('rows', DumpLines(Q));
        Clear(Q);
        Q.SetRange(FilterOwner, 'U1');
        Observer.Observe('owner U1', DumpLines(Q));
        Clear(Q);
        Q.SetRange(FilterStatus, 1);
        Observer.Observe('status 1', DumpLines(Q));
        Clear(Q);
        Q.SetRange(FilterStatus, 9);
        Observer.Observe('status 9', DumpLines(Q));
        Clear(Q);
        Q.SetRange(FilterOwner, 'U2');
        Q.SetRange(FilterStatus, 2);
        Observer.Observe('owner U2 status 2', DumpLines(Q));
        Observer.Expect('rows', '[1/0/1][1/1/1][2/1/1][4/2/1]');
        Observer.Expect('owner U1', '[1/0/1][1/1/1]');
        Observer.Expect('status 1', '[1/1/1][2/1/1]');
        Observer.Expect('status 9', '');
        Observer.Expect('owner U2 status 2', '[4/2/1]');
        Observer.Verify();
    end;

    [Test]
    procedure UH_Query_ReadFilter_BeforeOpen()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P131 Q Lines";
        Txt: Text;
    begin
        Seed();
        ClearLastError();
        asserterror Txt := Format(Q.FilterOwner);
        Observer.Observe('before open', GetLastErrorText());
        Observer.Verify();
    end;

    [Test]
    procedure UH_Query_ReadFilter_OpenNoRead()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P131 Q Lines";
        Txt: Text;
    begin
        Seed();
        Q.SetRange(FilterOwner, 'U1');
        Q.Open();
        ClearLastError();
        asserterror Txt := Format(Q.FilterOwner);
        Observer.Observe('open no read', GetLastErrorText());
        Observer.Verify();
    end;

    [Test]
    procedure UH_Query_ReadFilter_AfterRead_Code()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P131 Q Lines";
        Txt: Text;
    begin
        Seed();
        Q.SetRange(FilterOwner, 'U1');
        Q.Open();
        Q.Read();
        ClearLastError();
        Observer.Observe('code after read', '[' + Format(Q.FilterOwner) + ']');
        Observer.Verify();
    end;

    [Test]
    procedure UH_Query_ReadFilter_AfterRead_Int()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P131 Q Lines";
        Txt: Text;
    begin
        Seed();
        Q.SetRange(FilterStatus, 1);
        Q.Open();
        Q.Read();
        ClearLastError();
        Observer.Observe('int after read', '[' + Format(Q.FilterStatus) + ']');
        Observer.Verify();
    end;

    [Test]
    procedure UH_Query_ReadFilter_GetFilter()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P131 Q Lines";
        Txt: Text;
    begin
        Seed();
        Q.SetRange(FilterOwner, 'U1');
        Observer.Observe('getfilter', '[' + Q.GetFilter(FilterOwner) + ']');
        Observer.Verify();
    end;
}
