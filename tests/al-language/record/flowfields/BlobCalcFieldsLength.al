// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-calcfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 74450 below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: CalcFields on a Blob field and then HasValue / Length / CreateInStream, with and without content (issue #184 item 23): a fresh row, a row after Get (is the blob loaded without CalcFields), after CalcFields, content written to an OutStream and not yet modified, after Modify, after Clear of the field, FieldRef.CalcField on the blob.
// BC versions: 29 (27 and 28 by CI)

table 74450 "LT BlobCalc Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 74451 "LT BlobCalc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Store(Id: Integer; Content: Text)
    var
        Row: Record "LT BlobCalc Row";
        OutS: OutStream;
    begin
        Row.Init();
        Row.Id := Id;
        if Content <> '' then begin
            Row.Data.CreateOutStream(OutS);
            OutS.WriteText(Content);
        end;
        Row.Insert();
    end;

    local procedure ReadBack(var Row: Record "LT BlobCalc Row"): Text
    var
        InS: InStream;
        Result: Text;
    begin
        Row.Data.CreateInStream(InS);
        InS.ReadText(Result);
        exit(Result);
    end;

    [Test]
    procedure BlobCalcFields_WithContent_Result()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BlobCalc Row";
    begin
        Row.DeleteAll();
        Store(1, 'hello');
        Row.Get(1);
        Observer.Observe('get_hasvalue', Format(Row.Data.HasValue()));
        Observer.Observe('get_length', Format(Row.Data.Length()));
        Row.CalcFields(Data);
        Observer.Observe('calc_hasvalue', Format(Row.Data.HasValue()));
        Observer.Observe('calc_length', Format(Row.Data.Length()));
        Observer.Observe('calc_read', ReadBack(Row));
        Observer.Expect('get_hasvalue', 'Yes');
        Observer.Expect('get_length', '11');
        Observer.Expect('calc_hasvalue', 'Yes');
        Observer.Expect('calc_length', '5');
        Observer.Expect('calc_read', 'hello');
        Observer.Verify();
    end;

    [Test]
    procedure BlobCalcFields_WithoutContent_Result()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BlobCalc Row";
    begin
        Row.DeleteAll();
        Store(2, '');
        Row.Get(2);
        Observer.Observe('get_hasvalue', Format(Row.Data.HasValue()));
        Row.CalcFields(Data);
        Observer.Observe('calc_hasvalue', Format(Row.Data.HasValue()));
        Observer.Observe('calc_length', Format(Row.Data.Length()));
        Observer.Observe('calc_read', '[' + ReadBack(Row) + ']');
        Observer.Expect('get_hasvalue', 'No');
        Observer.Expect('calc_hasvalue', 'No');
        Observer.Expect('calc_length', '0');
        Observer.Expect('calc_read', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure BlobCalcFields_UnsavedContent_Result()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BlobCalc Row";
        OutS: OutStream;
    begin
        Row.DeleteAll();
        Store(3, 'stored');
        Row.Get(3);
        Row.Data.CreateOutStream(OutS);
        OutS.WriteText('changed in memory');
        Observer.Observe('mem_length', Format(Row.Data.Length()));
        Row.CalcFields(Data);
        Observer.Observe('after_calc_length', Format(Row.Data.Length()));
        Observer.Observe('after_calc_read', ReadBack(Row));
        Observer.Expect('mem_length', '17');
        Observer.Expect('after_calc_length', '6');
        Observer.Expect('after_calc_read', 'stored');
        Observer.Verify();
    end;

    [Test]
    procedure BlobCalcFields_AfterModifyAndClear_Result()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BlobCalc Row";
        Other: Record "LT BlobCalc Row";
        OutS: OutStream;
    begin
        Row.DeleteAll();
        Store(4, 'one');
        Row.Get(4);
        Row.Data.CreateOutStream(OutS);
        OutS.WriteText('twotwo');
        Row.Modify();
        Other.Get(4);
        Other.CalcFields(Data);
        Observer.Observe('modified_length', Format(Other.Data.Length()));
        Observer.Observe('modified_read', ReadBack(Other));
        Clear(Other.Data);
        Observer.Observe('cleared_hasvalue', Format(Other.Data.HasValue()));
        Other.Modify();
        Other.Get(4);
        Other.CalcFields(Data);
        Observer.Observe('cleared_saved_hasvalue', Format(Other.Data.HasValue()));
        Observer.Observe('cleared_saved_length', Format(Other.Data.Length()));
        Observer.Expect('modified_length', '6');
        Observer.Expect('modified_read', 'twotwo');
        Observer.Expect('cleared_hasvalue', 'No');
        Observer.Expect('cleared_saved_hasvalue', 'No');
        Observer.Expect('cleared_saved_length', '0');
        Observer.Verify();
    end;

    [Test]
    procedure BlobCalcFields_FieldRefCalcField_Result()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BlobCalc Row";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Row.DeleteAll();
        Store(5, 'refdata');
        RecRef.Open(Database::"LT BlobCalc Row");
        RecRef.Field(1).SetRange(5);
        RecRef.FindFirst();
        FldRef := RecRef.Field(2);
        Observer.Observe('class', Format(FldRef.Class));
        Observer.Observe('calc_result', Format(FldRef.CalcField()));
        Observer.Observe('type', Format(FldRef.Type));
        RecRef.Close();
        RecRef.Open(Database::"LT BlobCalc Row");
        RecRef.Field(1).SetRange(5);
        RecRef.FindFirst();
        FldRef := RecRef.Field(2);
        FldRef.CalcField();
        Observer.Observe('type_after_calc', Format(FldRef.Type));
        Observer.Observe('value_length_nonzero', Format(Format(FldRef.Value) <> ''));
        Observer.Expect('class', 'Normal');
        Observer.Expect('calc_result', 'Yes');
        Observer.Expect('type', 'BLOB');
        Observer.Expect('type_after_calc', 'BLOB');
        Observer.Expect('value_length_nonzero', 'Yes');
        Observer.Verify();
    end;

    // Writer RF (AL Runner issue 5681): a Blob written on a record read with Get WITHOUT CalcFields, then Modify, then read back through
    // another variable with Get + CalcFields. The same with CalcFields before the write, a shorter value over a longer stored one (does
    // any old byte remain), HasValue and Length before and after the write, two writes in a row, an OutStream created and not written,
    // Temp Blob FromRecord and ToRecordRef, Blob assignment from an unloaded Blob, and the Picture of Company Information. RfShown reads every byte as base64.
    // BC 29.0 answers: on a Blob not loaded by CalcFields, CreateOutStream starts from empty, so Modify stores exactly the new bytes (no old
    // byte remains). On a Blob loaded by CalcFields (or already written in memory), CreateOutStream writes over the old bytes from the start
    // and does not truncate: 'new' over 'a long stored value' stores 'newng stored value'. An OutStream created and not written leaves the
    // stored value alone. Assigning an unloaded Blob to another record's Blob empties the target. Before CalcFields, Length is the
    // stored (compressed) size, not the content length.
    local procedure RfShown(Id: Integer): Text
    var
        Fresh: Record "LT BlobCalc Row";
        Base64: Codeunit "Base64 Convert";
        InS: InStream;
        Txt: Text;
    begin
        Fresh.Get(Id);
        Fresh.CalcFields(Data);
        Fresh.Data.CreateInStream(InS);
        Txt := Base64.ToBase64(InS);
        exit(StrSubstNo('has=%1|len=%2|b64=%3', Fresh.Data.HasValue(), Fresh.Data.Length(), Txt));
    end;

    local procedure RfState(var Row: Record "LT BlobCalc Row"): Text
    begin
        exit(StrSubstNo('has=%1|len=%2', Row.Data.HasValue(), Row.Data.Length()));
    end;

    local procedure RfWrite(var Row: Record "LT BlobCalc Row"; Content: Text)
    var
        OutS: OutStream;
    begin
        Row.Data.CreateOutStream(OutS);
        OutS.WriteText(Content);
    end;

    [Test]
    procedure RF_GetWithoutCalcFields_ShorterWrite_Modify()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BlobCalc Row";
    begin
        Row.DeleteAll();
        Store(20, 'a long stored value');
        Row.Get(20);
        Observer.Observe('before write', RfState(Row));
        RfWrite(Row, 'new');
        Observer.Observe('after write', RfState(Row));
        Row.Modify();
        Observer.Observe('after modify', RfState(Row));
        Observer.Observe('read back', RfShown(20));
        Row.Get(20);
        Observer.Observe('same variable get', RfState(Row));
        Row.CalcFields(Data);
        Observer.Observe('same variable calc', RfState(Row));
        Observer.Expect('before write', 'has=Yes|len=25');
        Observer.Expect('after write', 'has=Yes|len=3');
        Observer.Expect('after modify', 'has=Yes|len=3');
        Observer.Expect('read back', 'has=Yes|len=3|b64=bmV3');
        Observer.Expect('same variable get', 'has=Yes|len=9');
        Observer.Expect('same variable calc', 'has=Yes|len=3');
        Observer.Verify();
    end;

    [Test]
    procedure RF_GetWithoutCalcFields_LongerWrite_Modify()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BlobCalc Row";
    begin
        Row.DeleteAll();
        Store(21, 'ab');
        Row.Get(21);
        Observer.Observe('before write', RfState(Row));
        RfWrite(Row, 'a much longer value');
        Observer.Observe('after write', RfState(Row));
        Row.Modify();
        Observer.Observe('read back', RfShown(21));
        Observer.Expect('before write', 'has=Yes|len=8');
        Observer.Expect('after write', 'has=Yes|len=19');
        Observer.Expect('read back', 'has=Yes|len=19|b64=YSBtdWNoIGxvbmdlciB2YWx1ZQ==');
        Observer.Verify();
    end;

    [Test]
    procedure RF_GetWithoutCalcFields_EmptyStoredBlob_Write_Modify()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BlobCalc Row";
    begin
        Row.DeleteAll();
        Store(22, '');
        Row.Get(22);
        Observer.Observe('before write', RfState(Row));
        RfWrite(Row, 'first content');
        Observer.Observe('after write', RfState(Row));
        Row.Modify();
        Observer.Observe('read back', RfShown(22));
        Observer.Expect('before write', 'has=No|len=0');
        Observer.Expect('after write', 'has=Yes|len=13');
        Observer.Expect('read back', 'has=Yes|len=13|b64=Zmlyc3QgY29udGVudA==');
        Observer.Verify();
    end;

    [Test]
    procedure RF_CalcFieldsBeforeWrite_ShorterWrite_Modify()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BlobCalc Row";
    begin
        Row.DeleteAll();
        Store(23, 'a long stored value');
        Row.Get(23);
        Row.CalcFields(Data);
        Observer.Observe('before write', RfState(Row));
        RfWrite(Row, 'new');
        Observer.Observe('after write', RfState(Row));
        Row.Modify();
        Observer.Observe('after modify', RfState(Row));
        Observer.Observe('read back', RfShown(23));
        Observer.Expect('before write', 'has=Yes|len=19');
        Observer.Expect('after write', 'has=Yes|len=19');
        Observer.Expect('after modify', 'has=Yes|len=19');
        Observer.Expect('read back', 'has=Yes|len=19|b64=bmV3b25nIHN0b3JlZCB2YWx1ZQ==');
        Observer.Verify();
    end;

    [Test]
    procedure RF_GetWithoutCalcFields_TwoWrites()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BlobCalc Row";
        OutS: OutStream;
    begin
        Row.DeleteAll();
        Store(24, 'a long stored value');
        // two OutStreams one after the other, then one Modify
        Row.Get(24);
        RfWrite(Row, 'first write');
        RfWrite(Row, 'two');
        Observer.Observe('two streams state', RfState(Row));
        Row.Modify();
        Observer.Observe('two streams read back', RfShown(24));
        // one OutStream written twice
        Row.Get(24);
        Row.Data.CreateOutStream(OutS);
        OutS.WriteText('one');
        OutS.WriteText('more');
        Row.Modify();
        Observer.Observe('one stream two texts read back', RfShown(24));
        // write and Modify twice on the same variable without a Get in between
        Row.Get(24);
        RfWrite(Row, 'third value');
        Row.Modify();
        RfWrite(Row, 'x');
        Row.Modify();
        Observer.Observe('two modifies read back', RfShown(24));
        Observer.Expect('two streams state', 'has=Yes|len=11');
        Observer.Expect('two streams read back', 'has=Yes|len=11|b64=dHdvc3Qgd3JpdGU=');
        Observer.Expect('one stream two texts read back', 'has=Yes|len=7|b64=b25lbW9yZQ==');
        Observer.Expect('two modifies read back', 'has=Yes|len=11|b64=eGhpcmQgdmFsdWU=');
        Observer.Verify();
    end;

    [Test]
    procedure RF_GetWithoutCalcFields_OutStreamNotWritten_Modify()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BlobCalc Row";
        OutS: OutStream;
    begin
        Row.DeleteAll();
        Store(25, 'stored');
        Row.Get(25);
        Row.Data.CreateOutStream(OutS);
        Observer.Observe('after create', RfState(Row));
        Row.Modify();
        Observer.Observe('read back', RfShown(25));
        Observer.Expect('after create', 'has=Yes|len=12');
        Observer.Expect('read back', 'has=Yes|len=6|b64=c3RvcmVk');
        Observer.Verify();
    end;

    [Test]
    procedure RF_GetWithoutCalcFields_TempBlobToRecord_Modify()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BlobCalc Row";
        TempBlob: Codeunit "Temp Blob";
        Source: Codeunit "Temp Blob";
        RecRef: RecordRef;
        OutS: OutStream;
        InS: InStream;
        Txt: Text;
    begin
        Row.DeleteAll();
        Store(26, 'a long stored value');
        Row.Get(26);
        Source.FromRecord(Row, Row.FieldNo(Data));
        Source.CreateInStream(InS);
        InS.ReadText(Txt);
        Observer.Observe('from record unloaded', StrSubstNo('len=%1|text=%2', Source.Length(), Txt));
        Observer.Observe('row after from record', RfState(Row));
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('tb');
        RecRef.GetTable(Row);
        TempBlob.ToRecordRef(RecRef, Row.FieldNo(Data));
        RecRef.SetTable(Row);
        Observer.Observe('after to record', RfState(Row));
        Row.Modify();
        Observer.Observe('read back', RfShown(26));
        Observer.Expect('from record unloaded', 'len=19|text=a long stored value');
        Observer.Expect('row after from record', 'has=Yes|len=25');
        Observer.Expect('after to record', 'has=Yes|len=2');
        Observer.Expect('read back', 'has=Yes|len=2|b64=dGI=');
        Observer.Verify();
    end;

    [Test]
    procedure RF_AssignFromUnloadedBlob_Modify()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "LT BlobCalc Row";
        Target: Record "LT BlobCalc Row";
    begin
        Source.DeleteAll();
        Store(27, 'source value');
        Store(28, 'target stored value');
        Source.Get(27);
        Target.Get(28);
        Target.Data := Source.Data;
        Observer.Observe('target after assign', RfState(Target));
        Target.Modify();
        Observer.Observe('unloaded source read back', RfShown(28));
        Source.Get(27);
        Source.CalcFields(Data);
        Target.Get(28);
        Target.Data := Source.Data;
        Target.Modify();
        Observer.Observe('loaded source read back', RfShown(28));
        Observer.Expect('target after assign', 'has=No|len=0');
        Observer.Expect('unloaded source read back', 'has=No|len=0|b64=');
        Observer.Expect('loaded source read back', 'has=Yes|len=12|b64=c291cmNlIHZhbHVl');
        Observer.Verify();
    end;

    local procedure RfPicture(): Text
    var
        Info: Record "Company Information";
        Base64: Codeunit "Base64 Convert";
        InS: InStream;
    begin
        Info.Get();
        Info.CalcFields(Picture);
        Info.Picture.CreateInStream(InS);
        exit(StrSubstNo('has=%1|len=%2|b64=%3', Info.Picture.HasValue(), Info.Picture.Length(), Base64.ToBase64(InS)));
    end;

    [Test]
    procedure RF_CompanyInformationPicture_GetWithoutCalcFields_Write()
    var
        Observer: Codeunit "Probe Observer";
        Info: Record "Company Information";
        Saved: Codeunit "Temp Blob";
        Base64: Codeunit "Base64 Convert";
        OutS: OutStream;
        InS: InStream;
        Inserted: Boolean;
        PngTxt: Text;
    begin
        PngTxt := 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
        if not Info.Get() then begin
            Info.Init();
            Info.Insert();
            Inserted := true;
        end;
        Info.CalcFields(Picture);
        Saved.FromRecord(Info, Info.FieldNo(Picture));
        // a known stored value first: 40 bytes of text
        Info.Get();
        Info.Picture.CreateOutStream(OutS);
        OutS.WriteText('0123456789012345678901234567890123456789');
        Info.Modify();
        // the write under test: Get without CalcFields, FromBase64 into the Picture, Modify
        Info.Get();
        Observer.Observe('before write', StrSubstNo('has=%1|len=%2', Info.Picture.HasValue(), Info.Picture.Length()));
        Info.Picture.CreateOutStream(OutS);
        Base64.FromBase64(PngTxt, OutS);
        Observer.Observe('after write', StrSubstNo('has=%1|len=%2', Info.Picture.HasValue(), Info.Picture.Length()));
        Info.Modify();
        Observer.Observe('png read back', RfPicture());
        Observer.Observe('png equals input', Format(RfPicture().EndsWith('|b64=' + PngTxt)));
        // a shorter value over the stored PNG
        Info.Get();
        Info.Picture.CreateOutStream(OutS);
        OutS.WriteText('xy');
        Info.Modify();
        Observer.Observe('short read back', RfPicture());
        // restore
        if Inserted then
            Info.Delete()
        else begin
            Info.Get();
            Clear(Info.Picture);
            if Saved.HasValue() then begin
                Info.Picture.CreateOutStream(OutS);
                Saved.CreateInStream(InS);
                CopyStream(OutS, InS);
            end;
            Info.Modify();
        end;
        Observer.Expect('before write', 'has=Yes|len=19');
        Observer.Expect('after write', 'has=Yes|len=70');
        Observer.Expect('png read back', 'has=Yes|len=70|b64=iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');
        Observer.Expect('png equals input', 'Yes');
        Observer.Expect('short read back', 'has=Yes|len=2|b64=eHk=');
        Observer.Verify();
    end;
}
