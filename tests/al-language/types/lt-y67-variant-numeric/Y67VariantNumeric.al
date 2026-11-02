// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); codeunit 93629 (writer Y67, gap cycle 6 follow-up)
// Probe: a Variant that holds a DEFINED Date (the first valid date, early, 1899/1900 edges, 2000, a leap day, a date in 2026, the last valid
//   date, a closing date), a Time, a DateTime, a Duration, an Integer, a BigInteger, a Decimal, a Boolean or a Text number, assigned to
//   Integer, Decimal, BigInteger, Duration, Text, Date, Time, DateTime and Boolean. Values are Format(.., 0, 9) or error:<text>|<code>.
//   types/lt-y62-undefined-date/Y62UndefinedDate.al pins 0D, 0T, 0DT and 20260115D into the first five targets.
// BC versions: 27, 28, 29

codeunit 93629 "LT Y67 Variant Numeric"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure ToInteger(V: Variant; var Txt: Text)
    var
        T: Integer;
    begin
        T := V;
        Txt := Format(T, 0, 9);
    end;

    [TryFunction]
    local procedure ToDecimal(V: Variant; var Txt: Text)
    var
        T: Decimal;
    begin
        T := V;
        Txt := Format(T, 0, 9);
    end;

    [TryFunction]
    local procedure ToBigInteger(V: Variant; var Txt: Text)
    var
        T: BigInteger;
    begin
        T := V;
        Txt := Format(T, 0, 9);
    end;

    [TryFunction]
    local procedure ToDuration(V: Variant; var Txt: Text)
    var
        T: Duration;
    begin
        T := V;
        Txt := Format(T, 0, 9);
    end;

    [TryFunction]
    local procedure ToText(V: Variant; var Txt: Text)
    var
        T: Text;
    begin
        T := V;
        Txt := T;
    end;

    [TryFunction]
    local procedure ToDate(V: Variant; var Txt: Text)
    var
        T: Date;
    begin
        T := V;
        Txt := Format(T, 0, 9);
    end;

    [TryFunction]
    local procedure ToTime(V: Variant; var Txt: Text)
    var
        T: Time;
    begin
        T := V;
        Txt := Format(T, 0, 9);
    end;

    [TryFunction]
    local procedure ToDateTime(V: Variant; var Txt: Text)
    var
        T: DateTime;
    begin
        T := V;
        Txt := Format(T, 0, 9);
    end;

    [TryFunction]
    local procedure ToBoolean(V: Variant; var Txt: Text)
    var
        T: Boolean;
    begin
        T := V;
        Txt := Format(T, 0, 9);
    end;

    // The runtime namespace prefixes make the texts long; they are written as tags.
    local procedure Short(ErrText: Text): Text
    begin
        ErrText := ErrText.Replace('The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.', '<ind>');
        ErrText := ErrText.Replace('Unable to convert from Microsoft.Dynamics.Nav.Runtime.', '<conv>');
        exit(ErrText);
    end;

    local procedure Targets(V: Variant): Text
    var
        Txt: Text;
        All: Text;
        k: Integer;
        Ok: Boolean;
    begin
        for k := 1 to 9 do begin
            ClearLastError();
            Txt := '';
            case k of
                1:
                    Ok := ToInteger(V, Txt);
                2:
                    Ok := ToDecimal(V, Txt);
                3:
                    Ok := ToBigInteger(V, Txt);
                4:
                    Ok := ToDuration(V, Txt);
                5:
                    Ok := ToText(V, Txt);
                6:
                    Ok := ToDate(V, Txt);
                7:
                    Ok := ToTime(V, Txt);
                8:
                    Ok := ToDateTime(V, Txt);
                9:
                    Ok := ToBoolean(V, Txt);
            end;
            if not Ok then
                Txt := 'error:' + Short(GetLastErrorText()) + '|' + GetLastErrorCode();
            All += Txt + ' ; ';
        end;
        exit(All);
    end;

    local procedure Show(var Observer: Codeunit "Probe Observer"; Name: Text; V: Variant)
    begin
        Observer.Observe(Name, Targets(V));
    end;

    [Test]
    procedure Variant_DefinedDates_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Show(Observer, '17530101D', 17530101D);
        Show(Observer, '17530102D', 17530102D);
        Show(Observer, '18991231D', 18991231D);
        Observer.Expect('17530101D', '1280543 ; 1280543 ; 1280543 ; P0DT0H21M20.543S ; error:<ind>NavText value.|TypeConversion ; 1753-01-01 ; error:<ind>NavTime value.|TypeConversion ; 1753-01-01T00:00:00Z ; true ; ');
        Observer.Expect('17530102D', '1280545 ; 1280545 ; 1280545 ; P0DT0H21M20.545S ; error:<ind>NavText value.|TypeConversion ; 1753-01-02 ; error:<ind>NavTime value.|TypeConversion ; 1753-01-02T00:00:00Z ; true ; ');
        Observer.Expect('18991231D', '1387921 ; 1387921 ; 1387921 ; P0DT0H23M7.921S ; error:<ind>NavText value.|TypeConversion ; 1899-12-31 ; error:<ind>NavTime value.|TypeConversion ; 1899-12-31T00:00:00Z ; true ; ');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_DefinedDates_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Show(Observer, '19000101D', 19000101D);
        Show(Observer, '19991231D', 19991231D);
        Show(Observer, '20000101D', 20000101D);
        Observer.Expect('19000101D', '1387923 ; 1387923 ; 1387923 ; P0DT0H23M7.923S ; error:<ind>NavText value.|TypeConversion ; 1900-01-01 ; error:<ind>NavTime value.|TypeConversion ; 1900-01-01T00:00:00Z ; true ; ');
        Observer.Expect('19991231D', '1460969 ; 1460969 ; 1460969 ; P0DT0H24M20.969S ; error:<ind>NavText value.|TypeConversion ; 1999-12-31 ; error:<ind>NavTime value.|TypeConversion ; 1999-12-31T00:00:00Z ; true ; ');
        Observer.Expect('20000101D', '1460971 ; 1460971 ; 1460971 ; P0DT0H24M20.971S ; error:<ind>NavText value.|TypeConversion ; 2000-01-01 ; error:<ind>NavTime value.|TypeConversion ; 2000-01-01T00:00:00Z ; true ; ');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_DefinedDates_C()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Show(Observer, '20240229D', 20240229D);
        Show(Observer, '20260115D', 20260115D);
        Show(Observer, '20261231D', 20261231D);
        Observer.Expect('20240229D', '1478621 ; 1478621 ; 1478621 ; P0DT0H24M38.621S ; error:<ind>NavText value.|TypeConversion ; 2024-02-29 ; error:<ind>NavTime value.|TypeConversion ; 2024-02-29T00:00:00Z ; true ; ');
        Observer.Expect('20260115D', '1479993 ; 1479993 ; 1479993 ; P0DT0H24M39.993S ; error:<ind>NavText value.|TypeConversion ; 2026-01-15 ; error:<ind>NavTime value.|TypeConversion ; 2026-01-15T00:00:00Z ; true ; ');
        Observer.Expect('20261231D', '1480693 ; 1480693 ; 1480693 ; P0DT0H24M40.693S ; error:<ind>NavText value.|TypeConversion ; 2026-12-31 ; error:<ind>NavTime value.|TypeConversion ; 2026-12-31T00:00:00Z ; true ; ');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_DefinedDates_D()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Show(Observer, '99991231D', 99991231D);
        Show(Observer, 'closing 20260115D', ClosingDate(20260115D));
        Show(Observer, 'closing 17530101D', ClosingDate(17530101D));
        Observer.Expect('99991231D', '7304849 ; 7304849 ; 7304849 ; P0DT2H1M44.849S ; error:<ind>NavText value.|TypeConversion ; 9999-12-31 ; error:<ind>NavTime value.|TypeConversion ; 9999-12-31T00:00:00Z ; true ; ');
        Observer.Expect('closing 20260115D', '1479994 ; 1479994 ; 1479994 ; P0DT0H24M39.994S ; error:<ind>NavText value.|TypeConversion ; 2026-01-15 ; error:<ind>NavTime value.|TypeConversion ; 2026-01-15T23:59:59Z ; true ; ');
        Observer.Expect('closing 17530101D', '1280544 ; 1280544 ; 1280544 ; P0DT0H21M20.544S ; error:<ind>NavText value.|TypeConversion ; 1753-01-01 ; error:<ind>NavTime value.|TypeConversion ; 1753-01-01T23:59:59Z ; true ; ');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_Times_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Show(Observer, '000000T', 000000T);
        Show(Observer, '120000T', 120000T);
        Show(Observer, '235959.999T', 235959.999T);
        Observer.Expect('000000T', '1 ; 1 ; 1 ; P0DT0H0M0.001S ; error:<ind>NavText value.|TypeConversion ; error:<ind>NavDate value.|TypeConversion ; 00:00:00 ; error:<ind>NavDateTime value.|TypeConversion ; true ; ');
        Observer.Expect('120000T', '43200001 ; 43200001 ; 43200001 ; P0DT12H0M0.001S ; error:<ind>NavText value.|TypeConversion ; error:<ind>NavDate value.|TypeConversion ; 12:00:00 ; error:<ind>NavDateTime value.|TypeConversion ; true ; ');
        Observer.Expect('235959.999T', '86400000 ; 86400000 ; 86400000 ; P1DT0H0M0.0S ; error:<ind>NavText value.|TypeConversion ; error:<ind>NavDate value.|TypeConversion ; 23:59:59.999 ; error:<ind>NavDateTime value.|TypeConversion ; true ; ');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_DateTimes_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Show(Observer, 'dt 20260115 120000', CreateDateTime(20260115D, 120000T));
        Show(Observer, 'dt 20000101 000000', CreateDateTime(20000101D, 000000T));
        Show(Observer, 'dt closing', CreateDateTime(ClosingDate(20260115D), 120000T));
        Observer.Expect('dt 20260115 120000', 'error:<conv>NavDateTime to System.Int32.|Conversion ; 63935697600001 ; 63935697600001 ; P739996DT12H0M0.001S ; error:<ind>NavText value.|TypeConversion ; 2026-01-15 ; error:<ind>NavTime value.|TypeConversion ; 2026-01-15T12:00:00Z ; error:<conv>NavDateTime to System.Int32.|Conversion ; ');
        Observer.Expect('dt 20000101 000000', 'error:<conv>NavDateTime to System.Int32.|Conversion ; 63113904000001 ; 63113904000001 ; P730485DT0H0M0.001S ; error:<ind>NavText value.|TypeConversion ; 2000-01-01 ; error:<ind>NavTime value.|TypeConversion ; 2000-01-01T00:00:00Z ; error:<conv>NavDateTime to System.Int32.|Conversion ; ');
        Observer.Expect('dt closing', 'error:<conv>NavDateTime to System.Int32.|Conversion ; 63935783999001 ; 63935783999001 ; P739997DT11H59M59.001S ; error:<ind>NavText value.|TypeConversion ; 2026-01-16 ; error:<ind>NavTime value.|TypeConversion ; 2026-01-16T11:59:59Z ; error:<conv>NavDateTime to System.Int32.|Conversion ; ');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_Numbers_A()
    var
        Observer: Codeunit "Probe Observer";
        Dur: Duration;
        Big: BigInteger;
        Dec: Decimal;
        Int: Integer;
        Flag: Boolean;
        Cd: Code[10];
    begin
        Dur := 1500;
        Evaluate(Big, '5000000000');
        Dec := 2.5;
        Int := -7;
        Flag := true;
        Cd := '12';
        Show(Observer, 'duration 1500', Dur);
        Show(Observer, 'biginteger', Big);
        Show(Observer, 'decimal 2.5', Dec);
        Observer.Expect('duration 1500', '1500 ; 1500 ; 1500 ; P0DT0H0M1.5S ; error:<ind>NavText value.|TypeConversion ; error:<ind>NavDate value.|TypeConversion ; error:<ind>NavTime value.|TypeConversion ; error:<ind>NavDateTime value.|TypeConversion ; true ; ');
        Observer.Expect('biginteger', 'error:The expression Variant cannot be type-converted to a Integer value.|TypeConversion:Overflow ; 5000000000 ; 5000000000 ; P57DT20H53M20.0S ; error:<ind>NavText value.|TypeConversion ; error:<ind>NavDate value.|TypeConversion ; error:<ind>NavTime value.|TypeConversion ; error:<ind>NavDateTime value.|TypeConversion ; error:The expression Variant cannot be type-converted to a Boolean value.|TypeConversion:Overflow ; ');
        Observer.Expect('decimal 2.5', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.|ConversionCast ; 2.5 ; error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int64.|ConversionCast ; error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int64.|ConversionCast ; error:<ind>NavText value.|TypeConversion ; error:<ind>NavDate value.|TypeConversion ; error:<ind>NavTime value.|TypeConversion ; error:<ind>NavDateTime value.|TypeConversion ; error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.|ConversionCast ; ');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_Numbers_B()
    var
        Observer: Codeunit "Probe Observer";
        Dur: Duration;
        Big: BigInteger;
        Dec: Decimal;
        Int: Integer;
        Flag: Boolean;
        Cd: Code[10];
    begin
        Dur := 1500;
        Evaluate(Big, '5000000000');
        Dec := 2.5;
        Int := -7;
        Flag := true;
        Cd := '12';
        Show(Observer, 'integer -7', Int);
        Show(Observer, 'boolean true', Flag);
        Show(Observer, 'code 12', Cd);
        Observer.Expect('integer -7', '-7 ; -7 ; -7 ; -P0DT0H0M0.007S ; error:<ind>NavText value.|TypeConversion ; error:<ind>NavDate value.|TypeConversion ; error:<ind>NavTime value.|TypeConversion ; error:<ind>NavDateTime value.|TypeConversion ; true ; ');
        Observer.Expect('boolean true', '1 ; 1 ; 1 ; P0DT0H0M0.001S ; error:<ind>NavText value.|TypeConversion ; error:<ind>NavDate value.|TypeConversion ; error:<ind>NavTime value.|TypeConversion ; error:<ind>NavDateTime value.|TypeConversion ; true ; ');
        Observer.Expect('code 12', '12 ; 12 ; 12 ; P0DT0H0M0.012S ; 12 ; error:<ind>NavDate value.|TypeConversion ; error:<ind>NavTime value.|TypeConversion ; error:<ind>NavDateTime value.|TypeConversion ; true ; ');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_TextNumbers_A()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Show(Observer, 'text 12', '12');
        Show(Observer, 'text 12.5', '12.5');
        Show(Observer, 'text 20260115', '20260115');
        Observer.Expect('text 12', '12 ; 12 ; 12 ; P0DT0H0M0.012S ; 12 ; error:<ind>NavDate value.|TypeConversion ; error:<ind>NavTime value.|TypeConversion ; error:<ind>NavDateTime value.|TypeConversion ; true ; ');
        Observer.Expect('text 12.5', 'error:The expression Variant cannot be type-converted to a Integer value.|TypeConversion:Format ; 12.5 ; error:The expression Variant cannot be type-converted to a BigInteger value.|TypeConversion:Format ; error:The input string ''12.5'' was not in a correct format.|AL:Format ; 12.5 ; error:<ind>NavDate value.|TypeConversion ; error:<ind>NavTime value.|TypeConversion ; error:<ind>NavDateTime value.|TypeConversion ; error:The expression Variant cannot be type-converted to a Boolean value.|TypeConversion:Format ; ');
        Observer.Expect('text 20260115', '20260115 ; 20260115 ; 20260115 ; P0DT5H37M40.115S ; 20260115 ; error:<ind>NavDate value.|TypeConversion ; error:<ind>NavTime value.|TypeConversion ; error:<ind>NavDateTime value.|TypeConversion ; true ; ');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_TextNumbers_B()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Show(Observer, 'text true', 'true');
        Show(Observer, 'text empty', '');
        Observer.Expect('text true', 'error:The expression Variant cannot be type-converted to a Integer value.|TypeConversion:Format ; error:The expression Variant cannot be type-converted to a Decimal value.|TypeConversion:Format ; error:The expression Variant cannot be type-converted to a BigInteger value.|TypeConversion:Format ; error:The input string ''true'' was not in a correct format.|AL:Format ; true ; error:<ind>NavDate value.|TypeConversion ; error:<ind>NavTime value.|TypeConversion ; error:<ind>NavDateTime value.|TypeConversion ; error:The expression Variant cannot be type-converted to a Boolean value.|TypeConversion:Format ; ');
        Observer.Expect('text empty', 'error:The expression Variant cannot be type-converted to a Integer value.|TypeConversion:Format ; error:The expression Variant cannot be type-converted to a Decimal value.|TypeConversion:Format ; error:The expression Variant cannot be type-converted to a BigInteger value.|TypeConversion:Format ; error:The input string '''' was not in a correct format.|AL:Format ;  ; error:<ind>NavDate value.|TypeConversion ; error:<ind>NavTime value.|TypeConversion ; error:<ind>NavDateTime value.|TypeConversion ; error:The expression Variant cannot be type-converted to a Boolean value.|TypeConversion:Format ; ');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_TextNumbers_C()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Show(Observer, 'text abc', 'abc');
        Observer.Expect('text abc', 'error:The expression Variant cannot be type-converted to a Integer value.|TypeConversion:Format ; error:The expression Variant cannot be type-converted to a Decimal value.|TypeConversion:Format ; error:The expression Variant cannot be type-converted to a BigInteger value.|TypeConversion:Format ; error:The input string ''abc'' was not in a correct format.|AL:Format ; abc ; error:<ind>NavDate value.|TypeConversion ; error:<ind>NavTime value.|TypeConversion ; error:<ind>NavDateTime value.|TypeConversion ; error:The expression Variant cannot be type-converted to a Boolean value.|TypeConversion:Format ; ');
        Observer.Verify();
    end;
}
