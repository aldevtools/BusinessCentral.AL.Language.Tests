// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-value-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 97740, 97741, 97742; helper codeunits 97743, 97745
// Probe: written against real BC (al-runner issue 7935); every literal asserted below is what BC produced (BC 27.5, 28.5 and 29.0).
// Facts: a Blob value set through FieldRef.Value, RecordRef.GetTable / SetTable, TransferFields or a Variant, followed by a
//   rewrite (CreateOutStream), a Clear or a Modify of the source, a Clear of the target field after Insert and a second Insert
//   through the same record; for temporary and stored targets, a source that is loaded (written in memory, or Get plus CalcFields)
//   or read with Get without CalcFields. Each observation is HasValue (before CalcFields for a row) and the text:
//   r<n> = row n read through a second record (Get, HasValue, CalcFields, read), h = the target record in hand (no CalcFields).
// BC versions: 27.5+

table 97740 "LT BFR Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Key"; Integer) { DataClassification = SystemMetadata; }
        field(2; Data; Blob) { DataClassification = SystemMetadata; }
        field(3; Other; Blob) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Key") { Clustered = true; }
    }
}

table 97741 "LT BFR Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Key"; Integer) { DataClassification = SystemMetadata; }
        field(2; Data; Blob) { DataClassification = SystemMetadata; }
        field(3; Other; Blob) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Key") { Clustered = true; }
    }
}

// The table of the reporter's repro (TableType = Temporary).
table 97742 "LT BFR TmpRow"
{
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; Key1; Integer) { DataClassification = SystemMetadata; }
        field(2; Data; Blob) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; Key1) { Clustered = true; }
    }
}

// The reporter's holder: one temporary record whose Blob is written again for every item.
codeunit 97743 "LT BFR Hold"
{
    var
        HB: Record "LT BFR TmpRow" temporary;

    procedure Fill(Txt: Text)
    var
        OS: OutStream;
    begin
        HB.Data.CreateOutStream(OS);
        OS.WriteText(Txt);
    end;

    procedure ToRec(var RR: RecordRef; FNo: Integer)
    var
        FR: FieldRef;
    begin
        FR := RR.Field(FNo);
        FR.Value := HB.Data;
    end;
}

// The reporter's list: Add as the BLOB Storage module's Temp Blob List does it.
codeunit 97745 "LT BFR Lst"
{
    var
        Rec: Record "LT BFR TmpRow" temporary;

    procedure Add(H: Codeunit "LT BFR Hold")
    var
        RR: RecordRef;
    begin
        Rec.Key1 := Rec.Count() + 1;
        Clear(Rec.Data);
        RR.GetTable(Rec);
        H.ToRec(RR, Rec.FieldNo(Data));
        RR.SetTable(Rec);
        Rec.Insert();
    end;

    procedure Text(K: Integer) Txt: Text
    var
        IS: InStream;
    begin
        if not Rec.Get(K) then
            exit('<no row>');
        if not Rec.Data.HasValue() then
            exit('nohv:');
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(IS);
        IS.ReadText(Txt);
        exit('hv:' + Txt);
    end;
}

codeunit 97744 "LT FieldRef Blob Copy"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Fill(var Src: Record "LT BFR Src"; Txt: Text)
    var
        OS: OutStream;
    begin
        Src.Data.CreateOutStream(OS);
        OS.WriteText(Txt);
    end;

    local procedure HasValueText(HV: Boolean): Text
    begin
        if HV then
            exit('hv:');
        exit('nohv:');
    end;

    // The target record in hand: HasValue and the text, without CalcFields.
    local procedure Hand(var Rec: Record "LT BFR Row"): Text
    var
        IS: InStream;
        Txt: Text;
    begin
        Rec.Data.CreateInStream(IS);
        IS.ReadText(Txt);
        exit(HasValueText(Rec.Data.HasValue()) + Txt);
    end;

    // A stored row read through a second record: Get, HasValue before CalcFields, CalcFields, the text.
    local procedure Row(var Reader: Record "LT BFR Row"; K: Integer): Text
    var
        IS: InStream;
        HV: Boolean;
        Txt: Text;
    begin
        if not Reader.Get(K) then
            exit('<no row>');
        HV := Reader.Data.HasValue();
        Reader.CalcFields(Data);
        Reader.Data.CreateInStream(IS);
        IS.ReadText(Txt);
        exit(HasValueText(HV) + Txt);
    end;

    // One item added as the reporter's Add does it, with the step before GetTable chosen by Mode:
    // n = nothing, c = Clear(Tgt.Data), i = Tgt.Init(), r = Clear(Tgt).
    local procedure Add(var Tgt: Record "LT BFR Row"; var Src: Record "LT BFR Src"; Mode: Text; K: Integer)
    var
        RR: RecordRef;
        FR: FieldRef;
    begin
        case Mode of
            'c':
                Clear(Tgt.Data);
            'i':
                Tgt.Init();
            'r':
                Clear(Tgt);
        end;
        Tgt."Key" := K;
        RR.GetTable(Tgt);
        FR := RR.Field(Tgt.FieldNo(Data));
        FR.Value := Src.Data;
        RR.SetTable(Tgt);
        Tgt.Insert();
    end;

    // Cell 1: the source is written in memory and refilled between and after two Adds through one target record.
    local procedure RunMem(var Observer: Codeunit "Probe Observer"; var Tgt: Record "LT BFR Row"; var Reader: Record "LT BFR Row"; var Src: Record "LT BFR Src"; Mode: Text; FirstFill: Boolean)
    begin
        if FirstFill then
            Fill(Src, 'alpha');
        Add(Tgt, Src, Mode, 1);
        Observer.Observe('add1 r1', Row(Reader, 1));
        Observer.Observe('add1 h', Hand(Tgt));
        Fill(Src, 'beta');
        Observer.Observe('refill r1', Row(Reader, 1));
        Observer.Observe('refill h', Hand(Tgt));
        Add(Tgt, Src, Mode, 2);
        Observer.Observe('add2 r1', Row(Reader, 1));
        Observer.Observe('add2 r2', Row(Reader, 2));
        Observer.Observe('add2 h', Hand(Tgt));
        Fill(Src, 'gamma');
        Observer.Observe('refill2 r1', Row(Reader, 1));
        Observer.Observe('refill2 r2', Row(Reader, 2));
        Observer.Observe('refill2 h', Hand(Tgt));
        Clear(Tgt.Data);
        Observer.Observe('cleartgt r1', Row(Reader, 1));
        Observer.Observe('cleartgt r2', Row(Reader, 2));
        Observer.Observe('cleartgt h', Hand(Tgt));
        Clear(Src.Data);
        Observer.Observe('clearsrc r1', Row(Reader, 1));
        Observer.Observe('clearsrc r2', Row(Reader, 2));
    end;

    local procedure RunMemTemp(var Observer: Codeunit "Probe Observer"; Mode: Text)
    var
        Tgt: Record "LT BFR Row" temporary;
        Reader: Record "LT BFR Row" temporary;
        Src: Record "LT BFR Src" temporary;
    begin
        Reader.Copy(Tgt, true);
        RunMem(Observer, Tgt, Reader, Src, Mode, true);
    end;

    local procedure ResetStored()
    var
        Row: Record "LT BFR Row";
        Src: Record "LT BFR Src";
    begin
        Row.DeleteAll();
        Src.DeleteAll();
    end;

    [Test]
    procedure Reporter_TableTypeTemporary_SameHolderTwoAdds()
    var
        Observer: Codeunit "Probe Observer";
        L: Codeunit "LT BFR Lst";
        H: Codeunit "LT BFR Hold";
    begin
        H.Fill('alpha');
        L.Add(H);
        H.Fill('beta');
        L.Add(H);
        Observer.Observe('r1', L.Text(1));
        Observer.Observe('r2', L.Text(2));
        H.Fill('gamma');
        Observer.Observe('refill r1', L.Text(1));
        Observer.Observe('refill r2', L.Text(2));
        L.Add(H);
        Observer.Observe('add3 r1', L.Text(1));
        Observer.Observe('add3 r2', L.Text(2));
        Observer.Observe('add3 r3', L.Text(3));
        Observer.Finish();
    end;

    [Test]
    procedure FieldRefValue_TempTarget_MemSource_NoClear()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunMemTemp(Observer, 'n');
        Observer.Finish();
    end;

    [Test]
    procedure FieldRefValue_TempTarget_MemSource_ClearField()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunMemTemp(Observer, 'c');
        Observer.Finish();
    end;

    [Test]
    procedure FieldRefValue_TempTarget_MemSource_Init()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunMemTemp(Observer, 'i');
        Observer.Finish();
    end;

    [Test]
    procedure FieldRefValue_TempTarget_MemSource_ClearRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunMemTemp(Observer, 'r');
        Observer.Finish();
    end;

    [Test]
    procedure FieldRefValue_StoredTarget_MemSource_NoClear()
    var
        Observer: Codeunit "Probe Observer";
        Tgt: Record "LT BFR Row";
        Reader: Record "LT BFR Row";
        Src: Record "LT BFR Src" temporary;
    begin
        ResetStored();
        RunMem(Observer, Tgt, Reader, Src, 'n', true);
        Observer.Finish();
    end;

    [Test]
    procedure FieldRefValue_StoredTarget_MemSource_ClearField()
    var
        Observer: Codeunit "Probe Observer";
        Tgt: Record "LT BFR Row";
        Reader: Record "LT BFR Row";
        Src: Record "LT BFR Src" temporary;
    begin
        ResetStored();
        RunMem(Observer, Tgt, Reader, Src, 'c', true);
        Observer.Finish();
    end;

    [Test]
    procedure FieldRefValue_StoredTarget_MemSource_Init()
    var
        Observer: Codeunit "Probe Observer";
        Tgt: Record "LT BFR Row";
        Reader: Record "LT BFR Row";
        Src: Record "LT BFR Src" temporary;
    begin
        ResetStored();
        RunMem(Observer, Tgt, Reader, Src, 'i', true);
        Observer.Finish();
    end;

    [Test]
    procedure FieldRefValue_StoredTarget_MemSource_ClearRecord()
    var
        Observer: Codeunit "Probe Observer";
        Tgt: Record "LT BFR Row";
        Reader: Record "LT BFR Row";
        Src: Record "LT BFR Src" temporary;
    begin
        ResetStored();
        RunMem(Observer, Tgt, Reader, Src, 'r', true);
        Observer.Finish();
    end;

    // Cell 1, stored source: inserted, then Get plus CalcFields (loaded); refilled in memory.
    [Test]
    procedure FieldRefValue_TempTarget_StoredLoadedSource_ClearField()
    var
        Observer: Codeunit "Probe Observer";
        Tgt: Record "LT BFR Row" temporary;
        Reader: Record "LT BFR Row" temporary;
        Src: Record "LT BFR Src";
    begin
        ResetStored();
        Reader.Copy(Tgt, true);
        Src."Key" := 1;
        Fill(Src, 'stored');
        Src.Insert();
        Src.Init();
        Src.Get(1);
        Src.CalcFields(Data);
        RunMem(Observer, Tgt, Reader, Src, 'c', true);
        Observer.Finish();
    end;

    [Test]
    procedure FieldRefValue_StoredTarget_StoredLoadedSource_ClearField()
    var
        Observer: Codeunit "Probe Observer";
        Tgt: Record "LT BFR Row";
        Reader: Record "LT BFR Row";
        Src: Record "LT BFR Src";
    begin
        ResetStored();
        Src."Key" := 1;
        Fill(Src, 'stored');
        Src.Insert();
        Src.Init();
        Src.Get(1);
        Src.CalcFields(Data);
        RunMem(Observer, Tgt, Reader, Src, 'c', true);
        Observer.Finish();
    end;

    // Cell 2: the source row is read with Get and no CalcFields before each Add; refilled in memory, then Modify.
    local procedure RunUnloaded(var Observer: Codeunit "Probe Observer"; var Tgt: Record "LT BFR Row"; var Reader: Record "LT BFR Row"; var Src: Record "LT BFR Src")
    begin
        Src."Key" := 1;
        Fill(Src, 'alpha');
        Src.Insert();
        Src.Init();
        Src.Get(1);
        Add(Tgt, Src, 'c', 1);
        Observer.Observe('add1 r1', Row(Reader, 1));
        Observer.Observe('add1 h', Hand(Tgt));
        Fill(Src, 'beta');
        Observer.Observe('refill r1', Row(Reader, 1));
        Src.Modify();
        Observer.Observe('modify r1', Row(Reader, 1));
        Src.Init();
        Src.Get(1);
        Add(Tgt, Src, 'c', 2);
        Observer.Observe('add2 r1', Row(Reader, 1));
        Observer.Observe('add2 r2', Row(Reader, 2));
        Observer.Observe('add2 h', Hand(Tgt));
        Fill(Src, 'gamma');
        Src.Modify();
        Observer.Observe('modify2 r1', Row(Reader, 1));
        Observer.Observe('modify2 r2', Row(Reader, 2));
        Clear(Tgt.Data);
        Observer.Observe('cleartgt r1', Row(Reader, 1));
        Observer.Observe('cleartgt r2', Row(Reader, 2));
    end;

    [Test]
    procedure FieldRefValue_TempTarget_TempSourceGetNoCalc()
    var
        Observer: Codeunit "Probe Observer";
        Tgt: Record "LT BFR Row" temporary;
        Reader: Record "LT BFR Row" temporary;
        Src: Record "LT BFR Src" temporary;
    begin
        Reader.Copy(Tgt, true);
        RunUnloaded(Observer, Tgt, Reader, Src);
        Observer.Finish();
    end;

    [Test]
    procedure FieldRefValue_StoredTarget_TempSourceGetNoCalc()
    var
        Observer: Codeunit "Probe Observer";
        Tgt: Record "LT BFR Row";
        Reader: Record "LT BFR Row";
        Src: Record "LT BFR Src" temporary;
    begin
        ResetStored();
        RunUnloaded(Observer, Tgt, Reader, Src);
        Observer.Finish();
    end;

    [Test]
    procedure FieldRefValue_TempTarget_StoredSourceGetNoCalc()
    var
        Observer: Codeunit "Probe Observer";
        Tgt: Record "LT BFR Row" temporary;
        Reader: Record "LT BFR Row" temporary;
        Src: Record "LT BFR Src";
    begin
        ResetStored();
        Reader.Copy(Tgt, true);
        RunUnloaded(Observer, Tgt, Reader, Src);
        Observer.Finish();
    end;

    [Test]
    procedure FieldRefValue_StoredTarget_StoredSourceGetNoCalc()
    var
        Observer: Codeunit "Probe Observer";
        Tgt: Record "LT BFR Row";
        Reader: Record "LT BFR Row";
        Src: Record "LT BFR Src";
    begin
        ResetStored();
        RunUnloaded(Observer, Tgt, Reader, Src);
        Observer.Finish();
    end;

    // Cell 1, refill between FieldRef.Value and Insert: the RecordRef field, the record after SetTable, the inserted row.
    local procedure RunRefillBeforeInsert(var Observer: Codeunit "Probe Observer"; var Tgt: Record "LT BFR Row"; var Reader: Record "LT BFR Row"; var Src: Record "LT BFR Src")
    var
        RR: RecordRef;
        FR: FieldRef;
    begin
        Fill(Src, 'alpha');
        Tgt."Key" := 1;
        RR.GetTable(Tgt);
        FR := RR.Field(Tgt.FieldNo(Data));
        FR.Value := Src.Data;
        Fill(Src, 'beta');
        RR.SetTable(Tgt);
        Observer.Observe('settable h', Hand(Tgt));
        Fill(Src, 'gamma');
        Observer.Observe('refill h', Hand(Tgt));
        Tgt.Insert();
        Observer.Observe('insert r1', Row(Reader, 1));
        Clear(Src.Data);
        Observer.Observe('clearsrc r1', Row(Reader, 1));
        Observer.Observe('clearsrc h', Hand(Tgt));
    end;

    [Test]
    procedure FieldRefValue_TempTarget_RefillBeforeInsert()
    var
        Observer: Codeunit "Probe Observer";
        Tgt: Record "LT BFR Row" temporary;
        Reader: Record "LT BFR Row" temporary;
        Src: Record "LT BFR Src" temporary;
    begin
        Reader.Copy(Tgt, true);
        RunRefillBeforeInsert(Observer, Tgt, Reader, Src);
        Observer.Finish();
    end;

    [Test]
    procedure FieldRefValue_StoredTarget_RefillBeforeInsert()
    var
        Observer: Codeunit "Probe Observer";
        Tgt: Record "LT BFR Row";
        Reader: Record "LT BFR Row";
        Src: Record "LT BFR Src" temporary;
    begin
        ResetStored();
        RunRefillBeforeInsert(Observer, Tgt, Reader, Src);
        Observer.Finish();
    end;

    // Cell 1 through RecordRef.Open: FieldRef.Value and RecordRef.Insert, rows read back through the same RecordRef.
    local procedure RRRow(var RR: RecordRef; K: Integer): Text
    var
        Probe: Record "LT BFR Row" temporary;
        KeyFR: FieldRef;
        DataFR: FieldRef;
    begin
        KeyFR := RR.Field(1);
        KeyFR.SetRange(K);
        if not RR.FindFirst() then
            exit('<no row>');
        DataFR := RR.Field(2);
        DataFR.CalcField();
        RR.SetTable(Probe);
        exit(Hand(Probe));
    end;

    local procedure RRInsert(var RR: RecordRef; var Src: Record "LT BFR Src"; K: Integer)
    var
        FR: FieldRef;
    begin
        RR.Init();
        FR := RR.Field(1);
        FR.Value := K;
        FR := RR.Field(2);
        FR.Value := Src.Data;
        RR.Insert();
    end;

    local procedure RunOpen(var Observer: Codeunit "Probe Observer"; IsTemp: Boolean)
    var
        Src: Record "LT BFR Src" temporary;
        RR: RecordRef;
    begin
        RR.Open(Database::"LT BFR Row", IsTemp);
        Fill(Src, 'alpha');
        RRInsert(RR, Src, 1);
        Observer.Observe('add1 r1', RRRow(RR, 1));
        Fill(Src, 'beta');
        Observer.Observe('refill r1', RRRow(RR, 1));
        RRInsert(RR, Src, 2);
        Observer.Observe('add2 r1', RRRow(RR, 1));
        Observer.Observe('add2 r2', RRRow(RR, 2));
        Fill(Src, 'gamma');
        Observer.Observe('refill2 r1', RRRow(RR, 1));
        Observer.Observe('refill2 r2', RRRow(RR, 2));
        Clear(Src.Data);
        Observer.Observe('clearsrc r1', RRRow(RR, 1));
        Observer.Observe('clearsrc r2', RRRow(RR, 2));
        RR.Close();
    end;

    [Test]
    procedure FieldRefValue_RecordRefOpenTemporary()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunOpen(Observer, true);
        Observer.Finish();
    end;

    [Test]
    procedure FieldRefValue_RecordRefOpenStored()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ResetStored();
        RunOpen(Observer, false);
        Observer.Finish();
    end;
}

codeunit 97746 "LT RecRef Blob Copy"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure FillRow(var Rec: Record "LT BFR Row"; Txt: Text)
    var
        OS: OutStream;
    begin
        Rec.Data.CreateOutStream(OS);
        OS.WriteText(Txt);
    end;

    local procedure Fill(var Src: Record "LT BFR Src"; Txt: Text)
    var
        OS: OutStream;
    begin
        Src.Data.CreateOutStream(OS);
        OS.WriteText(Txt);
    end;

    local procedure HasValueText(HV: Boolean): Text
    begin
        if HV then
            exit('hv:');
        exit('nohv:');
    end;

    local procedure Hand(var Rec: Record "LT BFR Row"): Text
    var
        IS: InStream;
        Txt: Text;
    begin
        Rec.Data.CreateInStream(IS);
        IS.ReadText(Txt);
        exit(HasValueText(Rec.Data.HasValue()) + Txt);
    end;

    local procedure Row(var Reader: Record "LT BFR Row"; K: Integer): Text
    var
        IS: InStream;
        HV: Boolean;
        Txt: Text;
    begin
        if not Reader.Get(K) then
            exit('<no row>');
        HV := Reader.Data.HasValue();
        Reader.CalcFields(Data);
        Reader.Data.CreateInStream(IS);
        IS.ReadText(Txt);
        exit(HasValueText(HV) + Txt);
    end;

    local procedure ResetStored()
    var
        Row: Record "LT BFR Row";
        Src: Record "LT BFR Src";
    begin
        Row.DeleteAll();
        Src.DeleteAll();
    end;

    // Cell 3: RecordRef.GetTable / SetTable between two records of one table, with rewrites of either side in between.
    local procedure RunGetSet(var Observer: Codeunit "Probe Observer"; var Src: Record "LT BFR Row"; var Dst: Record "LT BFR Row"; var Reader: Record "LT BFR Row")
    var
        RR: RecordRef;
    begin
        // a: refill the source between GetTable and SetTable
        FillRow(Src, 'alpha');
        RR.GetTable(Src);
        FillRow(Src, 'beta');
        RR.SetTable(Dst);
        Observer.Observe('a dst', Hand(Dst));
        Observer.Observe('a src', Hand(Src));
        // b: refill the source after SetTable, then write the target
        Clear(Src.Data);
        Clear(Dst.Data);
        FillRow(Src, 'alpha');
        RR.GetTable(Src);
        RR.SetTable(Dst);
        FillRow(Src, 'beta');
        Observer.Observe('b dst', Hand(Dst));
        FillRow(Dst, 'dst');
        Observer.Observe('b src', Hand(Src));
        // c: Clear the source between GetTable and SetTable
        Clear(Src.Data);
        Clear(Dst.Data);
        FillRow(Src, 'alpha');
        RR.GetTable(Src);
        Clear(Src.Data);
        RR.SetTable(Dst);
        Observer.Observe('c dst', Hand(Dst));
        // d: insert the copy, then refill and Clear the source, then Clear the target field
        Clear(Src.Data);
        Clear(Dst.Data);
        FillRow(Src, 'alpha');
        RR.GetTable(Src);
        RR.SetTable(Dst);
        Dst."Key" := 2;
        Dst.Insert();
        Observer.Observe('d insert r2', Row(Reader, 2));
        FillRow(Src, 'beta');
        Observer.Observe('d refill r2', Row(Reader, 2));
        Observer.Observe('d refill h', Hand(Dst));
        Clear(Src.Data);
        Observer.Observe('d clearsrc r2', Row(Reader, 2));
        Clear(Dst.Data);
        Observer.Observe('d cleartgt r2', Row(Reader, 2));
    end;

    [Test]
    procedure GetTableSetTable_Temporary()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR Row" temporary;
        Reader: Record "LT BFR Row" temporary;
    begin
        Reader.Copy(Dst, true);
        RunGetSet(Observer, Src, Dst, Reader);
        Observer.Finish();
    end;

    [Test]
    procedure GetTableSetTable_Stored()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BFR Row";
        Dst: Record "LT BFR Row";
        Reader: Record "LT BFR Row";
    begin
        ResetStored();
        RunGetSet(Observer, Src, Dst, Reader);
        Observer.Finish();
    end;

    // Cell 4: TransferFields from a loaded source, then refill and Clear the source, Insert, Clear the target field.
    local procedure RunTransfer(var Observer: Codeunit "Probe Observer"; var Src: Record "LT BFR Src"; var Tgt: Record "LT BFR Row"; var Reader: Record "LT BFR Row")
    begin
        Src."Key" := 1;
        Fill(Src, 'alpha');
        Tgt.TransferFields(Src);
        Observer.Observe('transfer h', Hand(Tgt));
        Fill(Src, 'beta');
        Observer.Observe('refill h', Hand(Tgt));
        Tgt.Insert();
        Observer.Observe('insert r1', Row(Reader, 1));
        Fill(Src, 'gamma');
        Observer.Observe('refill2 r1', Row(Reader, 1));
        Clear(Src.Data);
        Observer.Observe('clearsrc r1', Row(Reader, 1));
        Observer.Observe('clearsrc h', Hand(Tgt));
        Clear(Tgt.Data);
        Observer.Observe('cleartgt r1', Row(Reader, 1));
        // the same target record again: a second item from the refilled source
        Fill(Src, 'delta');
        Tgt.TransferFields(Src);
        Tgt."Key" := 2;
        Tgt.Insert();
        Fill(Src, 'epsilon');
        Observer.Observe('add2 r1', Row(Reader, 1));
        Observer.Observe('add2 r2', Row(Reader, 2));
    end;

    [Test]
    procedure TransferFields_Temporary()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BFR Src" temporary;
        Tgt: Record "LT BFR Row" temporary;
        Reader: Record "LT BFR Row" temporary;
    begin
        Reader.Copy(Tgt, true);
        RunTransfer(Observer, Src, Tgt, Reader);
        Observer.Finish();
    end;

    [Test]
    procedure TransferFields_Stored()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BFR Src";
        Tgt: Record "LT BFR Row";
        Reader: Record "LT BFR Row";
    begin
        ResetStored();
        RunTransfer(Observer, Src, Tgt, Reader);
        Observer.Finish();
    end;

    // Cell 4, source read with Get and no CalcFields.
    local procedure RunTransferUnloaded(var Observer: Codeunit "Probe Observer"; var Src: Record "LT BFR Src"; var Tgt: Record "LT BFR Row"; var Reader: Record "LT BFR Row")
    begin
        Src."Key" := 1;
        Fill(Src, 'alpha');
        Src.Insert();
        Src.Init();
        Src.Get(1);
        Tgt.TransferFields(Src);
        Observer.Observe('transfer h', Hand(Tgt));
        Tgt.Insert();
        Observer.Observe('insert r1', Row(Reader, 1));
        Fill(Src, 'beta');
        Src.Modify();
        Observer.Observe('modify r1', Row(Reader, 1));
    end;

    [Test]
    procedure TransferFields_TemporaryGetNoCalc()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BFR Src" temporary;
        Tgt: Record "LT BFR Row" temporary;
        Reader: Record "LT BFR Row" temporary;
    begin
        Reader.Copy(Tgt, true);
        RunTransferUnloaded(Observer, Src, Tgt, Reader);
        Observer.Finish();
    end;

    [Test]
    procedure TransferFields_StoredGetNoCalc()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BFR Src";
        Tgt: Record "LT BFR Row";
        Reader: Record "LT BFR Row";
    begin
        ResetStored();
        RunTransferUnloaded(Observer, Src, Tgt, Reader);
        Observer.Finish();
    end;

    // Cell 5: a Blob read into a Variant (from the field and from a FieldRef), the source refilled before the Variant is used.
    local procedure RunVariant(var Observer: Codeunit "Probe Observer"; var Src: Record "LT BFR Src"; var Tgt: Record "LT BFR Row"; var Reader: Record "LT BFR Row")
    var
        RR: RecordRef;
        SrcRR: RecordRef;
        FR: FieldRef;
        V: Variant;
    begin
        // a: Variant from the field, refill, field := Variant
        Fill(Src, 'alpha');
        V := Src.Data;
        Fill(Src, 'beta');
        Tgt.Data := V;
        Observer.Observe('a h', Hand(Tgt));
        // b: Variant from the field, refill, FieldRef.Value := Variant, Insert, refill again
        Clear(Tgt.Data);
        Fill(Src, 'alpha');
        V := Src.Data;
        Fill(Src, 'beta');
        Tgt."Key" := 1;
        RR.GetTable(Tgt);
        FR := RR.Field(Tgt.FieldNo(Data));
        FR.Value := V;
        RR.SetTable(Tgt);
        Tgt.Insert();
        Observer.Observe('b r1', Row(Reader, 1));
        Fill(Src, 'gamma');
        Observer.Observe('b refill r1', Row(Reader, 1));
        Observer.Observe('b refill h', Hand(Tgt));
        // c: Variant from a FieldRef of the source's RecordRef, refill the source, field := Variant
        Clear(Tgt.Data);
        Fill(Src, 'alpha');
        SrcRR.GetTable(Src);
        V := SrcRR.Field(2).Value;
        Fill(Src, 'beta');
        Tgt.Other := V;
        Observer.Observe('c other', OtherText(Tgt));
        // d: FieldRef.Value := FieldRef.Value of the source's RecordRef, Insert, refill the source
        Fill(Src, 'alpha');
        SrcRR.GetTable(Src);
        Clear(Tgt.Data);
        Tgt."Key" := 2;
        RR.GetTable(Tgt);
        FR := RR.Field(Tgt.FieldNo(Data));
        FR.Value := SrcRR.Field(2).Value;
        RR.SetTable(Tgt);
        Tgt.Insert();
        Fill(Src, 'beta');
        Observer.Observe('d r2', Row(Reader, 2));
        Observer.Observe('d r1', Row(Reader, 1));
    end;

    local procedure OtherText(var Rec: Record "LT BFR Row"): Text
    var
        IS: InStream;
        Txt: Text;
    begin
        Rec.Other.CreateInStream(IS);
        IS.ReadText(Txt);
        exit(HasValueText(Rec.Other.HasValue()) + Txt);
    end;

    [Test]
    procedure Variant_Temporary()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BFR Src" temporary;
        Tgt: Record "LT BFR Row" temporary;
        Reader: Record "LT BFR Row" temporary;
    begin
        Reader.Copy(Tgt, true);
        RunVariant(Observer, Src, Tgt, Reader);
        Observer.Finish();
    end;

    [Test]
    procedure Variant_Stored()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BFR Src";
        Tgt: Record "LT BFR Row";
        Reader: Record "LT BFR Row";
    begin
        ResetStored();
        RunVariant(Observer, Src, Tgt, Reader);
        Observer.Finish();
    end;
}

// The shapes of the review of the runtime change (one fresh pair of records per shape). Rd = HasValue and text of the record in hand,
// Stored(K) = the database row K (Get, HasValue, CalcFields, text).
codeunit 97747 "LT FieldRef Blob Shapes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure W(var R: Record "LT BFR Row"; T: Text)
    var
        OS: OutStream;
    begin
        R.Data.CreateOutStream(OS);
        OS.WriteText(T);
    end;

    local procedure HasValueText(HV: Boolean): Text
    begin
        if HV then
            exit('hv:');
        exit('nohv:');
    end;

    local procedure Rd(var R: Record "LT BFR Row"): Text
    var
        IS: InStream;
        T: Text;
    begin
        R.Data.CreateInStream(IS);
        IS.ReadText(T);
        exit(HasValueText(R.Data.HasValue()) + T);
    end;

    local procedure RdO(var R: Record "LT BFR Row"): Text
    var
        IS: InStream;
        T: Text;
    begin
        R.Other.CreateInStream(IS);
        IS.ReadText(T);
        exit(HasValueText(R.Other.HasValue()) + T);
    end;

    local procedure RdRR(var RR: RecordRef): Text
    var
        R: Record "LT BFR Row" temporary;
    begin
        RR.SetTable(R);
        exit(Rd(R));
    end;

    local procedure Stored(K: Integer): Text
    var
        R: Record "LT BFR Row";
        IS: InStream;
        T: Text;
        HV: Boolean;
    begin
        if not R.Get(K) then
            exit('<no row>');
        HV := R.Data.HasValue();
        R.CalcFields(Data);
        R.Data.CreateInStream(IS);
        IS.ReadText(T);
        exit(HasValueText(HV) + T);
    end;

    local procedure ResetStored()
    var
        Row: Record "LT BFR Row";
        Src: Record "LT BFR Src";
    begin
        Row.DeleteAll();
        Src.DeleteAll();
    end;

    // ---- FieldRef.Value, temporary target (RecordRef.GetTable of a temporary record) ----
    local procedure A01(): Text
    var
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR Row" temporary;
        RR: RecordRef;
    begin
        W(Src, 'alpha');
        RR.GetTable(Dst);
        RR.Field(2).Value := Src.Data;
        W(Src, 'beta');
        RR.SetTable(Dst);
        exit(Rd(Dst));
    end;

    local procedure A02(): Text
    var
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR Row" temporary;
        RR: RecordRef;
    begin
        W(Src, 'alpha');
        RR.GetTable(Dst);
        RR.Field(2).Value := Src.Data;
        Clear(Src.Data);
        RR.SetTable(Dst);
        exit(Rd(Dst));
    end;

    local procedure A03(): Text
    var
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR Row" temporary;
        RR: RecordRef;
    begin
        W(Src, 'alpha');
        RR.GetTable(Dst);
        RR.Field(2).Value := Src.Data;
        RR.SetTable(Dst);
        W(Dst, 'zz');
        exit('src=' + Rd(Src) + ' dst=' + Rd(Dst));
    end;

    local procedure A11(): Text
    var
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR Row" temporary;
        RS: RecordRef;
        RR: RecordRef;
    begin
        W(Src, 'alpha');
        RS.GetTable(Src);
        RR.GetTable(Dst);
        RR.Field(2).Value := RS.Field(2).Value;
        Clear(Src.Data);
        RR.SetTable(Dst);
        exit('dst=' + Rd(Dst) + ' srcrr=' + RdRR(RS));
    end;

    local procedure A12(): Text
    var
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR Row" temporary;
        RR: RecordRef;
        V: Variant;
    begin
        W(Src, 'alpha');
        V := Src.Data;
        RR.GetTable(Dst);
        RR.Field(2).Value := V;
        Clear(Src.Data);
        RR.SetTable(Dst);
        exit(Rd(Dst));
    end;

    local procedure A13(): Text
    var
        Dst: Record "LT BFR Row" temporary;
        RR: RecordRef;
    begin
        W(Dst, 'alpha');
        RR.GetTable(Dst);
        RR.Field(3).Value := RR.Field(2).Value;
        RR.SetTable(Dst);
        W(Dst, 'zz');
        exit('data=' + Rd(Dst) + ' other=' + RdO(Dst));
    end;

    local procedure A14(): Text
    var
        Dst: Record "LT BFR Row" temporary;
        RR: RecordRef;
    begin
        W(Dst, 'alpha');
        RR.GetTable(Dst);
        RR.Field(2).Value := Dst.Data;
        W(Dst, 'zz');
        exit('dst=' + Rd(Dst) + ' rr=' + RdRR(RR));
    end;

    local procedure A16(): Text
    var
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR Row" temporary;
        RR: RecordRef;
    begin
        W(Src, 'alpha');
        RR.GetTable(Dst);
        RR.Field(2).Value := Src.Data;
        RR.Field(2).Value := Src.Data;
        RR.Field(3).Value := Src.Data;
        W(Src, 'beta');
        RR.SetTable(Dst);
        exit('data=' + Rd(Dst) + ' other=' + RdO(Dst));
    end;

    [Test]
    procedure FieldRefValue_TempTarget_Shapes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('A01 rewrite source', A01());
        Observer.Observe('A02 clear source', A02());
        Observer.Observe('A03 write target', A03());
        Observer.Observe('A11 fieldref to fieldref', A11());
        Observer.Observe('A12 variant', A12());
        Observer.Observe('A13 same record other field', A13());
        Observer.Observe('A14 same field', A14());
        Observer.Observe('A16 two writes', A16());
        Observer.Finish();
    end;

    // ---- FieldRef.Value, stored target ----
    local procedure A04(): Text
    var
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR Row";
        RR: RecordRef;
    begin
        W(Src, 'alpha');
        RR.Open(Database::"LT BFR Row");
        RR.Field(2).Value := Src.Data;
        W(Src, 'beta');
        RR.SetTable(Dst);
        exit(Rd(Dst));
    end;

    local procedure A05(): Text
    var
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR Row";
        RR: RecordRef;
    begin
        W(Src, 'alpha');
        RR.GetTable(Dst);
        RR.Field(2).Value := Src.Data;
        Clear(Src.Data);
        RR.SetTable(Dst);
        exit(Rd(Dst));
    end;

    local procedure A06(): Text
    var
        Src: Record "LT BFR Row" temporary;
        RR: RecordRef;
    begin
        W(Src, 'alpha');
        RR.Open(Database::"LT BFR Row");
        RR.Field(1).Value := 6;
        RR.Field(2).Value := Src.Data;
        RR.Insert();
        W(Src, 'beta');
        exit('row=' + Stored(6) + ' rr=' + RdRR(RR));
    end;

    local procedure A07(): Text
    var
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR Row";
        RR: RecordRef;
    begin
        W(Src, 'alpha');
        RR.Open(Database::"LT BFR Row");
        RR.Field(2).Value := Src.Data;
        RR.SetTable(Dst);
        W(Dst, 'zz');
        exit('src=' + Rd(Src) + ' dst=' + Rd(Dst));
    end;

    [Test]
    procedure FieldRefValue_StoredTarget_Shapes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ResetStored();
        Observer.Observe('A04 open rewrite source', A04());
        Observer.Observe('A05 gettable clear source', A05());
        Observer.Observe('A06 insert rewrite source', A06());
        Observer.Observe('A07 write target', A07());
        Observer.Finish();
    end;

    // ---- FieldRef.Value, source rows ----
    local procedure A08(): Text
    var
        Src: Record "LT BFR Row";
        Dst: Record "LT BFR Row" temporary;
        RR: RecordRef;
    begin
        Src."Key" := 8;
        W(Src, 'alpha');
        Src.Insert();
        Src.Get(8);
        Src.CalcFields(Data);
        RR.GetTable(Dst);
        RR.Field(2).Value := Src.Data;
        Clear(Src.Data);
        RR.SetTable(Dst);
        exit(Rd(Dst));
    end;

    local procedure A09(): Text
    var
        Src: Record "LT BFR Row";
        Dst: Record "LT BFR Row" temporary;
        RR: RecordRef;
        Hand: Text;
    begin
        Src."Key" := 9;
        W(Src, 'alpha');
        Src.Insert();
        Src.Get(9);
        RR.GetTable(Dst);
        RR.Field(2).Value := Src.Data;
        RR.SetTable(Dst);
        Hand := Rd(Dst);
        Dst."Key" := 1;
        Dst.Insert();
        Dst.Get(1);
        Dst.CalcFields(Data);
        exit('hand=' + Hand + ' row=' + Rd(Dst));
    end;

    local procedure A10(): Text
    var
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR Row" temporary;
        RR: RecordRef;
    begin
        Src."Key" := 1;
        W(Src, 'alpha');
        Src.Insert();
        Src.Get(1);
        RR.GetTable(Dst);
        RR.Field(2).Value := Src.Data;
        Src.CalcFields(Data);
        RR.SetTable(Dst);
        exit(Rd(Dst));
    end;

    local procedure A15(): Text
    var
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR Row" temporary;
        RR: RecordRef;
    begin
        W(Src, 'alpha');
        RR.GetTable(Dst);
        RR.Field(1).Value := 15;
        RR.Field(2).Value := Src.Data;
        RR.Insert();
        W(Src, 'beta');
        RR.SetTable(Dst);
        Dst.Get(15);
        Dst.CalcFields(Data);
        exit(Rd(Dst));
    end;

    local procedure T1(): Text
    var
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR Row" temporary;
        RR: RecordRef;
    begin
        W(Src, 'alpha');
        RR.Open(Database::"LT BFR Row", true);
        RR.Field(2).Value := Src.Data;
        W(Src, 'beta');
        RR.SetTable(Dst);
        exit(Rd(Dst));
    end;

    local procedure MkVariant(): Variant
    var
        L: Record "LT BFR Row" temporary;
        V: Variant;
    begin
        W(L, 'alpha');
        V := L.Data;
        exit(V);
    end;

    local procedure T3(): Text
    var
        Dst: Record "LT BFR Row" temporary;
        RR: RecordRef;
    begin
        RR.GetTable(Dst);
        RR.Field(2).Value := MkVariant();
        RR.SetTable(Dst);
        exit(Rd(Dst));
    end;

    local procedure SetVia(var RR: RecordRef; var Src: Record "LT BFR Row")
    var
        FR: FieldRef;
        FR3: FieldRef;
    begin
        FR := RR.Field(2);
        FR.Value := Src.Data;
        FR3 := RR.Field(3);
        FR3.Value := FR.Value;
    end;

    local procedure T4(): Text
    var
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR Row" temporary;
        RR: RecordRef;
    begin
        W(Src, 'alpha');
        RR.GetTable(Dst);
        SetVia(RR, Src);
        W(Src, 'beta');
        RR.SetTable(Dst);
        exit('data=' + Rd(Dst) + ' other=' + RdO(Dst));
    end;

    [Test]
    procedure FieldRefValue_SourceShapes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ResetStored();
        Observer.Observe('A08 stored calcfields clear source', A08());
        Observer.Observe('A09 stored no calcfields', A09());
        Observer.Observe('A10 temp row no calcfields then calc', A10());
        Observer.Observe('A15 insert via recordref rewrite source', A15());
        Observer.Observe('T1 open temporary', T1());
        Observer.Observe('T3 variant from function', T3());
        Observer.Observe('T4 var recordref two fields', T4());
        Observer.Finish();
    end;

    [Test]
    procedure FieldRefValidate_Temp_RewriteSource()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR Row" temporary;
        RR: RecordRef;
        FR: FieldRef;
    begin
        W(Src, 'alpha');
        RR.GetTable(Dst);
        FR := RR.Field(2);
        FR.Validate(Src.Data);
        W(Src, 'beta');
        RR.SetTable(Dst);
        Observer.Observe('A17 validate', Rd(Dst));
        Observer.Observe('A17 source', Rd(Src));
        Observer.Finish();
    end;

    [Test]
    procedure FieldRefValue_TableTypeTemporary_OpenPlain()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR TmpRow";
        RR: RecordRef;
        IS: InStream;
        T: Text;
    begin
        W(Src, 'alpha');
        RR.Open(Database::"LT BFR TmpRow");
        RR.Field(2).Value := Src.Data;
        W(Src, 'beta');
        RR.SetTable(Dst);
        Dst.Data.CreateInStream(IS);
        IS.ReadText(T);
        Observer.Observe('T2 tabletype temporary', HasValueText(Dst.Data.HasValue()) + T);
        Observer.Finish();
    end;

    // ---- Direct assignment (0) against FieldRef.Value (1), with the life of the target: Insert, CalcFields, Get, Modify ----
    local procedure Put(var Src: Record "LT BFR Row"; var Dst: Record "LT BFR Row"; Mode: Integer)
    var
        RR: RecordRef;
    begin
        if Mode = 0 then
            Dst.Data := Src.Data
        else begin
            RR.GetTable(Dst);
            RR.Field(2).Value := Src.Data;
            RR.SetTable(Dst);
        end;
    end;

    local procedure Life(var Observer: Codeunit "Probe Observer"; P: Text; var Dst: Record "LT BFR Row"; K: Integer)
    begin
        Observer.Observe(P + ' hand', Rd(Dst));
        Dst."Key" := K;
        Dst.Insert();
        Observer.Observe(P + ' insert', Rd(Dst));
        Dst.CalcFields(Data);
        Observer.Observe(P + ' calc', Rd(Dst));
        Dst.Get(K);
        Observer.Observe(P + ' get', Rd(Dst));
        Dst.CalcFields(Data);
        Observer.Observe(P + ' getcalc', Rd(Dst));
        W(Dst, 'Q');
        Dst.Modify();
        Dst.Get(K);
        Dst.CalcFields(Data);
        Observer.Observe(P + ' modify', Rd(Dst));
    end;

    local procedure S1(var Observer: Codeunit "Probe Observer"; Mode: Integer)
    var
        Src: Record "LT BFR Row";
        Dst: Record "LT BFR Row" temporary;
        P: Text;
    begin
        P := 'S1.' + Format(Mode);
        Src."Key" := 100 + Mode;
        W(Src, 'alpha');
        Src.Insert();
        Src.Get(100 + Mode);
        Src.CalcFields(Data);
        Put(Src, Dst, Mode);
        Life(Observer, P, Dst, 1);
        Src.CalcFields(Data);
        Observer.Observe(P + ' src', Rd(Src));
    end;

    local procedure S2(var Observer: Codeunit "Probe Observer"; Mode: Integer)
    var
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR Row" temporary;
        P: Text;
    begin
        P := 'S2.' + Format(Mode);
        Src."Key" := 1;
        W(Src, 'alpha');
        Src.Insert();
        Put(Src, Dst, Mode);
        Clear(Src.Data);
        Life(Observer, P, Dst, 2);
        Src.Get(1);
        Src.CalcFields(Data);
        Observer.Observe(P + ' srcrow', Rd(Src));
    end;

    local procedure S3(var Observer: Codeunit "Probe Observer"; Mode: Integer)
    var
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR Row" temporary;
        P: Text;
    begin
        P := 'S3.' + Format(Mode);
        Src."Key" := 1;
        W(Src, 'alpha');
        Src.Insert();
        Src.Get(1);
        Src.CalcFields(Data);
        Put(Src, Dst, Mode);
        W(Src, 'zz');
        Life(Observer, P, Dst, 2);
        Src.Get(1);
        Src.CalcFields(Data);
        Observer.Observe(P + ' srcrow', Rd(Src));
    end;

    local procedure S4(var Observer: Codeunit "Probe Observer"; Mode: Integer)
    var
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR Row" temporary;
        OS: OutStream;
        P: Text;
    begin
        P := 'S4.' + Format(Mode);
        Src.Data.CreateOutStream(OS);
        OS.WriteText('al');
        Put(Src, Dst, Mode);
        OS.WriteText('pha');
        Observer.Observe(P + ' src', Rd(Src));
        Life(Observer, P, Dst, 3);
    end;

    local procedure S5(var Observer: Codeunit "Probe Observer"; Mode: Integer)
    var
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR Row" temporary;
        P: Text;
    begin
        P := 'S5.' + Format(Mode);
        W(Dst, 'old');
        Put(Src, Dst, Mode);
        W(Src, 'new');
        Life(Observer, P, Dst, 4);
    end;

    [Test]
    procedure Life_StoredLoadedSource()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ResetStored();
        S1(Observer, 0);
        S1(Observer, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Life_TempInsertedSource()
    var
        Observer: Codeunit "Probe Observer";
    begin
        S2(Observer, 0);
        S2(Observer, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Life_TempInsertedCalcSource()
    var
        Observer: Codeunit "Probe Observer";
    begin
        S3(Observer, 0);
        S3(Observer, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Life_OpenOutStreamSource()
    var
        Observer: Codeunit "Probe Observer";
    begin
        S4(Observer, 0);
        S4(Observer, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Life_EmptySource()
    var
        Observer: Codeunit "Probe Observer";
    begin
        S5(Observer, 0);
        S5(Observer, 1);
        Observer.Finish();
    end;

    // ---- RecordRef.GetTable / SetTable ----
    local procedure G01(): Text
    var
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR Row" temporary;
        RR: RecordRef;
    begin
        W(Src, 'alpha');
        RR.GetTable(Src);
        W(Src, 'beta');
        RR.SetTable(Dst);
        exit(Rd(Dst));
    end;

    local procedure G02(): Text
    var
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR Row" temporary;
        RR: RecordRef;
    begin
        W(Src, 'alpha');
        RR.GetTable(Src);
        Clear(Src.Data);
        RR.SetTable(Dst);
        exit(Rd(Dst));
    end;

    local procedure G03(): Text
    var
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR Row" temporary;
        Dst2: Record "LT BFR Row" temporary;
        RR: RecordRef;
    begin
        W(Src, 'alpha');
        RR.GetTable(Src);
        RR.SetTable(Dst);
        W(Dst, 'zz');
        RR.SetTable(Dst2);
        exit('src=' + Rd(Src) + ' dst2=' + Rd(Dst2));
    end;

    local procedure G04(): Text
    var
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR Row" temporary;
        Dst2: Record "LT BFR Row" temporary;
        RR: RecordRef;
    begin
        W(Src, 'alpha');
        RR.GetTable(Src);
        RR.SetTable(Dst);
        Clear(Dst.Data);
        RR.SetTable(Dst2);
        exit('src=' + Rd(Src) + ' dst2=' + Rd(Dst2));
    end;

    local procedure G05(): Text
    var
        Src: Record "LT BFR Row";
        Dst: Record "LT BFR Row";
        RR: RecordRef;
    begin
        W(Src, 'alpha');
        RR.GetTable(Src);
        W(Src, 'beta');
        RR.SetTable(Dst);
        exit(Rd(Dst));
    end;

    local procedure G06(): Text
    var
        Src: Record "LT BFR Row";
        RR: RecordRef;
    begin
        Src."Key" := 26;
        W(Src, 'alpha');
        RR.GetTable(Src);
        Clear(Src.Data);
        RR.Insert();
        exit('row=' + Stored(26) + ' src=' + Rd(Src));
    end;

    local procedure G07(): Text
    var
        Src: Record "LT BFR Row" temporary;
        RR: RecordRef;
    begin
        Src."Key" := 27;
        W(Src, 'alpha');
        RR.GetTable(Src);
        RR.Insert();
        Clear(Src.Data);
        Src.Get(27);
        Src.CalcFields(Data);
        exit(Rd(Src));
    end;

    local procedure G08(): Text
    var
        Buf: Record "LT BFR Row" temporary;
        Line: Record "LT BFR Row" temporary;
        RR: RecordRef;
        A: Text;
    begin
        Buf."Key" := 1;
        W(Buf, 'first');
        RR.GetTable(Buf);
        RR.SetTable(Line);
        Line.Insert();
        Clear(Buf.Data);
        Buf."Key" := 2;
        W(Buf, 'second');
        RR.GetTable(Buf);
        RR.SetTable(Line);
        Line.Insert();
        Line.Get(1);
        Line.CalcFields(Data);
        A := Rd(Line);
        Line.Get(2);
        Line.CalcFields(Data);
        exit('r1=' + A + ' r2=' + Rd(Line));
    end;

    [Test]
    procedure GetTableSetTable_Shapes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ResetStored();
        Observer.Observe('G06 stored gettable clear source insert', G06());
        Observer.Observe('G01 rewrite source', G01());
        Observer.Observe('G02 clear source', G02());
        Observer.Observe('G03 write target settable again', G03());
        Observer.Observe('G04 clear target settable again', G04());
        Observer.Observe('G05 stored rewrite source', G05());
        Observer.Observe('G07 insert then clear source', G07());
        Observer.Observe('G08 importer loop', G08());
        Observer.Finish();
    end;

    // ---- TransferFields ----
    local procedure F01(): Text
    var
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR Row" temporary;
    begin
        W(Src, 'alpha');
        Dst.TransferFields(Src);
        W(Src, 'beta');
        exit(Rd(Dst));
    end;

    local procedure F02(): Text
    var
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR Row" temporary;
    begin
        W(Src, 'alpha');
        Dst.TransferFields(Src);
        Clear(Src.Data);
        exit(Rd(Dst));
    end;

    local procedure F03(): Text
    var
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR Row" temporary;
    begin
        W(Src, 'alpha');
        Dst.TransferFields(Src);
        W(Dst, 'zz');
        exit('src=' + Rd(Src) + ' dst=' + Rd(Dst));
    end;

    local procedure F04(): Text
    var
        Src: Record "LT BFR Row";
        Dst: Record "LT BFR Row";
    begin
        Src."Key" := 34;
        W(Src, 'alpha');
        Dst.TransferFields(Src);
        Clear(Src.Data);
        Dst.Insert();
        exit('hand=' + Rd(Dst) + ' row=' + Stored(34));
    end;

    local procedure F05(): Text
    var
        Src: Record "LT BFR Row" temporary;
        Dst: Record "LT BFR Src" temporary;
        IS: InStream;
        T: Text;
    begin
        W(Src, 'alpha');
        Dst.TransferFields(Src);
        Clear(Src.Data);
        Dst.Data.CreateInStream(IS);
        IS.ReadText(T);
        exit(HasValueText(Dst.Data.HasValue()) + T);
    end;

    local procedure F06(): Text
    var
        Buf: Record "LT BFR Row" temporary;
        Line: Record "LT BFR Row" temporary;
        A: Text;
    begin
        W(Buf, 'first');
        Line.TransferFields(Buf);
        Line."Key" := 1;
        Line.Insert();
        Clear(Buf.Data);
        W(Buf, 'second');
        Line.TransferFields(Buf);
        Line."Key" := 2;
        Line.Insert();
        Line.Get(1);
        Line.CalcFields(Data);
        A := Rd(Line);
        Line.Get(2);
        Line.CalcFields(Data);
        exit('r1=' + A + ' r2=' + Rd(Line));
    end;

    [Test]
    procedure TransferFields_Shapes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ResetStored();
        Observer.Observe('F04 stored clear source insert', F04());
        Observer.Observe('F01 rewrite source', F01());
        Observer.Observe('F02 clear source', F02());
        Observer.Observe('F03 write target', F03());
        Observer.Observe('F05 other table clear source', F05());
        Observer.Observe('F06 importer loop', F06());
        Observer.Finish();
    end;
}
