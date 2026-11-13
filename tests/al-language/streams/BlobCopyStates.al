// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-value-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 97760, table extension 97761, helper codeunits 97763, 97769, 97770, 97771;
//   test codeunits 97764, 97765, 97766, 97767
// Probe: written against real BC (al-runner issue 7948, third probe; the earlier ones are recordref-fieldref/fieldref/FieldRefValueBlobCopy.al
//   and streams/BlobValueCopyShapes.al).
// Facts: whether a Blob value is copied or shared, per state of the source Blob, when it moves through FieldRef.Value and FieldRef.Validate
//   into a Compressed = false, a Compressed = true and a table extension Blob field, a record passed by value (also into a [TryFunction],
//   an event publisher and its subscriber, a temporary record into a non-temporary parameter and the reverse), Record.Copy (also between a
//   temporary and a stored record), RecordRef.SetTable(Rec, true), TransferFields with both InitPrimaryKeyFields values, a global Variant,
//   a Variant array element, Codeunit.Run with TableNo, and the table triggers OnInsert, OnModify (Rec and xRec) and OnValidate.
//   Source states: mem (written in memory, not stored), ins (written, then Insert), calc (stored, Get and CalcFields), get (stored, Get only,
//   Blob not loaded), empty (Init only), asg (copied by := from another record that holds 'alpha').
//   Value format: hv: or nohv: (HasValue of the Blob in hand, no CalcFields) followed by the text read from the Blob in hand;
//   row = the stored row read through a fresh record: HasValue before CalcFields, a space, then hv:/nohv: and the text after CalcFields;
//   rr = the RecordRef read through SetTable into a fresh temporary record.
// Observe form: values not yet measured.
// BC versions: 27.5+

table 97760 "LT BC3 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Key1; Integer) { DataClassification = SystemMetadata; }
        field(2; Data; Blob) { DataClassification = SystemMetadata; }
        field(3; Other; Blob) { DataClassification = SystemMetadata; }
        field(4; Plain; Blob) { DataClassification = SystemMetadata; Compressed = false; }
        field(5; Comp; Blob) { DataClassification = SystemMetadata; Compressed = true; }
        field(6; Mode; Integer)
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                L: Codeunit "LT BC3 Lib";
            begin
                if Mode = 4 then
                    L.W(Rec, 'val');
            end;
        }
        field(7; Seen; Text[250]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; Key1) { Clustered = true; }
    }

    trigger OnInsert()
    var
        L: Codeunit "LT BC3 Lib";
    begin
        if Mode = 3 then
            L.W(Rec, 'ins');
    end;

    trigger OnModify()
    var
        L: Codeunit "LT BC3 Lib";
    begin
        case Mode of
            1:
                begin
                    Seen := CopyStr(L.Rd(xRec), 1, 250);
                    L.W(Rec, 'trig');
                end;
            2:
                begin
                    L.W(xRec, 'xx');
                    Seen := CopyStr(L.Rd(Rec), 1, 250);
                end;
        end;
    end;
}

tableextension 97761 "LT BC3 Row Ext" extends "LT BC3 Row"
{
    fields
    {
        field(97761; Added; Blob) { DataClassification = SystemMetadata; }
    }
}

// Shared read and write helpers (no state).
codeunit 97763 "LT BC3 Lib"
{
    procedure HasValueText(HV: Boolean): Text
    begin
        if HV then
            exit('hv:');
        exit('nohv:');
    end;

    procedure WF(var R: Record "LT BC3 Row"; F: Integer; T: Text)
    var
        OS: OutStream;
    begin
        case F of
            2:
                R.Data.CreateOutStream(OS);
            3:
                R.Other.CreateOutStream(OS);
            4:
                R.Plain.CreateOutStream(OS);
            5:
                R.Comp.CreateOutStream(OS);
            97761:
                R.Added.CreateOutStream(OS);
        end;
        OS.WriteText(T);
    end;

    procedure RF(var R: Record "LT BC3 Row"; F: Integer): Text
    var
        IS: InStream;
        T: Text;
        HV: Boolean;
    begin
        case F of
            2:
                begin
                    HV := R.Data.HasValue();
                    R.Data.CreateInStream(IS);
                end;
            3:
                begin
                    HV := R.Other.HasValue();
                    R.Other.CreateInStream(IS);
                end;
            4:
                begin
                    HV := R.Plain.HasValue();
                    R.Plain.CreateInStream(IS);
                end;
            5:
                begin
                    HV := R.Comp.HasValue();
                    R.Comp.CreateInStream(IS);
                end;
            97761:
                begin
                    HV := R.Added.HasValue();
                    R.Added.CreateInStream(IS);
                end;
        end;
        IS.ReadText(T);
        exit(HasValueText(HV) + T);
    end;

    procedure W(var R: Record "LT BC3 Row"; T: Text)
    begin
        WF(R, 2, T);
    end;

    procedure Rd(var R: Record "LT BC3 Row"): Text
    begin
        exit(RF(R, 2));
    end;

    procedure CalcF(var R: Record "LT BC3 Row"; F: Integer)
    begin
        case F of
            2:
                R.CalcFields(Data);
            3:
                R.CalcFields(Other);
            4:
                R.CalcFields(Plain);
            5:
                R.CalcFields(Comp);
            97761:
                R.CalcFields(Added);
        end;
    end;

    // The RecordRef read through SetTable into a fresh temporary record.
    procedure RdRR(var RR: RecordRef; F: Integer): Text
    var
        R: Record "LT BC3 Row" temporary;
    begin
        RR.SetTable(R);
        exit(RF(R, F));
    end;

    // The stored row read through a fresh record: HasValue before CalcFields, then the text after CalcFields.
    procedure StoredF(K: Integer; F: Integer): Text
    var
        R: Record "LT BC3 Row";
        HV: Boolean;
        T: Text;
    begin
        if not R.Get(K) then
            exit('<no row>');
        case F of
            2:
                HV := R.Data.HasValue();
            4:
                HV := R.Plain.HasValue();
            5:
                HV := R.Comp.HasValue();
            97761:
                HV := R.Added.HasValue();
        end;
        CalcF(R, F);
        T := RF(R, F);
        exit(HasValueText(HV) + ' ' + T);
    end;

    procedure Stored(K: Integer): Text
    begin
        exit(StoredF(K, 2));
    end;

    procedure StateName(S: Integer): Text
    begin
        case S of
            1:
                exit('mem');
            2:
                exit('ins');
            3:
                exit('calc');
            4:
                exit('get');
            5:
                exit('empty');
            6:
                exit('asg');
        end;
    end;

    procedure IsStoredState(S: Integer): Boolean
    begin
        exit(S in [2, 3, 4]);
    end;

    // Puts R (key K) into state S, with 'alpha' in field F where the state has a value:
    // 1 mem   written in memory, not stored
    // 2 ins   written, then Insert (the Blob stays in memory)
    // 3 calc  stored, read again with Get and CalcFields
    // 4 get   stored, read again with Get only (Blob not loaded)
    // 5 empty Init only, not stored
    // 6 asg   copied by := from another record that holds 'alpha', not stored
    procedure PrepareF(var R: Record "LT BC3 Row"; S: Integer; K: Integer; F: Integer)
    var
        Other: Record "LT BC3 Row";
        TempOther: Record "LT BC3 Row" temporary;
    begin
        R.Init();
        R.Key1 := K;
        case S of
            1:
                WF(R, F, 'alpha');
            2:
                begin
                    WF(R, F, 'alpha');
                    R.Insert();
                end;
            3, 4:
                begin
                    WF(R, F, 'alpha');
                    R.Insert();
                    if R.IsTemporary() then
                        R.Init()
                    else
                        Clear(R);
                    R.Get(K);
                    if S = 3 then
                        CalcF(R, F);
                end;
            6:
                if R.IsTemporary() then begin
                    TempOther.Key1 := K;
                    WF(TempOther, F, 'alpha');
                    R := TempOther;
                end else begin
                    Other.Key1 := K;
                    WF(Other, F, 'alpha');
                    R := Other;
                end;
        end;
    end;

    procedure Prepare(var R: Record "LT BC3 Row"; S: Integer; K: Integer)
    begin
        PrepareF(R, S, K, 2);
    end;

    // Stores R: Modify for the stored states, Insert for the others.
    procedure Persist(var R: Record "LT BC3 Row"; S: Integer)
    begin
        if IsStoredState(S) then
            R.Modify()
        else
            R.Insert();
    end;

    procedure Reset()
    var
        R: Record "LT BC3 Row";
    begin
        R.DeleteAll();
    end;
}

// Codeunit.Run with TableNo: the OnRun trigger reads and writes the record it is given.
codeunit 97769 "LT BC3 Run"
{
    TableNo = "LT BC3 Row";

    trigger OnRun()
    var
        L: Codeunit "LT BC3 Lib";
    begin
        Rec.Seen := CopyStr(L.Rd(Rec), 1, 250);
        L.W(Rec, 'run');
    end;
}

codeunit 97770 "LT BC3 Pub"
{
    [IntegrationEvent(false, false)]
    procedure OnByValue(R: Record "LT BC3 Row"; var AtEntry: Text; var AfterWrite: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnByVar(var R: Record "LT BC3 Row"; var AtEntry: Text; var AfterWrite: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnByVarSubByValue(var R: Record "LT BC3 Row"; var AtEntry: Text; var AfterWrite: Text)
    begin
    end;
}

codeunit 97771 "LT BC3 Subs"
{
    var
        L: Codeunit "LT BC3 Lib";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT BC3 Pub", 'OnByValue', '', false, false)]
    local procedure HandleByValue(R: Record "LT BC3 Row"; var AtEntry: Text; var AfterWrite: Text)
    begin
        AtEntry := L.Rd(R);
        L.W(R, 'zz');
        AfterWrite := L.Rd(R);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT BC3 Pub", 'OnByVar', '', false, false)]
    local procedure HandleByVar(var R: Record "LT BC3 Row"; var AtEntry: Text; var AfterWrite: Text)
    begin
        AtEntry := L.Rd(R);
        L.W(R, 'zz');
        AfterWrite := L.Rd(R);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT BC3 Pub", 'OnByVarSubByValue', '', false, false)]
    local procedure HandleByVarSubByValue(R: Record "LT BC3 Row"; var AtEntry: Text; var AfterWrite: Text)
    begin
        AtEntry := L.Rd(R);
        L.W(R, 'zz');
        AfterWrite := L.Rd(R);
    end;
}

// ---- FieldRef.Value and FieldRef.Validate into Compressed = false, Compressed = true and table extension Blob fields ----
codeunit 97764 "LT BC3 FieldRef Into"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT BC3 Lib";

    local procedure SetTarget(var RR: RecordRef; F: Integer; UseValidate: Boolean; var Src: Record "LT BC3 Row")
    begin
        if UseValidate then
            RR.Field(F).Validate(Src.Data)
        else
            RR.Field(F).Value := Src.Data;
    end;

    // Source: field Data of row 100 + K in state S. Target: field F of a RecordRef on row K.
    local procedure Into(var Observer: Codeunit "Probe Observer"; Tag: Text; F: Integer; UseValidate: Boolean; S: Integer)
    var
        Src: Record "LT BC3 Row";
        Zz: Record "LT BC3 Row" temporary;
        Dst: Record "LT BC3 Row";
        RR: RecordRef;
        P: Text;
        K: Integer;
    begin
        L.Reset();
        K := 1;
        P := Tag + ' ' + L.StateName(S) + ' ';
        L.Prepare(Src, S, 100 + K);
        Dst.Key1 := K;
        RR.GetTable(Dst);
        SetTarget(RR, F, UseValidate, Src);
        Observer.Observe(P + 'rr', L.RdRR(RR, F));
        L.W(Src, 'beta');
        Observer.Observe(P + 'rr w src', L.RdRR(RR, F));
        RR.Insert();
        Observer.Observe(P + 'row ins', L.StoredF(K, F));
        L.W(Src, 'gammagamma');
        RR.Modify();
        Observer.Observe(P + 'row w src mod', L.StoredF(K, F));
        L.W(Zz, 'zz');
        SetTarget(RR, F, UseValidate, Zz);
        Observer.Observe(P + 'src t set', L.Rd(Src));
        RR.Modify();
        Observer.Observe(P + 'row t set mod', L.StoredF(K, F));
    end;

    // Source and target are the same field kind F.
    local procedure SameKind(var Observer: Codeunit "Probe Observer"; Tag: Text; F: Integer)
    var
        Src: Record "LT BC3 Row" temporary;
        Dst: Record "LT BC3 Row";
        RR: RecordRef;
    begin
        L.Reset();
        L.WF(Src, F, 'alpha');
        Dst.Key1 := 2;
        RR.GetTable(Dst);
        case F of
            4:
                RR.Field(F).Value := Src.Plain;
            5:
                RR.Field(F).Value := Src.Comp;
            97761:
                RR.Field(F).Value := Src.Added;
        end;
        L.WF(Src, F, 'beta');
        Observer.Observe(Tag + ' same rr w src', L.RdRR(RR, F));
        RR.Insert();
        Observer.Observe(Tag + ' same row', L.StoredF(2, F));
    end;

    // A Variant that holds field Data assigned to field F.
    local procedure VariantInto(var Observer: Codeunit "Probe Observer"; Tag: Text; F: Integer)
    var
        Src: Record "LT BC3 Row" temporary;
        Dst: Record "LT BC3 Row" temporary;
        V: Variant;
    begin
        L.W(Src, 'alpha');
        V := Src.Data;
        case F of
            4:
                Dst.Plain := V;
            5:
                Dst.Comp := V;
            97761:
                Dst.Added := V;
        end;
        Observer.Observe(Tag + ' var dst', L.RF(Dst, F));
        L.W(Src, 'beta');
        Observer.Observe(Tag + ' var dst w src', L.RF(Dst, F));
        L.WF(Dst, F, 'zz');
        Observer.Observe(Tag + ' var src w dst', L.Rd(Src));
    end;

    // Field Data assigned directly to field F.
    local procedure AssignInto(var Observer: Codeunit "Probe Observer"; Tag: Text; F: Integer)
    var
        Src: Record "LT BC3 Row" temporary;
        Dst: Record "LT BC3 Row" temporary;
    begin
        L.W(Src, 'alpha');
        case F of
            4:
                Dst.Plain := Src.Data;
            5:
                Dst.Comp := Src.Data;
            97761:
                Dst.Added := Src.Data;
        end;
        Observer.Observe(Tag + ' asg dst', L.RF(Dst, F));
        L.W(Src, 'beta');
        Observer.Observe(Tag + ' asg dst w src', L.RF(Dst, F));
        L.WF(Dst, F, 'zz');
        Observer.Observe(Tag + ' asg src w dst', L.Rd(Src));
    end;

    [Test]
    procedure Value_IntoPlain_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'plain value', 4, false, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Value_IntoPlain_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'plain value', 4, false, 5);
        Observer.Finish();
    end;

    [Test]
    procedure Value_IntoPlain_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'plain value', 4, false, 4);
        Observer.Finish();
    end;

    [Test]
    procedure Value_IntoPlain_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'plain value', 4, false, 3);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_IntoPlain_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'plain validate', 4, true, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_IntoPlain_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'plain validate', 4, true, 5);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_IntoPlain_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'plain validate', 4, true, 4);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_IntoPlain_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'plain validate', 4, true, 3);
        Observer.Finish();
    end;

    [Test]
    procedure Value_IntoComp_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'comp value', 5, false, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Value_IntoComp_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'comp value', 5, false, 5);
        Observer.Finish();
    end;

    [Test]
    procedure Value_IntoComp_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'comp value', 5, false, 4);
        Observer.Finish();
    end;

    [Test]
    procedure Value_IntoComp_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'comp value', 5, false, 3);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_IntoComp_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'comp validate', 5, true, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_IntoComp_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'comp validate', 5, true, 5);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_IntoComp_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'comp validate', 5, true, 4);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_IntoComp_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'comp validate', 5, true, 3);
        Observer.Finish();
    end;

    [Test]
    procedure Value_IntoExt_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'ext value', 97761, false, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Value_IntoExt_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'ext value', 97761, false, 5);
        Observer.Finish();
    end;

    [Test]
    procedure Value_IntoExt_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'ext value', 97761, false, 4);
        Observer.Finish();
    end;

    [Test]
    procedure Value_IntoExt_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'ext value', 97761, false, 3);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_IntoExt_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'ext validate', 97761, true, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_IntoExt_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'ext validate', 97761, true, 5);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_IntoExt_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'ext validate', 97761, true, 4);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_IntoExt_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'ext validate', 97761, true, 3);
        Observer.Finish();
    end;

    [Test]
    procedure Value_SameKind_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SameKind(Observer, 'plain', 4);
        Observer.Finish();
    end;

    [Test]
    procedure Value_SameKind_Comp()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SameKind(Observer, 'comp', 5);
        Observer.Finish();
    end;

    [Test]
    procedure Value_SameKind_Ext()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SameKind(Observer, 'ext', 97761);
        Observer.Finish();
    end;

    [Test]
    procedure Variant_IntoPlain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        VariantInto(Observer, 'plain', 4);
        Observer.Finish();
    end;

    [Test]
    procedure Variant_IntoComp()
    var
        Observer: Codeunit "Probe Observer";
    begin
        VariantInto(Observer, 'comp', 5);
        Observer.Finish();
    end;

    [Test]
    procedure Variant_IntoExt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        VariantInto(Observer, 'ext', 97761);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_IntoPlain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AssignInto(Observer, 'plain', 4);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_IntoComp()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AssignInto(Observer, 'comp', 5);
        Observer.Finish();
    end;

    [Test]
    procedure Assign_IntoExt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AssignInto(Observer, 'ext', 97761);
        Observer.Finish();
    end;

}

// ---- Record by value, Record.Copy, TransferFields, a global Variant and a Variant array element, per source state ----
codeunit 97765 "LT BC3 Record Moves"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT BC3 Lib";
        GV: Variant;

    local procedure Callee(R: Record "LT BC3 Row"; var AtEntry: Text; var AfterWrite: Text)
    begin
        AtEntry := L.Rd(R);
        L.W(R, 'zz');
        AfterWrite := L.Rd(R);
    end;

    local procedure CalleeCalc(R: Record "LT BC3 Row"; var AtEntry: Text; var AfterWrite: Text)
    begin
        R.CalcFields(Data);
        AtEntry := L.Rd(R);
        L.W(R, 'zz');
        AfterWrite := L.Rd(R);
    end;

    local procedure ByValue(var Observer: Codeunit "Probe Observer"; S: Integer; WithCalc: Boolean)
    var
        Src: Record "LT BC3 Row";
        A: Text;
        B: Text;
        P: Text;
    begin
        L.Reset();
        P := 'bv ' + L.StateName(S) + ' ';
        if WithCalc then
            P := 'bvc ' + L.StateName(S) + ' ';
        L.Prepare(Src, S, 10);
        Observer.Observe(P + 'src', L.Rd(Src));
        if WithCalc then
            CalleeCalc(Src, A, B)
        else
            Callee(Src, A, B);
        Observer.Observe(P + 'in entry', A);
        Observer.Observe(P + 'in w', B);
        Observer.Observe(P + 'src after call', L.Rd(Src));
        L.Persist(Src, S);
        Observer.Observe(P + 'row', L.Stored(10));
        Observer.Observe(P + 'src after persist', L.Rd(Src));
    end;

    local procedure CopyMove(var Observer: Codeunit "Probe Observer"; S: Integer)
    var
        Src: Record "LT BC3 Row";
        Dst: Record "LT BC3 Row";
        P: Text;
    begin
        L.Reset();
        P := 'copy ' + L.StateName(S) + ' ';
        L.Prepare(Src, S, 11);
        Dst.Copy(Src);
        Observer.Observe(P + 'dst', L.Rd(Dst));
        L.W(Src, 'beta');
        Observer.Observe(P + 'dst w src', L.Rd(Dst));
        L.W(Dst, 'zz');
        Observer.Observe(P + 'src w dst', L.Rd(Src));
        Observer.Observe(P + 'dst w dst', L.Rd(Dst));
        L.Persist(Src, S);
        Observer.Observe(P + 'row', L.Stored(11));
    end;

    local procedure TransferMove(var Observer: Codeunit "Probe Observer"; S: Integer; InitPK: Boolean)
    var
        Src: Record "LT BC3 Row";
        Dst: Record "LT BC3 Row";
        P: Text;
    begin
        L.Reset();
        P := 'tf ' + Format(InitPK) + ' ' + L.StateName(S) + ' ';
        L.Prepare(Src, S, 12);
        Dst.Init();
        Dst.Key1 := 62;
        Dst.TransferFields(Src, InitPK);
        Observer.Observe(P + 'dst key', Format(Dst.Key1));
        Observer.Observe(P + 'dst', L.Rd(Dst));
        L.W(Src, 'beta');
        Observer.Observe(P + 'dst w src', L.Rd(Dst));
        L.W(Dst, 'zz');
        Observer.Observe(P + 'src w dst', L.Rd(Src));
        L.Persist(Src, S);
        Observer.Observe(P + 'row src', L.Stored(12));
        if not InitPK then begin
            Dst.Insert();
            Observer.Observe(P + 'row dst', L.Stored(62));
        end;
    end;

    local procedure GlobalVariantMove(var Observer: Codeunit "Probe Observer"; S: Integer)
    var
        Src: Record "LT BC3 Row";
        Dst: Record "LT BC3 Row";
        Dst2: Record "LT BC3 Row";
        P: Text;
    begin
        L.Reset();
        P := 'gv ' + L.StateName(S) + ' ';
        L.Prepare(Src, S, 13);
        GV := Src;
        L.W(Src, 'beta');
        Dst := GV;
        Observer.Observe(P + 'dst w src', L.Rd(Dst));
        L.W(Dst, 'zz');
        Observer.Observe(P + 'src w dst', L.Rd(Src));
        Dst2 := GV;
        Observer.Observe(P + 'dst2 w dst', L.Rd(Dst2));
        L.Persist(Src, S);
        Observer.Observe(P + 'row', L.Stored(13));
    end;

    local procedure ArrayVariantMove(var Observer: Codeunit "Probe Observer"; S: Integer)
    var
        Src: Record "LT BC3 Row";
        Dst: Record "LT BC3 Row";
        Dst2: Record "LT BC3 Row";
        VA: array[3] of Variant;
        P: Text;
    begin
        L.Reset();
        P := 'va ' + L.StateName(S) + ' ';
        L.Prepare(Src, S, 14);
        VA[2] := Src;
        L.W(Src, 'beta');
        Dst := VA[2];
        Observer.Observe(P + 'dst w src', L.Rd(Dst));
        L.W(Dst, 'zz');
        Observer.Observe(P + 'src w dst', L.Rd(Src));
        Dst2 := VA[2];
        Observer.Observe(P + 'dst2 w dst', L.Rd(Dst2));
        L.Persist(Src, S);
        Observer.Observe(P + 'row', L.Stored(14));
    end;

    [Test]
    procedure ByValue_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ByValue(Observer, 1, false);
        Observer.Finish();
    end;

    [Test]
    procedure ByValue_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ByValue(Observer, 2, false);
        Observer.Finish();
    end;

    [Test]
    procedure ByValue_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ByValue(Observer, 3, false);
        Observer.Finish();
    end;

    [Test]
    procedure ByValue_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ByValue(Observer, 4, false);
        Observer.Finish();
    end;

    [Test]
    procedure ByValue_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ByValue(Observer, 5, false);
        Observer.Finish();
    end;

    [Test]
    procedure ByValue_Asg()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ByValue(Observer, 6, false);
        Observer.Finish();
    end;

    [Test]
    procedure ByValue_CalleeCalcFields_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ByValue(Observer, 4, true);
        Observer.Finish();
    end;

    [Test]
    procedure ByValue_CalleeCalcFields_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ByValue(Observer, 2, true);
        Observer.Finish();
    end;

    [Test]
    procedure Copy_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CopyMove(Observer, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Copy_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CopyMove(Observer, 2);
        Observer.Finish();
    end;

    [Test]
    procedure Copy_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CopyMove(Observer, 3);
        Observer.Finish();
    end;

    [Test]
    procedure Copy_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CopyMove(Observer, 4);
        Observer.Finish();
    end;

    [Test]
    procedure Copy_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CopyMove(Observer, 5);
        Observer.Finish();
    end;

    [Test]
    procedure Copy_Asg()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CopyMove(Observer, 6);
        Observer.Finish();
    end;

    [Test]
    procedure TransferFields_InitPK_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TransferMove(Observer, 1, true);
        Observer.Finish();
    end;

    [Test]
    procedure TransferFields_InitPK_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TransferMove(Observer, 2, true);
        Observer.Finish();
    end;

    [Test]
    procedure TransferFields_InitPK_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TransferMove(Observer, 3, true);
        Observer.Finish();
    end;

    [Test]
    procedure TransferFields_InitPK_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TransferMove(Observer, 4, true);
        Observer.Finish();
    end;

    [Test]
    procedure TransferFields_InitPK_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TransferMove(Observer, 5, true);
        Observer.Finish();
    end;

    [Test]
    procedure TransferFields_InitPK_Asg()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TransferMove(Observer, 6, true);
        Observer.Finish();
    end;

    [Test]
    procedure TransferFields_KeepPK_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TransferMove(Observer, 1, false);
        Observer.Finish();
    end;

    [Test]
    procedure TransferFields_KeepPK_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TransferMove(Observer, 2, false);
        Observer.Finish();
    end;

    [Test]
    procedure TransferFields_KeepPK_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TransferMove(Observer, 3, false);
        Observer.Finish();
    end;

    [Test]
    procedure TransferFields_KeepPK_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TransferMove(Observer, 4, false);
        Observer.Finish();
    end;

    [Test]
    procedure TransferFields_KeepPK_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TransferMove(Observer, 5, false);
        Observer.Finish();
    end;

    [Test]
    procedure TransferFields_KeepPK_Asg()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TransferMove(Observer, 6, false);
        Observer.Finish();
    end;

    [Test]
    procedure GlobalVariant_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GlobalVariantMove(Observer, 1);
        Observer.Finish();
    end;

    [Test]
    procedure GlobalVariant_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GlobalVariantMove(Observer, 2);
        Observer.Finish();
    end;

    [Test]
    procedure GlobalVariant_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GlobalVariantMove(Observer, 3);
        Observer.Finish();
    end;

    [Test]
    procedure GlobalVariant_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GlobalVariantMove(Observer, 4);
        Observer.Finish();
    end;

    [Test]
    procedure GlobalVariant_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GlobalVariantMove(Observer, 5);
        Observer.Finish();
    end;

    [Test]
    procedure GlobalVariant_Asg()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GlobalVariantMove(Observer, 6);
        Observer.Finish();
    end;

    [Test]
    procedure VariantArray_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArrayVariantMove(Observer, 1);
        Observer.Finish();
    end;

    [Test]
    procedure VariantArray_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArrayVariantMove(Observer, 2);
        Observer.Finish();
    end;

    [Test]
    procedure VariantArray_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArrayVariantMove(Observer, 3);
        Observer.Finish();
    end;

    [Test]
    procedure VariantArray_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArrayVariantMove(Observer, 4);
        Observer.Finish();
    end;

    [Test]
    procedure VariantArray_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArrayVariantMove(Observer, 5);
        Observer.Finish();
    end;

    [Test]
    procedure VariantArray_Asg()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArrayVariantMove(Observer, 6);
        Observer.Finish();
    end;

}

// ---- SetTable(Rec, true), temporary and non-temporary parameters, Record.Copy between temporary and stored records ----
codeunit 97766 "LT BC3 Temp Moves"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT BC3 Lib";

    local procedure ShareMoveTemp(var Observer: Codeunit "Probe Observer"; S: Integer)
    var
        Src: Record "LT BC3 Row" temporary;
        Dst: Record "LT BC3 Row" temporary;
        RR: RecordRef;
        P: Text;
    begin
        P := 'sht ' + L.StateName(S) + ' ';
        L.Prepare(Src, S, 20);
        RR.GetTable(Src);
        L.W(Src, 'beta');
        RR.SetTable(Dst, true);
        Observer.Observe(P + 'dst', L.Rd(Dst));
        L.W(Dst, 'zz');
        Observer.Observe(P + 'src w dst', L.Rd(Src));
        Observer.Observe(P + 'rr w dst', L.RdRR(RR, 2));
        L.W(Src, 'gammagamma');
        Observer.Observe(P + 'dst w src', L.Rd(Dst));
        if L.IsStoredState(S) then begin
            Dst.Get(20);
            Observer.Observe(P + 'dst get', L.Rd(Dst));
        end;
    end;

    local procedure ShareMoveStored(var Observer: Codeunit "Probe Observer"; S: Integer)
    var
        Src: Record "LT BC3 Row";
        Dst: Record "LT BC3 Row";
        RR: RecordRef;
        P: Text;
    begin
        L.Reset();
        P := 'shs ' + L.StateName(S) + ' ';
        L.Prepare(Src, S, 21);
        RR.GetTable(Src);
        L.W(Src, 'beta');
        RR.SetTable(Dst, true);
        Observer.Observe(P + 'dst', L.Rd(Dst));
        L.W(Dst, 'zz');
        Observer.Observe(P + 'src w dst', L.Rd(Src));
        Observer.Observe(P + 'rr w dst', L.RdRR(RR, 2));
        L.W(Src, 'gammagamma');
        Observer.Observe(P + 'dst w src', L.Rd(Dst));
        L.Persist(Src, S);
        Observer.Observe(P + 'row', L.Stored(21));
    end;

    local procedure TakeNonTemp(R: Record "LT BC3 Row"; var IsTemp: Text; var AtEntry: Text; var AfterWrite: Text)
    begin
        IsTemp := Format(R.IsTemporary());
        AtEntry := L.Rd(R);
        L.W(R, 'zz');
        AfterWrite := L.Rd(R);
    end;

    local procedure TakeTemp(R: Record "LT BC3 Row" temporary; var IsTemp: Text; var AtEntry: Text; var AfterWrite: Text)
    begin
        IsTemp := Format(R.IsTemporary());
        AtEntry := L.Rd(R);
        L.W(R, 'zz');
        AfterWrite := L.Rd(R);
    end;

    local procedure TempToNonTempParam(var Observer: Codeunit "Probe Observer"; S: Integer)
    var
        Src: Record "LT BC3 Row" temporary;
        IsTemp: Text;
        A: Text;
        B: Text;
        P: Text;
    begin
        P := 'tmppar ' + L.StateName(S) + ' ';
        L.Prepare(Src, S, 22);
        TakeNonTemp(Src, IsTemp, A, B);
        Observer.Observe(P + 'in temp', IsTemp);
        Observer.Observe(P + 'in entry', A);
        Observer.Observe(P + 'in w', B);
        Observer.Observe(P + 'src', L.Rd(Src));
        if L.IsStoredState(S) then begin
            Src.Get(22);
            Observer.Observe(P + 'src get', L.Rd(Src));
        end;
    end;

    local procedure NonTempToTempParam(var Observer: Codeunit "Probe Observer"; S: Integer)
    var
        Src: Record "LT BC3 Row";
        IsTemp: Text;
        A: Text;
        B: Text;
        P: Text;
    begin
        L.Reset();
        P := 'rectmp ' + L.StateName(S) + ' ';
        L.Prepare(Src, S, 23);
        TakeTemp(Src, IsTemp, A, B);
        Observer.Observe(P + 'in temp', IsTemp);
        Observer.Observe(P + 'in entry', A);
        Observer.Observe(P + 'in w', B);
        Observer.Observe(P + 'src', L.Rd(Src));
        L.Persist(Src, S);
        Observer.Observe(P + 'row', L.Stored(23));
    end;

    [TryFunction]
    local procedure TryCopy(var Dst: Record "LT BC3 Row"; var Src: Record "LT BC3 Row")
    begin
        Dst.Copy(Src);
    end;

    local procedure CopyStoredToTemp(var Observer: Codeunit "Probe Observer"; S: Integer)
    var
        Src: Record "LT BC3 Row";
        Dst: Record "LT BC3 Row" temporary;
        P: Text;
    begin
        L.Reset();
        P := 'copy2tmp ' + L.StateName(S) + ' ';
        L.Prepare(Src, S, 24);
        if TryCopy(Dst, Src) then
            Observer.Observe(P + 'copy', 'ok')
        else
            Observer.ObserveError(P + 'copy');
        Observer.Observe(P + 'dst temp', Format(Dst.IsTemporary()));
        Observer.Observe(P + 'dst', L.Rd(Dst));
        L.W(Src, 'beta');
        Observer.Observe(P + 'dst w src', L.Rd(Dst));
        L.W(Dst, 'zz');
        Observer.Observe(P + 'src w dst', L.Rd(Src));
        L.Persist(Src, S);
        Observer.Observe(P + 'row', L.Stored(24));
    end;

    local procedure CopyTempToStored(var Observer: Codeunit "Probe Observer"; S: Integer)
    var
        Src: Record "LT BC3 Row" temporary;
        Dst: Record "LT BC3 Row";
        P: Text;
    begin
        L.Reset();
        P := 'copy2rec ' + L.StateName(S) + ' ';
        L.Prepare(Src, S, 25);
        if TryCopy(Dst, Src) then
            Observer.Observe(P + 'copy', 'ok')
        else
            Observer.ObserveError(P + 'copy');
        Observer.Observe(P + 'dst temp', Format(Dst.IsTemporary()));
        Observer.Observe(P + 'dst', L.Rd(Dst));
        L.W(Src, 'beta');
        Observer.Observe(P + 'dst w src', L.Rd(Dst));
        L.W(Dst, 'zz');
        Observer.Observe(P + 'src w dst', L.Rd(Src));
    end;

    [Test]
    procedure SetTableShare_Temp_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShareMoveTemp(Observer, 1);
        Observer.Finish();
    end;

    [Test]
    procedure SetTableShare_Temp_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShareMoveTemp(Observer, 2);
        Observer.Finish();
    end;

    [Test]
    procedure SetTableShare_Temp_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShareMoveTemp(Observer, 3);
        Observer.Finish();
    end;

    [Test]
    procedure SetTableShare_Temp_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShareMoveTemp(Observer, 4);
        Observer.Finish();
    end;

    [Test]
    procedure SetTableShare_Temp_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShareMoveTemp(Observer, 5);
        Observer.Finish();
    end;

    [Test]
    procedure SetTableShare_Temp_Asg()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShareMoveTemp(Observer, 6);
        Observer.Finish();
    end;

    [Test]
    procedure SetTableShare_Stored_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShareMoveStored(Observer, 1);
        Observer.Finish();
    end;

    [Test]
    procedure SetTableShare_Stored_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShareMoveStored(Observer, 2);
        Observer.Finish();
    end;

    [Test]
    procedure SetTableShare_Stored_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShareMoveStored(Observer, 3);
        Observer.Finish();
    end;

    [Test]
    procedure SetTableShare_Stored_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShareMoveStored(Observer, 4);
        Observer.Finish();
    end;

    [Test]
    procedure SetTableShare_Stored_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShareMoveStored(Observer, 5);
        Observer.Finish();
    end;

    [Test]
    procedure SetTableShare_Stored_Asg()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShareMoveStored(Observer, 6);
        Observer.Finish();
    end;

    [Test]
    procedure TempToNonTempParam_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TempToNonTempParam(Observer, 1);
        Observer.Finish();
    end;

    [Test]
    procedure TempToNonTempParam_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TempToNonTempParam(Observer, 2);
        Observer.Finish();
    end;

    [Test]
    procedure TempToNonTempParam_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TempToNonTempParam(Observer, 4);
        Observer.Finish();
    end;

    [Test]
    procedure NonTempToTempParam_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NonTempToTempParam(Observer, 1);
        Observer.Finish();
    end;

    [Test]
    procedure NonTempToTempParam_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NonTempToTempParam(Observer, 2);
        Observer.Finish();
    end;

    [Test]
    procedure NonTempToTempParam_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NonTempToTempParam(Observer, 4);
        Observer.Finish();
    end;

    [Test]
    procedure CopyStoredToTemp_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CopyStoredToTemp(Observer, 1);
        Observer.Finish();
    end;

    [Test]
    procedure CopyStoredToTemp_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CopyStoredToTemp(Observer, 2);
        Observer.Finish();
    end;

    [Test]
    procedure CopyStoredToTemp_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CopyStoredToTemp(Observer, 4);
        Observer.Finish();
    end;

    [Test]
    procedure CopyTempToStored_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CopyTempToStored(Observer, 1);
        Observer.Finish();
    end;

    [Test]
    procedure CopyTempToStored_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CopyTempToStored(Observer, 2);
        Observer.Finish();
    end;

}

// ---- By value into a [TryFunction], table triggers, Codeunit.Run, an event publisher and its subscriber ----
codeunit 97767 "LT BC3 Calls"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT BC3 Lib";

    [TryFunction]
    local procedure TryByValue(R: Record "LT BC3 Row"; var AtEntry: Text; var AfterWrite: Text)
    begin
        AtEntry := L.Rd(R);
        L.W(R, 'zz');
        AfterWrite := L.Rd(R);
    end;

    [TryFunction]
    local procedure TryByVar(var R: Record "LT BC3 Row"; var AtEntry: Text; var AfterWrite: Text)
    begin
        AtEntry := L.Rd(R);
        L.W(R, 'zz');
        AfterWrite := L.Rd(R);
    end;

    local procedure TryCall(var Observer: Codeunit "Probe Observer"; S: Integer; ByVar: Boolean)
    var
        Src: Record "LT BC3 Row";
        A: Text;
        B: Text;
        P: Text;
        Ok: Boolean;
    begin
        L.Reset();
        P := 'try ' + L.StateName(S) + ' ';
        if ByVar then
            P := 'tryvar ' + L.StateName(S) + ' ';
        L.Prepare(Src, S, 30);
        if ByVar then
            Ok := TryByVar(Src, A, B)
        else
            Ok := TryByValue(Src, A, B);
        Observer.Observe(P + 'ok', Format(Ok));
        Observer.Observe(P + 'in entry', A);
        Observer.Observe(P + 'in w', B);
        Observer.Observe(P + 'src', L.Rd(Src));
        L.Persist(Src, S);
        Observer.Observe(P + 'row', L.Stored(30));
    end;

    // Mode 1: OnModify reads xRec into Seen, then writes 'trig' into Rec.
    // Mode 2: OnModify writes 'xx' into xRec, then reads Rec into Seen.
    local procedure ModifyTrigger(var Observer: Codeunit "Probe Observer"; S: Integer; Mode: Integer)
    var
        Src: Record "LT BC3 Row";
        P: Text;
    begin
        L.Reset();
        P := 'onmodify' + Format(Mode) + ' ' + L.StateName(S) + ' ';
        L.Prepare(Src, S, 31);
        Src.Mode := Mode;
        Src.Modify(true);
        Observer.Observe(P + 'seen', Src.Seen);
        Observer.Observe(P + 'src', L.Rd(Src));
        Observer.Observe(P + 'row', L.Stored(31));
    end;

    // Mode 3: OnInsert writes 'ins' into Rec.
    local procedure InsertTrigger(var Observer: Codeunit "Probe Observer"; S: Integer)
    var
        Src: Record "LT BC3 Row";
        P: Text;
    begin
        L.Reset();
        P := 'oninsert ' + L.StateName(S) + ' ';
        L.Prepare(Src, S, 32);
        Src.Mode := 3;
        Src.Insert(true);
        Observer.Observe(P + 'src', L.Rd(Src));
        Observer.Observe(P + 'row', L.Stored(32));
    end;

    // Validate(Mode, 4): OnValidate writes 'val' into Rec.
    local procedure ValidateTrigger(var Observer: Codeunit "Probe Observer"; S: Integer)
    var
        Src: Record "LT BC3 Row";
        P: Text;
    begin
        L.Reset();
        P := 'onvalidate ' + L.StateName(S) + ' ';
        L.Prepare(Src, S, 33);
        Src.Validate(Mode, 4);
        Observer.Observe(P + 'src', L.Rd(Src));
        L.Persist(Src, S);
        Observer.Observe(P + 'row', L.Stored(33));
    end;

    local procedure RunTableNo(var Observer: Codeunit "Probe Observer"; S: Integer)
    var
        Src: Record "LT BC3 Row";
        P: Text;
    begin
        L.Reset();
        P := 'run ' + L.StateName(S) + ' ';
        L.Prepare(Src, S, 34);
        Codeunit.Run(Codeunit::"LT BC3 Run", Src);
        Observer.Observe(P + 'seen', Src.Seen);
        Observer.Observe(P + 'src', L.Rd(Src));
        L.Persist(Src, S);
        Observer.Observe(P + 'row', L.Stored(34));
    end;

    local procedure RunTableNoTemp(var Observer: Codeunit "Probe Observer"; S: Integer)
    var
        Src: Record "LT BC3 Row" temporary;
        P: Text;
    begin
        P := 'runtmp ' + L.StateName(S) + ' ';
        L.Prepare(Src, S, 35);
        Codeunit.Run(Codeunit::"LT BC3 Run", Src);
        Observer.Observe(P + 'seen', Src.Seen);
        Observer.Observe(P + 'src', L.Rd(Src));
    end;

    // Kind 1: publisher and subscriber by value. 2: both var. 3: publisher var, subscriber by value.
    local procedure RaiseEvent(var Observer: Codeunit "Probe Observer"; S: Integer; Kind: Integer)
    var
        Src: Record "LT BC3 Row";
        Pub: Codeunit "LT BC3 Pub";
        A: Text;
        B: Text;
        P: Text;
    begin
        L.Reset();
        P := 'event' + Format(Kind) + ' ' + L.StateName(S) + ' ';
        L.Prepare(Src, S, 36);
        case Kind of
            1:
                Pub.OnByValue(Src, A, B);
            2:
                Pub.OnByVar(Src, A, B);
            3:
                Pub.OnByVarSubByValue(Src, A, B);
        end;
        Observer.Observe(P + 'in entry', A);
        Observer.Observe(P + 'in w', B);
        Observer.Observe(P + 'src', L.Rd(Src));
        L.Persist(Src, S);
        Observer.Observe(P + 'row', L.Stored(36));
    end;

    [Test]
    procedure TryFunction_ByValue_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryCall(Observer, 1, false);
        Observer.Finish();
    end;

    [Test]
    procedure TryFunction_ByValue_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryCall(Observer, 2, false);
        Observer.Finish();
    end;

    [Test]
    procedure TryFunction_ByValue_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryCall(Observer, 4, false);
        Observer.Finish();
    end;

    [Test]
    procedure TryFunction_ByVar_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryCall(Observer, 1, true);
        Observer.Finish();
    end;

    [Test]
    procedure OnModify_Mode1_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyTrigger(Observer, 2, 1);
        Observer.Finish();
    end;

    [Test]
    procedure OnModify_Mode1_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyTrigger(Observer, 3, 1);
        Observer.Finish();
    end;

    [Test]
    procedure OnModify_Mode1_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyTrigger(Observer, 4, 1);
        Observer.Finish();
    end;

    [Test]
    procedure OnModify_Mode2_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyTrigger(Observer, 2, 2);
        Observer.Finish();
    end;

    [Test]
    procedure OnModify_Mode2_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyTrigger(Observer, 3, 2);
        Observer.Finish();
    end;

    [Test]
    procedure OnModify_Mode2_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyTrigger(Observer, 4, 2);
        Observer.Finish();
    end;

    [Test]
    procedure OnInsert_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        InsertTrigger(Observer, 1);
        Observer.Finish();
    end;

    [Test]
    procedure OnInsert_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        InsertTrigger(Observer, 5);
        Observer.Finish();
    end;

    [Test]
    procedure OnValidate_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ValidateTrigger(Observer, 1);
        Observer.Finish();
    end;

    [Test]
    procedure OnValidate_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ValidateTrigger(Observer, 2);
        Observer.Finish();
    end;

    [Test]
    procedure OnValidate_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ValidateTrigger(Observer, 4);
        Observer.Finish();
    end;

    [Test]
    procedure CodeunitRun_TableNo_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTableNo(Observer, 1);
        Observer.Finish();
    end;

    [Test]
    procedure CodeunitRun_TableNo_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTableNo(Observer, 2);
        Observer.Finish();
    end;

    [Test]
    procedure CodeunitRun_TableNo_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTableNo(Observer, 4);
        Observer.Finish();
    end;

    [Test]
    procedure CodeunitRun_TableNo_Temp_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTableNoTemp(Observer, 1);
        Observer.Finish();
    end;

    [Test]
    procedure CodeunitRun_TableNo_Temp_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTableNoTemp(Observer, 2);
        Observer.Finish();
    end;

    [Test]
    procedure Event_ByValue_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RaiseEvent(Observer, 1, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Event_ByValue_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RaiseEvent(Observer, 2, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Event_ByValue_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RaiseEvent(Observer, 4, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Event_ByVar_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RaiseEvent(Observer, 1, 2);
        Observer.Finish();
    end;

    [Test]
    procedure Event_ByVar_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RaiseEvent(Observer, 2, 2);
        Observer.Finish();
    end;

    [Test]
    procedure Event_ByVar_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RaiseEvent(Observer, 4, 2);
        Observer.Finish();
    end;

    [Test]
    procedure Event_VarPublisherValueSubscriber_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RaiseEvent(Observer, 1, 3);
        Observer.Finish();
    end;

    [Test]
    procedure Event_VarPublisherValueSubscriber_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RaiseEvent(Observer, 2, 3);
        Observer.Finish();
    end;

    [Test]
    procedure Event_VarPublisherValueSubscriber_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RaiseEvent(Observer, 4, 3);
        Observer.Finish();
    end;

}
