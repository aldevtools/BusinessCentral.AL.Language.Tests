// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT VaT Helper (71026), table LT VaT Rec (71027)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71035 "LT VaT Format Evaluate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Format_Of_Variants()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        G: Guid;
        O: Option A,B,C;
    begin
        V := 5; Observer.Observe('int', Format(V));
        V := -5; Observer.Observe('int_neg', Format(V));
        V := 1.5; Observer.Observe('dec', Format(V));
        V := 1000000.25; Observer.Observe('dec_large', Format(V));
        V := 'text'; Observer.Observe('text', Format(V));
        V := true; Observer.Observe('bool_true', Format(V));
        V := false; Observer.Observe('bool_false', Format(V));
        V := DMY2Date(5, 6, 2020); Observer.Observe('date', Format(V));
        V := 0D; Observer.Observe('date_0', Format(V));
        V := 123456T; Observer.Observe('time', Format(V));
        V := 0T; Observer.Observe('time_0', Format(V));
        V := CreateDateTime(DMY2Date(5, 6, 2020), 123456T); Observer.Observe('datetime', Format(V));
        V := 0DT; Observer.Observe('datetime_0', Format(V));
        V := G; Observer.Observe('guid_null', Format(V));
        O := O::B; V := O; Observer.Observe('option', Format(V));
        V := 12.345; Observer.Observe('dec_format_fmt', Format(V, 0, '<Precision,1:1><Standard Format,0>'));
        V := DMY2Date(5, 6, 2020); Observer.Observe('date_format_9', Format(V, 0, 9));
        V := 1.5; Observer.Observe('dec_format_9', Format(V, 0, 9));
        V := true; Observer.Observe('bool_format_9', Format(V, 0, 9));
        V := 1000; Observer.Observe('int_format_len', Format(V, 8));
        Observer.Expect('int', '5');
        Observer.Expect('int_neg', '-5');
        Observer.Expect('dec', '1.5');
        Observer.Expect('dec_large', '1,000,000.25');
        Observer.Expect('text', 'text');
        Observer.Expect('bool_true', 'Yes');
        Observer.Expect('bool_false', 'No');
        Observer.Expect('date', '06/05/20');
        Observer.Expect('date_0', '');
        Observer.Expect('time', '12:34:56 PM');
        Observer.Expect('time_0', '');
        Observer.Expect('datetime', '06/05/20 12:34 PM');
        Observer.Expect('datetime_0', '');
        Observer.Expect('guid_null', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('option', 'B');
        Observer.Expect('dec_format_fmt', '12.3');
        Observer.Expect('date_format_9', '2020-06-05');
        Observer.Expect('dec_format_9', '1.5');
        Observer.Expect('bool_format_9', 'true');
        Observer.Expect('int_format_len', '    1000');
        Observer.Verify();
    end;

    [Test]
    procedure Format_Of_Duration_BigInteger_Char_Byte_Enum()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        Du: Duration;
        B: BigInteger;
        Ch: Char;
        By: Byte;
        E: Enum "LT VaT Enum";
    begin
        Du := 90000; V := Du; Observer.Observe('duration', Format(V));
        Evaluate(B, '12345678901'); V := B; Observer.Observe('bigint', Format(V));
        Ch := 65; V := Ch; Observer.Observe('char', Format(V));
        By := 66; V := By; Observer.Observe('byte', Format(V));
        V := E::Five; Observer.Observe('enum', Format(V));
        V := E::Five; Observer.Observe('enum_format_9', Format(V, 0, 9));
        Observer.Expect('duration', '1 minute 30 seconds');
        Observer.Expect('bigint', '12345678901');
        Observer.Expect('char', 'A');
        Observer.Expect('byte', 'B');
        Observer.Expect('enum', 'Five');
        Observer.Expect('enum_format_9', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_Into_Variant_Is_Rejected_Or_Typed()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT VaT Helper";
        I: Integer;
        D: Date;
        Dec: Decimal;
        Bo: Boolean;
        T: Time;
        V: Variant;
    begin
        V := '12';
        Observer.Observe('eval_int_from_variant_text', Format(Evaluate(I, V)));
        Observer.Observe('eval_int_value', Format(I));
        V := 'abc';
        Observer.Observe('eval_int_bad_from_variant', Format(Evaluate(I, V)));
        V := '2020-01-02';
        Observer.Observe('eval_date_from_variant', Format(Evaluate(D, V)));
        V := '1.5';
        Observer.Observe('eval_dec_from_variant', Format(Evaluate(Dec, V)));
        Observer.Observe('eval_dec_value', Format(Dec));
        V := 'true';
        Observer.Observe('eval_bool_from_variant', Format(Evaluate(Bo, V)));
        V := '12:34:56';
        Observer.Observe('eval_time_from_variant', Format(Evaluate(T, V)));
        V := 5;
        asserterror Observer.Observe('eval_int_from_variant_int', Format(Evaluate(I, V)));
        Observer.ObserveError('af92');
        Observer.Observe('eval_int_from_variant_int_value', Format(I));
        Observer.Expect('eval_int_from_variant_text', 'Yes');
        Observer.Expect('eval_int_value', '12');
        Observer.Expect('eval_int_bad_from_variant', 'No');
        Observer.Expect('eval_date_from_variant', 'Yes');
        Observer.Expect('eval_dec_from_variant', 'Yes');
        Observer.Expect('eval_dec_value', '1.5');
        Observer.Expect('eval_bool_from_variant', 'Yes');
        Observer.Expect('eval_time_from_variant', 'Yes');
        Observer.Expect('af92|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('af92|code', 'TypeConversion');
        Observer.Expect('eval_int_from_variant_int_value', '12');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_Error_Texts_Through_Typed_Targets()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        D: Date;
        Dec: Decimal;
        Bo: Boolean;
        T: Text;
    begin
        T := 'abc';
        asserterror Evaluate(I, T, 0);
        Observer.ObserveError('eval_int_abc_throwing');
        Observer.Expect('eval_int_abc_throwing|text', 'The value "abc" can''t be evaluated into type Integer.');
        Observer.Expect('eval_int_abc_throwing|code', 'Evaluate');
        Observer.Verify();
    end;
}
