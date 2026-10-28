// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonvalue/jsonvalue-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunit 72502
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 72502 "LT JsT Value Getters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure DoGet(V: JsonValue; Kind: Text; var R: Text)
    begin
        case Kind of
            'AsInteger':
                R := Format(V.AsInteger());
            'AsBigInteger':
                R := Format(V.AsBigInteger());
            'AsDecimal':
                R := Format(V.AsDecimal());
            'AsBoolean':
                R := Format(V.AsBoolean());
            'AsDate':
                R := Format(V.AsDate(), 0, 9);
            'AsDateTime':
                R := Format(V.AsDateTime(), 0, 9);
            'AsTime':
                R := Format(V.AsTime(), 0, 9);
            'AsDuration':
                R := Format(V.AsDuration(), 0, 9);
            'AsChar':
                R := Format(V.AsChar());
            'AsText':
                R := V.AsText();
            'AsCode':
                R := V.AsCode();
        end;
    end;

    local procedure Try(V: JsonValue; Kind: Text): Text
    var
        R: Text;
    begin
        if DoGet(V, Kind, R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ValFrom(Json: Text) V: JsonValue
    var
        A: JsonArray;
        T: JsonToken;
    begin
        A.ReadFrom('[' + Json + ']');
        A.Get(0, T);
        V := T.AsValue();
    end;

    [Test]
    procedure NumberGetters()
    var
        V: JsonValue;
    begin
        V := ValFrom('42');
        Observer.Observe('int_asinteger', Try(V, 'AsInteger'));
        Observer.Observe('int_asbiginteger', Try(V, 'AsBigInteger'));
        Observer.Observe('int_asdecimal', Try(V, 'AsDecimal'));
        Observer.Observe('int_astext', Try(V, 'AsText'));
        Observer.Observe('int_ascode', Try(V, 'AsCode'));
        Observer.Observe('int_asboolean', Try(V, 'AsBoolean'));
        V := ValFrom('1.5');
        Observer.Observe('dec_asdecimal', Try(V, 'AsDecimal'));
        Observer.Observe('dec_asinteger', Try(V, 'AsInteger'));
        Observer.Observe('dec_asbiginteger', Try(V, 'AsBigInteger'));
        Observer.Observe('dec_astext', Try(V, 'AsText'));
        V := ValFrom('0');
        Observer.Observe('zero_asboolean', Try(V, 'AsBoolean'));
        V := ValFrom('-7');
        Observer.Observe('neg_asinteger', Try(V, 'AsInteger'));
        V := ValFrom('9223372036854775807');
        Observer.Observe('big_asbiginteger', Try(V, 'AsBigInteger'));
        Observer.Observe('big_asinteger', Try(V, 'AsInteger'));
        Observer.Expect('int_asinteger', 'ok:42');
        Observer.Expect('int_asbiginteger', 'ok:42');
        Observer.Expect('int_asdecimal', 'ok:42');
        Observer.Expect('int_astext', 'ok:42');
        Observer.Expect('int_ascode', 'ok:42');
        Observer.Expect('int_asboolean', 'ok:Yes');
        Observer.Expect('dec_asdecimal', 'ok:1.5');
        Observer.Expect('dec_asinteger', 'ok:2');
        Observer.Expect('dec_asbiginteger', 'ok:2');
        Observer.Expect('dec_astext', 'ok:1.5');
        Observer.Expect('zero_asboolean', 'ok:No');
        Observer.Expect('neg_asinteger', 'ok:-7');
        Observer.Expect('big_asbiginteger', 'ok:9223372036854775807');
        Observer.Expect('big_asinteger', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Int32.|Conversion');
        Observer.Verify();
    end;

    [Test]
    procedure NumberRanges()
    var
        V: JsonValue;
    begin
        V := ValFrom('2147483648');
        Observer.Observe('over_int_asbiginteger', Try(V, 'AsBigInteger'));
        Observer.Observe('over_int_asdecimal', Try(V, 'AsDecimal'));
        Observer.Observe('over_int_astext', Try(V, 'AsText'));
        V := ValFrom('-2147483649');
        Observer.Observe('under_int_asbiginteger', Try(V, 'AsBigInteger'));
        V := ValFrom('2147483647');
        Observer.Observe('intmax_asinteger', Try(V, 'AsInteger'));
        V := ValFrom('1e3');
        Observer.Observe('exp_asdecimal', Try(V, 'AsDecimal'));
        Observer.Observe('exp_astext', Try(V, 'AsText'));
        V := ValFrom('1.0');
        Observer.Observe('onepointzero_asdecimal', Try(V, 'AsDecimal'));
        Observer.Observe('onepointzero_astext', Try(V, 'AsText'));
        Observer.Observe('onepointzero_asinteger', Try(V, 'AsInteger'));
        V := ValFrom('123456789012345678901234567890');
        Observer.Observe('huge_astext', Try(V, 'AsText'));
        Observer.Observe('huge_asdecimal', Try(V, 'AsDecimal'));
        V := ValFrom('0.1');
        Observer.Observe('tenth_asdecimal', Try(V, 'AsDecimal'));
        V := ValFrom('0.30000000000000004');
        Observer.Observe('float_noise_asdecimal', Try(V, 'AsDecimal'));
        Observer.Observe('float_noise_astext', Try(V, 'AsText'));
        Observer.Expect('over_int_asbiginteger', 'ok:2147483648');
        Observer.Expect('over_int_asdecimal', 'ok:2,147,483,648');
        Observer.Expect('over_int_astext', 'ok:2147483648');
        Observer.Expect('under_int_asbiginteger', 'ok:-2147483649');
        Observer.Expect('intmax_asinteger', 'ok:2147483647');
        Observer.Expect('exp_asdecimal', 'ok:1,000');
        Observer.Expect('exp_astext', 'ok:1000');
        Observer.Expect('onepointzero_asdecimal', 'ok:1');
        Observer.Expect('onepointzero_astext', 'ok:1');
        Observer.Expect('onepointzero_asinteger', 'ok:1');
        Observer.Expect('huge_astext', 'ok:123456789012345678901234567890');
        Observer.Expect('huge_asdecimal', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.Decimal18.|Conversion');
        Observer.Expect('tenth_asdecimal', 'ok:0.1');
        Observer.Expect('float_noise_asdecimal', 'ok:0.3');
        Observer.Expect('float_noise_astext', 'ok:0.30000000000000004');
        Observer.Verify();
    end;

    [Test]
    procedure TextGetters()
    var
        V: JsonValue;
    begin
        V := ValFrom('"hello"');
        Observer.Observe('text_astext', Try(V, 'AsText'));
        Observer.Observe('text_ascode', Try(V, 'AsCode'));
        Observer.Observe('text_aschar', Try(V, 'AsChar'));
        Observer.Observe('text_asinteger', Try(V, 'AsInteger'));
        Observer.Observe('text_asdecimal', Try(V, 'AsDecimal'));
        Observer.Observe('text_asboolean', Try(V, 'AsBoolean'));
        Observer.Observe('text_asbiginteger', Try(V, 'AsBigInteger'));
        Observer.Observe('text_asdate', Try(V, 'AsDate'));
        Observer.Observe('text_asdatetime', Try(V, 'AsDateTime'));
        Observer.Observe('text_astime', Try(V, 'AsTime'));
        Observer.Observe('text_asduration', Try(V, 'AsDuration'));
        Observer.Expect('text_astext', 'ok:hello');
        Observer.Expect('text_ascode', 'ok:HELLO');
        Observer.Expect('text_aschar', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Char.|Conversion');
        Observer.Expect('text_asinteger', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Int32.|Conversion');
        Observer.Expect('text_asdecimal', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.Decimal18.|Conversion');
        Observer.Expect('text_asboolean', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Boolean.|Conversion');
        Observer.Expect('text_asbiginteger', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavBigInteger.|Conversion');
        Observer.Expect('text_asdate', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDate.|Conversion');
        Observer.Expect('text_asdatetime', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDateTime.|Conversion');
        Observer.Expect('text_astime', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavTime.|Conversion');
        Observer.Expect('text_asduration', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDuration.|Conversion');
        Observer.Verify();
    end;

    [Test]
    procedure NumericTextGetters()
    var
        V: JsonValue;
    begin
        V := ValFrom('"42"');
        Observer.Observe('numtext_asinteger', Try(V, 'AsInteger'));
        Observer.Observe('numtext_asdecimal', Try(V, 'AsDecimal'));
        V := ValFrom('"true"');
        Observer.Observe('truetext_asboolean', Try(V, 'AsBoolean'));
        V := ValFrom('""');
        Observer.Observe('empty_astext', Try(V, 'AsText'));
        Observer.Observe('empty_ascode', Try(V, 'AsCode'));
        Observer.Observe('empty_aschar', Try(V, 'AsChar'));
        V := ValFrom('"abcdefghijklmnopqrstuvwxyz0123456789"');
        Observer.Observe('long_ascode', Try(V, 'AsCode'));
        Observer.Observe('long_aschar', Try(V, 'AsChar'));
        V := ValFrom('"a"');
        Observer.Observe('single_aschar', Try(V, 'AsChar'));
        Observer.Expect('numtext_asinteger', 'ok:42');
        Observer.Expect('numtext_asdecimal', 'ok:42');
        Observer.Expect('truetext_asboolean', 'ok:Yes');
        Observer.Expect('empty_astext', 'ok:');
        Observer.Expect('empty_ascode', 'ok:');
        Observer.Expect('empty_aschar', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Char.|Conversion');
        Observer.Expect('long_ascode', 'ok:ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789');
        Observer.Expect('long_aschar', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Char.|Conversion');
        Observer.Expect('single_aschar', 'ok:a');
        Observer.Verify();
    end;

    [Test]
    procedure BooleanGetters()
    var
        V: JsonValue;
    begin
        V := ValFrom('true');
        Observer.Observe('true_asboolean', Try(V, 'AsBoolean'));
        Observer.Observe('true_astext', Try(V, 'AsText'));
        Observer.Observe('true_asinteger', Try(V, 'AsInteger'));
        Observer.Observe('true_asdecimal', Try(V, 'AsDecimal'));
        V := ValFrom('false');
        Observer.Observe('false_asboolean', Try(V, 'AsBoolean'));
        Observer.Observe('false_astext', Try(V, 'AsText'));
        Observer.Observe('false_ascode', Try(V, 'AsCode'));
        Observer.Observe('false_asdate', Try(V, 'AsDate'));
        Observer.Expect('true_asboolean', 'ok:Yes');
        Observer.Expect('true_astext', 'ok:true');
        Observer.Expect('true_asinteger', 'ok:1');
        Observer.Expect('true_asdecimal', 'ok:1');
        Observer.Expect('false_asboolean', 'ok:No');
        Observer.Expect('false_astext', 'ok:false');
        Observer.Expect('false_ascode', 'ok:FALSE');
        Observer.Expect('false_asdate', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDate.|Conversion');
        Observer.Verify();
    end;

    [Test]
    procedure NullGetters()
    var
        V: JsonValue;
    begin
        V := ValFrom('null');
        Observer.Observe('isnull', Format(V.IsNull()));
        Observer.Observe('isundefined', Format(V.IsUndefined()));
        Observer.Observe('astext', Try(V, 'AsText'));
        Observer.Observe('ascode', Try(V, 'AsCode'));
        Observer.Observe('asinteger', Try(V, 'AsInteger'));
        Observer.Observe('asbiginteger', Try(V, 'AsBigInteger'));
        Observer.Observe('asdecimal', Try(V, 'AsDecimal'));
        Observer.Observe('asboolean', Try(V, 'AsBoolean'));
        Observer.Observe('asdate', Try(V, 'AsDate'));
        Observer.Observe('asdatetime', Try(V, 'AsDateTime'));
        Observer.Observe('astime', Try(V, 'AsTime'));
        Observer.Observe('asduration', Try(V, 'AsDuration'));
        Observer.Observe('aschar', Try(V, 'AsChar'));
        Observer.Observe('format', Format(V));
        Observer.Expect('isnull', 'Yes');
        Observer.Expect('isundefined', 'No');
        Observer.Expect('astext', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavText.|Conversion');
        Observer.Expect('ascode', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavText.|Conversion');
        Observer.Expect('asinteger', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Int32.|Conversion');
        Observer.Expect('asbiginteger', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavBigInteger.|Conversion');
        Observer.Expect('asdecimal', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.Decimal18.|Conversion');
        Observer.Expect('asboolean', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Boolean.|Conversion');
        Observer.Expect('asdate', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDate.|Conversion');
        Observer.Expect('asdatetime', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDateTime.|Conversion');
        Observer.Expect('astime', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavTime.|Conversion');
        Observer.Expect('asduration', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDuration.|Conversion');
        Observer.Expect('aschar', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Char.|Conversion');
        Observer.Expect('format', 'null');
        Observer.Verify();
    end;

    [Test]
    procedure DateTimeGetters()
    var
        V: JsonValue;
    begin
        V := ValFrom('"2020-02-01"');
        Observer.Observe('isodate_asdate', Try(V, 'AsDate'));
        Observer.Observe('isodate_astext', Try(V, 'AsText'));
        V := ValFrom('"2020-02-01T12:34:56Z"');
        Observer.Observe('isodatetime_asdatetime', Try(V, 'AsDateTime'));
        Observer.Observe('isodatetime_asdate', Try(V, 'AsDate'));
        Observer.Observe('isodatetime_astime', Try(V, 'AsTime'));
        V := ValFrom('"12:34:56"');
        Observer.Observe('isotime_astime', Try(V, 'AsTime'));
        V := ValFrom('"2020-02-01T12:34:56.789"');
        Observer.Observe('isoms_asdatetime', Try(V, 'AsDateTime'));
        V := ValFrom('"2020-02-30"');
        Observer.Observe('baddate_asdate', Try(V, 'AsDate'));
        V := ValFrom('"P1D"');
        Observer.Observe('p1d_asduration', Try(V, 'AsDuration'));
        V := ValFrom('"1.02:03:04"');
        Observer.Observe('dotnet_duration', Try(V, 'AsDuration'));
        V := ValFrom('90000');
        Observer.Observe('num_asduration', Try(V, 'AsDuration'));
        Observer.Observe('num_asdate', Try(V, 'AsDate'));
        Observer.Expect('isodate_asdate', 'ok:2020-02-01');
        Observer.Expect('isodate_astext', 'ok:2020-02-01');
        Observer.Expect('isodatetime_asdatetime', 'ok:2020-02-01T12:34:56Z');
        Observer.Expect('isodatetime_asdate', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDate.|Conversion');
        Observer.Expect('isodatetime_astime', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavTime.|Conversion');
        Observer.Expect('isotime_astime', 'ok:12:34:56');
        Observer.Expect('isoms_asdatetime', 'ok:2020-02-01T12:34:56.789Z');
        Observer.Expect('baddate_asdate', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDate.|Conversion');
        Observer.Expect('p1d_asduration', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDuration.|Conversion');
        Observer.Expect('dotnet_duration', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDuration.|Conversion');
        Observer.Expect('num_asduration', 'ok:P0DT0H1M30.0S');
        Observer.Expect('num_asdate', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDate.|Conversion');
        Observer.Verify();
    end;

    [Test]
    procedure SetValueRoundtrip()
    var
        V: JsonValue;
        D: Date;
        DT: DateTime;
        Tm: Time;
        Dur: Duration;
        Big: BigInteger;
        C: Code[20];
        Ch: Char;
    begin
        D := DMY2Date(5, 6, 2021);
        DT := CreateDateTime(D, 101112T);
        Tm := 101112T;
        Dur := 3600000;
        Evaluate(Big, '5000000000');
        C := 'code1';
        Ch := 66;
        V.SetValue(D);
        Observer.Observe('date_astext', Try(V, 'AsText'));
        Observer.Observe('date_asdate', Try(V, 'AsDate'));
        V.SetValue(DT);
        Observer.Observe('datetime_astext', Try(V, 'AsText'));
        Observer.Observe('datetime_asdatetime', Try(V, 'AsDateTime'));
        V.SetValue(Tm);
        Observer.Observe('time_astext', Try(V, 'AsText'));
        Observer.Observe('time_astime', Try(V, 'AsTime'));
        V.SetValue(Dur);
        Observer.Observe('duration_astext', Try(V, 'AsText'));
        Observer.Observe('duration_asduration', Try(V, 'AsDuration'));
        V.SetValue(Big);
        Observer.Observe('big_astext', Try(V, 'AsText'));
        Observer.Observe('big_asbig', Try(V, 'AsBigInteger'));
        V.SetValue(C);
        Observer.Observe('code_astext', Try(V, 'AsText'));
        Observer.Observe('code_ascode', Try(V, 'AsCode'));
        V.SetValue(Ch);
        Observer.Observe('char_astext', Try(V, 'AsText'));
        Observer.Observe('char_asinteger', Try(V, 'AsInteger'));
        Observer.Expect('date_astext', 'ok:2021-06-05');
        Observer.Expect('date_asdate', 'ok:2021-06-05');
        Observer.Expect('datetime_astext', 'ok:2021-06-05T10:11:12.0000000Z');
        Observer.Expect('datetime_asdatetime', 'ok:2021-06-05T10:11:12Z');
        Observer.Expect('time_astext', 'ok:10:11:12');
        Observer.Expect('time_astime', 'ok:10:11:12');
        Observer.Expect('duration_astext', 'ok:3600000');
        Observer.Expect('duration_asduration', 'ok:P0DT1H0M0.0S');
        Observer.Expect('big_astext', 'ok:5000000000');
        Observer.Expect('big_asbig', 'ok:5000000000');
        Observer.Expect('code_astext', 'ok:CODE1');
        Observer.Expect('code_ascode', 'ok:CODE1');
        Observer.Expect('char_astext', 'ok:66');
        Observer.Expect('char_asinteger', 'ok:66');
        Observer.Verify();
    end;

    // Writer SQ (NP lane 2026-10-28): AsBigInteger, AsByte and AsOption of a JSON string that holds digits (AsInteger of "42" is NumericTextGetters).
    [TryFunction]
    local procedure SqDoGet(V: JsonValue; Kind: Text; var R: Text)
    begin
        case Kind of
            'AsBigInteger':
                R := Format(V.AsBigInteger());
            'AsByte':
                R := Format(V.AsByte());
            'AsOption':
                R := Format(V.AsOption());
            'AsInteger':
                R := Format(V.AsInteger());
        end;
    end;

    local procedure SqTry(V: JsonValue; Kind: Text): Text
    var
        R: Text;
    begin
        if SqDoGet(V, Kind, R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure SqRow(Json: Text): Text
    var
        V: JsonValue;
    begin
        V := ValFrom(Json);
        exit('big=' + SqTry(V, 'AsBigInteger') + ' ; byte=' + SqTry(V, 'AsByte') + ' ; option=' + SqTry(V, 'AsOption') + ' ; int=' + SqTry(V, 'AsInteger'));
    end;

    [Test]
    procedure Sq_DigitText_BigIntegerByteOption()
    begin
        Observer.Observe('text 42', SqRow('"42"'));
        Observer.Observe('text 7', SqRow('"7"'));
        Observer.Observe('text 0', SqRow('"0"'));
        Observer.Observe('text -5', SqRow('"-5"'));
        Observer.Observe('text 300', SqRow('"300"'));
        Observer.Observe('text 3000000000', SqRow('"3000000000"'));
        Observer.Observe('text 4.5', SqRow('"4.5"'));
        Observer.Observe('text space 42', SqRow('" 42"'));
        Observer.Observe('text 1,000', SqRow('"1,000"'));
        Observer.Observe('number 42', SqRow('42'));
        Observer.Observe('number 300', SqRow('300'));
        Observer.Finish();
    end;
}
