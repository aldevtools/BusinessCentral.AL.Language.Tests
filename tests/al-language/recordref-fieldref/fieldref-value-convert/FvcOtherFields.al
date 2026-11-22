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

codeunit 75984 "FVC Other Fields"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure DurField_To_Integer()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Integer;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DurF));
        FR.Value := 65000;
        if ToInteger(FR, R) then Observer.Observe('dur', Format(R, 0, 9)) else Observer.ObserveError('dur');
        if ToViaInteger(FR, R) then Observer.Observe('dur via variant', Format(R, 0, 9)) else Observer.ObserveError('dur via variant');
        Observer.Expect('dur', '65000');
        Observer.Expect('dur via variant', '65000');
        Observer.Verify();
    end;

    [Test]
    procedure DurField_To_BigInteger()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: BigInteger;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DurF));
        FR.Value := 65000;
        if ToBigInteger(FR, R) then Observer.Observe('dur', Format(R, 0, 9)) else Observer.ObserveError('dur');
        if ToViaBigInteger(FR, R) then Observer.Observe('dur via variant', Format(R, 0, 9)) else Observer.ObserveError('dur via variant');
        Observer.Expect('dur', '65000');
        Observer.Expect('dur via variant', '65000');
        Observer.Verify();
    end;

    [Test]
    procedure DurField_To_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Decimal;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DurF));
        FR.Value := 65000;
        if ToDecimal(FR, R) then Observer.Observe('dur', Format(R, 0, 9)) else Observer.ObserveError('dur');
        if ToViaDecimal(FR, R) then Observer.Observe('dur via variant', Format(R, 0, 9)) else Observer.ObserveError('dur via variant');
        Observer.Expect('dur', '65000');
        Observer.Expect('dur via variant', '65000');
        Observer.Verify();
    end;

    [Test]
    procedure DurField_To_DateTime()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: DateTime;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DurF));
        FR.Value := 65000;
        if ToDateTime(FR, R) then Observer.Observe('dur', Format(R, 0, 9)) else Observer.ObserveError('dur');
        if ToViaDateTime(FR, R) then Observer.Observe('dur via variant', Format(R, 0, 9)) else Observer.ObserveError('dur via variant');
#if BC28PLUS
        Observer.Expect('dur|text', 'The value "1 minute 5 seconds" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('dur|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDuration to System.DateTime.');
#endif
#if BC28PLUS
        Observer.Expect('dur|code', 'Evaluate:Conversion');
#else
        Observer.Expect('dur|code', 'Conversion');
#endif
        Observer.Expect('dur via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavDateTime value.');
        Observer.Expect('dur via variant|code', 'TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure DurField_To_Text50()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Text[50];
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DurF));
        FR.Value := 65000;
        if ToText50(FR, R) then Observer.Observe('dur', Format(R, 0, 9)) else Observer.ObserveError('dur');
        if ToViaText50(FR, R) then Observer.Observe('dur via variant', Format(R, 0, 9)) else Observer.ObserveError('dur via variant');
        Observer.Expect('dur', '1 minute 5 seconds');
        Observer.Expect('dur via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('dur via variant|code', 'TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure DecField_To_Integer()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Integer;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DecF));
        FR.Value := 1.5;
        if ToInteger(FR, R) then Observer.Observe('dec', Format(R, 0, 9)) else Observer.ObserveError('dec');
        if ToViaInteger(FR, R) then Observer.Observe('dec via variant', Format(R, 0, 9)) else Observer.ObserveError('dec via variant');
        Observer.Expect('dec|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.5 to System.Int32.');
        Observer.Expect('dec|code', 'ConversionCast');
        Observer.Expect('dec via variant|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.5 to System.Int32.');
        Observer.Expect('dec via variant|code', 'ConversionCast');
        Observer.Verify();
    end;

    [Test]
    procedure DecField_To_DateTime()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: DateTime;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DecF));
        FR.Value := 1.5;
        if ToDateTime(FR, R) then Observer.Observe('dec', Format(R, 0, 9)) else Observer.ObserveError('dec');
        if ToViaDateTime(FR, R) then Observer.Observe('dec via variant', Format(R, 0, 9)) else Observer.ObserveError('dec via variant');
#if BC28PLUS
        Observer.Expect('dec|text', 'The value "1.5" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('dec|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDecimal to System.DateTime.');
#endif
#if BC28PLUS
        Observer.Expect('dec|code', 'Evaluate:Conversion');
#else
        Observer.Expect('dec|code', 'Conversion');
#endif
        Observer.Expect('dec via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavDateTime value.');
        Observer.Expect('dec via variant|code', 'TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure DecField_To_Duration()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Duration;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DecF));
        FR.Value := 1.5;
        if ToDuration(FR, R) then Observer.Observe('dec', Format(R, 0, 9)) else Observer.ObserveError('dec');
        if ToViaDuration(FR, R) then Observer.Observe('dec via variant', Format(R, 0, 9)) else Observer.ObserveError('dec via variant');
        Observer.Expect('dec|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.5 to System.Int64.');
        Observer.Expect('dec|code', 'ConversionCast');
        Observer.Expect('dec via variant|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.5 to System.Int64.');
        Observer.Expect('dec via variant|code', 'ConversionCast');
        Observer.Verify();
    end;

    [Test]
    procedure DecField_To_Boolean()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Boolean;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DecF));
        FR.Value := 1.5;
        if ToBoolean(FR, R) then Observer.Observe('dec', Format(R, 0, 9)) else Observer.ObserveError('dec');
        if ToViaBoolean(FR, R) then Observer.Observe('dec via variant', Format(R, 0, 9)) else Observer.ObserveError('dec via variant');
        Observer.Expect('dec|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.5 to System.Int32.');
        Observer.Expect('dec|code', 'ConversionCast');
        Observer.Expect('dec via variant|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.5 to System.Int32.');
        Observer.Expect('dec via variant|code', 'ConversionCast');
        Observer.Verify();
    end;

    [Test]
    procedure DecField_To_Text50()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Text[50];
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DecF));
        FR.Value := 1.5;
        if ToText50(FR, R) then Observer.Observe('dec', Format(R, 0, 9)) else Observer.ObserveError('dec');
        if ToViaText50(FR, R) then Observer.Observe('dec via variant', Format(R, 0, 9)) else Observer.ObserveError('dec via variant');
        Observer.Expect('dec', '1.5');
        Observer.Expect('dec via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('dec via variant|code', 'TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure BoolField_To_Integer()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Integer;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(BoolF));
        FR.Value := true;
        if ToInteger(FR, R) then Observer.Observe('bool-true', Format(R, 0, 9)) else Observer.ObserveError('bool-true');
        if ToViaInteger(FR, R) then Observer.Observe('bool-true via variant', Format(R, 0, 9)) else Observer.ObserveError('bool-true via variant');
        FR.Value := false;
        if ToInteger(FR, R) then Observer.Observe('bool-false', Format(R, 0, 9)) else Observer.ObserveError('bool-false');
        if ToViaInteger(FR, R) then Observer.Observe('bool-false via variant', Format(R, 0, 9)) else Observer.ObserveError('bool-false via variant');
        Observer.Expect('bool-true', '1');
        Observer.Expect('bool-true via variant', '1');
        Observer.Expect('bool-false', '0');
        Observer.Expect('bool-false via variant', '0');
        Observer.Verify();
    end;

    [Test]
    procedure BoolField_To_DateTime()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: DateTime;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(BoolF));
        FR.Value := true;
        if ToDateTime(FR, R) then Observer.Observe('bool-true', Format(R, 0, 9)) else Observer.ObserveError('bool-true');
        if ToViaDateTime(FR, R) then Observer.Observe('bool-true via variant', Format(R, 0, 9)) else Observer.ObserveError('bool-true via variant');
        FR.Value := false;
        if ToDateTime(FR, R) then Observer.Observe('bool-false', Format(R, 0, 9)) else Observer.ObserveError('bool-false');
        if ToViaDateTime(FR, R) then Observer.Observe('bool-false via variant', Format(R, 0, 9)) else Observer.ObserveError('bool-false via variant');
#if BC28PLUS
        Observer.Expect('bool-true|text', 'The value "Yes" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('bool-true|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavBoolean to System.DateTime.');
#endif
#if BC28PLUS
        Observer.Expect('bool-true|code', 'Evaluate:Conversion');
#else
        Observer.Expect('bool-true|code', 'Conversion');
#endif
        Observer.Expect('bool-true via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavDateTime value.');
        Observer.Expect('bool-true via variant|code', 'TypeConversion');
#if BC28PLUS
        Observer.Expect('bool-false|text', 'The value "No" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('bool-false|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavBoolean to System.DateTime.');
#endif
#if BC28PLUS
        Observer.Expect('bool-false|code', 'Evaluate:Conversion');
#else
        Observer.Expect('bool-false|code', 'Conversion');
#endif
        Observer.Expect('bool-false via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavDateTime value.');
        Observer.Expect('bool-false via variant|code', 'TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure BoolField_To_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Decimal;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(BoolF));
        FR.Value := true;
        if ToDecimal(FR, R) then Observer.Observe('bool-true', Format(R, 0, 9)) else Observer.ObserveError('bool-true');
        if ToViaDecimal(FR, R) then Observer.Observe('bool-true via variant', Format(R, 0, 9)) else Observer.ObserveError('bool-true via variant');
        FR.Value := false;
        if ToDecimal(FR, R) then Observer.Observe('bool-false', Format(R, 0, 9)) else Observer.ObserveError('bool-false');
        if ToViaDecimal(FR, R) then Observer.Observe('bool-false via variant', Format(R, 0, 9)) else Observer.ObserveError('bool-false via variant');
        Observer.Expect('bool-true', '1');
        Observer.Expect('bool-true via variant', '1');
        Observer.Expect('bool-false', '0');
        Observer.Expect('bool-false via variant', '0');
        Observer.Verify();
    end;

    [Test]
    procedure BoolField_To_Text50()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Text[50];
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(BoolF));
        FR.Value := true;
        if ToText50(FR, R) then Observer.Observe('bool-true', Format(R, 0, 9)) else Observer.ObserveError('bool-true');
        if ToViaText50(FR, R) then Observer.Observe('bool-true via variant', Format(R, 0, 9)) else Observer.ObserveError('bool-true via variant');
        FR.Value := false;
        if ToText50(FR, R) then Observer.Observe('bool-false', Format(R, 0, 9)) else Observer.ObserveError('bool-false');
        if ToViaText50(FR, R) then Observer.Observe('bool-false via variant', Format(R, 0, 9)) else Observer.ObserveError('bool-false via variant');
        Observer.Expect('bool-true', 'Yes');
        Observer.Expect('bool-true via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('bool-true via variant|code', 'TypeConversion');
        Observer.Expect('bool-false', 'No');
        Observer.Expect('bool-false via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('bool-false via variant|code', 'TypeConversion');
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
