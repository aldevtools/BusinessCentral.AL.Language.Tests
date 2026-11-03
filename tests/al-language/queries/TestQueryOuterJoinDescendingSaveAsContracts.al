// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: ALT Parent (60004), ALT Child (60005), ALT Universal (60000), ALTFixtureCleanup (60019),
//                shared Assert (60021); self-contained queries 68250..68254, codeunit 68255
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins ties under a descending OrderBy (the primary key still ascends), left outer joins (unmatched
// parents come back with blank child columns, a filter on an outer-joined column drops them unless the
// filter admits blank/0, aggregates over the join), SaveAsXml and SaveAsJson output, and that a row
// inserted after Open and before the first Read is read.
//
// Compile-time facts (no test possible, the AL compiler rejects them): two data items at the same level
// (AL0342, "unions are not supported"), Sum/Average/Min/Max on anything but Decimal, BigInteger, Integer
// and Duration columns (AL0347), a Count column with a data source (AL0353).
// BC versions: 27.5

query 68250 "Probe Q Desc"
{
    QueryType = Normal;
    OrderBy = descending(IntV);

    elements
    {
        dataitem(U; "ALT Universal")
        {
            column(IntV; "Integer Field") { }
            column(Entry; "Entry No.") { }
        }
    }
}

query 68251 "Probe Q Group Desc"
{
    QueryType = Normal;
    OrderBy = descending(Grp);

    elements
    {
        dataitem(U; "ALT Universal")
        {
            column(Grp; "Integer Field") { }
            column(Cnt) { Method = Count; }
            column(Mx; "Entry No.") { Method = Max; }
        }
    }
}

query 68252 "Probe Q Outer"
{
    QueryType = Normal;
    OrderBy = ascending(PNo);

    elements
    {
        dataitem(P; "ALT Parent")
        {
            column(PNo; "Entry No.") { }

            dataitem(C; "ALT Child")
            {
                DataItemLink = "Parent Entry No." = P."Entry No.";
                SqlJoinType = LeftOuterJoin;

                column(CNo; "Entry No.") { }
                column(CAmt; Amount) { }
            }
        }
    }
}

query 68253 "Probe Q Outer Sum"
{
    QueryType = Normal;
    OrderBy = ascending(PNo);

    elements
    {
        dataitem(P; "ALT Parent")
        {
            column(PNo; "Entry No.") { }

            dataitem(C; "ALT Child")
            {
                DataItemLink = "Parent Entry No." = P."Entry No.";
                SqlJoinType = LeftOuterJoin;

                column(SumAmt; Amount) { Method = Sum; }
                column(CntC) { Method = Count; }
            }
        }
    }
}

query 68254 "Probe Q Sum Int"
{
    QueryType = Normal;

    elements
    {
        dataitem(U; "ALT Universal")
        {
            column(SumI; "Integer Field") { Method = Sum; }
        }
    }
}

codeunit 68255 "Probe Query Outer Desc SaveAs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    var
        ALTParent: Record "ALT Parent";
        ALTChild: Record "ALT Child";
        ALTUniversal: Record "ALT Universal";
    begin
        Cleanup.Initialize();
        ALTParent.Init();
        ALTParent."Entry No." := 1;
        ALTParent.Insert();
        ALTParent."Entry No." := 2;
        ALTParent.Insert();
        ALTParent."Entry No." := 3;
        ALTParent.Insert();
        ALTChild.Init();
        ALTChild."Entry No." := 10;
        ALTChild."Parent Entry No." := 1;
        ALTChild.Amount := 5;
        ALTChild.Insert();
        ALTChild."Entry No." := 11;
        ALTChild.Amount := 7;
        ALTChild.Insert();
        ALTChild."Entry No." := 12;
        ALTChild."Parent Entry No." := 3;
        ALTChild.Amount := 1;
        ALTChild.Insert();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 1;
        ALTUniversal."Integer Field" := 2;
        ALTUniversal.Insert();
        ALTUniversal."Entry No." := 2;
        ALTUniversal."Integer Field" := 1;
        ALTUniversal.Insert();
        ALTUniversal."Entry No." := 3;
        ALTUniversal."Integer Field" := 2;
        ALTUniversal.Insert();
        ALTUniversal."Entry No." := 4;
        ALTUniversal."Integer Field" := 1;
        ALTUniversal.Insert();
        Commit();
    end;

    [Test]
    procedure Query_DescendingOrderBy_TiesStayInAscendingPrimaryKeyOrder()
    var
        Q: Query "Probe Q Desc";
        G: Query "Probe Q Group Desc";
        Rows: Text;
    begin
        Initialize();

        Q.Open();
        while Q.Read() do
            Rows += Format(Q.IntV) + '/' + Format(Q.Entry) + ' ';
        Q.Close();
        Assert.AreEqual('2/1 2/3 1/2 1/4 ', Rows, 'ties');

        Rows := '';
        G.Open();
        while G.Read() do
            Rows += Format(G.Grp) + 'x' + Format(G.Cnt) + 'max' + Format(G.Mx) + ' ';
        G.Close();
        Assert.AreEqual('2x2max3 1x2max4 ', Rows, 'groups descending');
    end;

    [Test]
    procedure Query_LeftOuterJoin_RowsFiltersAndAggregates()
    var
        Q: Query "Probe Q Outer";
        Sums: Query "Probe Q Outer Sum";
        Rows: Text;
    begin
        Initialize();

        Q.Open();
        while Q.Read() do
            Rows += Format(Q.PNo) + '/' + Format(Q.CNo) + '/' + Format(Q.CAmt) + ' ';
        Q.Close();
        Assert.AreEqual('1/10/5 1/11/7 2/0/0 3/12/1 ', Rows, 'the parent without children has blank child columns');

        Rows := '';
        Q.SetRange(CNo, 10);
        Q.Open();
        while Q.Read() do
            Rows += Format(Q.PNo) + '/' + Format(Q.CNo) + ' ';
        Q.Close();
        Assert.AreEqual('1/10 ', Rows, 'a filter on an outer-joined column drops the unmatched parents');

        Rows := '';
        Q.SetRange(CNo);
        Q.SetRange(CAmt, 0);
        Q.Open();
        while Q.Read() do
            Rows += Format(Q.PNo) + '/' + Format(Q.CNo) + ' ';
        Q.Close();
        Assert.AreEqual('2/0 ', Rows, 'a filter that admits 0 keeps the unmatched parent');

        Rows := '';
        Sums.Open();
        while Sums.Read() do
            Rows += Format(Sums.PNo) + '/sum' + Format(Sums.SumAmt) + '/cnt' + Format(Sums.CntC) + ' ';
        Sums.Close();
        Assert.AreEqual('1/sum12/cnt2 2/sum0/cnt0 3/sum1/cnt1 ', Rows, 'aggregates over the join');
    end;

    [Test]
    procedure Query_SumOfAnIntegerColumn_AndARowInsertedBeforeTheFirstRead()
    var
        Q: Query "Probe Q Sum Int";
        G: Query "Probe Q Group Desc";
        ALTUniversal: Record "ALT Universal";
        Rows: Text;
    begin
        Initialize();

        Q.Open();
        Assert.IsTrue(Q.Read(), 'a row');
        Assert.AreEqual(6, Q.SumI, 'Sum of an Integer column');
        Q.Close();

        G.Open();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 99;
        ALTUniversal."Integer Field" := 1;
        ALTUniversal.Insert();
        while G.Read() do
            Rows += Format(G.Grp) + 'x' + Format(G.Cnt) + ' ';
        G.Close();
        Assert.AreEqual('2x2 1x3 ', Rows, 'Open does not run the query: the row inserted after it is counted');
    end;

    local procedure StreamText(var TempBlob: Codeunit "Temp Blob"; Separator: Text): Text
    var
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Result += Line.Trim() + Separator;
        end;
        exit(Result);
    end;

    [Test]
    procedure Query_SaveAsXml_And_SaveAsJson_Output()
    var
        Q: Query "Probe Q Desc";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        Initialize();

        TempBlob.CreateOutStream(OutStr);
        Assert.IsTrue(Q.SaveAsXml(OutStr), 'SaveAsXml');
        Assert.AreEqual('<?xml version="1.0" standalone="yes"?><DataSet><xs:schema id="NewDataSet" xmlns="" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:msdata="urn:schemas-microsoft-com:xml-msdata"><xs:element name="NewDataSet" msdata:IsDataSet="true" msdata:MainDataTable="Result" msdata:Locale=""><xs:complexType><xs:choice minOccurs="0" maxOccurs="unbounded"><xs:element name="Result" msdata:Locale=""><xs:complexType><xs:sequence><xs:element name="IntV" type="xs:int" minOccurs="0" /><xs:element name="Entry" type="xs:int" minOccurs="0" /></xs:sequence></xs:complexType></xs:element></xs:choice></xs:complexType></xs:element></xs:schema><Result><IntV>2</IntV><Entry>1</Entry></Result><Result><IntV>2</IntV><Entry>3</Entry></Result><Result><IntV>1</IntV><Entry>2</Entry></Result><Result><IntV>1</IntV><Entry>4</Entry></Result></DataSet>',
            StreamText(TempBlob, ''), 'XML (a .NET DataSet; lines trimmed and joined)');

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        Assert.IsTrue(Q.SaveAsJson(OutStr), 'SaveAsJson');
        Assert.AreEqual('[{"IntV":2,"Entry":1},{"IntV":2,"Entry":3},{"IntV":1,"Entry":2},{"IntV":1,"Entry":4}]', StreamText(TempBlob, ''), 'JSON: an array of objects keyed by column name');
    end;
}
