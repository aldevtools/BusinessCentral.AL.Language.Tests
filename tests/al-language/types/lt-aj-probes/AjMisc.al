// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-write-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (Base Application); own tables 79005, 79018, enum 79019
// Facts: Text + Guid concatenation and MaxStrLen of a Guid; an Option compared with a Decimal; the bytes OutStream.Write produces for value types not pinned elsewhere (Code, Option, Enum, DateFormula, RecordId, Variant, Label, BigText, Record, JsonObject); the Field table row of the rowversion field (No. 0, name timestamp) on an own table and on Customer.
// Facts (writer QT): RecordRef on a table with a key over SystemRowVersion (own key or from a tableextension): the FieldIndex walk never meets
//   the rowversion field, Field(0) is timestamp (No. 0, BigInteger, Normal), FieldExist(0) is No, the key's FieldIndex(1) is timestamp No. 0.
//   QT_FieldTable_*: the Field table finds the rowversion row (0:timestamp) only by a FieldName filter (asserted after the Windows check of 2026-10-22).
// Facts (writer RA): the Field table read filtered only on TableNo (and with ObsoleteState <> Removed added) on those tables: which rows, in what order.
// BC versions: 27.5+

table 79005 "LT AJ Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Opt; Option) { OptionMembers = A,B,C; }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 79018 "LT AJ Ts"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

enum 79019 "LT AJ Enum"
{
    Extensible = true;
    value(0; A) { }
    value(7; Seven) { }
}

codeunit 79013 "LT AJ Misc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LabelValue: Label 'Lbl', Locked = true;

    [Test]
    procedure Guid_TextConcatenationAndMaxStrLen()
    var
        G: Guid;
        Empty: Guid;
        T: Text;
        Long: Text[40];
        Cd: Code[40];
    begin
        Evaluate(G, '{11111111-2222-3333-4444-555555555555}');
        T := 'x' + Format(G);
        Observer.Observe('x + Format(G)', T);
        T := 'x' + G;
        Observer.Observe('x + G', T);
        Observer.Observe('x + G length', Format(StrLen(T)));
        T := G + 'x';
        Observer.Observe('G + x', T);
        T := 'x' + Empty;
        Observer.Observe('x + empty guid', T);
        Observer.Observe('MaxStrLen(G)', Format(MaxStrLen(G)));
        Observer.Observe('MaxStrLen(empty)', Format(MaxStrLen(Empty)));
        Long := G;
        Observer.Observe('Text[40] := G', Long);
        Cd := G;
        Observer.Observe('Code[40] := G', Cd);
        Observer.Observe('StrLen(Format(G))', Format(StrLen(Format(G))));
        Observer.Expect('x + Format(G)', 'x{11111111-2222-3333-4444-555555555555}');
        Observer.Expect('x + G', 'x{11111111-2222-3333-4444-555555555555}');
        Observer.Expect('x + G length', '39');
        Observer.Expect('G + x', '{11111111-2222-3333-4444-555555555555}x');
        Observer.Expect('x + empty guid', 'x{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('MaxStrLen(G)', '2147483647');
        Observer.Expect('MaxStrLen(empty)', '2147483647');
        Observer.Expect('Text[40] := G', '{11111111-2222-3333-4444-555555555555}');
        Observer.Expect('Code[40] := G', '{11111111-2222-3333-4444-555555555555}');
        Observer.Expect('StrLen(Format(G))', '38');
        Observer.Verify();
    end;

    [Test]
    procedure Option_ComparedWithDecimal()
    var
        Opt: Option A,B,C;
        Item: Record "LT AJ Item";
    begin
        Opt := Opt::B;
        Observer.Observe('B = 1.0', Format(Opt = 1.0));
        Observer.Observe('B = 1', Format(Opt = 1));
        Observer.Observe('B = 0.0', Format(Opt = 0.0));
        Observer.Observe('B = 1.5', Format(Opt = 1.5));
        Observer.Observe('B <> 1.5', Format(Opt <> 1.5));
        Observer.Observe('B > 0.5', Format(Opt > 0.5));
        Observer.Observe('B > 1.0', Format(Opt > 1.0));
        Observer.Observe('B >= 1.0', Format(Opt >= 1.0));
        Observer.Observe('B < 1.5', Format(Opt < 1.5));
        Observer.Observe('B < 1.0', Format(Opt < 1.0));
        Observer.Observe('B <= 0.9', Format(Opt <= 0.9));
        Observer.Observe('0.5 < B', Format(0.5 < Opt));
        Observer.Observe('1.0 = B', Format(1.0 = Opt));
        Item.Opt := Item.Opt::C;
        Observer.Observe('field C = 2.0', Format(Item.Opt = 2.0));
        Observer.Observe('field C > 1.5', Format(Item.Opt > 1.5));
        Observer.Observe('field C = 2.5', Format(Item.Opt = 2.5));
        Observer.Observe('field C < 2.5', Format(Item.Opt < 2.5));
        Observer.Expect('B = 1.0', 'Yes');
        Observer.Expect('B = 1', 'Yes');
        Observer.Expect('B = 0.0', 'No');
        Observer.Expect('B = 1.5', 'No');
        Observer.Expect('B <> 1.5', 'Yes');
        Observer.Expect('B > 0.5', 'Yes');
        Observer.Expect('B > 1.0', 'No');
        Observer.Expect('B >= 1.0', 'Yes');
        Observer.Expect('B < 1.5', 'Yes');
        Observer.Expect('B < 1.0', 'No');
        Observer.Expect('B <= 0.9', 'No');
        Observer.Expect('0.5 < B', 'Yes');
        Observer.Expect('1.0 = B', 'Yes');
        Observer.Expect('field C = 2.0', 'Yes');
        Observer.Expect('field C > 1.5', 'Yes');
        Observer.Expect('field C = 2.5', 'No');
        Observer.Expect('field C < 2.5', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure OutStream_Write_Code_Option_Enum_DateFormula()
    var
        C: Code[10];
        Opt: Option A,B,C;
        E: Enum "LT AJ Enum";
        DF: DateFormula;
        Tmp: Codeunit "Temp Blob";
    begin
        C := 'ab';
        Observer.Observe('Code[10] ab', Dump(Tmp, 'Code', C));
        Opt := Opt::C;
        Observer.Observe('Option C', Dump(Tmp, 'Option', Opt));
        E := E::Seven;
        Observer.Observe('Enum Seven', Dump(Tmp, 'Enum', E.AsInteger()));
        Evaluate(DF, '<1M>');
        Observer.Observe('DateFormula 1M', Dump(Tmp, 'DateFormula', DF));
        Observer.Expect('Code[10] ab', '3:41 42 00 ');
        Observer.Expect('Option C', '4:02 00 00 00 ');
        Observer.Expect('Enum Seven', '4:07 00 00 00 ');
        Observer.Expect('DateFormula 1M', '32:31 05 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ');
        Observer.Verify();
    end;

    [Test]
    procedure OutStream_Write_RecordId_And_Label()
    var
        RId: RecordId;
        Cu: Record "LT AJ Item";
        Tmp: Codeunit "Temp Blob";
    begin
        Cu.Id := 5;
        RId := Cu.RecordId();
        Observer.Observe('RecordId', Dump(Tmp, 'RecordId', RId));
        Clear(RId);
        Observer.Observe('RecordId empty', Dump(Tmp, 'RecordId', RId));
        Observer.Observe('Label', Dump(Tmp, 'Label', LabelValue));
        Observer.Expect('RecordId', 'err:ALStream.ALWrite, invalid stream mode: Stream|InvalidStreamMode');
        Observer.Expect('RecordId empty', 'err:ALStream.ALWrite, invalid stream mode: Stream|InvalidStreamMode');
        Observer.Expect('Label', '4:4C 62 6C 00 ');
        Observer.Verify();
    end;

    [Test]
    procedure OutStream_Write_Variant()
    var
        V: Variant;
        Tmp: Codeunit "Temp Blob";
    begin
        V := 42;
        Observer.Observe('Variant 42', Dump(Tmp, 'Variant', V));
        V := 'hi';
        Observer.Observe('Variant hi', Dump(Tmp, 'Variant', V));
        V := 1.5;
        Observer.Observe('Variant 1.5', Dump(Tmp, 'Variant', V));
        V := true;
        Observer.Observe('Variant true', Dump(Tmp, 'Variant', V));
        Clear(V);
        Observer.Observe('Variant empty', Dump(Tmp, 'Variant', V));
        Observer.Expect('Variant 42', '4:2A 00 00 00 ');
        Observer.Expect('Variant hi', '3:68 69 00 ');
        Observer.Expect('Variant 1.5', '12:40 00 00 00 00 00 00 00 00 15 00 00 ');
        Observer.Expect('Variant true', '4:01 00 00 00 ');
        Observer.Expect('Variant empty', 'err:The type Variant is not supported.|NotSupportedType');
        Observer.Verify();
    end;

    [Test]
    procedure OutStream_Write_BigText_Record_JsonObject()
    var
        Bt: BigText;
        Cu: Record "LT AJ Item";
        Jo: JsonObject;
        Tmp: Codeunit "Temp Blob";
    begin
        Bt.AddText('abc');
        Observer.Observe('BigText abc', Dump(Tmp, 'BigText', Bt));
        Cu.Id := 5;
        Cu.Txt := 'q';
        Observer.Observe('Record', Dump(Tmp, 'Record', Cu));
        Jo.ReadFrom('{"a":1}');
        Observer.Observe('JsonObject', Dump(Tmp, 'JsonObject', Jo));
        Observer.Expect('BigText abc', 'err:ALStream.ALWrite, invalid stream mode: Stream|InvalidStreamMode');
        Observer.Expect('Record', 'err:ALStream.ALWrite, invalid stream mode: Stream|InvalidStreamMode');
        Observer.Expect('JsonObject', 'err:The type JsonObject is not supported.|NotSupportedType');
        Observer.Verify();
    end;

    local procedure Dump(var Tmp: Codeunit "Temp Blob"; Kind: Text; Value: Variant): Text
    var
        Result: Text;
    begin
        Clear(Tmp);
        ClearLastError();
        if not TryWrite(Tmp, Kind, Value) then
            exit('err:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Result := Hex(Tmp);
        exit(Result);
    end;

    [TryFunction]
    local procedure TryWrite(var Tmp: Codeunit "Temp Blob"; Kind: Text; Value: Variant)
    var
        O: OutStream;
        C: Code[10];
        Opt: Option A,B,C;
        E: Enum "LT AJ Enum";
        DF: DateFormula;
        RId: RecordId;
        Bt: BigText;
        Cu: Record "LT AJ Item";
        Jo: JsonObject;
        Txt: Text;
        Ordinal: Integer;
    begin
        Tmp.CreateOutStream(O);
        case Kind of
            'Code':
                begin
                    C := Value;
                    O.Write(C);
                end;
            'Option':
                begin
                    Opt := Value;
                    O.Write(Opt);
                end;
            'Enum':
                begin
                    Ordinal := Value;
                    E := Enum::"LT AJ Enum".FromInteger(Ordinal);
                    O.Write(E);
                end;
            'DateFormula':
                begin
                    DF := Value;
                    O.Write(DF);
                end;
            'RecordId':
                begin
                    RId := Value;
                    O.Write(RId);
                end;
            'Variant':
                O.Write(Value);
            'Label':
                begin
                    Txt := Value;
                    O.Write(LabelValue);
                end;
            'BigText':
                begin
                    Bt := Value;
                    O.Write(Bt);
                end;
            'Record':
                begin
                    Cu := Value;
                    O.Write(Cu);
                end;
            'JsonObject':
                begin
                    Jo := Value;
                    O.Write(Jo);
                end;
        end;
    end;

    local procedure Hex(var Tmp: Codeunit "Temp Blob"): Text
    var
        I: InStream;
        B: Byte;
        Digits: Text;
        Result: Text;
        Count: Integer;
    begin
        Digits := '0123456789ABCDEF';
        Tmp.CreateInStream(I);
        while (not I.EOS()) and (Count < 200) do begin
            I.Read(B);
            Result += CopyStr(Digits, (B div 16) + 1, 1) + CopyStr(Digits, (B mod 16) + 1, 1) + ' ';
            Count += 1;
        end;
        exit(Format(Count) + ':' + Result);
    end;

    [Test]
    procedure FieldTable_OwnTable_AllRows()
    begin
        Observer.Observe('Get(0)', Describe(Database::"LT AJ Ts", 0));
        Observer.Observe('rows', ListRows(Database::"LT AJ Ts", ''));
        Observer.Expect('Get(0)', 'not found');
        Observer.Expect('rows', '1:Id:Integer:Normal:4;2:Txt:Text:Normal:30;2000000000:$systemId:GUID:Normal:16;2000000001:SystemCreatedAt:DateTime:Normal:8;2000000002:SystemCreatedBy:GUID:Normal:16;2000000003:SystemModifiedAt:DateTime:Normal:8;2000000004:SystemModifiedBy:GUID:Normal:16;');
        Observer.Verify();
    end;

    [Test]
    procedure FieldTable_Customer_RowVersionField()
    var
        Fld: Record Field;
    begin
        Observer.Observe('Get(0)', Describe(Database::Customer, 0));
        Observer.Observe('by name timestamp', ListRows(Database::Customer, 'timestamp'));
        Fld.SetRange(TableNo, Database::Customer);
        Fld.SetRange("No.", 0);
        Observer.Observe('No. = 0 count', Format(Fld.Count()));
        Observer.Expect('Get(0)', 'not found');
        Observer.Expect('by name timestamp', '0:timestamp:BigInteger:Normal:8;');
        Observer.Expect('No. = 0 count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure FieldTable_Customer_FirstRows()
    var
        Fld: Record Field;
        Seen: Text;
        Index: Integer;
    begin
        Fld.SetRange(TableNo, Database::Customer);
        Fld.SetCurrentKey(TableNo, "No.");
        if Fld.FindSet() then
            repeat
                Index += 1;
                if Index <= 3 then
                    Seen += Format(Fld."No.") + ':' + Fld.FieldName + ';';
            until Fld.Next() = 0;
        Observer.Observe('first three', Seen);
        Observer.Expect('first three', '1:No.;2:Name;3:Search Name;');
        Observer.Verify();
    end;

    local procedure ListRows(TableNumber: Integer; NameFilter: Text): Text
    var
        Fld: Record Field;
        Result: Text;
    begin
        Fld.SetRange(TableNo, TableNumber);
        if TableNumber = Database::"LT AJ Ts" then
            Fld.SetFilter("No.", '<2000000005'); // the four FlowField system fields 2000000005..8 exist only from BC 28
        if NameFilter <> '' then
            Fld.SetRange(FieldName, NameFilter);
        if Fld.FindSet() then
            repeat
                Result += Format(Fld."No.") + ':' + Fld.FieldName + ':' + Format(Fld.Type) + ':' + Format(Fld.Class) + ':' + Format(Fld.Len) + ';';
            until Fld.Next() = 0;
        exit(Result);
    end;

    local procedure Describe(TableNumber: Integer; FieldNumber: Integer): Text
    var
        Fld: Record Field;
    begin
        if not Fld.Get(TableNumber, FieldNumber) then
            exit('not found');
        exit(StrSubstNo('TableNo=%1|No=%2|Name=%3|Type=%4|Class=%5|Len=%6|Enabled=%7|Obsolete=%8', Fld.TableNo, Fld."No.", Fld.FieldName, Fld.Type, Fld.Class, Fld.Len, Fld.Enabled, Fld.ObsoleteState));
    end;

    // ---- Writer QT (2026-10-22, al-runtime-rs PR 5658): the Field table and RecordRef on tables with a key over SystemRowVersion: "KRV Row"
    // (own key RowVersionKey), "KRV Modified Row" (own key, plus a tableextension that modifies a field) and "Customer Bank Account" (key added
    // by tableextension "KRV Bank Account Ext"); "LT AJ Ts" (no such key) as the control. Fixtures in recordref/TestKeyMetadataRowVersionRemoved.Fixtures.al. ----

    local procedure QtRowVersionRows(TableNumber: Integer): Text
    var
        Fld: Record Field;
        Result: Text;
    begin
        Fld.SetRange(TableNo, TableNumber);
        Fld.SetRange(FieldName, 'timestamp');
        if Fld.FindSet() then
            repeat
                Result += Format(Fld."No.") + ':' + Fld.FieldName + ':' + Format(Fld.Type) + ':' + Format(Fld.Class) + ':' + Format(Fld.Len) + ':' + Format(Fld.Enabled) + ';';
            until Fld.Next() = 0;
        exit(Result);
    end;

    local procedure QtFieldTableAnswers(TableNumber: Integer)
    var
        Fld: Record Field;
    begin
        Observer.Observe('Get(table, 0)', Describe(TableNumber, 0));
        Observer.Observe('by name timestamp', QtRowVersionRows(TableNumber));
        Fld.SetRange(TableNo, TableNumber);
        Fld.SetRange("No.", 0);
        Observer.Observe('No. = 0 count', Format(Fld.Count()));
        Fld.SetRange("No.");
        Fld.SetRange(Type, Fld.Type::BigInteger);
        Observer.Observe('BigInteger count', Format(Fld.Count()));
        Fld.SetRange(Type);
        Fld.SetRange(FieldName, 'SystemRowVersion');
        Observer.Observe('by name SystemRowVersion count', Format(Fld.Count()));
    end;

    local procedure QtRecordRefAnswers(TableNumber: Integer)
    var
        Fld: Record Field;
        RecRef: RecordRef;
        FldRef: FieldRef;
        KRef: KeyRef;
        Index: Integer;
        Found: Text;
    begin
        RecRef.Open(TableNumber);
        for Index := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(Index);
            if (FldRef.Name() = 'timestamp') or (FldRef.Number() = 0) then
                Found += Format(Index) + ':' + FldRef.Name() + '#' + Format(FldRef.Number()) + ';';
        end;
        Observer.Observe('FieldIndex walk finds timestamp', '[' + Found + ']');
        FldRef := RecRef.Field(0);
        Observer.Observe('Field(0)', FldRef.Name() + '#' + Format(FldRef.Number()) + '#' + Format(FldRef.Type()) + '#' + Format(FldRef.Class()));
        Observer.Observe('FieldExist(0)', Format(RecRef.FieldExist(0)));
        Found := '';
        for Index := 1 to RecRef.KeyCount() do begin
            KRef := RecRef.KeyIndex(Index);
            if KRef.FieldIndex(1).Name() = 'timestamp' then
                Found += Format(Index) + ':' + KRef.FieldIndex(1).Name() + '#' + Format(KRef.FieldIndex(1).Number()) + '#' + Format(KRef.FieldCount()) + ';';
        end;
        Observer.Observe('key on rowversion', '[' + Found + ']');
        Fld.SetRange(TableNo, TableNumber);
        Fld.SetRange(FieldName, 'timestamp');
        if Fld.FindFirst() then begin
            FldRef := RecRef.Field(Fld."No.");
            Observer.Observe('Field(No. of the timestamp row)', FldRef.Name() + '#' + Format(FldRef.Number()));
        end else
            Observer.Observe('Field(No. of the timestamp row)', 'no row');
        RecRef.Close();
    end;

    [Test]
    procedure QT_FieldTable_OwnKeyOnRowVersion()
    begin
        QtFieldTableAnswers(Database::"KRV Row");
        // The Field table answers the rowversion row (0:timestamp) only to a FieldName filter, not to Get(table, 0) or a No. filter.
        // Windows containers 27.5, 28.5 and 29.0 gave the same values as Linux (Windows check, 2026-10-22).
        Observer.Expect('Get(table, 0)', 'not found');
        Observer.Expect('by name timestamp', '0:timestamp:BigInteger:Normal:8:Yes;');
        Observer.Expect('No. = 0 count', '0');
        Observer.Expect('BigInteger count', '0');
        Observer.Expect('by name SystemRowVersion count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure QT_FieldTable_OwnKeyOnRowVersion_TableWithModifyExtension()
    begin
        QtFieldTableAnswers(Database::"KRV Modified Row");
        // The Field table answers the rowversion row (0:timestamp) only to a FieldName filter, not to Get(table, 0) or a No. filter.
        // Windows containers 27.5, 28.5 and 29.0 gave the same values as Linux (Windows check, 2026-10-22).
        Observer.Expect('Get(table, 0)', 'not found');
        Observer.Expect('by name timestamp', '0:timestamp:BigInteger:Normal:8:Yes;');
        Observer.Expect('No. = 0 count', '0');
        Observer.Expect('BigInteger count', '0');
        Observer.Expect('by name SystemRowVersion count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure QT_FieldTable_KeyOnRowVersionFromTableExtension()
    begin
        QtFieldTableAnswers(Database::"Customer Bank Account");
        // The Field table answers the rowversion row (0:timestamp) only to a FieldName filter, not to Get(table, 0) or a No. filter.
        // Windows containers 27.5, 28.5 and 29.0 gave the same values as Linux (Windows check, 2026-10-22).
        Observer.Expect('Get(table, 0)', 'not found');
        Observer.Expect('by name timestamp', '0:timestamp:BigInteger:Normal:8:Yes;');
        Observer.Expect('No. = 0 count', '0');
        Observer.Expect('BigInteger count', '0');
        Observer.Expect('by name SystemRowVersion count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure QT_FieldTable_NoKeyOnRowVersion_Control()
    begin
        QtFieldTableAnswers(Database::"LT AJ Ts");
        // The Field table answers the rowversion row (0:timestamp) only to a FieldName filter, not to Get(table, 0) or a No. filter.
        // Windows containers 27.5, 28.5 and 29.0 gave the same values as Linux (Windows check, 2026-10-22).
        Observer.Expect('Get(table, 0)', 'not found');
        Observer.Expect('by name timestamp', '0:timestamp:BigInteger:Normal:8:Yes;');
        Observer.Expect('No. = 0 count', '0');
        Observer.Expect('BigInteger count', '0');
        Observer.Expect('by name SystemRowVersion count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure QT_RecordRef_OwnKeyOnRowVersion()
    begin
        QtRecordRefAnswers(Database::"KRV Row");
        Observer.Expect('FieldIndex walk finds timestamp', '[]');
        Observer.Expect('Field(0)', 'timestamp#0#BigInteger#Normal');
        Observer.Expect('FieldExist(0)', 'No');
        Observer.Expect('key on rowversion', '[2:timestamp#0#1;]');
        Observer.Expect('Field(No. of the timestamp row)', 'timestamp#0');
        Observer.Verify();
    end;

    [Test]
    procedure QT_RecordRef_KeyOnRowVersionFromTableExtension()
    begin
        QtRecordRefAnswers(Database::"Customer Bank Account");
        Observer.Expect('FieldIndex walk finds timestamp', '[]');
        Observer.Expect('Field(0)', 'timestamp#0#BigInteger#Normal');
        Observer.Expect('FieldExist(0)', 'No');
        Observer.Expect('key on rowversion', '[2:timestamp#0#1;]');
        Observer.Expect('Field(No. of the timestamp row)', 'timestamp#0');
        Observer.Verify();
    end;

    [Test]
    procedure QT_RecordRef_NoKeyOnRowVersion_Control()
    begin
        QtRecordRefAnswers(Database::"LT AJ Ts");
        Observer.Expect('FieldIndex walk finds timestamp', '[]');
        Observer.Expect('Field(0)', 'timestamp#0#BigInteger#Normal');
        Observer.Expect('FieldExist(0)', 'No');
        Observer.Expect('key on rowversion', '[]');
        Observer.Expect('Field(No. of the timestamp row)', 'timestamp#0');
        Observer.Verify();
    end;

    // ---- Writer RA (2026-10-22): the Field table read filtered only on TableNo, FindSet loop, on tables with a key over SystemRowVersion and the
    // control: count, then each row as No.:FieldName:ObsoleteState in the order FindSet gives (a table with more than 15 rows: the first 3 rows,
    // the position of the timestamp row, the last 8 rows, and whether the No. values ascend). The same with ObsoleteState <> Removed added. ----

    local procedure RaFieldScan(TableNumber: Integer; WithoutRemoved: Boolean): Text
    var
        Fld: Record Field;
        Rows: List of [Text];
        Row: Text;
        Result: Text;
        TimestampAt: Integer;
        PrevNo: Integer;
        Ascending: Boolean;
        Index: Integer;
    begin
        Fld.SetRange(TableNo, TableNumber);
        if WithoutRemoved then
            Fld.SetFilter(ObsoleteState, '<>%1', Fld.ObsoleteState::Removed);
        Ascending := true;
        PrevNo := -1;
        if Fld.FindSet() then
            repeat
                Rows.Add(Format(Fld."No.") + ':' + Fld.FieldName + ':' + Format(Fld.ObsoleteState));
                if (Fld.FieldName = 'timestamp') and (TimestampAt = 0) then
                    TimestampAt := Rows.Count();
                if Fld."No." <= PrevNo then
                    Ascending := false;
                PrevNo := Fld."No.";
            until Fld.Next() = 0;
        Result := 'count=' + Format(Fld.Count()) + '|rows=' + Format(Rows.Count()) + '|timestamp at=' + Format(TimestampAt) + '|ascending=' + Format(Ascending) + '|';
        if Rows.Count() <= 15 then begin
            foreach Row in Rows do
                Result += Row + ';';
            exit(Result);
        end;
        for Index := 1 to 3 do
            Result += Rows.Get(Index) + ';';
        Result += '...;';
        for Index := Rows.Count() - 7 to Rows.Count() do
            Result += Rows.Get(Index) + ';';
        exit(Result);
    end;

    local procedure RaObserveScans(TableNumber: Integer)
    begin
        Observer.Observe('TableNo only', RaFieldScan(TableNumber, false));
        Observer.Observe('TableNo and ObsoleteState <> Removed', RaFieldScan(TableNumber, true));
    end;

    [Test]
    procedure RA_FieldTable_ScanByTableNo_OwnKeyOnRowVersion()
    begin
        RaObserveScans(Database::"KRV Row");
#if BC29PLUS
        Observer.Expect('TableNo only', 'count=13|rows=13|timestamp at=0|ascending=Yes|1:Code:No;2:Live Value:No;3:Pending Value:Pending;4:Removed Value:Removed;2000000000:$systemId:No;2000000001:SystemCreatedAt:No;2000000002:SystemCreatedBy:No;2000000003:SystemModifiedAt:No;2000000004:SystemModifiedBy:No;2000000005:SystemCreatedByUserName:No;2000000006:SystemCreatedByFullName:No;2000000007:SystemModifiedByUserName:No;2000000008:SystemModifiedByFullName:No;');
        Observer.Expect('TableNo and ObsoleteState <> Removed', 'count=12|rows=12|timestamp at=0|ascending=Yes|1:Code:No;2:Live Value:No;3:Pending Value:Pending;2000000000:$systemId:No;2000000001:SystemCreatedAt:No;2000000002:SystemCreatedBy:No;2000000003:SystemModifiedAt:No;2000000004:SystemModifiedBy:No;2000000005:SystemCreatedByUserName:No;2000000006:SystemCreatedByFullName:No;2000000007:SystemModifiedByUserName:No;2000000008:SystemModifiedByFullName:No;');
#else
        Observer.Expect('TableNo only', 'count=9|rows=9|timestamp at=0|ascending=Yes|1:Code:No;2:Live Value:No;3:Pending Value:Pending;4:Removed Value:Removed;2000000000:$systemId:No;2000000001:SystemCreatedAt:No;2000000002:SystemCreatedBy:No;2000000003:SystemModifiedAt:No;2000000004:SystemModifiedBy:No;');
        Observer.Expect('TableNo and ObsoleteState <> Removed', 'count=8|rows=8|timestamp at=0|ascending=Yes|1:Code:No;2:Live Value:No;3:Pending Value:Pending;2000000000:$systemId:No;2000000001:SystemCreatedAt:No;2000000002:SystemCreatedBy:No;2000000003:SystemModifiedAt:No;2000000004:SystemModifiedBy:No;');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure RA_FieldTable_ScanByTableNo_KeyOnRowVersionFromTableExtension()
    begin
        RaObserveScans(Database::"Customer Bank Account");
#if BC29PLUS
        Observer.Expect('TableNo only', 'count=35|rows=35|timestamp at=0|ascending=Yes|1:Customer No.:No;2:Code:No;3:Name:No;...;2000000001:SystemCreatedAt:No;2000000002:SystemCreatedBy:No;2000000003:SystemModifiedAt:No;2000000004:SystemModifiedBy:No;2000000005:SystemCreatedByUserName:No;2000000006:SystemCreatedByFullName:No;2000000007:SystemModifiedByUserName:No;2000000008:SystemModifiedByFullName:No;');
        Observer.Expect('TableNo and ObsoleteState <> Removed', 'count=35|rows=35|timestamp at=0|ascending=Yes|1:Customer No.:No;2:Code:No;3:Name:No;...;2000000001:SystemCreatedAt:No;2000000002:SystemCreatedBy:No;2000000003:SystemModifiedAt:No;2000000004:SystemModifiedBy:No;2000000005:SystemCreatedByUserName:No;2000000006:SystemCreatedByFullName:No;2000000007:SystemModifiedByUserName:No;2000000008:SystemModifiedByFullName:No;');
#else
        Observer.Expect('TableNo only', 'count=31|rows=31|timestamp at=0|ascending=Yes|1:Customer No.:No;2:Code:No;3:Name:No;...;25:SWIFT Code:No;1211:Bank Clearing Code:No;1212:Bank Clearing Standard:No;2000000000:$systemId:No;2000000001:SystemCreatedAt:No;2000000002:SystemCreatedBy:No;2000000003:SystemModifiedAt:No;2000000004:SystemModifiedBy:No;');
        Observer.Expect('TableNo and ObsoleteState <> Removed', 'count=31|rows=31|timestamp at=0|ascending=Yes|1:Customer No.:No;2:Code:No;3:Name:No;...;25:SWIFT Code:No;1211:Bank Clearing Code:No;1212:Bank Clearing Standard:No;2000000000:$systemId:No;2000000001:SystemCreatedAt:No;2000000002:SystemCreatedBy:No;2000000003:SystemModifiedAt:No;2000000004:SystemModifiedBy:No;');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure RA_FieldTable_ScanByTableNo_NoKeyOnRowVersion_Control()
    begin
        RaObserveScans(Database::"LT AJ Ts");
#if BC29PLUS
        Observer.Expect('TableNo only', 'count=11|rows=11|timestamp at=0|ascending=Yes|1:Id:No;2:Txt:No;2000000000:$systemId:No;2000000001:SystemCreatedAt:No;2000000002:SystemCreatedBy:No;2000000003:SystemModifiedAt:No;2000000004:SystemModifiedBy:No;2000000005:SystemCreatedByUserName:No;2000000006:SystemCreatedByFullName:No;2000000007:SystemModifiedByUserName:No;2000000008:SystemModifiedByFullName:No;');
        Observer.Expect('TableNo and ObsoleteState <> Removed', 'count=11|rows=11|timestamp at=0|ascending=Yes|1:Id:No;2:Txt:No;2000000000:$systemId:No;2000000001:SystemCreatedAt:No;2000000002:SystemCreatedBy:No;2000000003:SystemModifiedAt:No;2000000004:SystemModifiedBy:No;2000000005:SystemCreatedByUserName:No;2000000006:SystemCreatedByFullName:No;2000000007:SystemModifiedByUserName:No;2000000008:SystemModifiedByFullName:No;');
#else
        Observer.Expect('TableNo only', 'count=7|rows=7|timestamp at=0|ascending=Yes|1:Id:No;2:Txt:No;2000000000:$systemId:No;2000000001:SystemCreatedAt:No;2000000002:SystemCreatedBy:No;2000000003:SystemModifiedAt:No;2000000004:SystemModifiedBy:No;');
        Observer.Expect('TableNo and ObsoleteState <> Removed', 'count=7|rows=7|timestamp at=0|ascending=Yes|1:Id:No;2:Txt:No;2000000000:$systemId:No;2000000001:SystemCreatedAt:No;2000000002:SystemCreatedBy:No;2000000003:SystemModifiedAt:No;2000000004:SystemModifiedBy:No;');
#endif
        Observer.Verify();
    end;

    // ---- Writer SG (2026-10-27): every column of the Field row of the rowversion field (timestamp) found by TableNo + FieldName, the lookups
    // that combine the name with other filters (ObsoleteState, Type, Class, a case-insensitive name filter), the name alone (no TableNo), and
    // Base Application's Data Type Management.FindFieldByName on a RecordRef. ----

    local procedure SgAllColumns(var Fld: Record Field): Text
    begin
        exit(StrSubstNo('TableNo=%1|No=%2|TableName=%3|FieldName=%4|Type=%5|Len=%6|Class=%7|Enabled=%8|TypeName=%9', Fld.TableNo, Fld."No.", Fld.TableName, Fld.FieldName, Fld.Type, Fld.Len, Fld.Class, Fld.Enabled, Fld."Type Name") +
            StrSubstNo('|Caption=%1|RelationTableNo=%2|RelationFieldNo=%3|SQLDataType=%4|OptionString=%5|ObsoleteState=%6|ObsoleteReason=%7|DataClassification=%8|IsPartOfPrimaryKey=%9', Fld."Field Caption", Fld.RelationTableNo, Fld.RelationFieldNo, Fld.SQLDataType, Fld.OptionString, Fld.ObsoleteState, Fld.ObsoleteReason, Fld.DataClassification, Fld.IsPartOfPrimaryKey));
    end;

    local procedure SgFound(var Fld: Record Field): Text
    begin
        if not Fld.FindFirst() then
            exit('none');
        exit(Format(Fld.Count()) + ':' + Format(Fld."No.") + ':' + Fld.FieldName);
    end;

    [Test]
    procedure SG_FieldTable_RowVersion_AllColumns()
    var
        Fld: Record Field;
    begin
        Fld.SetRange(TableNo, Database::Customer);
        Fld.SetRange(FieldName, 'timestamp');
        if Fld.FindFirst() then
            Observer.Observe('customer', SgAllColumns(Fld))
        else
            Observer.Observe('customer', 'none');
        Fld.SetRange(TableNo, Database::"LT AJ Ts");
        if Fld.FindFirst() then
            Observer.Observe('own table', SgAllColumns(Fld))
        else
            Observer.Observe('own table', 'none');
        Observer.Finish();
    end;

    [Test]
    procedure SG_FieldTable_RowVersion_NameWithOtherFilters()
    var
        Fld: Record Field;
    begin
        Fld.SetRange(TableNo, Database::Customer);
        Fld.SetRange(FieldName, 'timestamp');
        Fld.SetRange(ObsoleteState, Fld.ObsoleteState::No);
        Observer.Observe('name + ObsoleteState No', SgFound(Fld));
        Fld.SetFilter(ObsoleteState, '<>%1', Fld.ObsoleteState::Removed);
        Observer.Observe('name + ObsoleteState <> Removed', SgFound(Fld));
        Fld.SetRange(ObsoleteState);
        Fld.SetRange(Type, Fld.Type::BigInteger);
        Observer.Observe('name + Type BigInteger', SgFound(Fld));
        Fld.SetRange(Type);
        Fld.SetRange(Class, Fld.Class::Normal);
        Observer.Observe('name + Class Normal', SgFound(Fld));
        Fld.SetRange(Class);
        Fld.SetRange(Enabled, true);
        Observer.Observe('name + Enabled', SgFound(Fld));
        Fld.Reset();
        Fld.SetRange(TableNo, Database::Customer);
        Fld.SetFilter(FieldName, '@TIMESTAMP');
        Observer.Observe('case-insensitive name filter', SgFound(Fld));
        Fld.SetFilter(FieldName, 'times*');
        Observer.Observe('wildcard name filter', SgFound(Fld));
        Fld.SetFilter(FieldName, 'timestamp|No.');
        Observer.Observe('name or another name', SgFound(Fld));
        Fld.Reset();
        Fld.SetRange(TableNo, Database::Customer);
        Fld.SetRange(Type, Fld.Type::BigInteger);
        Observer.Observe('TableNo + Type BigInteger, no name', SgFound(Fld));
        Observer.Finish();
    end;

    [Test]
    procedure SG_FieldTable_RowVersion_NameAlone()
    var
        Fld: Record Field;
    begin
        Fld.SetRange(FieldName, 'timestamp');
        Observer.Observe('name alone is empty', Format(Fld.IsEmpty()));
        Fld.SetRange(TableNo, Database::Customer, Database::Customer);
        Observer.Observe('name + TableNo range of one', SgFound(Fld));
        Fld.SetFilter(TableNo, '%1|%2', Database::Customer, Database::"LT AJ Ts");
        Observer.Observe('name + two tables', SgFound(Fld));
        Observer.Finish();
    end;

    [Test]
    procedure SG_FieldTable_RowVersion_FindFieldByName()
    var
        DataTypeMgt: Codeunit "Data Type Management";
        RecRef: RecordRef;
        FRef: FieldRef;
    begin
        RecRef.Open(Database::Customer);
        Observer.Observe('customer found', Format(DataTypeMgt.FindFieldByName(RecRef, FRef, 'timestamp')));
        Observer.Observe('customer field', Format(FRef.Number) + ':' + FRef.Name + ':' + Format(FRef.Type) + ':' + Format(FRef.Class));
        RecRef.Close();
        RecRef.Open(Database::"LT AJ Ts");
        Observer.Observe('own found', Format(DataTypeMgt.FindFieldByName(RecRef, FRef, 'timestamp')));
        Observer.Observe('own field', Format(FRef.Number) + ':' + FRef.Name + ':' + Format(FRef.Type) + ':' + Format(FRef.Class));
        Observer.Observe('upper case found', Format(DataTypeMgt.FindFieldByName(RecRef, FRef, 'TIMESTAMP')));
        Observer.Observe('SystemRowVersion found', Format(DataTypeMgt.FindFieldByName(RecRef, FRef, 'SystemRowVersion')));
        RecRef.Close();
        Observer.Finish();
    end;
}
