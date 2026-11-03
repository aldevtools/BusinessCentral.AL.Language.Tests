// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-joker-integer-integer-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunit 92860
// Probe: gap cycle 4, spec G4-16. Format of a JsonValue that holds a value, for each kind of value (SetValue overloads), next to WriteTo,
//        standard formats 0, 1, 2 and 9, the Format text read back through JsonToken.ReadFrom, and values read from JSON text.
//        Already pinned nearby: json/JsonValueSetters.al ValueAsToken (text, decimal 12.50, boolean at format 0).
//        Every value asserted is what BC 27.5, 28.5, 29.0 (CI containers) and a SaaS sandbox BC 29 produced, all the same. The DateTime values
//        come from CreateDateTime in a session whose time zone is UTC (all four).
// BC versions: 27, 28, 29

codeunit 92860 "LT Y44 Format JsonValue"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryFmt(V: JsonValue; Std: Integer; var Result: Text)
    begin
        Result := Format(V, 0, Std);
    end;

    local procedure Fmt(Name: Text; V: JsonValue; Std: Integer)
    var
        Result: Text;
    begin
        ClearLastError();
        if TryFmt(V, Std, Result) then
            Observer.Observe('fmt_' + Name + '_' + Format(Std), Result)
        else
            Observer.ObserveError('fmt_' + Name + '_' + Format(Std));
    end;

    local procedure WT(Name: Text; V: JsonValue)
    var
        Txt: Text;
    begin
        V.WriteTo(Txt);
        Observer.Observe('wt_' + Name, Txt);
    end;

    local procedure Both(Name: Text; V: JsonValue)
    begin
        Fmt(Name, V, 0);
        WT(Name, V);
    end;

    local procedure Quoted(): Text
    var
        Tab: Text[1];
    begin
        Tab[1] := 9;
        exit('He said "hi"\' + Tab + 'x');
    end;

    [Test]
    procedure FormatJsonValue_Numbers()
    var
        V: JsonValue;
        I: Integer;
        Bi: BigInteger;
        D: Decimal;
        By: Byte;
        Du: Duration;
        Op: Option A,B,C,D;
    begin
        I := 42;
        V.SetValue(I);
        Both('int42', V);
        I := -1313548468;
        V.SetValue(I);
        Both('intneg', V);
        Bi := 9007199254740993L;
        V.SetValue(Bi);
        Both('bigint', V);
        Bi := -5;
        V.SetValue(Bi);
        Both('bigneg', V);
        D := 12.5;
        V.SetValue(D);
        Both('dec12_5', V);
        D := -0.001;
        V.SetValue(D);
        Both('decneg', V);
        D := 1234567.89;
        V.SetValue(D);
        Both('decbig', V);
        By := 7;
        V.SetValue(By);
        Both('byte', V);
        Du := 1234567;
        V.SetValue(Du);
        Both('duration', V);
        Op := Op::D;
        V.SetValue(Op);
        Both('option', V);
        Observer.Expect('fmt_int42_0', '42');
        Observer.Expect('wt_int42', '42');
        Observer.Expect('fmt_intneg_0', '-1313548468');
        Observer.Expect('wt_intneg', '-1313548468');
        Observer.Expect('fmt_bigint_0', '9007199254740993');
        Observer.Expect('wt_bigint', '9007199254740993');
        Observer.Expect('fmt_bigneg_0', '-5');
        Observer.Expect('wt_bigneg', '-5');
        Observer.Expect('fmt_dec12_5_0', '12.5');
        Observer.Expect('wt_dec12_5', '12.5');
        Observer.Expect('fmt_decneg_0', '-0.001');
        Observer.Expect('wt_decneg', '-0.001');
        Observer.Expect('fmt_decbig_0', '1234567.89');
        Observer.Expect('wt_decbig', '1234567.89');
        Observer.Expect('fmt_byte_0', '7');
        Observer.Expect('wt_byte', '7');
        Observer.Expect('fmt_duration_0', '1234567');
        Observer.Expect('wt_duration', '1234567');
        Observer.Expect('fmt_option_0', '3');
        Observer.Expect('wt_option', '3');
        Observer.Verify();
    end;

    [Test]
    procedure FormatJsonValue_TextLike()
    var
        V: JsonValue;
        T: Text;
        C: Code[10];
        Ch: Char;
    begin
        T := Quoted();
        V.SetValue(T);
        Both('text', V);
        C := 'AB1';
        V.SetValue(C);
        Both('code', V);
        Ch := 'A';
        V.SetValue(Ch);
        Both('charA', V);
        Ch := 34;
        V.SetValue(Ch);
        Both('charquote', V);
        T := '';
        V.SetValue(T);
        Both('textempty', V);
        V.SetValue(false);
        Both('false', V);
        Observer.Expect('fmt_text_0', '"He said \"hi\"\\\tx"');
        Observer.Expect('wt_text', '"He said \"hi\"\\\tx"');
        Observer.Expect('fmt_code_0', '"AB1"');
        Observer.Expect('wt_code', '"AB1"');
        Observer.Expect('fmt_charA_0', '65');
        Observer.Expect('wt_charA', '65');
        Observer.Expect('fmt_charquote_0', '34');
        Observer.Expect('wt_charquote', '34');
        Observer.Expect('fmt_textempty_0', '""');
        Observer.Expect('wt_textempty', '""');
        Observer.Expect('fmt_false_0', 'false');
        Observer.Expect('wt_false', 'false');
        Observer.Verify();
    end;

    [Test]
    procedure FormatJsonValue_DateTime()
    var
        V: JsonValue;
        Dt: Date;
        Tm: Time;
        DT2: DateTime;
    begin
        Dt := 20240315D;
        V.SetValue(Dt);
        Both('date', V);
        Dt := 0D;
        V.SetValue(Dt);
        Both('date0', V);
        Tm := 143015.123T;
        V.SetValue(Tm);
        Both('time', V);
        Tm := 0T;
        V.SetValue(Tm);
        Both('time0', V);
        DT2 := CreateDateTime(20240315D, 143015.123T);
        V.SetValue(DT2);
        Both('datetime', V);
        DT2 := 0DT;
        V.SetValue(DT2);
        Both('datetime0', V);
        Observer.Expect('fmt_date_0', '"2024-03-15"');
        Observer.Expect('wt_date', '"2024-03-15"');
        Observer.Expect('fmt_date0_0', '"0001-01-01"');
        Observer.Expect('wt_date0', '"0001-01-01"');
        Observer.Expect('fmt_time_0', '"14:30:15.123"');
        Observer.Expect('wt_time', '"14:30:15.123"');
        Observer.Expect('fmt_time0_0', '"00:00:00"');
        Observer.Expect('wt_time0', '"00:00:00"');
        Observer.Expect('fmt_datetime_0', '"2024-03-15T14:30:15.1230000Z"');
        Observer.Expect('wt_datetime', '"2024-03-15T14:30:15.1230000Z"');
        Observer.Expect('fmt_datetime0_0', '"0001-01-01T00:00:00.0000000"');
        Observer.Expect('wt_datetime0', '"0001-01-01T00:00:00.0000000"');
        Observer.Verify();
    end;

    local procedure AllStd(Name: Text; V: JsonValue)
    begin
        Fmt(Name, V, 1);
        Fmt(Name, V, 2);
        Fmt(Name, V, 9);
    end;

    [Test]
    procedure FormatJsonValue_StandardFormats_Scalars()
    var
        V: JsonValue;
        I: Integer;
        D: Decimal;
        T: Text;
    begin
        I := 42;
        V.SetValue(I);
        AllStd('int', V);
        D := 1234567.89;
        V.SetValue(D);
        AllStd('dec', V);
        V.SetValue(true);
        AllStd('bool', V);
        T := 'x';
        V.SetValue(T);
        AllStd('text', V);
        Observer.Expect('fmt_int_1', '42');
        Observer.Expect('fmt_int_2', '42');
        Observer.Expect('fmt_int_9|text', 'Standard format number 9 does not exist for the type ''JsonValue''.');
        Observer.Expect('fmt_int_9|code', 'InvalidStandardFormat');
        Observer.Expect('fmt_dec_1', '1234567.89');
        Observer.Expect('fmt_dec_2', '1234567.89');
        Observer.Expect('fmt_dec_9|text', 'Standard format number 9 does not exist for the type ''JsonValue''.');
        Observer.Expect('fmt_dec_9|code', 'InvalidStandardFormat');
        Observer.Expect('fmt_bool_1', 'true');
        Observer.Expect('fmt_bool_2', 'true');
        Observer.Expect('fmt_bool_9|text', 'Standard format number 9 does not exist for the type ''JsonValue''.');
        Observer.Expect('fmt_bool_9|code', 'InvalidStandardFormat');
        Observer.Expect('fmt_text_1', '"x"');
        Observer.Expect('fmt_text_2', '"x"');
        Observer.Expect('fmt_text_9|text', 'Standard format number 9 does not exist for the type ''JsonValue''.');
        Observer.Expect('fmt_text_9|code', 'InvalidStandardFormat');
        Observer.Verify();
    end;

    [Test]
    procedure FormatJsonValue_StandardFormats_DatesAndNull()
    var
        V: JsonValue;
        Dt: Date;
        DT2: DateTime;
    begin
        Dt := 20240315D;
        V.SetValue(Dt);
        AllStd('date', V);
        DT2 := CreateDateTime(20240315D, 143015.123T);
        V.SetValue(DT2);
        AllStd('datetime', V);
        V.SetValueToNull();
        AllStd('null', V);
        Observer.Expect('fmt_date_1', '"2024-03-15"');
        Observer.Expect('fmt_date_2', '"2024-03-15"');
        Observer.Expect('fmt_date_9|text', 'Standard format number 9 does not exist for the type ''JsonValue''.');
        Observer.Expect('fmt_date_9|code', 'InvalidStandardFormat');
        Observer.Expect('fmt_datetime_1', '"2024-03-15T14:30:15.1230000Z"');
        Observer.Expect('fmt_datetime_2', '"2024-03-15T14:30:15.1230000Z"');
        Observer.Expect('fmt_datetime_9|text', 'Standard format number 9 does not exist for the type ''JsonValue''.');
        Observer.Expect('fmt_datetime_9|code', 'InvalidStandardFormat');
        Observer.Expect('fmt_null_1', 'null');
        Observer.Expect('fmt_null_2', 'null');
        Observer.Expect('fmt_null_9|text', 'Standard format number 9 does not exist for the type ''JsonValue''.');
        Observer.Expect('fmt_null_9|code', 'InvalidStandardFormat');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadFrom(Src: Text; var Tok: JsonToken; var Answer: Boolean)
    begin
        Answer := Tok.ReadFrom(Src);
    end;

    local procedure ReadBack(Name: Text; V: JsonValue)
    var
        Tok: JsonToken;
        A: JsonToken;
        Answer: Boolean;
        Txt: Text;
    begin
        ClearLastError();
        if not TryReadFrom('{"a":' + Format(V) + '}', Tok, Answer) then begin
            Observer.ObserveError('readfrom_' + Name);
            exit;
        end;
        Observer.Observe('readfrom_' + Name, Format(Answer));
        if not Answer then
            exit;
        if Tok.SelectToken('a', A) then begin
            A.WriteTo(Txt);
            Observer.Observe('back_' + Name, Txt);
        end else
            Observer.Observe('back_' + Name, '<no a>');
    end;

    [Test]
    procedure FormatJsonValue_ReadBack()
    var
        V: JsonValue;
        I: Integer;
        T: Text;
        Dt: Date;
        Tm: Time;
        DT2: DateTime;
        Du: Duration;
    begin
        I := -1313548468;
        V.SetValue(I);
        ReadBack('int', V);
        T := Quoted();
        V.SetValue(T);
        ReadBack('text', V);
        Dt := 20240315D;
        V.SetValue(Dt);
        ReadBack('date', V);
        DT2 := CreateDateTime(20240315D, 143015.123T);
        V.SetValue(DT2);
        ReadBack('datetime', V);
        Tm := 143015.123T;
        V.SetValue(Tm);
        ReadBack('time', V);
        Du := 1234567;
        V.SetValue(Du);
        ReadBack('duration', V);
        Observer.Expect('readfrom_int', 'Yes');
        Observer.Expect('back_int', '-1313548468');
        Observer.Expect('readfrom_text', 'Yes');
        Observer.Expect('back_text', '"He said \"hi\"\\\tx"');
        Observer.Expect('readfrom_date', 'Yes');
        Observer.Expect('back_date', '"2024-03-15"');
        Observer.Expect('readfrom_datetime', 'Yes');
        Observer.Expect('back_datetime', '"2024-03-15T14:30:15.1230000Z"');
        Observer.Expect('readfrom_time', 'Yes');
        Observer.Expect('back_time', '"14:30:15.123"');
        Observer.Expect('readfrom_duration', 'Yes');
        Observer.Expect('back_duration', '1234567');
        Observer.Verify();
    end;

    [Test]
    procedure FormatJsonValue_FromReadFrom()
    var
        Tok: JsonToken;
        M: JsonToken;
        Name: Text;
        Names: List of [Text];
    begin
        Tok.ReadFrom('{"n":42,"d":12.50,"e":1.0E2,"s":"x","b":false,"z":null}');
        Names.AddRange('n', 'd', 'e', 's', 'b', 'z');
        foreach Name in Names do begin
            Tok.SelectToken(Name, M);
            Both('read_' + Name, M.AsValue());
        end;
        Observer.Expect('fmt_read_n_0', '42');
        Observer.Expect('wt_read_n', '42');
        Observer.Expect('fmt_read_d_0', '12.5');
        Observer.Expect('wt_read_d', '12.5');
        Observer.Expect('fmt_read_e_0', '100.0');
        Observer.Expect('wt_read_e', '100.0');
        Observer.Expect('fmt_read_s_0', '"x"');
        Observer.Expect('wt_read_s', '"x"');
        Observer.Expect('fmt_read_b_0', 'false');
        Observer.Expect('wt_read_b', 'false');
        Observer.Expect('fmt_read_z_0', 'null');
        Observer.Expect('wt_read_z', 'null');
        Observer.Verify();
    end;
}
