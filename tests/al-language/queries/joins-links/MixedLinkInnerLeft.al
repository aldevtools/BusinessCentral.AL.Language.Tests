// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object-data-item-link
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own tables 70750 to 70752, queries 70753 to 70758, test codeunit 70759
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: three-level query A > B > C where the leaf DataItemLink names a field of the parent B and a field of the grandparent A in one link: rows, count and columns per SqlJoinType combination (Inner, LeftOuter)
// BC versions: 29 (27 and 28 by CI)

table 70750 "LT P100 A"
{
    DataClassification = SystemMetadata;
    fields { field(1; Id; Integer) { } field(2; Name; Code[10]) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

table 70751 "LT P100 B"
{
    DataClassification = SystemMetadata;
    fields { field(1; Id; Integer) { } field(2; AId; Integer) { } field(3; Tag; Code[10]) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

table 70752 "LT P100 C"
{
    DataClassification = SystemMetadata;
    fields { field(1; Id; Integer) { } field(2; AId; Integer) { } field(3; BId; Integer) { } field(4; Tag; Code[10]) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

query 70753 "LT P100 Q Inner"
{
    QueryType = Normal;
    OrderBy = ascending(AName), ascending(BTag), ascending(CTag);

    elements
    {
        dataitem(DA; "LT P100 A")
        {
            column(AName; Name) { }

            dataitem(DB; "LT P100 B")
            {
                DataItemLink = AId = DA.Id;
                SqlJoinType = InnerJoin;
                column(BTag; Tag) { }

                dataitem(DC; "LT P100 C")
                {
                    DataItemLink = AId = DA.Id, BId = DB.Id;
                    SqlJoinType = InnerJoin;
                    column(CTag; Tag) { }
                }
            }
        }
    }
}

query 70754 "LT P100 Q InnerLeftC"
{
    QueryType = Normal;
    OrderBy = ascending(AName), ascending(BTag), ascending(CTag);

    elements
    {
        dataitem(DA; "LT P100 A")
        {
            column(AName; Name) { }

            dataitem(DB; "LT P100 B")
            {
                DataItemLink = AId = DA.Id;
                SqlJoinType = InnerJoin;
                column(BTag; Tag) { }

                dataitem(DC; "LT P100 C")
                {
                    DataItemLink = AId = DA.Id, BId = DB.Id;
                    SqlJoinType = LeftOuterJoin;
                    column(CTag; Tag) { }
                }
            }
        }
    }
}

query 70755 "LT P100 Q LeftLeft"
{
    QueryType = Normal;
    OrderBy = ascending(AName), ascending(BTag), ascending(CTag);

    elements
    {
        dataitem(DA; "LT P100 A")
        {
            column(AName; Name) { }

            dataitem(DB; "LT P100 B")
            {
                DataItemLink = AId = DA.Id;
                SqlJoinType = LeftOuterJoin;
                column(BTag; Tag) { }

                dataitem(DC; "LT P100 C")
                {
                    DataItemLink = AId = DA.Id, BId = DB.Id;
                    SqlJoinType = LeftOuterJoin;
                    column(CTag; Tag) { }
                }
            }
        }
    }
}

query 70756 "LT P100 Q LeftInner"
{
    QueryType = Normal;
    OrderBy = ascending(AName), ascending(BTag), ascending(CTag);

    elements
    {
        dataitem(DA; "LT P100 A")
        {
            column(AName; Name) { }

            dataitem(DB; "LT P100 B")
            {
                DataItemLink = AId = DA.Id;
                SqlJoinType = LeftOuterJoin;
                column(BTag; Tag) { }

                dataitem(DC; "LT P100 C")
                {
                    DataItemLink = AId = DA.Id, BId = DB.Id;
                    SqlJoinType = InnerJoin;
                    column(CTag; Tag) { }
                }
            }
        }
    }
}

query 70757 "LT P100 Q GrandOnly"
{
    QueryType = Normal;
    OrderBy = ascending(AName), ascending(BTag), ascending(CTag);

    elements
    {
        dataitem(DA; "LT P100 A")
        {
            column(AName; Name) { }

            dataitem(DB; "LT P100 B")
            {
                DataItemLink = AId = DA.Id;
                SqlJoinType = InnerJoin;
                column(BTag; Tag) { }

                dataitem(DC; "LT P100 C")
                {
                    DataItemLink = AId = DA.Id;
                    SqlJoinType = InnerJoin;
                    column(CTag; Tag) { }
                }
            }
        }
    }
}

query 70758 "LT P100 Q Swapped"
{
    QueryType = Normal;
    OrderBy = ascending(AName), ascending(BTag), ascending(CTag);

    elements
    {
        dataitem(DA; "LT P100 A")
        {
            column(AName; Name) { }

            dataitem(DB; "LT P100 B")
            {
                DataItemLink = AId = DA.Id;
                SqlJoinType = InnerJoin;
                column(BTag; Tag) { }

                dataitem(DC; "LT P100 C")
                {
                    DataItemLink = BId = DB.Id, AId = DA.Id;
                    SqlJoinType = InnerJoin;
                    column(CTag; Tag) { }
                }
            }
        }
    }
}

codeunit 70759 "LT P100 Mixed Link"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        A: Record "LT P100 A";
        B: Record "LT P100 B";
        C: Record "LT P100 C";
    begin
        A.DeleteAll();
        B.DeleteAll();
        C.DeleteAll();
        AddA(1, 'A1');
        AddA(2, 'A2');
        AddA(3, 'A3');
        AddB(1, 1, 'B1');
        AddB(2, 1, 'B2');
        AddB(3, 2, 'B3');
        AddC(1, 1, 1, 'C1');
        AddC(2, 1, 2, 'C2');
        AddC(3, 1, 1, 'C3');
        AddC(4, 2, 3, 'C4');
        AddC(5, 2, 1, 'C5');
        AddC(6, 3, 9, 'C6');
    end;

    local procedure AddA(Id: Integer; Name: Code[10])
    var
        A: Record "LT P100 A";
    begin
        A.Id := Id;
        A.Name := Name;
        A.Insert();
    end;

    local procedure AddB(Id: Integer; AId: Integer; Tag: Code[10])
    var
        B: Record "LT P100 B";
    begin
        B.Id := Id;
        B.AId := AId;
        B.Tag := Tag;
        B.Insert();
    end;

    local procedure AddC(Id: Integer; AId: Integer; BId: Integer; Tag: Code[10])
    var
        C: Record "LT P100 C";
    begin
        C.Id := Id;
        C.AId := AId;
        C.BId := BId;
        C.Tag := Tag;
        C.Insert();
    end;

    local procedure DumpInner(var Q: Query "LT P100 Q Inner"): Text
    var
        Rows: Text;
        Cnt: Integer;
    begin
        Q.Open();
        while Q.Read() do begin
            Cnt += 1;
            Rows += Q.AName + '/' + Q.BTag + '/' + Q.CTag + ';';
        end;
        Q.Close();
        exit(Format(Cnt) + ':' + Rows);
    end;

    local procedure DumpInnerLeftC(var Q: Query "LT P100 Q InnerLeftC"): Text
    var
        Rows: Text;
        Cnt: Integer;
    begin
        Q.Open();
        while Q.Read() do begin
            Cnt += 1;
            Rows += Q.AName + '/' + Q.BTag + '/' + Q.CTag + ';';
        end;
        Q.Close();
        exit(Format(Cnt) + ':' + Rows);
    end;

    local procedure DumpLeftLeft(var Q: Query "LT P100 Q LeftLeft"): Text
    var
        Rows: Text;
        Cnt: Integer;
    begin
        Q.Open();
        while Q.Read() do begin
            Cnt += 1;
            Rows += Q.AName + '/' + Q.BTag + '/' + Q.CTag + ';';
        end;
        Q.Close();
        exit(Format(Cnt) + ':' + Rows);
    end;

    local procedure DumpLeftInner(var Q: Query "LT P100 Q LeftInner"): Text
    var
        Rows: Text;
        Cnt: Integer;
    begin
        Q.Open();
        while Q.Read() do begin
            Cnt += 1;
            Rows += Q.AName + '/' + Q.BTag + '/' + Q.CTag + ';';
        end;
        Q.Close();
        exit(Format(Cnt) + ':' + Rows);
    end;

    local procedure DumpGrandOnly(var Q: Query "LT P100 Q GrandOnly"): Text
    var
        Rows: Text;
        Cnt: Integer;
    begin
        Q.Open();
        while Q.Read() do begin
            Cnt += 1;
            Rows += Q.AName + '/' + Q.BTag + '/' + Q.CTag + ';';
        end;
        Q.Close();
        exit(Format(Cnt) + ':' + Rows);
    end;

    local procedure DumpSwapped(var Q: Query "LT P100 Q Swapped"): Text
    var
        Rows: Text;
        Cnt: Integer;
    begin
        Q.Open();
        while Q.Read() do begin
            Cnt += 1;
            Rows += Q.AName + '/' + Q.BTag + '/' + Q.CTag + ';';
        end;
        Q.Close();
        exit(Format(Cnt) + ':' + Rows);
    end;

    [Test]
    procedure P100_Inner()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P100 Q Inner";
    begin
        Seed();
        Observer.Observe('rows', DumpInner(Q));
        Observer.Expect('rows', '4:A1/B1/C1;A1/B1/C3;A1/B2/C2;A2/B3/C4;');
        Observer.Verify();
    end;

    [Test]
    procedure P100_InnerLeftC()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P100 Q InnerLeftC";
    begin
        Seed();
        Observer.Observe('rows', DumpInnerLeftC(Q));
        Observer.Expect('rows', '4:A1/B1/C1;A1/B1/C3;A1/B2/C2;A2/B3/C4;');
        Observer.Verify();
    end;

    [Test]
    procedure P100_LeftLeft()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P100 Q LeftLeft";
    begin
        Seed();
        Observer.Observe('rows', DumpLeftLeft(Q));
        Observer.Expect('rows', '5:A1/B1/C1;A1/B1/C3;A1/B2/C2;A2/B3/C4;A3//;');
        Observer.Verify();
    end;

    [Test]
    procedure P100_LeftInner()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P100 Q LeftInner";
    begin
        Seed();
        Observer.Observe('rows', DumpLeftInner(Q));
        Observer.Expect('rows', '4:A1/B1/C1;A1/B1/C3;A1/B2/C2;A2/B3/C4;');
        Observer.Verify();
    end;

    [Test]
    procedure P100_GrandOnly()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P100 Q GrandOnly";
    begin
        Seed();
        Observer.Observe('rows', DumpGrandOnly(Q));
        Observer.Expect('rows', '8:A1/B1/C1;A1/B1/C2;A1/B1/C3;A1/B2/C1;A1/B2/C2;A1/B2/C3;A2/B3/C4;A2/B3/C5;');
        Observer.Verify();
    end;

    [Test]
    procedure P100_Swapped()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P100 Q Swapped";
    begin
        Seed();
        Observer.Observe('rows', DumpSwapped(Q));
        Observer.Expect('rows', '4:A1/B1/C1;A1/B1/C3;A1/B2/C2;A2/B3/C4;');
        Observer.Verify();
    end;

    [Test]
    procedure P100_InnerReopen()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P100 Q Inner";
        First: Text;
    begin
        Seed();
        First := DumpInner(Q);
        Observer.Observe('first', First);
        Observer.Observe('second_same', Format(DumpInner(Q) = First));
        Observer.Expect('first', '4:A1/B1/C1;A1/B1/C3;A1/B2/C2;A2/B3/C4;');
        Observer.Expect('second_same', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P100_InnerColumnFilterOnA()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P100 Q Inner";
        Cnt: Integer;
        Rows: Text;
    begin
        Seed();
        Q.SetFilter(AName, 'A2');
        Q.Open();
        while Q.Read() do begin
            Cnt += 1;
            Rows += Q.AName + '/' + Q.BTag + '/' + Q.CTag + ';';
        end;
        Observer.Observe('count', Format(Cnt));
        Observer.Observe('rows', Rows);
        Observer.Expect('count', '1');
        Observer.Expect('rows', 'A2/B3/C4;');
        Observer.Verify();
    end;

    [Test]
    procedure P100_InnerColumnFilterOnC()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P100 Q Inner";
        Cnt: Integer;
        Rows: Text;
    begin
        Seed();
        Q.SetFilter(CTag, 'C1|C5');
        Q.Open();
        while Q.Read() do begin
            Cnt += 1;
            Rows += Q.AName + '/' + Q.BTag + '/' + Q.CTag + ';';
        end;
        Observer.Observe('count', Format(Cnt));
        Observer.Observe('rows', Rows);
        Observer.Expect('count', '1');
        Observer.Expect('rows', 'A1/B1/C1;');
        Observer.Verify();
    end;

    [Test]
    procedure P100_LeftLeftNoData()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P100 Q LeftLeft";
        C: Record "LT P100 C";
    begin
        Seed();
        C.DeleteAll();
        Observer.Observe('no_c', DumpLeftLeft(Q));
        Observer.Observe('no_c_inner', Format(C.Count()));
        Observer.Expect('no_c', '4:A1/B1/;A1/B2/;A2/B3/;A3//;');
        Observer.Expect('no_c_inner', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P100_InnerNoB()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P100 Q Inner";
        B: Record "LT P100 B";
    begin
        Seed();
        B.DeleteAll();
        Observer.Observe('no_b', DumpInner(Q));
        Observer.Expect('no_b', '0:');
        Observer.Verify();
    end;
}
