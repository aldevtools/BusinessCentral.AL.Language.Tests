// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-value-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), FVC Source (75980)
// Probe: written against a local BC 27.5 / 28.5 / 29.0 observe host; every literal asserted below is what BC produced.
// Facts: FieldRef.Value of an Integer, BigInteger, Decimal, Duration or Boolean field assigned to a DateTime (runner issue 8662, extends FvcIntegerField, FvcOtherFields).
//   Four assignment shapes per value: a var parameter, a plain declared local, a by-value parameter and a named return value.
//   The var parameter shape matches the earlier probe; the other three measure whether the target slot changes the result.
//   Values beyond the earlier probe: more Decimal values (negative, many decimals, whole, 1000 or more) and Duration values (days, other milliseconds, 0, negative).
//   Result (BC 27.5, 28.5, 29.0): every cell raises. The four shapes give the same error as the var parameter shape.
//   Version difference: BC 27 gives 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.Nav<Type> to System.DateTime.' (code Conversion), BC 28 and later
//   the Evaluate error of the value's text (code Evaluate:Conversion). Decimal text uses thousands separators (1,000.5); Duration text is the long form (1 minute 5 seconds).
// BC versions: see the asserted values; a version guard is used only where the versions differ.

codeunit 75985 "FVC DateTime Shapes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure IntField_To_DateTime_Shapes()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(IntF));
        FR.Value := 0;
        Shapes(Observer, FR, '0');
        FR.Value := 1;
        Shapes(Observer, FR, '1');
        FR.Value := 1000;
        Shapes(Observer, FR, '1000');
        FR.Value := -1;
        Shapes(Observer, FR, 'neg1');
#if BC28PLUS
        Observer.Expect('0 var', 'error Evaluate:Conversion | The value "0" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('0 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to System.DateTime.');
#endif
        Observer.Expect('0 local', 'same as var');
        Observer.Expect('0 byval', 'same as var');
        Observer.Expect('0 named', 'same as var');
        Observer.Expect('0 plain var', 'same as var');
        Observer.Expect('0 plain local', 'same as var');
        Observer.Expect('0 plain byval', 'same as var');
        Observer.Expect('0 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('1 var', 'error Evaluate:Conversion | The value "1" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('1 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to System.DateTime.');
#endif
        Observer.Expect('1 local', 'same as var');
        Observer.Expect('1 byval', 'same as var');
        Observer.Expect('1 named', 'same as var');
        Observer.Expect('1 plain var', 'same as var');
        Observer.Expect('1 plain local', 'same as var');
        Observer.Expect('1 plain byval', 'same as var');
        Observer.Expect('1 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('1000 var', 'error Evaluate:Conversion | The value "1000" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('1000 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to System.DateTime.');
#endif
        Observer.Expect('1000 local', 'same as var');
        Observer.Expect('1000 byval', 'same as var');
        Observer.Expect('1000 named', 'same as var');
        Observer.Expect('1000 plain var', 'same as var');
        Observer.Expect('1000 plain local', 'same as var');
        Observer.Expect('1000 plain byval', 'same as var');
        Observer.Expect('1000 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('neg1 var', 'error Evaluate:Conversion | The value "-1" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('neg1 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to System.DateTime.');
#endif
        Observer.Expect('neg1 local', 'same as var');
        Observer.Expect('neg1 byval', 'same as var');
        Observer.Expect('neg1 named', 'same as var');
        Observer.Expect('neg1 plain var', 'same as var');
        Observer.Expect('neg1 plain local', 'same as var');
        Observer.Expect('neg1 plain byval', 'same as var');
        Observer.Expect('neg1 plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure BigField_To_DateTime_Shapes()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(BigF));
        FR.Value := 1;
        Shapes(Observer, FR, '1');
        FR.Value := 3000000000L;
        Shapes(Observer, FR, '3e9');
        FR.Value := -1;
        Shapes(Observer, FR, 'neg1');
#if BC28PLUS
        Observer.Expect('1 var', 'error Evaluate:Conversion | The value "1" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('1 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavBigInteger to System.DateTime.');
#endif
        Observer.Expect('1 local', 'same as var');
        Observer.Expect('1 byval', 'same as var');
        Observer.Expect('1 named', 'same as var');
        Observer.Expect('1 plain var', 'same as var');
        Observer.Expect('1 plain local', 'same as var');
        Observer.Expect('1 plain byval', 'same as var');
        Observer.Expect('1 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('3e9 var', 'error Evaluate:Conversion | The value "3000000000" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('3e9 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavBigInteger to System.DateTime.');
#endif
        Observer.Expect('3e9 local', 'same as var');
        Observer.Expect('3e9 byval', 'same as var');
        Observer.Expect('3e9 named', 'same as var');
        Observer.Expect('3e9 plain var', 'same as var');
        Observer.Expect('3e9 plain local', 'same as var');
        Observer.Expect('3e9 plain byval', 'same as var');
        Observer.Expect('3e9 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('neg1 var', 'error Evaluate:Conversion | The value "-1" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('neg1 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavBigInteger to System.DateTime.');
#endif
        Observer.Expect('neg1 local', 'same as var');
        Observer.Expect('neg1 byval', 'same as var');
        Observer.Expect('neg1 named', 'same as var');
        Observer.Expect('neg1 plain var', 'same as var');
        Observer.Expect('neg1 plain local', 'same as var');
        Observer.Expect('neg1 plain byval', 'same as var');
        Observer.Expect('neg1 plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure DecField_To_DateTime_Shapes_Small()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DecF));
        FR.Value := -0.5;
        Shapes(Observer, FR, 'neg half');
        FR.Value := 0.123456789;
        Shapes(Observer, FR, 'many decimals');
        FR.Value := 999.99;
        Shapes(Observer, FR, '999.99');
        FR.Value := 1.5;
        Shapes(Observer, FR, '1.5');
#if BC28PLUS
        Observer.Expect('neg half var', 'error Evaluate:Conversion | The value "-0.5" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('neg half var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDecimal to System.DateTime.');
#endif
        Observer.Expect('neg half local', 'same as var');
        Observer.Expect('neg half byval', 'same as var');
        Observer.Expect('neg half named', 'same as var');
        Observer.Expect('neg half plain var', 'same as var');
        Observer.Expect('neg half plain local', 'same as var');
        Observer.Expect('neg half plain byval', 'same as var');
        Observer.Expect('neg half plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('many decimals var', 'error Evaluate:Conversion | The value "0.123456789" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('many decimals var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDecimal to System.DateTime.');
#endif
        Observer.Expect('many decimals local', 'same as var');
        Observer.Expect('many decimals byval', 'same as var');
        Observer.Expect('many decimals named', 'same as var');
        Observer.Expect('many decimals plain var', 'same as var');
        Observer.Expect('many decimals plain local', 'same as var');
        Observer.Expect('many decimals plain byval', 'same as var');
        Observer.Expect('many decimals plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('999.99 var', 'error Evaluate:Conversion | The value "999.99" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('999.99 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDecimal to System.DateTime.');
#endif
        Observer.Expect('999.99 local', 'same as var');
        Observer.Expect('999.99 byval', 'same as var');
        Observer.Expect('999.99 named', 'same as var');
        Observer.Expect('999.99 plain var', 'same as var');
        Observer.Expect('999.99 plain local', 'same as var');
        Observer.Expect('999.99 plain byval', 'same as var');
        Observer.Expect('999.99 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('1.5 var', 'error Evaluate:Conversion | The value "1.5" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('1.5 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDecimal to System.DateTime.');
#endif
        Observer.Expect('1.5 local', 'same as var');
        Observer.Expect('1.5 byval', 'same as var');
        Observer.Expect('1.5 named', 'same as var');
        Observer.Expect('1.5 plain var', 'same as var');
        Observer.Expect('1.5 plain local', 'same as var');
        Observer.Expect('1.5 plain byval', 'same as var');
        Observer.Expect('1.5 plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure DecField_To_DateTime_Shapes_Large()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DecF));
        FR.Value := 1000.5;
        Shapes(Observer, FR, '1000.5');
        FR.Value := 0;
        Shapes(Observer, FR, 'zero');
        FR.Value := 1;
        Shapes(Observer, FR, 'one');
        FR.Value := 5;
        Shapes(Observer, FR, 'five');
        FR.Value := -1000.25;
        Shapes(Observer, FR, 'neg 1000.25');
#if BC28PLUS
        Observer.Expect('1000.5 var', 'error Evaluate:Conversion | The value "1,000.5" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('1000.5 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDecimal to System.DateTime.');
#endif
        Observer.Expect('1000.5 local', 'same as var');
        Observer.Expect('1000.5 byval', 'same as var');
        Observer.Expect('1000.5 named', 'same as var');
        Observer.Expect('1000.5 plain var', 'same as var');
        Observer.Expect('1000.5 plain local', 'same as var');
        Observer.Expect('1000.5 plain byval', 'same as var');
        Observer.Expect('1000.5 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('zero var', 'error Evaluate:Conversion | The value "0" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('zero var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDecimal to System.DateTime.');
#endif
        Observer.Expect('zero local', 'same as var');
        Observer.Expect('zero byval', 'same as var');
        Observer.Expect('zero named', 'same as var');
        Observer.Expect('zero plain var', 'same as var');
        Observer.Expect('zero plain local', 'same as var');
        Observer.Expect('zero plain byval', 'same as var');
        Observer.Expect('zero plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('one var', 'error Evaluate:Conversion | The value "1" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('one var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDecimal to System.DateTime.');
#endif
        Observer.Expect('one local', 'same as var');
        Observer.Expect('one byval', 'same as var');
        Observer.Expect('one named', 'same as var');
        Observer.Expect('one plain var', 'same as var');
        Observer.Expect('one plain local', 'same as var');
        Observer.Expect('one plain byval', 'same as var');
        Observer.Expect('one plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('five var', 'error Evaluate:Conversion | The value "5" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('five var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDecimal to System.DateTime.');
#endif
        Observer.Expect('five local', 'same as var');
        Observer.Expect('five byval', 'same as var');
        Observer.Expect('five named', 'same as var');
        Observer.Expect('five plain var', 'same as var');
        Observer.Expect('five plain local', 'same as var');
        Observer.Expect('five plain byval', 'same as var');
        Observer.Expect('five plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('neg 1000.25 var', 'error Evaluate:Conversion | The value "-1,000.25" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('neg 1000.25 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDecimal to System.DateTime.');
#endif
        Observer.Expect('neg 1000.25 local', 'same as var');
        Observer.Expect('neg 1000.25 byval', 'same as var');
        Observer.Expect('neg 1000.25 named', 'same as var');
        Observer.Expect('neg 1000.25 plain var', 'same as var');
        Observer.Expect('neg 1000.25 plain local', 'same as var');
        Observer.Expect('neg 1000.25 plain byval', 'same as var');
        Observer.Expect('neg 1000.25 plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure DurField_To_DateTime_Shapes_Small()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DurF));
        FR.Value := 1;
        Shapes(Observer, FR, '1 ms');
        FR.Value := 65000;
        Shapes(Observer, FR, '65000');
        FR.Value := 65001;
        Shapes(Observer, FR, '65001');
        FR.Value := 0;
        Shapes(Observer, FR, '0');
        FR.Value := -1;
        Shapes(Observer, FR, 'neg1');
#if BC28PLUS
        Observer.Expect('1 ms var', 'error Evaluate:Conversion | The value "1 millisecond" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('1 ms var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDuration to System.DateTime.');
#endif
        Observer.Expect('1 ms local', 'same as var');
        Observer.Expect('1 ms byval', 'same as var');
        Observer.Expect('1 ms named', 'same as var');
        Observer.Expect('1 ms plain var', 'same as var');
        Observer.Expect('1 ms plain local', 'same as var');
        Observer.Expect('1 ms plain byval', 'same as var');
        Observer.Expect('1 ms plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('65000 var', 'error Evaluate:Conversion | The value "1 minute 5 seconds" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('65000 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDuration to System.DateTime.');
#endif
        Observer.Expect('65000 local', 'same as var');
        Observer.Expect('65000 byval', 'same as var');
        Observer.Expect('65000 named', 'same as var');
        Observer.Expect('65000 plain var', 'same as var');
        Observer.Expect('65000 plain local', 'same as var');
        Observer.Expect('65000 plain byval', 'same as var');
        Observer.Expect('65000 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('65001 var', 'error Evaluate:Conversion | The value "1 minute 5 seconds 1 millisecond" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('65001 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDuration to System.DateTime.');
#endif
        Observer.Expect('65001 local', 'same as var');
        Observer.Expect('65001 byval', 'same as var');
        Observer.Expect('65001 named', 'same as var');
        Observer.Expect('65001 plain var', 'same as var');
        Observer.Expect('65001 plain local', 'same as var');
        Observer.Expect('65001 plain byval', 'same as var');
        Observer.Expect('65001 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('0 var', 'error Evaluate:Conversion | The value "" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('0 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDuration to System.DateTime.');
#endif
        Observer.Expect('0 local', 'same as var');
        Observer.Expect('0 byval', 'same as var');
        Observer.Expect('0 named', 'same as var');
        Observer.Expect('0 plain var', 'same as var');
        Observer.Expect('0 plain local', 'same as var');
        Observer.Expect('0 plain byval', 'same as var');
        Observer.Expect('0 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('neg1 var', 'error Evaluate:Conversion | The value "-1 millisecond" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('neg1 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDuration to System.DateTime.');
#endif
        Observer.Expect('neg1 local', 'same as var');
        Observer.Expect('neg1 byval', 'same as var');
        Observer.Expect('neg1 named', 'same as var');
        Observer.Expect('neg1 plain var', 'same as var');
        Observer.Expect('neg1 plain local', 'same as var');
        Observer.Expect('neg1 plain byval', 'same as var');
        Observer.Expect('neg1 plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure DurField_To_DateTime_Shapes_Large()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(DurF));
        FR.Value := 1000;
        Shapes(Observer, FR, '1000');
        FR.Value := 93780000;
        Shapes(Observer, FR, '1 day 2h 3m');
        FR.Value := 86400000;
        Shapes(Observer, FR, '1 day');
        FR.Value := 7200000;
        Shapes(Observer, FR, '2h');
#if BC28PLUS
        Observer.Expect('1000 var', 'error Evaluate:Conversion | The value "1 second" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('1000 var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDuration to System.DateTime.');
#endif
        Observer.Expect('1000 local', 'same as var');
        Observer.Expect('1000 byval', 'same as var');
        Observer.Expect('1000 named', 'same as var');
        Observer.Expect('1000 plain var', 'same as var');
        Observer.Expect('1000 plain local', 'same as var');
        Observer.Expect('1000 plain byval', 'same as var');
        Observer.Expect('1000 plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('1 day 2h 3m var', 'error Evaluate:Conversion | The value "1 day 2 hours 3 minutes" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('1 day 2h 3m var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDuration to System.DateTime.');
#endif
        Observer.Expect('1 day 2h 3m local', 'same as var');
        Observer.Expect('1 day 2h 3m byval', 'same as var');
        Observer.Expect('1 day 2h 3m named', 'same as var');
        Observer.Expect('1 day 2h 3m plain var', 'same as var');
        Observer.Expect('1 day 2h 3m plain local', 'same as var');
        Observer.Expect('1 day 2h 3m plain byval', 'same as var');
        Observer.Expect('1 day 2h 3m plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('1 day var', 'error Evaluate:Conversion | The value "1 day" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('1 day var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDuration to System.DateTime.');
#endif
        Observer.Expect('1 day local', 'same as var');
        Observer.Expect('1 day byval', 'same as var');
        Observer.Expect('1 day named', 'same as var');
        Observer.Expect('1 day plain var', 'same as var');
        Observer.Expect('1 day plain local', 'same as var');
        Observer.Expect('1 day plain byval', 'same as var');
        Observer.Expect('1 day plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('2h var', 'error Evaluate:Conversion | The value "2 hours" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('2h var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDuration to System.DateTime.');
#endif
        Observer.Expect('2h local', 'same as var');
        Observer.Expect('2h byval', 'same as var');
        Observer.Expect('2h named', 'same as var');
        Observer.Expect('2h plain var', 'same as var');
        Observer.Expect('2h plain local', 'same as var');
        Observer.Expect('2h plain byval', 'same as var');
        Observer.Expect('2h plain named', 'same as var');
        Observer.Verify();
    end;

    [Test]
    procedure BoolField_To_DateTime_Shapes()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "FVC Source";
        RR: RecordRef;
        FR: FieldRef;
    begin
        Rec.DeleteAll();
        RR.GetTable(Rec);
        FR := RR.Field(Rec.FieldNo(BoolF));
        FR.Value := true;
        Shapes(Observer, FR, 'true');
        FR.Value := false;
        Shapes(Observer, FR, 'false');
#if BC28PLUS
        Observer.Expect('true var', 'error Evaluate:Conversion | The value "Yes" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('true var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavBoolean to System.DateTime.');
#endif
        Observer.Expect('true local', 'same as var');
        Observer.Expect('true byval', 'same as var');
        Observer.Expect('true named', 'same as var');
        Observer.Expect('true plain var', 'same as var');
        Observer.Expect('true plain local', 'same as var');
        Observer.Expect('true plain byval', 'same as var');
        Observer.Expect('true plain named', 'same as var');
#if BC28PLUS
        Observer.Expect('false var', 'error Evaluate:Conversion | The value "No" can''t be evaluated into type DateTime.');
#else
        Observer.Expect('false var', 'error Conversion | Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavBoolean to System.DateTime.');
#endif
        Observer.Expect('false local', 'same as var');
        Observer.Expect('false byval', 'same as var');
        Observer.Expect('false named', 'same as var');
        Observer.Expect('false plain var', 'same as var');
        Observer.Expect('false plain local', 'same as var');
        Observer.Expect('false plain byval', 'same as var');
        Observer.Expect('false plain named', 'same as var');
        Observer.Verify();
    end;

    local procedure Shapes(var Observer: Codeunit "Probe Observer"; var FR: FieldRef; Label: Text)
    var
        Base: Text;
        Other: Text;
        Ok: Boolean;
    begin
        Other := '';
        Ok := TryVarParam(FR, Other);
        Base := Outcome(Ok, Other);
        Observer.Observe(Label + ' var', Base);
        Other := '';
        Ok := TryLocal(FR, Other);
        Report(Observer, Label + ' local', Base, Outcome(Ok, Other));
        Other := '';
        Ok := TryByValue(FR, Other);
        Report(Observer, Label + ' byval', Base, Outcome(Ok, Other));
        Other := '';
        Ok := TryNamedReturn(FR, Other);
        Report(Observer, Label + ' named', Base, Outcome(Ok, Other));
        Report(Observer, Label + ' plain var', Base, PlainVar(FR));
        Report(Observer, Label + ' plain local', Base, PlainLocal(FR));
        Report(Observer, Label + ' plain byval', Base, PlainByValue(FR));
        Report(Observer, Label + ' plain named', Base, PlainNamed(FR));
    end;

    local procedure Outcome(Ok: Boolean; Res: Text): Text
    begin
        if Ok then
            exit('ok ' + Res);
        exit('error ' + GetLastErrorCode() + ' | ' + GetLastErrorText());
    end;

    local procedure Report(var Observer: Codeunit "Probe Observer"; Label: Text; Base: Text; Got: Text)
    begin
        if Got = Base then
            Observer.Observe(Label, 'same as var')
        else
            Observer.Observe(Label, Got);
    end;

    [TryFunction]
    local procedure TryVarParam(var FR: FieldRef; var Res: Text)
    var
        P: DateTime;
    begin
        FillVar(FR, P);
        Res := Format(P, 0, 9);
    end;

    local procedure FillVar(var FR: FieldRef; var R: DateTime)
    begin
        R := FR.Value;
    end;

    [TryFunction]
    local procedure TryLocal(var FR: FieldRef; var Res: Text)
    var
        L: DateTime;
    begin
        L := FR.Value;
        Res := Format(L, 0, 9);
    end;

    [TryFunction]
    local procedure TryByValue(var FR: FieldRef; var Res: Text)
    begin
        Res := FillByValue(FR, 0DT);
    end;

    local procedure FillByValue(var FR: FieldRef; R: DateTime): Text
    begin
        R := FR.Value;
        exit(Format(R, 0, 9));
    end;

    [TryFunction]
    local procedure TryNamedReturn(var FR: FieldRef; var Res: Text)
    begin
        Res := Format(NamedReturn(FR), 0, 9);
    end;

    local procedure NamedReturn(var FR: FieldRef) R: DateTime
    begin
        R := FR.Value;
    end;

    local procedure PlainVar(var FR: FieldRef): Text
    var
        P: DateTime;
    begin
        asserterror FillVar(FR, P);
        exit(Outcome(false, ''));
    end;

    local procedure PlainLocal(var FR: FieldRef): Text
    begin
        asserterror PlainLocalBody(FR);
        exit(Outcome(false, ''));
    end;

    local procedure PlainLocalBody(var FR: FieldRef)
    var
        L: DateTime;
    begin
        L := FR.Value;
    end;

    local procedure PlainByValue(var FR: FieldRef): Text
    begin
        asserterror FillByValue(FR, 0DT);
        exit(Outcome(false, ''));
    end;

    local procedure PlainNamed(var FR: FieldRef): Text
    begin
        asserterror NamedReturn(FR);
        exit(Outcome(false, ''));
    end;
}
