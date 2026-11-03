// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained tables 71178, 71179 and 71180, queries 71181 and 71182, codeunit 71183
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles GitHub issue #69 (Inferred behaviors waiting for a pin): Query DataItemLink whose pairs name two different outer items
// Facts: a nested dataitem whose DataItemLink pairs refer to two different outer dataitems; inner and left outer join; pair order swapped
// BC versions: 29 (27 and 28 by CI)

table 71178 "LT P69 QA"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Code[10]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 71179 "LT P69 QB"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; AId; Integer) { }
        field(3; Tag; Code[10]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 71180 "LT P69 QC"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; AId; Integer) { }
        field(3; BId; Integer) { }
        field(4; Tag; Code[10]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

query 71181 "LT P69 Q Two Outers"
{
    QueryType = Normal;

    elements
    {
        dataitem(A; "LT P69 QA")
        {
            column(AId; Id) { }
            dataitem(B; "LT P69 QB")
            {
                DataItemLink = AId = A.Id;
                column(BId; Id) { }
                dataitem(C; "LT P69 QC")
                {
                    DataItemLink = AId = A.Id, BId = B.Id;
                    column(CId; Id) { }
                    column(CTag; Tag) { }
                }
            }
        }
    }
}

query 71182 "LT P69 Q Two Outers Left"
{
    QueryType = Normal;

    elements
    {
        dataitem(A; "LT P69 QA")
        {
            column(AId; Id) { }
            dataitem(B; "LT P69 QB")
            {
                DataItemLink = AId = A.Id;
                SqlJoinType = LeftOuterJoin;
                column(BId; Id) { }
                dataitem(C; "LT P69 QC")
                {
                    DataItemLink = BId = B.Id, AId = A.Id;
                    SqlJoinType = LeftOuterJoin;
                    column(CId; Id) { }
                    column(CTag; Tag) { }
                }
            }
        }
    }
}

codeunit 71183 "LT P69 Query Two Outers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        A: Record "LT P69 QA";
        B: Record "LT P69 QB";
        C: Record "LT P69 QC";
    begin
        A.DeleteAll();
        B.DeleteAll();
        C.DeleteAll();
        A.Id := 1;
        A.Insert();
        A.Id := 2;
        A.Insert();
        A.Id := 3;
        A.Insert();
        B.Id := 10;
        B.AId := 1;
        B.Insert();
        B.Id := 11;
        B.AId := 1;
        B.Insert();
        B.Id := 20;
        B.AId := 2;
        B.Insert();
        C.Id := 100;
        C.AId := 1;
        C.BId := 10;
        C.Tag := 'match';
        C.Insert();
        C.Id := 101;
        C.AId := 1;
        C.BId := 20;
        C.Tag := 'badB';
        C.Insert();
        C.Id := 102;
        C.AId := 2;
        C.BId := 10;
        C.Tag := 'badA';
        C.Insert();
        C.Id := 103;
        C.AId := 2;
        C.BId := 20;
        C.Tag := 'match2';
        C.Insert();
        C.Id := 104;
        C.AId := 1;
        C.BId := 11;
        C.Tag := 'second';
        C.Insert();
    end;

    [Test]
    procedure QueryLink_InnerJoin()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P69 Q Two Outers";
        Rows: Text;
        N: Integer;
    begin
        Seed();
        Q.Open();
        while Q.Read() do begin
            N += 1;
            Rows += Format(Q.AId) + '/' + Format(Q.BId) + '/' + Format(Q.CId) + '/' + Q.CTag + ';';
        end;
        Q.Close();
        Observer.Observe('count', Format(N));
        Observer.Observe('rows', Rows);
        Observer.Expect('count', '4');
        Observer.Expect('rows', '1/10/100/MATCH;1/11/104/SECOND;2/20/103/MATCH2;3/0/0/;');
        Observer.Verify();
    end;

    [Test]
    procedure QueryLink_LeftOuterJoin()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P69 Q Two Outers Left";
        Rows: Text;
        N: Integer;
    begin
        Seed();
        Q.Open();
        while Q.Read() do begin
            N += 1;
            Rows += Format(Q.AId) + '/' + Format(Q.BId) + '/' + Format(Q.CId) + '/' + Q.CTag + ';';
        end;
        Q.Close();
        Observer.Observe('count', Format(N));
        Observer.Observe('rows', Rows);
        Observer.Expect('count', '4');
        Observer.Expect('rows', '1/10/100/MATCH;1/11/104/SECOND;2/20/103/MATCH2;3/0/0/;');
        Observer.Verify();
    end;

    [Test]
    procedure QueryLink_FilteredColumns()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P69 Q Two Outers";
        Rows: Text;
    begin
        Seed();
        Q.SetRange(AId, 2);
        Q.Open();
        while Q.Read() do
            Rows += Format(Q.BId) + '/' + Format(Q.CId) + ';';
        Q.Close();
        Observer.Observe('a_is_2', Rows);
        Q.SetRange(AId);
        Q.SetFilter(CTag, 'match*');
        Q.Open();
        Rows := '';
        while Q.Read() do
            Rows += Format(Q.AId) + '/' + Format(Q.CId) + ';';
        Q.Close();
        Observer.Observe('tag_match', Rows);
        Observer.Expect('a_is_2', '20/103;');
        Observer.Expect('tag_match', '1/100;2/103;');
        Observer.Verify();
    end;
}
