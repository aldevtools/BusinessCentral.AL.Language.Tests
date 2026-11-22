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

codeunit 75983 "FVC Temporal Fields"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure DtField_To_Date()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Date;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DtF));
        FR.Value := CreateDateTime(20260131D, 120000T);
        if ToDate(FR, R) then Observer.Observe('dt', Format(R, 0, 9)) else Observer.ObserveError('dt');
        if ToViaDate(FR, R) then Observer.Observe('dt via variant', Format(R, 0, 9)) else Observer.ObserveError('dt via variant');
        FR.Value := 0DT;
        if ToDate(FR, R) then Observer.Observe('dt-zero', Format(R, 0, 9)) else Observer.ObserveError('dt-zero');
        if ToViaDate(FR, R) then Observer.Observe('dt-zero via variant', Format(R, 0, 9)) else Observer.ObserveError('dt-zero via variant');
        Observer.Expect('dt|text', 'The date is not valid.');
        Observer.Expect('dt|code', 'DateInvalid');
        Observer.Expect('dt via variant', '2026-01-31');
        Observer.Expect('dt-zero', '');
        Observer.Expect('dt-zero via variant', '');
        Observer.Verify();
    end;

    [Test]
    procedure DtField_To_Time()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Time;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DtF));
        FR.Value := CreateDateTime(20260131D, 120000T);
        if ToTime(FR, R) then Observer.Observe('dt', Format(R, 0, 9)) else Observer.ObserveError('dt');
        if ToViaTime(FR, R) then Observer.Observe('dt via variant', Format(R, 0, 9)) else Observer.ObserveError('dt via variant');
        FR.Value := 0DT;
        if ToTime(FR, R) then Observer.Observe('dt-zero', Format(R, 0, 9)) else Observer.ObserveError('dt-zero');
        if ToViaTime(FR, R) then Observer.Observe('dt-zero via variant', Format(R, 0, 9)) else Observer.ObserveError('dt-zero via variant');
        Observer.Expect('dt|text', 'The time is not valid.');
        Observer.Expect('dt|code', 'InvalidTime');
        Observer.Expect('dt via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavTime value.');
        Observer.Expect('dt via variant|code', 'TypeConversion');
        Observer.Expect('dt-zero', '');
        Observer.Expect('dt-zero via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavTime value.');
        Observer.Expect('dt-zero via variant|code', 'TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure DtField_To_Duration()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Duration;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DtF));
        FR.Value := CreateDateTime(20260131D, 120000T);
        if ToDuration(FR, R) then Observer.Observe('dt', Format(R, 0, 9)) else Observer.ObserveError('dt');
        if ToViaDuration(FR, R) then Observer.Observe('dt via variant', Format(R, 0, 9)) else Observer.ObserveError('dt via variant');
        FR.Value := 0DT;
        if ToDuration(FR, R) then Observer.Observe('dt-zero', Format(R, 0, 9)) else Observer.ObserveError('dt-zero');
        if ToViaDuration(FR, R) then Observer.Observe('dt-zero via variant', Format(R, 0, 9)) else Observer.ObserveError('dt-zero via variant');
        Observer.Expect('dt', 'P740012DT12H0M0.001S');
        Observer.Expect('dt via variant', 'P740012DT12H0M0.001S');
        Observer.Expect('dt-zero', 'P0DT0H0M0.0S');
        Observer.Expect('dt-zero via variant', 'P0DT0H0M0.0S');
        Observer.Verify();
    end;

    [Test]
    procedure DtField_To_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Decimal;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DtF));
        FR.Value := CreateDateTime(20260131D, 120000T);
        if ToDecimal(FR, R) then Observer.Observe('dt', Format(R, 0, 9)) else Observer.ObserveError('dt');
        if ToViaDecimal(FR, R) then Observer.Observe('dt via variant', Format(R, 0, 9)) else Observer.ObserveError('dt via variant');
        FR.Value := 0DT;
        if ToDecimal(FR, R) then Observer.Observe('dt-zero', Format(R, 0, 9)) else Observer.ObserveError('dt-zero');
        if ToViaDecimal(FR, R) then Observer.Observe('dt-zero via variant', Format(R, 0, 9)) else Observer.ObserveError('dt-zero via variant');
        Observer.Expect('dt|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDateTime to Microsoft.Dynamics.Nav.Runtime.Decimal18.');
        Observer.Expect('dt|code', 'Conversion');
        Observer.Expect('dt via variant', '63937080000001');
        Observer.Expect('dt-zero|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDateTime to Microsoft.Dynamics.Nav.Runtime.Decimal18.');
        Observer.Expect('dt-zero|code', 'Conversion');
        Observer.Expect('dt-zero via variant', '0');
        Observer.Verify();
    end;

    [Test]
    procedure DtField_To_Boolean()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Boolean;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DtF));
        FR.Value := CreateDateTime(20260131D, 120000T);
        if ToBoolean(FR, R) then Observer.Observe('dt', Format(R, 0, 9)) else Observer.ObserveError('dt');
        if ToViaBoolean(FR, R) then Observer.Observe('dt via variant', Format(R, 0, 9)) else Observer.ObserveError('dt via variant');
        FR.Value := 0DT;
        if ToBoolean(FR, R) then Observer.Observe('dt-zero', Format(R, 0, 9)) else Observer.ObserveError('dt-zero');
        if ToViaBoolean(FR, R) then Observer.Observe('dt-zero via variant', Format(R, 0, 9)) else Observer.ObserveError('dt-zero via variant');
        Observer.Expect('dt|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDateTime to System.Int32.');
        Observer.Expect('dt|code', 'Conversion');
        Observer.Expect('dt via variant|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDateTime to System.Int32.');
        Observer.Expect('dt via variant|code', 'Conversion');
        Observer.Expect('dt-zero|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDateTime to System.Int32.');
        Observer.Expect('dt-zero|code', 'Conversion');
        Observer.Expect('dt-zero via variant|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDateTime to System.Int32.');
        Observer.Expect('dt-zero via variant|code', 'Conversion');
        Observer.Verify();
    end;

    [Test]
    procedure DtField_To_Code20()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Code[20];
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DtF));
        FR.Value := CreateDateTime(20260131D, 120000T);
        if ToCode20(FR, R) then Observer.Observe('dt', Format(R, 0, 9)) else Observer.ObserveError('dt');
        if ToViaCode20(FR, R) then Observer.Observe('dt via variant', Format(R, 0, 9)) else Observer.ObserveError('dt via variant');
        FR.Value := 0DT;
        if ToCode20(FR, R) then Observer.Observe('dt-zero', Format(R, 0, 9)) else Observer.ObserveError('dt-zero');
        if ToViaCode20(FR, R) then Observer.Observe('dt-zero via variant', Format(R, 0, 9)) else Observer.ObserveError('dt-zero via variant');
        Observer.Expect('dt', '01/31/26 12:00 PM');
        Observer.Expect('dt via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Expect('dt via variant|code', 'TypeConversion');
        Observer.Expect('dt-zero', '');
        Observer.Expect('dt-zero via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Expect('dt-zero via variant|code', 'TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure DtField_To_Text50()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Text[50];
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DtF));
        FR.Value := CreateDateTime(20260131D, 120000T);
        if ToText50(FR, R) then Observer.Observe('dt', Format(R, 0, 9)) else Observer.ObserveError('dt');
        if ToViaText50(FR, R) then Observer.Observe('dt via variant', Format(R, 0, 9)) else Observer.ObserveError('dt via variant');
        FR.Value := 0DT;
        if ToText50(FR, R) then Observer.Observe('dt-zero', Format(R, 0, 9)) else Observer.ObserveError('dt-zero');
        if ToViaText50(FR, R) then Observer.Observe('dt-zero via variant', Format(R, 0, 9)) else Observer.ObserveError('dt-zero via variant');
        Observer.Expect('dt', '01/31/26 12:00 PM');
        Observer.Expect('dt via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('dt via variant|code', 'TypeConversion');
        Observer.Expect('dt-zero', '');
        Observer.Expect('dt-zero via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('dt-zero via variant|code', 'TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure DtField_To_Integer()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Integer;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DtF));
        FR.Value := CreateDateTime(20260131D, 120000T);
        if ToInteger(FR, R) then Observer.Observe('dt', Format(R, 0, 9)) else Observer.ObserveError('dt');
        if ToViaInteger(FR, R) then Observer.Observe('dt via variant', Format(R, 0, 9)) else Observer.ObserveError('dt via variant');
        FR.Value := 0DT;
        if ToInteger(FR, R) then Observer.Observe('dt-zero', Format(R, 0, 9)) else Observer.ObserveError('dt-zero');
        if ToViaInteger(FR, R) then Observer.Observe('dt-zero via variant', Format(R, 0, 9)) else Observer.ObserveError('dt-zero via variant');
        Observer.Expect('dt|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDateTime to System.Int32.');
        Observer.Expect('dt|code', 'Conversion');
        Observer.Expect('dt via variant|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDateTime to System.Int32.');
        Observer.Expect('dt via variant|code', 'Conversion');
        Observer.Expect('dt-zero|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDateTime to System.Int32.');
        Observer.Expect('dt-zero|code', 'Conversion');
        Observer.Expect('dt-zero via variant|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDateTime to System.Int32.');
        Observer.Expect('dt-zero via variant|code', 'Conversion');
        Observer.Verify();
    end;

    [Test]
    procedure DtField_To_BigInteger()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: BigInteger;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DtF));
        FR.Value := CreateDateTime(20260131D, 120000T);
        if ToBigInteger(FR, R) then Observer.Observe('dt', Format(R, 0, 9)) else Observer.ObserveError('dt');
        if ToViaBigInteger(FR, R) then Observer.Observe('dt via variant', Format(R, 0, 9)) else Observer.ObserveError('dt via variant');
        FR.Value := 0DT;
        if ToBigInteger(FR, R) then Observer.Observe('dt-zero', Format(R, 0, 9)) else Observer.ObserveError('dt-zero');
        if ToViaBigInteger(FR, R) then Observer.Observe('dt-zero via variant', Format(R, 0, 9)) else Observer.ObserveError('dt-zero via variant');
        Observer.Expect('dt|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDateTime to System.Int64.');
        Observer.Expect('dt|code', 'Conversion');
        Observer.Expect('dt via variant', '63937080000001');
        Observer.Expect('dt-zero|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDateTime to System.Int64.');
        Observer.Expect('dt-zero|code', 'Conversion');
        Observer.Expect('dt-zero via variant', '0');
        Observer.Verify();
    end;

    [Test]
    procedure DateField_To_Integer()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Integer;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DateF));
        FR.Value := 20260131D;
        if ToInteger(FR, R) then Observer.Observe('d', Format(R, 0, 9)) else Observer.ObserveError('d');
        if ToViaInteger(FR, R) then Observer.Observe('d via variant', Format(R, 0, 9)) else Observer.ObserveError('d via variant');
        Observer.Expect('d|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDate to System.Int32.');
        Observer.Expect('d|code', 'Conversion');
        Observer.Expect('d via variant', '1480025');
        Observer.Verify();
    end;

    [Test]
    procedure DateField_To_DateTime()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: DateTime;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DateF));
        FR.Value := 20260131D;
        if ToDateTime(FR, R) then Observer.Observe('d', Format(R, 0, 9)) else Observer.ObserveError('d');
        if ToViaDateTime(FR, R) then Observer.Observe('d via variant', Format(R, 0, 9)) else Observer.ObserveError('d via variant');
        Observer.Expect('d', '2026-01-31T00:00:00Z');
        Observer.Expect('d via variant', '2026-01-31T00:00:00Z');
        Observer.Verify();
    end;

    [Test]
    procedure DateField_To_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Decimal;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DateF));
        FR.Value := 20260131D;
        if ToDecimal(FR, R) then Observer.Observe('d', Format(R, 0, 9)) else Observer.ObserveError('d');
        if ToViaDecimal(FR, R) then Observer.Observe('d via variant', Format(R, 0, 9)) else Observer.ObserveError('d via variant');
        Observer.Expect('d|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDate to Microsoft.Dynamics.Nav.Runtime.Decimal18.');
        Observer.Expect('d|code', 'Conversion');
        Observer.Expect('d via variant', '1480025');
        Observer.Verify();
    end;

    [Test]
    procedure DateField_To_Text50()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Text[50];
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DateF));
        FR.Value := 20260131D;
        if ToText50(FR, R) then Observer.Observe('d', Format(R, 0, 9)) else Observer.ObserveError('d');
        if ToViaText50(FR, R) then Observer.Observe('d via variant', Format(R, 0, 9)) else Observer.ObserveError('d via variant');
        Observer.Expect('d', '01/31/26');
        Observer.Expect('d via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('d via variant|code', 'TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure TimeField_To_Integer()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Integer;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(TimeF));
        FR.Value := 120000T;
        if ToInteger(FR, R) then Observer.Observe('t', Format(R, 0, 9)) else Observer.ObserveError('t');
        if ToViaInteger(FR, R) then Observer.Observe('t via variant', Format(R, 0, 9)) else Observer.ObserveError('t via variant');
        Observer.Expect('t|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavTime to System.Int32.');
        Observer.Expect('t|code', 'Conversion');
        Observer.Expect('t via variant', '43200001');
        Observer.Verify();
    end;

    [Test]
    procedure TimeField_To_DateTime()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: DateTime;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(TimeF));
        FR.Value := 120000T;
        if ToDateTime(FR, R) then Observer.Observe('t', Format(R, 0, 9)) else Observer.ObserveError('t');
        if ToViaDateTime(FR, R) then Observer.Observe('t via variant', Format(R, 0, 9)) else Observer.ObserveError('t via variant');
        Observer.Expect('t', '0001-01-02T12:00:00Z');
        Observer.Expect('t via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavDateTime value.');
        Observer.Expect('t via variant|code', 'TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure TimeField_To_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Decimal;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(TimeF));
        FR.Value := 120000T;
        if ToDecimal(FR, R) then Observer.Observe('t', Format(R, 0, 9)) else Observer.ObserveError('t');
        if ToViaDecimal(FR, R) then Observer.Observe('t via variant', Format(R, 0, 9)) else Observer.ObserveError('t via variant');
        Observer.Expect('t|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavTime to Microsoft.Dynamics.Nav.Runtime.Decimal18.');
        Observer.Expect('t|code', 'Conversion');
        Observer.Expect('t via variant', '43200001');
        Observer.Verify();
    end;

    [Test]
    procedure TimeField_To_Text50()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
        R: Text[50];
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(TimeF));
        FR.Value := 120000T;
        if ToText50(FR, R) then Observer.Observe('t', Format(R, 0, 9)) else Observer.ObserveError('t');
        if ToViaText50(FR, R) then Observer.Observe('t via variant', Format(R, 0, 9)) else Observer.ObserveError('t via variant');
        Observer.Expect('t', '12:00:00 PM');
        Observer.Expect('t via variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('t via variant|code', 'TypeConversion');
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
