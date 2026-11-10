// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-get-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: Probe Observer (codeunit 69160); own objects 96450 to 96461
// BC versions: 27.5+
// Probe (al-runner 7597): Record.Get with no value or with fewer values than the primary key has fields. Pinned so far
// (RcAGetFind.al, Get_Fewer_Values_Than_Key_Fields_BQ): on a key (Code, Integer, Date) and a CLEARED record variable, an omitted field is
// searched with its blank value. This file asks what that test cannot tell: the record variable holds a value in the omitted field, only
// rows with a non-blank rest exist, a filter is set on the omitted field, the omitted field is an Option, an Enum without ordinal 0, a
// Guid or one of eight more types, the field has an InitValue, the record is temporary, a RecordId holds fewer values, and the texts of
// the errors. No cell reads rows after an asserterror (it would roll the rows back): an error is observed through a TryFunction.
// Values measured on BC 27.5, 28.5 and 29.0 (corpus CI runs 42876663156, 42876712578, 42876759234; identical on all three).
// Measured: Get with fewer values searches every omitted key field with the blank value of its type (Code '', Integer 0, Option and Enum
// ordinal 0 even when the enum has no member 0, Boolean false, zero Guid, blank Date, Time, DateFormula and Duration). An omitted field
// with InitValue = 5 is searched with 5, also on a cleared record variable: the row with 5 is found, the row with 0 is not. It ignores the value the record variable holds in the omitted field, a filter on that field or on another field (any
// filter group; the filters stay), and the current key. A row whose omitted fields are not blank is not found: the used form answers
// false, the unused form raises DB:RecordNotFound and names every key field, the omitted ones with their blank value. After a miss the
// record variable keeps its values when the Get was used (false) and after a TryFunction error; a cleared variable stays cleared.
// A temporary record, a RecordId with fewer values (Record.Get and RecordRef.Get) and the assignment form behave the same.
// local object: every table below has the primary key (field types, InitValue, captions) that is the subject of the probe.

table 96450 "REC GetFewer Two"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; A; Code[10]) { }
        field(2; B; Code[10]) { }
        field(3; Info; Text[30]) { }
    }

    keys
    {
        key(PK; A, B) { Clustered = true; }
        key(Sec; Info) { }
    }
}

table 96451 "REC GetFewer Mixed"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; A; Code[10]) { }
        field(2; N; Integer) { }
        field(3; O; Option) { OptionMembers = " ",One,Two; }
        field(4; G; Guid) { }
        field(5; Info; Text[30]) { }
    }

    keys
    {
        key(PK; A, N, O, G) { Clustered = true; }
    }
}

table 96452 "REC GetFewer Types"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; A; Code[10]) { }
        field(2; Bo; Boolean) { }
        field(3; De; Decimal) { }
        field(4; Bi; BigInteger) { }
        field(5; Dt; DateTime) { }
        field(6; Ti; Time) { }
        field(7; Tx; Text[20]) { }
        field(8; Du; Duration) { }
        field(9; Info; Text[30]) { }
    }

    keys
    {
        key(PK; A, Bo, De, Bi, Dt, Ti, Tx, Du) { Clustered = true; }
    }
}

table 96453 "REC GetFewer Formula"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; A; Code[10]) { }
        field(2; Df; DateFormula) { }
        field(3; Da; Date) { }
        field(4; Info; Text[30]) { }
    }

    keys
    {
        key(PK; A, Df, Da) { Clustered = true; }
    }
}

enum 96454 "REC GetFewer Enum"
{
    Extensible = false;

    value(1; One) { }
    value(2; Two) { }
}

table 96455 "REC GetFewer Enum Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; A; Code[10]) { }
        field(2; E; Enum "REC GetFewer Enum") { }
        field(3; Info; Text[30]) { }
    }

    keys
    {
        key(PK; A, E) { Clustered = true; }
    }
}

table 96456 "REC GetFewer Option Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; A; Code[10]) { }
        field(2; O; Option) { OptionMembers = Zero,One; }
        field(3; Info; Text[30]) { }
    }

    keys
    {
        key(PK; A, O) { Clustered = true; }
    }
}

table 96457 "REC GetFewer Init"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; A; Code[10]) { }
        field(2; N; Integer) { InitValue = 5; }
        field(3; Info; Text[30]) { }
    }

    keys
    {
        key(PK; A, N) { Clustered = true; }
    }
}

table 96458 "REC GetFewer Cap"
{
    Caption = 'GF Captioned';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; A; Code[10]) { Caption = 'First Part'; }
        field(2; B; Code[10]) { Caption = 'Second Part'; }
        field(3; Info; Text[30]) { }
    }

    keys
    {
        key(PK; A, B) { Clustered = true; }
    }
}

codeunit 96460 "REC GetFewer Key Values"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Every field of the record, in field order, as Format(value, 0, 9), joined with '/'.
    local procedure Show(Rec: Variant): Text
    var
        RecRef: RecordRef;
        Result: Text;
        i: Integer;
    begin
        RecRef.GetTable(Rec);
        for i := 1 to RecRef.FieldCount() do begin
            if i > 1 then
                Result += '/';
            Result += Format(RecRef.FieldIndex(i).Value(), 0, 9);
        end;
        exit(Result);
    end;

    local procedure Used(Found: Boolean; Rec: Variant): Text
    begin
        exit(Format(Found) + ' ' + Show(Rec));
    end;

    local procedure ShowRef(RecRef: RecordRef): Text
    var
        Result: Text;
        i: Integer;
    begin
        for i := 1 to RecRef.FieldCount() do begin
            if i > 1 then
                Result += '/';
            Result += Format(RecRef.FieldIndex(i).Value(), 0, 9);
        end;
        exit(Result);
    end;

    local procedure Failed(): Text
    var
        Result: Text;
    begin
        Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    // The outcome of a Get whose result is not used (it ran inside a TryFunction): 'ok' or the error, and the record after it.
    local procedure Unused(Ok: Boolean; Rec: Variant): Text
    var
        Result: Text;
    begin
        if Ok then
            exit('ok ' + Show(Rec));
        Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode() + ' record ' + Show(Rec);
        ClearLastError();
        exit(Result);
    end;

    local procedure AddTwo(A: Code[10]; B: Code[10]; Info: Text[30])
    var
        Two: Record "REC GetFewer Two";
    begin
        Two.A := A;
        Two.B := B;
        Two.Info := Info;
        Two.Insert();
    end;

    local procedure SeedTwoBlankAndX()
    var
        Two: Record "REC GetFewer Two";
    begin
        Two.DeleteAll();
        AddTwo('Q', '', 'q-blank');
        AddTwo('Q', 'X', 'q-x');
    end;

    local procedure SeedTwoOnlyX()
    var
        Two: Record "REC GetFewer Two";
    begin
        Two.DeleteAll();
        AddTwo('Q', 'X', 'q-x');
    end;

    [TryFunction]
    local procedure TwoGet0(var Two: Record "REC GetFewer Two")
    begin
        Two.Get();
    end;

    [TryFunction]
    local procedure TwoGet1(var Two: Record "REC GetFewer Two"; A: Code[10])
    begin
        Two.Get(A);
    end;

    // G1: Get() on a two-field key; the row with both key fields blank exists.
    [Test]
    procedure Get_NoValues_AllBlankRowPresent()
    var
        Two: Record "REC GetFewer Two";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Two.DeleteAll();
        AddTwo('', '', 'all-blank');
        AddTwo('Q', '', 'q-blank');
        Clear(Two);
        Observer.Observe('used', Used(Two.Get(), Two));
        Clear(Two);
        Ok := TwoGet0(Two);
        Observer.Observe('unused', Unused(Ok, Two));
        Observer.Expect('used', 'Yes //all-blank');
        Observer.Expect('unused', 'ok //all-blank');
        Observer.Verify();
    end;

    // G2: Get('Q') when only a row with a non-blank second key field exists: no row, or the first row that starts with Q?
    [Test]
    procedure Get_OneValue_OnlyRowsWithNonBlankRest()
    var
        Two: Record "REC GetFewer Two";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        SeedTwoOnlyX();
        Clear(Two);
        Observer.Observe('used', Used(Two.Get('Q'), Two));
        Clear(Two);
        Ok := TwoGet1(Two, 'Q');
        Observer.Observe('unused', Unused(Ok, Two));
        Observer.Expect('used', 'No //');
        Observer.Expect('unused', 'error:The REC GetFewer Two does not exist. Identification fields and values: A=''Q'',B=''''|DB:RecordNotFound record //');
        Observer.Verify();
    end;

    // G3: the record variable holds 'X' in the omitted field (assigned, no read): blank or the held value is searched?
    [Test]
    procedure Get_OneValue_RecordHoldsValueInOmittedField()
    var
        Two: Record "REC GetFewer Two";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        SeedTwoBlankAndX();
        Clear(Two);
        Two.A := 'Q';
        Two.B := 'X';
        Observer.Observe('both rows, used', Used(Two.Get('Q'), Two));
        Clear(Two);
        Two.B := 'X';
        Ok := TwoGet1(Two, 'Q');
        Observer.Observe('both rows, unused', Unused(Ok, Two));
        SeedTwoOnlyX();
        Clear(Two);
        Two.A := 'Q';
        Two.B := 'X';
        Observer.Observe('only the X row, used', Used(Two.Get('Q'), Two));
        Clear(Two);
        Two.A := 'Q';
        Two.B := 'X';
        Ok := TwoGet1(Two, 'Q');
        Observer.Observe('only the X row, unused', Unused(Ok, Two));
        Clear(Two);
        Two.A := 'Q';
        Two.B := 'X';
        Observer.Observe('only the X row, no values', Used(Two.Get(), Two));
        Observer.Expect('both rows, used', 'Yes Q//q-blank');
        Observer.Expect('both rows, unused', 'ok Q//q-blank');
        Observer.Expect('only the X row, used', 'No Q/X/');
        Observer.Expect('only the X row, unused', 'error:The REC GetFewer Two does not exist. Identification fields and values: A=''Q'',B=''''|DB:RecordNotFound record Q/X/');
        Observer.Expect('only the X row, no values', 'No Q/X/');
        Observer.Verify();
    end;

    // G4: the same question after a successful full-key Get of the X row.
    [Test]
    procedure Get_OneValue_AfterFullKeyGet()
    var
        Two: Record "REC GetFewer Two";
        Observer: Codeunit "Probe Observer";
    begin
        SeedTwoBlankAndX();
        Clear(Two);
        Observer.Observe('full key', Used(Two.Get('Q', 'X'), Two));
        Observer.Observe('both rows', Used(Two.Get('Q'), Two));
        SeedTwoOnlyX();
        Clear(Two);
        Observer.Observe('only the X row, full key', Used(Two.Get('Q', 'X'), Two));
        Observer.Observe('only the X row', Used(Two.Get('Q'), Two));
        Observer.Observe('only the X row, no values', Used(Two.Get(), Two));
        Observer.Expect('full key', 'Yes Q/X/q-x');
        Observer.Expect('both rows', 'Yes Q//q-blank');
        Observer.Expect('only the X row, full key', 'Yes Q/X/q-x');
        Observer.Expect('only the X row', 'No Q/X/q-x');
        Observer.Expect('only the X row, no values', 'No Q/X/q-x');
        Observer.Verify();
    end;

    // G5: a filter on the omitted key field: it supplies the value, hides the blank row, or is ignored?
    [Test]
    procedure Get_OneValue_FilterOnOmittedField()
    var
        Two: Record "REC GetFewer Two";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        SeedTwoBlankAndX();
        Clear(Two);
        Two.SetRange(B, 'X');
        Observer.Observe('both rows, used', Used(Two.Get('Q'), Two));
        Observer.Observe('filters after', Two.GetFilters());
        Clear(Two);
        Two.SetRange(B, 'X');
        Ok := TwoGet1(Two, 'Q');
        Observer.Observe('both rows, unused', Unused(Ok, Two));
        SeedTwoOnlyX();
        Clear(Two);
        Two.SetRange(B, 'X');
        Observer.Observe('only the X row, used', Used(Two.Get('Q'), Two));
        Clear(Two);
        Two.SetRange(A, 'Q');
        Two.SetRange(B, 'X');
        Observer.Observe('only the X row, both filtered, no values', Used(Two.Get(), Two));
        Observer.Expect('both rows, used', 'Yes Q//q-blank');
        Observer.Expect('filters after', 'B: X');
        Observer.Expect('both rows, unused', 'ok Q//q-blank');
        Observer.Expect('only the X row, used', 'No //');
        Observer.Expect('only the X row, both filtered, no values', 'No //');
        Observer.Verify();
    end;

    // G6: a filter on a field outside the key, in filter group 0 and in filter group 2.
    [Test]
    procedure Get_OneValue_FilterOnAnotherField()
    var
        Two: Record "REC GetFewer Two";
        Observer: Codeunit "Probe Observer";
    begin
        SeedTwoBlankAndX();
        Clear(Two);
        Two.SetRange(Info, 'none');
        Observer.Observe('group 0', Used(Two.Get('Q'), Two));
        Observer.Observe('group 0 filters after', Two.GetFilters());
        Clear(Two);
        Two.FilterGroup(2);
        Two.SetRange(Info, 'none');
        Two.FilterGroup(0);
        Observer.Observe('group 2', Used(Two.Get('Q'), Two));
        Clear(Two);
        Two.FilterGroup(2);
        Two.SetRange(B, 'X');
        Two.FilterGroup(0);
        Observer.Observe('group 2 on the omitted field', Used(Two.Get('Q'), Two));
        Two.FilterGroup(2);
        Observer.Observe('group 2 filters after', Two.GetFilters());
        Observer.Expect('group 0', 'Yes Q//q-blank');
        Observer.Expect('group 0 filters after', 'Info: none');
        Observer.Expect('group 2', 'Yes Q//q-blank');
        Observer.Expect('group 2 on the omitted field', 'Yes Q//q-blank');
        Observer.Expect('group 2 filters after', 'B: X');
        Observer.Verify();
    end;

    // G7: the current key is a secondary key.
    [Test]
    procedure Get_OneValue_SecondaryKeyIsCurrent()
    var
        Two: Record "REC GetFewer Two";
        Observer: Codeunit "Probe Observer";
    begin
        SeedTwoBlankAndX();
        Clear(Two);
        Two.SetCurrentKey(Info);
        Two.Ascending(false);
        Observer.Observe('used', Used(Two.Get('Q'), Two));
        Observer.Observe('key after', Two.CurrentKey());
        Observer.Expect('used', 'Yes Q//q-blank');
        Observer.Expect('key after', 'Info');
        Observer.Verify();
    end;

    local procedure AddMixed(A: Code[10]; N: Integer; O: Option; G: Guid; Info: Text[30])
    var
        Mixed: Record "REC GetFewer Mixed";
    begin
        Mixed.A := A;
        Mixed.N := N;
        Mixed.O := O;
        Mixed.G := G;
        Mixed.Info := Info;
        Mixed.Insert();
    end;

    local procedure SomeGuid(): Guid
    var
        G: Guid;
    begin
        Evaluate(G, '{11111111-2222-3333-4444-555555555555}');
        exit(G);
    end;

    [TryFunction]
    local procedure MixedGet(var Mixed: Record "REC GetFewer Mixed"; A: Code[10]; Values: Integer)
    begin
        case Values of
            0:
                Mixed.Get();
            1:
                Mixed.Get(A);
            2:
                Mixed.Get(A, 1);
            3:
                Mixed.Get(A, 1, Mixed.O::One);
        end;
    end;

    // G8: Integer, Option and Guid omitted; a row with the blank rest exists for every length.
    [Test]
    procedure Get_FewerValues_IntegerOptionGuidOmitted_Found()
    var
        Mixed: Record "REC GetFewer Mixed";
        Observer: Codeunit "Probe Observer";
        NullGuid: Guid;
    begin
        Mixed.DeleteAll();
        AddMixed('Q', 0, Mixed.O::" ", NullGuid, 'blank');
        AddMixed('Q', 1, Mixed.O::" ", NullGuid, 'n1');
        AddMixed('Q', 1, Mixed.O::One, NullGuid, 'n1-one');
        AddMixed('Q', 1, Mixed.O::One, SomeGuid(), 'n1-one-guid');
        Clear(Mixed);
        Observer.Observe('one value', Used(Mixed.Get('Q'), Mixed));
        Clear(Mixed);
        Observer.Observe('two values', Used(Mixed.Get('Q', 1), Mixed));
        Clear(Mixed);
        Observer.Observe('three values', Used(Mixed.Get('Q', 1, Mixed.O::One), Mixed));
        Clear(Mixed);
        Mixed.N := 1;
        Mixed.O := Mixed.O::One;
        Mixed.G := SomeGuid();
        Observer.Observe('one value, record holds the rest', Used(Mixed.Get('Q'), Mixed));
        Observer.Expect('one value', 'Yes Q/0/0/{00000000-0000-0000-0000-000000000000}/blank');
        Observer.Expect('two values', 'Yes Q/1/0/{00000000-0000-0000-0000-000000000000}/n1');
        Observer.Expect('three values', 'Yes Q/1/1/{00000000-0000-0000-0000-000000000000}/n1-one');
        Observer.Expect('one value, record holds the rest', 'Yes Q/0/0/{00000000-0000-0000-0000-000000000000}/blank');
        Observer.Verify();
    end;

    // G8, G12: only the row with a non-blank rest exists; the error text for each number of values.
    [Test]
    procedure Get_FewerValues_IntegerOptionGuidOmitted_Missing()
    var
        Mixed: Record "REC GetFewer Mixed";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
        Values: Integer;
    begin
        Mixed.DeleteAll();
        AddMixed('Q', 1, Mixed.O::One, SomeGuid(), 'n1-one-guid');
        Clear(Mixed);
        Observer.Observe('three values, used', Used(Mixed.Get('Q', 1, Mixed.O::One), Mixed));
        for Values := 0 to 3 do begin
            Clear(Mixed);
            Ok := MixedGet(Mixed, 'Q', Values);
            Observer.Observe(Format(Values) + ' value(s), unused', Unused(Ok, Mixed));
        end;
        Observer.Expect('three values, used', 'No /0/0/{00000000-0000-0000-0000-000000000000}/');
        Observer.Expect('0 value(s), unused', 'error:The REC GetFewer Mixed does not exist. Identification fields and values: A='''',N=''0'',O='' '',G=''{00000000-0000-0000-0000-000000000000}''|DB:RecordNotFound record /0/0/{00000000-0000-0000-0000-000000000000}/');
        Observer.Expect('1 value(s), unused', 'error:The REC GetFewer Mixed does not exist. Identification fields and values: A=''Q'',N=''0'',O='' '',G=''{00000000-0000-0000-0000-000000000000}''|DB:RecordNotFound record /0/0/{00000000-0000-0000-0000-000000000000}/');
        Observer.Expect('2 value(s), unused', 'error:The REC GetFewer Mixed does not exist. Identification fields and values: A=''Q'',N=''1'',O='' '',G=''{00000000-0000-0000-0000-000000000000}''|DB:RecordNotFound record /0/0/{00000000-0000-0000-0000-000000000000}/');
        Observer.Expect('3 value(s), unused', 'error:The REC GetFewer Mixed does not exist. Identification fields and values: A=''Q'',N=''1'',O=''One'',G=''{00000000-0000-0000-0000-000000000000}''|DB:RecordNotFound record /0/0/{00000000-0000-0000-0000-000000000000}/');
        Observer.Verify();
    end;

    local procedure AddTypes(A: Code[10]; Full: Boolean; Info: Text[30])
    var
        Types: Record "REC GetFewer Types";
    begin
        Types.A := A;
        if Full then begin
            Types.Bo := true;
            Types.De := 1.5;
            Types.Bi := 7;
            Types.Dt := CreateDateTime(DMY2Date(2, 1, 2020), 120000T);
            Types.Ti := 101500T;
            Types.Tx := 'x';
            Types.Du := 60000;
        end;
        Types.Info := Info;
        Types.Insert();
    end;

    [TryFunction]
    local procedure TypesGet1(var Types: Record "REC GetFewer Types"; A: Code[10])
    begin
        Types.Get(A);
    end;

    // G9: Boolean, Decimal, BigInteger, DateTime, Time, Text and Duration omitted.
    [Test]
    procedure Get_OneValue_SevenTypesOmitted()
    var
        Types: Record "REC GetFewer Types";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Types.DeleteAll();
        AddTypes('Q', false, 'q-blank');
        AddTypes('Q', true, 'q-full');
        Types.A := 'Q';
        Types.Bo := true;
        Types.Info := 'q-true';
        Types.Insert();
        AddTypes('P', true, 'p-full');
        Clear(Types);
        Observer.Observe('blank row present', Used(Types.Get('Q'), Types));
        Clear(Types);
        Observer.Observe('two values, false', Used(Types.Get('Q', false), Types));
        Clear(Types);
        Observer.Observe('two values, true', Used(Types.Get('Q', true), Types));
        Clear(Types);
        Observer.Observe('only the full row', Used(Types.Get('P'), Types));
        Clear(Types);
        Ok := TypesGet1(Types, 'P');
        Observer.Observe('only the full row, unused', Unused(Ok, Types));
        Observer.Expect('blank row present', 'Yes Q/false/0/0////P0DT0H0M0.0S/q-blank');
        Observer.Expect('two values, false', 'Yes Q/false/0/0////P0DT0H0M0.0S/q-blank');
        Observer.Expect('two values, true', 'Yes Q/true/0/0////P0DT0H0M0.0S/q-true');
        Observer.Expect('only the full row', 'No /false/0/0////P0DT0H0M0.0S/');
        Observer.Expect('only the full row, unused', 'error:The REC GetFewer Types does not exist. Identification fields and values: A=''P'',Bo=''No'',De=''0'',Bi=''0'',Dt='''',Ti='''',Tx='''',Du=''''|DB:RecordNotFound record /false/0/0////P0DT0H0M0.0S/');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure FormulaGet1(var Formula: Record "REC GetFewer Formula"; A: Code[10])
    begin
        Formula.Get(A);
    end;

    // G9: DateFormula and Date omitted.
    [Test]
    procedure Get_OneValue_DateFormulaOmitted()
    var
        Formula: Record "REC GetFewer Formula";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Formula.DeleteAll();
        Formula.A := 'Q';
        Formula.Info := 'q-blank';
        Formula.Insert();
        Formula.A := 'Q';
        Evaluate(Formula.Df, '<1D>');
        Formula.Da := DMY2Date(2, 1, 2020);
        Formula.Info := 'q-full';
        Formula.Insert();
        Formula.A := 'P';
        Formula.Info := 'p-full';
        Formula.Insert();
        Clear(Formula);
        Observer.Observe('blank row present', Used(Formula.Get('Q'), Formula));
        Clear(Formula);
        Observer.Observe('only the full row', Used(Formula.Get('P'), Formula));
        Clear(Formula);
        Ok := FormulaGet1(Formula, 'P');
        Observer.Observe('only the full row, unused', Unused(Ok, Formula));
        Observer.Expect('blank row present', 'Yes Q///q-blank');
        Observer.Expect('only the full row', 'No ///');
        Observer.Expect('only the full row, unused', 'error:The REC GetFewer Formula does not exist. Identification fields and values: A=''P'',Df='''',Da=''''|DB:RecordNotFound record ///');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure EnumGet1(var EnumRow: Record "REC GetFewer Enum Row"; A: Code[10])
    begin
        EnumRow.Get(A);
    end;

    // G10: an Enum without ordinal 0 omitted. Init leaves ordinal 0 in the field, so a row with ordinal 0 can exist.
    [Test]
    procedure Get_OneValue_EnumWithoutOrdinalZeroOmitted()
    var
        EnumRow: Record "REC GetFewer Enum Row";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        EnumRow.DeleteAll();
        EnumRow.Init();
        EnumRow.A := 'Q';
        EnumRow.Info := 'q-init';
        Observer.Observe('ordinal after Init', Format(EnumRow.E.AsInteger()));
        EnumRow.Insert();
        EnumRow.Init();
        EnumRow.A := 'Q';
        EnumRow.E := EnumRow.E::One;
        EnumRow.Info := 'q-one';
        EnumRow.Insert();
        EnumRow.Init();
        EnumRow.A := 'P';
        EnumRow.E := EnumRow.E::One;
        EnumRow.Info := 'p-one';
        EnumRow.Insert();
        Clear(EnumRow);
        Observer.Observe('row with ordinal 0 present', Used(EnumRow.Get('Q'), EnumRow));
        Clear(EnumRow);
        Observer.Observe('only the row with One', Used(EnumRow.Get('P'), EnumRow));
        Clear(EnumRow);
        Ok := EnumGet1(EnumRow, 'P');
        Observer.Observe('only the row with One, unused', Unused(Ok, EnumRow));
        Observer.Expect('ordinal after Init', '0');
        Observer.Expect('row with ordinal 0 present', 'Yes Q/0/q-init');
        Observer.Expect('only the row with One', 'No /0/');
        Observer.Expect('only the row with One, unused', 'error:The REC GetFewer Enum Row does not exist. Identification fields and values: A=''P'',E=''0''|DB:RecordNotFound record /0/');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure OptionGet1(var OptionRow: Record "REC GetFewer Option Row"; A: Code[10])
    begin
        OptionRow.Get(A);
    end;

    // G10: an Option whose first member is not blank (Zero,One) omitted.
    [Test]
    procedure Get_OneValue_OptionWithNamedFirstMemberOmitted()
    var
        OptionRow: Record "REC GetFewer Option Row";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        OptionRow.DeleteAll();
        OptionRow.A := 'Q';
        OptionRow.O := OptionRow.O::Zero;
        OptionRow.Info := 'q-zero';
        OptionRow.Insert();
        OptionRow.O := OptionRow.O::One;
        OptionRow.Info := 'q-one';
        OptionRow.Insert();
        OptionRow.A := 'P';
        OptionRow.Info := 'p-one';
        OptionRow.Insert();
        Clear(OptionRow);
        Observer.Observe('row with Zero present', Used(OptionRow.Get('Q'), OptionRow));
        Clear(OptionRow);
        Observer.Observe('only the row with One', Used(OptionRow.Get('P'), OptionRow));
        Clear(OptionRow);
        Ok := OptionGet1(OptionRow, 'P');
        Observer.Observe('only the row with One, unused', Unused(Ok, OptionRow));
        Observer.Expect('row with Zero present', 'Yes Q/0/q-zero');
        Observer.Expect('only the row with One', 'No /0/');
        Observer.Expect('only the row with One, unused', 'error:The REC GetFewer Option Row does not exist. Identification fields and values: A=''P'',O=''Zero''|DB:RecordNotFound record /0/');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure InitGet1(var InitRow: Record "REC GetFewer Init"; A: Code[10])
    begin
        InitRow.Get(A);
    end;

    // G11: the omitted key field has InitValue = 5: zero or 5 is searched?
    [Test]
    procedure Get_OneValue_OmittedFieldHasInitValue()
    var
        InitRow: Record "REC GetFewer Init";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        InitRow.DeleteAll();
        InitRow.A := 'Q';
        InitRow.N := 0;
        InitRow.Info := 'q-0';
        InitRow.Insert();
        InitRow.N := 5;
        InitRow.Info := 'q-5';
        InitRow.Insert();
        InitRow.A := 'P';
        InitRow.Info := 'p-5';
        InitRow.Insert();
        Clear(InitRow);
        Observer.Observe('rows 0 and 5, cleared record', Used(InitRow.Get('Q'), InitRow));
        InitRow.Init();
        Observer.Observe('rows 0 and 5, after Init', Used(InitRow.Get('Q'), InitRow));
        Clear(InitRow);
        Observer.Observe('only row 5, cleared record', Used(InitRow.Get('P'), InitRow));
        Clear(InitRow);
        InitRow.Init();
        Observer.Observe('only row 5, after Init', Used(InitRow.Get('P'), InitRow));
        Clear(InitRow);
        Ok := InitGet1(InitRow, 'P');
        Observer.Observe('only row 5, unused', Unused(Ok, InitRow));
        Observer.Expect('rows 0 and 5, cleared record', 'Yes Q/5/q-5');
        Observer.Expect('rows 0 and 5, after Init', 'Yes Q/5/q-5');
        Observer.Expect('only row 5, cleared record', 'Yes P/5/p-5');
        Observer.Expect('only row 5, after Init', 'Yes P/5/p-5');
        Observer.Expect('only row 5, unused', 'ok P/5/p-5');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure CapGet(var Cap: Record "REC GetFewer Cap"; A: Code[10]; Values: Integer)
    begin
        if Values = 0 then
            Cap.Get()
        else
            Cap.Get(A);
    end;

    // G12: the error of a Get whose result is not used, on a table without captions and on one with a table caption and field captions.
    [Test]
    procedure Get_FewerValues_NoRow_ErrorTexts()
    var
        Two: Record "REC GetFewer Two";
        Cap: Record "REC GetFewer Cap";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Two.DeleteAll();
        Cap.DeleteAll();
        Ok := TwoGet0(Two);
        Observer.Observe('no caption, no values', Unused(Ok, Two));
        Ok := TwoGet1(Two, 'R');
        Observer.Observe('no caption, one value', Unused(Ok, Two));
        Ok := CapGet(Cap, '', 0);
        Observer.Observe('captions, no values', Unused(Ok, Cap));
        Ok := CapGet(Cap, 'R', 1);
        Observer.Observe('captions, one value', Unused(Ok, Cap));
        Observer.Expect('no caption, no values', 'error:The REC GetFewer Two does not exist. Identification fields and values: A='''',B=''''|DB:RecordNotFound record //');
        Observer.Expect('no caption, one value', 'error:The REC GetFewer Two does not exist. Identification fields and values: A=''R'',B=''''|DB:RecordNotFound record //');
        Observer.Expect('captions, no values', 'error:The GF Captioned does not exist. Identification fields and values: First Part='''',Second Part=''''|DB:RecordNotFound record //');
        Observer.Expect('captions, one value', 'error:The GF Captioned does not exist. Identification fields and values: First Part=''R'',Second Part=''''|DB:RecordNotFound record //');
        Observer.Verify();
    end;

    // G13: the record variable holds values and no row matches: the record after the miss.
    [Test]
    procedure Get_OneValue_NoRow_RecordAfterTheMiss()
    var
        Two: Record "REC GetFewer Two";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        SeedTwoBlankAndX();
        Clear(Two);
        Two.A := 'Z';
        Two.B := 'Y';
        Two.Info := 'held';
        Observer.Observe('used', Used(Two.Get('R'), Two));
        Ok := TwoGet1(Two, 'R');
        Observer.Observe('unused', Unused(Ok, Two));
        Two.Get('Q', 'X');
        Observer.Observe('used, after a read', Used(Two.Get('R'), Two));
        Observer.Expect('used', 'No Z/Y/held');
        Observer.Expect('unused', 'error:The REC GetFewer Two does not exist. Identification fields and values: A=''R'',B=''''|DB:RecordNotFound record Z/Y/held');
        Observer.Expect('used, after a read', 'No Q/X/q-x');
        Observer.Verify();
    end;

    // G14: a temporary record: the cells G1 to G3.
    [Test]
    procedure Get_FewerValues_TemporaryRecord()
    var
        Temp: Record "REC GetFewer Two" temporary;
        Observer: Codeunit "Probe Observer";
        Found: Boolean;
    begin
        Temp.A := '';
        Temp.B := '';
        Temp.Info := 'all-blank';
        Temp.Insert();
        Temp.A := 'Q';
        Temp.B := 'X';
        Temp.Info := 'q-x';
        Temp.Insert();
        Temp.Init();
        Temp.A := '';
        Temp.B := '';
        Found := Temp.Get();
        Observer.Observe('no values, all-blank row present', Format(Found) + ' ' + Temp.A + '/' + Temp.B + '/' + Temp.Info);
        Temp.Init();
        Found := Temp.Get('Q');
        Observer.Observe('one value, only the X row', Format(Found) + ' ' + Temp.A + '/' + Temp.B + '/' + Temp.Info);
        Temp.A := 'Q';
        Temp.B := 'X';
        Temp.Info := '';
        Found := Temp.Get('Q');
        Observer.Observe('one value, record holds X', Format(Found) + ' ' + Temp.A + '/' + Temp.B + '/' + Temp.Info);
        Temp.A := 'Q';
        Temp.B := '';
        Temp.Info := 'q-blank';
        Temp.Insert();
        Temp.B := 'X';
        Found := Temp.Get('Q');
        Observer.Observe('one value, both rows, record holds X', Format(Found) + ' ' + Temp.A + '/' + Temp.B + '/' + Temp.Info);
        Temp.SetRange(B, 'X');
        Found := Temp.Get('Q');
        Observer.Observe('one value, both rows, filter on X', Format(Found) + ' ' + Temp.A + '/' + Temp.B + '/' + Temp.Info);
        Observer.Expect('no values, all-blank row present', 'Yes //all-blank');
        Observer.Expect('one value, only the X row', 'No //');
        Observer.Expect('one value, record holds X', 'No Q/X/');
        Observer.Expect('one value, both rows, record holds X', 'Yes Q//q-blank');
        Observer.Expect('one value, both rows, filter on X', 'Yes Q//q-blank');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TwoGetRecordId(var Two: Record "REC GetFewer Two"; RecId: RecordId; UseResult: Boolean; var Found: Boolean)
    begin
        Found := true;
        if UseResult then
            Found := Two.Get(RecId)
        else
            Two.Get(RecId);
    end;

    [TryFunction]
    local procedure RefGetRecordId(var RecRef: RecordRef; RecId: RecordId; UseResult: Boolean; var Found: Boolean)
    begin
        Found := true;
        if UseResult then
            Found := RecRef.Get(RecId)
        else
            RecRef.Get(RecId);
    end;

    local procedure TwoRecordIdOutcome(var Two: Record "REC GetFewer Two"; RecId: RecordId; UseResult: Boolean): Text
    var
        Found: Boolean;
    begin
        if TwoGetRecordId(Two, RecId, UseResult, Found) then
            exit(Format(Found) + ' ' + Show(Two));
        exit(Failed() + ' record ' + Show(Two));
    end;

    local procedure RefRecordIdOutcome(RecId: RecordId; UseResult: Boolean): Text
    var
        RecRef: RecordRef;
        Found: Boolean;
    begin
        RecRef.Open(Database::"REC GetFewer Two");
        if RefGetRecordId(RecRef, RecId, UseResult, Found) then
            exit(Format(Found) + ' ' + ShowRef(RecRef));
        exit(Failed() + ' record ' + ShowRef(RecRef));
    end;

    // G15: a RecordId evaluated from a text with one value of the two key fields, into Record.Get and RecordRef.Get
    // ('Yes'/'No' is the result when it is used; a call whose result is not used shows 'Yes' when it did not raise).
    [Test]
    procedure Get_RecordIdWithFewerValues()
    var
        Two: Record "REC GetFewer Two";
        RecId: RecordId;
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        SeedTwoBlankAndX();
        Ok := Evaluate(RecId, 'REC GetFewer Two: Q');
        Observer.Observe('evaluate', Format(Ok) + ' ' + Format(RecId));
        if Ok then begin
            Clear(Two);
            Observer.Observe('record, both rows, used', TwoRecordIdOutcome(Two, RecId, true));
            Clear(Two);
            Two.B := 'X';
            Observer.Observe('record holds X, both rows, used', TwoRecordIdOutcome(Two, RecId, true));
            Observer.Observe('recordref, both rows, used', RefRecordIdOutcome(RecId, true));
            SeedTwoOnlyX();
            Clear(Two);
            Observer.Observe('record, only the X row, used', TwoRecordIdOutcome(Two, RecId, true));
            Clear(Two);
            Observer.Observe('record, only the X row, unused', TwoRecordIdOutcome(Two, RecId, false));
            Observer.Observe('recordref, only the X row, used', RefRecordIdOutcome(RecId, true));
            Observer.Observe('recordref, only the X row, unused', RefRecordIdOutcome(RecId, false));
        end;
        Observer.Expect('evaluate', 'Yes REC GetFewer Two: Q');
        Observer.Expect('record, both rows, used', 'Yes Q//q-blank');
        Observer.Expect('record holds X, both rows, used', 'Yes Q//q-blank');
        Observer.Expect('recordref, both rows, used', 'Yes Q//q-blank');
        Observer.Expect('record, only the X row, used', 'No //');
        Observer.Expect('record, only the X row, unused', 'error:The REC GetFewer Two does not exist. Identification fields and values: A=''Q'',B=''''|DB:RecordNotFound record //');
        Observer.Expect('recordref, only the X row, used', 'No //');
        Observer.Expect('recordref, only the X row, unused', 'error:The REC GetFewer Two does not exist. Identification fields and values: A=''Q'',B=''''|DB:RecordNotFound record //');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TwoGetAssign(var Two: Record "REC GetFewer Two"; A: Code[10])
    begin
        Two.Get := A;
    end;

    // G16: the assignment form `Two.Get := 'Q'` on a two-field key: the call Get('Q') with the result not used.
    [Test]
    procedure Get_AssignmentForm_OneValueOfTwo()
    var
        Two: Record "REC GetFewer Two";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        SeedTwoBlankAndX();
        Clear(Two);
        Two.Get := 'Q';
        Observer.Observe('both rows', Show(Two));
        Clear(Two);
        Two.B := 'X';
        Ok := TwoGetAssign(Two, 'Q');
        Observer.Observe('both rows, record holds X', Unused(Ok, Two));
        SeedTwoOnlyX();
        Clear(Two);
        Ok := TwoGetAssign(Two, 'Q');
        Observer.Observe('only the X row', Unused(Ok, Two));
        Clear(Two);
        Ok := TwoGet1(Two, 'Q');
        Observer.Observe('only the X row, call form', Unused(Ok, Two));
        Observer.Expect('both rows', 'Q//q-blank');
        Observer.Expect('both rows, record holds X', 'ok Q//q-blank');
        Observer.Expect('only the X row', 'error:The REC GetFewer Two does not exist. Identification fields and values: A=''Q'',B=''''|DB:RecordNotFound record //');
        Observer.Expect('only the X row, call form', 'error:The REC GetFewer Two does not exist. Identification fields and values: A=''Q'',B=''''|DB:RecordNotFound record //');
        Observer.Verify();
    end;
}
