// Probe: the value of a FieldRef (RecordRef.Field(..).Value / FieldIndex(..).Value) passed into a by-value Text or Code parameter, assigned to
// a Text or Code variable, and appended with TextBuilder.Append, for an Enum field (captions differ from names) and for every other field type
// (a loop that appends every field of a row, as an error text that lists a record does).
// Gap cycle 5, spec G5-08 (writer Y49). Object ids: enum 92941, table 92941, codeunit 92941.
// Fixtures used: Probe Observer (codeunit 69160).
// Culture: the corpus tier runs en-US; Date, DateTime and Decimal texts depend on it.

enum 92941 "LT Y49 Kind"
{
    Extensible = true;
    value(0; " ") { Caption = ' '; }
    value(1; Alpha) { Caption = 'Alpha Cap'; }
    value(2; "Beta Two") { Caption = 'Beta Cap'; }
}

table 92941 "LT Y49 All Types"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "LT Y49 Kind") { }
        field(3; Opt; Option) { OptionMembers = " ",Red,Green; OptionCaption = ' ,Red Cap,Green Cap'; }
        field(4; Int; Integer) { }
        field(5; Big; BigInteger) { }
        field(6; Dec; Decimal) { }
        field(7; Txt; Text[30]) { }
        field(8; Cde; Code[20]) { }
        field(9; D; Date) { }
        field(10; Tm; Time) { }
        field(11; Dt; DateTime) { }
        field(12; Dur; Duration) { }
        field(13; G; Guid) { }
        field(14; Df; DateFormula) { }
        field(15; Flag; Boolean) { }
        field(16; Bin; Blob) { }
        field(17; Pic; Media) { }
        field(18; Pics; MediaSet) { }
        field(19; Rid; RecordId) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 92941 "LT Y49 FieldRef Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Row: Record "LT Y49 All Types";
        OutS: OutStream;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Kind := Row.Kind::"Beta Two";
        Row.Opt := Row.Opt::Green;
        Row.Int := 12345;
        Row.Big := 9876543210L;
        Row.Dec := 1234.5;
        Row.Txt := 'Hello World';
        Row.Cde := 'ABC-1';
        Row.D := 20240305D;
        Row.Tm := 134506T;
        Row.Dt := CreateDateTime(20240305D, 134506T);
        Row.Dur := 3600000;
        Evaluate(Row.G, '{3F2504E0-4F89-11D3-9A0C-0305E82C3301}');
        Evaluate(Row.Df, '<1M>');
        Row.Flag := true;
        Row.Bin.CreateOutStream(OutS);
        OutS.WriteText('abc');
        Row.Insert();
        Row.Rid := Row.RecordId;
        Row.Modify();
        Row.Init();
        Row.Id := 2;
        Row.Insert();
    end;

    procedure TakeText250(Value: Text[250]): Text
    begin
        exit(Value);
    end;

    procedure TakeText(Value: Text): Text
    begin
        exit(Value);
    end;

    procedure TakeCode20(Value: Code[20]): Text
    begin
        exit(Value);
    end;

    procedure TakeCode3(Value: Code[3]): Text
    begin
        exit(Value);
    end;

    // Kind: 1 Text[250], 2 Text, 3 Code[20], 4 Code[3]
    [TryFunction]
    local procedure TryTake(var RecRef: RecordRef; FieldNo: Integer; Kind: Integer; var Res: Text)
    begin
        case Kind of
            1:
                Res := TakeText250(RecRef.Field(FieldNo).Value());
            2:
                Res := TakeText(RecRef.Field(FieldNo).Value());
            3:
                Res := TakeCode20(RecRef.Field(FieldNo).Value());
            4:
                Res := TakeCode3(RecRef.Field(FieldNo).Value());
        end;
    end;

    local procedure ObsTake(Name: Text; var RecRef: RecordRef; FieldNo: Integer; Kind: Integer)
    var
        Res: Text;
    begin
        ClearLastError();
        if TryTake(RecRef, FieldNo, Kind, Res) then
            Observer.Observe(Name, '[' + Res + ']')
        else begin
            Observer.Observe(Name, 'raised');
            Observer.ObserveError(Name);
        end;
    end;

    // Kind: 1 Text, 2 Text[250], 3 Code[20], 4 Code[3]
    [TryFunction]
    local procedure TryAssign(var RecRef: RecordRef; FieldNo: Integer; Kind: Integer; var Res: Text)
    var
        T: Text;
        T250: Text[250];
        C20: Code[20];
        C3: Code[3];
    begin
        case Kind of
            1:
                begin
                    T := RecRef.Field(FieldNo).Value();
                    Res := T;
                end;
            2:
                begin
                    T250 := RecRef.Field(FieldNo).Value();
                    Res := T250;
                end;
            3:
                begin
                    C20 := RecRef.Field(FieldNo).Value();
                    Res := C20;
                end;
            4:
                begin
                    C3 := RecRef.Field(FieldNo).Value();
                    Res := C3;
                end;
        end;
    end;

    local procedure ObsAssign(Name: Text; var RecRef: RecordRef; FieldNo: Integer; Kind: Integer)
    var
        Res: Text;
    begin
        ClearLastError();
        if TryAssign(RecRef, FieldNo, Kind, Res) then
            Observer.Observe(Name, '[' + Res + ']')
        else begin
            Observer.Observe(Name, 'raised');
            Observer.ObserveError(Name);
        end;
    end;

    [TryFunction]
    local procedure TryAppend(var TB: TextBuilder; var RecRef: RecordRef; Index: Integer)
    begin
        TB.Append(RecRef.FieldIndex(Index).Value());
    end;

    local procedure AppendAll(Prefix: Text; var RecRef: RecordRef; FromIndex: Integer; ToIndex: Integer)
    var
        TB: TextBuilder;
        Part: TextBuilder;
        Index: Integer;
    begin
        for Index := FromIndex to ToIndex do begin
            Clear(Part);
            ClearLastError();
            if TryAppend(Part, RecRef, Index) then begin
                Observer.Observe(Prefix + ' ' + RecRef.FieldIndex(Index).Name, '[' + Part.ToText() + ']');
                TB.Append(Part.ToText());
            end else begin
                Observer.Observe(Prefix + ' ' + RecRef.FieldIndex(Index).Name, 'raised');
                Observer.ObserveError(Prefix + ' ' + RecRef.FieldIndex(Index).Name);
            end;
            TB.Append('|');
        end;
        Observer.Observe(Prefix + ' all', TB.ToText());
    end;

    [Test]
    procedure FrEnum_IntoText250Param()
    var
        Row: Record "LT Y49 All Types";
        RecRef: RecordRef;
    begin
        Seed();
        Row.Get(1);
        RecRef.GetTable(Row);
        ObsTake('beta two text250', RecRef, 2, 1);
        ObsTake('beta two text', RecRef, 2, 2);
        ObsTake('beta two code20', RecRef, 2, 3);
        ObsTake('beta two code3', RecRef, 2, 4);
        Row.Kind := Row.Kind::Alpha;
        RecRef.GetTable(Row);
        ObsTake('alpha text250', RecRef, 2, 1);
        Row.Kind := Row.Kind::" ";
        RecRef.GetTable(Row);
        ObsTake('blank text250', RecRef, 2, 1);
        Observer.Expect('beta two text250', '[Beta Cap]');
        Observer.Expect('beta two text', '[Beta Cap]');
        Observer.Expect('beta two code20', '[BETA CAP]');
        Observer.Expect('beta two code3', 'raised');
        Observer.Expect('beta two code3|text', 'The length of the string is 8, but it must be less than or equal to 3 characters. Value: Beta Cap');
        Observer.Expect('beta two code3|code', 'StringLengthExceeded');
        Observer.Expect('alpha text250', '[Alpha Cap]');
        Observer.Expect('blank text250', '[ ]');
        Observer.Verify();
    end;

    [Test]
    procedure FrEnum_IntoTextVariable()
    var
        Row: Record "LT Y49 All Types";
        RecRef: RecordRef;
    begin
        Seed();
        Row.Get(1);
        RecRef.GetTable(Row);
        ObsAssign('beta two text', RecRef, 2, 1);
        ObsAssign('beta two text250', RecRef, 2, 2);
        ObsAssign('beta two code20', RecRef, 2, 3);
        ObsAssign('beta two code3', RecRef, 2, 4);
        Row.Kind := Row.Kind::Alpha;
        RecRef.GetTable(Row);
        ObsAssign('alpha code3', RecRef, 2, 4);
        Row.Kind := Row.Kind::" ";
        RecRef.GetTable(Row);
        ObsAssign('blank text', RecRef, 2, 1);
        ObsAssign('blank code20', RecRef, 2, 3);
        Observer.Expect('beta two text', '[Beta Cap]');
        Observer.Expect('beta two text250', '[Beta Cap]');
        Observer.Expect('beta two code20', '[BETA CAP]');
        Observer.Expect('beta two code3', 'raised');
        Observer.Expect('beta two code3|text', 'The length of the string is 8, but it must be less than or equal to 3 characters. Value: Beta Cap');
        Observer.Expect('beta two code3|code', 'StringLengthExceeded');
        Observer.Expect('alpha code3', 'raised');
        Observer.Expect('alpha code3|text', 'The length of the string is 9, but it must be less than or equal to 3 characters. Value: Alpha Cap');
        Observer.Expect('alpha code3|code', 'StringLengthExceeded');
        Observer.Expect('blank text', '[ ]');
        Observer.Expect('blank code20', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure FrEnum_RoundTripEvaluate()
    var
        Row: Record "LT Y49 All Types";
        Fresh: Record "LT Y49 All Types";
        RecRef: RecordRef;
        FreshRef: RecordRef;
        FR: FieldRef;
        R: Text;
        Ok: Boolean;
        Kind: Enum "LT Y49 Kind";
    begin
        Seed();
        Row.Get(1);
        RecRef.GetTable(Row);
        R := TakeText250(RecRef.Field(2).Value());
        FreshRef.Open(Database::"LT Y49 All Types");
        FreshRef.Init();
        FR := FreshRef.Field(2);
        ClearLastError();
        Ok := Evaluate(Kind, R);
        Observer.Observe('evaluate enum var', Format(Ok) + ' ' + Format(Kind.AsInteger()));
        ClearLastError();
        if TryValidateText(FR, R) then
            Observer.Observe('fieldref validate text', 'ok ' + Format(FR.Value) + ' ' + Format(FR.Value, 0, 9))
        else begin
            Observer.Observe('fieldref validate text', 'raised');
            Observer.ObserveError('fieldref validate text');
        end;
        Fresh.Init();
        ClearLastError();
        Ok := Evaluate(Fresh.Kind, R);
        Observer.Observe('evaluate enum field', Format(Ok) + ' ' + Format(Fresh.Kind.AsInteger()));
        Ok := Evaluate(Fresh.Kind, 'Beta Two');
        Observer.Observe('evaluate enum field name', Format(Ok) + ' ' + Format(Fresh.Kind.AsInteger()));
        Observer.Expect('evaluate enum var', 'Yes 2');
        Observer.Expect('fieldref validate text', 'raised');
#if BC28PLUS
        Observer.Expect('fieldref validate text|text', 'The value "Beta Cap" can''t be evaluated into type Option.');
        Observer.Expect('fieldref validate text|code', 'Evaluate:Format');
#else
        // BC 27.5 (Windows container): another error for the same call.
        Observer.Expect('fieldref validate text|text', 'The type NavOption is unknown.');
        Observer.Expect('fieldref validate text|code', 'NotSupportedType');
#endif
        Observer.Expect('evaluate enum field', 'Yes 2');
        Observer.Expect('evaluate enum field name', 'Yes 2');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryValidateText(var FR: FieldRef; R: Text)
    begin
        FR.Validate(R);
    end;

    [Test]
    procedure FrNumberAndOption_IntoTextParam()
    var
        Row: Record "LT Y49 All Types";
        RecRef: RecordRef;
    begin
        Seed();
        Row.Get(1);
        RecRef.GetTable(Row);
        ObsTake('int text250', RecRef, 4, 1);
        ObsTake('int text', RecRef, 4, 2);
        ObsTake('int code20', RecRef, 4, 3);
        ObsTake('int code3', RecRef, 4, 4);
        ObsTake('dec text250', RecRef, 6, 1);
        ObsTake('big text250', RecRef, 5, 1);
        ObsTake('opt text250', RecRef, 3, 1);
        ObsTake('opt code20', RecRef, 3, 3);
        ObsTake('flag text250', RecRef, 15, 1);
        ObsTake('date text250', RecRef, 9, 1);
        ObsTake('guid text250', RecRef, 13, 1);
        Observer.Expect('int text250', '[12345]');
        Observer.Expect('int text', '[12345]');
        Observer.Expect('int code20', '[12345]');
        Observer.Expect('int code3', 'raised');
        Observer.Expect('int code3|text', 'The length of the string is 5, but it must be less than or equal to 3 characters. Value: 12345');
        Observer.Expect('int code3|code', 'StringLengthExceeded');
        Observer.Expect('dec text250', '[1,234.5]');
        Observer.Expect('big text250', '[9876543210]');
        Observer.Expect('opt text250', '[Green Cap]');
        Observer.Expect('opt code20', '[GREEN CAP]');
        Observer.Expect('flag text250', '[Yes]');
        Observer.Expect('date text250', '[03/05/24]');
        Observer.Expect('guid text250', '[{3F2504E0-4F89-11D3-9A0C-0305E82C3301}]');
        Observer.Verify();
    end;

    [Test]
    procedure TbAppend_FieldIndexValue_AllTypes()
    var
        Row: Record "LT Y49 All Types";
        RecRef: RecordRef;
    begin
        Seed();
        Row.Get(1);
        RecRef.GetTable(Row);
        Observer.Observe('field count', Format(RecRef.FieldCount()));
        AppendAll('filled', RecRef, 1, 10);
        Observer.Expect('field count', '19');
        Observer.Expect('filled Id', '[1]');
        Observer.Expect('filled Kind', '[Beta Cap]');
        Observer.Expect('filled Opt', '[Green Cap]');
        Observer.Expect('filled Int', '[12345]');
        Observer.Expect('filled Big', '[9876543210]');
        Observer.Expect('filled Dec', '[1,234.5]');
        Observer.Expect('filled Txt', '[Hello World]');
        Observer.Expect('filled Cde', '[ABC-1]');
        Observer.Expect('filled D', '[03/05/24]');
        Observer.Expect('filled Tm', '[ 1:45:06 PM]');
        Observer.Expect('filled all', '1|Beta Cap|Green Cap|12345|9876543210|1,234.5|Hello World|ABC-1|03/05/24| 1:45:06 PM|');
        Observer.Verify();
    end;

    [Test]
    procedure TbAppend_FieldIndexValue_AllTypes_Part2()
    var
        Row: Record "LT Y49 All Types";
        RecRef: RecordRef;
    begin
        Seed();
        Row.Get(1);
        RecRef.GetTable(Row);
        AppendAll('filled', RecRef, 11, RecRef.FieldCount());
        Observer.Expect('filled Dt', '[03/05/24 01:45 PM]');
        Observer.Expect('filled Dur', '[1 hour]');
        Observer.Expect('filled G', '[{3F2504E0-4F89-11D3-9A0C-0305E82C3301}]');
        Observer.Expect('filled Df', '[1M]');
        Observer.Expect('filled Flag', '[Yes]');
        Observer.Expect('filled Bin', '[*]');
        Observer.Expect('filled Pic', '[{00000000-0000-0000-0000-000000000000}]');
        Observer.Expect('filled Pics', '[{00000000-0000-0000-0000-000000000000}]');
        Observer.Expect('filled Rid', '[LT Y49 All Types: 1]');
        Observer.Expect('filled all', '03/05/24 01:45 PM|1 hour|{3F2504E0-4F89-11D3-9A0C-0305E82C3301}|1M|Yes|*|{00000000-0000-0000-0000-000000000000}|{00000000-0000-0000-0000-000000000000}|LT Y49 All Types: 1|');
        Observer.Verify();
    end;

    [Test]
    procedure TbAppend_FieldIndexValue_AllTypes_Blank()
    var
        Row: Record "LT Y49 All Types";
        RecRef: RecordRef;
    begin
        Seed();
        Row.Get(2);
        RecRef.GetTable(Row);
        AppendAll('blank', RecRef, 1, 10);
        Observer.Expect('blank Id', '[2]');
        Observer.Expect('blank Kind', '[ ]');
        Observer.Expect('blank Opt', '[ ]');
        Observer.Expect('blank Int', '[0]');
        Observer.Expect('blank Big', '[0]');
        Observer.Expect('blank Dec', '[0]');
        Observer.Expect('blank Txt', '[]');
        Observer.Expect('blank Cde', '[]');
        Observer.Expect('blank D', '[]');
        Observer.Expect('blank Tm', '[]');
        Observer.Expect('blank all', '2| | |0|0|0|||||');
        Observer.Verify();
    end;

    [Test]
    procedure TbAppend_FieldIndexValue_AllTypes_Blank_Part2()
    var
        Row: Record "LT Y49 All Types";
        RecRef: RecordRef;
    begin
        Seed();
        Row.Get(2);
        RecRef.GetTable(Row);
        AppendAll('blank', RecRef, 11, RecRef.FieldCount());
        Observer.Expect('blank Dt', '[]');
        Observer.Expect('blank Dur', '[]');
        Observer.Expect('blank G', '[{00000000-0000-0000-0000-000000000000}]');
        Observer.Expect('blank Df', '[]');
        Observer.Expect('blank Flag', '[No]');
        Observer.Expect('blank Bin', '[ ]');
        Observer.Expect('blank Pic', '[{00000000-0000-0000-0000-000000000000}]');
        Observer.Expect('blank Pics', '[{00000000-0000-0000-0000-000000000000}]');
        Observer.Expect('blank Rid', '[]');
        Observer.Expect('blank all', '||{00000000-0000-0000-0000-000000000000}||No| |{00000000-0000-0000-0000-000000000000}|{00000000-0000-0000-0000-000000000000}||');
        Observer.Verify();
    end;
}
