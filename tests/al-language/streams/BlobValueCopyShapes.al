// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-gettable-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 97750, 97752, table extension 97751, helper codeunit 97757; test codeunits 97753, 97754, 97755
// Probe: written against real BC (al-runner issue 7935, second probe; the first is recordref-fieldref/fieldref/FieldRefValueBlobCopy.al).
// Facts: whether a Blob value is copied or shared when it moves through RecordRef.GetTable / SetTable, TransferFields, FieldRef.Value
//   and FieldRef.Validate, a Variant (local, global, array element, by-value and var parameter, Variant := Variant, a record held in a
//   Variant), Record.Copy, a record passed by value, and record assignment; for an empty Blob, a Blob cleared with Clear, a stored row
//   read with Get and no CalcFields, and a Blob that holds a value. After each step the probe reads every record, RecordRef and
//   variable involved, and after Insert or Modify the stored row.
//   Value format: hv: or nohv: (HasValue of the Blob in hand, no CalcFields) followed by the text read from the Blob in hand;
//   row = the stored row read through a fresh record (Get, HasValue, CalcFields, text), <no row> when Get fails;
//   rr = the RecordRef read through SetTable into a fresh temporary record.
// What BC did: see the Expect lines of each test.
// BC versions: 27.5+

table 97750 "LT BCP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Key1; Integer) { DataClassification = SystemMetadata; }
        field(2; Data; Blob) { DataClassification = SystemMetadata; }
        field(3; Other; Blob) { DataClassification = SystemMetadata; }
        field(4; Plain; Blob) { DataClassification = SystemMetadata; Compressed = false; }
        field(5; Memo; Blob) { DataClassification = SystemMetadata; SubType = Memo; }
    }

    keys
    {
        key(PK; Key1) { Clustered = true; }
    }
}

tableextension 97751 "LT BCP Row Ext" extends "LT BCP Row"
{
    fields
    {
        field(97751; Added; Blob) { DataClassification = SystemMetadata; }
    }
}

// A second table with the same field numbers (TransferFields between two tables).
table 97752 "LT BCP Other"
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

// Shared read and write helpers (no state).
codeunit 97757 "LT BCP Lib"
{
    procedure W(var R: Record "LT BCP Row"; T: Text)
    var
        OS: OutStream;
    begin
        R.Data.CreateOutStream(OS);
        OS.WriteText(T);
    end;

    procedure HasValueText(HV: Boolean): Text
    begin
        if HV then
            exit('hv:');
        exit('nohv:');
    end;

    procedure Rd(var R: Record "LT BCP Row"): Text
    var
        IS: InStream;
        T: Text;
    begin
        R.Data.CreateInStream(IS);
        IS.ReadText(T);
        exit(HasValueText(R.Data.HasValue()) + T);
    end;

    procedure RdOther(var R: Record "LT BCP Row"): Text
    var
        IS: InStream;
        T: Text;
    begin
        R.Other.CreateInStream(IS);
        IS.ReadText(T);
        exit(HasValueText(R.Other.HasValue()) + T);
    end;

    procedure RdRR(var RR: RecordRef): Text
    var
        R: Record "LT BCP Row" temporary;
    begin
        RR.SetTable(R);
        exit(Rd(R));
    end;

    procedure Stored(K: Integer): Text
    var
        R: Record "LT BCP Row";
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

    // Inserts row K with 'alpha' and leaves Src read with Get and no CalcFields (the Blob not loaded).
    procedure StoreUnloaded(var Src: Record "LT BCP Row"; K: Integer)
    begin
        Src.Init();
        Src.Key1 := K;
        W(Src, 'alpha');
        Src.Insert();
        Clear(Src);
        Src.Get(K);
    end;

    procedure Reset()
    var
        R: Record "LT BCP Row";
        O: Record "LT BCP Other";
    begin
        R.DeleteAll();
        O.DeleteAll();
    end;
}

// ---- Empty and not-loaded sources ----
codeunit 97753 "LT BCP Empty Source"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT BCP Lib";

    [Test]
    procedure GetTable_EmptyBlob_WriteSource()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row" temporary;
        RR: RecordRef;
    begin
        // E1
        RR.GetTable(Src);
        Observer.Observe('E1 after GetTable rr', L.RdRR(RR));
        L.W(Src, 'x');
        Observer.Observe('E1 after write src', L.Rd(Src));
        Observer.Observe('E1 after write rr', L.RdRR(RR));
        Observer.Finish();
    end;

    [Test]
    procedure GetTable_EmptyBlob_WriteSource_RecordRefInsert()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row";
        RR: RecordRef;
    begin
        // E2
        L.Reset();
        Src.Key1 := 2;
        RR.GetTable(Src);
        L.W(Src, 'x');
        Observer.Observe('E2 after write src', L.Rd(Src));
        Observer.Observe('E2 after write rr', L.RdRR(RR));
        RR.Insert();
        Observer.Observe('E2 after RR.Insert row', L.Stored(2));
        Observer.Observe('E2 after RR.Insert src', L.Rd(Src));
        Observer.Observe('E2 after RR.Insert rr', L.RdRR(RR));
        Observer.Finish();
    end;

    [Test]
    procedure SetTable_EmptyBlob_WriteTarget()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row" temporary;
        Dst: Record "LT BCP Row" temporary;
        RR: RecordRef;
    begin
        // E3
        RR.GetTable(Src);
        RR.SetTable(Dst);
        L.W(Dst, 'x');
        Observer.Observe('E3 after write dst', L.Rd(Dst));
        Observer.Observe('E3 after write src', L.Rd(Src));
        Observer.Observe('E3 after write rr', L.RdRR(RR));
        Observer.Finish();
    end;

    [Test]
    procedure TransferFields_EmptyBlob_WriteSource()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row" temporary;
        Dst: Record "LT BCP Row" temporary;
    begin
        // E4
        Dst.TransferFields(Src);
        L.W(Src, 'x');
        Observer.Observe('E4 after write src', L.Rd(Src));
        Observer.Observe('E4 after write dst', L.Rd(Dst));
        Observer.Finish();
    end;

    [Test]
    procedure TransferFields_EmptyBlob_WriteTarget_SourceInsert()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row";
        Dst: Record "LT BCP Row";
    begin
        // E4b
        L.Reset();
        Src.Key1 := 41;
        Dst.TransferFields(Src);
        L.W(Dst, 'y');
        Observer.Observe('E4b after write dst', L.Rd(Dst));
        Observer.Observe('E4b after write src', L.Rd(Src));
        Src.Insert();
        Observer.Observe('E4b after Src.Insert row', L.Stored(41));
        Observer.Observe('E4b after Src.Insert src', L.Rd(Src));
        Observer.Observe('E4b after Src.Insert dst', L.Rd(Dst));
        Observer.Finish();
    end;

    [Test]
    procedure FieldRefValidate_EmptyBlob_WriteSource()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row" temporary;
        Dst: Record "LT BCP Row" temporary;
        RR: RecordRef;
    begin
        // E5
        RR.GetTable(Dst);
        RR.Field(2).Validate(Src.Data);
        L.W(Src, 'x');
        Observer.Observe('E5 after write src', L.Rd(Src));
        Observer.Observe('E5 after write rr', L.RdRR(RR));
        Observer.Finish();
    end;

    [Test]
    procedure Variant_EmptyBlob_WriteSource()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row" temporary;
        Dst: Record "LT BCP Row" temporary;
        V: Variant;
        RR: RecordRef;
    begin
        // E6
        V := Src.Data;
        L.W(Src, 'x');
        RR.GetTable(Dst);
        RR.Field(2).Value := V;
        Observer.Observe('E6 after FieldRef.Value src', L.Rd(Src));
        Observer.Observe('E6 after FieldRef.Value rr', L.RdRR(RR));
        Dst.Data := V;
        Observer.Observe('E6 after Dst.Data := V dst', L.Rd(Dst));
        Observer.Finish();
    end;

    [Test]
    procedure GetTable_ClearedBlob_WriteSource()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row" temporary;
        RR: RecordRef;
    begin
        // E7
        L.W(Src, 'alpha');
        Clear(Src.Data);
        Observer.Observe('E7 after Clear src', L.Rd(Src));
        RR.GetTable(Src);
        L.W(Src, 'x');
        Observer.Observe('E7 after write src', L.Rd(Src));
        Observer.Observe('E7 after write rr', L.RdRR(RR));
        Observer.Finish();
    end;

    [Test]
    procedure GetTable_EmptyBlob_OtherBlobFilled_WriteSource()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row" temporary;
        R: Record "LT BCP Row" temporary;
        RR: RecordRef;
        OS: OutStream;
    begin
        // E8
        Src.Other.CreateOutStream(OS);
        OS.WriteText('o');
        RR.GetTable(Src);
        L.W(Src, 'x');
        Observer.Observe('E8 after write src data', L.Rd(Src));
        Observer.Observe('E8 after write src other', L.RdOther(Src));
        RR.SetTable(R);
        Observer.Observe('E8 after write rr data', L.Rd(R));
        Observer.Observe('E8 after write rr other', L.RdOther(R));
        Observer.Finish();
    end;

    [Test]
    procedure GetTable_Unloaded_CalcFieldsSource_SetTable()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row";
        Dst: Record "LT BCP Row";
        RR: RecordRef;
    begin
        // N1
        L.Reset();
        L.StoreUnloaded(Src, 11);
        RR.GetTable(Src);
        Src.CalcFields(Data);
        Observer.Observe('N1 after CalcFields src', L.Rd(Src));
        Observer.Observe('N1 after CalcFields rr', L.RdRR(RR));
        RR.SetTable(Dst);
        Observer.Observe('N1 after SetTable dst', L.Rd(Dst));
        Observer.Observe('N1 row', L.Stored(11));
        Observer.Finish();
    end;

    [Test]
    procedure GetTable_Unloaded_WriteSource_RecordRefModify()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row";
        RR: RecordRef;
    begin
        // N2
        L.Reset();
        L.StoreUnloaded(Src, 12);
        RR.GetTable(Src);
        L.W(Src, 'new');
        Observer.Observe('N2 after write src', L.Rd(Src));
        Observer.Observe('N2 after write rr', L.RdRR(RR));
        RR.Modify();
        Observer.Observe('N2 after RR.Modify row', L.Stored(12));
        Observer.Observe('N2 after RR.Modify src', L.Rd(Src));
        Observer.Finish();
    end;

    [Test]
    procedure SetTable_UnloadedFindFirst_CalcFieldsTarget()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row";
        Dst: Record "LT BCP Row";
        RR: RecordRef;
    begin
        // N3
        L.Reset();
        L.StoreUnloaded(Src, 13);
        RR.Open(Database::"LT BCP Row");
        RR.FindFirst();
        RR.SetTable(Dst);
        Observer.Observe('N3 after SetTable dst', L.Rd(Dst));
        Dst.CalcFields(Data);
        Observer.Observe('N3 after CalcFields dst', L.Rd(Dst));
        Observer.Observe('N3 after CalcFields rr', L.RdRR(RR));
        Observer.Finish();
    end;

    [Test]
    procedure SetTable_UnloadedFindFirst_WriteTarget_RecordRefModify()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row";
        Dst: Record "LT BCP Row";
        RR: RecordRef;
    begin
        // N4
        L.Reset();
        L.StoreUnloaded(Src, 14);
        RR.Open(Database::"LT BCP Row");
        RR.FindFirst();
        RR.SetTable(Dst);
        L.W(Dst, 'new');
        Observer.Observe('N4 after write dst', L.Rd(Dst));
        Observer.Observe('N4 after write rr', L.RdRR(RR));
        RR.Modify();
        Observer.Observe('N4 after RR.Modify row', L.Stored(14));
        Observer.Observe('N4 after RR.Modify dst', L.Rd(Dst));
        Observer.Finish();
    end;

    [Test]
    procedure FieldRefValidate_Unloaded_CalcFieldsSource()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row";
        Dst: Record "LT BCP Row" temporary;
        RR: RecordRef;
    begin
        // N5
        L.Reset();
        L.StoreUnloaded(Src, 15);
        RR.GetTable(Dst);
        RR.Field(2).Validate(Src.Data);
        Observer.Observe('N5 after Validate rr', L.RdRR(RR));
        Src.CalcFields(Data);
        Observer.Observe('N5 after CalcFields src', L.Rd(Src));
        Observer.Observe('N5 after CalcFields rr', L.RdRR(RR));
        Observer.Finish();
    end;

    [Test]
    procedure Variant_Unloaded_CalcFieldsSource()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row";
        Dst: Record "LT BCP Row" temporary;
        V: Variant;
        RR: RecordRef;
    begin
        // N6
        L.Reset();
        L.StoreUnloaded(Src, 16);
        V := Src.Data;
        Src.CalcFields(Data);
        Observer.Observe('N6 after CalcFields src', L.Rd(Src));
        RR.GetTable(Dst);
        RR.Field(2).Value := V;
        Observer.Observe('N6 after FieldRef.Value rr', L.RdRR(RR));
        Dst.Data := V;
        Observer.Observe('N6 after Dst.Data := V dst', L.Rd(Dst));
        Observer.Finish();
    end;

    [Test]
    procedure GetTable_Unloaded_FieldRefCalcField()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row";
        Dst: Record "LT BCP Row";
        RR: RecordRef;
    begin
        // N7
        L.Reset();
        L.StoreUnloaded(Src, 17);
        RR.GetTable(Src);
        RR.Field(2).CalcField();
        Observer.Observe('N7 after CalcField rr', L.RdRR(RR));
        Observer.Observe('N7 after CalcField src', L.Rd(Src));
        RR.SetTable(Dst);
        Observer.Observe('N7 after SetTable dst', L.Rd(Dst));
        Observer.Finish();
    end;
}

// ---- Call forms with content ----
codeunit 97754 "LT BCP Call Forms"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT BCP Lib";
        GRow: Record "LT BCP Row" temporary;
        GVar: Variant;

    local procedure TakeVar(V: Variant; var Src: Record "LT BCP Row"; var Dst: Record "LT BCP Row")
    begin
        L.W(Src, 'beta');
        Dst.Data := V;
    end;

    local procedure SetVar(var V: Variant; var Src: Record "LT BCP Row")
    begin
        V := Src.Data;
    end;

    local procedure FromVariant(RecVar: Variant; var RR: RecordRef)
    begin
        RR.GetTable(RecVar);
        L.W(GRow, 'beta');
    end;

    local procedure ToRecord(var RecVar: Variant; var Src: Record "LT BCP Row")
    var
        RR: RecordRef;
    begin
        RR.GetTable(RecVar);
        RR.Field(2).Value := Src.Data;
        RR.SetTable(RecVar);
    end;

    local procedure ByValueTemp(R: Record "LT BCP Row" temporary): Text
    begin
        L.W(R, 'zz');
        exit(L.Rd(R));
    end;

    local procedure ByValue(R: Record "LT BCP Row"): Text
    begin
        L.W(R, 'zz');
        exit(L.Rd(R));
    end;

    [Test]
    procedure Variant_ByValueParameter()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row" temporary;
        Dst: Record "LT BCP Row" temporary;
    begin
        // V3
        L.W(Src, 'alpha');
        TakeVar(Src.Data, Src, Dst);
        Observer.Observe('V3 dst', L.Rd(Dst));
        Observer.Observe('V3 src', L.Rd(Src));
        Observer.Finish();
    end;

    [Test]
    procedure Variant_VarParameter()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row" temporary;
        Dst: Record "LT BCP Row" temporary;
        V: Variant;
    begin
        // V1
        L.W(Src, 'alpha');
        SetVar(V, Src);
        L.W(Src, 'beta');
        Dst.Data := V;
        Observer.Observe('V1 dst', L.Rd(Dst));
        Observer.Observe('V1 src', L.Rd(Src));
        Observer.Finish();
    end;

    [Test]
    procedure Variant_AssignVariant()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row" temporary;
        Dst: Record "LT BCP Row" temporary;
        V: Variant;
        V2: Variant;
    begin
        // V2
        L.W(Src, 'alpha');
        V := Src.Data;
        V2 := V;
        L.W(Src, 'beta');
        Dst.Data := V2;
        Observer.Observe('V2 dst from V2', L.Rd(Dst));
        Dst.Data := V;
        Observer.Observe('V2 dst from V', L.Rd(Dst));
        Observer.Observe('V2 src', L.Rd(Src));
        Observer.Finish();
    end;

    [Test]
    procedure Variant_ArrayElement()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row" temporary;
        Dst: Record "LT BCP Row" temporary;
        V: array[2] of Variant;
    begin
        // V5
        L.W(Src, 'alpha');
        V[1] := Src.Data;
        L.W(Src, 'beta');
        Dst.Data := V[1];
        Observer.Observe('V5 dst', L.Rd(Dst));
        Observer.Observe('V5 src', L.Rd(Src));
        Observer.Finish();
    end;

    [Test]
    procedure Variant_Global()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row" temporary;
        Dst: Record "LT BCP Row" temporary;
    begin
        // global Variant
        Clear(GVar);
        L.W(Src, 'alpha');
        GVar := Src.Data;
        L.W(Src, 'beta');
        Dst.Data := GVar;
        Observer.Observe('GV dst', L.Rd(Dst));
        Observer.Observe('GV src', L.Rd(Src));
        Observer.Finish();
    end;

    [Test]
    procedure Variant_FromGlobalRecord()
    var
        Observer: Codeunit "Probe Observer";
        Dst: Record "LT BCP Row" temporary;
        V: Variant;
    begin
        // V6
        Clear(GRow);
        L.W(GRow, 'alpha');
        V := GRow.Data;
        L.W(GRow, 'beta');
        Dst.Data := V;
        Observer.Observe('V6 dst', L.Rd(Dst));
        Observer.Observe('V6 grow', L.Rd(GRow));
        Observer.Finish();
    end;

    [Test]
    procedure SetTable_ShareTable()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row" temporary;
        Dst: Record "LT BCP Row" temporary;
        RR: RecordRef;
    begin
        // X6
        L.W(Src, 'alpha');
        RR.GetTable(Src);
        RR.SetTable(Dst, true);
        Observer.Observe('X6 after SetTable dst', L.Rd(Dst));
        L.W(Dst, 'zz');
        Observer.Observe('X6 after write dst dst', L.Rd(Dst));
        Observer.Observe('X6 after write dst rr', L.RdRR(RR));
        Observer.Observe('X6 after write dst src', L.Rd(Src));
        L.W(Src, 'beta');
        Observer.Observe('X6 after write src dst', L.Rd(Dst));
        Observer.Observe('X6 after write src rr', L.RdRR(RR));
        Observer.Finish();
    end;

    [Test]
    procedure TransferFields_TwoArguments()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row" temporary;
        Dst: Record "LT BCP Row" temporary;
    begin
        // TransferFields(Src, true)
        L.W(Src, 'alpha');
        Dst.TransferFields(Src, true);
        L.W(Src, 'beta');
        Observer.Observe('TF2 after write src dst', L.Rd(Dst));
        L.W(Dst, 'zz');
        Observer.Observe('TF2 after write dst src', L.Rd(Src));
        Observer.Observe('TF2 after write dst dst', L.Rd(Dst));
        Observer.Finish();
    end;

    [Test]
    procedure TransferFields_TwoArguments_NoPrimaryKey()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row" temporary;
        Dst: Record "LT BCP Row" temporary;
    begin
        // TransferFields(Src, false)
        L.W(Src, 'alpha');
        Dst.TransferFields(Src, false);
        L.W(Src, 'beta');
        Observer.Observe('TF2f after write src dst', L.Rd(Dst));
        L.W(Dst, 'zz');
        Observer.Observe('TF2f after write dst src', L.Rd(Src));
        Observer.Finish();
    end;

    [Test]
    procedure TransferFields_ThreeArguments()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row" temporary;
        Dst: Record "LT BCP Row" temporary;
    begin
        // TransferFields(Src, true, true)
        L.W(Src, 'alpha');
        Dst.TransferFields(Src, true, true);
        L.W(Src, 'beta');
        Observer.Observe('TF3 after write src dst', L.Rd(Dst));
        L.W(Dst, 'zz');
        Observer.Observe('TF3 after write dst src', L.Rd(Src));
        Observer.Observe('TF3 after write dst dst', L.Rd(Dst));
        Observer.Finish();
    end;

    [Test]
    procedure TransferFields_OtherTable()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row" temporary;
        Dst: Record "LT BCP Other" temporary;
        IS: InStream;
        T: Text;
    begin
        // TransferFields between two tables (R7)
        L.W(Src, 'alpha');
        Dst.TransferFields(Src);
        L.W(Src, 'beta');
        Dst.Data.CreateInStream(IS);
        IS.ReadText(T);
        Observer.Observe('TFO after write src dst', L.HasValueText(Dst.Data.HasValue()) + T);
        Observer.Observe('TFO after write src src', L.Rd(Src));
        Observer.Finish();
    end;

    [Test]
    procedure GetTable_RecordInLocalVariant()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row" temporary;
        V: Variant;
        RR: RecordRef;
    begin
        // P1
        L.W(Src, 'alpha');
        V := Src;
        L.W(Src, 'beta');
        RR.GetTable(V);
        Observer.Observe('P1 after GetTable rr', L.RdRR(RR));
        Observer.Observe('P1 after GetTable src', L.Rd(Src));
        L.W(Src, 'zz');
        Observer.Observe('P1 after second write rr', L.RdRR(RR));
        Observer.Finish();
    end;

    [Test]
    procedure GetTable_RecordAsVariantParameter()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        // P2
        Clear(GRow);
        L.W(GRow, 'alpha');
        FromVariant(GRow, RR);
        Observer.Observe('P2 rr', L.RdRR(RR));
        Observer.Observe('P2 grow', L.Rd(GRow));
        Observer.Finish();
    end;

    [Test]
    procedure ToRecord_VarVariant_WriteSource()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row" temporary;
        Dst: Record "LT BCP Row" temporary;
        V: Variant;
    begin
        // P3
        L.W(Src, 'alpha');
        V := Dst;
        ToRecord(V, Src);
        L.W(Src, 'beta');
        Dst := V;
        Observer.Observe('P3 dst', L.Rd(Dst));
        Observer.Observe('P3 src', L.Rd(Src));
        Observer.Finish();
    end;

    [Test]
    procedure ToRecord_VarVariant_ClearSource()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row" temporary;
        Dst: Record "LT BCP Row" temporary;
        V: Variant;
    begin
        // P4
        L.W(Src, 'alpha');
        V := Dst;
        ToRecord(V, Src);
        Clear(Src.Data);
        Dst := V;
        Observer.Observe('P4 dst', L.Rd(Dst));
        Observer.Observe('P4 src', L.Rd(Src));
        Observer.Finish();
    end;

    [Test]
    procedure RecordCopy()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row" temporary;
        Dst: Record "LT BCP Row" temporary;
    begin
        // X2
        L.W(Src, 'alpha');
        Dst.Copy(Src);
        Observer.Observe('X2 after Copy dst', L.Rd(Dst));
        L.W(Src, 'beta');
        Observer.Observe('X2 after write src dst', L.Rd(Dst));
        L.W(Dst, 'zz');
        Observer.Observe('X2 after write dst src', L.Rd(Src));
        Observer.Observe('X2 after write dst dst', L.Rd(Dst));
        Observer.Finish();
    end;

    [Test]
    procedure RecordCopy_ShareTable()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row" temporary;
        Dst: Record "LT BCP Row" temporary;
    begin
        // X2 with ShareTable
        L.W(Src, 'alpha');
        Dst.Copy(Src, true);
        Observer.Observe('X2s after Copy dst', L.Rd(Dst));
        L.W(Src, 'beta');
        Observer.Observe('X2s after write src dst', L.Rd(Dst));
        L.W(Dst, 'zz');
        Observer.Observe('X2s after write dst src', L.Rd(Src));
        Observer.Observe('X2s after write dst dst', L.Rd(Dst));
        Observer.Finish();
    end;

    [Test]
    procedure RecordCopy_Stored_Insert()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row";
        Dst: Record "LT BCP Row";
    begin
        // X2 stored: Copy, write the target, insert the source
        L.Reset();
        Src.Key1 := 21;
        L.W(Src, 'alpha');
        Dst.Copy(Src);
        L.W(Dst, 'zz');
        Src.Insert();
        Observer.Observe('X2r after Src.Insert row', L.Stored(21));
        Observer.Observe('X2r after Src.Insert src', L.Rd(Src));
        Observer.Observe('X2r after Src.Insert dst', L.Rd(Dst));
        Observer.Finish();
    end;

    [Test]
    procedure RecordByValue_Temporary()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row" temporary;
    begin
        // P5 temporary
        L.W(Src, 'alpha');
        Observer.Observe('P5t inside', ByValueTemp(Src));
        Observer.Observe('P5t caller', L.Rd(Src));
        Observer.Finish();
    end;

    [Test]
    procedure RecordByValue_NotTemporary()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row";
    begin
        // P5 not temporary, never stored
        L.W(Src, 'alpha');
        Observer.Observe('P5 inside', ByValue(Src));
        Observer.Observe('P5 caller', L.Rd(Src));
        Observer.Finish();
    end;

    [Test]
    procedure RecordAssign_Control()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row" temporary;
        Dst: Record "LT BCP Row" temporary;
    begin
        // X1 control
        L.W(Src, 'alpha');
        Dst := Src;
        Observer.Observe('X1 after assign dst', L.Rd(Dst));
        L.W(Src, 'beta');
        Observer.Observe('X1 after write src dst', L.Rd(Dst));
        L.W(Dst, 'zz');
        Observer.Observe('X1 after write dst src', L.Rd(Src));
        Observer.Observe('X1 after write dst dst', L.Rd(Dst));
        Observer.Finish();
    end;

    [Test]
    procedure RecordAssign_Stored_Insert()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row";
        Dst: Record "LT BCP Row";
    begin
        // X1 stored: assign, write the target, insert the source
        L.Reset();
        Src.Key1 := 22;
        L.W(Src, 'alpha');
        Dst := Src;
        L.W(Dst, 'zz');
        Src.Insert();
        Observer.Observe('X1r after Src.Insert row', L.Stored(22));
        Observer.Observe('X1r after Src.Insert dst', L.Rd(Dst));
        Observer.Finish();
    end;
}

// ---- Other field kinds and the open stream ----
codeunit 97755 "LT BCP Field Kinds"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT BCP Lib";

    local procedure WriteField(var R: Record "LT BCP Row"; FieldNo: Integer; T: Text)
    var
        OS: OutStream;
    begin
        case FieldNo of
            4:
                R.Plain.CreateOutStream(OS);
            5:
                R.Memo.CreateOutStream(OS);
            97751:
                R.Added.CreateOutStream(OS);
        end;
        OS.WriteText(T);
    end;

    local procedure ReadField(var R: Record "LT BCP Row"; FieldNo: Integer): Text
    var
        IS: InStream;
        T: Text;
        HV: Boolean;
    begin
        case FieldNo of
            4:
                begin
                    HV := R.Plain.HasValue();
                    R.Plain.CreateInStream(IS);
                end;
            5:
                begin
                    HV := R.Memo.HasValue();
                    R.Memo.CreateInStream(IS);
                end;
            97751:
                begin
                    HV := R.Added.HasValue();
                    R.Added.CreateInStream(IS);
                end;
        end;
        IS.ReadText(T);
        exit(L.HasValueText(HV) + T);
    end;

    local procedure GetSet(var Observer: Codeunit "Probe Observer"; Tag: Text; FieldNo: Integer)
    var
        Src: Record "LT BCP Row" temporary;
        Dst: Record "LT BCP Row" temporary;
        RR: RecordRef;
    begin
        WriteField(Src, FieldNo, 'alpha');
        RR.GetTable(Src);
        WriteField(Src, FieldNo, 'beta');
        RR.SetTable(Dst);
        Observer.Observe(Tag + ' GetTable then write src dst', ReadField(Dst, FieldNo));
        WriteField(Dst, FieldNo, 'zz');
        Observer.Observe(Tag + ' write dst src', ReadField(Src, FieldNo));
    end;

    local procedure TransferF(var Observer: Codeunit "Probe Observer"; Tag: Text; FieldNo: Integer)
    var
        Src: Record "LT BCP Row" temporary;
        Dst: Record "LT BCP Row" temporary;
    begin
        WriteField(Src, FieldNo, 'alpha');
        Dst.TransferFields(Src);
        WriteField(Src, FieldNo, 'beta');
        Observer.Observe(Tag + ' TransferFields then write src dst', ReadField(Dst, FieldNo));
    end;

    local procedure ToData(var Observer: Codeunit "Probe Observer"; Tag: Text; FieldNo: Integer)
    var
        Src: Record "LT BCP Row" temporary;
        Dst: Record "LT BCP Row" temporary;
        RR: RecordRef;
        V: Variant;
    begin
        WriteField(Src, FieldNo, 'alpha');
        RR.GetTable(Dst);
        case FieldNo of
            4:
                RR.Field(2).Value := Src.Plain;
            5:
                RR.Field(2).Value := Src.Memo;
            97751:
                RR.Field(2).Value := Src.Added;
        end;
        case FieldNo of
            4:
                V := Src.Plain;
            5:
                V := Src.Memo;
            97751:
                V := Src.Added;
        end;
        WriteField(Src, FieldNo, 'beta');
        Observer.Observe(Tag + ' FieldRef.Value into Data then write src rr', L.RdRR(RR));
        Dst.Data := V;
        Observer.Observe(Tag + ' Variant into Data then write src dst', L.Rd(Dst));
    end;

    [Test]
    procedure MemoSubtype_Shapes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GetSet(Observer, 'memo', 5);
        TransferF(Observer, 'memo', 5);
        ToData(Observer, 'memo', 5);
        Observer.Finish();
    end;

    [Test]
    procedure CompressedFalse_Shapes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GetSet(Observer, 'plain', 4);
        TransferF(Observer, 'plain', 4);
        ToData(Observer, 'plain', 4);
        Observer.Finish();
    end;

    [Test]
    procedure TableExtensionField_Shapes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GetSet(Observer, 'ext', 97751);
        TransferF(Observer, 'ext', 97751);
        ToData(Observer, 'ext', 97751);
        Observer.Finish();
    end;

    [Test]
    procedure TableExtensionField_Stored_GetTable_Modify()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row";
        R: Record "LT BCP Row";
        RR: RecordRef;
    begin
        L.Reset();
        Src.Key1 := 26;
        WriteField(Src, 97751, 'alpha');
        Src.Insert();
        Src.Get(26);
        Src.CalcFields(Added);
        RR.GetTable(Src);
        WriteField(Src, 97751, 'new');
        RR.Modify();
        R.Get(26);
        Observer.Observe('ext row before CalcFields', L.HasValueText(R.Added.HasValue()));
        R.CalcFields(Added);
        Observer.Observe('ext row', ReadField(R, 97751));
        Observer.Observe('ext src', ReadField(Src, 97751));
        Observer.Finish();
    end;

    [Test]
    procedure OpenOutStream_GetTable_SetTableSameRecord()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row" temporary;
        RR: RecordRef;
        OS: OutStream;
    begin
        // X4
        Src.Data.CreateOutStream(OS);
        OS.WriteText('al');
        RR.GetTable(Src);
        RR.SetTable(Src);
        Observer.Observe('X4 after SetTable src', L.Rd(Src));
        OS.WriteText('pha');
        Observer.Observe('X4 after stream write src', L.Rd(Src));
        Observer.Observe('X4 after stream write rr', L.RdRR(RR));
        Observer.Finish();
    end;

    [Test]
    procedure OpenOutStream_GetTable_WriteStream()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BCP Row" temporary;
        RR: RecordRef;
        OS: OutStream;
    begin
        // X4 without SetTable back
        Src.Data.CreateOutStream(OS);
        OS.WriteText('al');
        RR.GetTable(Src);
        OS.WriteText('pha');
        Observer.Observe('X4g after stream write src', L.Rd(Src));
        Observer.Observe('X4g after stream write rr', L.RdRR(RR));
        Observer.Finish();
    end;
}
