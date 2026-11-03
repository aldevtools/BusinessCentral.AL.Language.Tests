// Probe writer-c, round 2: "Query" open points of docs/probes-needed.md (table globals section, Query row). Observe-only.
//  - SqlJoinType = CrossJoin with a DataItemLink: settled by the compiler (AL0365), no runtime probe
//  - DataItemTableFilter forms other than filter('>=2')
//  - several grouped columns with no OrderBy: the output order when the grouping columns do / do not start with the root key
// Fixtures: tables 69753 / 69754 / 69755, queries 69756..69759, codeunit 69760.

table 69753 "PW Q A"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 69754 "PW Q B"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; AId; Integer) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 69755 "PW Q G"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp1; Integer) { }
        field(3; Grp2; Code[10]) { }
        field(4; Amt; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// query 69756 (CrossJoin with DataItemLink) does not compile: AL0365 "The property 'DataItemLink' cannot be set if the property 'SqlJoinType' is set to 'CrossJoin'".

query 69757 "PW Q Groups Non Key"
{
    QueryType = Normal;

    elements
    {
        dataitem(G; "PW Q G")
        {
            column(Grp2; Grp2) { }
            column(Grp1; Grp1) { }
            column(SumAmt; Amt) { Method = Sum; }
        }
    }
}

query 69758 "PW Q Groups Key First"
{
    QueryType = Normal;

    elements
    {
        dataitem(G; "PW Q G")
        {
            column(Id; Id) { }
            column(Grp2; Grp2) { }
            column(SumAmt; Amt) { Method = Sum; }
        }
    }
}

query 69759 "PW Q Table Filter Forms"
{
    QueryType = Normal;

    elements
    {
        dataitem(A; "PW Q A")
        {
            column(Id; Id) { }
            column(Name; Name) { }
        }
    }
}

codeunit 69760 "PW Query Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        A: Record "PW Q A";
        B: Record "PW Q B";
        G: Record "PW Q G";
    begin
        A.DeleteAll();
        B.DeleteAll();
        G.DeleteAll();
        AddA(1, 'alpha');
        AddA(2, 'beta');
        AddA(3, 'Gamma');
        AddA(4, 'a*b');
        AddB('X', 1);
        AddB('Y', 3);
        AddB('Z', 9);
        AddG(1, 2, 'B', 10);
        AddG(2, 1, 'A', 20);
        AddG(3, 2, 'B', 30);
        AddG(4, 1, 'C', 40);
        AddG(5, 2, 'A', 50);
        AddG(6, 1, 'A', 60);
    end;

    local procedure AddA(Id: Integer; Name: Text)
    var
        A: Record "PW Q A";
    begin
        A.Id := Id;
        A.Name := CopyStr(Name, 1, MaxStrLen(A.Name));
        A.Insert();
    end;

    local procedure AddB(Code: Code[10]; AId: Integer)
    var
        B: Record "PW Q B";
    begin
        B.Code := Code;
        B.AId := AId;
        B.Insert();
    end;

    local procedure AddG(Id: Integer; Grp1: Integer; Grp2: Code[10]; Amt: Decimal)
    var
        G: Record "PW Q G";
    begin
        G.Id := Id;
        G.Grp1 := Grp1;
        G.Grp2 := Grp2;
        G.Amt := Amt;
        G.Insert();
    end;

    [Test]
    procedure Groups_NoOrderBy_GroupColumnsDoNotStartWithKey()
    var
        Qry: Query "PW Q Groups Non Key";
        Result: Text;
    begin
        Seed();
        Qry.Open();
        while Qry.Read() do
            Result += StrSubstNo('[%1 %2 sum=%3] ', Qry.Grp2, Qry.Grp1, Qry.SumAmt);
        Qry.Close();
        Observer.Observe('rows', Result);
        Observer.Expect('rows', '[A 1 sum=80] [A 2 sum=50] [B 2 sum=40] [C 1 sum=40] ');
        Observer.Verify();
    end;

    [Test]
    procedure Groups_NoOrderBy_GroupColumnsStartWithKey()
    var
        Qry: Query "PW Q Groups Key First";
        Result: Text;
    begin
        Seed();
        Qry.Open();
        while Qry.Read() do
            Result += StrSubstNo('[%1 %2 sum=%3] ', Qry.Id, Qry.Grp2, Qry.SumAmt);
        Qry.Close();
        Observer.Observe('rows', Result);
        Observer.Expect('rows', '[1 B sum=10] [2 A sum=20] [3 B sum=30] [4 C sum=40] [5 A sum=50] [6 A sum=60] ');
        Observer.Verify();
    end;

    local procedure RunWithFilter(FilterText: Text; ColumnIsName: Boolean): Text
    var
        Qry: Query "PW Q Table Filter Forms";
        Result: Text;
    begin
        if ColumnIsName then
            Qry.SetFilter(Name, FilterText)
        else
            Qry.SetFilter(Id, FilterText);
        Qry.Open();
        while Qry.Read() do
            Result += StrSubstNo('%1 ', Qry.Id);
        Qry.Close();
        exit(Result);
    end;

    [Test]
    procedure QueryFilter_IntegerFilterForms()
    begin
        Seed();
        Observer.Observe('id_ge_2', RunWithFilter('>=2', false));
        Observer.Observe('id_1_or_3', RunWithFilter('1|3', false));
        Observer.Observe('id_ne_2', RunWithFilter('<>2', false));
        Observer.Observe('id_range_2_3', RunWithFilter('2..3', false));
        Observer.Observe('id_lt_3_and_ne_1', RunWithFilter('<3&<>1', false));
        Observer.Expect('id_ge_2', '2 3 4 ');
        Observer.Expect('id_1_or_3', '1 3 ');
        Observer.Expect('id_ne_2', '1 3 4 ');
        Observer.Expect('id_range_2_3', '2 3 ');
        Observer.Expect('id_lt_3_and_ne_1', '2 ');
        Observer.Verify();
    end;

    [Test]
    procedure QueryFilter_TextFilterForms()
    begin
        Seed();
        Observer.Observe('name_a_star', RunWithFilter('a*', true));
        Observer.Observe('name_at_gamma_ignore_case', RunWithFilter('@gamma', true));
        Observer.Observe('name_literal_star', RunWithFilter('''a*b''', true));
        Observer.Observe('name_gamma_exact_case', RunWithFilter('gamma', true));
        Observer.Expect('name_a_star', '1 4 ');
        Observer.Expect('name_at_gamma_ignore_case', '3 ');
        Observer.Expect('name_literal_star', '4 ');
        Observer.Expect('name_gamma_exact_case', '');
        Observer.Verify();
    end;

    [Test]
    procedure QueryFilter_SetRange_ThenGetFilters()
    var
        Qry: Query "PW Q Table Filter Forms";
    begin
        Seed();
        Qry.SetFilter(Id, '>=2');
        Observer.Observe('getfilters_ge_2', Qry.GetFilters());
        Qry.SetRange(Name, 'beta');
        Observer.Observe('getfilters_with_name', Qry.GetFilters());
        Observer.Expect('getfilters_ge_2', 'Id: >=2');
        Observer.Expect('getfilters_with_name', 'Id: >=2, Name: beta');
        Observer.Verify();
    end;
}
