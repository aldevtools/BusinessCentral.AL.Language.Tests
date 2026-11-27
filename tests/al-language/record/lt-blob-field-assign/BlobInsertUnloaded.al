// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-calcfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 73780, table extension 73780, helper codeunit 73780, test codeunit 73781
// Probe (AL Runner issue 9286): what Insert and Modify store from a record whose Blob fields were never loaded (read with Get,
//   FindFirst or FindSet, no CalcFields). The table has three Blob fields: Body (Compressed, the default), Raw (Compressed = false)
//   and, from a table extension, Ext. The seed row SRC holds 'hello' in Body, 'hello-raw' in Raw and 'hello-ext' in Ext; the row
//   OTHER holds 'other', 'other-raw' and 'other-ext'.
//   Cells (stored table): C01 C := Src, new key, Insert (the issue's shape); C02 the same variable under a new key; C03 Delete, then
//   Insert of the same variable and key; C04 C.Copy(Src); C05 a by-value parameter inserted under a new key in the callee; C06 a
//   Variant (V := Src; C := V); C07 RecordRef.GetTable(Src), field 1 set, RecordRef.Insert; C08 the source read with FindFirst
//   (C := and the same variable) and with FindSet; C09 C := Src and Insert(true), the table's OnInsert writes what it sees of Body
//   (HasValue, then CalcFields and HasValue) into the row's Note field; C10 the source read after SetLoadFields that names Body,
//   and that names only Note; C11 C := Src under the key OTHER, then Modify (what OTHER stores afterwards).
//   Temporary table (rows inserted with the seed values): T12 the same variable under a new key, Insert; T13 T2.Copy(T, true) (the
//   same temporary table), new key, Insert.
//   Controls: K1 CalcFields on the source before C := Src; K2 CalcFields on the copy before the key changes; K3 a source with
//   empty Blobs; K4 TransferFields from the source.
//   Readings per cell: own = the inserting record's own Blobs right after the Insert or Modify, without CalcFields
//   ('hasValue=<Yes|No> text=[<text>]'); before = a fresh record's Get of the stored row, HasValue before CalcFields; stored = the
//   same record after CalcFields (hasValue and text). Each Blob gets its own reading: body, raw, ext.
//   Measured on BC 29.0 (Linux, W1, en-US session) with an invented app holding these objects, through the dev endpoint's
//   TestRunnerHub; the values are that run's readings, turned into Expect and Verify by convert.py verbatim. This pull request's CI
//   checks them on 27.5, 28.5 and 29.0; a version difference gets a version guard.
//   Facts (BC 29.0), the same for the three Blob fields:
//   - A Blob that was never loaded is not stored by Insert: every C cell (:=, the same variable, Copy, a by-value parameter, a
//     Variant, a RecordRef, FindFirst, FindSet, SetLoadFields with or without the Blob) stores a row without Blob content. Right
//     after the Insert the inserting record's own Blob answers HasValue Yes and reads empty. Delete and Insert of the same key
//     (C03) leaves the row without its Blob.
//   - Modify onto another stored row (C11) leaves that row's Blobs as they were ('other', 'other-raw', 'other-ext').
//   - Insert(true) (C09): in OnInsert Body.HasValue is Yes before CalcFields and No after it; the inserted row has no Blob.
//   - Temporary table (T12, T13): the new row answers HasValue Yes before CalcFields and No with an empty text after it; the
//     inserting record reads empty.
//   - Controls: CalcFields on the source before := (K1) or on the copy before the new key (K2) stores the content; an empty
//     source (K3) and TransferFields (K4) store no Blob.
// BC versions: 27, 28, 29 by CI
table 73780 "LT BIU Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Body; Blob) { }
        field(3; Raw; Blob) { Compressed = false; }
        field(4; Note; Text[100]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }

    trigger OnInsert()
    var
        Before: Boolean;
    begin
        Before := Body.HasValue();
        CalcFields(Body);
        Note := StrSubstNo('trigger before=%1 after=%2', Before, Body.HasValue());
    end;
}

tableextension 73780 "LT BIU Row Ext" extends "LT BIU Row"
{
    fields
    {
        field(73780; Ext; Blob) { }
    }
}

codeunit 73780 "LT BIU Probe"
{
    procedure Write(var R: Record "LT BIU Row"; B: Text; Rw: Text; E: Text)
    var
        OutS: OutStream;
    begin
        if B <> '' then begin
            R.Body.CreateOutStream(OutS);
            OutS.WriteText(B);
        end;
        if Rw <> '' then begin
            R.Raw.CreateOutStream(OutS);
            OutS.WriteText(Rw);
        end;
        if E <> '' then begin
            R.Ext.CreateOutStream(OutS);
            OutS.WriteText(E);
        end;
    end;

    // The stored rows SRC (hello, hello-raw, hello-ext) and OTHER (other, other-raw, other-ext); EMPTY with no Blob content.
    procedure Seed()
    var
        R: Record "LT BIU Row";
    begin
        R.DeleteAll();
        R.Init();
        R."No." := 'SRC';
        Write(R, 'hello', 'hello-raw', 'hello-ext');
        R.Insert();
        R.Init();
        R."No." := 'OTHER';
        Write(R, 'other', 'other-raw', 'other-ext');
        R.Insert();
        R.Init();
        R."No." := 'EMPTY';
        R.Insert();
    end;

    procedure SeedTemp(var T: Record "LT BIU Row" temporary)
    begin
        T.Reset();
        T.DeleteAll();
        T.Init();
        T."No." := 'SRC';
        Write(T, 'hello', 'hello-raw', 'hello-ext');
        T.Insert();
    end;

    local procedure Show(HasValue: Boolean; InS: InStream): Text
    var
        Txt: Text;
    begin
        if HasValue then
            InS.ReadText(Txt);
        exit(StrSubstNo('hasValue=%1 text=[%2]', HasValue, Txt));
    end;

    procedure ShowBody(var R: Record "LT BIU Row"): Text
    var
        InS: InStream;
    begin
        R.Body.CreateInStream(InS);
        exit(Show(R.Body.HasValue(), InS));
    end;

    procedure ShowRaw(var R: Record "LT BIU Row"): Text
    var
        InS: InStream;
    begin
        R.Raw.CreateInStream(InS);
        exit(Show(R.Raw.HasValue(), InS));
    end;

    procedure ShowExt(var R: Record "LT BIU Row"): Text
    var
        InS: InStream;
    begin
        R.Ext.CreateInStream(InS);
        exit(Show(R.Ext.HasValue(), InS));
    end;

    // own_*: the record's Blobs as they are, without CalcFields.
    procedure Own(var Observer: Codeunit "Probe Observer"; var R: Record "LT BIU Row")
    begin
        Observer.Observe('own_body', ShowBody(R));
        Observer.Observe('own_raw', ShowRaw(R));
        Observer.Observe('own_ext', ShowExt(R));
    end;

    // before_* and stored_*: the stored row No through a fresh record, before and after CalcFields.
    procedure Stored(var Observer: Codeunit "Probe Observer"; No: Code[20])
    var
        R: Record "LT BIU Row";
    begin
        if not R.Get(No) then begin
            Observer.Observe('stored', 'row missing');
            exit;
        end;
        Observer.Observe('before', StrSubstNo('body=%1 raw=%2 ext=%3', R.Body.HasValue(), R.Raw.HasValue(), R.Ext.HasValue()));
        R.CalcFields(Body, Raw, Ext);
        Observer.Observe('stored_body', ShowBody(R));
        Observer.Observe('stored_raw', ShowRaw(R));
        Observer.Observe('stored_ext', ShowExt(R));
    end;

    procedure StoredTemp(var Observer: Codeunit "Probe Observer"; var T: Record "LT BIU Row" temporary; No: Code[20])
    begin
        if not T.Get(No) then begin
            Observer.Observe('stored', 'row missing');
            exit;
        end;
        Observer.Observe('before', StrSubstNo('body=%1 raw=%2 ext=%3', T.Body.HasValue(), T.Raw.HasValue(), T.Ext.HasValue()));
        T.CalcFields(Body, Raw, Ext);
        Observer.Observe('stored_body', ShowBody(T));
        Observer.Observe('stored_raw', ShowRaw(T));
        Observer.Observe('stored_ext', ShowExt(T));
    end;

    // C05: the callee changes the key of its by-value copy and inserts it.
    procedure InsertByValue(R: Record "LT BIU Row"; No: Code[20]; var Observer: Codeunit "Probe Observer")
    begin
        R."No." := No;
        R.Insert();
        Own(Observer, R);
    end;
}

codeunit 73781 "LT BIU Insert Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // C01: C := Src (read with Get, no CalcFields), new key, Insert.
    [Test]
    procedure C01_AssignInsert()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
        C: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.Get('SRC');
        C := Src;
        C."No." := 'NEW';
        C.Insert();
        Probe.Own(Observer, C);
        Probe.Stored(Observer, 'NEW');
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=No raw=No ext=No');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
    end;

    // C02: the same variable under a new key.
    [Test]
    procedure C02_SameVariableNewKey()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.Get('SRC');
        Src."No." := 'NEW';
        Src.Insert();
        Probe.Own(Observer, Src);
        Probe.Stored(Observer, 'NEW');
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=No raw=No ext=No');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
    end;

    // C03: Delete, then Insert of the same variable and key.
    [Test]
    procedure C03_DeleteInsertSameKey()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.Get('SRC');
        Src.Delete();
        Src.Insert();
        Probe.Own(Observer, Src);
        Probe.Stored(Observer, 'SRC');
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=No raw=No ext=No');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
    end;

    // C04: C.Copy(Src), new key, Insert.
    [Test]
    procedure C04_CopyInsert()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
        C: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.Get('SRC');
        C.Copy(Src);
        C."No." := 'NEW';
        C.Insert();
        Probe.Own(Observer, C);
        Probe.Stored(Observer, 'NEW');
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=No raw=No ext=No');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
    end;

    // C05: a by-value parameter, new key and Insert in the callee.
    [Test]
    procedure C05_ByValueParameterInsert()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.Get('SRC');
        Probe.InsertByValue(Src, 'NEW', Observer);
        Probe.Stored(Observer, 'NEW');
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=No raw=No ext=No');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
    end;

    // C06: through a Variant (V := Src; C := V), new key, Insert.
    [Test]
    procedure C06_VariantInsert()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
        C: Record "LT BIU Row";
        V: Variant;
    begin
        Probe.Seed();
        Src.Get('SRC');
        V := Src;
        C := V;
        C."No." := 'NEW';
        C.Insert();
        Probe.Own(Observer, C);
        Probe.Stored(Observer, 'NEW');
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=No raw=No ext=No');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
    end;

    // C07: RecordRef.GetTable(Src), field 1 set to the new key, RecordRef.Insert.
    [Test]
    procedure C07_RecordRefInsert()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Probe.Seed();
        Src.Get('SRC');
        RR.GetTable(Src);
        FR := RR.Field(1);
        FR.Value := 'NEW';
        RR.Insert();
        Probe.Stored(Observer, 'NEW');
        Observer.Expect('before', 'body=No raw=No ext=No');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
    end;

    // C08a: the source read with FindFirst, C := Src, new key, Insert.
    [Test]
    procedure C08a_FindFirstAssignInsert()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
        C: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.SetRange("No.", 'SRC');
        Src.FindFirst();
        C := Src;
        C."No." := 'NEW';
        C.Insert();
        Probe.Own(Observer, C);
        Probe.Stored(Observer, 'NEW');
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=No raw=No ext=No');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
    end;

    // C08b: the source read with FindFirst, the same variable under a new key.
    [Test]
    procedure C08b_FindFirstSameVariable()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.SetRange("No.", 'SRC');
        Src.FindFirst();
        Src."No." := 'NEW';
        Src.Insert();
        Probe.Own(Observer, Src);
        Probe.Stored(Observer, 'NEW');
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=No raw=No ext=No');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
    end;

    // C08c: the source read with FindSet, C := Src, new key, Insert.
    [Test]
    procedure C08c_FindSetAssignInsert()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
        C: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.SetRange("No.", 'SRC');
        Src.FindSet();
        C := Src;
        C."No." := 'NEW';
        C.Insert();
        Probe.Own(Observer, C);
        Probe.Stored(Observer, 'NEW');
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=No raw=No ext=No');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
    end;

    // C09: C := Src and Insert(true); OnInsert writes what it saw of Body into Note.
    [Test]
    procedure C09_InsertTrueTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
        C: Record "LT BIU Row";
        R: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.Get('SRC');
        C := Src;
        C."No." := 'NEW';
        C.Insert(true);
        R.Get('NEW');
        Observer.Observe('note', R.Note);
        Probe.Own(Observer, C);
        Probe.Stored(Observer, 'NEW');
        Observer.Expect('note', 'trigger before=Yes after=No');
        Observer.Expect('own_body', 'hasValue=No text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=No raw=No ext=No');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
    end;

    // C10a: the source read after SetLoadFields(Body), C := Src, new key, Insert.
    [Test]
    procedure C10a_SetLoadFieldsBody()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
        C: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.SetLoadFields(Body);
        Src.Get('SRC');
        C := Src;
        C."No." := 'NEW';
        C.Insert();
        Probe.Own(Observer, C);
        Probe.Stored(Observer, 'NEW');
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=No raw=No ext=No');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
    end;

    // C10b: the source read after SetLoadFields(Note), which does not name a Blob.
    [Test]
    procedure C10b_SetLoadFieldsNote()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
        C: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.SetLoadFields(Note);
        Src.Get('SRC');
        C := Src;
        C."No." := 'NEW';
        C.Insert();
        Probe.Own(Observer, C);
        Probe.Stored(Observer, 'NEW');
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=No raw=No ext=No');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
    end;

    // C11: C := Src under the key of the stored row OTHER, then Modify; what OTHER stores afterwards.
    [Test]
    procedure C11_ModifyOntoOtherRow()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
        C: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.Get('SRC');
        C := Src;
        C."No." := 'OTHER';
        C.Modify();
        Probe.Own(Observer, C);
        Probe.Stored(Observer, 'OTHER');
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=Yes raw=Yes ext=Yes');
        Observer.Expect('stored_body', 'hasValue=Yes text=[other]');
        Observer.Expect('stored_raw', 'hasValue=Yes text=[other-raw]');
        Observer.Expect('stored_ext', 'hasValue=Yes text=[other-ext]');
        Observer.Verify();
    end;

    // T12: a temporary table, the same variable (read with Get) under a new key, Insert.
    [Test]
    procedure T12_TempSameVariableNewKey()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        T: Record "LT BIU Row" temporary;
    begin
        Probe.SeedTemp(T);
        T.Get('SRC');
        T."No." := 'NEW';
        T.Insert();
        Probe.Own(Observer, T);
        Probe.StoredTemp(Observer, T, 'NEW');
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=Yes raw=Yes ext=Yes');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
    end;

    // T13: T2.Copy(T, true) shares the temporary table; T2 under a new key, Insert.
    [Test]
    procedure T13_TempSharedCopyInsert()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        T: Record "LT BIU Row" temporary;
        T2: Record "LT BIU Row" temporary;
    begin
        Probe.SeedTemp(T);
        T.Get('SRC');
        T2.Copy(T, true);
        T2."No." := 'NEW';
        T2.Insert();
        Probe.Own(Observer, T2);
        Probe.StoredTemp(Observer, T, 'NEW');
        Observer.Expect('own_body', 'hasValue=Yes text=[]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[]');
        Observer.Expect('before', 'body=Yes raw=Yes ext=Yes');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
    end;

    // K1: control, CalcFields on the source before C := Src.
    [Test]
    procedure K1_CalcFieldsSourceThenAssign()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
        C: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.Get('SRC');
        Src.CalcFields(Body, Raw, Ext);
        C := Src;
        C."No." := 'NEW';
        C.Insert();
        Probe.Own(Observer, C);
        Probe.Stored(Observer, 'NEW');
        Observer.Expect('own_body', 'hasValue=Yes text=[hello]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[hello-raw]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[hello-ext]');
        Observer.Expect('before', 'body=Yes raw=Yes ext=Yes');
        Observer.Expect('stored_body', 'hasValue=Yes text=[hello]');
        Observer.Expect('stored_raw', 'hasValue=Yes text=[hello-raw]');
        Observer.Expect('stored_ext', 'hasValue=Yes text=[hello-ext]');
        Observer.Verify();
    end;

    // K2: control, C := Src, CalcFields on the copy while it still has the key SRC, then the new key and Insert.
    [Test]
    procedure K2_CalcFieldsCopyThenInsert()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
        C: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.Get('SRC');
        C := Src;
        C.CalcFields(Body, Raw, Ext);
        C."No." := 'NEW';
        C.Insert();
        Probe.Own(Observer, C);
        Probe.Stored(Observer, 'NEW');
        Observer.Expect('own_body', 'hasValue=Yes text=[hello]');
        Observer.Expect('own_raw', 'hasValue=Yes text=[hello-raw]');
        Observer.Expect('own_ext', 'hasValue=Yes text=[hello-ext]');
        Observer.Expect('before', 'body=Yes raw=Yes ext=Yes');
        Observer.Expect('stored_body', 'hasValue=Yes text=[hello]');
        Observer.Expect('stored_raw', 'hasValue=Yes text=[hello-raw]');
        Observer.Expect('stored_ext', 'hasValue=Yes text=[hello-ext]');
        Observer.Verify();
    end;

    // K3: control, a source with empty Blobs (EMPTY), C := Src, new key, Insert.
    [Test]
    procedure K3_EmptySourceAssignInsert()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
        C: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.Get('EMPTY');
        C := Src;
        C."No." := 'NEW';
        C.Insert();
        Probe.Own(Observer, C);
        Probe.Stored(Observer, 'NEW');
        Observer.Expect('own_body', 'hasValue=No text=[]');
        Observer.Expect('own_raw', 'hasValue=No text=[]');
        Observer.Expect('own_ext', 'hasValue=No text=[]');
        Observer.Expect('before', 'body=No raw=No ext=No');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
    end;

    // K4: control, C.TransferFields(Src) from a source read with Get, new key, Insert.
    [Test]
    procedure K4_TransferFieldsInsert()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
        C: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.Get('SRC');
        C.Init();
        C.TransferFields(Src);
        C."No." := 'NEW';
        C.Insert();
        Probe.Own(Observer, C);
        Probe.Stored(Observer, 'NEW');
        Observer.Expect('own_body', 'hasValue=No text=[]');
        Observer.Expect('own_raw', 'hasValue=No text=[]');
        Observer.Expect('own_ext', 'hasValue=No text=[]');
        Observer.Expect('before', 'body=No raw=No ext=No');
        Observer.Expect('stored_body', 'hasValue=No text=[]');
        Observer.Expect('stored_raw', 'hasValue=No text=[]');
        Observer.Expect('stored_ext', 'hasValue=No text=[]');
        Observer.Verify();
    end;
}

// The shapes named in the review of AL Runner pull request 9301 (Modify of the same key, temporary <-> database copies, a field
// assignment of an unloaded Blob, CalcFields after the Insert, a source read in another company).
codeunit 73782 "LT BIU More Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // M1: the source read with Get (Blobs not loaded), Note changed, Modify of the same key: what the row stores.
    [Test]
    procedure M1_ModifySameKey()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.Get('SRC');
        Src.Note := 'modified';
        Src.Modify();
        Probe.Own(Observer, Src);
        Probe.Stored(Observer, 'SRC');
        Observer.Finish();
    end;

    // M2: a stale buffer: the source is read with Get, a second variable then writes 'changed' into the row's Body and modifies
    // it, then the first variable (Blobs not loaded) changes Note and modifies the same key.
    [Test]
    procedure M2_ModifySameKeyStaleBuffer()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
        Second: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.Get('SRC');
        Second.Get('SRC');
        Probe.Write(Second, 'changed', '', '');
        Second.Modify();
        Src.Note := 'modified';
        Src.Modify();
        Probe.Stored(Observer, 'SRC');
        Observer.Finish();
    end;

    // M3: the source read with Get, new key, Insert, then Note changed and Modify of the same variable.
    [Test]
    procedure M3_InsertThenModify()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.Get('SRC');
        Src."No." := 'NEW';
        Src.Insert();
        Src.Note := 'modified';
        Src.Modify();
        Probe.Own(Observer, Src);
        Probe.Stored(Observer, 'NEW');
        Observer.Finish();
    end;

    // I1: database to temporary: T := Src (read with Get, Blobs not loaded), Insert into a temporary table of the same table.
    [Test]
    procedure I1_DatabaseToTemporary()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
        T: Record "LT BIU Row" temporary;
    begin
        Probe.Seed();
        Src.Get('SRC');
        T := Src;
        T.Insert();
        Probe.Own(Observer, T);
        Probe.StoredTemp(Observer, T, 'SRC');
        Observer.Finish();
    end;

    // I2: temporary to database: C := T (a temporary row with the seed Blobs, read with Get), new key, Insert into the table.
    [Test]
    procedure I2_TemporaryToDatabase()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        T: Record "LT BIU Row" temporary;
        C: Record "LT BIU Row";
    begin
        Probe.Seed();
        Probe.SeedTemp(T);
        T.Get('SRC');
        C := T;
        C."No." := 'NEW';
        C.Insert();
        Probe.Own(Observer, C);
        Probe.Stored(Observer, 'NEW');
        Observer.Finish();
    end;

    // I3: field assignment C.Body := Src.Body (and Raw, Ext) from a source read with Get, then C.Insert under a new key.
    [Test]
    procedure I3_FieldAssignInsert()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
        C: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.Get('SRC');
        C.Init();
        C."No." := 'NEW';
        C.Body := Src.Body;
        C.Raw := Src.Raw;
        C.Ext := Src.Ext;
        C.Insert();
        Probe.Own(Observer, C);
        Probe.Stored(Observer, 'NEW');
        Observer.Finish();
    end;

    // I4: C := Src (read with Get), new key, Insert, then CalcFields on C itself: what C reads.
    [Test]
    procedure I4_CalcFieldsAfterInsert()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Src: Record "LT BIU Row";
        C: Record "LT BIU Row";
    begin
        Probe.Seed();
        Src.Get('SRC');
        C := Src;
        C."No." := 'NEW';
        C.Insert();
        C.CalcFields(Body, Raw, Ext);
        Probe.Own(Observer, C);
        Observer.Finish();
    end;

    // G1: a source read in another company (ChangeCompany, Get, no CalcFields), C := Other, new key, Insert in this company; and
    // the reverse: a source read in this company, inserted into the other company.
    [Test]
    procedure G1_OtherCompanySource()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BIU Probe";
        Company: Record Company;
        Other: Record "LT BIU Row";
        OtherNew: Record "LT BIU Row";
        Src: Record "LT BIU Row";
        C: Record "LT BIU Row";
        OtherName: Text;
    begin
        Probe.Seed();
        Company.SetFilter(Name, '<>%1', CompanyName());
        if Company.FindFirst() then
            OtherName := Company.Name;
        Observer.Observe('other_company_found', Format(OtherName <> ''));
        if OtherName <> '' then begin
            Other.ChangeCompany(OtherName);
            Other.DeleteAll();
            Other.Init();
            Other."No." := 'SRC';
            Probe.Write(Other, 'there', 'there-raw', 'there-ext');
            Other.Insert();
            Clear(Other);
            Other.ChangeCompany(OtherName);
            Other.Get('SRC');
            C := Other;
            C.ChangeCompany(CompanyName());
            C."No." := 'NEW';
            C.Insert();
            Probe.Stored(Observer, 'NEW');
            Src.Get('SRC');
            OtherNew := Src;
            OtherNew.ChangeCompany(OtherName);
            OtherNew."No." := 'BACK';
            OtherNew.Insert();
            Clear(Other);
            Other.ChangeCompany(OtherName);
            Other.Get('BACK');
            Other.CalcFields(Body, Raw, Ext);
            Observer.Observe('other_company_body', Probe.ShowBody(Other));
            Observer.Observe('other_company_raw', Probe.ShowRaw(Other));
            Observer.Observe('other_company_ext', Probe.ShowExt(Other));
            Other.DeleteAll();
        end;
        Observer.Finish();
    end;
}
