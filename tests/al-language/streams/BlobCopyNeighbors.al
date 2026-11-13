// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-copy-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 97850, 97851, helper codeunits 97852, 97853, 97854, 97855;
//   test codeunits 97860 to 97866
// Probe: written against real BC (al-runner pull request 7981, fourth Blob copy probe; the earlier ones are
//   recordref-fieldref/fieldref/FieldRefValueBlobCopy.al, streams/BlobValueCopyShapes.al, streams/BlobCopyStates.al and
//   streams/BlobAssignThenCalcFields.al).
// Facts: whether a Blob value is copied or shared when a record or a Blob field moves, per source kind (stored or temporary record),
//   taker and preparation state of the source. Each cell writes 'zz' on the other side after the move and reads one side back.
//   Takers: a Record parameter, a temporary Record parameter, a Variant parameter, a local Variant, a global Variant, a Variant array
//   element, a procedure return value, TransferFields(Src, true); Record.Copy for every pair of stored and temporary records and
//   Record.Copy(Src, true) between temporary records; a Blob field read into a global Variant, a Variant array element and a by-value
//   Variant parameter; event subscribers that take the record by value (codeunit IntegrationEvent and BusinessEvent publishers by value
//   and var, IncludeSender, a manual subscriber, IntegrationEvents declared in a table, the table events OnBeforeInsertEvent,
//   OnAfterInsertEvent, OnBeforeModifyEvent and OnAfterModifyEvent); a table procedure with and without [TryFunction];
//   RecordRef.SetTable(Rec) after GetTable, Open and FindFirst, FieldRef.Value := and RecordRef.Modify; RecordRef.SetTable(Rec, true)
//   after a RecordRef call or a RecordRef assignment; a record method between Insert and the by-value call; CalcFields after :=.
//   Preparation states (LT BC4 Lib.Prep): mem, ins, insmod, inswrite, insmodwrite, insinitwrite, calc, get, empty, asg, insemptywrite,
//   inscalcwrite, inswritemodwrite, insfailedinsertwrite, insclearfield, insclearfieldwrite (written out at Prep).
//   Value format: hv: or nohv: (HasValue of the Blob in hand, no CalcFields) followed by the text read from it; row = the stored row
//   read through a fresh record: HasValue before CalcFields, a space, then hv:/nohv: and the text after CalcFields.
// What BC did (the same on 27.5, 28.5 and 29.0):
//   - Every by-value taker, Record.Copy pair, field read and by-value subscriber copies the Blob in every state, for stored and for
//     temporary sources: the other side's 'zz' never reaches the side that is read. A Blob written again after Insert, Modify, Init,
//     CalcFields or Clear(field) is copied with the text it holds in memory ('beta' over 'alpha' reads 'betaa').
//   - Record.Copy(Src, true) between temporary records: a write into the target's Blob does not reach the source's buffer.
//   - A source read with Get only (state get), or after FindFirst: the record copies give HasValue true and empty text; the field reads
//     give HasValue false. An empty source or a cleared field gives nohv:.
//   - Shared, not copied: only a var subscriber of a var publisher (and of OnBeforeInsertEvent, where the row stores 'zzpha').
//     A by-value subscriber of a table event changes neither Rec nor the stored row.
//   - RecordRef.SetTable(Rec) after RR.Open and FindFirst gives HasValue true and empty text (the Blob is not loaded); after
//     RR.Field(2).CalcField() or GetTable the value; SetTable(Rec, true) gives the RecordRef's value, the source keeps its own.
//   - A Blob assigned with := into a record that was never inserted: CalcFields on the copy and on the source gives nohv:
//     (the value is lost, as BlobAssignThenCalcFields.al measured); over a stored row CalcFields gives the stored 'alpha'.
// BC versions: 27.5+

table 97850 "LT BC4 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Key1; Integer) { DataClassification = SystemMetadata; }
        field(2; Data; Blob) { DataClassification = SystemMetadata; }
        field(3; Mode; Integer) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; Key1) { Clustered = true; }
    }
}

// A table that declares event publishers and procedures that take a record by value.
table 97851 "LT BC4 Pub Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Key1; Integer) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; Key1) { Clustered = true; }
    }

    [IntegrationEvent(false, false)]
    procedure OnTableVar(var R: Record "LT BC4 Row")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnTableValue(R: Record "LT BC4 Row")
    begin
    end;

    procedure Take(R: Record "LT BC4 Row")
    var
        L: Codeunit "LT BC4 Lib";
    begin
        L.W(R, 'zz');
    end;

    [TryFunction]
    procedure TryTake(R: Record "LT BC4 Row")
    var
        L: Codeunit "LT BC4 Lib";
    begin
        L.W(R, 'zz');
    end;
}

// Shared read and write helpers (no state).
codeunit 97852 "LT BC4 Lib"
{
    procedure W(var R: Record "LT BC4 Row"; T: Text)
    var
        OS: OutStream;
    begin
        R.Data.CreateOutStream(OS);
        OS.WriteText(T);
    end;

    // hv: or nohv: (HasValue of the Blob in hand, no CalcFields), then the text read from it.
    procedure Rd(var R: Record "LT BC4 Row"): Text
    var
        IS: InStream;
        T: Text;
        HV: Boolean;
    begin
        HV := R.Data.HasValue();
        R.Data.CreateInStream(IS);
        IS.ReadText(T);
        if HV then
            exit('hv:' + T);
        exit('nohv:' + T);
    end;

    // The RecordRef read through SetTable into a fresh temporary record.
    procedure RdRR(var RR: RecordRef): Text
    var
        R: Record "LT BC4 Row" temporary;
    begin
        RR.SetTable(R);
        exit(Rd(R));
    end;

    // The stored row read through a fresh record: HasValue before CalcFields, a space, then the text after CalcFields.
    procedure Stored(K: Integer): Text
    var
        R: Record "LT BC4 Row";
        HV: Boolean;
    begin
        if not R.Get(K) then
            exit('<no row>');
        HV := R.Data.HasValue();
        R.CalcFields(Data);
        if HV then
            exit('hv: ' + Rd(R));
        exit('nohv: ' + Rd(R));
    end;

    procedure StateName(S: Integer): Text
    begin
        case S of
            1:
                exit('mem');
            2:
                exit('ins');
            3:
                exit('insmod');
            4:
                exit('inswrite');
            5:
                exit('insmodwrite');
            6:
                exit('insinitwrite');
            7:
                exit('calc');
            8:
                exit('get');
            9:
                exit('empty');
            10:
                exit('asg');
            11:
                exit('insemptywrite');
            12:
                exit('inscalcwrite');
            13:
                exit('inswritemodwrite');
            14:
                exit('insfailedinsertwrite');
            15:
                exit('insclearfield');
            16:
                exit('insclearfieldwrite');
        end;
    end;

    // Puts R (key 10) into state S:
    //  1 mem                  'alpha' written in memory, not stored
    //  2 ins                  'alpha' written, then Insert
    //  3 insmod               'alpha' written, Insert, Modify
    //  4 inswrite             'alpha' written, Insert, 'beta' written
    //  5 insmodwrite          'alpha' written, Insert, Modify, 'beta' written
    //  6 insinitwrite         'alpha' written, Insert, Init, 'beta' written
    //  7 calc                 'alpha' stored, read again with Get and CalcFields
    //  8 get                  'alpha' stored, read again with Get only (Blob not loaded)
    //  9 empty                Init only, not stored
    // 10 asg                  copied by := from another record that holds 'alpha', not stored
    // 11 insemptywrite        Insert with an empty Blob, then 'beta' written
    // 12 inscalcwrite         'alpha' written, Insert, CalcFields, 'beta' written
    // 13 inswritemodwrite     'alpha' written, Insert, 'gamma' written, Modify, 'beta' written
    // 14 insfailedinsertwrite 'alpha' written, Insert, Modify, a second Insert that returns false, 'beta' written
    // 15 insclearfield        'alpha' written, Insert, Clear(Data)
    // 16 insclearfieldwrite   'alpha' written, Insert, Clear(Data), 'beta' written
    procedure Prep(var R: Record "LT BC4 Row"; S: Integer)
    var
        Other: Record "LT BC4 Row";
        TempOther: Record "LT BC4 Row" temporary;
    begin
        R.Init();
        R.Key1 := 10;
        case S of
            1:
                W(R, 'alpha');
            2:
                begin
                    W(R, 'alpha');
                    R.Insert();
                end;
            3:
                begin
                    W(R, 'alpha');
                    R.Insert();
                    R.Modify();
                end;
            4:
                begin
                    W(R, 'alpha');
                    R.Insert();
                    W(R, 'beta');
                end;
            5:
                begin
                    W(R, 'alpha');
                    R.Insert();
                    R.Modify();
                    W(R, 'beta');
                end;
            6:
                begin
                    W(R, 'alpha');
                    R.Insert();
                    R.Init();
                    W(R, 'beta');
                end;
            7, 8:
                begin
                    W(R, 'alpha');
                    R.Insert();
                    if R.IsTemporary() then
                        R.Init()
                    else
                        Clear(R);
                    R.Get(10);
                    if S = 7 then
                        R.CalcFields(Data);
                end;
            10:
                if R.IsTemporary() then begin
                    TempOther.Key1 := 10;
                    W(TempOther, 'alpha');
                    R := TempOther;
                end else begin
                    Other.Key1 := 10;
                    W(Other, 'alpha');
                    R := Other;
                end;
            11:
                begin
                    R.Insert();
                    W(R, 'beta');
                end;
            12:
                begin
                    W(R, 'alpha');
                    R.Insert();
                    R.CalcFields(Data);
                    W(R, 'beta');
                end;
            13:
                begin
                    W(R, 'alpha');
                    R.Insert();
                    W(R, 'gamma');
                    R.Modify();
                    W(R, 'beta');
                end;
            14:
                begin
                    W(R, 'alpha');
                    R.Insert();
                    R.Modify();
                    if R.Insert() then;
                    W(R, 'beta');
                end;
            15:
                begin
                    W(R, 'alpha');
                    R.Insert();
                    Clear(R.Data);
                end;
            16:
                begin
                    W(R, 'alpha');
                    R.Insert();
                    Clear(R.Data);
                    W(R, 'beta');
                end;
        end;
    end;

    procedure Reset()
    var
        R: Record "LT BC4 Row";
    begin
        R.DeleteAll();
    end;
}

codeunit 97853 "LT BC4 Pub"
{
    [IntegrationEvent(false, false)]
    procedure OnValue(R: Record "LT BC4 Row")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnVarSubValue(var R: Record "LT BC4 Row")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnVarSubVar(var R: Record "LT BC4 Row")
    begin
    end;

    [BusinessEvent(false)]
    procedure OnBusinessValue(R: Record "LT BC4 Row")
    begin
    end;

    [BusinessEvent(false)]
    procedure OnBusinessVar(var R: Record "LT BC4 Row")
    begin
    end;

    [IntegrationEvent(true, false)]
    procedure OnSenderValue(R: Record "LT BC4 Row")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnManualVar(var R: Record "LT BC4 Row")
    begin
    end;
}

// Every subscriber writes 'zz' into the record it is given. The table event subscribers act only for the Mode their test sets.
codeunit 97854 "LT BC4 Subs"
{
    var
        L: Codeunit "LT BC4 Lib";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT BC4 Pub", 'OnValue', '', false, false)]
    local procedure HValue(R: Record "LT BC4 Row")
    begin
        L.W(R, 'zz');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT BC4 Pub", 'OnVarSubValue', '', false, false)]
    local procedure HVarSubValue(R: Record "LT BC4 Row")
    begin
        L.W(R, 'zz');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT BC4 Pub", 'OnVarSubVar', '', false, false)]
    local procedure HVarSubVar(var R: Record "LT BC4 Row")
    begin
        L.W(R, 'zz');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT BC4 Pub", 'OnBusinessValue', '', false, false)]
    local procedure HBusinessValue(R: Record "LT BC4 Row")
    begin
        L.W(R, 'zz');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT BC4 Pub", 'OnBusinessVar', '', false, false)]
    local procedure HBusinessVar(R: Record "LT BC4 Row")
    begin
        L.W(R, 'zz');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT BC4 Pub", 'OnSenderValue', '', false, false)]
    local procedure HSenderValue(sender: Codeunit "LT BC4 Pub"; R: Record "LT BC4 Row")
    begin
        L.W(R, 'zz');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT BC4 Pub Table", 'OnTableVar', '', false, false)]
    local procedure HTableVar(R: Record "LT BC4 Row")
    begin
        L.W(R, 'zz');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT BC4 Pub Table", 'OnTableValue', '', false, false)]
    local procedure HTableValue(R: Record "LT BC4 Row")
    begin
        L.W(R, 'zz');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT BC4 Row", 'OnBeforeInsertEvent', '', false, false)]
    local procedure HBeforeInsertValue(Rec: Record "LT BC4 Row"; RunTrigger: Boolean)
    begin
        if Rec.Mode = 77 then
            L.W(Rec, 'zz');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT BC4 Row", 'OnBeforeInsertEvent', '', false, false)]
    local procedure HBeforeInsertVar(var Rec: Record "LT BC4 Row"; RunTrigger: Boolean)
    begin
        if Rec.Mode = 75 then
            L.W(Rec, 'zz');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT BC4 Row", 'OnAfterInsertEvent', '', false, false)]
    local procedure HAfterInsertValue(Rec: Record "LT BC4 Row"; RunTrigger: Boolean)
    begin
        if Rec.Mode = 76 then
            L.W(Rec, 'zz');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT BC4 Row", 'OnBeforeModifyEvent', '', false, false)]
    local procedure HBeforeModifyValue(Rec: Record "LT BC4 Row"; xRec: Record "LT BC4 Row"; RunTrigger: Boolean)
    begin
        if Rec.Mode = 79 then
            L.W(Rec, 'zz');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT BC4 Row", 'OnAfterModifyEvent', '', false, false)]
    local procedure HAfterModifyValue(Rec: Record "LT BC4 Row"; xRec: Record "LT BC4 Row"; RunTrigger: Boolean)
    begin
        if Rec.Mode = 78 then
            L.W(Rec, 'zz');
    end;
}

codeunit 97855 "LT BC4 Manual Subs"
{
    EventSubscriberInstance = Manual;

    var
        L: Codeunit "LT BC4 Lib";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT BC4 Pub", 'OnManualVar', '', false, false)]
    local procedure HManualVar(R: Record "LT BC4 Row")
    begin
        L.W(R, 'zz');
    end;
}


codeunit 97860 "LT BC4 ByValue Stored"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT BC4 Lib";
        Observer: Codeunit "Probe Observer";
        GV: Variant;

    local procedure TakeRec(R: Record "LT BC4 Row")
    begin
        L.W(R, 'zz');
    end;

    local procedure TakeTemp(R: Record "LT BC4 Row" temporary)
    begin
        L.W(R, 'zz');
    end;

    local procedure TakeVariant(V: Variant; var Src: Record "LT BC4 Row"): Text
    var
        R: Record "LT BC4 Row";
    begin
        L.W(Src, 'zz');
        R := V;
        exit(L.Rd(R));
    end;

    local procedure RetOf(var R: Record "LT BC4 Row"): Record "LT BC4 Row"
    begin
        exit(R);
    end;

    local procedure CellRecordParam(S: Integer): Text
    var
        Src: Record "LT BC4 Row";
    begin
        L.Reset();
        L.Prep(Src, S);
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure CellTemporaryParam(S: Integer): Text
    var
        Src: Record "LT BC4 Row";
    begin
        L.Reset();
        L.Prep(Src, S);
        TakeTemp(Src);
        exit(L.Rd(Src));
    end;

    local procedure CellVariantParam(S: Integer): Text
    var
        Src: Record "LT BC4 Row";
    begin
        L.Reset();
        L.Prep(Src, S);
        exit(TakeVariant(Src, Src));
    end;

    local procedure CellLocalVariant(S: Integer): Text
    var
        Src: Record "LT BC4 Row";
        Dst: Record "LT BC4 Row";
        V: Variant;
    begin
        L.Reset();
        L.Prep(Src, S);
        V := Src;
        L.W(Src, 'zz');
        Dst := V;
        exit(L.Rd(Dst));
    end;

    local procedure CellGlobalVariant(S: Integer): Text
    var
        Src: Record "LT BC4 Row";
        Dst: Record "LT BC4 Row";
    begin
        L.Reset();
        L.Prep(Src, S);
        GV := Src;
        L.W(Src, 'zz');
        Dst := GV;
        exit(L.Rd(Dst));
    end;

    local procedure CellArrayVariant(S: Integer): Text
    var
        Src: Record "LT BC4 Row";
        Dst: Record "LT BC4 Row";
        VA: array[3] of Variant;
    begin
        L.Reset();
        L.Prep(Src, S);
        VA[2] := Src;
        L.W(Src, 'zz');
        Dst := VA[2];
        exit(L.Rd(Dst));
    end;

    local procedure CellReturnValue(S: Integer): Text
    var
        Src: Record "LT BC4 Row";
        Dst: Record "LT BC4 Row";
    begin
        L.Reset();
        L.Prep(Src, S);
        Dst := RetOf(Src);
        L.W(Dst, 'zz');
        exit(L.Rd(Src));
    end;

    local procedure CellTransferFieldsTrue(S: Integer): Text
    var
        Src: Record "LT BC4 Row";
        Dst: Record "LT BC4 Row";
    begin
        L.Reset();
        L.Prep(Src, S);
        Dst.TransferFields(Src, true);
        L.W(Dst, 'zz');
        exit(L.Rd(Src));
    end;

    [Test]
    procedure ByValue_StoredIntoRecordParam_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), CellRecordParam(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_StoredIntoTemporaryParam_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), CellTemporaryParam(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_StoredIntoVariantParam_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), CellVariantParam(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_StoredIntoLocalVariant_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), CellLocalVariant(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_StoredIntoGlobalVariant_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), CellGlobalVariant(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_StoredIntoArrayVariant_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), CellArrayVariant(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_StoredIntoReturnValue_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), CellReturnValue(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_StoredIntoTransferFieldsTrue_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), CellTransferFieldsTrue(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

}

codeunit 97861 "LT BC4 ByValue Temp"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT BC4 Lib";
        Observer: Codeunit "Probe Observer";
        GV: Variant;

    local procedure TakeRec(R: Record "LT BC4 Row")
    begin
        L.W(R, 'zz');
    end;

    local procedure TakeTemp(R: Record "LT BC4 Row" temporary)
    begin
        L.W(R, 'zz');
    end;

    local procedure TakeVariant(V: Variant; var Src: Record "LT BC4 Row" temporary): Text
    var
        R: Record "LT BC4 Row" temporary;
    begin
        L.W(Src, 'zz');
        R := V;
        exit(L.Rd(R));
    end;

    local procedure RetOf(var R: Record "LT BC4 Row" temporary): Record "LT BC4 Row"
    begin
        exit(R);
    end;

    local procedure CellRecordParam(S: Integer): Text
    var
        Src: Record "LT BC4 Row" temporary;
    begin
        L.Reset();
        L.Prep(Src, S);
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure CellTemporaryParam(S: Integer): Text
    var
        Src: Record "LT BC4 Row" temporary;
    begin
        L.Reset();
        L.Prep(Src, S);
        TakeTemp(Src);
        exit(L.Rd(Src));
    end;

    local procedure CellVariantParam(S: Integer): Text
    var
        Src: Record "LT BC4 Row" temporary;
    begin
        L.Reset();
        L.Prep(Src, S);
        exit(TakeVariant(Src, Src));
    end;

    local procedure CellLocalVariant(S: Integer): Text
    var
        Src: Record "LT BC4 Row" temporary;
        Dst: Record "LT BC4 Row" temporary;
        V: Variant;
    begin
        L.Reset();
        L.Prep(Src, S);
        V := Src;
        L.W(Src, 'zz');
        Dst := V;
        exit(L.Rd(Dst));
    end;

    local procedure CellGlobalVariant(S: Integer): Text
    var
        Src: Record "LT BC4 Row" temporary;
        Dst: Record "LT BC4 Row" temporary;
    begin
        L.Reset();
        L.Prep(Src, S);
        GV := Src;
        L.W(Src, 'zz');
        Dst := GV;
        exit(L.Rd(Dst));
    end;

    local procedure CellArrayVariant(S: Integer): Text
    var
        Src: Record "LT BC4 Row" temporary;
        Dst: Record "LT BC4 Row" temporary;
        VA: array[3] of Variant;
    begin
        L.Reset();
        L.Prep(Src, S);
        VA[2] := Src;
        L.W(Src, 'zz');
        Dst := VA[2];
        exit(L.Rd(Dst));
    end;

    local procedure CellReturnValue(S: Integer): Text
    var
        Src: Record "LT BC4 Row" temporary;
        Dst: Record "LT BC4 Row" temporary;
    begin
        L.Reset();
        L.Prep(Src, S);
        Dst := RetOf(Src);
        L.W(Dst, 'zz');
        exit(L.Rd(Src));
    end;

    local procedure CellTransferFieldsTrue(S: Integer): Text
    var
        Src: Record "LT BC4 Row" temporary;
        Dst: Record "LT BC4 Row" temporary;
    begin
        L.Reset();
        L.Prep(Src, S);
        Dst.TransferFields(Src, true);
        L.W(Dst, 'zz');
        exit(L.Rd(Src));
    end;

    [Test]
    procedure ByValue_TempIntoRecordParam_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), CellRecordParam(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_TempIntoTemporaryParam_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), CellTemporaryParam(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_TempIntoVariantParam_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), CellVariantParam(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_TempIntoLocalVariant_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), CellLocalVariant(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_TempIntoGlobalVariant_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), CellGlobalVariant(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_TempIntoArrayVariant_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), CellArrayVariant(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_TempIntoReturnValue_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), CellReturnValue(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_TempIntoTransferFieldsTrue_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), CellTransferFieldsTrue(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

}

codeunit 97862 "LT BC4 Copy Pairs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT BC4 Lib";
        Observer: Codeunit "Probe Observer";

    local procedure CopyStoredToStored(S: Integer): Text
    var
        Src: Record "LT BC4 Row";
        Dst: Record "LT BC4 Row";
    begin
        L.Reset();
        L.Prep(Src, S);
        Dst.Copy(Src);
        L.W(Dst, 'zz');
        exit(L.Rd(Src));
    end;

    local procedure CopyStoredToTemp(S: Integer): Text
    var
        Src: Record "LT BC4 Row";
        Dst: Record "LT BC4 Row" temporary;
    begin
        L.Reset();
        L.Prep(Src, S);
        Dst.Copy(Src);
        L.W(Dst, 'zz');
        exit(L.Rd(Src));
    end;

    local procedure CopyTempToStored(S: Integer): Text
    var
        Src: Record "LT BC4 Row" temporary;
        Dst: Record "LT BC4 Row";
    begin
        L.Reset();
        L.Prep(Src, S);
        Dst.Copy(Src);
        L.W(Dst, 'zz');
        exit(L.Rd(Src));
    end;

    local procedure CopyTempToTemp(S: Integer): Text
    var
        Src: Record "LT BC4 Row" temporary;
        Dst: Record "LT BC4 Row" temporary;
    begin
        L.Reset();
        L.Prep(Src, S);
        Dst.Copy(Src);
        L.W(Dst, 'zz');
        exit(L.Rd(Src));
    end;

    local procedure CopyShareTempToTemp(S: Integer): Text
    var
        Src: Record "LT BC4 Row" temporary;
        Dst: Record "LT BC4 Row" temporary;
    begin
        L.Reset();
        L.Prep(Src, S);
        Dst.Copy(Src, true);
        L.W(Dst, 'zz');
        exit(L.Rd(Src));
    end;

    [Test]
    procedure Copy_StoredToStored_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), CopyStoredToStored(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_StoredToTemp_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), CopyStoredToTemp(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_TempToStored_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), CopyTempToStored(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_TempToTemp_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), CopyTempToTemp(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_ShareTempToTemp_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), CopyShareTempToTemp(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

}

codeunit 97863 "LT BC4 Field Reads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT BC4 Lib";
        Observer: Codeunit "Probe Observer";
        GV: Variant;

    local procedure TakeVarWrite(V: Variant; var Src: Record "LT BC4 Row"; var Dst: Record "LT BC4 Row")
    begin
        L.W(Src, 'zz');
        Dst.Data := V;
    end;

    local procedure TakeVarWriteT(V: Variant; var Src: Record "LT BC4 Row" temporary; var Dst: Record "LT BC4 Row" temporary)
    begin
        L.W(Src, 'zz');
        Dst.Data := V;
    end;

    local procedure ReadStoredGlobalVariant(S: Integer): Text
    var
        Src: Record "LT BC4 Row";
        Dst: Record "LT BC4 Row";
    begin
        L.Reset();
        L.Prep(Src, S);
        GV := Src.Data;
        L.W(Src, 'zz');
        Dst.Data := GV;
        exit(L.Rd(Dst));
    end;

    local procedure ReadStoredArrayElement(S: Integer): Text
    var
        Src: Record "LT BC4 Row";
        Dst: Record "LT BC4 Row";
        VA: array[2] of Variant;
    begin
        L.Reset();
        L.Prep(Src, S);
        VA[1] := Src.Data;
        L.W(Src, 'zz');
        Dst.Data := VA[1];
        exit(L.Rd(Dst));
    end;

    local procedure ReadStoredVariantParam(S: Integer): Text
    var
        Src: Record "LT BC4 Row";
        Dst: Record "LT BC4 Row";
    begin
        L.Reset();
        L.Prep(Src, S);
        TakeVarWrite(Src.Data, Src, Dst);
        exit(L.Rd(Dst));
    end;

    local procedure ReadTempGlobalVariant(S: Integer): Text
    var
        Src: Record "LT BC4 Row" temporary;
        Dst: Record "LT BC4 Row" temporary;
    begin
        L.Reset();
        L.Prep(Src, S);
        GV := Src.Data;
        L.W(Src, 'zz');
        Dst.Data := GV;
        exit(L.Rd(Dst));
    end;

    local procedure ReadTempArrayElement(S: Integer): Text
    var
        Src: Record "LT BC4 Row" temporary;
        Dst: Record "LT BC4 Row" temporary;
        VA: array[2] of Variant;
    begin
        L.Reset();
        L.Prep(Src, S);
        VA[1] := Src.Data;
        L.W(Src, 'zz');
        Dst.Data := VA[1];
        exit(L.Rd(Dst));
    end;

    local procedure ReadTempVariantParam(S: Integer): Text
    var
        Src: Record "LT BC4 Row" temporary;
        Dst: Record "LT BC4 Row" temporary;
    begin
        L.Reset();
        L.Prep(Src, S);
        TakeVarWriteT(Src.Data, Src, Dst);
        exit(L.Rd(Dst));
    end;

    [Test]
    procedure FieldRead_StoredIntoGlobalVariant_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), ReadStoredGlobalVariant(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'nohv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRead_StoredIntoArrayElement_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), ReadStoredArrayElement(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'nohv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRead_StoredIntoVariantParam_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), ReadStoredVariantParam(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'nohv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRead_TempIntoGlobalVariant_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), ReadTempGlobalVariant(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'nohv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRead_TempIntoArrayElement_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), ReadTempArrayElement(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'nohv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRead_TempIntoVariantParam_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), ReadTempVariantParam(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'nohv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

}

codeunit 97864 "LT BC4 Events"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT BC4 Lib";
        Observer: Codeunit "Probe Observer";

    local procedure EventCodeunitIntegrationValue(S: Integer): Text
    var
        Src: Record "LT BC4 Row";
        P: Codeunit "LT BC4 Pub";
    begin
        L.Reset();
        L.Prep(Src, S);
        P.OnValue(Src);
        exit(L.Rd(Src));
    end;

    local procedure EventCodeunitIntegrationVarSubValue(S: Integer): Text
    var
        Src: Record "LT BC4 Row";
        P: Codeunit "LT BC4 Pub";
    begin
        L.Reset();
        L.Prep(Src, S);
        P.OnVarSubValue(Src);
        exit(L.Rd(Src));
    end;

    local procedure EventCodeunitIntegrationVarSubVar(S: Integer): Text
    var
        Src: Record "LT BC4 Row";
        P: Codeunit "LT BC4 Pub";
    begin
        L.Reset();
        L.Prep(Src, S);
        P.OnVarSubVar(Src);
        exit(L.Rd(Src));
    end;

    local procedure EventCodeunitBusinessValue(S: Integer): Text
    var
        Src: Record "LT BC4 Row";
        P: Codeunit "LT BC4 Pub";
    begin
        L.Reset();
        L.Prep(Src, S);
        P.OnBusinessValue(Src);
        exit(L.Rd(Src));
    end;

    local procedure EventCodeunitBusinessVarSubValue(S: Integer): Text
    var
        Src: Record "LT BC4 Row";
        P: Codeunit "LT BC4 Pub";
    begin
        L.Reset();
        L.Prep(Src, S);
        P.OnBusinessVar(Src);
        exit(L.Rd(Src));
    end;

    local procedure EventCodeunitSenderValue(S: Integer): Text
    var
        Src: Record "LT BC4 Row";
        P: Codeunit "LT BC4 Pub";
    begin
        L.Reset();
        L.Prep(Src, S);
        P.OnSenderValue(Src);
        exit(L.Rd(Src));
    end;

    local procedure EventCodeunitManualVarSubValue(S: Integer): Text
    var
        Src: Record "LT BC4 Row";
        P: Codeunit "LT BC4 Pub";
        M: Codeunit "LT BC4 Manual Subs";
    begin
        L.Reset();
        L.Prep(Src, S);
        BindSubscription(M);
        P.OnManualVar(Src);
        UnbindSubscription(M);
        exit(L.Rd(Src));
    end;

    local procedure EventTableIntegrationValue(S: Integer): Text
    var
        Src: Record "LT BC4 Row";
        P: Record "LT BC4 Pub Table";
    begin
        L.Reset();
        L.Prep(Src, S);
        P.OnTableValue(Src);
        exit(L.Rd(Src));
    end;

    local procedure EventTableIntegrationVarSubValue(S: Integer): Text
    var
        Src: Record "LT BC4 Row";
        P: Record "LT BC4 Pub Table";
    begin
        L.Reset();
        L.Prep(Src, S);
        P.OnTableVar(Src);
        exit(L.Rd(Src));
    end;

    local procedure EventTableProcedure(S: Integer): Text
    var
        Src: Record "LT BC4 Row";
        P: Record "LT BC4 Pub Table";
    begin
        L.Reset();
        L.Prep(Src, S);
        P.Take(Src);
        exit(L.Rd(Src));
    end;

    local procedure EventTableTryFunction(S: Integer): Text
    var
        Src: Record "LT BC4 Row";
        P: Record "LT BC4 Pub Table";
    begin
        L.Reset();
        L.Prep(Src, S);
        if P.TryTake(Src) then;
        exit(L.Rd(Src));
    end;

    local procedure TableOnBeforeInsertEventValue(var Rec: Text; var Row: Text)
    var
        Src: Record "LT BC4 Row";
    begin
        L.Reset();
        Src.Key1 := 10;
        Src.Mode := 77;
        L.W(Src, 'alpha');
        Src.Insert();
        Rec := L.Rd(Src);
        Row := L.Stored(10);
    end;

    local procedure TableOnAfterInsertEventValue(var Rec: Text; var Row: Text)
    var
        Src: Record "LT BC4 Row";
    begin
        L.Reset();
        Src.Key1 := 10;
        Src.Mode := 76;
        L.W(Src, 'alpha');
        Src.Insert();
        Rec := L.Rd(Src);
        Row := L.Stored(10);
    end;

    local procedure TableOnBeforeInsertEventVar(var Rec: Text; var Row: Text)
    var
        Src: Record "LT BC4 Row";
    begin
        L.Reset();
        Src.Key1 := 10;
        Src.Mode := 75;
        L.W(Src, 'alpha');
        Src.Insert();
        Rec := L.Rd(Src);
        Row := L.Stored(10);
    end;

    local procedure TableOnBeforeModifyEventValue(var Rec: Text; var Row: Text)
    var
        Src: Record "LT BC4 Row";
    begin
        L.Reset();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        Src.Mode := 79;
        Src.Modify();
        Rec := L.Rd(Src);
        Row := L.Stored(10);
    end;

    local procedure TableOnAfterModifyEventValue(var Rec: Text; var Row: Text)
    var
        Src: Record "LT BC4 Row";
    begin
        L.Reset();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        Src.Mode := 78;
        Src.Modify();
        Rec := L.Rd(Src);
        Row := L.Stored(10);
    end;

    [Test]
    procedure Publisher_CodeunitIntegrationValue_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), EventCodeunitIntegrationValue(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure Publisher_CodeunitIntegrationVarSubValue_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), EventCodeunitIntegrationVarSubValue(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure Publisher_CodeunitIntegrationVarSubVar_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), EventCodeunitIntegrationVarSubVar(S));
        Observer.Expect('mem', 'hv:zzpha');
        Observer.Expect('ins', 'hv:zzpha');
        Observer.Expect('insmod', 'hv:zzpha');
        Observer.Expect('inswrite', 'hv:zztaa');
        Observer.Expect('insmodwrite', 'hv:zztaa');
        Observer.Expect('insinitwrite', 'hv:zzta');
        Observer.Expect('calc', 'hv:zzpha');
        Observer.Expect('get', 'hv:zz');
        Observer.Expect('empty', 'hv:zz');
        Observer.Expect('asg', 'hv:zzpha');
        Observer.Expect('insemptywrite', 'hv:zzta');
        Observer.Expect('inscalcwrite', 'hv:zztaa');
        Observer.Expect('inswritemodwrite', 'hv:zztaa');
        Observer.Expect('insfailedinsertwrite', 'hv:zztaa');
        Observer.Expect('insclearfield', 'hv:zz');
        Observer.Expect('insclearfieldwrite', 'hv:zzta');
        Observer.Verify();
    end;

    [Test]
    procedure Publisher_CodeunitBusinessValue_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), EventCodeunitBusinessValue(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure Publisher_CodeunitBusinessVarSubValue_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), EventCodeunitBusinessVarSubValue(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure Publisher_CodeunitSenderValue_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), EventCodeunitSenderValue(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure Publisher_CodeunitManualVarSubValue_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), EventCodeunitManualVarSubValue(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure Publisher_TableIntegrationValue_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), EventTableIntegrationValue(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure Publisher_TableIntegrationVarSubValue_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), EventTableIntegrationVarSubValue(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure Publisher_TableProcedure_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), EventTableProcedure(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure Publisher_TableTryFunction_PerState()
    var
        S: Integer;
    begin
        for S := 1 to 16 do
            Observer.Observe(L.StateName(S), EventTableTryFunction(S));
        Observer.Expect('mem', 'hv:alpha');
        Observer.Expect('ins', 'hv:alpha');
        Observer.Expect('insmod', 'hv:alpha');
        Observer.Expect('inswrite', 'hv:betaa');
        Observer.Expect('insmodwrite', 'hv:betaa');
        Observer.Expect('insinitwrite', 'hv:beta');
        Observer.Expect('calc', 'hv:alpha');
        Observer.Expect('get', 'hv:');
        Observer.Expect('empty', 'nohv:');
        Observer.Expect('asg', 'hv:alpha');
        Observer.Expect('insemptywrite', 'hv:beta');
        Observer.Expect('inscalcwrite', 'hv:betaa');
        Observer.Expect('inswritemodwrite', 'hv:betaa');
        Observer.Expect('insfailedinsertwrite', 'hv:betaa');
        Observer.Expect('insclearfield', 'nohv:');
        Observer.Expect('insclearfieldwrite', 'hv:beta');
        Observer.Verify();
    end;

    [Test]
    procedure TableEvent_SubscriberWritesRec_RecAndRow()
    var
        R: Text;
        W: Text;
    begin
        TableOnBeforeInsertEventValue(R, W);
        Observer.Observe('OnBeforeInsertEventValue rec', R);
        Observer.Observe('OnBeforeInsertEventValue row', W);
        TableOnAfterInsertEventValue(R, W);
        Observer.Observe('OnAfterInsertEventValue rec', R);
        Observer.Observe('OnAfterInsertEventValue row', W);
        TableOnBeforeInsertEventVar(R, W);
        Observer.Observe('OnBeforeInsertEventVar rec', R);
        Observer.Observe('OnBeforeInsertEventVar row', W);
        TableOnBeforeModifyEventValue(R, W);
        Observer.Observe('OnBeforeModifyEventValue rec', R);
        Observer.Observe('OnBeforeModifyEventValue row', W);
        TableOnAfterModifyEventValue(R, W);
        Observer.Observe('OnAfterModifyEventValue rec', R);
        Observer.Observe('OnAfterModifyEventValue row', W);
        Observer.Expect('OnBeforeInsertEventValue rec', 'hv:alpha');
        Observer.Expect('OnBeforeInsertEventValue row', 'hv: hv:alpha');
        Observer.Expect('OnAfterInsertEventValue rec', 'hv:alpha');
        Observer.Expect('OnAfterInsertEventValue row', 'hv: hv:alpha');
        Observer.Expect('OnBeforeInsertEventVar rec', 'hv:zzpha');
        Observer.Expect('OnBeforeInsertEventVar row', 'hv: hv:zzpha');
        Observer.Expect('OnBeforeModifyEventValue rec', 'hv:alpha');
        Observer.Expect('OnBeforeModifyEventValue row', 'hv: hv:alpha');
        Observer.Expect('OnAfterModifyEventValue rec', 'hv:alpha');
        Observer.Expect('OnAfterModifyEventValue row', 'hv: hv:alpha');
        Observer.Verify();
    end;

}

codeunit 97865 "LT BC4 RecordRef"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT BC4 Lib";
        Observer: Codeunit "Probe Observer";

    local procedure TakeRec(R: Record "LT BC4 Row")
    begin
        L.W(R, 'zz');
    end;

    local procedure TakeRecT(R: Record "LT BC4 Row" temporary)
    begin
        L.W(R, 'zz');
    end;

    local procedure RrGetTable(): Text
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        RR: RecordRef;
    begin
        L.Reset();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        RR.GetTable(Src);
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure RrGetTableSetTable(): Text
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        RR: RecordRef;
    begin
        L.Reset();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        RR.GetTable(Src);
        RR.SetTable(Src);
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure RrGetTableSetTableFalse(): Text
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        RR: RecordRef;
    begin
        L.Reset();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        RR.GetTable(Src);
        RR.SetTable(Src, false);
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure RrOpenFindSetTable(): Text
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        RR: RecordRef;
    begin
        L.Reset();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        RR.Open(Database::"LT BC4 Row");
        RR.FindFirst();
        RR.SetTable(Src);
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure RrOpenFindCalcSetTable(): Text
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        RR: RecordRef;
    begin
        L.Reset();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        RR.Open(Database::"LT BC4 Row");
        RR.FindFirst();
        RR.Field(2).CalcField();
        RR.SetTable(Src);
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure RrOtherGetTableSetTable(): Text
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        RR: RecordRef;
    begin
        L.Reset();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        L.W(Other, 'gamma');
        RR.GetTable(Other);
        RR.SetTable(Src);
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure RrFieldValueSetTable(): Text
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        RR: RecordRef;
    begin
        L.Reset();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        RR.GetTable(Src);
        L.W(Other, 'gamma');
        RR.Field(2).Value := Other.Data;
        RR.SetTable(Src);
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure RrFieldValueModifySetTable(): Text
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        RR: RecordRef;
    begin
        L.Reset();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        RR.GetTable(Src);
        L.W(Other, 'gamma');
        RR.Field(2).Value := Other.Data;
        RR.Modify();
        RR.SetTable(Src);
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SharePlain(var RrText: Text; var SrcText: Text)
    var
        Src: Record "LT BC4 Row" temporary;
        Dst: Record "LT BC4 Row" temporary;
        Other: Record "LT BC4 Row" temporary;
        RR: RecordRef;
        RR2: RecordRef;
    begin
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        RR.GetTable(Src);

        RR.SetTable(Dst, true);
        L.W(Dst, 'zz');
        SrcText := L.Rd(Src);
        RrText := L.RdRR(RR);
    end;

    local procedure ShareFindCalc(var RrText: Text; var SrcText: Text)
    var
        Src: Record "LT BC4 Row" temporary;
        Dst: Record "LT BC4 Row" temporary;
        Other: Record "LT BC4 Row" temporary;
        RR: RecordRef;
        RR2: RecordRef;
    begin
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        RR.GetTable(Src);
        RR.FindFirst();
        RR.Field(2).CalcField();
        RR.SetTable(Dst, true);
        L.W(Dst, 'zz');
        SrcText := L.Rd(Src);
        RrText := L.RdRR(RR);
    end;

    local procedure ShareAssigned(var RrText: Text; var SrcText: Text)
    var
        Src: Record "LT BC4 Row" temporary;
        Dst: Record "LT BC4 Row" temporary;
        Other: Record "LT BC4 Row" temporary;
        RR: RecordRef;
        RR2: RecordRef;
    begin
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        RR.GetTable(Src);
        RR2 := RR;
        RR2.SetTable(Dst, true);
        L.W(Dst, 'zz');
        SrcText := L.Rd(Src);
        RrText := L.RdRR(RR2);
    end;

    local procedure ShareFieldValue(var RrText: Text; var SrcText: Text)
    var
        Src: Record "LT BC4 Row" temporary;
        Dst: Record "LT BC4 Row" temporary;
        Other: Record "LT BC4 Row" temporary;
        RR: RecordRef;
        RR2: RecordRef;
    begin
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        RR.GetTable(Src);
        L.W(Other, 'gamma');
        RR.Field(2).Value := Other.Data;
        RR.SetTable(Dst, true);
        L.W(Dst, 'zz');
        SrcText := L.Rd(Src);
        RrText := L.RdRR(RR);
    end;

    local procedure ShareModify(var RrText: Text; var SrcText: Text)
    var
        Src: Record "LT BC4 Row" temporary;
        Dst: Record "LT BC4 Row" temporary;
        Other: Record "LT BC4 Row" temporary;
        RR: RecordRef;
        RR2: RecordRef;
    begin
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        RR.GetTable(Src);
        RR.Modify();
        RR.SetTable(Dst, true);
        L.W(Dst, 'zz');
        SrcText := L.Rd(Src);
        RrText := L.RdRR(RR);
    end;

    local procedure ShareInsert(var RrText: Text; var SrcText: Text)
    var
        Src: Record "LT BC4 Row" temporary;
        Dst: Record "LT BC4 Row" temporary;
        Other: Record "LT BC4 Row" temporary;
        RR: RecordRef;
        RR2: RecordRef;
    begin
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        RR.GetTable(Src);
        RR.Field(1).Value := 55;
        RR.Insert();
        RR.SetTable(Dst, true);
        L.W(Dst, 'zz');
        SrcText := L.Rd(Src);
        RrText := L.RdRR(RR);
    end;

    local procedure ShareSetRange(var RrText: Text; var SrcText: Text)
    var
        Src: Record "LT BC4 Row" temporary;
        Dst: Record "LT BC4 Row" temporary;
        Other: Record "LT BC4 Row" temporary;
        RR: RecordRef;
        RR2: RecordRef;
    begin
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        RR.GetTable(Src);
        RR.Field(1).SetRange(10);
        RR.SetTable(Dst, true);
        L.W(Dst, 'zz');
        SrcText := L.Rd(Src);
        RrText := L.RdRR(RR);
    end;

    local procedure ShareReset(var RrText: Text; var SrcText: Text)
    var
        Src: Record "LT BC4 Row" temporary;
        Dst: Record "LT BC4 Row" temporary;
        Other: Record "LT BC4 Row" temporary;
        RR: RecordRef;
        RR2: RecordRef;
    begin
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        RR.GetTable(Src);
        RR.Reset();
        RR.SetTable(Dst, true);
        L.W(Dst, 'zz');
        SrcText := L.Rd(Src);
        RrText := L.RdRR(RR);
    end;

    [Test]
    procedure SetTable_ThenStoredByValue_Source()
    begin
        Observer.Observe('GetTable', RrGetTable());
        Observer.Observe('GetTableSetTable', RrGetTableSetTable());
        Observer.Observe('GetTableSetTableFalse', RrGetTableSetTableFalse());
        Observer.Observe('OpenFindSetTable', RrOpenFindSetTable());
        Observer.Observe('OpenFindCalcSetTable', RrOpenFindCalcSetTable());
        Observer.Observe('OtherGetTableSetTable', RrOtherGetTableSetTable());
        Observer.Observe('FieldValueSetTable', RrFieldValueSetTable());
        Observer.Observe('FieldValueModifySetTable', RrFieldValueModifySetTable());
        Observer.Expect('GetTable', 'hv:alpha');
        Observer.Expect('GetTableSetTable', 'hv:alpha');
        Observer.Expect('GetTableSetTableFalse', 'hv:alpha');
        Observer.Expect('OpenFindSetTable', 'hv:');
        Observer.Expect('OpenFindCalcSetTable', 'hv:alpha');
        Observer.Expect('OtherGetTableSetTable', 'hv:gamma');
        Observer.Expect('FieldValueSetTable', 'hv:gamma');
        Observer.Expect('FieldValueModifySetTable', 'hv:gamma');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableShared_AfterRecordRefCall_Values()
    var
        R: Text;
        W: Text;
    begin
        SharePlain(R, W);
        Observer.Observe('Plain rr', R);
        Observer.Observe('Plain src', W);
        ShareFindCalc(R, W);
        Observer.Observe('FindCalc rr', R);
        Observer.Observe('FindCalc src', W);
        ShareAssigned(R, W);
        Observer.Observe('Assigned rr', R);
        Observer.Observe('Assigned src', W);
        ShareFieldValue(R, W);
        Observer.Observe('FieldValue rr', R);
        Observer.Observe('FieldValue src', W);
        ShareModify(R, W);
        Observer.Observe('Modify rr', R);
        Observer.Observe('Modify src', W);
        ShareInsert(R, W);
        Observer.Observe('Insert rr', R);
        Observer.Observe('Insert src', W);
        ShareSetRange(R, W);
        Observer.Observe('SetRange rr', R);
        Observer.Observe('SetRange src', W);
        ShareReset(R, W);
        Observer.Observe('Reset rr', R);
        Observer.Observe('Reset src', W);
        Observer.Expect('Plain rr', 'hv:alpha');
        Observer.Expect('Plain src', 'hv:alpha');
        Observer.Expect('FindCalc rr', 'hv:alpha');
        Observer.Expect('FindCalc src', 'hv:alpha');
        Observer.Expect('Assigned rr', 'hv:alpha');
        Observer.Expect('Assigned src', 'hv:alpha');
        Observer.Expect('FieldValue rr', 'hv:gamma');
        Observer.Expect('FieldValue src', 'hv:alpha');
        Observer.Expect('Modify rr', 'hv:alpha');
        Observer.Expect('Modify src', 'hv:alpha');
        Observer.Expect('Insert rr', 'hv:alpha');
        Observer.Expect('Insert src', 'hv:alpha');
        Observer.Expect('SetRange rr', 'hv:alpha');
        Observer.Expect('SetRange src', 'hv:alpha');
        Observer.Expect('Reset rr', 'hv:alpha');
        Observer.Expect('Reset src', 'hv:alpha');
        Observer.Verify();
    end;

}

codeunit 97866 "LT BC4 Sequences"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT BC4 Lib";
        Observer: Codeunit "Probe Observer";

    local procedure TakeRec(R: Record "LT BC4 Row")
    begin
        L.W(R, 'zz');
    end;

    local procedure SeqStoredBaseline(): Text
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        B := true;
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqStoredFindFirst(): Text
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        Src.FindFirst();
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqStoredModifyNoArg(): Text
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        Src.Modify();
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqStoredGetNoClear(): Text
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        Src.Get(10);
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqStoredCalcFieldsNoGet(): Text
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        Src.CalcFields(Data);
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqStoredIsTemporary(): Text
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        B := Src.IsTemporary();
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqStoredAssignSource(): Text
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        Other := Src;
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqStoredAssignTarget(): Text
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        L.W(Other, 'gamma');
        Src := Other;
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqStoredClearField(): Text
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        Clear(Src.Data);
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqStoredClearFieldWrite(): Text
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        Clear(Src.Data);
        L.W(Src, 'beta');
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqStoredFieldWrite(): Text
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        Src.Mode := 5;
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqStoredInitWrite(): Text
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        Src.Init();
        L.W(Src, 'beta');
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqStoredModifySubscriber(): Text
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        Src.Mode := 78;
        Src.Modify();
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqStoredVariantOf(): Text
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        V := Src;
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqStoredIsRecord(): Text
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        V := Src;
        B := V.IsRecord();
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqStoredSelectLatestVersion(): Text
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        SelectLatestVersion();
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqTempBaseline(): Text
    var
        Src: Record "LT BC4 Row" temporary;
        Other: Record "LT BC4 Row" temporary;
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        B := true;
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqTempFindFirst(): Text
    var
        Src: Record "LT BC4 Row" temporary;
        Other: Record "LT BC4 Row" temporary;
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        Src.FindFirst();
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqTempModifyNoArg(): Text
    var
        Src: Record "LT BC4 Row" temporary;
        Other: Record "LT BC4 Row" temporary;
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        Src.Modify();
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqTempGetNoClear(): Text
    var
        Src: Record "LT BC4 Row" temporary;
        Other: Record "LT BC4 Row" temporary;
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        Src.Get(10);
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqTempCalcFieldsNoGet(): Text
    var
        Src: Record "LT BC4 Row" temporary;
        Other: Record "LT BC4 Row" temporary;
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        Src.CalcFields(Data);
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqTempIsTemporary(): Text
    var
        Src: Record "LT BC4 Row" temporary;
        Other: Record "LT BC4 Row" temporary;
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        B := Src.IsTemporary();
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqTempAssignSource(): Text
    var
        Src: Record "LT BC4 Row" temporary;
        Other: Record "LT BC4 Row" temporary;
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        Other := Src;
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqTempAssignTarget(): Text
    var
        Src: Record "LT BC4 Row" temporary;
        Other: Record "LT BC4 Row" temporary;
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        L.W(Other, 'gamma');
        Src := Other;
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqTempClearField(): Text
    var
        Src: Record "LT BC4 Row" temporary;
        Other: Record "LT BC4 Row" temporary;
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        Clear(Src.Data);
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqTempClearFieldWrite(): Text
    var
        Src: Record "LT BC4 Row" temporary;
        Other: Record "LT BC4 Row" temporary;
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        Clear(Src.Data);
        L.W(Src, 'beta');
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqTempFieldWrite(): Text
    var
        Src: Record "LT BC4 Row" temporary;
        Other: Record "LT BC4 Row" temporary;
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        Src.Mode := 5;
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqTempInitWrite(): Text
    var
        Src: Record "LT BC4 Row" temporary;
        Other: Record "LT BC4 Row" temporary;
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        Src.Init();
        L.W(Src, 'beta');
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqTempModifySubscriber(): Text
    var
        Src: Record "LT BC4 Row" temporary;
        Other: Record "LT BC4 Row" temporary;
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        Src.Mode := 78;
        Src.Modify();
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqTempVariantOf(): Text
    var
        Src: Record "LT BC4 Row" temporary;
        Other: Record "LT BC4 Row" temporary;
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        V := Src;
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqTempIsRecord(): Text
    var
        Src: Record "LT BC4 Row" temporary;
        Other: Record "LT BC4 Row" temporary;
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        V := Src;
        B := V.IsRecord();
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure SeqTempSelectLatestVersion(): Text
    var
        Src: Record "LT BC4 Row" temporary;
        Other: Record "LT BC4 Row" temporary;
        V: Variant;
        B: Boolean;
    begin
        L.Reset();
        Other.Key1 := 99;
        Other.Insert();
        Src.Key1 := 10;
        L.W(Src, 'alpha');
        Src.Insert();
        SelectLatestVersion();
        TakeRec(Src);
        exit(L.Rd(Src));
    end;

    local procedure CalcIn(R: Record "LT BC4 Row"): Text
    begin
        R.CalcFields(Data);
        exit(L.Rd(R));
    end;

    local procedure HByValueAssignedNeverInserted(var A: Text; var B: Text; var C: Text)
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        Dst: Record "LT BC4 Row";
    begin
        L.Reset();
        Src.Key1 := 10;
        L.W(Other, 'beta');
        Src.Data := Other.Data;
        A := CalcIn(Src);
        B := L.Rd(Src);
        Src.CalcFields(Data);
        C := L.Rd(Src);
    end;

    local procedure HCopyAssignedNeverInserted(var A: Text; var B: Text; var C: Text)
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        Dst: Record "LT BC4 Row";
    begin
        L.Reset();
        Src.Key1 := 10;
        L.W(Other, 'beta');
        Src.Data := Other.Data;
        Dst.Copy(Src);
        Dst.CalcFields(Data);
        A := L.Rd(Dst);
        B := L.Rd(Src);
        Src.CalcFields(Data);
        C := L.Rd(Src);
    end;

    local procedure HByValueAssignedOverStored(var A: Text; var B: Text; var C: Text)
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        Dst: Record "LT BC4 Row";
    begin
        L.Reset();
        L.Prep(Src, 7);
        L.W(Other, 'beta');
        Src.Data := Other.Data;
        A := CalcIn(Src);
        B := L.Rd(Src);
        Src.CalcFields(Data);
        C := L.Rd(Src);
    end;

    local procedure HCopyAssignedOverStored(var A: Text; var B: Text; var C: Text)
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        Dst: Record "LT BC4 Row";
    begin
        L.Reset();
        L.Prep(Src, 7);
        L.W(Other, 'beta');
        Src.Data := Other.Data;
        Dst.Copy(Src);
        Dst.CalcFields(Data);
        A := L.Rd(Dst);
        B := L.Rd(Src);
        Src.CalcFields(Data);
        C := L.Rd(Src);
    end;

    local procedure HByValueAssignedOverStoredGetOnly(var A: Text; var B: Text; var C: Text)
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        Dst: Record "LT BC4 Row";
    begin
        L.Reset();
        L.Prep(Src, 8);
        L.W(Other, 'beta');
        Src.Data := Other.Data;
        A := CalcIn(Src);
        B := L.Rd(Src);
        Src.CalcFields(Data);
        C := L.Rd(Src);
    end;

    local procedure HCopyAssignedOverStoredGetOnly(var A: Text; var B: Text; var C: Text)
    var
        Src: Record "LT BC4 Row";
        Other: Record "LT BC4 Row";
        Dst: Record "LT BC4 Row";
    begin
        L.Reset();
        L.Prep(Src, 8);
        L.W(Other, 'beta');
        Src.Data := Other.Data;
        Dst.Copy(Src);
        Dst.CalcFields(Data);
        A := L.Rd(Dst);
        B := L.Rd(Src);
        Src.CalcFields(Data);
        C := L.Rd(Src);
    end;

    [Test]
    procedure Sequence_StoredMethodThenByValue_Source()
    begin
        Observer.Observe('Baseline', SeqStoredBaseline());
        Observer.Observe('FindFirst', SeqStoredFindFirst());
        Observer.Observe('ModifyNoArg', SeqStoredModifyNoArg());
        Observer.Observe('GetNoClear', SeqStoredGetNoClear());
        Observer.Observe('CalcFieldsNoGet', SeqStoredCalcFieldsNoGet());
        Observer.Observe('IsTemporary', SeqStoredIsTemporary());
        Observer.Observe('AssignSource', SeqStoredAssignSource());
        Observer.Observe('AssignTarget', SeqStoredAssignTarget());
        Observer.Observe('ClearField', SeqStoredClearField());
        Observer.Observe('ClearFieldWrite', SeqStoredClearFieldWrite());
        Observer.Observe('FieldWrite', SeqStoredFieldWrite());
        Observer.Observe('InitWrite', SeqStoredInitWrite());
        Observer.Observe('ModifySubscriber', SeqStoredModifySubscriber());
        Observer.Observe('VariantOf', SeqStoredVariantOf());
        Observer.Observe('IsRecord', SeqStoredIsRecord());
        Observer.Observe('SelectLatestVersion', SeqStoredSelectLatestVersion());
        Observer.Expect('Baseline', 'hv:alpha');
        Observer.Expect('FindFirst', 'hv:');
        Observer.Expect('ModifyNoArg', 'hv:alpha');
        Observer.Expect('GetNoClear', 'hv:');
        Observer.Expect('CalcFieldsNoGet', 'hv:alpha');
        Observer.Expect('IsTemporary', 'hv:alpha');
        Observer.Expect('AssignSource', 'hv:alpha');
        Observer.Expect('AssignTarget', 'hv:gamma');
        Observer.Expect('ClearField', 'nohv:');
        Observer.Expect('ClearFieldWrite', 'hv:beta');
        Observer.Expect('FieldWrite', 'hv:alpha');
        Observer.Expect('InitWrite', 'hv:beta');
        Observer.Expect('ModifySubscriber', 'hv:alpha');
        Observer.Expect('VariantOf', 'hv:alpha');
        Observer.Expect('IsRecord', 'hv:alpha');
        Observer.Expect('SelectLatestVersion', 'hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure Sequence_TempMethodThenByValue_Source()
    begin
        Observer.Observe('Baseline', SeqTempBaseline());
        Observer.Observe('FindFirst', SeqTempFindFirst());
        Observer.Observe('ModifyNoArg', SeqTempModifyNoArg());
        Observer.Observe('GetNoClear', SeqTempGetNoClear());
        Observer.Observe('CalcFieldsNoGet', SeqTempCalcFieldsNoGet());
        Observer.Observe('IsTemporary', SeqTempIsTemporary());
        Observer.Observe('AssignSource', SeqTempAssignSource());
        Observer.Observe('AssignTarget', SeqTempAssignTarget());
        Observer.Observe('ClearField', SeqTempClearField());
        Observer.Observe('ClearFieldWrite', SeqTempClearFieldWrite());
        Observer.Observe('FieldWrite', SeqTempFieldWrite());
        Observer.Observe('InitWrite', SeqTempInitWrite());
        Observer.Observe('ModifySubscriber', SeqTempModifySubscriber());
        Observer.Observe('VariantOf', SeqTempVariantOf());
        Observer.Observe('IsRecord', SeqTempIsRecord());
        Observer.Observe('SelectLatestVersion', SeqTempSelectLatestVersion());
        Observer.Expect('Baseline', 'hv:alpha');
        Observer.Expect('FindFirst', 'hv:');
        Observer.Expect('ModifyNoArg', 'hv:alpha');
        Observer.Expect('GetNoClear', 'hv:');
        Observer.Expect('CalcFieldsNoGet', 'hv:alpha');
        Observer.Expect('IsTemporary', 'hv:alpha');
        Observer.Expect('AssignSource', 'hv:alpha');
        Observer.Expect('AssignTarget', 'hv:gamma');
        Observer.Expect('ClearField', 'nohv:');
        Observer.Expect('ClearFieldWrite', 'hv:beta');
        Observer.Expect('FieldWrite', 'hv:alpha');
        Observer.Expect('InitWrite', 'hv:beta');
        Observer.Expect('ModifySubscriber', 'hv:alpha');
        Observer.Expect('VariantOf', 'hv:alpha');
        Observer.Expect('IsRecord', 'hv:alpha');
        Observer.Expect('SelectLatestVersion', 'hv:alpha');
        Observer.Verify();
    end;

    [Test]
    procedure CalcFields_AfterAssign_ByValueAndCopy()
    var
        A: Text;
        B: Text;
        C: Text;
    begin
        HByValueAssignedNeverInserted(A, B, C);
        Observer.Observe('ByValue AssignedNeverInserted moved', A);
        Observer.Observe('ByValue AssignedNeverInserted src', B);
        Observer.Observe('ByValue AssignedNeverInserted src calc', C);
        HCopyAssignedNeverInserted(A, B, C);
        Observer.Observe('Copy AssignedNeverInserted moved', A);
        Observer.Observe('Copy AssignedNeverInserted src', B);
        Observer.Observe('Copy AssignedNeverInserted src calc', C);
        HByValueAssignedOverStored(A, B, C);
        Observer.Observe('ByValue AssignedOverStored moved', A);
        Observer.Observe('ByValue AssignedOverStored src', B);
        Observer.Observe('ByValue AssignedOverStored src calc', C);
        HCopyAssignedOverStored(A, B, C);
        Observer.Observe('Copy AssignedOverStored moved', A);
        Observer.Observe('Copy AssignedOverStored src', B);
        Observer.Observe('Copy AssignedOverStored src calc', C);
        HByValueAssignedOverStoredGetOnly(A, B, C);
        Observer.Observe('ByValue AssignedOverStoredGetOnly moved', A);
        Observer.Observe('ByValue AssignedOverStoredGetOnly src', B);
        Observer.Observe('ByValue AssignedOverStoredGetOnly src calc', C);
        HCopyAssignedOverStoredGetOnly(A, B, C);
        Observer.Observe('Copy AssignedOverStoredGetOnly moved', A);
        Observer.Observe('Copy AssignedOverStoredGetOnly src', B);
        Observer.Observe('Copy AssignedOverStoredGetOnly src calc', C);
        Observer.Expect('ByValue AssignedNeverInserted moved', 'nohv:');
        Observer.Expect('ByValue AssignedNeverInserted src', 'hv:beta');
        Observer.Expect('ByValue AssignedNeverInserted src calc', 'nohv:');
        Observer.Expect('Copy AssignedNeverInserted moved', 'nohv:');
        Observer.Expect('Copy AssignedNeverInserted src', 'hv:beta');
        Observer.Expect('Copy AssignedNeverInserted src calc', 'nohv:');
        Observer.Expect('ByValue AssignedOverStored moved', 'hv:alpha');
        Observer.Expect('ByValue AssignedOverStored src', 'hv:beta');
        Observer.Expect('ByValue AssignedOverStored src calc', 'hv:alpha');
        Observer.Expect('Copy AssignedOverStored moved', 'hv:alpha');
        Observer.Expect('Copy AssignedOverStored src', 'hv:beta');
        Observer.Expect('Copy AssignedOverStored src calc', 'hv:alpha');
        Observer.Expect('ByValue AssignedOverStoredGetOnly moved', 'hv:alpha');
        Observer.Expect('ByValue AssignedOverStoredGetOnly src', 'hv:beta');
        Observer.Expect('ByValue AssignedOverStoredGetOnly src calc', 'hv:alpha');
        Observer.Expect('Copy AssignedOverStoredGetOnly moved', 'hv:alpha');
        Observer.Expect('Copy AssignedOverStoredGetOnly src', 'hv:beta');
        Observer.Expect('Copy AssignedOverStoredGetOnly src calc', 'hv:alpha');
        Observer.Verify();
    end;

}
