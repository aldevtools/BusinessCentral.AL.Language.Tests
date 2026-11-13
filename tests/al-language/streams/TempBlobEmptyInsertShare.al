// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-insert-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: Probe Observer (codeunit 69160); Excel Buffer (Base Application); own tables 75230, 75231,
//   helper codeunit 75232; test codeunits 75235 to 75238
// Probe: written against real BC for al-runner issue 6924 (an outside reporter's Excel import that failed only on the
//   runner). Related pins: streams/TestBlobUncommittedWriteIsolation.al (same key, write after Insert),
//   streams/TestBlobCalcFieldsUncommittedWrite.al (Clear then Get, same key), streams/BlobCopyNeighbors.al.
// Facts: a temporary row inserted while its Blob is empty, then the same record variable moves to another key
//   (:= or Validate, with or without Init), Clear(Blob) or not, writes text into its Blob and inserts again or not.
//   What the earlier rows hold afterwards, read through the same variable (Get, SetRange + FindFirst) or a second
//   variable that shares the table (Copy(R, true)), for a temporary variable of a normal table and for a table with
//   TableType = Temporary. Control: the same key (no key change) reads the write back. Last, the Excel Buffer flow
//   that the reporter used: ReadSheet of a workbook with a short C2 and a 510-character D2 (the workbook is built
//   from base64 text in the test; no binary fixture).
//   Value format: 'none' = no row; 'nohv' = row found, HasValue false after CalcFields; 'hv:<text>' = HasValue true
//   and the text read from the Blob.
// What BC did: filled in from the observation (see the Expect lines).
// BC versions: 27.5+

table 75230 "LT TBS Row"
{
    DataClassification = SystemMetadata;

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

table 75231 "LT TBS Temp Row"
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

codeunit 75232 "LT TBS Lib"
{
    procedure Write(var R: Record "LT TBS Row" temporary; T: Text)
    var
        O: OutStream;
    begin
        R.Data.CreateOutStream(O, TextEncoding::UTF8);
        O.WriteText(T);
    end;

    procedure ReadGet(var R: Record "LT TBS Row" temporary; K: Integer): Text
    begin
        if not R.Get(K) then
            exit('none');
        exit(Content(R));
    end;

    procedure ReadFind(var R: Record "LT TBS Row" temporary; K: Integer): Text
    var
        Result: Text;
    begin
        R.SetRange(Key1, K);
        if R.FindFirst() then
            Result := Content(R)
        else
            Result := 'none';
        R.SetRange(Key1);
        exit(Result);
    end;

    procedure Content(var R: Record "LT TBS Row" temporary): Text
    var
        I: InStream;
        T: Text;
    begin
        R.CalcFields(Data);
        if not R.Data.HasValue() then
            exit('nohv');
        R.Data.CreateInStream(I, TextEncoding::UTF8);
        I.ReadText(T);
        exit('hv:' + T);
    end;

    procedure WriteTT(var R: Record "LT TBS Temp Row"; T: Text)
    var
        O: OutStream;
    begin
        R.Data.CreateOutStream(O, TextEncoding::UTF8);
        O.WriteText(T);
    end;

    procedure ReadGetTT(var R: Record "LT TBS Temp Row"; K: Integer): Text
    var
        I: InStream;
        T: Text;
    begin
        if not R.Get(K) then
            exit('none');
        R.CalcFields(Data);
        if not R.Data.HasValue() then
            exit('nohv');
        R.Data.CreateInStream(I, TextEncoding::UTF8);
        I.ReadText(T);
        exit('hv:' + T);
    end;
}

// Cells 1, 2, 3 and 9: one empty row, key change, write, second Insert or not.
codeunit 75235 "LT TBS Key Change"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Lib: Codeunit "LT TBS Lib";
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure InsertEmpty_KeyChangeClearWriteInsert_RowsHold()
    var
        R: Record "LT TBS Row" temporary;
    begin
        R.DeleteAll();
        R.Key1 := 1;
        R.Insert();
        R.Key1 := 2;
        Clear(R.Data);
        Lib.Write(R, 'X');
        R.Insert();
        Observer.Observe('get 1', Lib.ReadGet(R, 1));
        Observer.Observe('get 2', Lib.ReadGet(R, 2));
        Observer.Observe('find 1', Lib.ReadFind(R, 1));
        Observer.Observe('find 2', Lib.ReadFind(R, 2));
        Observer.Observe('count', Format(R.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure ClearInsertEmpty_KeyChangeClearWriteInsert_RowsHold()
    var
        R: Record "LT TBS Row" temporary;
    begin
        // The Excel Buffer shape: Clear(Blob) before every Insert, the empty row too.
        R.DeleteAll();
        R.Key1 := 1;
        Clear(R.Data);
        R.Insert();
        R.Key1 := 2;
        Clear(R.Data);
        Lib.Write(R, 'X');
        R.Insert();
        Observer.Observe('find 1', Lib.ReadFind(R, 1));
        Observer.Observe('find 2', Lib.ReadFind(R, 2));
        Observer.Finish();
    end;

    [Test]
    procedure InsertEmpty_KeyChangeWriteInsert_NoClear_RowsHold()
    var
        R: Record "LT TBS Row" temporary;
    begin
        R.DeleteAll();
        R.Key1 := 1;
        R.Insert();
        R.Key1 := 2;
        Lib.Write(R, 'X');
        R.Insert();
        Observer.Observe('get 1', Lib.ReadGet(R, 1));
        Observer.Observe('get 2', Lib.ReadGet(R, 2));
        Observer.Finish();
    end;

    [Test]
    procedure InsertEmpty_KeyChangeClearWrite_NoInsert_Row1Holds()
    var
        R: Record "LT TBS Row" temporary;
    begin
        R.DeleteAll();
        R.Key1 := 1;
        R.Insert();
        R.Key1 := 2;
        Clear(R.Data);
        Lib.Write(R, 'X');
        Observer.Observe('in hand', Lib.Content(R));
        Observer.Observe('get 1', Lib.ReadGet(R, 1));
        Observer.Observe('get 2', Lib.ReadGet(R, 2));
        Observer.Finish();
    end;

    [Test]
    procedure InsertEmpty_KeyChangeWrite_NoClearNoInsert_Row1Holds()
    var
        R: Record "LT TBS Row" temporary;
    begin
        R.DeleteAll();
        R.Key1 := 1;
        R.Insert();
        R.Key1 := 2;
        Lib.Write(R, 'X');
        Observer.Observe('get 1', Lib.ReadGet(R, 1));
        Observer.Finish();
    end;

    [Test]
    procedure InsertEmpty_SameKeyClearWrite_GetReads()
    var
        R: Record "LT TBS Row" temporary;
    begin
        // Control: no key change.
        R.DeleteAll();
        R.Key1 := 1;
        R.Insert();
        Clear(R.Data);
        Lib.Write(R, 'X');
        Observer.Observe('get 1', Lib.ReadGet(R, 1));
        Observer.Finish();
    end;

    [Test]
    procedure InsertEmpty_SameKeyWrite_NoClear_GetReads()
    var
        R: Record "LT TBS Row" temporary;
    begin
        // Control: no key change, no Clear.
        R.DeleteAll();
        R.Key1 := 1;
        R.Insert();
        Lib.Write(R, 'X');
        Observer.Observe('get 1', Lib.ReadGet(R, 1));
        Observer.Finish();
    end;
}

// Cells 4 and 5: more empty rows; a cleared row after a written one.
codeunit 75236 "LT TBS Sequence"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Lib: Codeunit "LT TBS Lib";
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure TwoEmptyRows_ThirdClearWriteInsert_RowsHold()
    var
        R: Record "LT TBS Row" temporary;
    begin
        R.DeleteAll();
        R.Key1 := 1;
        R.Insert();
        R.Key1 := 2;
        R.Insert();
        R.Key1 := 3;
        Clear(R.Data);
        Lib.Write(R, 'X');
        R.Insert();
        Observer.Observe('get 1', Lib.ReadGet(R, 1));
        Observer.Observe('get 2', Lib.ReadGet(R, 2));
        Observer.Observe('get 3', Lib.ReadGet(R, 3));
        Observer.Finish();
    end;

    [Test]
    procedure WrittenRow_ThenKeyChangeClearInsert_RowsHold()
    var
        R: Record "LT TBS Row" temporary;
    begin
        R.DeleteAll();
        R.Key1 := 1;
        R.Insert();
        R.Key1 := 2;
        Clear(R.Data);
        Lib.Write(R, 'X');
        R.Insert();
        R.Key1 := 3;
        Clear(R.Data);
        R.Insert();
        Observer.Observe('get 1', Lib.ReadGet(R, 1));
        Observer.Observe('get 2', Lib.ReadGet(R, 2));
        Observer.Observe('get 3', Lib.ReadGet(R, 3));
        Observer.Finish();
    end;

    [Test]
    procedure WrittenRow_ThenKeyChangeClearWriteInsert_RowsHold()
    var
        R: Record "LT TBS Row" temporary;
    begin
        R.DeleteAll();
        R.Key1 := 1;
        R.Insert();
        R.Key1 := 2;
        Clear(R.Data);
        Lib.Write(R, 'X');
        R.Insert();
        R.Key1 := 3;
        Clear(R.Data);
        Lib.Write(R, 'Y');
        R.Insert();
        Observer.Observe('get 1', Lib.ReadGet(R, 1));
        Observer.Observe('get 2', Lib.ReadGet(R, 2));
        Observer.Observe('get 3', Lib.ReadGet(R, 3));
        Observer.Finish();
    end;
}

// Cells 6, 7 and 8: Validate, Init, a second variable, a TableType = Temporary table.
codeunit 75237 "LT TBS Variants"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Lib: Codeunit "LT TBS Lib";
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure ValidateKey_ClearWriteInsert_RowsHold()
    var
        R: Record "LT TBS Row" temporary;
    begin
        R.DeleteAll();
        R.Validate(Key1, 1);
        R.Insert();
        R.Validate(Key1, 2);
        Clear(R.Data);
        Lib.Write(R, 'X');
        R.Insert();
        Observer.Observe('get 1', Lib.ReadGet(R, 1));
        Observer.Observe('get 2', Lib.ReadGet(R, 2));
        Observer.Finish();
    end;

    [Test]
    procedure InitThenKey_ClearWriteInsert_RowsHold()
    var
        R: Record "LT TBS Row" temporary;
    begin
        R.DeleteAll();
        R.Init();
        R.Key1 := 1;
        R.Insert();
        R.Init();
        R.Key1 := 2;
        Clear(R.Data);
        Lib.Write(R, 'X');
        R.Insert();
        Observer.Observe('get 1', Lib.ReadGet(R, 1));
        Observer.Observe('get 2', Lib.ReadGet(R, 2));
        Observer.Finish();
    end;

    [Test]
    procedure InitThenKey_WriteInsert_NoClear_RowsHold()
    var
        R: Record "LT TBS Row" temporary;
    begin
        R.DeleteAll();
        R.Init();
        R.Key1 := 1;
        R.Insert();
        R.Init();
        R.Key1 := 2;
        Lib.Write(R, 'X');
        R.Insert();
        Observer.Observe('get 1', Lib.ReadGet(R, 1));
        Observer.Observe('get 2', Lib.ReadGet(R, 2));
        Observer.Finish();
    end;

    [Test]
    procedure SharedCopy_ReadsRow1_AfterKeyChangeClearWriteInsert()
    var
        R: Record "LT TBS Row" temporary;
        R2: Record "LT TBS Row" temporary;
    begin
        R.DeleteAll();
        R2.Copy(R, true);
        R.Key1 := 1;
        R.Insert();
        R.Key1 := 2;
        Clear(R.Data);
        Lib.Write(R, 'X');
        R.Insert();
        Observer.Observe('second get 1', Lib.ReadGet(R2, 1));
        Observer.Observe('second get 2', Lib.ReadGet(R2, 2));
        Observer.Finish();
    end;

    [Test]
    procedure SharedCopy_ReadsRow1_AfterKeyChangeClearWrite_NoInsert()
    var
        R: Record "LT TBS Row" temporary;
        R2: Record "LT TBS Row" temporary;
    begin
        R.DeleteAll();
        R2.Copy(R, true);
        R.Key1 := 1;
        R.Insert();
        R.Key1 := 2;
        Clear(R.Data);
        Lib.Write(R, 'X');
        Observer.Observe('second get 1', Lib.ReadGet(R2, 1));
        Observer.Finish();
    end;

    [Test]
    procedure TempTable_KeyChangeClearWriteInsert_RowsHold()
    var
        R: Record "LT TBS Temp Row";
    begin
        R.DeleteAll();
        R.Key1 := 1;
        R.Insert();
        R.Key1 := 2;
        Clear(R.Data);
        Lib.WriteTT(R, 'X');
        R.Insert();
        Observer.Observe('get 1', Lib.ReadGetTT(R, 1));
        Observer.Observe('get 2', Lib.ReadGetTT(R, 2));
        Observer.Finish();
    end;

    [Test]
    procedure TempTable_KeyChangeWriteInsert_NoClear_RowsHold()
    var
        R: Record "LT TBS Temp Row";
    begin
        R.DeleteAll();
        R.Key1 := 1;
        R.Insert();
        R.Key1 := 2;
        Lib.WriteTT(R, 'X');
        R.Insert();
        Observer.Observe('get 1', Lib.ReadGetTT(R, 1));
        Observer.Observe('get 2', Lib.ReadGetTT(R, 2));
        Observer.Finish();
    end;

    [Test]
    procedure TempTable_SameKeyClearWrite_GetReads()
    var
        R: Record "LT TBS Temp Row";
    begin
        R.DeleteAll();
        R.Key1 := 1;
        R.Insert();
        Clear(R.Data);
        Lib.WriteTT(R, 'X');
        Observer.Observe('get 1', Lib.ReadGetTT(R, 1));
        Observer.Finish();
    end;
}

// Cell 10: the Excel Buffer read flow.
codeunit 75238 "LT TBS Excel Read"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure ReadSheet_LongCellAfterShortCells_EachCellKeepsItsText()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        Blob: Codeunit "Temp Blob";
        Input: InStream;
    begin
        TempExcelBuffer.DeleteAll();
        BuildBook(Blob);
        Blob.CreateInStream(Input);
        TempExcelBuffer.OpenBookStream(Input, 'Sheet1');
        TempExcelBuffer.ReadSheet();
        Observer.Observe('count', Format(TempExcelBuffer.Count()));
        ObserveCell(TempExcelBuffer, 'D', 1);
        ObserveCell(TempExcelBuffer, 'C', 2);
        ObserveCell(TempExcelBuffer, 'D', 2);
        TempExcelBuffer.CloseBook();
        Observer.Finish();
    end;

    local procedure ObserveCell(var TempExcelBuffer: Record "Excel Buffer" temporary; Column: Text; Row: Integer)
    var
        InStrm: InStream;
        Got: Text;
        Name: Text;
    begin
        Name := Column + Format(Row);
        TempExcelBuffer.Reset();
        TempExcelBuffer.SetRange("Row No.", Row);
        TempExcelBuffer.SetRange(xlColID, Column);
        if not TempExcelBuffer.FindFirst() then begin
            Observer.Observe(Name, 'none');
            exit;
        end;
        Observer.Observe(Name + ' text len', Format(StrLen(TempExcelBuffer."Cell Value as Text")));
        Observer.Observe(Name + ' text head', CopyStr(TempExcelBuffer."Cell Value as Text", 1, 20));
        TempExcelBuffer.CalcFields("Cell Value as Blob");
        if not TempExcelBuffer."Cell Value as Blob".HasValue() then begin
            Observer.Observe(Name + ' blob', 'nohv');
            exit;
        end;
        TempExcelBuffer."Cell Value as Blob".CreateInStream(InStrm, TextEncoding::Windows);
        InStrm.Read(Got);
        Observer.Observe(Name + ' blob len', Format(StrLen(Got)));
        Observer.Observe(Name + ' blob head', CopyStr(Got, 1, 20));
        Observer.Observe(Name + ' blob is long text', Format(Got = LongText()));
    end;

    local procedure LongText(): Text
    var
        T: Text;
        i: Integer;
    begin
        for i := 1 to 51 do
            T += 'abcdefghi ';
        exit(T);
    end;

    // A minimal workbook, written by hand: sheet Sheet1, shared strings, D1 = a 55-character text,
    // C2 = 'C2VALUE', D2 = LongText() (510 characters).
    local procedure BuildBook(var Blob: Codeunit "Temp Blob")
    var
        B64: Codeunit "Base64 Convert";
        Output: OutStream;
    begin
        Blob.CreateOutStream(Output);
        B64.FromBase64('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', Output);
    end;
}
