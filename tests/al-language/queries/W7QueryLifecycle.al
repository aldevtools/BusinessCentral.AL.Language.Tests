// Batch 7 probes: Query Open / SetRange / Read order, writes while a query is open, captions of aggregate columns, SaveAs output. Observe only.
codeunit 68511 "W7 Query Lifecycle"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeedFour()
    var
        Seed: Codeunit "W7 Q Seed";
    begin
        Seed.Clear();
        Seed.Row(1, 10, 'T1', 1, 'A');
        Seed.Row(2, 20, 'T2', 2, 'A');
        Seed.Row(3, 30, 'T3', 3, 'B');
        Seed.Row(4, 40, 'T4', 4, 'B');
    end;

    local procedure Drain(var Q: Query "W7 Q Plain"): Text
    var
        Result: Text;
    begin
        while Q.Read() do
            Result += Format(Q.Entry) + ',';
        exit(Result);
    end;

    [TryFunction]
    local procedure TrySetRange(var Q: Query "W7 Q Plain"; FromValue: Integer; ToValue: Integer)
    begin
        Q.SetRange(Entry, FromValue, ToValue);
    end;

    [TryFunction]
    local procedure TryOpen(var Q: Query "W7 Q Plain")
    begin
        Q.Open();
    end;

    [Test]
    procedure Open_AfterTheFirstRead()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "W7 Q Plain";
        Ok: Boolean;
    begin
        SeedFour();
        Q.Open();
        Observer.Observe('read 1', Format(Q.Read()));
        Observer.Observe('entry 1', Format(Q.Entry));
        Observer.Observe('read 2', Format(Q.Read()));
        Observer.Observe('entry 2', Format(Q.Entry));
        Ok := TryOpen(Q);
        Observer.Observe('open again ok', Format(Ok));
        Observer.ObserveError('open again');
        Observer.Observe('rows read after it', Drain(Q));
        Observer.Observe('read past the end', Format(Q.Read()));
        Observer.Observe('read past the end again', Format(Q.Read()));
        Q.Close();
        Observer.Observe('read after close', Format(Q.Read()));
        Q.Open();
        Observer.Observe('rows after open', Drain(Q));
        Q.Close();
        Observer.Expect('read 1', 'Yes');
        Observer.Expect('entry 1', '1');
        Observer.Expect('read 2', 'Yes');
        Observer.Expect('entry 2', '2');
        Observer.Expect('open again ok', 'Yes');
        Observer.Expect('open again|text', '');
        Observer.Expect('open again|code', '');
        Observer.Expect('rows read after it', '1,2,3,4,');
        Observer.Expect('read past the end', 'No');
        Observer.Expect('read past the end again', 'No');
        Observer.Expect('read after close', 'No');
        Observer.Expect('rows after open', '1,2,3,4,');
        Observer.Verify();
    end;

    [Test]
    procedure WriteWhileANormalQueryIsOpen_InsertAfterFirstRead()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "W7 Q Seed";
        Q: Query "W7 Q Plain";
    begin
        SeedFour();
        Q.Open();
        Observer.Observe('read 1', Format(Q.Read()));
        Seed.Row(10, 100, 'T10', 10, 'C');
        Observer.Observe('rows after inserting entry 10', Drain(Q));
        Q.Close();
        Observer.Expect('read 1', 'Yes');
        Observer.Expect('rows after inserting entry 10', '2,3,4,10,');
        Observer.Verify();
    end;

    [Test]
    procedure WriteWhileANormalQueryIsOpen_InsertBetweenOpenAndFirstRead()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "W7 Q Seed";
        Q: Query "W7 Q Plain";
    begin
        SeedFour();
        Q.Open();
        Seed.Row(11, 110, 'T11', 11, 'C');
        Observer.Observe('rows after insert between open and first read', Drain(Q));
        Q.Close();
        Observer.Expect('rows after insert between open and first read', '1,2,3,4,11,');
        Observer.Verify();
    end;

    [Test]
    procedure WriteWhileANormalQueryIsOpen_DeleteAndModify()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W7 Q Row";
        Q: Query "W7 Q Plain";
    begin
        SeedFour();
        Q.Open();
        Observer.Observe('read 1', Format(Q.Read()));
        Row.Get(3);
        Row.Delete();
        Row.Get(4);
        Row.Txt := 'changed';
        Row.Modify();
        Observer.Observe('rows after delete of 3 and modify of 4', Drain(Q));
        Q.Close();
        Observer.Expect('read 1', 'Yes');
        Observer.Expect('rows after delete of 3 and modify of 4', '2,4,');
        Observer.Verify();
    end;

    [Test]
    procedure WriteWhileAnAggregatedQueryIsOpen_InsertAfterFirstRead()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "W7 Q Seed";
        Q: Query "W7 Q Aggregates";
    begin
        SeedFour();
        Q.Open();
        Observer.Observe('read', Format(Q.Read()));
        Observer.Observe('count', Format(Q.Cnt));
        Seed.Row(10, 100, 'T10', 10, 'C');
        Observer.Observe('read again', Format(Q.Read()));
        Q.Close();
        Q.Open();
        Observer.Observe('read after reopen', Format(Q.Read()));
        Observer.Observe('count after reopen', Format(Q.Cnt));
        Observer.Observe('sum int after reopen', Format(Q.SumInt));
        Q.Close();
        Observer.Expect('read', 'Yes');
        Observer.Expect('count', '4');
        Observer.Expect('read again', 'No');
        Observer.Expect('read after reopen', 'Yes');
        Observer.Expect('count after reopen', '5');
        Observer.Expect('sum int after reopen', '200');
        Observer.Verify();
    end;

    [Test]
    procedure WriteWhileAnAggregatedQueryIsOpen_InsertBetweenOpenAndFirstRead()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "W7 Q Seed";
        Q: Query "W7 Q Aggregates";
    begin
        SeedFour();
        Q.Open();
        Seed.Row(11, 110, 'T11', 11, 'C');
        Observer.Observe('read after insert between open and read', Format(Q.Read()));
        Observer.Observe('count then', Format(Q.Cnt));
        Q.Close();
        Observer.Expect('read after insert between open and read', 'Yes');
        Observer.Expect('count then', '5');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryCaption(var Q: Query "W7 Q Aggregates"; var Result: Text)
    begin
        Result := Q.ColumnCaption(Cnt);
    end;

    [Test]
    procedure ColumnCaption_OfCountAndOtherAggregateColumns()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "W7 Q Aggregates";
        Plain: Query "W7 Q Plain";
        Caption: Text;
    begin
        Observer.Observe('count caption ok', Format(TryCaption(Q, Caption)));
        Observer.Observe('count caption', Caption);
        Observer.ObserveError('count caption');
        Observer.Observe('count name', Q.ColumnName(Cnt));
        Observer.Observe('sum int caption', Q.ColumnCaption(SumInt));
        Observer.Observe('sum int name', Q.ColumnName(SumInt));
        Observer.Observe('avg dec caption', Q.ColumnCaption(AvgDec));
        Observer.Observe('min dec caption', Q.ColumnCaption(MinDec));
        Observer.Observe('plain Entry caption', Plain.ColumnCaption(Entry));
        Observer.Observe('plain Dup caption', Plain.ColumnCaption(Dup));
        Observer.Observe('plain FIntF caption', Plain.ColumnCaption(FIntF));
        Observer.Expect('count caption ok', 'Yes');
        Observer.Expect('count caption', 'Cnt');
        Observer.Expect('count caption|text', '');
        Observer.Expect('count caption|code', '');
        Observer.Expect('count name', 'Cnt');
        Observer.Expect('sum int caption', 'SumInt');
        Observer.Expect('sum int name', 'SumInt');
        Observer.Expect('avg dec caption', 'AvgDec');
        Observer.Expect('min dec caption', 'MinDec');
        Observer.Expect('plain Entry caption', 'Entry');
        Observer.Expect('plain Dup caption', 'IntF');
        Observer.Expect('plain FIntF caption', 'IntF');
        Observer.Verify();
    end;

    local procedure SeedSave()
    var
        Seed: Codeunit "W7 Q Seed";
        Row: Record "W7 Q Row";
        Accent: Text[1];
    begin
        Accent[1] := 233;
        Seed.Clear();
        Seed.Row(1, 10, 'plain', 1.5, 'A');
        Seed.Row(2, 20, 'a,"b"', 2, 'A');
        Seed.Row(3, 30, 'x' + Accent + 'y<&>', 0, 'A');
        Row.Get(1);
        Row.Dt := DMY2Date(5, 3, 2024);
        Row.Modify();
    end;

    [Test]
    procedure SaveAsCsv_NonIntegerColumns()
    var
        Observer: Codeunit "Probe Observer";
        Util: Codeunit "W7 Stream Util";
        TempBlob: Codeunit "Temp Blob";
        Q: Query "W7 Q Save";
        OutS: OutStream;
        Ok: Boolean;
    begin
        SeedSave();
        TempBlob.CreateOutStream(OutS);
        Ok := Q.SaveAsCsv(OutS);
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('length', Format(TempBlob.Length()));
        Observer.Observe('bytes', CopyStr(Util.Hex(TempBlob), 1, 60));
        Observer.Observe('text utf8', Util.Lines(TempBlob, TextEncoding::UTF8));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('length', '85');
        Observer.Expect('bytes', '45 6E 74 72 79 2C 54 78 74 2C 44 65 63 46 2C 44 74 0D 0A 31 ');
        Observer.Expect('text utf8', 'Entry,Txt,DecF,Dt|1,plain,1.5,3/5/2024 12:00:00 AM|2,"a,""b""",2,0|3,xéy<&>,0,0|');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsCsv_IntegerColumns()
    var
        Observer: Codeunit "Probe Observer";
        Util: Codeunit "W7 Stream Util";
        TempBlob: Codeunit "Temp Blob";
        Q: Query "W7 Q Save Integers";
        OutS: OutStream;
        Ok: Boolean;
    begin
        SeedSave();
        TempBlob.CreateOutStream(OutS);
        Ok := Q.SaveAsCsv(OutS);
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('length', Format(TempBlob.Length()));
        Observer.Observe('bytes', CopyStr(Util.Hex(TempBlob), 1, 60));
        Observer.Observe('text utf8', Util.Lines(TempBlob, TextEncoding::UTF8));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('length', '30');
        Observer.Expect('bytes', '45 6E 74 72 79 2C 49 6E 74 46 0D 0A 31 2C 31 30 0D 0A 32 2C ');
        Observer.Expect('text utf8', 'Entry,IntF|1,10|2,20|3,30|');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsXml_NonIntegerColumns()
    var
        Observer: Codeunit "Probe Observer";
        Util: Codeunit "W7 Stream Util";
        TempBlob: Codeunit "Temp Blob";
        Q: Query "W7 Q Save";
        OutS: OutStream;
        Ok: Boolean;
    begin
        SeedSave();
        TempBlob.CreateOutStream(OutS);
        Ok := Q.SaveAsXml(OutS);
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('length', Format(TempBlob.Length()));
        Observer.Observe('bytes', CopyStr(Util.Hex(TempBlob), 1, 60));
        Observer.Observe('text utf8', Util.Lines(TempBlob, TextEncoding::UTF8));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('length', '1317');
        Observer.Expect('bytes', 'EF BB BF 3C 3F 78 6D 6C 20 76 65 72 73 69 6F 6E 3D 22 31 2E ');
        Observer.Ignore('text utf8'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsXml_IntegerColumns()
    var
        Observer: Codeunit "Probe Observer";
        Util: Codeunit "W7 Stream Util";
        TempBlob: Codeunit "Temp Blob";
        Q: Query "W7 Q Save Integers";
        OutS: OutStream;
        Ok: Boolean;
    begin
        SeedSave();
        TempBlob.CreateOutStream(OutS);
        Ok := Q.SaveAsXml(OutS);
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('length', Format(TempBlob.Length()));
        Observer.Observe('bytes', CopyStr(Util.Hex(TempBlob), 1, 60));
        Observer.Observe('text utf8', Util.Lines(TempBlob, TextEncoding::UTF8));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('length', '1019');
        Observer.Expect('bytes', 'EF BB BF 3C 3F 78 6D 6C 20 76 65 72 73 69 6F 6E 3D 22 31 2E ');
        Observer.Ignore('text utf8'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsJson_NonIntegerColumns()
    var
        Observer: Codeunit "Probe Observer";
        Util: Codeunit "W7 Stream Util";
        TempBlob: Codeunit "Temp Blob";
        Q: Query "W7 Q Save";
        OutS: OutStream;
        Ok: Boolean;
    begin
        SeedSave();
        TempBlob.CreateOutStream(OutS);
        Ok := Q.SaveAsJson(OutS);
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('length', Format(TempBlob.Length()));
        Observer.Observe('bytes', CopyStr(Util.Hex(TempBlob), 1, 60));
        Observer.Observe('text utf8', Util.Lines(TempBlob, TextEncoding::UTF8));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('length', '140');
        Observer.Expect('bytes', '5B 7B 22 45 6E 74 72 79 22 3A 31 2C 22 54 78 74 22 3A 22 70 ');
        Observer.Expect('text utf8', '[{"Entry":1,"Txt":"plain","DecF":1.5,"Dt":"2024-03-05T00:00:00Z"},{"Entry":2,"Txt":"a,\"b\"","DecF":2},{"Entry":3,"Txt":"xéy<&>","DecF":0}]|');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsJson_IntegerColumns()
    var
        Observer: Codeunit "Probe Observer";
        Util: Codeunit "W7 Stream Util";
        TempBlob: Codeunit "Temp Blob";
        Q: Query "W7 Q Save Integers";
        OutS: OutStream;
        Ok: Boolean;
    begin
        SeedSave();
        TempBlob.CreateOutStream(OutS);
        Ok := Q.SaveAsJson(OutS);
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('length', Format(TempBlob.Length()));
        Observer.Observe('bytes', CopyStr(Util.Hex(TempBlob), 1, 60));
        Observer.Observe('text utf8', Util.Lines(TempBlob, TextEncoding::UTF8));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('length', '67');
        Observer.Expect('bytes', '5B 7B 22 45 6E 74 72 79 22 3A 31 2C 22 49 6E 74 46 22 3A 31 ');
        Observer.Expect('text utf8', '[{"Entry":1,"IntF":10},{"Entry":2,"IntF":20},{"Entry":3,"IntF":30}]|');
        Observer.Verify();
    end;
}
