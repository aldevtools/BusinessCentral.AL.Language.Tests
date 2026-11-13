// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-value-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 97760, 97762, table extension 97761, interface "LT BC3 Taker",
//   helper codeunits 97763, 97769, 97770, 97771, 97772; test codeunits 97764, 97765, 97766, 97767, 97768
// Probe: written against real BC (al-runner issue 7948, third probe; the earlier ones are recordref-fieldref/fieldref/FieldRefValueBlobCopy.al
//   and streams/BlobValueCopyShapes.al).
// Facts: whether a Blob value is copied or shared, per state of the source Blob, when it moves through FieldRef.Value and FieldRef.Validate
//   into a Compressed = false, a Compressed = true and a table extension Blob field, a record passed by value (also into a [TryFunction],
//   an event publisher and its subscriber, a temporary record into a non-temporary parameter and the reverse), Record.Copy (also between a
//   temporary and a stored record), RecordRef.SetTable(Rec, true), TransferFields with both InitPrimaryKeyFields values, a global Variant,
//   a Variant array element, Codeunit.Run with TableNo, and the table triggers OnInsert, OnModify (Rec and xRec) and OnValidate;
//   neighbors: a Blob written again after Insert or Modify, a Blob filled by := or FieldRef.Value and then moved, other field kinds in
//   a Variant, and a callee in another codeunit, an interface method, a table procedure, a var parameter passed on by value, a global record.
//   Source states: mem (written in memory, not stored), ins (written, then Insert), calc (stored, Get and CalcFields), get (stored, Get only,
//   Blob not loaded), empty (Init only), asg (copied by := from another record that holds 'alpha').
//   Value format: hv: or nohv: (HasValue of the Blob in hand, no CalcFields) followed by the text read from the Blob in hand;
//   row = the stored row read through a fresh record: HasValue before CalcFields, a space, then hv:/nohv: and the text after CalcFields;
//   rr = the RecordRef read through SetTable into a fresh temporary record.
// What BC did (the same on 27.5, 28.5 and 29.0):
//   - Every by-value form copies the Blob when it runs, in every source state; a later write on either side never reaches the other,
//     and Insert or Modify stores only that side's value: FieldRef.Value and Validate into Compressed = false, Compressed = true and
//     table extension fields (also a same-kind source, a Variant and := into those fields); a record by value (also into a [TryFunction],
//     another codeunit, an interface method, a table procedure, a var parameter passed on by value, a global record, a by-value event
//     publisher, a var publisher with a by-value subscriber, a temporary record into a non-temporary parameter and the reverse);
//     Record.Copy (also stored to temporary and temporary to stored: no error, the target keeps its own temporariness); SetTable(Rec, true)
//     between temporary records; TransferFields(Src, true) and (Src, false), also into another table; a global Variant, a Variant array
//     element and a local Variant, also for Compressed = false, Compressed = true and table extension fields; a Variant holding a Blob
//     passed to a by-value Variant parameter.
//   - The same holds for a Blob written again after Insert or Modify, a Blob filled by := or FieldRef.Value and then moved, and a Blob read
//     with CalcFields and written again.
//   - A source read with Get only (Blob not loaded): FieldRef.Value, Validate and TransferFields give HasValue false; by value, Copy, the
//     Variants and SetTable give HasValue true and empty text; a write there starts empty ('zz'); the caller and the stored row keep 'alpha'.
//     An empty source gives an empty copy (nohv:).
//   - Get of a temporary row (also through a shared table) gives HasValue true and empty text without CalcFields.
//   - Shared, not copied: a [TryFunction] var parameter, a var event publisher with a var subscriber, Codeunit.Run with TableNo (also a
//     temporary record), and writes into Rec in OnInsert, OnModify and OnValidate: they reach the caller and the stored row. In OnModify
//     xRec holds the caller's value from memory; a write into xRec reaches neither Rec nor the row.
//   - RecordRef.SetTable(Rec, true) with records that are not temporary raises "The COPY function can only be used with the shareTable
//     argument set to true if both records are temporary." (code Argument); the target stays empty.
//   - CreateOutStream over a value does not truncate ('zz' over 'betaa' reads 'zztaa').
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

    // A table procedure that takes a record by value and writes its Blob.
    procedure TakeByValue(R: Record "LT BC3 Row"; var AfterWrite: Text)
    var
        L: Codeunit "LT BC3 Lib";
    begin
        L.W(R, 'zz');
        AfterWrite := L.Rd(R);
    end;
}

// A second table with the same field numbers (TransferFields into another table).
table 97762 "LT BC3 Other"
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

interface "LT BC3 Taker"
{
    procedure Take(R: Record "LT BC3 Row"; var AfterWrite: Text);
}

// A callee in another codeunit, also reached through an interface.
codeunit 97772 "LT BC3 Taker Impl" implements "LT BC3 Taker"
{
    procedure Take(R: Record "LT BC3 Row"; var AfterWrite: Text)
    var
        L: Codeunit "LT BC3 Lib";
    begin
        L.W(R, 'zz');
        AfterWrite := L.Rd(R);
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
        Observer.Expect('plain value mem rr', 'hv:alpha');
        Observer.Expect('plain value mem rr w src', 'hv:alpha');
        Observer.Expect('plain value mem row ins', 'hv: hv:alpha');
        Observer.Expect('plain value mem row w src mod', 'hv: hv:alpha');
        Observer.Expect('plain value mem src t set', 'hv:gammagamma');
        Observer.Expect('plain value mem row t set mod', 'hv: hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure Value_IntoPlain_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'plain value', 4, false, 5);
        Observer.Expect('plain value empty rr', 'nohv:');
        Observer.Expect('plain value empty rr w src', 'nohv:');
        Observer.Expect('plain value empty row ins', 'nohv: nohv:');
        Observer.Expect('plain value empty row w src mod', 'nohv: nohv:');
        Observer.Expect('plain value empty src t set', 'hv:gammagamma');
        Observer.Expect('plain value empty row t set mod', 'hv: hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure Value_IntoPlain_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'plain value', 4, false, 4);
        Observer.Expect('plain value get rr', 'nohv:');
        Observer.Expect('plain value get rr w src', 'nohv:');
        Observer.Expect('plain value get row ins', 'nohv: nohv:');
        Observer.Expect('plain value get row w src mod', 'nohv: nohv:');
        Observer.Expect('plain value get src t set', 'hv:gammagamma');
        Observer.Expect('plain value get row t set mod', 'hv: hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure Value_IntoPlain_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'plain value', 4, false, 3);
        Observer.Expect('plain value calc rr', 'hv:alpha');
        Observer.Expect('plain value calc rr w src', 'hv:alpha');
        Observer.Expect('plain value calc row ins', 'hv: hv:alpha');
        Observer.Expect('plain value calc row w src mod', 'hv: hv:alpha');
        Observer.Expect('plain value calc src t set', 'hv:gammagamma');
        Observer.Expect('plain value calc row t set mod', 'hv: hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_IntoPlain_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'plain validate', 4, true, 1);
        Observer.Expect('plain validate mem rr', 'hv:alpha');
        Observer.Expect('plain validate mem rr w src', 'hv:alpha');
        Observer.Expect('plain validate mem row ins', 'hv: hv:alpha');
        Observer.Expect('plain validate mem row w src mod', 'hv: hv:alpha');
        Observer.Expect('plain validate mem src t set', 'hv:gammagamma');
        Observer.Expect('plain validate mem row t set mod', 'hv: hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_IntoPlain_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'plain validate', 4, true, 5);
        Observer.Expect('plain validate empty rr', 'nohv:');
        Observer.Expect('plain validate empty rr w src', 'nohv:');
        Observer.Expect('plain validate empty row ins', 'nohv: nohv:');
        Observer.Expect('plain validate empty row w src mod', 'nohv: nohv:');
        Observer.Expect('plain validate empty src t set', 'hv:gammagamma');
        Observer.Expect('plain validate empty row t set mod', 'hv: hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_IntoPlain_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'plain validate', 4, true, 4);
        Observer.Expect('plain validate get rr', 'nohv:');
        Observer.Expect('plain validate get rr w src', 'nohv:');
        Observer.Expect('plain validate get row ins', 'nohv: nohv:');
        Observer.Expect('plain validate get row w src mod', 'nohv: nohv:');
        Observer.Expect('plain validate get src t set', 'hv:gammagamma');
        Observer.Expect('plain validate get row t set mod', 'hv: hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_IntoPlain_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'plain validate', 4, true, 3);
        Observer.Expect('plain validate calc rr', 'hv:alpha');
        Observer.Expect('plain validate calc rr w src', 'hv:alpha');
        Observer.Expect('plain validate calc row ins', 'hv: hv:alpha');
        Observer.Expect('plain validate calc row w src mod', 'hv: hv:alpha');
        Observer.Expect('plain validate calc src t set', 'hv:gammagamma');
        Observer.Expect('plain validate calc row t set mod', 'hv: hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure Value_IntoComp_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'comp value', 5, false, 1);
        Observer.Expect('comp value mem rr', 'hv:alpha');
        Observer.Expect('comp value mem rr w src', 'hv:alpha');
        Observer.Expect('comp value mem row ins', 'hv: hv:alpha');
        Observer.Expect('comp value mem row w src mod', 'hv: hv:alpha');
        Observer.Expect('comp value mem src t set', 'hv:gammagamma');
        Observer.Expect('comp value mem row t set mod', 'hv: hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure Value_IntoComp_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'comp value', 5, false, 5);
        Observer.Expect('comp value empty rr', 'nohv:');
        Observer.Expect('comp value empty rr w src', 'nohv:');
        Observer.Expect('comp value empty row ins', 'nohv: nohv:');
        Observer.Expect('comp value empty row w src mod', 'nohv: nohv:');
        Observer.Expect('comp value empty src t set', 'hv:gammagamma');
        Observer.Expect('comp value empty row t set mod', 'hv: hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure Value_IntoComp_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'comp value', 5, false, 4);
        Observer.Expect('comp value get rr', 'nohv:');
        Observer.Expect('comp value get rr w src', 'nohv:');
        Observer.Expect('comp value get row ins', 'nohv: nohv:');
        Observer.Expect('comp value get row w src mod', 'nohv: nohv:');
        Observer.Expect('comp value get src t set', 'hv:gammagamma');
        Observer.Expect('comp value get row t set mod', 'hv: hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure Value_IntoComp_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'comp value', 5, false, 3);
        Observer.Expect('comp value calc rr', 'hv:alpha');
        Observer.Expect('comp value calc rr w src', 'hv:alpha');
        Observer.Expect('comp value calc row ins', 'hv: hv:alpha');
        Observer.Expect('comp value calc row w src mod', 'hv: hv:alpha');
        Observer.Expect('comp value calc src t set', 'hv:gammagamma');
        Observer.Expect('comp value calc row t set mod', 'hv: hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_IntoComp_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'comp validate', 5, true, 1);
        Observer.Expect('comp validate mem rr', 'hv:alpha');
        Observer.Expect('comp validate mem rr w src', 'hv:alpha');
        Observer.Expect('comp validate mem row ins', 'hv: hv:alpha');
        Observer.Expect('comp validate mem row w src mod', 'hv: hv:alpha');
        Observer.Expect('comp validate mem src t set', 'hv:gammagamma');
        Observer.Expect('comp validate mem row t set mod', 'hv: hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_IntoComp_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'comp validate', 5, true, 5);
        Observer.Expect('comp validate empty rr', 'nohv:');
        Observer.Expect('comp validate empty rr w src', 'nohv:');
        Observer.Expect('comp validate empty row ins', 'nohv: nohv:');
        Observer.Expect('comp validate empty row w src mod', 'nohv: nohv:');
        Observer.Expect('comp validate empty src t set', 'hv:gammagamma');
        Observer.Expect('comp validate empty row t set mod', 'hv: hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_IntoComp_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'comp validate', 5, true, 4);
        Observer.Expect('comp validate get rr', 'nohv:');
        Observer.Expect('comp validate get rr w src', 'nohv:');
        Observer.Expect('comp validate get row ins', 'nohv: nohv:');
        Observer.Expect('comp validate get row w src mod', 'nohv: nohv:');
        Observer.Expect('comp validate get src t set', 'hv:gammagamma');
        Observer.Expect('comp validate get row t set mod', 'hv: hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_IntoComp_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'comp validate', 5, true, 3);
        Observer.Expect('comp validate calc rr', 'hv:alpha');
        Observer.Expect('comp validate calc rr w src', 'hv:alpha');
        Observer.Expect('comp validate calc row ins', 'hv: hv:alpha');
        Observer.Expect('comp validate calc row w src mod', 'hv: hv:alpha');
        Observer.Expect('comp validate calc src t set', 'hv:gammagamma');
        Observer.Expect('comp validate calc row t set mod', 'hv: hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure Value_IntoExt_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'ext value', 97761, false, 1);
        Observer.Expect('ext value mem rr', 'hv:alpha');
        Observer.Expect('ext value mem rr w src', 'hv:alpha');
        Observer.Expect('ext value mem row ins', 'hv: hv:alpha');
        Observer.Expect('ext value mem row w src mod', 'hv: hv:alpha');
        Observer.Expect('ext value mem src t set', 'hv:gammagamma');
        Observer.Expect('ext value mem row t set mod', 'hv: hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure Value_IntoExt_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'ext value', 97761, false, 5);
        Observer.Expect('ext value empty rr', 'nohv:');
        Observer.Expect('ext value empty rr w src', 'nohv:');
        Observer.Expect('ext value empty row ins', 'nohv: nohv:');
        Observer.Expect('ext value empty row w src mod', 'nohv: nohv:');
        Observer.Expect('ext value empty src t set', 'hv:gammagamma');
        Observer.Expect('ext value empty row t set mod', 'hv: hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure Value_IntoExt_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'ext value', 97761, false, 4);
        Observer.Expect('ext value get rr', 'nohv:');
        Observer.Expect('ext value get rr w src', 'nohv:');
        Observer.Expect('ext value get row ins', 'nohv: nohv:');
        Observer.Expect('ext value get row w src mod', 'nohv: nohv:');
        Observer.Expect('ext value get src t set', 'hv:gammagamma');
        Observer.Expect('ext value get row t set mod', 'hv: hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure Value_IntoExt_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'ext value', 97761, false, 3);
        Observer.Expect('ext value calc rr', 'hv:alpha');
        Observer.Expect('ext value calc rr w src', 'hv:alpha');
        Observer.Expect('ext value calc row ins', 'hv: hv:alpha');
        Observer.Expect('ext value calc row w src mod', 'hv: hv:alpha');
        Observer.Expect('ext value calc src t set', 'hv:gammagamma');
        Observer.Expect('ext value calc row t set mod', 'hv: hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_IntoExt_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'ext validate', 97761, true, 1);
        Observer.Expect('ext validate mem rr', 'hv:alpha');
        Observer.Expect('ext validate mem rr w src', 'hv:alpha');
        Observer.Expect('ext validate mem row ins', 'hv: hv:alpha');
        Observer.Expect('ext validate mem row w src mod', 'hv: hv:alpha');
        Observer.Expect('ext validate mem src t set', 'hv:gammagamma');
        Observer.Expect('ext validate mem row t set mod', 'hv: hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_IntoExt_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'ext validate', 97761, true, 5);
        Observer.Expect('ext validate empty rr', 'nohv:');
        Observer.Expect('ext validate empty rr w src', 'nohv:');
        Observer.Expect('ext validate empty row ins', 'nohv: nohv:');
        Observer.Expect('ext validate empty row w src mod', 'nohv: nohv:');
        Observer.Expect('ext validate empty src t set', 'hv:gammagamma');
        Observer.Expect('ext validate empty row t set mod', 'hv: hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_IntoExt_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'ext validate', 97761, true, 4);
        Observer.Expect('ext validate get rr', 'nohv:');
        Observer.Expect('ext validate get rr w src', 'nohv:');
        Observer.Expect('ext validate get row ins', 'nohv: nohv:');
        Observer.Expect('ext validate get row w src mod', 'nohv: nohv:');
        Observer.Expect('ext validate get src t set', 'hv:gammagamma');
        Observer.Expect('ext validate get row t set mod', 'hv: hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_IntoExt_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Into(Observer, 'ext validate', 97761, true, 3);
        Observer.Expect('ext validate calc rr', 'hv:alpha');
        Observer.Expect('ext validate calc rr w src', 'hv:alpha');
        Observer.Expect('ext validate calc row ins', 'hv: hv:alpha');
        Observer.Expect('ext validate calc row w src mod', 'hv: hv:alpha');
        Observer.Expect('ext validate calc src t set', 'hv:gammagamma');
        Observer.Expect('ext validate calc row t set mod', 'hv: hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure Value_SameKind_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SameKind(Observer, 'plain', 4);
        Observer.Expect('plain same rr w src', 'hv:alpha');
        Observer.Expect('plain same row', 'hv: hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure Value_SameKind_Comp()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SameKind(Observer, 'comp', 5);
        Observer.Expect('comp same rr w src', 'hv:alpha');
        Observer.Expect('comp same row', 'hv: hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure Value_SameKind_Ext()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SameKind(Observer, 'ext', 97761);
        Observer.Expect('ext same rr w src', 'hv:alpha');
        Observer.Expect('ext same row', 'hv: hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_IntoPlain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        VariantInto(Observer, 'plain', 4);
        Observer.Expect('plain var dst', 'hv:alpha');
        Observer.Expect('plain var dst w src', 'hv:alpha');
        Observer.Expect('plain var src w dst', 'hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_IntoComp()
    var
        Observer: Codeunit "Probe Observer";
    begin
        VariantInto(Observer, 'comp', 5);
        Observer.Expect('comp var dst', 'hv:alpha');
        Observer.Expect('comp var dst w src', 'hv:alpha');
        Observer.Expect('comp var src w dst', 'hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_IntoExt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        VariantInto(Observer, 'ext', 97761);
        Observer.Expect('ext var dst', 'hv:alpha');
        Observer.Expect('ext var dst w src', 'hv:alpha');
        Observer.Expect('ext var src w dst', 'hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure Assign_IntoPlain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AssignInto(Observer, 'plain', 4);
        Observer.Expect('plain asg dst', 'hv:alpha');
        Observer.Expect('plain asg dst w src', 'hv:alpha');
        Observer.Expect('plain asg src w dst', 'hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure Assign_IntoComp()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AssignInto(Observer, 'comp', 5);
        Observer.Expect('comp asg dst', 'hv:alpha');
        Observer.Expect('comp asg dst w src', 'hv:alpha');
        Observer.Expect('comp asg src w dst', 'hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure Assign_IntoExt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AssignInto(Observer, 'ext', 97761);
        Observer.Expect('ext asg dst', 'hv:alpha');
        Observer.Expect('ext asg dst w src', 'hv:alpha');
        Observer.Expect('ext asg src w dst', 'hv:betaa');
        Observer.Verify();
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
        Observer.Expect('bv mem src', 'hv:alpha');
        Observer.Expect('bv mem in entry', 'hv:alpha');
        Observer.Expect('bv mem in w', 'hv:zzpha');
        Observer.Expect('bv mem src after call', 'hv:alpha');
        Observer.Expect('bv mem row', 'hv: hv:alpha');
        Observer.Expect('bv mem src after persist', 'hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ByValue(Observer, 2, false);
        Observer.Expect('bv ins src', 'hv:alpha');
        Observer.Expect('bv ins in entry', 'hv:alpha');
        Observer.Expect('bv ins in w', 'hv:zzpha');
        Observer.Expect('bv ins src after call', 'hv:alpha');
        Observer.Expect('bv ins row', 'hv: hv:alpha');
        Observer.Expect('bv ins src after persist', 'hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ByValue(Observer, 3, false);
        Observer.Expect('bv calc src', 'hv:alpha');
        Observer.Expect('bv calc in entry', 'hv:alpha');
        Observer.Expect('bv calc in w', 'hv:zzpha');
        Observer.Expect('bv calc src after call', 'hv:alpha');
        Observer.Expect('bv calc row', 'hv: hv:alpha');
        Observer.Expect('bv calc src after persist', 'hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ByValue(Observer, 4, false);
        Observer.Expect('bv get src', 'hv:');
        Observer.Expect('bv get in entry', 'hv:');
        Observer.Expect('bv get in w', 'hv:zz');
        Observer.Expect('bv get src after call', 'hv:');
        Observer.Expect('bv get row', 'hv: hv:alpha');
        Observer.Expect('bv get src after persist', 'hv:');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ByValue(Observer, 5, false);
        Observer.Expect('bv empty src', 'nohv:');
        Observer.Expect('bv empty in entry', 'nohv:');
        Observer.Expect('bv empty in w', 'hv:zz');
        Observer.Expect('bv empty src after call', 'nohv:');
        Observer.Expect('bv empty row', 'nohv: nohv:');
        Observer.Expect('bv empty src after persist', 'nohv:');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_Asg()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ByValue(Observer, 6, false);
        Observer.Expect('bv asg src', 'hv:alpha');
        Observer.Expect('bv asg in entry', 'hv:alpha');
        Observer.Expect('bv asg in w', 'hv:zzpha');
        Observer.Expect('bv asg src after call', 'hv:alpha');
        Observer.Expect('bv asg row', 'hv: hv:alpha');
        Observer.Expect('bv asg src after persist', 'hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_CalleeCalcFields_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ByValue(Observer, 4, true);
        Observer.Expect('bvc get src', 'hv:');
        Observer.Expect('bvc get in entry', 'hv:alpha');
        Observer.Expect('bvc get in w', 'hv:zzpha');
        Observer.Expect('bvc get src after call', 'hv:');
        Observer.Expect('bvc get row', 'hv: hv:alpha');
        Observer.Expect('bvc get src after persist', 'hv:');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_CalleeCalcFields_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ByValue(Observer, 2, true);
        Observer.Expect('bvc ins src', 'hv:alpha');
        Observer.Expect('bvc ins in entry', 'hv:alpha');
        Observer.Expect('bvc ins in w', 'hv:zzpha');
        Observer.Expect('bvc ins src after call', 'hv:alpha');
        Observer.Expect('bvc ins row', 'hv: hv:alpha');
        Observer.Expect('bvc ins src after persist', 'hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CopyMove(Observer, 1);
        Observer.Expect('copy mem dst', 'hv:alpha');
        Observer.Expect('copy mem dst w src', 'hv:alpha');
        Observer.Expect('copy mem src w dst', 'hv:betaa');
        Observer.Expect('copy mem dst w dst', 'hv:zzpha');
        Observer.Expect('copy mem row', 'hv: hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CopyMove(Observer, 2);
        Observer.Expect('copy ins dst', 'hv:alpha');
        Observer.Expect('copy ins dst w src', 'hv:alpha');
        Observer.Expect('copy ins src w dst', 'hv:betaa');
        Observer.Expect('copy ins dst w dst', 'hv:zzpha');
        Observer.Expect('copy ins row', 'hv: hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CopyMove(Observer, 3);
        Observer.Expect('copy calc dst', 'hv:alpha');
        Observer.Expect('copy calc dst w src', 'hv:alpha');
        Observer.Expect('copy calc src w dst', 'hv:betaa');
        Observer.Expect('copy calc dst w dst', 'hv:zzpha');
        Observer.Expect('copy calc row', 'hv: hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CopyMove(Observer, 4);
        Observer.Expect('copy get dst', 'hv:');
        Observer.Expect('copy get dst w src', 'hv:');
        Observer.Expect('copy get src w dst', 'hv:beta');
        Observer.Expect('copy get dst w dst', 'hv:zz');
        Observer.Expect('copy get row', 'hv: hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CopyMove(Observer, 5);
        Observer.Expect('copy empty dst', 'nohv:');
        Observer.Expect('copy empty dst w src', 'nohv:');
        Observer.Expect('copy empty src w dst', 'hv:beta');
        Observer.Expect('copy empty dst w dst', 'hv:zz');
        Observer.Expect('copy empty row', 'hv: hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_Asg()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CopyMove(Observer, 6);
        Observer.Expect('copy asg dst', 'hv:alpha');
        Observer.Expect('copy asg dst w src', 'hv:alpha');
        Observer.Expect('copy asg src w dst', 'hv:betaa');
        Observer.Expect('copy asg dst w dst', 'hv:zzpha');
        Observer.Expect('copy asg row', 'hv: hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure TransferFields_InitPK_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TransferMove(Observer, 1, true);
        Observer.Expect('tf Yes mem dst key', '12');
        Observer.Expect('tf Yes mem dst', 'hv:alpha');
        Observer.Expect('tf Yes mem dst w src', 'hv:alpha');
        Observer.Expect('tf Yes mem src w dst', 'hv:betaa');
        Observer.Expect('tf Yes mem row src', 'hv: hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure TransferFields_InitPK_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TransferMove(Observer, 2, true);
        Observer.Expect('tf Yes ins dst key', '12');
        Observer.Expect('tf Yes ins dst', 'hv:alpha');
        Observer.Expect('tf Yes ins dst w src', 'hv:alpha');
        Observer.Expect('tf Yes ins src w dst', 'hv:betaa');
        Observer.Expect('tf Yes ins row src', 'hv: hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure TransferFields_InitPK_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TransferMove(Observer, 3, true);
        Observer.Expect('tf Yes calc dst key', '12');
        Observer.Expect('tf Yes calc dst', 'hv:alpha');
        Observer.Expect('tf Yes calc dst w src', 'hv:alpha');
        Observer.Expect('tf Yes calc src w dst', 'hv:betaa');
        Observer.Expect('tf Yes calc row src', 'hv: hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure TransferFields_InitPK_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TransferMove(Observer, 4, true);
        Observer.Expect('tf Yes get dst key', '12');
        Observer.Expect('tf Yes get dst', 'nohv:');
        Observer.Expect('tf Yes get dst w src', 'nohv:');
        Observer.Expect('tf Yes get src w dst', 'hv:beta');
        Observer.Expect('tf Yes get row src', 'hv: hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure TransferFields_InitPK_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TransferMove(Observer, 5, true);
        Observer.Expect('tf Yes empty dst key', '12');
        Observer.Expect('tf Yes empty dst', 'nohv:');
        Observer.Expect('tf Yes empty dst w src', 'nohv:');
        Observer.Expect('tf Yes empty src w dst', 'hv:beta');
        Observer.Expect('tf Yes empty row src', 'hv: hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure TransferFields_InitPK_Asg()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TransferMove(Observer, 6, true);
        Observer.Expect('tf Yes asg dst key', '12');
        Observer.Expect('tf Yes asg dst', 'hv:alpha');
        Observer.Expect('tf Yes asg dst w src', 'hv:alpha');
        Observer.Expect('tf Yes asg src w dst', 'hv:betaa');
        Observer.Expect('tf Yes asg row src', 'hv: hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure TransferFields_KeepPK_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TransferMove(Observer, 1, false);
        Observer.Expect('tf No mem dst key', '62');
        Observer.Expect('tf No mem dst', 'hv:alpha');
        Observer.Expect('tf No mem dst w src', 'hv:alpha');
        Observer.Expect('tf No mem src w dst', 'hv:betaa');
        Observer.Expect('tf No mem row src', 'hv: hv:betaa');
        Observer.Expect('tf No mem row dst', 'hv: hv:zzpha');
        Observer.Verify();
    end;

    [Test]
    procedure TransferFields_KeepPK_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TransferMove(Observer, 2, false);
        Observer.Expect('tf No ins dst key', '62');
        Observer.Expect('tf No ins dst', 'hv:alpha');
        Observer.Expect('tf No ins dst w src', 'hv:alpha');
        Observer.Expect('tf No ins src w dst', 'hv:betaa');
        Observer.Expect('tf No ins row src', 'hv: hv:betaa');
        Observer.Expect('tf No ins row dst', 'hv: hv:zzpha');
        Observer.Verify();
    end;

    [Test]
    procedure TransferFields_KeepPK_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TransferMove(Observer, 3, false);
        Observer.Expect('tf No calc dst key', '62');
        Observer.Expect('tf No calc dst', 'hv:alpha');
        Observer.Expect('tf No calc dst w src', 'hv:alpha');
        Observer.Expect('tf No calc src w dst', 'hv:betaa');
        Observer.Expect('tf No calc row src', 'hv: hv:betaa');
        Observer.Expect('tf No calc row dst', 'hv: hv:zzpha');
        Observer.Verify();
    end;

    [Test]
    procedure TransferFields_KeepPK_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TransferMove(Observer, 4, false);
        Observer.Expect('tf No get dst key', '62');
        Observer.Expect('tf No get dst', 'nohv:');
        Observer.Expect('tf No get dst w src', 'nohv:');
        Observer.Expect('tf No get src w dst', 'hv:beta');
        Observer.Expect('tf No get row src', 'hv: hv:beta');
        Observer.Expect('tf No get row dst', 'hv: hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure TransferFields_KeepPK_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TransferMove(Observer, 5, false);
        Observer.Expect('tf No empty dst key', '62');
        Observer.Expect('tf No empty dst', 'nohv:');
        Observer.Expect('tf No empty dst w src', 'nohv:');
        Observer.Expect('tf No empty src w dst', 'hv:beta');
        Observer.Expect('tf No empty row src', 'hv: hv:beta');
        Observer.Expect('tf No empty row dst', 'hv: hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure TransferFields_KeepPK_Asg()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TransferMove(Observer, 6, false);
        Observer.Expect('tf No asg dst key', '62');
        Observer.Expect('tf No asg dst', 'hv:alpha');
        Observer.Expect('tf No asg dst w src', 'hv:alpha');
        Observer.Expect('tf No asg src w dst', 'hv:betaa');
        Observer.Expect('tf No asg row src', 'hv: hv:betaa');
        Observer.Expect('tf No asg row dst', 'hv: hv:zzpha');
        Observer.Verify();
    end;

    [Test]
    procedure GlobalVariant_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GlobalVariantMove(Observer, 1);
        Observer.Expect('gv mem dst w src', 'hv:alpha');
        Observer.Expect('gv mem src w dst', 'hv:betaa');
        Observer.Expect('gv mem dst2 w dst', 'hv:alpha');
        Observer.Expect('gv mem row', 'hv: hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure GlobalVariant_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GlobalVariantMove(Observer, 2);
        Observer.Expect('gv ins dst w src', 'hv:alpha');
        Observer.Expect('gv ins src w dst', 'hv:betaa');
        Observer.Expect('gv ins dst2 w dst', 'hv:alpha');
        Observer.Expect('gv ins row', 'hv: hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure GlobalVariant_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GlobalVariantMove(Observer, 3);
        Observer.Expect('gv calc dst w src', 'hv:alpha');
        Observer.Expect('gv calc src w dst', 'hv:betaa');
        Observer.Expect('gv calc dst2 w dst', 'hv:alpha');
        Observer.Expect('gv calc row', 'hv: hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure GlobalVariant_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GlobalVariantMove(Observer, 4);
        Observer.Expect('gv get dst w src', 'hv:');
        Observer.Expect('gv get src w dst', 'hv:beta');
        Observer.Expect('gv get dst2 w dst', 'hv:');
        Observer.Expect('gv get row', 'hv: hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure GlobalVariant_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GlobalVariantMove(Observer, 5);
        Observer.Expect('gv empty dst w src', 'nohv:');
        Observer.Expect('gv empty src w dst', 'hv:beta');
        Observer.Expect('gv empty dst2 w dst', 'nohv:');
        Observer.Expect('gv empty row', 'hv: hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure GlobalVariant_Asg()
    var
        Observer: Codeunit "Probe Observer";
    begin
        GlobalVariantMove(Observer, 6);
        Observer.Expect('gv asg dst w src', 'hv:alpha');
        Observer.Expect('gv asg src w dst', 'hv:betaa');
        Observer.Expect('gv asg dst2 w dst', 'hv:alpha');
        Observer.Expect('gv asg row', 'hv: hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure VariantArray_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArrayVariantMove(Observer, 1);
        Observer.Expect('va mem dst w src', 'hv:alpha');
        Observer.Expect('va mem src w dst', 'hv:betaa');
        Observer.Expect('va mem dst2 w dst', 'hv:alpha');
        Observer.Expect('va mem row', 'hv: hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure VariantArray_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArrayVariantMove(Observer, 2);
        Observer.Expect('va ins dst w src', 'hv:alpha');
        Observer.Expect('va ins src w dst', 'hv:betaa');
        Observer.Expect('va ins dst2 w dst', 'hv:alpha');
        Observer.Expect('va ins row', 'hv: hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure VariantArray_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArrayVariantMove(Observer, 3);
        Observer.Expect('va calc dst w src', 'hv:alpha');
        Observer.Expect('va calc src w dst', 'hv:betaa');
        Observer.Expect('va calc dst2 w dst', 'hv:alpha');
        Observer.Expect('va calc row', 'hv: hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure VariantArray_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArrayVariantMove(Observer, 4);
        Observer.Expect('va get dst w src', 'hv:');
        Observer.Expect('va get src w dst', 'hv:beta');
        Observer.Expect('va get dst2 w dst', 'hv:');
        Observer.Expect('va get row', 'hv: hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure VariantArray_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArrayVariantMove(Observer, 5);
        Observer.Expect('va empty dst w src', 'nohv:');
        Observer.Expect('va empty src w dst', 'hv:beta');
        Observer.Expect('va empty dst2 w dst', 'nohv:');
        Observer.Expect('va empty row', 'hv: hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure VariantArray_Asg()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ArrayVariantMove(Observer, 6);
        Observer.Expect('va asg dst w src', 'hv:alpha');
        Observer.Expect('va asg src w dst', 'hv:betaa');
        Observer.Expect('va asg dst2 w dst', 'hv:alpha');
        Observer.Expect('va asg row', 'hv: hv:betaa');
        Observer.Verify();
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

    // SetTable(Rec, true) with records that are not temporary raises (observed in the first run of this probe).
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
        asserterror RR.SetTable(Dst, true);
        Observer.ObserveError(P + 'settable');
        Observer.Observe(P + 'dst', L.Rd(Dst));
        Observer.Observe(P + 'rr', L.RdRR(RR, 2));
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
        Observer.Expect('sht mem dst', 'hv:alpha');
        Observer.Expect('sht mem src w dst', 'hv:betaa');
        Observer.Expect('sht mem rr w dst', 'hv:alpha');
        Observer.Expect('sht mem dst w src', 'hv:zzpha');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableShare_Temp_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShareMoveTemp(Observer, 2);
        Observer.Expect('sht ins dst', 'hv:alpha');
        Observer.Expect('sht ins src w dst', 'hv:betaa');
        Observer.Expect('sht ins rr w dst', 'hv:alpha');
        Observer.Expect('sht ins dst w src', 'hv:zzpha');
        Observer.Expect('sht ins dst get', 'hv:');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableShare_Temp_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShareMoveTemp(Observer, 3);
        Observer.Expect('sht calc dst', 'hv:alpha');
        Observer.Expect('sht calc src w dst', 'hv:betaa');
        Observer.Expect('sht calc rr w dst', 'hv:alpha');
        Observer.Expect('sht calc dst w src', 'hv:zzpha');
        Observer.Expect('sht calc dst get', 'hv:');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableShare_Temp_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShareMoveTemp(Observer, 4);
        Observer.Expect('sht get dst', 'hv:');
        Observer.Expect('sht get src w dst', 'hv:beta');
        Observer.Expect('sht get rr w dst', 'hv:');
        Observer.Expect('sht get dst w src', 'hv:zz');
        Observer.Expect('sht get dst get', 'hv:');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableShare_Temp_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShareMoveTemp(Observer, 5);
        Observer.Expect('sht empty dst', 'nohv:');
        Observer.Expect('sht empty src w dst', 'hv:beta');
        Observer.Expect('sht empty rr w dst', 'nohv:');
        Observer.Expect('sht empty dst w src', 'hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableShare_Temp_Asg()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShareMoveTemp(Observer, 6);
        Observer.Expect('sht asg dst', 'hv:alpha');
        Observer.Expect('sht asg src w dst', 'hv:betaa');
        Observer.Expect('sht asg rr w dst', 'hv:alpha');
        Observer.Expect('sht asg dst w src', 'hv:zzpha');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableShare_Stored_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShareMoveStored(Observer, 1);
        Observer.Expect('shs mem settable|text', 'The COPY function can only be used with the shareTable argument set to true if both records are temporary.');
        Observer.Expect('shs mem settable|code', 'Argument');
        Observer.Expect('shs mem dst', 'nohv:');
        Observer.Expect('shs mem rr', 'hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableShare_Stored_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShareMoveStored(Observer, 2);
        Observer.Expect('shs ins settable|text', 'The COPY function can only be used with the shareTable argument set to true if both records are temporary.');
        Observer.Expect('shs ins settable|code', 'Argument');
        Observer.Expect('shs ins dst', 'nohv:');
        Observer.Expect('shs ins rr', 'hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableShare_Stored_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShareMoveStored(Observer, 3);
        Observer.Expect('shs calc settable|text', 'The COPY function can only be used with the shareTable argument set to true if both records are temporary.');
        Observer.Expect('shs calc settable|code', 'Argument');
        Observer.Expect('shs calc dst', 'nohv:');
        Observer.Expect('shs calc rr', 'hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableShare_Stored_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShareMoveStored(Observer, 4);
        Observer.Expect('shs get settable|text', 'The COPY function can only be used with the shareTable argument set to true if both records are temporary.');
        Observer.Expect('shs get settable|code', 'Argument');
        Observer.Expect('shs get dst', 'nohv:');
        Observer.Expect('shs get rr', 'hv:');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableShare_Stored_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShareMoveStored(Observer, 5);
        Observer.Expect('shs empty settable|text', 'The COPY function can only be used with the shareTable argument set to true if both records are temporary.');
        Observer.Expect('shs empty settable|code', 'Argument');
        Observer.Expect('shs empty dst', 'nohv:');
        Observer.Expect('shs empty rr', 'nohv:');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableShare_Stored_Asg()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShareMoveStored(Observer, 6);
        Observer.Expect('shs asg settable|text', 'The COPY function can only be used with the shareTable argument set to true if both records are temporary.');
        Observer.Expect('shs asg settable|code', 'Argument');
        Observer.Expect('shs asg dst', 'nohv:');
        Observer.Expect('shs asg rr', 'hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure TempToNonTempParam_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TempToNonTempParam(Observer, 1);
        Observer.Expect('tmppar mem in temp', 'No');
        Observer.Expect('tmppar mem in entry', 'hv:alpha');
        Observer.Expect('tmppar mem in w', 'hv:zzpha');
        Observer.Expect('tmppar mem src', 'hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure TempToNonTempParam_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TempToNonTempParam(Observer, 2);
        Observer.Expect('tmppar ins in temp', 'No');
        Observer.Expect('tmppar ins in entry', 'hv:alpha');
        Observer.Expect('tmppar ins in w', 'hv:zzpha');
        Observer.Expect('tmppar ins src', 'hv:alpha');
        Observer.Expect('tmppar ins src get', 'hv:');
        Observer.Verify();
    end;

    [Test]
    procedure TempToNonTempParam_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TempToNonTempParam(Observer, 4);
        Observer.Expect('tmppar get in temp', 'No');
        Observer.Expect('tmppar get in entry', 'hv:');
        Observer.Expect('tmppar get in w', 'hv:zz');
        Observer.Expect('tmppar get src', 'hv:');
        Observer.Expect('tmppar get src get', 'hv:');
        Observer.Verify();
    end;

    [Test]
    procedure NonTempToTempParam_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NonTempToTempParam(Observer, 1);
        Observer.Expect('rectmp mem in temp', 'Yes');
        Observer.Expect('rectmp mem in entry', 'hv:alpha');
        Observer.Expect('rectmp mem in w', 'hv:zzpha');
        Observer.Expect('rectmp mem src', 'hv:alpha');
        Observer.Expect('rectmp mem row', 'hv: hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure NonTempToTempParam_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NonTempToTempParam(Observer, 2);
        Observer.Expect('rectmp ins in temp', 'Yes');
        Observer.Expect('rectmp ins in entry', 'hv:alpha');
        Observer.Expect('rectmp ins in w', 'hv:zzpha');
        Observer.Expect('rectmp ins src', 'hv:alpha');
        Observer.Expect('rectmp ins row', 'hv: hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure NonTempToTempParam_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NonTempToTempParam(Observer, 4);
        Observer.Expect('rectmp get in temp', 'Yes');
        Observer.Expect('rectmp get in entry', 'hv:');
        Observer.Expect('rectmp get in w', 'hv:zz');
        Observer.Expect('rectmp get src', 'hv:');
        Observer.Expect('rectmp get row', 'hv: hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure CopyStoredToTemp_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CopyStoredToTemp(Observer, 1);
        Observer.Expect('copy2tmp mem copy', 'ok');
        Observer.Expect('copy2tmp mem dst temp', 'Yes');
        Observer.Expect('copy2tmp mem dst', 'hv:alpha');
        Observer.Expect('copy2tmp mem dst w src', 'hv:alpha');
        Observer.Expect('copy2tmp mem src w dst', 'hv:betaa');
        Observer.Expect('copy2tmp mem row', 'hv: hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure CopyStoredToTemp_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CopyStoredToTemp(Observer, 2);
        Observer.Expect('copy2tmp ins copy', 'ok');
        Observer.Expect('copy2tmp ins dst temp', 'Yes');
        Observer.Expect('copy2tmp ins dst', 'hv:alpha');
        Observer.Expect('copy2tmp ins dst w src', 'hv:alpha');
        Observer.Expect('copy2tmp ins src w dst', 'hv:betaa');
        Observer.Expect('copy2tmp ins row', 'hv: hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure CopyStoredToTemp_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CopyStoredToTemp(Observer, 4);
        Observer.Expect('copy2tmp get copy', 'ok');
        Observer.Expect('copy2tmp get dst temp', 'Yes');
        Observer.Expect('copy2tmp get dst', 'hv:');
        Observer.Expect('copy2tmp get dst w src', 'hv:');
        Observer.Expect('copy2tmp get src w dst', 'hv:beta');
        Observer.Expect('copy2tmp get row', 'hv: hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure CopyTempToStored_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CopyTempToStored(Observer, 1);
        Observer.Expect('copy2rec mem copy', 'ok');
        Observer.Expect('copy2rec mem dst temp', 'No');
        Observer.Expect('copy2rec mem dst', 'hv:alpha');
        Observer.Expect('copy2rec mem dst w src', 'hv:alpha');
        Observer.Expect('copy2rec mem src w dst', 'hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure CopyTempToStored_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CopyTempToStored(Observer, 2);
        Observer.Expect('copy2rec ins copy', 'ok');
        Observer.Expect('copy2rec ins dst temp', 'No');
        Observer.Expect('copy2rec ins dst', 'hv:alpha');
        Observer.Expect('copy2rec ins dst w src', 'hv:alpha');
        Observer.Expect('copy2rec ins src w dst', 'hv:betaa');
        Observer.Verify();
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
        Observer.Expect('try mem ok', 'Yes');
        Observer.Expect('try mem in entry', 'hv:alpha');
        Observer.Expect('try mem in w', 'hv:zzpha');
        Observer.Expect('try mem src', 'hv:alpha');
        Observer.Expect('try mem row', 'hv: hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure TryFunction_ByValue_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryCall(Observer, 2, false);
        Observer.Expect('try ins ok', 'Yes');
        Observer.Expect('try ins in entry', 'hv:alpha');
        Observer.Expect('try ins in w', 'hv:zzpha');
        Observer.Expect('try ins src', 'hv:alpha');
        Observer.Expect('try ins row', 'hv: hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure TryFunction_ByValue_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryCall(Observer, 4, false);
        Observer.Expect('try get ok', 'Yes');
        Observer.Expect('try get in entry', 'hv:');
        Observer.Expect('try get in w', 'hv:zz');
        Observer.Expect('try get src', 'hv:');
        Observer.Expect('try get row', 'hv: hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure TryFunction_ByVar_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryCall(Observer, 1, true);
        Observer.Expect('tryvar mem ok', 'Yes');
        Observer.Expect('tryvar mem in entry', 'hv:alpha');
        Observer.Expect('tryvar mem in w', 'hv:zzpha');
        Observer.Expect('tryvar mem src', 'hv:zzpha');
        Observer.Expect('tryvar mem row', 'hv: hv:zzpha');
        Observer.Verify();
    end;

    [Test]
    procedure OnModify_Mode1_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyTrigger(Observer, 2, 1);
        Observer.Expect('onmodify1 ins seen', 'hv:alpha');
        Observer.Expect('onmodify1 ins src', 'hv:triga');
        Observer.Expect('onmodify1 ins row', 'hv: hv:triga');
        Observer.Verify();
    end;

    [Test]
    procedure OnModify_Mode1_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyTrigger(Observer, 3, 1);
        Observer.Expect('onmodify1 calc seen', 'hv:alpha');
        Observer.Expect('onmodify1 calc src', 'hv:triga');
        Observer.Expect('onmodify1 calc row', 'hv: hv:triga');
        Observer.Verify();
    end;

    [Test]
    procedure OnModify_Mode1_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyTrigger(Observer, 4, 1);
        Observer.Expect('onmodify1 get seen', 'hv:');
        Observer.Expect('onmodify1 get src', 'hv:trig');
        Observer.Expect('onmodify1 get row', 'hv: hv:trig');
        Observer.Verify();
    end;

    [Test]
    procedure OnModify_Mode2_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyTrigger(Observer, 2, 2);
        Observer.Expect('onmodify2 ins seen', 'hv:alpha');
        Observer.Expect('onmodify2 ins src', 'hv:alpha');
        Observer.Expect('onmodify2 ins row', 'hv: hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure OnModify_Mode2_Calc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyTrigger(Observer, 3, 2);
        Observer.Expect('onmodify2 calc seen', 'hv:alpha');
        Observer.Expect('onmodify2 calc src', 'hv:alpha');
        Observer.Expect('onmodify2 calc row', 'hv: hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure OnModify_Mode2_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyTrigger(Observer, 4, 2);
        Observer.Expect('onmodify2 get seen', 'hv:');
        Observer.Expect('onmodify2 get src', 'hv:');
        Observer.Expect('onmodify2 get row', 'hv: hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure OnInsert_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        InsertTrigger(Observer, 1);
        Observer.Expect('oninsert mem src', 'hv:insha');
        Observer.Expect('oninsert mem row', 'hv: hv:insha');
        Observer.Verify();
    end;

    [Test]
    procedure OnInsert_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        InsertTrigger(Observer, 5);
        Observer.Expect('oninsert empty src', 'hv:ins');
        Observer.Expect('oninsert empty row', 'hv: hv:ins');
        Observer.Verify();
    end;

    [Test]
    procedure OnValidate_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ValidateTrigger(Observer, 1);
        Observer.Expect('onvalidate mem src', 'hv:valha');
        Observer.Expect('onvalidate mem row', 'hv: hv:valha');
        Observer.Verify();
    end;

    [Test]
    procedure OnValidate_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ValidateTrigger(Observer, 2);
        Observer.Expect('onvalidate ins src', 'hv:valha');
        Observer.Expect('onvalidate ins row', 'hv: hv:valha');
        Observer.Verify();
    end;

    [Test]
    procedure OnValidate_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ValidateTrigger(Observer, 4);
        Observer.Expect('onvalidate get src', 'hv:val');
        Observer.Expect('onvalidate get row', 'hv: hv:val');
        Observer.Verify();
    end;

    [Test]
    procedure CodeunitRun_TableNo_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTableNo(Observer, 1);
        Observer.Expect('run mem seen', 'hv:alpha');
        Observer.Expect('run mem src', 'hv:runha');
        Observer.Expect('run mem row', 'hv: hv:runha');
        Observer.Verify();
    end;

    [Test]
    procedure CodeunitRun_TableNo_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTableNo(Observer, 2);
        Observer.Expect('run ins seen', 'hv:alpha');
        Observer.Expect('run ins src', 'hv:runha');
        Observer.Expect('run ins row', 'hv: hv:runha');
        Observer.Verify();
    end;

    [Test]
    procedure CodeunitRun_TableNo_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTableNo(Observer, 4);
        Observer.Expect('run get seen', 'hv:');
        Observer.Expect('run get src', 'hv:run');
        Observer.Expect('run get row', 'hv: hv:run');
        Observer.Verify();
    end;

    [Test]
    procedure CodeunitRun_TableNo_Temp_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTableNoTemp(Observer, 1);
        Observer.Expect('runtmp mem seen', 'hv:alpha');
        Observer.Expect('runtmp mem src', 'hv:runha');
        Observer.Verify();
    end;

    [Test]
    procedure CodeunitRun_TableNo_Temp_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTableNoTemp(Observer, 2);
        Observer.Expect('runtmp ins seen', 'hv:alpha');
        Observer.Expect('runtmp ins src', 'hv:runha');
        Observer.Verify();
    end;

    [Test]
    procedure Event_ByValue_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RaiseEvent(Observer, 1, 1);
        Observer.Expect('event1 mem in entry', 'hv:alpha');
        Observer.Expect('event1 mem in w', 'hv:zzpha');
        Observer.Expect('event1 mem src', 'hv:alpha');
        Observer.Expect('event1 mem row', 'hv: hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure Event_ByValue_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RaiseEvent(Observer, 2, 1);
        Observer.Expect('event1 ins in entry', 'hv:alpha');
        Observer.Expect('event1 ins in w', 'hv:zzpha');
        Observer.Expect('event1 ins src', 'hv:alpha');
        Observer.Expect('event1 ins row', 'hv: hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure Event_ByValue_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RaiseEvent(Observer, 4, 1);
        Observer.Expect('event1 get in entry', 'hv:');
        Observer.Expect('event1 get in w', 'hv:zz');
        Observer.Expect('event1 get src', 'hv:');
        Observer.Expect('event1 get row', 'hv: hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure Event_ByVar_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RaiseEvent(Observer, 1, 2);
        Observer.Expect('event2 mem in entry', 'hv:alpha');
        Observer.Expect('event2 mem in w', 'hv:zzpha');
        Observer.Expect('event2 mem src', 'hv:zzpha');
        Observer.Expect('event2 mem row', 'hv: hv:zzpha');
        Observer.Verify();
    end;

    [Test]
    procedure Event_ByVar_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RaiseEvent(Observer, 2, 2);
        Observer.Expect('event2 ins in entry', 'hv:alpha');
        Observer.Expect('event2 ins in w', 'hv:zzpha');
        Observer.Expect('event2 ins src', 'hv:zzpha');
        Observer.Expect('event2 ins row', 'hv: hv:zzpha');
        Observer.Verify();
    end;

    [Test]
    procedure Event_ByVar_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RaiseEvent(Observer, 4, 2);
        Observer.Expect('event2 get in entry', 'hv:');
        Observer.Expect('event2 get in w', 'hv:zz');
        Observer.Expect('event2 get src', 'hv:zz');
        Observer.Expect('event2 get row', 'hv: hv:zz');
        Observer.Verify();
    end;

    [Test]
    procedure Event_VarPublisherValueSubscriber_Mem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RaiseEvent(Observer, 1, 3);
        Observer.Expect('event3 mem in entry', 'hv:alpha');
        Observer.Expect('event3 mem in w', 'hv:zzpha');
        Observer.Expect('event3 mem src', 'hv:alpha');
        Observer.Expect('event3 mem row', 'hv: hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure Event_VarPublisherValueSubscriber_Ins()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RaiseEvent(Observer, 2, 3);
        Observer.Expect('event3 ins in entry', 'hv:alpha');
        Observer.Expect('event3 ins in w', 'hv:zzpha');
        Observer.Expect('event3 ins src', 'hv:alpha');
        Observer.Expect('event3 ins row', 'hv: hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure Event_VarPublisherValueSubscriber_Get()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RaiseEvent(Observer, 4, 3);
        Observer.Expect('event3 get in entry', 'hv:');
        Observer.Expect('event3 get in w', 'hv:zz');
        Observer.Expect('event3 get src', 'hv:');
        Observer.Expect('event3 get row', 'hv: hv:alpha');
        Observer.Verify();
    end;

}

// ---- Neighbors: a Blob written again after Insert or Modify, a Blob filled by := or FieldRef.Value, other field kinds in a Variant,
// ---- and more call forms (another codeunit, an interface, a table procedure, a var parameter passed on, a global record) ----
codeunit 97768 "LT BC3 Neighbors"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT BC3 Lib";
        GV: Variant;
        GRec: Record "LT BC3 Row";

    local procedure ByValue(R: Record "LT BC3 Row"; var AfterWrite: Text)
    begin
        L.W(R, 'zz');
        AfterWrite := L.Rd(R);
    end;

    local procedure ByValueTemp(R: Record "LT BC3 Row" temporary; var AfterWrite: Text)
    begin
        L.W(R, 'zz');
        AfterWrite := L.Rd(R);
    end;

    local procedure PassOn(var R: Record "LT BC3 Row"; var AfterWrite: Text)
    begin
        ByValue(R, AfterWrite);
    end;

    local procedure TakeVar(V: Variant; var Dst: Record "LT BC3 Row")
    begin
        Dst.Data := V;
    end;

    // Writes 'beta' into field F of Src, then assigns the Variant parameter to Dst.Data.
    local procedure TakeVarWrite(V: Variant; var Src: Record "LT BC3 Row"; var Dst: Record "LT BC3 Row"; F: Integer)
    begin
        L.WF(Src, F, 'beta');
        Dst.Data := V;
    end;

    [Test]
    procedure InsertWriteAgain_ByValue()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BC3 Row";
        B: Text;
    begin
        // A1
        L.Reset();
        Src.Key1 := 40;
        L.W(Src, 'alpha');
        Src.Insert();
        L.W(Src, 'beta');
        ByValue(Src, B);
        Observer.Observe('A1 in w', B);
        Observer.Observe('A1 src', L.Rd(Src));
        Src.Modify();
        Observer.Observe('A1 row', L.Stored(40));
        Observer.Expect('A1 in w', 'hv:zztaa');
        Observer.Expect('A1 src', 'hv:betaa');
        Observer.Expect('A1 row', 'hv: hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure TempInsertWriteAgain_ByValue()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BC3 Row" temporary;
        B: Text;
    begin
        // A2
        Src.Key1 := 41;
        L.W(Src, 'alpha');
        Src.Insert();
        L.W(Src, 'beta');
        ByValueTemp(Src, B);
        Observer.Observe('A2 in w', B);
        Observer.Observe('A2 src', L.Rd(Src));
        Src.Get(41);
        Observer.Observe('A2 src get', L.Rd(Src));
        Observer.Expect('A2 in w', 'hv:zztaa');
        Observer.Expect('A2 src', 'hv:betaa');
        Observer.Expect('A2 src get', 'hv:');
        Observer.Verify();
    end;

    [Test]
    procedure InsertWriteAgain_Copy_Modify()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BC3 Row";
        Dst: Record "LT BC3 Row";
    begin
        // A3
        L.Reset();
        Src.Key1 := 42;
        L.W(Src, 'alpha');
        Src.Insert();
        L.W(Src, 'beta');
        Dst.Copy(Src);
        Observer.Observe('A3 dst', L.Rd(Dst));
        L.W(Dst, 'zz');
        Observer.Observe('A3 src w dst', L.Rd(Src));
        Src.Modify();
        Observer.Observe('A3 row', L.Stored(42));
        Observer.Expect('A3 dst', 'hv:betaa');
        Observer.Expect('A3 src w dst', 'hv:betaa');
        Observer.Expect('A3 row', 'hv: hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyWriteAgain_ByValue()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BC3 Row";
        B: Text;
    begin
        // A4
        L.Reset();
        Src.Key1 := 43;
        Src.Insert();
        L.W(Src, 'alpha');
        Src.Modify();
        L.W(Src, 'beta');
        ByValue(Src, B);
        Observer.Observe('A4 in w', B);
        Observer.Observe('A4 src', L.Rd(Src));
        Src.Modify();
        Observer.Observe('A4 row', L.Stored(43));
        Observer.Expect('A4 in w', 'hv:zztaa');
        Observer.Expect('A4 src', 'hv:betaa');
        Observer.Expect('A4 row', 'hv: hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure TempInsertWriteAgain_GlobalVariant_TransferFieldsTrue()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BC3 Row" temporary;
        Dst: Record "LT BC3 Row" temporary;
        Dst2: Record "LT BC3 Row" temporary;
    begin
        // A5
        Src.Key1 := 44;
        L.W(Src, 'alpha');
        Src.Insert();
        L.W(Src, 'beta');
        GV := Src.Data;
        Dst2.TransferFields(Src, true);
        L.W(Src, 'zz');
        Dst.Data := GV;
        Observer.Observe('A5 gv', L.Rd(Dst));
        Observer.Observe('A5 tf', L.Rd(Dst2));
        L.W(Dst2, 'yyyyyy');
        Observer.Observe('A5 src w tf', L.Rd(Src));
        Observer.Expect('A5 gv', 'hv:betaa');
        Observer.Expect('A5 tf', 'hv:betaa');
        Observer.Expect('A5 src w tf', 'hv:zztaa');
        Observer.Verify();
    end;

    [Test]
    procedure StoredInsertWriteAgain_GlobalVariant_TransferFieldsTrue()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BC3 Row";
        Dst: Record "LT BC3 Row";
        Dst2: Record "LT BC3 Row";
    begin
        // A5 with a stored record
        L.Reset();
        Src.Key1 := 45;
        L.W(Src, 'alpha');
        Src.Insert();
        L.W(Src, 'beta');
        GV := Src.Data;
        Dst2.TransferFields(Src, true);
        L.W(Src, 'zz');
        Dst.Data := GV;
        Observer.Observe('A5s gv', L.Rd(Dst));
        Observer.Observe('A5s tf', L.Rd(Dst2));
        Src.Modify();
        Observer.Observe('A5s row', L.Stored(45));
        Observer.Expect('A5s gv', 'hv:betaa');
        Observer.Expect('A5s tf', 'hv:betaa');
        Observer.Expect('A5s row', 'hv: hv:zztaa');
        Observer.Verify();
    end;

    [Test]
    procedure FieldAssignedBlob_ByValue()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BC3 Row";
        Mid: Record "LT BC3 Row";
        B: Text;
    begin
        // B1
        L.W(Src, 'alpha');
        Mid.Data := Src.Data;
        ByValue(Mid, B);
        Observer.Observe('B1 in w', B);
        Observer.Observe('B1 mid', L.Rd(Mid));
        Observer.Observe('B1 src', L.Rd(Src));
        Observer.Expect('B1 in w', 'hv:zzpha');
        Observer.Expect('B1 mid', 'hv:alpha');
        Observer.Expect('B1 src', 'hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure RecordAssignedThenWritten_ByValue()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BC3 Row";
        Mid: Record "LT BC3 Row";
        B: Text;
    begin
        // B2
        L.W(Src, 'alpha');
        Mid := Src;
        L.W(Mid, 'beta');
        ByValue(Mid, B);
        Observer.Observe('B2 in w', B);
        Observer.Observe('B2 mid', L.Rd(Mid));
        Observer.Observe('B2 src', L.Rd(Src));
        Observer.Expect('B2 in w', 'hv:zztaa');
        Observer.Expect('B2 mid', 'hv:betaa');
        Observer.Expect('B2 src', 'hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRefValueBlob_SetTable_ByValue()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BC3 Row";
        Mid: Record "LT BC3 Row";
        RR: RecordRef;
        B: Text;
    begin
        // B3
        L.W(Src, 'alpha');
        RR.GetTable(Mid);
        RR.Field(2).Value := Src.Data;
        RR.SetTable(Mid);
        ByValue(Mid, B);
        Observer.Observe('B3 in w', B);
        Observer.Observe('B3 mid', L.Rd(Mid));
        Observer.Observe('B3 src', L.Rd(Src));
        Observer.Observe('B3 rr', L.RdRR(RR, 2));
        Observer.Expect('B3 in w', 'hv:zzpha');
        Observer.Expect('B3 mid', 'hv:alpha');
        Observer.Expect('B3 src', 'hv:alpha');
        Observer.Expect('B3 rr', 'hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure FieldAssignedBlob_Copy()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BC3 Row";
        Mid: Record "LT BC3 Row";
        Dst: Record "LT BC3 Row";
    begin
        // B1 moved by Record.Copy
        L.W(Src, 'alpha');
        Mid.Data := Src.Data;
        Dst.Copy(Mid);
        L.W(Dst, 'zz');
        Observer.Observe('B1c mid w dst', L.Rd(Mid));
        L.W(Mid, 'beta');
        Observer.Observe('B1c dst w mid', L.Rd(Dst));
        Observer.Expect('B1c mid w dst', 'hv:alpha');
        Observer.Expect('B1c dst w mid', 'hv:zzpha');
        Observer.Verify();
    end;

    [Test]
    procedure GetCalcFieldsThenWrite_ByValue()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BC3 Row";
        B: Text;
    begin
        // B4
        L.Reset();
        Src.Key1 := 46;
        L.W(Src, 'alpha');
        Src.Insert();
        Clear(Src);
        Src.Get(46);
        Src.CalcFields(Data);
        L.W(Src, 'beta');
        ByValue(Src, B);
        Observer.Observe('B4 in w', B);
        Observer.Observe('B4 src', L.Rd(Src));
        Observer.Expect('B4 in w', 'hv:zztaa');
        Observer.Expect('B4 src', 'hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure GetNoCalcFieldsThenWrite_ByValue()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BC3 Row";
        B: Text;
    begin
        // B5
        L.Reset();
        Src.Key1 := 47;
        L.W(Src, 'alpha');
        Src.Insert();
        Clear(Src);
        Src.Get(47);
        L.W(Src, 'beta');
        ByValue(Src, B);
        Observer.Observe('B5 in w', B);
        Observer.Observe('B5 src', L.Rd(Src));
        Observer.Expect('B5 in w', 'hv:zzta');
        Observer.Expect('B5 src', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure OtherKinds_ByValueVariantParam()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BC3 Row" temporary;
        Dst: Record "LT BC3 Row" temporary;
    begin
        // C1, C2, C3
        L.WF(Src, 97761, 'alpha');
        TakeVarWrite(Src.Added, Src, Dst, 97761);
        Observer.Observe('C1 ext dst', L.Rd(Dst));
        Observer.Observe('C1 ext src', L.RF(Src, 97761));
        Clear(Dst);
        L.WF(Src, 4, 'alpha');
        TakeVarWrite(Src.Plain, Src, Dst, 4);
        Observer.Observe('C2 plain dst', L.Rd(Dst));
        Observer.Observe('C2 plain src', L.RF(Src, 4));
        Clear(Dst);
        L.WF(Src, 5, 'alpha');
        TakeVarWrite(Src.Comp, Src, Dst, 5);
        Observer.Observe('C3 comp dst', L.Rd(Dst));
        Observer.Observe('C3 comp src', L.RF(Src, 5));
        Observer.Expect('C1 ext dst', 'hv:alpha');
        Observer.Expect('C1 ext src', 'hv:betaa');
        Observer.Expect('C2 plain dst', 'hv:alpha');
        Observer.Expect('C2 plain src', 'hv:betaa');
        Observer.Expect('C3 comp dst', 'hv:alpha');
        Observer.Expect('C3 comp src', 'hv:betaa');
        Observer.Verify();
    end;

    local procedure KindVariants(var Observer: Codeunit "Probe Observer"; Tag: Text; F: Integer)
    var
        Src: Record "LT BC3 Row" temporary;
        Dst: Record "LT BC3 Row" temporary;
        Dst2: Record "LT BC3 Row" temporary;
        Dst3: Record "LT BC3 Row" temporary;
        A: array[2] of Variant;
        V: Variant;
    begin
        L.WF(Src, F, 'alpha');
        case F of
            4:
                begin
                    GV := Src.Plain;
                    A[1] := Src.Plain;
                    V := Src.Plain;
                end;
            5:
                begin
                    GV := Src.Comp;
                    A[1] := Src.Comp;
                    V := Src.Comp;
                end;
            97761:
                begin
                    GV := Src.Added;
                    A[1] := Src.Added;
                    V := Src.Added;
                end;
        end;
        L.WF(Src, F, 'beta');
        Dst.Data := GV;
        Dst2.Data := A[1];
        Dst3.Data := V;
        Observer.Observe(Tag + ' gv', L.Rd(Dst));
        Observer.Observe(Tag + ' arr', L.Rd(Dst2));
        Observer.Observe(Tag + ' local', L.Rd(Dst3));
    end;

    [Test]
    procedure OtherKinds_GlobalVariant_ArrayElement_LocalVariant()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // C4, C5
        KindVariants(Observer, 'C4 ext', 97761);
        KindVariants(Observer, 'C4 plain', 4);
        KindVariants(Observer, 'C5 comp', 5);
        Observer.Expect('C4 ext gv', 'hv:alpha');
        Observer.Expect('C4 ext arr', 'hv:alpha');
        Observer.Expect('C4 ext local', 'hv:alpha');
        Observer.Expect('C4 plain gv', 'hv:alpha');
        Observer.Expect('C4 plain arr', 'hv:alpha');
        Observer.Expect('C4 plain local', 'hv:alpha');
        Observer.Expect('C5 comp gv', 'hv:alpha');
        Observer.Expect('C5 comp arr', 'hv:alpha');
        Observer.Expect('C5 comp local', 'hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure OtherKinds_RecordByValue()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BC3 Row";
    begin
        // C6
        L.WF(Src, 97761, 'alpha');
        L.WF(Src, 4, 'alpha');
        L.WF(Src, 5, 'alpha');
        WriteOthersByValue(Src);
        Observer.Observe('C6 ext', L.RF(Src, 97761));
        Observer.Observe('C6 plain', L.RF(Src, 4));
        Observer.Observe('C6 comp', L.RF(Src, 5));
        Observer.Expect('C6 ext', 'hv:alpha');
        Observer.Expect('C6 plain', 'hv:alpha');
        Observer.Expect('C6 comp', 'hv:alpha');
        Observer.Verify();
    end;

    local procedure WriteOthersByValue(R: Record "LT BC3 Row")
    begin
        L.WF(R, 97761, 'zz');
        L.WF(R, 4, 'zz');
        L.WF(R, 5, 'zz');
    end;

    [Test]
    procedure OtherCodeunit_ByValue()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BC3 Row";
        Impl: Codeunit "LT BC3 Taker Impl";
        B: Text;
    begin
        // D1
        L.W(Src, 'alpha');
        Impl.Take(Src, B);
        Observer.Observe('D1 in w', B);
        Observer.Observe('D1 src', L.Rd(Src));
        Observer.Expect('D1 in w', 'hv:zzpha');
        Observer.Expect('D1 src', 'hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure InterfaceMethod_ByValue()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BC3 Row";
        Impl: Codeunit "LT BC3 Taker Impl";
        I: Interface "LT BC3 Taker";
        B: Text;
    begin
        // D2
        I := Impl;
        L.W(Src, 'alpha');
        I.Take(Src, B);
        Observer.Observe('D2 in w', B);
        Observer.Observe('D2 src', L.Rd(Src));
        Observer.Expect('D2 in w', 'hv:zzpha');
        Observer.Expect('D2 src', 'hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure TableProcedure_ByValue()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BC3 Row";
        Other: Record "LT BC3 Row";
        B: Text;
    begin
        // D3
        L.W(Src, 'alpha');
        Other.TakeByValue(Src, B);
        Observer.Observe('D3 in w', B);
        Observer.Observe('D3 src', L.Rd(Src));
        Observer.Expect('D3 in w', 'hv:zzpha');
        Observer.Expect('D3 src', 'hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure VarParameterPassedOnByValue()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BC3 Row";
        B: Text;
    begin
        // D4
        L.W(Src, 'alpha');
        PassOn(Src, B);
        Observer.Observe('D4 in w', B);
        Observer.Observe('D4 src', L.Rd(Src));
        Observer.Expect('D4 in w', 'hv:zzpha');
        Observer.Expect('D4 src', 'hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure GlobalRecord_ByValue()
    var
        Observer: Codeunit "Probe Observer";
        B: Text;
    begin
        // D5
        Clear(GRec);
        L.W(GRec, 'alpha');
        ByValue(GRec, B);
        Observer.Observe('D5 in w', B);
        Observer.Observe('D5 grec', L.Rd(GRec));
        Observer.Expect('D5 in w', 'hv:zzpha');
        Observer.Expect('D5 grec', 'hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure VariantHoldingBlob_ByValueVariantParam()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BC3 Row" temporary;
        Dst: Record "LT BC3 Row" temporary;
        Src2: Record "LT BC3 Row" temporary;
        V: Variant;
    begin
        // D6
        L.W(Src, 'alpha');
        V := Src.Data;
        TakeVar(V, Dst);
        L.W(Dst, 'zz');
        Src2.Data := V;
        Observer.Observe('D6 v', L.Rd(Src2));
        Observer.Observe('D6 src', L.Rd(Src));
        Observer.Observe('D6 dst', L.Rd(Dst));
        Observer.Expect('D6 v', 'hv:alpha');
        Observer.Expect('D6 src', 'hv:alpha');
        Observer.Expect('D6 dst', 'hv:zzpha');
        Observer.Verify();
    end;

    [Test]
    procedure TransferFieldsTrue_OtherTable()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BC3 Row" temporary;
        Dst: Record "LT BC3 Other" temporary;
        IS: InStream;
        OS: OutStream;
        T: Text;
    begin
        // E1
        L.W(Src, 'alpha');
        Dst.TransferFields(Src, true);
        L.W(Src, 'beta');
        Dst.Data.CreateInStream(IS);
        IS.ReadText(T);
        Observer.Observe('E1 dst w src', L.HasValueText(Dst.Data.HasValue()) + T);
        Dst.Data.CreateOutStream(OS);
        OS.WriteText('zz');
        Observer.Observe('E1 src w dst', L.Rd(Src));
        Observer.Expect('E1 dst w src', 'hv:alpha');
        Observer.Expect('E1 src w dst', 'hv:betaa');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_TwoBlobsOneStored()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BC3 Row";
        Dst: Record "LT BC3 Row";
    begin
        // E2
        L.Reset();
        Src.Key1 := 48;
        L.W(Src, 'alpha');
        Src.Insert();
        L.WF(Src, 4, 'alpha');
        Dst.Copy(Src);
        L.W(Dst, 'zz');
        L.WF(Dst, 4, 'zz');
        Observer.Observe('E2 src data', L.Rd(Src));
        Observer.Observe('E2 src plain', L.RF(Src, 4));
        Src.Modify();
        Observer.Observe('E2 row data', L.Stored(48));
        Observer.Observe('E2 row plain', L.StoredF(48, 4));
        Observer.Expect('E2 src data', 'hv:alpha');
        Observer.Expect('E2 src plain', 'hv:alpha');
        Observer.Expect('E2 row data', 'hv: hv:alpha');
        Observer.Expect('E2 row plain', 'hv: hv:alpha');
        Observer.Verify();
    end;
}
