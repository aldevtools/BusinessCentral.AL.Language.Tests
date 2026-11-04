// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Fixtures.al (own tables 73406-73409, helper 73430, DT runner 73450), XmlPortFixtures.al, QueryFixtures.al, Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Query.SaveAsXml / SaveAsCsv to streams, static and instance, with empty tables, aggregates, joins and escaping.
// BC versions: 29 (27 and 28 by CI)

codeunit 73516 "LT XpT Query Save"
{
    Subtype = Test;
    TestPermissions = Disabled;


    [Test]
    procedure SaveAsXml_Seeded()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('xml', Helper.SaveXml(Query::"LT XpT Q Items"));
        Observer.Observe('len', Format(Helper.LastLength()));
        Observer.Expect('len', '1756');
        Observer.Ignore('xml'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;










    [Test]
    procedure SaveAsXml_UnknownQueryId()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.SaveXml(1);
        Observer.Observe('err', 'no error');
        Observer.Expect('err', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsCsv_Seeded()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('csv', Helper.SaveCsv(Query::"LT XpT Q Items"));
        Observer.Observe('len', Format(Helper.LastLength()));
        Observer.Expect('csv', 'ItemNo,ItemName,QtyCol,AmountCol,CategoryCol,ActiveCol<NL>1,Alpha,10,1.5,A,True<NL>2,Beta,20,2.5,A,False<NL>3,Gamma,30,3.5,B,True');
        Observer.Expect('len', '125');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsCsv_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('csv', Helper.SaveCsv(Query::"LT XpT Q Items"));
        Observer.Observe('len', Format(Helper.LastLength()));
        Observer.Expect('csv', 'ItemNo,ItemName,QtyCol,AmountCol,CategoryCol,ActiveCol');
        Observer.Expect('len', '56');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsCsv_Aggregates()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('csv', Helper.SaveCsv(Query::"LT XpT Q Agg Group"));
        Observer.Expect('csv', 'CategoryCol,Cnt,SumQty,MinQty,MaxQty,AvgAmount<NL>A,2,30,10,20,2<NL>B,1,30,30,30,3.5');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsCsv_Joins()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('csv', Helper.SaveCsv(Query::"LT XpT Q Left"));
        Observer.Expect('csv', 'ItemNo,ItemName,LineId,Descr,LineQty<NL>1,Alpha,1,L1a,1<NL>1,Alpha,2,L1b,2<NL>2,Beta,3,L2a,5<NL>3,Gamma,0,,0');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsCsv_SpecialCharacters()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'a,b "q"', 1, 1, true, 'C', 0D);
        Helper.AddItem(2, 'x' + Helper.Chr(10) + 'y', 1, 1, true, 'C', 0D);
        Observer.Observe('csv', Helper.SaveCsv(Query::"LT XpT Q Items"));
        Observer.Expect('csv', 'ItemNo,ItemName,QtyCol,AmountCol,CategoryCol,ActiveCol<NL>1,"a,b ""q""",1,1,C,True<NL>2,x<NL>y,1,1,C,True');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsCsv_UnknownQueryId()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.SaveCsv(1);
        Observer.Observe('err', 'no error');
        Observer.Expect('err', 'no error');
        Observer.Verify();
    end;


    [Test]
    procedure SaveAs_InstanceCsvWithFilter()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Q: Query "LT XpT Q Items";
        TB: Record "LT XpT Blob" temporary;
        OutS: OutStream;
        InS: InStream;
    begin
        Helper.Wipe();
        Helper.Seed();
        Q.SetRange(QtyCol, 20);
        TB.Data.CreateOutStream(OutS);
        Q.SaveAsCsv(OutS);
        TB.Data.CreateInStream(InS);
        Observer.Observe('csv', Helper.ReadAll(InS));
        Observer.Expect('csv', 'ItemNo,ItemName,QtyCol,AmountCol,CategoryCol,ActiveCol<NL>2,Beta,20,2.5,A,False');
        Observer.Verify();
    end;
}
