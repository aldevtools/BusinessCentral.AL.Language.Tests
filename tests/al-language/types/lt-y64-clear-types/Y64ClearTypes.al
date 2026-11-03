// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 93301-93306
// Probe (writer Y64, al-runner issue 6656 asks for Clear of a Dialog; the owner rule asks for Clear of every value type): what a variable of each
//   type holds after Clear, when it held a value before. Already pinned: Integer, Text, Boolean, Decimal, Guid, Date, Record, List, Dictionary,
//   TextBuilder (types/TestClearContracts.al), a codeunit variable (misc/lt-probes-needed-2/PnBRecordMisc.al:583), Dialog
//   (pages/lt-page-runtime/P82Dialog.al Y64_*), array rows (types/lt-clear-array-row), Http types (network/lt-uf-http-clear), Xml
//   (xml/lt-ul-clear-ref). Clear of a Label or a TextConst, a literal or an expression is AL0130 (must-not-compile 2628); Clear() and
//   Clear(a, b) are AL0126 (2629).
// BC versions: 27-29

table 93302 "LT Y64 Clear Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { InitValue = 'init'; }
        field(3; Pic; Blob) { }
        field(4; Img; Media) { }
        field(5; Imgs; MediaSet) { }
        field(6; Qty; Decimal) { InitValue = 5; }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

enum 93302 "LT Y64 Clear Enum"
{
    Extensible = false;
    value(0; Zero) { }
    value(1; One) { }
    value(2; Two) { }
}

interface "LT Y64 Clear Answer"
{
    procedure Answer(): Integer;
}

codeunit 93303 "LT Y64 Clear Impl" implements "LT Y64 Clear Answer"
{
    var
        Counter: Integer;

    procedure Answer(): Integer
    begin
        Counter += 1;
        exit(Counter);
    end;
}

query 93306 "LT Y64 Clear Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "LT Y64 Clear Row")
        {
            column(Id; Id) { }
        }
    }
}

codeunit 93301 "LT Y64 Clear Types"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Y64_Clear_Scalars()
    var
        Observer: Codeunit "Probe Observer";
        BI: BigInteger;
        By: Byte;
        Ch: Char;
        C: Code[10];
        Tx: Text[10];
        Tm: Time;
        DT: DateTime;
        Du: Duration;
        O: Option A,B,C;
        E: Enum "LT Y64 Clear Enum";
        DF: DateFormula;
        Ver: Version;
    begin
        BI := 12345678901L;
        By := 7;
        Ch := 'x';
        C := 'ABC';
        Tx := 'abc';
        Tm := 101010T;
        DT := CreateDateTime(20240305D, 101010T);
        Du := 3600000;
        O := O::C;
        E := E::Two;
        Evaluate(DF, '<1M>');
        Ver := Version.Create(1, 2, 3, 4);
        Clear(BI);
        Clear(By);
        Clear(Ch);
        Clear(C);
        Clear(Tx);
        Clear(Tm);
        Clear(DT);
        Clear(Du);
        Clear(O);
        Clear(E);
        Clear(DF);
        Clear(Ver);
        Observer.Observe('BigInteger', Format(BI));
        Observer.Observe('Byte is 0', Format(By = 0));
        Observer.Observe('Char', Format(Ch = 0));
        Observer.Observe('Code', '[' + C + ']');
        Observer.Observe('Text[10]', '[' + Tx + ']');
        Observer.Observe('Time', Format(Tm = 0T));
        Observer.Observe('DateTime', Format(DT = 0DT));
        Observer.Observe('Duration', Format(Du));
        Observer.Observe('Option', Format(O) + '|' + Format(O, 0, 2));
        Observer.Observe('Enum', Format(E) + '|' + Format(E.AsInteger()));
        Observer.Observe('DateFormula', '[' + Format(DF) + ']');
        Observer.Observe('Version', Format(Ver));
        Observer.Expect('BigInteger', '0');
        Observer.Expect('Byte is 0', 'Yes');
        Observer.Expect('Char', 'Yes');
        Observer.Expect('Code', '[]');
        Observer.Expect('Text[10]', '[]');
        Observer.Expect('Time', 'Yes');
        Observer.Expect('DateTime', 'Yes');
        Observer.Expect('Duration', '');
        Observer.Expect('Option', 'A|0');
        Observer.Expect('Enum', 'Zero|0');
        Observer.Expect('DateFormula', '[]');
        Observer.Expect('Version', '0.0.0.0');
        Observer.Verify();
    end;

    [Test]
    procedure Y64_Clear_VariantBigTextSecretRecordId()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y64 Clear Row";
        V: Variant;
        BT: BigText;
        ST: SecretText;
        RId: RecordId;
        Ints: array[3] of Integer;
    begin
        V := 42;
        Clear(V);
        Observer.Observe('Variant IsInteger', Format(V.IsInteger()));
        Observer.Observe('Variant Format', '[' + Format(V) + ']');
        V := Row;
        Clear(V);
        Observer.Observe('Variant IsRecord', Format(V.IsRecord()));
        BT.AddText('hello');
        Clear(BT);
        Observer.Observe('BigText Length', Format(BT.Length()));
        ST := SecretSource();
        Clear(ST);
        Observer.Observe('SecretText IsEmpty', Format(ST.IsEmpty()));
        Row.Id := 1;
        RId := Row.RecordId();
        Clear(RId);
        Observer.Observe('RecordId TableNo', Format(RId.TableNo()));
        Observer.Observe('RecordId Format', '[' + Format(RId) + ']');
        Ints[1] := 1;
        Ints[2] := 2;
        Ints[3] := 3;
        Clear(Ints[2]);
        Observer.Observe('array element', Format(Ints[1]) + Format(Ints[2]) + Format(Ints[3]));
        Clear(Ints);
        Observer.Observe('array', Format(Ints[1]) + Format(Ints[2]) + Format(Ints[3]));
        Observer.Expect('Variant IsInteger', 'No');
        Observer.Expect('Variant Format', '[]');
        Observer.Expect('Variant IsRecord', 'No');
        Observer.Expect('BigText Length', '0');
        Observer.Expect('SecretText IsEmpty', 'Yes');
        Observer.Expect('RecordId TableNo', '0');
        Observer.Expect('RecordId Format', '[]');
        Observer.Expect('array element', '103');
        Observer.Expect('array', '000');
        Observer.Verify();
    end;

    [Test]
    procedure Y64_Clear_RecordFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y64 Clear Row";
        OutS: OutStream;
    begin
        Row.Init();
        Row.Id := 3;
        Row.Name := 'given';
        Row.Qty := 9;
        Row.Pic.CreateOutStream(OutS);
        OutS.WriteText('blob');
        Clear(Row.Name);
        Clear(Row.Qty);
        Clear(Row.Pic);
        Clear(Row.Img);
        Clear(Row.Imgs);
        Observer.Observe('Name', '[' + Row.Name + ']');
        Observer.Observe('Qty', Format(Row.Qty));
        Observer.Observe('Pic HasValue', Format(Row.Pic.HasValue()));
        Observer.Observe('Img HasValue', Format(Row.Img.HasValue()));
        Observer.Observe('Imgs Count', Format(Row.Imgs.Count()));
        Observer.Observe('Id', Format(Row.Id));
        Clear(Row);
        Observer.Observe('Clear(Row) Name', '[' + Row.Name + ']');
        Observer.Observe('Clear(Row) Qty', Format(Row.Qty));
        Observer.Expect('Name', '[]');
        Observer.Expect('Qty', '0');
        Observer.Expect('Pic HasValue', 'No');
        Observer.Expect('Img HasValue', 'No');
        Observer.Expect('Imgs Count', '0');
        Observer.Expect('Id', '3');
        Observer.Expect('Clear(Row) Name', '[init]');
        Observer.Expect('Clear(Row) Qty', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Y64_Clear_JsonTypes()
    var
        Observer: Codeunit "Probe Observer";
        JO: JsonObject;
        JA: JsonArray;
        JT: JsonToken;
        JV: JsonValue;
        Txt: Text;
    begin
        JO.Add('a', 1);
        Clear(JO);
        JO.WriteTo(Txt);
        Observer.Observe('JsonObject', Txt);
        JA.Add(1);
        Clear(JA);
        JA.WriteTo(Txt);
        Observer.Observe('JsonArray', Txt);
        JT.ReadFrom('{"b":2}');
        Clear(JT);
        Observer.Observe('JsonToken IsObject', Format(JT.IsObject()));
        Observer.Observe('JsonToken IsValue', Format(JT.IsValue()));
        JT.WriteTo(Txt);
        Observer.Observe('JsonToken WriteTo', Txt);
        JV.SetValue(5);
        Clear(JV);
        Observer.Observe('JsonValue IsNull', Format(JV.IsNull()));
        Observer.Observe('JsonValue IsUndefined', Format(JV.IsUndefined()));
        JV.WriteTo(Txt);
        Observer.Observe('JsonValue WriteTo', Txt);
        Observer.Expect('JsonObject', '{}');
        Observer.Expect('JsonArray', '[]');
        Observer.Expect('JsonToken IsObject', 'No');
        Observer.Expect('JsonToken IsValue', 'Yes');
        Observer.Expect('JsonToken WriteTo', 'null');
        Observer.Expect('JsonValue IsNull', 'Yes');
        Observer.Expect('JsonValue IsUndefined', 'No');
        Observer.Expect('JsonValue WriteTo', 'null');
        Observer.Verify();
    end;

    [Test]
    procedure Y64_Clear_RecordRefFieldRefNotificationErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        FR: FieldRef;
        KR: KeyRef;
        N: Notification;
        EI: ErrorInfo;
        FPB: FilterPageBuilder;
        MI: ModuleInfo;
    begin
        RR.Open(Database::"LT Y64 Clear Row");
        Clear(RR);
        Observer.Observe('RecordRef Number', Format(RR.Number()));
        RR.Open(Database::"LT Y64 Clear Row");
        FR := RR.Field(2);
        KR := RR.KeyIndex(1);
        Clear(FR);
        Clear(KR);
        Observer.Observe('FieldRef cleared, RecordRef Number', Format(RR.Number()));
        RR.Close();
        N.Message('note');
        N.SetData('k', 'v');
        Clear(N);
        Observer.Observe('Notification Message', '[' + N.Message() + ']');
        Observer.Observe('Notification HasData', Format(N.HasData('k')));
        EI.Message('err');
        EI.Title('title');
        Clear(EI);
        Observer.Observe('ErrorInfo Message', '[' + EI.Message() + ']');
        Observer.Observe('ErrorInfo Title', '[' + EI.Title() + ']');
        FPB.AddTable('Row', Database::"LT Y64 Clear Row");
        Clear(FPB);
        Observer.Observe('FilterPageBuilder Count', Format(FPB.Count()));
        NavApp.GetCurrentModuleInfo(MI);
        Clear(MI);
        Observer.Observe('ModuleInfo Id', Format(MI.Id()));
        Observer.Observe('ModuleInfo Name', '[' + MI.Name() + ']');
        Observer.Expect('RecordRef Number', '0');
        Observer.Expect('FieldRef cleared, RecordRef Number', '93302');
        Observer.Expect('Notification Message', '[]');
        Observer.Expect('Notification HasData', 'No');
        Observer.Expect('ErrorInfo Message', '[]');
        Observer.Expect('ErrorInfo Title', '[]');
        Observer.Expect('FilterPageBuilder Count', '0');
        Observer.Expect('ModuleInfo Id', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('ModuleInfo Name', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure Y64_Clear_InterfaceAndObjectVariables()
    var
        Observer: Codeunit "Probe Observer";
        Impl: Codeunit "LT Y64 Clear Impl";
        Itf: Interface "LT Y64 Clear Answer";
        Qr: Query "LT Y64 Clear Query";
        Row: Record "LT Y64 Clear Row";
    begin
        Itf := Impl;
        Observer.Observe('interface first', Format(Itf.Answer()));
        Clear(Itf);
        ClearLastError();
        Observer.Observe('interface after clear', TryAnswer(Itf));
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Qr.Open();
        Observer.Observe('query read', Format(Qr.Read()));
        Clear(Qr);
        Observer.Observe('query read after clear', TryRead(Qr));
        Qr.Open();
        Observer.Observe('query reopen read', Format(Qr.Read()) + '|' + Format(Qr.Id));
        Qr.Close();
        Observer.Expect('interface first', '1');
        Observer.Expect('interface after clear', 'error:Interface not initialized|InvalidOperation');
        Observer.Expect('query read', 'Yes');
        Observer.Expect('query read after clear', 'ok:No');
        Observer.Expect('query reopen read', 'Yes|1');
        Observer.Verify();
    end;

    [NonDebuggable]
    local procedure SecretSource(): SecretText
    var
        T: Text;
    begin
        T := 'secret';
        exit(T);
    end;

    local procedure TryAnswer(var Itf: Interface "LT Y64 Clear Answer"): Text
    var
        R: Integer;
    begin
        if DoAnswer(Itf, R) then
            exit('ok:' + Format(R));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure DoAnswer(var Itf: Interface "LT Y64 Clear Answer"; var R: Integer)
    begin
        R := Itf.Answer();
    end;

    local procedure TryRead(var Qr: Query "LT Y64 Clear Query"): Text
    var
        R: Boolean;
    begin
        ClearLastError();
        if DoRead(Qr, R) then
            exit('ok:' + Format(R));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure DoRead(var Qr: Query "LT Y64 Clear Query"; var R: Boolean)
    begin
        R := Qr.Read();
    end;
}
