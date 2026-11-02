// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sqldatatype-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160), objects in Y82Objects.al
// Probe (runner issues 6796 and 6797): SQLDataType on Code fields (Varchar, Integer, BigInteger, Variant, none) in the primary key, in secondary keys, in no key.
// Object ids 94300 to 94309.

table 94300 "LT Y82 PkVar"
{
    DataClassification = SystemMetadata;
    fields { field(1; K; Code[10]) { SQLDataType = Varchar; } field(2; Note; Text[30]) { } }
    keys { key(PK; K) { Clustered = true; } }
}

table 94301 "LT Y82 PkInt"
{
    DataClassification = SystemMetadata;
    fields { field(1; K; Code[10]) { SQLDataType = Integer; } field(2; Note; Text[30]) { } }
    keys { key(PK; K) { Clustered = true; } }
}

table 94302 "LT Y82 PkBig"
{
    DataClassification = SystemMetadata;
    fields { field(1; K; Code[10]) { SQLDataType = BigInteger; } field(2; Note; Text[30]) { } }
    keys { key(PK; K) { Clustered = true; } }
}

table 94303 "LT Y82 PkVnt"
{
    DataClassification = SystemMetadata;
    fields { field(1; K; Code[10]) { SQLDataType = Variant; } field(2; Note; Text[30]) { } }
    keys { key(PK; K) { Clustered = true; } }
}

table 94304 "LT Y82 PkDef"
{
    DataClassification = SystemMetadata;
    fields { field(1; K; Code[10]) { } field(2; Note; Text[30]) { } }
    keys { key(PK; K) { Clustered = true; } }
}

table 94305 "LT Y82 Sec"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; FVar; Code[10]) { SQLDataType = Varchar; }
        field(3; FInt; Code[10]) { SQLDataType = Integer; }
        field(4; FBig; Code[10]) { SQLDataType = BigInteger; }
        field(5; FVnt; Code[10]) { SQLDataType = Variant; }
        field(6; FDef; Code[10]) { }
        field(7; NoKInt; Code[10]) { SQLDataType = Integer; }
        field(8; NoKVnt; Code[10]) { SQLDataType = Variant; }
        field(9; NoKBig; Code[10]) { SQLDataType = BigInteger; }
        field(10; NoKVar; Code[10]) { SQLDataType = Varchar; }
        field(11; FObs; Code[6])
        {
            SQLDataType = Variant;
            ObsoleteState = Pending;
            ObsoleteReason = 'Y82 probe of a pending obsolete Variant field in a key';
            ObsoleteTag = '1.0';
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(K2; FVar) { }
        key(K3; FInt) { }
        key(K4; FBig) { }
        key(K5; FVnt) { }
        key(K6; FDef) { }
        key(K7; FDef, FVnt) { }
        key(K8; FDef, FObs) { }
        key(K9; FDef, FInt) { }
    }
}

tableextension 94307 "LT Y82 Sec Ext" extends "LT Y82 Sec"
{
    fields
    {
        field(94300; ExtInt; Code[10]) { SQLDataType = Integer; }
        field(94301; ExtVnt; Code[10]) { SQLDataType = Variant; }
    }

    keys
    {
        key(KExtInt; ExtInt) { }
        key(KExtVnt; ExtVnt) { }
    }
}

table 94306 "LT Y82 Flow"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; RefInt; Code[10]) { SQLDataType = Integer; }
        field(3; RefVar; Code[10]) { }
        field(10; CntVarRange; Integer) { FieldClass = FlowField; CalcFormula = count("LT Y82 PkVar" where(K = filter(2 .. 10))); }
        field(11; CntIntRange; Integer) { FieldClass = FlowField; CalcFormula = count("LT Y82 PkInt" where(K = filter(2 .. 10))); }
        field(12; CntBigRange; Integer) { FieldClass = FlowField; CalcFormula = count("LT Y82 PkBig" where(K = filter(2 .. 10))); }
        field(13; CntVntRange; Integer) { FieldClass = FlowField; CalcFormula = count("LT Y82 PkVnt" where(K = filter(2 .. 10))); }
        field(14; CntDefRange; Integer) { FieldClass = FlowField; CalcFormula = count("LT Y82 PkDef" where(K = filter(2 .. 10))); }
        field(20; CntIntByRefInt; Integer) { FieldClass = FlowField; CalcFormula = count("LT Y82 PkInt" where(K = field(RefInt))); }
        field(21; CntIntByRefVar; Integer) { FieldClass = FlowField; CalcFormula = count("LT Y82 PkInt" where(K = field(RefVar))); }
        field(22; CntVarByRefInt; Integer) { FieldClass = FlowField; CalcFormula = count("LT Y82 PkVar" where(K = field(RefInt))); }
        field(23; CntVntByRefVar; Integer) { FieldClass = FlowField; CalcFormula = count("LT Y82 PkVnt" where(K = field(RefVar))); }
        field(24; CntIntLess; Integer) { FieldClass = FlowField; CalcFormula = count("LT Y82 PkInt" where(K = filter(< 10))); }
        field(25; CntVarLess; Integer) { FieldClass = FlowField; CalcFormula = count("LT Y82 PkVar" where(K = filter(< 10))); }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 94308 "LT Y82 Step"
{
    var
        Op: Text;
        TableNo: Integer;
        SortField: Integer;
        ShowField: Integer;
        FilterField: Integer;
        FilterKind: Integer;
        IdValue: Integer;
        Ascending: Boolean;
        V1: Text;
        V2: Text;
        Result: Text;

    procedure Setup(NewOp: Text; NewTableNo: Integer; NewSortField: Integer; NewShowField: Integer; NewFilterField: Integer; NewFilterKind: Integer; NewAscending: Boolean; NewV1: Text; NewV2: Text; NewId: Integer)
    begin
        Op := NewOp;
        TableNo := NewTableNo;
        SortField := NewSortField;
        ShowField := NewShowField;
        FilterField := NewFilterField;
        FilterKind := NewFilterKind;
        Ascending := NewAscending;
        V1 := NewV1;
        V2 := NewV2;
        IdValue := NewId;
        Result := '';
    end;

    procedure GetResult(): Text
    begin
        exit(Result);
    end;

    local procedure ApplyFilter(var RR: RecordRef)
    var
        FR: FieldRef;
    begin
        if FilterKind = 0 then
            exit;
        FR := RR.Field(FilterField);
        if FilterKind = 1 then
            FR.SetFilter(V1)
        else
            FR.SetRange(V1, V2);
    end;

    local procedure SelectKey(var RR: RecordRef)
    var
        I: Integer;
    begin
        for I := 1 to RR.KeyCount() do
            if (RR.KeyIndex(I).FieldCount() = 1) and (RR.KeyIndex(I).FieldIndex(1).Number = SortField) then begin
                RR.CurrentKeyIndex(I);
                exit;
            end;
        Error('no single-field key on field %1', SortField);
    end;

    trigger OnRun()
    var
        RR: RecordRef;
        FR: FieldRef;
        Sep: Text;
    begin
        RR.Open(TableNo);
        case Op of
            'INS':
                begin
                    RR.Init();
                    if IdValue <> 0 then
                        RR.Field(1).Value := IdValue;
                    FR := RR.Field(SortField);
                    FR.Value := V1;
                    RR.Insert();
                    Result := 'ok';
                end;
            'DUMP':
                begin
                    ApplyFilter(RR);
                    SelectKey(RR);
                    RR.Ascending(Ascending);
                    if RR.FindSet() then
                        repeat
                            Result += Sep + Format(RR.Field(ShowField).Value);
                            Sep := ',';
                        until RR.Next() = 0;
                    if Result = '' then
                        Result := '(none)';
                end;
            'COUNT':
                begin
                    ApplyFilter(RR);
                    Result := Format(RR.Count());
                end;
            'FIND=':
                begin
                    RR.Field(1).Value := V1;
                    if RR.Find('=') then
                        Result := 'found ' + Format(RR.Field(1).Value)
                    else
                        Result := 'not found';
                end;
            'RENAME':
                begin
                    RR.Field(1).Value := V1;
                    RR.Find('=');
                    RR.Rename(V2);
                    Result := 'ok';
                end;
        end;
    end;
}

codeunit 94309 "LT Y82 Helper"
{
    procedure Exec(Op: Text; TableNo: Integer; SortField: Integer; ShowField: Integer; FilterField: Integer; FilterKind: Integer; Ascending: Boolean; V1: Text; V2: Text; Id: Integer): Text
    var
        Step: Codeunit "LT Y82 Step";
    begin
        ClearLastError();
        Step.Setup(Op, TableNo, SortField, ShowField, FilterField, FilterKind, Ascending, V1, V2, Id);
        if Step.Run() then
            exit(Step.GetResult());
        exit('ERR[' + GetLastErrorCode() + ']: ' + GetLastErrorText());
    end;

    procedure Ins(TableNo: Integer; Fld: Integer; Id: Integer; Value: Text): Text
    begin
        exit(Exec('INS', TableNo, Fld, 0, 0, 0, true, Value, '', Id));
    end;

    // Inserts the comma separated values (an empty piece is a blank value); Id counts from 1 when IdField <> 1.
    procedure Seed(TableNo: Integer; Fld: Integer; Values: Text): Text
    var
        Parts: List of [Text];
        Part: Text;
        Id: Integer;
        Results: Text;
        Sep: Text;
    begin
        Parts := Values.Split(',');
        foreach Part in Parts do begin
            Id += 1;
            if Fld = 1 then
                Results += Sep + Ins(TableNo, Fld, 0, Part)
            else
                Results += Sep + Ins(TableNo, Fld, Id, Part);
            Sep := ' | ';
        end;
        exit(Results);
    end;

    procedure Dump(TableNo: Integer; SortField: Integer; ShowField: Integer; Ascending: Boolean): Text
    begin
        exit(Exec('DUMP', TableNo, SortField, ShowField, 0, 0, Ascending, '', '', 0));
    end;

    procedure DumpFilter(TableNo: Integer; SortField: Integer; ShowField: Integer; FilterField: Integer; Expression: Text): Text
    begin
        exit(Exec('DUMP', TableNo, SortField, ShowField, FilterField, 1, true, Expression, '', 0));
    end;

    procedure DumpRange(TableNo: Integer; SortField: Integer; ShowField: Integer; FilterField: Integer; FromValue: Text; ToValue: Text): Text
    begin
        exit(Exec('DUMP', TableNo, SortField, ShowField, FilterField, 2, true, FromValue, ToValue, 0));
    end;

    procedure CountFilter(TableNo: Integer; FilterField: Integer; Expression: Text): Text
    begin
        exit(Exec('COUNT', TableNo, 1, 1, FilterField, 1, true, Expression, '', 0));
    end;

    procedure CountRange(TableNo: Integer; FilterField: Integer; FromValue: Text; ToValue: Text): Text
    begin
        exit(Exec('COUNT', TableNo, 1, 1, FilterField, 2, true, FromValue, ToValue, 0));
    end;

    procedure FindKey(TableNo: Integer; Value: Text): Text
    begin
        exit(Exec('FIND=', TableNo, 1, 1, 0, 0, true, Value, '', 0));
    end;

    procedure RenameKey(TableNo: Integer; FromValue: Text; ToValue: Text): Text
    begin
        exit(Exec('RENAME', TableNo, 1, 1, 0, 0, true, FromValue, ToValue, 0));
    end;

    procedure FieldInfo(TableNo: Integer; FieldNo: Integer): Text
    var
        RR: RecordRef;
        FR: FieldRef;
        FieldRow: Record Field;
    begin
        RR.Open(TableNo);
        FR := RR.Field(FieldNo);
        FieldRow.Get(TableNo, FieldNo);
        exit(StrSubstNo('%1 type=%2 len=%3 class=%4 sql=%5 pk=%6 enabled=%7', FR.Name, FR.Type, FR.Length, FR.Class, FieldRow.SQLDataType, FieldRow.IsPartOfPrimaryKey, FieldRow.Enabled));
    end;

    procedure KeyInfo(TableNo: Integer): Text
    var
        RR: RecordRef;
        KR: KeyRef;
        I: Integer;
        J: Integer;
        Text1: Text;
    begin
        RR.Open(TableNo);
        Text1 := 'keys=' + Format(RR.KeyCount());
        for I := 1 to RR.KeyCount() do begin
            KR := RR.KeyIndex(I);
            Text1 += ' ' + Format(I) + '=';
            for J := 1 to KR.FieldCount() do begin
                if J > 1 then
                    Text1 += '+';
                Text1 += KR.FieldIndex(J).Name;
            end;
            if KR.Active() then
                Text1 += '*';
        end;
        exit(Text1);
    end;
}
