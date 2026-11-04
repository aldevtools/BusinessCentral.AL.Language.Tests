// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: tables and helper of P105Fix.al; self-contained query 72275 and test codeunit 72276
// Facts: Query.SaveAsXml stream forms (instance and static) into a Blob OutStream: default, filters, empty result, TopNumberOfRows, unknown id

query 72275 "LT P105 XmlQry"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "LT P105 Row")
        {
            column(Id; Id) { }
            column(Grp; Grp) { }
            column(Name; Name) { }
            column(Amount; Amount) { }
        }
    }
}

codeunit 72276 "LT P105 XmlQry Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT P105 Helper";

    [Test]
    procedure P105_SaveAsXml_Stream_Default()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 XmlQry";
        Ok: Boolean;
        OutStr: OutStream;
    begin
        Helper.Seed();
        Store.Id := 1;
        Store.Insert();
        Store.Data.CreateOutStream(OutStr);
        Ok := Qry.SaveAsXml(OutStr);
        Observer.Observe('ok', Format(Ok));
        Store.Modify();
        Observer.Observe('content', Helper.ReadAll(Store));
        Observer.Expect('ok', 'Yes');
        Observer.Ignore('content'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

    [Test]
    procedure P105_SaveAsXml_Stream_WithFilter()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 XmlQry";
        Ok: Boolean;
        OutStr: OutStream;
    begin
        Helper.Seed();
        Store.Id := 1;
        Store.Insert();
        Store.Data.CreateOutStream(OutStr);
        Qry.SetRange(Grp, 2);
        Ok := Qry.SaveAsXml(OutStr);
        Observer.Observe('ok', Format(Ok));
        Store.Modify();
        Observer.Observe('content', Helper.ReadAll(Store));
        Observer.Expect('ok', 'Yes');
        Observer.Ignore('content'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

    [Test]
    procedure P105_SaveAsXml_Stream_EmptyResult()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 XmlQry";
        Ok: Boolean;
        OutStr: OutStream;
    begin
        Helper.Seed();
        Store.Id := 1;
        Store.Insert();
        Store.Data.CreateOutStream(OutStr);
        Qry.SetRange(Grp, 99);
        Ok := Qry.SaveAsXml(OutStr);
        Observer.Observe('ok', Format(Ok));
        Store.Modify();
        Observer.Observe('content', Helper.ReadAll(Store));
        Observer.Expect('ok', 'Yes');
        Observer.Ignore('content'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

    [Test]
    procedure P105_SaveAsXml_Stream_Top1()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 XmlQry";
        Ok: Boolean;
        OutStr: OutStream;
    begin
        Helper.Seed();
        Store.Id := 1;
        Store.Insert();
        Store.Data.CreateOutStream(OutStr);
        Qry.TopNumberOfRows(1);
        Ok := Qry.SaveAsXml(OutStr);
        Observer.Observe('ok', Format(Ok));
        Store.Modify();
        Observer.Observe('content', Helper.ReadAll(Store));
        Observer.Expect('ok', 'Yes');
        Observer.Ignore('content'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

    [Test]
    procedure P105_SaveAsXml_Stream_Static()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 XmlQry";
        Ok: Boolean;
        OutStr: OutStream;
    begin
        Helper.Seed();
        Store.Id := 1;
        Store.Insert();
        Store.Data.CreateOutStream(OutStr);
        Ok := Query.SaveAsXml(72275, OutStr);
        Observer.Observe('ok', Format(Ok));
        Store.Modify();
        Observer.Observe('content', Helper.ReadAll(Store));
        Observer.Expect('ok', 'Yes');
        Observer.Ignore('content'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

    [Test]
    procedure P105_SaveAsXml_Stream_NameFilter()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 XmlQry";
        Ok: Boolean;
        OutStr: OutStream;
    begin
        Helper.Seed();
        Store.Id := 1;
        Store.Insert();
        Store.Data.CreateOutStream(OutStr);
        Qry.SetFilter(Name, '*o*');
        Ok := Qry.SaveAsXml(OutStr);
        Observer.Observe('ok', Format(Ok));
        Store.Modify();
        Observer.Observe('content', Helper.ReadAll(Store));
        Observer.Expect('ok', 'Yes');
        Observer.Ignore('content'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

    [Test]
    procedure P105_SaveAsXml_Stream_UnknownId()
    var
        Observer: Codeunit "Probe Observer";
        OutStr: OutStream;
        Store: Record "LT P105 Store";
    begin
        Helper.Seed();
        Store.Id := 1;
        Store.Insert();
        Store.Data.CreateOutStream(OutStr);
        Observer.Observe('ok', Format(Query.SaveAsXml(72399, OutStr)));
        Observer.Observe('unknown id', 'no error');
        Observer.Expect('ok', 'No');
        Observer.Expect('unknown id', 'no error');
        Observer.Verify();
    end;
}
