// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-value-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), FVC Source (75980)
// Probe: written against a local BC 27.5 / 28.5 / 29.0 observe host; every literal asserted below is what BC produced.
// Facts: FieldRef.Value assigned to a variable of another type (runner issue 8662: an Integer field value assigned to a DateTime).
//   Each cell is run twice: directly (R := FR.Value) and through a Variant (V := FR.Value; R := V).
//   Source fields of the type named in the codeunit; targets DateTime, Date, Time, Duration, Decimal, Boolean, Code, Text, Integer, BigInteger.
//   A cell that BC refuses records the error text and code.
//   Version difference: a direct assignment of a number, Duration or Boolean field to a DateTime, Date or Time is refused on BC 27 with
//   'Unable to convert from ... to System.DateTime.' (code Conversion) and on BC 28 and later with an Evaluate:Conversion error; through a Variant all versions agree.
// BC versions: see the asserted values; a version guard is used only where the versions differ.

codeunit 75981 "FVC Integer Field"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure IntField_To_DateTime()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: DateTime;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(IntF));
        FR.Value := 0;
        if ToDateTime(FR, R) then Observer.Observe('0', Format(R, 0, 9)) else Observer.ObserveError('0');
        if ToViaDateTime(FR, R) then Observer.Observe('0 via variant', Format(R, 0, 9)) else Observer.ObserveError('0 via variant');
        FR.Value := 1;
        if ToDateTime(FR, R) then Observer.Observe('1', Format(R, 0, 9)) else Observer.ObserveError('1');
        if ToViaDateTime(FR, R) then Observer.Observe('1 via variant', Format(R, 0, 9)) else Observer.ObserveError('1 via variant');
        FR.Value := 2147483647;
        if ToDateTime(FR, R) then Observer.Observe('max', Format(R, 0, 9)) else Observer.ObserveError('max');
        if ToViaDateTime(FR, R) then Observer.Observe('max via variant', Format(R, 0, 9)) else Observer.ObserveError('max via variant');
        FR.Value := -2147483647;
        if ToDateTime(FR, R) then Observer.Observe('min', Format(R, 0, 9)) else Observer.ObserveError('min');
        if ToViaDateTime(FR, R) then Observer.Observe('min via variant', Format(R, 0, 9)) else Observer.ObserveError('min via variant');
        FR.Value := -1;
        if ToDateTime(FR, R) then Observer.Observe('neg1', Format(R, 0, 9)) else Observer.ObserveError('neg1');
        if ToViaDateTime(FR, R) then Observer.Observe('neg1 via variant', Format(R, 0, 9)) else Observer.ObserveError('neg1 via variant');
        FR.Value := 1000;
        if ToDateTime(FR, R) then Observer.Observe('1000', Format(R, 0, 9)) else Observer.ObserveError('1000');
        if ToViaDateTime(FR, R) then Observer.Observe('1000 via variant', Format(R, 0, 9)) else Observer.ObserveError('1000 via variant');
#if BC28PLUS
        Observer.Expect('0|text', 'The value "0" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('0|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to System.DateTime.');
#endif
#if BC28PLUS
        Observer.Expect('0|code', 'Evaluate:Conversion');
#else
        Observer.Expect('0|code', 'Conversion');
#endif
        Observer.Expect('0 via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavDateTime value.');
        Observer.Expect('0 via variant|code', 'TypeConversion');
#if BC28PLUS
        Observer.Expect('1|text', 'The value "1" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('1|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to System.DateTime.');
#endif
#if BC28PLUS
        Observer.Expect('1|code', 'Evaluate:Conversion');
#else
        Observer.Expect('1|code', 'Conversion');
#endif
        Observer.Expect('1 via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavDateTime value.');
        Observer.Expect('1 via variant|code', 'TypeConversion');
#if BC28PLUS
        Observer.Expect('max|text', 'The value "2147483647" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('max|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to System.DateTime.');
#endif
#if BC28PLUS
        Observer.Expect('max|code', 'Evaluate:Conversion');
#else
        Observer.Expect('max|code', 'Conversion');
#endif
        Observer.Expect('max via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavDateTime value.');
        Observer.Expect('max via variant|code', 'TypeConversion');
#if BC28PLUS
        Observer.Expect('min|text', 'The value "-2147483647" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('min|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to System.DateTime.');
#endif
#if BC28PLUS
        Observer.Expect('min|code', 'Evaluate:Conversion');
#else
        Observer.Expect('min|code', 'Conversion');
#endif
        Observer.Expect('min via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavDateTime value.');
        Observer.Expect('min via variant|code', 'TypeConversion');
#if BC28PLUS
        Observer.Expect('neg1|text', 'The value "-1" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('neg1|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to System.DateTime.');
#endif
#if BC28PLUS
        Observer.Expect('neg1|code', 'Evaluate:Conversion');
#else
        Observer.Expect('neg1|code', 'Conversion');
#endif
        Observer.Expect('neg1 via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavDateTime value.');
        Observer.Expect('neg1 via variant|code', 'TypeConversion');
#if BC28PLUS
        Observer.Expect('1000|text', 'The value "1000" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('1000|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to System.DateTime.');
#endif
#if BC28PLUS
        Observer.Expect('1000|code', 'Evaluate:Conversion');
#else
        Observer.Expect('1000|code', 'Conversion');
#endif
        Observer.Expect('1000 via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavDateTime value.');
        Observer.Expect('1000 via variant|code', 'TypeConversion');
        Observer.Verify();
    end;




    [Test]
    procedure IntField_To_Date()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Date;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(IntF));
        FR.Value := 0;
        if ToDate(FR, R) then Observer.Observe('0', Format(R, 0, 9)) else Observer.ObserveError('0');
        if ToViaDate(FR, R) then Observer.Observe('0 via variant', Format(R, 0, 9)) else Observer.ObserveError('0 via variant');
        FR.Value := 1;
        if ToDate(FR, R) then Observer.Observe('1', Format(R, 0, 9)) else Observer.ObserveError('1');
        if ToViaDate(FR, R) then Observer.Observe('1 via variant', Format(R, 0, 9)) else Observer.ObserveError('1 via variant');
        FR.Value := 2147483647;
        if ToDate(FR, R) then Observer.Observe('max', Format(R, 0, 9)) else Observer.ObserveError('max');
        if ToViaDate(FR, R) then Observer.Observe('max via variant', Format(R, 0, 9)) else Observer.ObserveError('max via variant');
        FR.Value := -2147483647;
        if ToDate(FR, R) then Observer.Observe('min', Format(R, 0, 9)) else Observer.ObserveError('min');
        if ToViaDate(FR, R) then Observer.Observe('min via variant', Format(R, 0, 9)) else Observer.ObserveError('min via variant');
        FR.Value := -1;
        if ToDate(FR, R) then Observer.Observe('neg1', Format(R, 0, 9)) else Observer.ObserveError('neg1');
        if ToViaDate(FR, R) then Observer.Observe('neg1 via variant', Format(R, 0, 9)) else Observer.ObserveError('neg1 via variant');
        FR.Value := 1000;
        if ToDate(FR, R) then Observer.Observe('1000', Format(R, 0, 9)) else Observer.ObserveError('1000');
        if ToViaDate(FR, R) then Observer.Observe('1000 via variant', Format(R, 0, 9)) else Observer.ObserveError('1000 via variant');
#if BC28PLUS
        Observer.Expect('0|text', 'The format of the Date ''0'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('0|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to System.DateTime.');
#endif
#if BC28PLUS
        Observer.Expect('0|code', 'Evaluate:Conversion');
#else
        Observer.Expect('0|code', 'Conversion');
#endif
        Observer.Expect('0 via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavDate value.');
        Observer.Expect('0 via variant|code', 'TypeConversion');
#if BC28PLUS
        Observer.Expect('1|text', 'The format of the Date ''1'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('1|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to System.DateTime.');
#endif
#if BC28PLUS
        Observer.Expect('1|code', 'Evaluate:Conversion');
#else
        Observer.Expect('1|code', 'Conversion');
#endif
        Observer.Expect('1 via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavDate value.');
        Observer.Expect('1 via variant|code', 'TypeConversion');
#if BC28PLUS
        Observer.Expect('max|text', 'The format of the Date ''2147483647'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('max|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to System.DateTime.');
#endif
#if BC28PLUS
        Observer.Expect('max|code', 'Evaluate:Conversion');
#else
        Observer.Expect('max|code', 'Conversion');
#endif
        Observer.Expect('max via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavDate value.');
        Observer.Expect('max via variant|code', 'TypeConversion');
#if BC28PLUS
        Observer.Expect('min|text', 'The format of the Date ''-2147483647'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
#else
        Observer.Expect('min|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to System.DateTime.');
#endif
#if BC28PLUS
        Observer.Expect('min|code', 'Evaluate:Conversion');
#else
        Observer.Expect('min|code', 'Conversion');
#endif
        Observer.Expect('min via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectVal');
        Observer.Verify();
    end;




    [Test]
    procedure IntField_To_Time()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Time;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(IntF));
        FR.Value := 0;
        if ToTime(FR, R) then Observer.Observe('0', Format(R, 0, 9)) else Observer.ObserveError('0');
        if ToViaTime(FR, R) then Observer.Observe('0 via variant', Format(R, 0, 9)) else Observer.ObserveError('0 via variant');
        FR.Value := 1;
        if ToTime(FR, R) then Observer.Observe('1', Format(R, 0, 9)) else Observer.ObserveError('1');
        if ToViaTime(FR, R) then Observer.Observe('1 via variant', Format(R, 0, 9)) else Observer.ObserveError('1 via variant');
        FR.Value := 2147483647;
        if ToTime(FR, R) then Observer.Observe('max', Format(R, 0, 9)) else Observer.ObserveError('max');
        if ToViaTime(FR, R) then Observer.Observe('max via variant', Format(R, 0, 9)) else Observer.ObserveError('max via variant');
        FR.Value := -2147483647;
        if ToTime(FR, R) then Observer.Observe('min', Format(R, 0, 9)) else Observer.ObserveError('min');
        if ToViaTime(FR, R) then Observer.Observe('min via variant', Format(R, 0, 9)) else Observer.ObserveError('min via variant');
        FR.Value := -1;
        if ToTime(FR, R) then Observer.Observe('neg1', Format(R, 0, 9)) else Observer.ObserveError('neg1');
        if ToViaTime(FR, R) then Observer.Observe('neg1 via variant', Format(R, 0, 9)) else Observer.ObserveError('neg1 via variant');
        FR.Value := 1000;
        if ToTime(FR, R) then Observer.Observe('1000', Format(R, 0, 9)) else Observer.ObserveError('1000');
        if ToViaTime(FR, R) then Observer.Observe('1000 via variant', Format(R, 0, 9)) else Observer.ObserveError('1000 via variant');
#if BC28PLUS
        Observer.Expect('0|text', 'The value "0" can''t be evaluated into type Time.');
#else
        Observer.Expect('0|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to System.DateTime.');
#endif
#if BC28PLUS
        Observer.Expect('0|code', 'Evaluate:Conversion');
#else
        Observer.Expect('0|code', 'Conversion');
#endif
        Observer.Expect('0 via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavTime value.');
        Observer.Expect('0 via variant|code', 'TypeConversion');
#if BC28PLUS
        Observer.Expect('1|text', 'The value "1" can''t be evaluated into type Time.');
#else
        Observer.Expect('1|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to System.DateTime.');
#endif
#if BC28PLUS
        Observer.Expect('1|code', 'Evaluate:Conversion');
#else
        Observer.Expect('1|code', 'Conversion');
#endif
        Observer.Expect('1 via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavTime value.');
        Observer.Expect('1 via variant|code', 'TypeConversion');
#if BC28PLUS
        Observer.Expect('max|text', 'The value "2147483647" can''t be evaluated into type Time.');
#else
        Observer.Expect('max|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to System.DateTime.');
#endif
#if BC28PLUS
        Observer.Expect('max|code', 'Evaluate:Conversion');
#else
        Observer.Expect('max|code', 'Conversion');
#endif
        Observer.Expect('max via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavTime value.');
        Observer.Expect('max via variant|code', 'TypeConversion');
#if BC28PLUS
        Observer.Expect('min|text', 'The value "-2147483647" can''t be evaluated into type Time.');
#else
        Observer.Expect('min|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to System.DateTime.');
#endif
#if BC28PLUS
        Observer.Expect('min|code', 'Evaluate:Conversion');
#else
        Observer.Expect('min|code', 'Conversion');
#endif
        Observer.Expect('min via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavTime value.');
        Observer.Expect('min via variant|code', 'TypeConversion');
#if BC28PLUS
        Observer.Expect('neg1|text', 'The value "-1" can''t be evaluated into type Time.');
#else
        Observer.Expect('neg1|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to System.DateTime.');
#endif
#if BC28PLUS
        Observer.Expect('neg1|code', 'Evaluate:Conversion');
#else
        Observer.Expect('neg1|code', 'Conversion');
#endif
        Observer.Expect('neg1 via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavTime value.');
        Observer.Expect('neg1 via variant|code', 'TypeConversion');
#if BC28PLUS
        Observer.Expect('1000|text', 'The value "1000" can''t be evaluated into type Time.');
#else
        Observer.Expect('1000|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to System.DateTime.');
#endif
#if BC28PLUS
        Observer.Expect('1000|code', 'Evaluate:Conversion');
#else
        Observer.Expect('1000|code', 'Conversion');
#endif
        Observer.Expect('1000 via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavTime value.');
        Observer.Expect('1000 via variant|code', 'TypeConversion');
        Observer.Verify();
    end;




    [Test]
    procedure IntField_To_Duration()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Duration;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(IntF));
        FR.Value := 0;
        if ToDuration(FR, R) then Observer.Observe('0', Format(R, 0, 9)) else Observer.ObserveError('0');
        if ToViaDuration(FR, R) then Observer.Observe('0 via variant', Format(R, 0, 9)) else Observer.ObserveError('0 via variant');
        FR.Value := 1;
        if ToDuration(FR, R) then Observer.Observe('1', Format(R, 0, 9)) else Observer.ObserveError('1');
        if ToViaDuration(FR, R) then Observer.Observe('1 via variant', Format(R, 0, 9)) else Observer.ObserveError('1 via variant');
        FR.Value := 2147483647;
        if ToDuration(FR, R) then Observer.Observe('max', Format(R, 0, 9)) else Observer.ObserveError('max');
        if ToViaDuration(FR, R) then Observer.Observe('max via variant', Format(R, 0, 9)) else Observer.ObserveError('max via variant');
        FR.Value := -2147483647;
        if ToDuration(FR, R) then Observer.Observe('min', Format(R, 0, 9)) else Observer.ObserveError('min');
        if ToViaDuration(FR, R) then Observer.Observe('min via variant', Format(R, 0, 9)) else Observer.ObserveError('min via variant');
        FR.Value := -1;
        if ToDuration(FR, R) then Observer.Observe('neg1', Format(R, 0, 9)) else Observer.ObserveError('neg1');
        if ToViaDuration(FR, R) then Observer.Observe('neg1 via variant', Format(R, 0, 9)) else Observer.ObserveError('neg1 via variant');
        FR.Value := 1000;
        if ToDuration(FR, R) then Observer.Observe('1000', Format(R, 0, 9)) else Observer.ObserveError('1000');
        if ToViaDuration(FR, R) then Observer.Observe('1000 via variant', Format(R, 0, 9)) else Observer.ObserveError('1000 via variant');
        Observer.Expect('0', 'P0DT0H0M0.0S');
        Observer.Expect('0 via variant', 'P0DT0H0M0.0S');
        Observer.Expect('1', 'P0DT0H0M0.001S');
        Observer.Expect('1 via variant', 'P0DT0H0M0.001S');
        Observer.Expect('max', 'P24DT20H31M23.647S');
        Observer.Expect('max via variant', 'P24DT20H31M23.647S');
        Observer.Expect('min', '-P24DT20H31M23.647S');
        Observer.Expect('min via variant', '-P24DT20H31M23.647S');
        Observer.Expect('neg1', '-P0DT0H0M0.001S');
        Observer.Expect('neg1 via variant', '-P0DT0H0M0.001S');
        Observer.Expect('1000', 'P0DT0H0M1.0S');
        Observer.Expect('1000 via variant', 'P0DT0H0M1.0S');
        Observer.Verify();
    end;

    [Test]
    procedure IntField_To_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Decimal;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(IntF));
        FR.Value := 0;
        if ToDecimal(FR, R) then Observer.Observe('0', Format(R, 0, 9)) else Observer.ObserveError('0');
        if ToViaDecimal(FR, R) then Observer.Observe('0 via variant', Format(R, 0, 9)) else Observer.ObserveError('0 via variant');
        FR.Value := 1;
        if ToDecimal(FR, R) then Observer.Observe('1', Format(R, 0, 9)) else Observer.ObserveError('1');
        if ToViaDecimal(FR, R) then Observer.Observe('1 via variant', Format(R, 0, 9)) else Observer.ObserveError('1 via variant');
        FR.Value := 2147483647;
        if ToDecimal(FR, R) then Observer.Observe('max', Format(R, 0, 9)) else Observer.ObserveError('max');
        if ToViaDecimal(FR, R) then Observer.Observe('max via variant', Format(R, 0, 9)) else Observer.ObserveError('max via variant');
        FR.Value := -2147483647;
        if ToDecimal(FR, R) then Observer.Observe('min', Format(R, 0, 9)) else Observer.ObserveError('min');
        if ToViaDecimal(FR, R) then Observer.Observe('min via variant', Format(R, 0, 9)) else Observer.ObserveError('min via variant');
        FR.Value := -1;
        if ToDecimal(FR, R) then Observer.Observe('neg1', Format(R, 0, 9)) else Observer.ObserveError('neg1');
        if ToViaDecimal(FR, R) then Observer.Observe('neg1 via variant', Format(R, 0, 9)) else Observer.ObserveError('neg1 via variant');
        FR.Value := 1000;
        if ToDecimal(FR, R) then Observer.Observe('1000', Format(R, 0, 9)) else Observer.ObserveError('1000');
        if ToViaDecimal(FR, R) then Observer.Observe('1000 via variant', Format(R, 0, 9)) else Observer.ObserveError('1000 via variant');
        Observer.Expect('0', '0');
        Observer.Expect('0 via variant', '0');
        Observer.Expect('1', '1');
        Observer.Expect('1 via variant', '1');
        Observer.Expect('max', '2147483647');
        Observer.Expect('max via variant', '2147483647');
        Observer.Expect('min', '-2147483647');
        Observer.Expect('min via variant', '-2147483647');
        Observer.Expect('neg1', '-1');
        Observer.Expect('neg1 via variant', '-1');
        Observer.Expect('1000', '1000');
        Observer.Expect('1000 via variant', '1000');
        Observer.Verify();
    end;

    [Test]
    procedure IntField_To_Boolean()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Boolean;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(IntF));
        FR.Value := 0;
        if ToBoolean(FR, R) then Observer.Observe('0', Format(R, 0, 9)) else Observer.ObserveError('0');
        if ToViaBoolean(FR, R) then Observer.Observe('0 via variant', Format(R, 0, 9)) else Observer.ObserveError('0 via variant');
        FR.Value := 1;
        if ToBoolean(FR, R) then Observer.Observe('1', Format(R, 0, 9)) else Observer.ObserveError('1');
        if ToViaBoolean(FR, R) then Observer.Observe('1 via variant', Format(R, 0, 9)) else Observer.ObserveError('1 via variant');
        FR.Value := 2147483647;
        if ToBoolean(FR, R) then Observer.Observe('max', Format(R, 0, 9)) else Observer.ObserveError('max');
        if ToViaBoolean(FR, R) then Observer.Observe('max via variant', Format(R, 0, 9)) else Observer.ObserveError('max via variant');
        FR.Value := -2147483647;
        if ToBoolean(FR, R) then Observer.Observe('min', Format(R, 0, 9)) else Observer.ObserveError('min');
        if ToViaBoolean(FR, R) then Observer.Observe('min via variant', Format(R, 0, 9)) else Observer.ObserveError('min via variant');
        FR.Value := -1;
        if ToBoolean(FR, R) then Observer.Observe('neg1', Format(R, 0, 9)) else Observer.ObserveError('neg1');
        if ToViaBoolean(FR, R) then Observer.Observe('neg1 via variant', Format(R, 0, 9)) else Observer.ObserveError('neg1 via variant');
        FR.Value := 1000;
        if ToBoolean(FR, R) then Observer.Observe('1000', Format(R, 0, 9)) else Observer.ObserveError('1000');
        if ToViaBoolean(FR, R) then Observer.Observe('1000 via variant', Format(R, 0, 9)) else Observer.ObserveError('1000 via variant');
        Observer.Expect('0', 'false');
        Observer.Expect('0 via variant', 'false');
        Observer.Expect('1', 'true');
        Observer.Expect('1 via variant', 'true');
        Observer.Expect('max', 'true');
        Observer.Expect('max via variant', 'true');
        Observer.Expect('min', 'true');
        Observer.Expect('min via variant', 'true');
        Observer.Expect('neg1', 'true');
        Observer.Expect('neg1 via variant', 'true');
        Observer.Expect('1000', 'true');
        Observer.Expect('1000 via variant', 'true');
        Observer.Verify();
    end;

    [Test]
    procedure IntField_To_Code20()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Code[20];
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(IntF));
        FR.Value := 0;
        if ToCode20(FR, R) then Observer.Observe('0', Format(R, 0, 9)) else Observer.ObserveError('0');
        if ToViaCode20(FR, R) then Observer.Observe('0 via variant', Format(R, 0, 9)) else Observer.ObserveError('0 via variant');
        FR.Value := 1;
        if ToCode20(FR, R) then Observer.Observe('1', Format(R, 0, 9)) else Observer.ObserveError('1');
        if ToViaCode20(FR, R) then Observer.Observe('1 via variant', Format(R, 0, 9)) else Observer.ObserveError('1 via variant');
        FR.Value := 2147483647;
        if ToCode20(FR, R) then Observer.Observe('max', Format(R, 0, 9)) else Observer.ObserveError('max');
        if ToViaCode20(FR, R) then Observer.Observe('max via variant', Format(R, 0, 9)) else Observer.ObserveError('max via variant');
        FR.Value := -2147483647;
        if ToCode20(FR, R) then Observer.Observe('min', Format(R, 0, 9)) else Observer.ObserveError('min');
        if ToViaCode20(FR, R) then Observer.Observe('min via variant', Format(R, 0, 9)) else Observer.ObserveError('min via variant');
        FR.Value := -1;
        if ToCode20(FR, R) then Observer.Observe('neg1', Format(R, 0, 9)) else Observer.ObserveError('neg1');
        if ToViaCode20(FR, R) then Observer.Observe('neg1 via variant', Format(R, 0, 9)) else Observer.ObserveError('neg1 via variant');
        FR.Value := 1000;
        if ToCode20(FR, R) then Observer.Observe('1000', Format(R, 0, 9)) else Observer.ObserveError('1000');
        if ToViaCode20(FR, R) then Observer.Observe('1000 via variant', Format(R, 0, 9)) else Observer.ObserveError('1000 via variant');
        Observer.Expect('0', '0');
        Observer.Expect('0 via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Expect('0 via variant|code', 'TypeConversion');
        Observer.Expect('1', '1');
        Observer.Expect('1 via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Expect('1 via variant|code', 'TypeConversion');
        Observer.Expect('max', '2147483647');
        Observer.Expect('max via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Expect('max via variant|code', 'TypeConversion');
        Observer.Expect('min', '-2147483647');
        Observer.Expect('min via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Expect('min via variant|code', 'TypeConversion');
        Observer.Expect('neg1', '-1');
        Observer.Expect('neg1 via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Expect('neg1 via variant|code', 'TypeConversion');
        Observer.Expect('1000', '1000');
        Observer.Expect('1000 via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Expect('1000 via variant|code', 'TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure IntField_To_Text50()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Text[50];
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(IntF));
        FR.Value := 0;
        if ToText50(FR, R) then Observer.Observe('0', Format(R, 0, 9)) else Observer.ObserveError('0');
        if ToViaText50(FR, R) then Observer.Observe('0 via variant', Format(R, 0, 9)) else Observer.ObserveError('0 via variant');
        FR.Value := 1;
        if ToText50(FR, R) then Observer.Observe('1', Format(R, 0, 9)) else Observer.ObserveError('1');
        if ToViaText50(FR, R) then Observer.Observe('1 via variant', Format(R, 0, 9)) else Observer.ObserveError('1 via variant');
        FR.Value := 2147483647;
        if ToText50(FR, R) then Observer.Observe('max', Format(R, 0, 9)) else Observer.ObserveError('max');
        if ToViaText50(FR, R) then Observer.Observe('max via variant', Format(R, 0, 9)) else Observer.ObserveError('max via variant');
        FR.Value := -2147483647;
        if ToText50(FR, R) then Observer.Observe('min', Format(R, 0, 9)) else Observer.ObserveError('min');
        if ToViaText50(FR, R) then Observer.Observe('min via variant', Format(R, 0, 9)) else Observer.ObserveError('min via variant');
        FR.Value := -1;
        if ToText50(FR, R) then Observer.Observe('neg1', Format(R, 0, 9)) else Observer.ObserveError('neg1');
        if ToViaText50(FR, R) then Observer.Observe('neg1 via variant', Format(R, 0, 9)) else Observer.ObserveError('neg1 via variant');
        FR.Value := 1000;
        if ToText50(FR, R) then Observer.Observe('1000', Format(R, 0, 9)) else Observer.ObserveError('1000');
        if ToViaText50(FR, R) then Observer.Observe('1000 via variant', Format(R, 0, 9)) else Observer.ObserveError('1000 via variant');
        Observer.Expect('0', '0');
        Observer.Expect('0 via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('0 via variant|code', 'TypeConversion');
        Observer.Expect('1', '1');
        Observer.Expect('1 via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('1 via variant|code', 'TypeConversion');
        Observer.Expect('max', '2147483647');
        Observer.Expect('max via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('max via variant|code', 'TypeConversion');
        Observer.Expect('min', '-2147483647');
        Observer.Expect('min via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('min via variant|code', 'TypeConversion');
        Observer.Expect('neg1', '-1');
        Observer.Expect('neg1 via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('neg1 via variant|code', 'TypeConversion');
        Observer.Expect('1000', '1000');
        Observer.Expect('1000 via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('1000 via variant|code', 'TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure IntField_To_BigInteger()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: BigInteger;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(IntF));
        FR.Value := 0;
        if ToBigInteger(FR, R) then Observer.Observe('0', Format(R, 0, 9)) else Observer.ObserveError('0');
        if ToViaBigInteger(FR, R) then Observer.Observe('0 via variant', Format(R, 0, 9)) else Observer.ObserveError('0 via variant');
        FR.Value := 1;
        if ToBigInteger(FR, R) then Observer.Observe('1', Format(R, 0, 9)) else Observer.ObserveError('1');
        if ToViaBigInteger(FR, R) then Observer.Observe('1 via variant', Format(R, 0, 9)) else Observer.ObserveError('1 via variant');
        FR.Value := 2147483647;
        if ToBigInteger(FR, R) then Observer.Observe('max', Format(R, 0, 9)) else Observer.ObserveError('max');
        if ToViaBigInteger(FR, R) then Observer.Observe('max via variant', Format(R, 0, 9)) else Observer.ObserveError('max via variant');
        FR.Value := -2147483647;
        if ToBigInteger(FR, R) then Observer.Observe('min', Format(R, 0, 9)) else Observer.ObserveError('min');
        if ToViaBigInteger(FR, R) then Observer.Observe('min via variant', Format(R, 0, 9)) else Observer.ObserveError('min via variant');
        FR.Value := -1;
        if ToBigInteger(FR, R) then Observer.Observe('neg1', Format(R, 0, 9)) else Observer.ObserveError('neg1');
        if ToViaBigInteger(FR, R) then Observer.Observe('neg1 via variant', Format(R, 0, 9)) else Observer.ObserveError('neg1 via variant');
        FR.Value := 1000;
        if ToBigInteger(FR, R) then Observer.Observe('1000', Format(R, 0, 9)) else Observer.ObserveError('1000');
        if ToViaBigInteger(FR, R) then Observer.Observe('1000 via variant', Format(R, 0, 9)) else Observer.ObserveError('1000 via variant');
        Observer.Expect('0', '0');
        Observer.Expect('0 via variant', '0');
        Observer.Expect('1', '1');
        Observer.Expect('1 via variant', '1');
        Observer.Expect('max', '2147483647');
        Observer.Expect('max via variant', '2147483647');
        Observer.Expect('min', '-2147483647');
        Observer.Expect('min via variant', '-2147483647');
        Observer.Expect('neg1', '-1');
        Observer.Expect('neg1 via variant', '-1');
        Observer.Expect('1000', '1000');
        Observer.Expect('1000 via variant', '1000');
        Observer.Verify();
    end;

    [Test]
    procedure PrimaryKeyViaFieldIndex_To_DateTime()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: DateTime;
    begin
        Rec.DeleteAll();
        Rec.Id := 1;
        Rec.Insert();
        RR.GetTable(Rec);
        FR := RR.FieldIndex(1);
        Observer.Observe('type', Format(FR.Type));
        if ToDateTime(FR, R) then Observer.Observe('pk', Format(R, 0, 9)) else Observer.ObserveError('pk');
        RR.Close();
        RR.Open(Database::"FVC Source");
        RR.FindFirst();
        FR := RR.FieldIndex(1);
        if ToDateTime(FR, R) then Observer.Observe('pk reread', Format(R, 0, 9)) else Observer.ObserveError('pk reread');
        Observer.Expect('type', 'Integer');
#if BC28PLUS
        Observer.Expect('pk|text', 'The value "1" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('pk|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to System.DateTime.');
#endif
#if BC28PLUS
        Observer.Expect('pk|code', 'Evaluate:Conversion');
#else
        Observer.Expect('pk|code', 'Conversion');
#endif
#if BC28PLUS
        Observer.Expect('pk reread|text', 'The value "1" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('pk reread|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to System.DateTime.');
#endif
#if BC28PLUS
        Observer.Expect('pk reread|code', 'Evaluate:Conversion');
#else
        Observer.Expect('pk reread|code', 'Conversion');
#endif
        Observer.Verify();
    end;

    [TryFunction]
    local procedure ToDateTime(var FR: FieldRef; var R: DateTime)
    begin
        Clear(R);
        R := FR.Value;
    end;

    [TryFunction]
    local procedure ToViaDateTime(var FR: FieldRef; var R: DateTime)
    var
        V: Variant;
    begin
        Clear(R);
        V := FR.Value;
        R := V;
    end;
    [TryFunction]
    local procedure ToDate(var FR: FieldRef; var R: Date)
    begin
        Clear(R);
        R := FR.Value;
    end;

    [TryFunction]
    local procedure ToViaDate(var FR: FieldRef; var R: Date)
    var
        V: Variant;
    begin
        Clear(R);
        V := FR.Value;
        R := V;
    end;
    [TryFunction]
    local procedure ToTime(var FR: FieldRef; var R: Time)
    begin
        Clear(R);
        R := FR.Value;
    end;

    [TryFunction]
    local procedure ToViaTime(var FR: FieldRef; var R: Time)
    var
        V: Variant;
    begin
        Clear(R);
        V := FR.Value;
        R := V;
    end;
    [TryFunction]
    local procedure ToDuration(var FR: FieldRef; var R: Duration)
    begin
        Clear(R);
        R := FR.Value;
    end;

    [TryFunction]
    local procedure ToViaDuration(var FR: FieldRef; var R: Duration)
    var
        V: Variant;
    begin
        Clear(R);
        V := FR.Value;
        R := V;
    end;
    [TryFunction]
    local procedure ToDecimal(var FR: FieldRef; var R: Decimal)
    begin
        Clear(R);
        R := FR.Value;
    end;

    [TryFunction]
    local procedure ToViaDecimal(var FR: FieldRef; var R: Decimal)
    var
        V: Variant;
    begin
        Clear(R);
        V := FR.Value;
        R := V;
    end;
    [TryFunction]
    local procedure ToBoolean(var FR: FieldRef; var R: Boolean)
    begin
        Clear(R);
        R := FR.Value;
    end;

    [TryFunction]
    local procedure ToViaBoolean(var FR: FieldRef; var R: Boolean)
    var
        V: Variant;
    begin
        Clear(R);
        V := FR.Value;
        R := V;
    end;
    [TryFunction]
    local procedure ToCode20(var FR: FieldRef; var R: Code[20])
    begin
        Clear(R);
        R := FR.Value;
    end;

    [TryFunction]
    local procedure ToViaCode20(var FR: FieldRef; var R: Code[20])
    var
        V: Variant;
    begin
        Clear(R);
        V := FR.Value;
        R := V;
    end;
    [TryFunction]
    local procedure ToText50(var FR: FieldRef; var R: Text[50])
    begin
        Clear(R);
        R := FR.Value;
    end;

    [TryFunction]
    local procedure ToViaText50(var FR: FieldRef; var R: Text[50])
    var
        V: Variant;
    begin
        Clear(R);
        V := FR.Value;
        R := V;
    end;
    [TryFunction]
    local procedure ToInteger(var FR: FieldRef; var R: Integer)
    begin
        Clear(R);
        R := FR.Value;
    end;

    [TryFunction]
    local procedure ToViaInteger(var FR: FieldRef; var R: Integer)
    var
        V: Variant;
    begin
        Clear(R);
        V := FR.Value;
        R := V;
    end;
    [TryFunction]
    local procedure ToBigInteger(var FR: FieldRef; var R: BigInteger)
    begin
        Clear(R);
        R := FR.Value;
    end;

    [TryFunction]
    local procedure ToViaBigInteger(var FR: FieldRef; var R: BigInteger)
    var
        V: Variant;
    begin
        Clear(R);
        V := FR.Value;
        R := V;
    end;
}
