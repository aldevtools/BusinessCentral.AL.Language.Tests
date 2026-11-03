// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: tables and helper of P105Fix.al; self-contained query 72273 and test codeunit 72274
// Facts: Query.SaveAsCsv stream forms (instance and static) into a Blob OutStream: default, Format 0 1 2 with FormatArgument, filters, empty result, TopNumberOfRows, twice into one stream, unknown id

query 72273 "LT P105 CsvQry"
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

codeunit 72274 "LT P105 CsvQry Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT P105 Helper";

    [Test]
    procedure P105_SaveAsCsv_Stream_Default()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 CsvQry";
        Ok: Boolean;
        OutStr: OutStream;
    begin
        Helper.Seed();
        Store.Id := 1;
        Store.Insert();
        Store.Data.CreateOutStream(OutStr);
        Ok := Qry.SaveAsCsv(OutStr);
        Observer.Observe('ok', Format(Ok));
        Store.Modify();
        Observer.Observe('content', Helper.ReadAll(Store));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('content', 'Id,Grp,Name,Amount|1,1,one,10.5|2,1,two,20|3,2,three,30.25|4,2,four,-5|');
        Observer.Verify();
    end;

    [Test]
    procedure P105_SaveAsCsv_Stream_Format0()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 CsvQry";
        Ok: Boolean;
        OutStr: OutStream;
    begin
        Helper.Seed();
        Store.Id := 1;
        Store.Insert();
        Store.Data.CreateOutStream(OutStr);
        Ok := Qry.SaveAsCsv(OutStr, 0, '');
        Observer.Observe('ok', Format(Ok));
        Store.Modify();
        Observer.Observe('content', Helper.ReadAll(Store));
        Observer.Expect('ok', 'No');
        Observer.Expect('content', '<no value>');
        Observer.Verify();
    end;

    [Test]
    procedure P105_SaveAsCsv_Stream_Format1()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 CsvQry";
        Ok: Boolean;
        OutStr: OutStream;
    begin
        Helper.Seed();
        Store.Id := 1;
        Store.Insert();
        Store.Data.CreateOutStream(OutStr);
        Ok := Qry.SaveAsCsv(OutStr, 1, '');
        Observer.Observe('ok', Format(Ok));
        Store.Modify();
        Observer.Observe('content', Helper.ReadAll(Store));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('content', 'Id,Grp,Name,Amount|1,1,one,10.5|2,1,two,20|3,2,three,30.25|4,2,four,-5|');
        Observer.Verify();
    end;

    [Test]
    procedure P105_SaveAsCsv_Stream_Format2()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 CsvQry";
        Ok: Boolean;
        OutStr: OutStream;
    begin
        Helper.Seed();
        Store.Id := 1;
        Store.Insert();
        Store.Data.CreateOutStream(OutStr);
        Ok := Qry.SaveAsCsv(OutStr, 2, '');
        Observer.Observe('ok', Format(Ok));
        Store.Modify();
        Observer.Observe('content', Helper.ReadAll(Store));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('content', 'Id,Grp,Name,Amount|1,1,one,10.5|2,1,two,20|3,2,three,30.25|4,2,four,-5|');
        Observer.Verify();
    end;

    [Test]
    procedure P105_SaveAsCsv_Stream_FormatArgument()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 CsvQry";
        Ok: Boolean;
        OutStr: OutStream;
    begin
        Helper.Seed();
        Store.Id := 1;
        Store.Insert();
        Store.Data.CreateOutStream(OutStr);
        Ok := Qry.SaveAsCsv(OutStr, 1, ';');
        Observer.Observe('ok', Format(Ok));
        Store.Modify();
        Observer.Observe('content', Helper.ReadAll(Store));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('content', 'Id;Grp;Name;Amount|1;1;one;10.5|2;1;two;20|3;2;three;30.25|4;2;four;-5|');
        Observer.Verify();
    end;

    [Test]
    procedure P105_SaveAsCsv_Stream_FormatArgumentTab()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 CsvQry";
        Ok: Boolean;
        OutStr: OutStream;
    begin
        Helper.Seed();
        Store.Id := 1;
        Store.Insert();
        Store.Data.CreateOutStream(OutStr);
        Ok := Qry.SaveAsCsv(OutStr, 1, 'x');
        Observer.Observe('ok', Format(Ok));
        Store.Modify();
        Observer.Observe('content', Helper.ReadAll(Store));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('content', 'IdxGrpxNamexAmount|1x1xonex10.5|2x1xtwox20|3x2xthreex30.25|4x2xfourx-5|');
        Observer.Verify();
    end;

    [Test]
    procedure P105_SaveAsCsv_Stream_WithFilter()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 CsvQry";
        Ok: Boolean;
        OutStr: OutStream;
    begin
        Helper.Seed();
        Store.Id := 1;
        Store.Insert();
        Store.Data.CreateOutStream(OutStr);
        Qry.SetRange(Grp, 2);
        Ok := Qry.SaveAsCsv(OutStr);
        Observer.Observe('ok', Format(Ok));
        Store.Modify();
        Observer.Observe('content', Helper.ReadAll(Store));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('content', 'Id,Grp,Name,Amount|3,2,three,30.25|4,2,four,-5|');
        Observer.Verify();
    end;

    [Test]
    procedure P105_SaveAsCsv_Stream_EmptyResult()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 CsvQry";
        Ok: Boolean;
        OutStr: OutStream;
    begin
        Helper.Seed();
        Store.Id := 1;
        Store.Insert();
        Store.Data.CreateOutStream(OutStr);
        Qry.SetRange(Grp, 99);
        Ok := Qry.SaveAsCsv(OutStr);
        Observer.Observe('ok', Format(Ok));
        Store.Modify();
        Observer.Observe('content', Helper.ReadAll(Store));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('content', 'Id,Grp,Name,Amount|');
        Observer.Verify();
    end;

    [Test]
    procedure P105_SaveAsCsv_Stream_Top1()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 CsvQry";
        Ok: Boolean;
        OutStr: OutStream;
    begin
        Helper.Seed();
        Store.Id := 1;
        Store.Insert();
        Store.Data.CreateOutStream(OutStr);
        Qry.TopNumberOfRows(1);
        Ok := Qry.SaveAsCsv(OutStr);
        Observer.Observe('ok', Format(Ok));
        Store.Modify();
        Observer.Observe('content', Helper.ReadAll(Store));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('content', 'Id,Grp,Name,Amount|1,1,one,10.5|');
        Observer.Verify();
    end;

    [Test]
    procedure P105_SaveAsCsv_Stream_Static()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 CsvQry";
        Ok: Boolean;
        OutStr: OutStream;
    begin
        Helper.Seed();
        Store.Id := 1;
        Store.Insert();
        Store.Data.CreateOutStream(OutStr);
        Ok := Query.SaveAsCsv(72273, OutStr);
        Observer.Observe('ok', Format(Ok));
        Store.Modify();
        Observer.Observe('content', Helper.ReadAll(Store));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('content', 'Id,Grp,Name,Amount|1,1,one,10.5|2,1,two,20|3,2,three,30.25|4,2,four,-5|');
        Observer.Verify();
    end;

    [Test]
    procedure P105_SaveAsCsv_Stream_StaticFormat()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 CsvQry";
        Ok: Boolean;
        OutStr: OutStream;
    begin
        Helper.Seed();
        Store.Id := 1;
        Store.Insert();
        Store.Data.CreateOutStream(OutStr);
        Ok := Query.SaveAsCsv(72273, OutStr, 1, '');
        Observer.Observe('ok', Format(Ok));
        Store.Modify();
        Observer.Observe('content', Helper.ReadAll(Store));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('content', 'Id,Grp,Name,Amount|1,1,one,10.5|2,1,two,20|3,2,three,30.25|4,2,four,-5|');
        Observer.Verify();
    end;

    [Test]
    procedure P105_SaveAsCsv_Stream_UnknownId()
    var
        Observer: Codeunit "Probe Observer";
        OutStr: OutStream;
        Store: Record "LT P105 Store";
    begin
        Helper.Seed();
        Store.Id := 1;
        Store.Insert();
        Store.Data.CreateOutStream(OutStr);
        Observer.Observe('ok', Format(Query.SaveAsCsv(72399, OutStr)));
        Observer.Observe('unknown id', 'no error');
        Observer.Expect('ok', 'No');
        Observer.Expect('unknown id', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure P105_SaveAsCsv_Stream_Twice()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 CsvQry";
        OutStr: OutStream;
    begin
        Helper.Seed();
        Store.Id := 1;
        Store.Insert();
        Store.Data.CreateOutStream(OutStr);
        Qry.SetRange(Grp, 1);
        Observer.Observe('first', Format(Qry.SaveAsCsv(OutStr)));
        Qry.SetRange(Grp, 2);
        Observer.Observe('second', Format(Qry.SaveAsCsv(OutStr)));
        Store.Modify();
        Observer.Observe('content', Helper.ReadAll(Store));
        Observer.Expect('first', 'Yes');
        Observer.Expect('second', 'Yes');
        Observer.Expect('content', 'Id,Grp,Name,Amount|3,2,three,30.25|4,2,four,-5|');
        Observer.Verify();
    end;
}
