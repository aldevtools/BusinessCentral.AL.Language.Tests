// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object-data-item-link
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), tables 70750 to 70752 of MixedLinkInnerLeft.al, queries 70760 to 70763, test codeunit 70764
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: three-level mixed DataItemLink with RightOuterJoin and FullOuterJoin on the leaf and on the middle level (risky: needs the tables of the first file)
// BC versions: 29 (27 and 28 by CI)

query 70760 "LT P100 Q InnerRightC"
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
                    SqlJoinType = RightOuterJoin;
                    column(CTag; Tag) { }
                }
            }
        }
    }
}

query 70761 "LT P100 Q InnerFullC"
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
                    SqlJoinType = FullOuterJoin;
                    column(CTag; Tag) { }
                }
            }
        }
    }
}

query 70762 "LT P100 Q RightInner"
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
                SqlJoinType = RightOuterJoin;
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

query 70763 "LT P100 Q FullLeft"
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
                SqlJoinType = FullOuterJoin;
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

codeunit 70764 "LT P100 Mixed Outer"
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
        A.Id := 1; A.Name := 'A1'; A.Insert();
        A.Id := 2; A.Name := 'A2'; A.Insert();
        A.Id := 3; A.Name := 'A3'; A.Insert();
        B.Id := 1; B.AId := 1; B.Tag := 'B1'; B.Insert();
        B.Id := 2; B.AId := 1; B.Tag := 'B2'; B.Insert();
        B.Id := 3; B.AId := 2; B.Tag := 'B3'; B.Insert();
        C.Id := 1; C.AId := 1; C.BId := 1; C.Tag := 'C1'; C.Insert();
        C.Id := 2; C.AId := 1; C.BId := 2; C.Tag := 'C2'; C.Insert();
        C.Id := 3; C.AId := 1; C.BId := 1; C.Tag := 'C3'; C.Insert();
        C.Id := 4; C.AId := 2; C.BId := 3; C.Tag := 'C4'; C.Insert();
        C.Id := 5; C.AId := 2; C.BId := 1; C.Tag := 'C5'; C.Insert();
        C.Id := 6; C.AId := 3; C.BId := 9; C.Tag := 'C6'; C.Insert();
    end;

    local procedure DumpInnerRightC(var Q: Query "LT P100 Q InnerRightC"): Text
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

    local procedure DumpInnerFullC(var Q: Query "LT P100 Q InnerFullC"): Text
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

    local procedure DumpRightInner(var Q: Query "LT P100 Q RightInner"): Text
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

    local procedure DumpFullLeft(var Q: Query "LT P100 Q FullLeft"): Text
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
    procedure P100_InnerRightC()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P100 Q InnerRightC";
    begin
        Seed();
        Observer.Observe('rows', DumpInnerRightC(Q));
        Observer.Expect('rows', '6://C5;//C6;A1/B1/C1;A1/B1/C3;A1/B2/C2;A2/B3/C4;');
        Observer.Verify();
    end;

    [Test]
    procedure P100_InnerFullC()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P100 Q InnerFullC";
    begin
        Seed();
        Observer.Observe('rows', DumpInnerFullC(Q));
        Observer.Expect('rows', '6://C5;//C6;A1/B1/C1;A1/B1/C3;A1/B2/C2;A2/B3/C4;');
        Observer.Verify();
    end;

    [Test]
    procedure P100_RightInner()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P100 Q RightInner";
    begin
        Seed();
        Observer.Observe('rows', DumpRightInner(Q));
        Observer.Expect('rows', '4:A1/B1/C1;A1/B1/C3;A1/B2/C2;A2/B3/C4;');
        Observer.Verify();
    end;

    [Test]
    procedure P100_FullLeft()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P100 Q FullLeft";
    begin
        Seed();
        Observer.Observe('rows', DumpFullLeft(Q));
        Observer.Expect('rows', '5:A1/B1/C1;A1/B1/C3;A1/B2/C2;A2/B3/C4;A3//;');
        Observer.Verify();
    end;
}
