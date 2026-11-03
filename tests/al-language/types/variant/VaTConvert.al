// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT VaT Helper (71026), table LT VaT Rec (71027)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71033 "LT VaT Convert Errors"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure TextVariant_To_Integer()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        V: Variant;
    begin
        V := 'abc';
        asserterror I := V;
        Observer.ObserveError('text_abc');
        V := '12';
        I := V;
        Observer.Observe('text_12', 'no error');
        V := '';
        asserterror I := V;
        Observer.ObserveError('text_empty');
        V := ' 5 ';
        I := V;
        Observer.Observe('text_spaces', 'no error');
        Observer.Expect('text_abc|text', 'The expression Variant cannot be type-converted to a Integer value.');
        Observer.Expect('text_abc|code', 'TypeConversion:Format');
        Observer.Expect('text_12', 'no error');
        Observer.Expect('text_empty|text', 'The expression Variant cannot be type-converted to a Integer value.');
        Observer.Expect('text_empty|code', 'TypeConversion:Format');
        Observer.Expect('text_spaces', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure TextVariant_To_Date_Time_Decimal_Boolean()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
        Tm: Time;
        Dec: Decimal;
        Bo: Boolean;
        G: Guid;
        V: Variant;
    begin
        V := '2020-01-02';
        asserterror D := V;
        Observer.ObserveError('text_to_date');
        V := '120000';
        asserterror Tm := V;
        Observer.ObserveError('text_to_time');
        V := '1.5';
        Dec := V;
        Observer.Observe('text_to_decimal', 'no error');
        V := 'true';
        asserterror Bo := V;
        Observer.ObserveError('text_to_boolean');
        V := '{00000000-0000-0000-0000-000000000001}';
        G := V;
        Observer.Observe('text_to_guid', 'no error');
        Observer.Expect('text_to_date|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavDate value.');
        Observer.Expect('text_to_date|code', 'TypeConversion');
        Observer.Expect('text_to_time|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavTime value.');
        Observer.Expect('text_to_time|code', 'TypeConversion');
        Observer.Expect('text_to_decimal', 'no error');
        Observer.Expect('text_to_boolean|text', 'The expression Variant cannot be type-converted to a Boolean value.');
        Observer.Expect('text_to_boolean|code', 'TypeConversion:Format');
        Observer.Expect('text_to_guid', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure TextVariant_To_Record_RecordRef_Codeunit_List()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT VaT Rec";
        RecRef: RecordRef;
        L: List of [Text];
        V: Variant;
    begin
        V := 'abc';
        asserterror Rec := V;
        Observer.ObserveError('text_to_record');
        asserterror RecRef := V;
        Observer.ObserveError('text_to_recordref');
        asserterror L := V;
        Observer.ObserveError('text_to_list');
        Observer.Expect('text_to_record|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to Microsoft.Dynamics.Nav.Runtime.INavRecordHandle.');
        Observer.Expect('text_to_record|code', 'Conversion');
        Observer.Expect('text_to_recordref|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavRecordRef value.');
        Observer.Expect('text_to_recordref|code', 'TypeConversion');
        Observer.Expect('text_to_list|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to Microsoft.Dynamics.Nav.Runtime.NavList`1[Microsoft.Dynamics.Nav.Runtime.NavText].');
        Observer.Expect('text_to_list|code', 'Conversion');
        Observer.Verify();
    end;

    [Test]
    procedure IntegerVariant_To_Other_Types()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
        T: Text;
        Dec: Decimal;
        Bo: Boolean;
        BI: BigInteger;
        Rec: Record "LT VaT Rec";
        V: Variant;
    begin
        V := 5;
        Dec := V; Observer.Observe('int_to_decimal', Format(Dec));
        BI := V; Observer.Observe('int_to_bigint', Format(BI));
        asserterror T := V; Observer.Observe('int_to_text', T);
        Observer.ObserveError('af97');
        asserterror D := V;
        Observer.ObserveError('int_to_date');
        Bo := V;
        Observer.Observe('int_to_boolean', 'no error');
        asserterror Rec := V;
        Observer.ObserveError('int_to_record');
        Observer.Expect('int_to_decimal', '5');
        Observer.Expect('int_to_bigint', '5');
        Observer.Expect('int_to_text', '');
        Observer.Expect('af97|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('af97|code', 'TypeConversion');
        Observer.Expect('int_to_date|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavDate value.');
        Observer.Expect('int_to_date|code', 'TypeConversion');
        Observer.Expect('int_to_boolean', 'no error');
        Observer.Expect('int_to_record|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to Microsoft.Dynamics.Nav.Runtime.INavRecordHandle.');
        Observer.Expect('int_to_record|code', 'Conversion');
        Observer.Verify();
    end;

    [Test]
    procedure DecimalVariant_To_Integer()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        BI: BigInteger;
        V: Variant;
    begin
        V := 2.0;
        I := V; Observer.Observe('dec_2_0', Format(I));
        V := 1.5;
        asserterror I := V;
        Observer.ObserveError('dec_1_5');
        asserterror BI := V;
        Observer.ObserveError('dec_1_5_bigint');
        V := 3000000000.0;
        asserterror I := V;
        Observer.ObserveError('dec_3e9');
        Observer.Expect('dec_2_0', '2');
        Observer.Expect('dec_1_5|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.5 to System.Int32.');
        Observer.Expect('dec_1_5|code', 'ConversionCast');
        Observer.Expect('dec_1_5_bigint|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.5 to System.Int64.');
        Observer.Expect('dec_1_5_bigint|code', 'ConversionCast');
        Observer.Expect('dec_3e9|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 3000000000.0 to System.Int32.');
        Observer.Expect('dec_3e9|code', 'ConversionCast');
        Observer.Verify();
    end;

    [Test]
    procedure BigIntegerVariant_To_Integer()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        Dec: Decimal;
        B: BigInteger;
        V: Variant;
    begin
        B := 5; V := B;
        I := V; Observer.Observe('bigint_5_to_int', Format(I));
        Dec := V; Observer.Observe('bigint_5_to_dec', Format(Dec));
        Evaluate(B, '3000000000'); V := B;
        asserterror I := V;
        Observer.ObserveError('bigint_3e9_to_int');
        Observer.Expect('bigint_5_to_int', '5');
        Observer.Expect('bigint_5_to_dec', '5');
        Observer.Expect('bigint_3e9_to_int|text', 'The expression Variant cannot be type-converted to a Integer value.');
        Observer.Expect('bigint_3e9_to_int|code', 'TypeConversion:Overflow');
        Observer.Verify();
    end;

    [Test]
    procedure DateVariant_To_Other_Types()
    var
        Observer: Codeunit "Probe Observer";
        DtTm: DateTime;
        T: Text;
        I: Integer;
        Tm: Time;
        V: Variant;
    begin
        V := DMY2Date(1, 2, 2020);
        DtTm := V; Observer.Observe('date_to_datetime_defined', Format(DtTm <> 0DT));
        asserterror T := V; Observer.Observe('date_to_text', T);
        Observer.ObserveError('af159');
        I := V;
        Observer.Observe('date_to_integer', 'no error');
        asserterror Tm := V;
        Observer.ObserveError('date_to_time');
        Observer.Expect('date_to_datetime_defined', 'Yes');
        Observer.Expect('date_to_text', '');
        Observer.Expect('af159|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('af159|code', 'TypeConversion');
        Observer.Expect('date_to_integer', 'no error');
        Observer.Expect('date_to_time|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavTime value.');
        Observer.Expect('date_to_time|code', 'TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure BooleanVariant_To_Other_Types()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        I: Integer;
        Dec: Decimal;
        V: Variant;
    begin
        V := true;
        asserterror T := V; Observer.Observe('bool_to_text', T);
        Observer.ObserveError('af178');
        I := V;
        Observer.Observe('bool_to_integer', 'no error');
        Dec := V;
        Observer.Observe('bool_to_decimal', 'no error');
        Observer.Expect('bool_to_text', '');
        Observer.Expect('af178|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('af178|code', 'TypeConversion');
        Observer.Expect('bool_to_integer', 'no error');
        Observer.Expect('bool_to_decimal', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure RecordVariant_To_Other_Types()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT VaT Rec";
        Rec2: Record "LT VaT Rec";
        RecRef: RecordRef;
        I: Integer;
        T: Text;
        V: Variant;
    begin
        Rec.DeleteAll();
        Rec.Id := 4; Rec.Name := 'four'; Rec.Insert();
        V := Rec;
        Rec2 := V; Observer.Observe('record_roundtrip', Format(Rec2.Id) + '|' + Rec2.Name);
        asserterror RecRef := V; Observer.Observe('record_to_recordref', Format(RecRef.Number));
        Observer.ObserveError('af202');
        asserterror I := V;
        Observer.ObserveError('record_to_integer');
        asserterror T := V;
        Observer.ObserveError('record_to_text');
        Observer.Expect('record_roundtrip', '4|four');
        Observer.Expect('record_to_recordref', '0');
        Observer.Expect('af202|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavRecordRef value.');
        Observer.Expect('af202|code', 'TypeConversion');
        Observer.Expect('record_to_integer|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavRecordHandle to System.Int32.');
        Observer.Expect('record_to_integer|code', 'Conversion');
        Observer.Expect('record_to_text|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('record_to_text|code', 'TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyVariant_To_Types()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        T: Text;
        D: Date;
        Dec: Decimal;
        Bo: Boolean;
        Rec: Record "LT VaT Rec";
        V: Variant;
    begin
        asserterror I := V;
        Observer.ObserveError('empty_to_integer');
        T := V;
        Observer.Observe('empty_to_text', 'no error');
        D := V;
        Observer.Observe('empty_to_date', 'no error');
        asserterror Dec := V;
        Observer.ObserveError('empty_to_decimal');
        asserterror Bo := V;
        Observer.ObserveError('empty_to_boolean');
        asserterror Rec := V;
        Observer.ObserveError('empty_to_record');
        Observer.Expect('empty_to_integer|text', 'Microsoft.Dynamics.Nav.Runtime.NavVariant variable not initialized.');
        Observer.Expect('empty_to_integer|code', 'NotInitialized');
        Observer.Expect('empty_to_text', 'no error');
        Observer.Expect('empty_to_date', 'no error');
        Observer.Expect('empty_to_decimal|text', 'Microsoft.Dynamics.Nav.Runtime.NavVariant variable not initialized.');
        Observer.Expect('empty_to_decimal|code', 'NotInitialized');
        Observer.Expect('empty_to_boolean|text', 'Microsoft.Dynamics.Nav.Runtime.NavVariant variable not initialized.');
        Observer.Expect('empty_to_boolean|code', 'NotInitialized');
        Observer.Expect('empty_to_record|text', 'Microsoft.Dynamics.Nav.Runtime.NavVariant variable not initialized.');
        Observer.Expect('empty_to_record|code', 'NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Param_Variant_Into_Integer_Text()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT VaT Helper";
    begin
        Observer.Observe('int_ok', Format(Helper.ToInt(5)));
        asserterror Helper.ToInt('abc');
        Observer.ObserveError('text_abc_as_int');
        asserterror Observer.Observe('text_ok', Helper.ToText(5));
        Observer.ObserveError('af247');
        asserterror Observer.Observe('text_date', Helper.ToText(DMY2Date(1, 2, 2020)));
        Observer.ObserveError('af249');
        asserterror Observer.Observe('text_decimal', Helper.ToText(1.50));
        Observer.ObserveError('af251');
        asserterror Observer.Observe('text_bool', Helper.ToText(true));
        Observer.ObserveError('af253');
        Observer.Expect('int_ok', '5');
        Observer.Expect('text_abc_as_int|text', 'The expression Variant cannot be type-converted to a Integer value.');
        Observer.Expect('text_abc_as_int|code', 'TypeConversion:Format');
        Observer.Expect('af247|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('af247|code', 'TypeConversion');
        Observer.Expect('af249|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('af249|code', 'TypeConversion');
        Observer.Expect('af251|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('af251|code', 'TypeConversion');
        Observer.Expect('af253|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('af253|code', 'TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure Enum_Variant_To_Integer_Text()
    var
        Observer: Codeunit "Probe Observer";
        E: Enum "LT VaT Enum";
        E2: Enum "LT VaT Enum";
        I: Integer;
        T: Text;
        V: Variant;
    begin
        V := E::Five;
        Observer.Observe('enum_format', Format(V));
        I := V;
        Observer.Observe('enum_to_integer', 'no error');
        asserterror T := V;
        Observer.ObserveError('enum_to_text');
        Observer.Expect('enum_format', 'Five');
        Observer.Expect('enum_to_integer', 'no error');
        Observer.Expect('enum_to_text|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('enum_to_text|code', 'TypeConversion');
        Observer.Verify();
    end;
}
