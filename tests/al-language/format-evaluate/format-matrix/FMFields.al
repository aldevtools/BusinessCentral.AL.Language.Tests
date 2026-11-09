// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160) and own table 72864
// Probe: matrix of Format (every standard format number 0..10 and a list of format-string elements) and Evaluate (boolean and statement form, format 0 and 9)
//        on FieldRef fields: AutoFormatType and DecimalPlaces (StrSubstNo and Format of a Decimal field), Evaluate into FieldRef of every field type, and Format-then-Evaluate round trips (al-runner 7404, 7471, 7472). Session language 1033 (restored); a de-DE test per type shows what changes under GlobalLanguage 1031.
//        Cell names are the value or text and the format; an error cell is err:<error code>. Generated; Evaluate texts include empty, blanks, out-of-range and trailing D/T.
// BC versions: 27, 28, 29

// local object: the table's own field properties (AutoFormatType, DecimalPlaces, OptionCaption) are under test
table 72864 "LT FM Fields"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Dur; Duration) { }
        field(3; Opt; Option)
        {
            OptionMembers = " ",male,female,nonbinary;
            OptionCaption = ' ,male,female,non-binary';
        }
        field(4; DecAf2; Decimal) { AutoFormatType = 2; }
        field(5; DecPlaces; Decimal) { DecimalPlaces = 0 : 5; }
        field(6; DecAf2Places; Decimal) { AutoFormatType = 2; DecimalPlaces = 0 : 5; }
        field(7; DecAf1; Decimal) { AutoFormatType = 1; }
        field(8; DecAf1Places; Decimal) { AutoFormatType = 1; DecimalPlaces = 0 : 5; }
        field(9; DecAf2Expr; Decimal) { AutoFormatType = 2; AutoFormatExpression = ''; DecimalPlaces = 2 : 2; }
        field(10; Dt; Date) { }
        field(11; Tm; Time) { }
        field(12; DtTm; DateTime) { }
        field(13; Bool; Boolean) { }
        field(14; Big; BigInteger) { }
        field(15; Gd; Guid) { }
        field(16; Dec; Decimal) { }
        field(17; Int; Integer) { }
        field(18; Cd; Code[10]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 72865 "LT FM Fields Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Nul(): Text
    var
        C: Char;
        T: Text;
    begin
        C := 0;
        T := '';
        T += C;
        exit(T);
    end;
    local procedure Tab(): Text
    var
        C: Char;
        T: Text;
    begin
        C := 9;
        T += C;
        exit(T);
    end;

    [TryFunction]
    local procedure TryEvF(var F: FieldRef; Txt: Text)
    begin
        Evaluate(F, Txt);
    end;

    local procedure EvF(var O: Codeunit "Probe Observer"; Name: Text; FieldNo: Integer; Txt: Text)
    var
        R: Record "LT FM Fields";
        RecRef: RecordRef;
        F: FieldRef;
    begin
        RecRef.GetTable(R);
        F := RecRef.Field(FieldNo);
        ClearLastError();
        if TryEvF(F, Txt) then
            O.Observe(Name, 'ok|' + Format(F.Value, 0, 9) + '|' + Format(F.Value))
        else
            O.Observe(Name, 'err:' + GetLastErrorCode() + '|' + Format(F.Value, 0, 9));
    end;

    local procedure Roundtrip(var O: Codeunit "Probe Observer"; Name: Text; FieldNo: Integer; Value: Variant)
    var
        R: Record "LT FM Fields";
        RecRef: RecordRef;
        F: FieldRef;
        Txt: Text;
    begin
        RecRef.GetTable(R);
        F := RecRef.Field(FieldNo);
        F.Value := Value;
        Txt := Format(F.Value);
        Clear(R);
        RecRef.GetTable(R);
        F := RecRef.Field(FieldNo);
        ClearLastError();
        if TryEvF(F, Txt) then
            O.Observe(Name, 'text=' + Txt + '|back=' + Format(F.Value, 0, 9))
        else
            O.Observe(Name, 'text=' + Txt + '|err:' + GetLastErrorCode());
    end;

    local procedure AfCell(var O: Codeunit "Probe Observer"; Name: Text; FieldNo: Integer; Value: Decimal)
    var
        R: Record "LT FM Fields";
        RecRef: RecordRef;
        F: FieldRef;
    begin
        RecRef.GetTable(R);
        F := RecRef.Field(FieldNo);
        F.Value := Value;
        RecRef.SetTable(R);
        case FieldNo of
            4:
                O.Observe(Name, StrSubstNo('%1', R.DecAf2) + '|' + Format(R.DecAf2));
            5:
                O.Observe(Name, StrSubstNo('%1', R.DecPlaces) + '|' + Format(R.DecPlaces));
            6:
                O.Observe(Name, StrSubstNo('%1', R.DecAf2Places) + '|' + Format(R.DecAf2Places));
            7:
                O.Observe(Name, StrSubstNo('%1', R.DecAf1) + '|' + Format(R.DecAf1));
            8:
                O.Observe(Name, StrSubstNo('%1', R.DecAf1Places) + '|' + Format(R.DecAf1Places));
            9:
                O.Observe(Name, StrSubstNo('%1', R.DecAf2Expr) + '|' + Format(R.DecAf2Expr));
        end;
    end;

    [Test]
    procedure StrSubstNo_Format_DecimalField_DecAf2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        AfCell(O, 'DecAf2_0', 4, 0);
        AfCell(O, 'DecAf2_1234_5', 4, 1234.5);
        AfCell(O, 'DecAf2_1234567_891234', 4, 1234567.891234);
        AfCell(O, 'DecAf2_0_000001', 4, 0.000001);
        AfCell(O, 'DecAf2_neg0_5', 4, -0.5);
        AfCell(O, 'DecAf2_100', 4, 100);
        AfCell(O, 'DecAf2_0_123456789', 4, 0.123456789);
        GlobalLanguage(Saved);
        O.Expect('DecAf2_0', '0.00|0.00');
        O.Expect('DecAf2_1234_5', '1,234.50|1,234.50');
        O.Expect('DecAf2_1234567_891234', '1,234,567.89123|1,234,567.89123');
        O.Expect('DecAf2_0_000001', '0.00|0.00');
        O.Expect('DecAf2_neg0_5', '-0.50|-0.50');
        O.Expect('DecAf2_100', '100.00|100.00');
        O.Expect('DecAf2_0_123456789', '0.12346|0.12346');
        O.Verify();
    end;

    [Test]
    procedure StrSubstNo_Format_DecimalField_DecPlaces()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        AfCell(O, 'DecPlaces_0', 5, 0);
        AfCell(O, 'DecPlaces_1234_5', 5, 1234.5);
        AfCell(O, 'DecPlaces_1234567_891234', 5, 1234567.891234);
        AfCell(O, 'DecPlaces_0_000001', 5, 0.000001);
        AfCell(O, 'DecPlaces_neg0_5', 5, -0.5);
        AfCell(O, 'DecPlaces_100', 5, 100);
        AfCell(O, 'DecPlaces_0_123456789', 5, 0.123456789);
        GlobalLanguage(Saved);
        O.Expect('DecPlaces_0', '0|0');
        O.Expect('DecPlaces_1234_5', '1,234.5|1,234.5');
        O.Expect('DecPlaces_1234567_891234', '1,234,567.89123|1,234,567.89123');
        O.Expect('DecPlaces_0_000001', '0|0');
        O.Expect('DecPlaces_neg0_5', '-0.5|-0.5');
        O.Expect('DecPlaces_100', '100|100');
        O.Expect('DecPlaces_0_123456789', '0.12346|0.12346');
        O.Verify();
    end;

    [Test]
    procedure StrSubstNo_Format_DecimalField_DecAf2Places()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        AfCell(O, 'DecAf2Places_0', 6, 0);
        AfCell(O, 'DecAf2Places_1234_5', 6, 1234.5);
        AfCell(O, 'DecAf2Places_1234567_891234', 6, 1234567.891234);
        AfCell(O, 'DecAf2Places_0_000001', 6, 0.000001);
        AfCell(O, 'DecAf2Places_neg0_5', 6, -0.5);
        AfCell(O, 'DecAf2Places_100', 6, 100);
        AfCell(O, 'DecAf2Places_0_123456789', 6, 0.123456789);
        GlobalLanguage(Saved);
        O.Expect('DecAf2Places_0', '0.00|0.00');
        O.Expect('DecAf2Places_1234_5', '1,234.50|1,234.50');
        O.Expect('DecAf2Places_1234567_891234', '1,234,567.89123|1,234,567.89123');
        O.Expect('DecAf2Places_0_000001', '0.00|0.00');
        O.Expect('DecAf2Places_neg0_5', '-0.50|-0.50');
        O.Expect('DecAf2Places_100', '100.00|100.00');
        O.Expect('DecAf2Places_0_123456789', '0.12346|0.12346');
        O.Verify();
    end;

    [Test]
    procedure StrSubstNo_Format_DecimalField_DecAf1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        AfCell(O, 'DecAf1_0', 7, 0);
        AfCell(O, 'DecAf1_1234_5', 7, 1234.5);
        AfCell(O, 'DecAf1_1234567_891234', 7, 1234567.891234);
        AfCell(O, 'DecAf1_0_000001', 7, 0.000001);
        AfCell(O, 'DecAf1_neg0_5', 7, -0.5);
        AfCell(O, 'DecAf1_100', 7, 100);
        AfCell(O, 'DecAf1_0_123456789', 7, 0.123456789);
        GlobalLanguage(Saved);
        // A field with AutoFormatType = 1: BC 28.5 and 29.0 format the value with two decimals,
        // BC 27.5 formats the value as it is (CI subset runs 42636879122, 42636918830, 42636961473).
#if BC28PLUS
        O.Expect('DecAf1_0', '0.00|0.00');
        O.Expect('DecAf1_1234_5', '1,234.50|1,234.50');
        O.Expect('DecAf1_1234567_891234', '1,234,567.89|1,234,567.89');
        O.Expect('DecAf1_0_000001', '0.00|0.00');
        O.Expect('DecAf1_neg0_5', '-0.50|-0.50');
        O.Expect('DecAf1_100', '100.00|100.00');
        O.Expect('DecAf1_0_123456789', '0.12|0.12');
#else
        O.Expect('DecAf1_0', '0|0');
        O.Expect('DecAf1_1234_5', '1,234.5|1,234.5');
        O.Expect('DecAf1_1234567_891234', '1,234,567.891234|1,234,567.891234');
        O.Expect('DecAf1_0_000001', '0.000001|0.000001');
        O.Expect('DecAf1_neg0_5', '-0.5|-0.5');
        O.Expect('DecAf1_100', '100|100');
        O.Expect('DecAf1_0_123456789', '0.123456789|0.123456789');
#endif
        O.Verify();
    end;

    [Test]
    procedure StrSubstNo_Format_DecimalField_DecAf1Places()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        AfCell(O, 'DecAf1Places_0', 8, 0);
        AfCell(O, 'DecAf1Places_1234_5', 8, 1234.5);
        AfCell(O, 'DecAf1Places_1234567_891234', 8, 1234567.891234);
        AfCell(O, 'DecAf1Places_0_000001', 8, 0.000001);
        AfCell(O, 'DecAf1Places_neg0_5', 8, -0.5);
        AfCell(O, 'DecAf1Places_100', 8, 100);
        AfCell(O, 'DecAf1Places_0_123456789', 8, 0.123456789);
        GlobalLanguage(Saved);
        // A field with AutoFormatType = 1: BC 28.5 and 29.0 format the value with two decimals,
        // BC 27.5 formats the value as it is (CI subset runs 42636879122, 42636918830, 42636961473).
#if BC28PLUS
        O.Expect('DecAf1Places_0', '0.00|0.00');
        O.Expect('DecAf1Places_1234_5', '1,234.50|1,234.50');
        O.Expect('DecAf1Places_1234567_891234', '1,234,567.89|1,234,567.89');
        O.Expect('DecAf1Places_0_000001', '0.00|0.00');
        O.Expect('DecAf1Places_neg0_5', '-0.50|-0.50');
        O.Expect('DecAf1Places_100', '100.00|100.00');
        O.Expect('DecAf1Places_0_123456789', '0.12|0.12');
#else
        O.Expect('DecAf1Places_0', '0|0');
        O.Expect('DecAf1Places_1234_5', '1,234.5|1,234.5');
        O.Expect('DecAf1Places_1234567_891234', '1,234,567.891234|1,234,567.891234');
        O.Expect('DecAf1Places_0_000001', '0.000001|0.000001');
        O.Expect('DecAf1Places_neg0_5', '-0.5|-0.5');
        O.Expect('DecAf1Places_100', '100|100');
        O.Expect('DecAf1Places_0_123456789', '0.123456789|0.123456789');
#endif
        O.Verify();
    end;

    [Test]
    procedure StrSubstNo_Format_DecimalField_DecAf2Expr()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        AfCell(O, 'DecAf2Expr_0', 9, 0);
        AfCell(O, 'DecAf2Expr_1234_5', 9, 1234.5);
        AfCell(O, 'DecAf2Expr_1234567_891234', 9, 1234567.891234);
        AfCell(O, 'DecAf2Expr_0_000001', 9, 0.000001);
        AfCell(O, 'DecAf2Expr_neg0_5', 9, -0.5);
        AfCell(O, 'DecAf2Expr_100', 9, 100);
        AfCell(O, 'DecAf2Expr_0_123456789', 9, 0.123456789);
        GlobalLanguage(Saved);
        O.Expect('DecAf2Expr_0', '0.00|0.00');
        O.Expect('DecAf2Expr_1234_5', '1,234.50|1,234.50');
        O.Expect('DecAf2Expr_1234567_891234', '1,234,567.89123|1,234,567.89123');
        O.Expect('DecAf2Expr_0_000001', '0.00|0.00');
        O.Expect('DecAf2Expr_neg0_5', '-0.50|-0.50');
        O.Expect('DecAf2Expr_100', '100.00|100.00');
        O.Expect('DecAf2Expr_0_123456789', '0.12346|0.12346');
        O.Verify();
    end;

    [Test]
    procedure StrSubstNo_Format_DecimalField_DecAf2Places_de()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        AfCell(O, 'DecAf2Places_0', 6, 0);
        AfCell(O, 'DecAf2Places_1234_5', 6, 1234.5);
        AfCell(O, 'DecAf2Places_1234567_891234', 6, 1234567.891234);
        AfCell(O, 'DecAf2Places_0_000001', 6, 0.000001);
        GlobalLanguage(Saved);
        O.Expect('DecAf2Places_0', '0.00|0.00');
        O.Expect('DecAf2Places_1234_5', '1,234.50|1,234.50');
        O.Expect('DecAf2Places_1234567_891234', '1,234,567.89123|1,234,567.89123');
        O.Expect('DecAf2Places_0_000001', '0.00|0.00');
        O.Verify();
    end;

    [Test]
    procedure StrSubstNo_Format_DecimalField_DecPlaces_de()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        AfCell(O, 'DecPlaces_0', 5, 0);
        AfCell(O, 'DecPlaces_1234_5', 5, 1234.5);
        AfCell(O, 'DecPlaces_1234567_891234', 5, 1234567.891234);
        AfCell(O, 'DecPlaces_0_000001', 5, 0.000001);
        GlobalLanguage(Saved);
        O.Expect('DecPlaces_0', '0|0');
        O.Expect('DecPlaces_1234_5', '1,234.5|1,234.5');
        O.Expect('DecPlaces_1234567_891234', '1,234,567.89123|1,234,567.89123');
        O.Expect('DecPlaces_0_000001', '0|0');
        O.Verify();
    end;

    [Test]
    procedure FieldRef_Evaluate_Duration_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvF(O, 'empty', 2, '');
        EvF(O, 'blank', 2, ' ');
        EvF(O, '0', 2, '0');
        EvF(O, '1', 2, '1');
        EvF(O, '-1', 2, '-1');
        EvF(O, '1000', 2, '1000');
        EvF(O, '90061001', 2, '90061001');
        EvF(O, '1 millisecond', 2, '1 millisecond');
        EvF(O, '-1 millisecond', 2, '-1 millisecond');
        EvF(O, '1 milliseconds', 2, '1 milliseconds');
        EvF(O, '1 second', 2, '1 second');
        EvF(O, '2 seconds', 2, '2 seconds');
        EvF(O, '1 minute', 2, '1 minute');
        EvF(O, '1 hour', 2, '1 hour');
        EvF(O, '1 day', 2, '1 day');
        EvF(O, '2 days', 2, '2 days');
        EvF(O, '1 day 2 hours', 2, '1 day 2 hours');
        EvF(O, '1 day 2 hours 3 minutes 4 seconds 5 milliseconds', 2, '1 day 2 hours 3 minutes 4 seconds 5 milliseconds');
        EvF(O, '-1 day 2 hours', 2, '-1 day 2 hours');
        EvF(O, '1.5 seconds', 2, '1.5 seconds');
        EvF(O, '1h', 2, '1h');
        EvF(O, '1h 2m', 2, '1h 2m');
        EvF(O, '1s', 2, '1s');
        EvF(O, '1 ms', 2, '1 ms');
        EvF(O, '1 sec', 2, '1 sec');
        EvF(O, '1 min', 2, '1 min');
        EvF(O, '1 Second', 2, '1 Second');
        EvF(O, 'abc', 2, 'abc');
        EvF(O, '1D', 2, '1D');
        GlobalLanguage(Saved);
        O.Expect('empty', 'ok|P0DT0H0M0.0S|');
        O.Expect('blank', 'ok|P0DT0H0M0.0S|');
        O.Expect('0', 'ok|P0DT0H0M0.0S|');
        O.Expect('1', 'ok|P0DT1H0M0.0S|1 hour');
        O.Expect('-1', 'ok|-P0DT1H0M0.0S|-1 hour');
        O.Expect('1000', 'ok|P41DT16H0M0.0S|41 days 16 hours');
        O.Expect('90061001', 'ok|P3752541DT17H0M0.0S|3752541 days 17 hours');
        O.Expect('1 millisecond', 'ok|P0DT0H0M0.001S|1 millisecond');
        O.Expect('-1 millisecond', 'ok|-P0DT0H0M0.001S|-1 millisecond');
        O.Expect('1 milliseconds', 'ok|P0DT0H0M0.001S|1 millisecond');
        O.Expect('1 second', 'ok|P0DT0H0M1.0S|1 second');
        O.Expect('2 seconds', 'ok|P0DT0H0M2.0S|2 seconds');
        O.Expect('1 minute', 'ok|P0DT0H1M0.0S|1 minute');
        O.Expect('1 hour', 'ok|P0DT1H0M0.0S|1 hour');
        O.Expect('1 day', 'ok|P1DT0H0M0.0S|1 day');
        O.Expect('2 days', 'ok|P2DT0H0M0.0S|2 days');
        O.Expect('1 day 2 hours', 'ok|P1DT2H0M0.0S|1 day 2 hours');
        O.Expect('1 day 2 hours 3 minutes 4 seconds 5 milliseconds', 'ok|P1DT2H3M4.005S|1 day 2 hours 3 minutes 4 seconds 5 milliseconds');
        O.Expect('-1 day 2 hours', 'ok|-P1DT2H0M0.0S|-1 day 2 hours');
        O.Expect('1.5 seconds', 'ok|P0DT0H0M1.5S|1 second 500 milliseconds');
        O.Expect('1h', 'ok|P0DT1H0M0.0S|1 hour');
        O.Expect('1h 2m', 'ok|P0DT1H2M0.0S|1 hour 2 minutes');
        O.Expect('1s', 'ok|P0DT0H0M1.0S|1 second');
        O.Expect('1 ms', 'err:Evaluate|P0DT0H0M0.0S');
        O.Expect('1 sec', 'ok|P0DT0H0M1.0S|1 second');
        O.Expect('1 min', 'ok|P0DT0H1M0.0S|1 minute');
        O.Expect('1 Second', 'ok|P0DT0H0M1.0S|1 second');
        O.Expect('abc', 'err:Evaluate|P0DT0H0M0.0S');
        O.Expect('1D', 'ok|P1DT0H0M0.0S|1 day');
        O.Verify();
    end;

    [Test]
    procedure FieldRef_Evaluate_Duration_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvF(O, '1T', 2, '1T');
        EvF(O, 'NUL', 2, Nul());
        EvF(O, '?', 2, '?');
        EvF(O, 'P1DT2H', 2, 'P1DT2H');
        EvF(O, 'PT1.5S', 2, 'PT1.5S');
        EvF(O, '0 milliseconds', 2, '0 milliseconds');
        EvF(O, '9223372036854775807', 2, '9223372036854775807');
        EvF(O, '9223372036854775808', 2, '9223372036854775808');
        EvF(O, '999999999999 days', 2, '999999999999 days');
        GlobalLanguage(Saved);
        O.Expect('1T', 'err:Evaluate|P0DT0H0M0.0S');
        O.Expect('NUL', 'err:Evaluate|P0DT0H0M0.0S');
        O.Expect('?', 'err:Evaluate|P0DT0H0M0.0S');
        O.Expect('P1DT2H', 'err:Evaluate|P0DT0H0M0.0S');
        O.Expect('PT1.5S', 'err:Evaluate|P0DT0H0M0.0S');
        O.Expect('0 milliseconds', 'ok|P0DT0H0M0.0S|');
        O.Expect('9223372036854775807', 'err:Evaluate|P0DT0H0M0.0S');
        O.Expect('9223372036854775808', 'err:Evaluate|P0DT0H0M0.0S');
        O.Expect('999999999999 days', 'err:Evaluate|P0DT0H0M0.0S');
        O.Verify();
    end;

    [Test]
    procedure FieldRef_Evaluate_Option_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvF(O, '', 3, '');
        EvF(O, ' ', 3, ' ');
        EvF(O, 'Draft', 3, 'Draft');
        EvF(O, 'draft', 3, 'draft');
        EvF(O, 'DRAFT', 3, 'DRAFT');
        EvF(O, 'Active', 3, 'Active');
        EvF(O, 'Closed', 3, 'Closed');
        EvF(O, '1', 3, '1');
        EvF(O, '2', 3, '2');
        EvF(O, '3', 3, '3');
        EvF(O, '0', 3, '0');
        EvF(O, '4', 3, '4');
        EvF(O, '-1', 3, '-1');
        EvF(O, 'abc', 3, 'abc');
        EvF(O, 'test123', 3, 'test123');
        EvF(O, 'Draft ', 3, 'Draft ');
        EvF(O, ' Draft', 3, ' Draft');
        EvF(O, ',', 3, ',');
        EvF(O, 'Dra', 3, 'Dra');
        EvF(O, 'Draft,Active', 3, 'Draft,Active');
        EvF(O, '1D', 3, '1D');
        EvF(O, '1T', 3, '1T');
        EvF(O, 'male', 3, 'male');
        EvF(O, 'non-binary', 3, 'non-binary');
        EvF(O, 'nonbinary', 3, 'nonbinary');
        EvF(O, 'NUL', 3, Nul());
        EvF(O, '?', 3, '?');
        GlobalLanguage(Saved);
        O.Expect('', 'ok|0| ');
        O.Expect(' ', 'ok|0| ');
        O.Expect('Draft', 'err:InvalidOptionString|0');
        O.Expect('draft', 'err:InvalidOptionString|0');
        O.Expect('DRAFT', 'err:InvalidOptionString|0');
        O.Expect('Active', 'err:InvalidOptionString|0');
        O.Expect('Closed', 'err:InvalidOptionString|0');
        O.Expect('1', 'ok|1|male');
        O.Expect('2', 'ok|2|female');
        O.Expect('3', 'ok|3|non-binary');
        O.Expect('0', 'ok|0| ');
        O.Expect('4', 'ok|4|4');
        O.Expect('-1', 'err:InvalidOptionString|0');
        O.Expect('abc', 'err:InvalidOptionString|0');
        O.Expect('test123', 'err:InvalidOptionString|0');
        O.Expect('Draft ', 'err:InvalidOptionString|0');
        O.Expect(' Draft', 'err:InvalidOptionString|0');
        O.Expect(',', 'err:InvalidOptionString|0');
        O.Expect('Dra', 'err:InvalidOptionString|0');
        O.Expect('Draft,Active', 'err:InvalidOptionString|0');
        O.Expect('1D', 'err:InvalidOptionString|0');
        O.Expect('1T', 'err:InvalidOptionString|0');
        O.Expect('male', 'ok|1|male');
        O.Expect('non-binary', 'ok|3|non-binary');
        O.Expect('nonbinary', 'ok|3|non-binary');
        O.Expect('NUL', 'ok|0| ');
        O.Expect('?', 'err:InvalidOptionString|0');
        O.Verify();
    end;

    [Test]
    procedure FieldRef_Evaluate_Date_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvF(O, 'empty', 10, '');
        EvF(O, 'blank', 10, ' ');
        EvF(O, '0D', 10, '0D');
        EvF(O, 'D', 10, 'D');
        EvF(O, 'T', 10, 'T');
        EvF(O, '12/09/26', 10, '12/09/26');
        EvF(O, '12/09/26D', 10, '12/09/26D');
        EvF(O, '12/09/26T', 10, '12/09/26T');
        EvF(O, '12/09/2026D', 10, '12/09/2026D');
        EvF(O, '12.09.26D', 10, '12.09.26D');
        EvF(O, '12/09/26 D', 10, '12/09/26 D');
        EvF(O, '32/01/26', 10, '32/01/26');
        EvF(O, '02/30/26', 10, '02/30/26');
        EvF(O, '00/00/00', 10, '00/00/00');
        EvF(O, '13/01/26', 10, '13/01/26');
        EvF(O, '01/13/26', 10, '01/13/26');
        EvF(O, '1/1/1753', 10, '1/1/1753');
        EvF(O, '12/31/9999', 10, '12/31/9999');
        EvF(O, '1/1/0001', 10, '1/1/0001');
        EvF(O, '12/31/10000', 10, '12/31/10000');
        EvF(O, 'abc', 10, 'abc');
        EvF(O, '<=11/09/26', 10, '<=11/09/26');
        EvF(O, '>=11/09/26', 10, '>=11/09/26');
        EvF(O, '11/09/26..12/09/26', 10, '11/09/26..12/09/26');
        EvF(O, '%today', 10, '%today');
        EvF(O, 'W', 10, 'W');
        EvF(O, '1D', 10, '1D');
        EvF(O, 'CM', 10, 'CM');
        EvF(O, '12-09-26', 10, '12-09-26');
        GlobalLanguage(Saved);
        O.Expect('empty', 'ok||');
        O.Expect('blank', 'ok||');
        O.Expect('0D', 'err:Evaluate|');
        O.Ignore('D'); // depends on today's date or the current time: observed, not asserted
        O.Ignore('T'); // depends on today's date or the current time: observed, not asserted
        O.Expect('12/09/26', 'ok|2026-12-09|12/09/26');
        O.Expect('12/09/26D', 'ok|2026-12-09|12/09/26');
        O.Expect('12/09/26T', 'ok|2026-12-09|12/09/26');
        O.Expect('12/09/2026D', 'ok|2026-12-09|12/09/26');
        O.Expect('12.09.26D', 'ok|2026-12-09|12/09/26');
        O.Expect('12/09/26 D', 'ok|2026-12-09|12/09/26');
        O.Expect('32/01/26', 'err:Evaluate|');
        O.Expect('02/30/26', 'err:Evaluate|');
        O.Expect('00/00/00', 'err:Evaluate|');
        O.Expect('13/01/26', 'err:Evaluate|');
        O.Expect('01/13/26', 'ok|2026-01-13|01/13/26');
        O.Expect('1/1/1753', 'ok|1753-01-01|01/01/1753');
        O.Expect('12/31/9999', 'ok|9999-12-31|12/31/9999');
        O.Expect('1/1/0001', 'ok||');
        O.Expect('12/31/10000', 'err:Evaluate|');
        O.Expect('abc', 'err:Evaluate|');
        O.Expect('<=11/09/26', 'err:Evaluate|');
        O.Expect('>=11/09/26', 'err:Evaluate|');
        O.Expect('11/09/26..12/09/26', 'ok|2026-11-09|11/09/26');
        O.Expect('%today', 'err:Evaluate|');
        O.Ignore('W'); // depends on today's date or the current time: observed, not asserted
        O.Ignore('1D'); // depends on today's date or the current time: observed, not asserted
        O.Expect('CM', 'err:Evaluate|');
        O.Expect('12-09-26', 'ok|2026-12-09|12/09/26');
        O.Verify();
    end;

    [Test]
    procedure FieldRef_Evaluate_Date_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvF(O, '2026-12-09', 10, '2026-12-09');
        EvF(O, '20261209', 10, '20261209');
        EvF(O, '121226', 10, '121226');
        EvF(O, '12/09', 10, '12/09');
        EvF(O, '12', 10, '12');
        EvF(O, 'NUL', 10, Nul());
        EvF(O, '?', 10, '?');
        EvF(O, 'Monday', 10, 'Monday');
        EvF(O, '9 Mar 2026', 10, '9 Mar 2026');
        EvF(O, 'March 9, 2026', 10, 'March 9, 2026');
        EvF(O, '12/09/26 12:00', 10, '12/09/26 12:00');
        GlobalLanguage(Saved);
        O.Expect('2026-12-09', 'ok|2026-12-09|12/09/26');
        O.Expect('20261209', 'err:Evaluate|');
        O.Expect('121226', 'ok|2026-12-12|12/12/26');
        O.Ignore('12/09'); // depends on today's date or the current time: observed, not asserted
        O.Ignore('12'); // depends on today's date or the current time: observed, not asserted
        O.Expect('NUL', 'err:Evaluate|');
        O.Expect('?', 'err:Evaluate|');
        O.Ignore('Monday'); // depends on today's date or the current time: observed, not asserted
        O.Expect('9 Mar 2026', 'ok|2026-09-20|09/20/26');
        O.Expect('March 9, 2026', 'err:Evaluate|');
        O.Expect('12/09/26 12:00', 'ok|2026-12-09|12/09/26');
        O.Verify();
    end;

    [Test]
    procedure FieldRef_Evaluate_Time_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvF(O, 'empty', 11, '');
        EvF(O, 'blank', 11, ' ');
        EvF(O, '12:00:00', 11, '12:00:00');
        EvF(O, '12:00', 11, '12:00');
        EvF(O, '12:00 AM', 11, '12:00 AM');
        EvF(O, '12:00 PM', 11, '12:00 PM');
        EvF(O, '12:00:00 AM', 11, '12:00:00 AM');
        EvF(O, '1:05 pm', 11, '1:05 pm');
        EvF(O, '0:00', 11, '0:00');
        EvF(O, '24:00:00', 11, '24:00:00');
        EvF(O, '25:00:00', 11, '25:00:00');
        EvF(O, '12:60:00', 11, '12:60:00');
        EvF(O, '12:00:60', 11, '12:00:60');
        EvF(O, '12:00:00.123', 11, '12:00:00.123');
        EvF(O, '12:00:00.1234', 11, '12:00:00.1234');
        EvF(O, '12:00:00,123', 11, '12:00:00,123');
        EvF(O, 'T', 11, 'T');
        EvF(O, '0T', 11, '0T');
        EvF(O, '12:00:00T', 11, '12:00:00T');
        EvF(O, '12:00:00D', 11, '12:00:00D');
        EvF(O, '1200', 11, '1200');
        EvF(O, '120000', 11, '120000');
        EvF(O, 'abc', 11, 'abc');
        EvF(O, '-1:00', 11, '-1:00');
        EvF(O, '12.00.00', 11, '12.00.00');
        EvF(O, '12:00:00 ', 11, '12:00:00 ');
        EvF(O, ' 12:00:00', 11, ' 12:00:00');
        EvF(O, 'NUL', 11, Nul());
        EvF(O, '?', 11, '?');
        GlobalLanguage(Saved);
        O.Expect('empty', 'ok||');
        O.Expect('blank', 'ok||');
        O.Expect('12:00:00', 'ok|12:00:00|12:00:00 PM');
        O.Expect('12:00', 'ok|12:00:00|12:00:00 PM');
        O.Expect('12:00 AM', 'ok|00:00:00|12:00:00 AM');
        O.Expect('12:00 PM', 'ok|12:00:00|12:00:00 PM');
        O.Expect('12:00:00 AM', 'ok|00:00:00|12:00:00 AM');
        O.Expect('1:05 pm', 'ok|13:05:00| 1:05:00 PM');
        O.Expect('0:00', 'ok|00:00:00|12:00:00 AM');
        O.Expect('24:00:00', 'err:Evaluate|');
        O.Expect('25:00:00', 'err:Evaluate|');
        O.Expect('12:60:00', 'err:Evaluate|');
        O.Expect('12:00:60', 'err:Evaluate|');
        O.Expect('12:00:00.123', 'ok|12:00:00.123|12:00:00 PM');
        O.Expect('12:00:00.1234', 'err:Evaluate|');
        O.Expect('12:00:00,123', 'ok|12:00:00.123|12:00:00 PM');
        O.Ignore('T'); // depends on today's date or the current time: observed, not asserted
        O.Expect('0T', 'err:Evaluate|');
        O.Expect('12:00:00T', 'err:Evaluate|');
        O.Expect('12:00:00D', 'err:Evaluate|');
        O.Expect('1200', 'ok|12:00:00|12:00:00 PM');
        O.Expect('120000', 'ok|12:00:00|12:00:00 PM');
        O.Expect('abc', 'err:Evaluate|');
        O.Expect('-1:00', 'err:Evaluate|');
        O.Expect('12.00.00', 'ok|12:00:00|12:00:00 PM');
        O.Expect('12:00:00 ', 'ok|12:00:00|12:00:00 PM');
        O.Expect(' 12:00:00', 'ok|12:00:00|12:00:00 PM');
        O.Expect('NUL', 'err:Evaluate|');
        O.Expect('?', 'err:Evaluate|');
        O.Verify();
    end;

    [Test]
    procedure FieldRef_Evaluate_Time_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvF(O, '12', 11, '12');
        EvF(O, '12:', 11, '12:');
        EvF(O, ':30', 11, ':30');
        EvF(O, '1:2:3', 11, '1:2:3');
        EvF(O, '11:59:59.999 PM', 11, '11:59:59.999 PM');
        GlobalLanguage(Saved);
        O.Expect('12', 'ok|12:00:00|12:00:00 PM');
        O.Expect('12:', 'err:Evaluate|');
        O.Expect(':30', 'err:Evaluate|');
        O.Expect('1:2:3', 'ok|01:02:03| 1:02:03 AM');
        O.Expect('11:59:59.999 PM', 'ok|23:59:59.999|11:59:59 PM');
        O.Verify();
    end;

    [Test]
    procedure FieldRef_Evaluate_DateTime_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvF(O, 'empty', 12, '');
        EvF(O, 'blank', 12, ' ');
        EvF(O, '0DT', 12, '0DT');
        EvF(O, 'T', 12, 'T');
        EvF(O, 'D', 12, 'D');
        EvF(O, '01/01/26', 12, '01/01/26');
        EvF(O, '01/01/23', 12, '01/01/23');
        EvF(O, '11/01/26', 12, '11/01/26');
        EvF(O, '01/01/2026', 12, '01/01/2026');
        EvF(O, '01/01/26D', 12, '01/01/26D');
        EvF(O, '01/01/26T', 12, '01/01/26T');
        EvF(O, '01/01/26 12:00', 12, '01/01/26 12:00');
        EvF(O, '01/01/26 12:00:00', 12, '01/01/26 12:00:00');
        EvF(O, '01/01/26 12:00:00 AM', 12, '01/01/26 12:00:00 AM');
        EvF(O, '01/01/26 12:00 PM', 12, '01/01/26 12:00 PM');
        EvF(O, '01/01/26 12:00:00T', 12, '01/01/26 12:00:00T');
        EvF(O, '01/01/26 24:00', 12, '01/01/26 24:00');
        EvF(O, '01/01/26 25:00', 12, '01/01/26 25:00');
        EvF(O, '01/01/26 12:60', 12, '01/01/26 12:60');
        EvF(O, '01/01/26 12:00:00.123', 12, '01/01/26 12:00:00.123');
        EvF(O, '13/01/26 12:00', 12, '13/01/26 12:00');
        EvF(O, '02/30/26 12:00', 12, '02/30/26 12:00');
        EvF(O, '12:00:00', 12, '12:00:00');
        EvF(O, '12:00 AM', 12, '12:00 AM');
        EvF(O, '2026-01-01', 12, '2026-01-01');
        EvF(O, '2026-01-01T12:00:00', 12, '2026-01-01T12:00:00');
        EvF(O, '2026-01-01T12:00:00Z', 12, '2026-01-01T12:00:00Z');
        GlobalLanguage(Saved);
        O.Expect('empty', 'ok||');
        O.Expect('blank', 'ok||');
        O.Expect('0DT', 'err:Evaluate|');
        O.Ignore('T'); // depends on today's date or the current time: observed, not asserted
        O.Ignore('D'); // depends on today's date or the current time: observed, not asserted
        O.Expect('01/01/26', 'ok|2026-01-01T00:00:00Z|01/01/26 12:00 AM');
        O.Expect('01/01/23', 'ok|2023-01-01T00:00:00Z|01/01/23 12:00 AM');
        O.Expect('11/01/26', 'ok|2026-11-01T00:00:00Z|11/01/26 12:00 AM');
        O.Expect('01/01/2026', 'ok|2026-01-01T00:00:00Z|01/01/26 12:00 AM');
        O.Expect('01/01/26D', 'ok|2026-01-01T00:00:00Z|01/01/26 12:00 AM');
        O.Expect('01/01/26T', 'ok|2026-01-01T00:00:00Z|01/01/26 12:00 AM');
        O.Expect('01/01/26 12:00', 'ok|2026-01-01T12:00:00Z|01/01/26 12:00 PM');
        O.Expect('01/01/26 12:00:00', 'ok|2026-01-01T12:00:00Z|01/01/26 12:00 PM');
        O.Expect('01/01/26 12:00:00 AM', 'ok|2026-01-01T00:00:00Z|01/01/26 12:00 AM');
        O.Expect('01/01/26 12:00 PM', 'ok|2026-01-01T12:00:00Z|01/01/26 12:00 PM');
        O.Expect('01/01/26 12:00:00T', 'err:Evaluate|');
        O.Expect('01/01/26 24:00', 'err:Evaluate|');
        O.Expect('01/01/26 25:00', 'err:Evaluate|');
        O.Expect('01/01/26 12:60', 'err:Evaluate|');
        O.Expect('01/01/26 12:00:00.123', 'ok|2026-01-01T12:00:00.123Z|01/01/26 12:00 PM');
        O.Expect('13/01/26 12:00', 'err:Evaluate|');
        O.Expect('02/30/26 12:00', 'err:Evaluate|');
        O.Expect('12:00:00', 'err:DateInvalid|');
        O.Expect('12:00 AM', 'err:DateInvalid|');
        O.Expect('2026-01-01', 'ok|2026-01-01T00:00:00Z|01/01/26 12:00 AM');
        O.Expect('2026-01-01T12:00:00', 'err:DateInvalid|');
        O.Expect('2026-01-01T12:00:00Z', 'ok|2026-01-01T12:00:00Z|01/01/26 12:00 PM');
        O.Verify();
    end;

    [Test]
    procedure FieldRef_Evaluate_DateTime_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvF(O, '2026-01-01T12:00:00.123Z', 12, '2026-01-01T12:00:00.123Z');
        EvF(O, '2026-13-01T00:00:00Z', 12, '2026-13-01T00:00:00Z');
        EvF(O, '2026-01-01T12:00:00+01:00', 12, '2026-01-01T12:00:00+01:00');
        EvF(O, '2026-01-01T24:00:00Z', 12, '2026-01-01T24:00:00Z');
        EvF(O, '20260101T120000Z', 12, '20260101T120000Z');
        EvF(O, 'abc', 12, 'abc');
        EvF(O, 'NUL', 12, Nul());
        EvF(O, '?', 12, '?');
        EvF(O, '01/01/26 ', 12, '01/01/26 ');
        EvF(O, ' 01/01/26', 12, ' 01/01/26');
        EvF(O, '01/xx/26', 12, '01/xx/26');
        EvF(O, 'Mon, 01 Jan 2026 12:00:00 GMT', 12, 'Mon, 01 Jan 2026 12:00:00 GMT');
        EvF(O, '01/01/26 12:00:00 12:00:00', 12, '01/01/26 12:00:00 12:00:00');
        GlobalLanguage(Saved);
        O.Expect('2026-01-01T12:00:00.123Z', 'ok|2026-01-01T12:00:00.123Z|01/01/26 12:00 PM');
        O.Expect('2026-13-01T00:00:00Z', 'err:Evaluate|');
        O.Expect('2026-01-01T12:00:00+01:00', 'ok|2026-01-01T11:00:00Z|01/01/26 11:00 AM');
        O.Expect('2026-01-01T24:00:00Z', 'err:Evaluate|');
        O.Expect('20260101T120000Z', 'err:Evaluate|');
        O.Expect('abc', 'err:Evaluate|');
        O.Expect('NUL', 'err:Evaluate|');
        O.Expect('?', 'err:Evaluate|');
        O.Expect('01/01/26 ', 'ok|2026-01-01T00:00:00Z|01/01/26 12:00 AM');
        O.Expect(' 01/01/26', 'ok|2026-01-01T00:00:00Z|01/01/26 12:00 AM');
        O.Expect('01/xx/26', 'ok|2026-01-26T00:00:00Z|01/26/26 12:00 AM');
        O.Expect('Mon, 01 Jan 2026 12:00:00 GMT', 'err:Evaluate|');
        O.Expect('01/01/26 12:00:00 12:00:00', 'err:Evaluate|');
        O.Verify();
    end;

    [Test]
    procedure FieldRef_Evaluate_Boolean_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvF(O, '', 13, '');
        EvF(O, ' ', 13, ' ');
        EvF(O, 'Yes', 13, 'Yes');
        EvF(O, 'No', 13, 'No');
        EvF(O, 'yes', 13, 'yes');
        EvF(O, 'YES', 13, 'YES');
        EvF(O, 'true', 13, 'true');
        EvF(O, 'false', 13, 'false');
        EvF(O, 'True', 13, 'True');
        EvF(O, 'FALSE', 13, 'FALSE');
        EvF(O, '1', 13, '1');
        EvF(O, '0', 13, '0');
        EvF(O, '-1', 13, '-1');
        EvF(O, '2', 13, '2');
        EvF(O, 'Ja', 13, 'Ja');
        EvF(O, 'Nein', 13, 'Nein');
        EvF(O, 'y', 13, 'y');
        EvF(O, 'n', 13, 'n');
        EvF(O, 'abc', 13, 'abc');
        EvF(O, 'Yes ', 13, 'Yes ');
        EvF(O, ' No', 13, ' No');
        EvF(O, 'Y', 13, 'Y');
        EvF(O, 'N', 13, 'N');
        EvF(O, 'T', 13, 'T');
        EvF(O, 'F', 13, 'F');
        EvF(O, 'on', 13, 'on');
        EvF(O, 'off', 13, 'off');
        EvF(O, 'NUL', 13, Nul());
        EvF(O, '?', 13, '?');
        GlobalLanguage(Saved);
        O.Expect('', 'err:Evaluate|false');
        O.Expect(' ', 'err:Evaluate|false');
        O.Expect('Yes', 'ok|true|Yes');
        O.Expect('No', 'ok|false|No');
        O.Expect('yes', 'ok|true|Yes');
        O.Expect('YES', 'ok|true|Yes');
        O.Expect('true', 'ok|true|Yes');
        O.Expect('false', 'ok|false|No');
        O.Expect('True', 'ok|true|Yes');
        O.Expect('FALSE', 'ok|false|No');
        O.Expect('1', 'ok|true|Yes');
        O.Expect('0', 'ok|false|No');
        O.Expect('-1', 'err:Evaluate|false');
        O.Expect('2', 'err:Evaluate|false');
        O.Expect('Ja', 'err:Evaluate|false');
        O.Expect('Nein', 'err:Evaluate|false');
        O.Expect('y', 'ok|true|Yes');
        O.Expect('n', 'ok|false|No');
        O.Expect('abc', 'err:Evaluate|false');
        O.Expect('Yes ', 'ok|true|Yes');
        O.Expect(' No', 'ok|false|No');
        O.Expect('Y', 'ok|true|Yes');
        O.Expect('N', 'ok|false|No');
        O.Expect('T', 'ok|true|Yes');
        O.Expect('F', 'ok|false|No');
        O.Expect('on', 'err:Evaluate|false');
        O.Expect('off', 'err:Evaluate|false');
        O.Expect('NUL', 'err:Evaluate|false');
        O.Expect('?', 'err:Evaluate|false');
        O.Verify();
    end;

    [Test]
    procedure FieldRef_Evaluate_BigInteger_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvF(O, 'empty', 14, '');
        EvF(O, 'blank', 14, ' ');
        EvF(O, 'two blanks', 14, '  ');
        EvF(O, '0', 14, '0');
        EvF(O, '-0', 14, '-0');
        EvF(O, '+5', 14, '+5');
        EvF(O, '1', 14, '1');
        EvF(O, ' 5 ', 14, ' 5 ');
        EvF(O, '1,234', 14, '1,234');
        EvF(O, '1.5', 14, '1.5');
        EvF(O, '1,5', 14, '1,5');
        EvF(O, '.5', 14, '.5');
        EvF(O, '5.', 14, '5.');
        EvF(O, '12abc', 14, '12abc');
        EvF(O, 'abc', 14, 'abc');
        EvF(O, '--1', 14, '--1');
        EvF(O, '1e3', 14, '1e3');
        EvF(O, '1E3', 14, '1E3');
        EvF(O, '09e738195', 14, '09e738195');
        EvF(O, '1e-5', 14, '1e-5');
        EvF(O, '0x10', 14, '0x10');
        EvF(O, '5D', 14, '5D');
        EvF(O, '5T', 14, '5T');
        EvF(O, 'NUL', 14, Nul());
        EvF(O, '?', 14, '?');
        EvF(O, 'tab 5', 14, ''+Tab()+'5');
        EvF(O, '2147483647', 14, '2147483647');
        EvF(O, '2147483648', 14, '2147483648');
        EvF(O, '-2147483648', 14, '-2147483648');
        EvF(O, '-2147483649', 14, '-2147483649');
        EvF(O, '9223372036854775807', 14, '9223372036854775807');
        GlobalLanguage(Saved);
        O.Expect('empty', 'err:Evaluate|0');
        O.Expect('blank', 'err:Evaluate|0');
        O.Expect('two blanks', 'err:Evaluate|0');
        O.Expect('0', 'ok|0|0');
        O.Expect('-0', 'ok|0|0');
        O.Expect('+5', 'ok|5|5');
        O.Expect('1', 'ok|1|1');
        O.Expect(' 5 ', 'ok|5|5');
        O.Expect('1,234', 'ok|1234|1234');
        O.Expect('1.5', 'err:Evaluate|0');
        O.Expect('1,5', 'ok|15|15');
        O.Expect('.5', 'err:Evaluate|0');
        O.Expect('5.', 'ok|5|5');
        O.Expect('12abc', 'err:Evaluate|0');
        O.Expect('abc', 'err:Evaluate|0');
        O.Expect('--1', 'err:Evaluate|0');
        O.Expect('1e3', 'ok|1000|1000');
        O.Expect('1E3', 'ok|1000|1000');
        O.Expect('09e738195', 'err:Evaluate|0');
        O.Expect('1e-5', 'err:Evaluate|0');
        O.Expect('0x10', 'err:Evaluate|0');
        O.Expect('5D', 'err:Evaluate|0');
        O.Expect('5T', 'err:Evaluate|0');
        O.Expect('NUL', 'err:Evaluate|0');
        O.Expect('?', 'err:Evaluate|0');
        O.Expect('tab 5', 'ok|5|5');
        O.Expect('2147483647', 'ok|2147483647|2147483647');
        O.Expect('2147483648', 'ok|2147483648|2147483648');
        O.Expect('-2147483648', 'ok|-2147483648|-2147483648');
        O.Expect('-2147483649', 'ok|-2147483649|-2147483649');
        O.Expect('9223372036854775807', 'ok|9223372036854775807|9223372036854775807');
        O.Verify();
    end;

    [Test]
    procedure FieldRef_Evaluate_BigInteger_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvF(O, '9223372036854775808', 14, '9223372036854775808');
        EvF(O, '79228162514264337593543950335', 14, '79228162514264337593543950335');
        EvF(O, '99999999999999999999999999999', 14, '99999999999999999999999999999');
        EvF(O, '1 000', 14, '1 000');
        EvF(O, '1000', 14, '1''''000');
        EvF(O, '(5)', 14, '(5)');
        EvF(O, '5-', 14, '5-');
        EvF(O, 'true', 14, 'true');
        GlobalLanguage(Saved);
        O.Expect('9223372036854775808', 'err:Evaluate|0');
        O.Expect('79228162514264337593543950335', 'err:Evaluate|0');
        O.Expect('99999999999999999999999999999', 'err:Evaluate|0');
        O.Expect('1 000', 'err:Evaluate|0');
        O.Expect('1000', 'err:Evaluate|0');
        O.Expect('(5)', 'ok|-5|-5');
        O.Expect('5-', 'ok|-5|-5');
        O.Expect('true', 'err:Evaluate|0');
        O.Verify();
    end;

    [Test]
    procedure FieldRef_Evaluate_Guid_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvF(O, '', 15, '');
        EvF(O, ' ', 15, ' ');
        EvF(O, '{12345678-1234-5678-9ABC-DEF012345678}', 15, '{12345678-1234-5678-9ABC-DEF012345678}');
        EvF(O, '12345678-1234-5678-9ABC-DEF012345678', 15, '12345678-1234-5678-9ABC-DEF012345678');
        EvF(O, '{12345678-1234-5678-9abc-def012345678}', 15, '{12345678-1234-5678-9abc-def012345678}');
        EvF(O, '12345678123456789ABCDEF012345678', 15, '12345678123456789ABCDEF012345678');
        EvF(O, '{00000000-0000-0000-0000-000000000000}', 15, '{00000000-0000-0000-0000-000000000000}');
        EvF(O, '00000000-0000-0000-0000-000000000000', 15, '00000000-0000-0000-0000-000000000000');
        GlobalLanguage(Saved);
        O.Expect('', 'err:InvalidGuidFormat|{00000000-0000-0000-0000-000000000000}');
        O.Expect(' ', 'err:InvalidGuidFormat|{00000000-0000-0000-0000-000000000000}');
        O.Expect('{12345678-1234-5678-9ABC-DEF012345678}', 'ok|{12345678-1234-5678-9ABC-DEF012345678}|{12345678-1234-5678-9ABC-DEF012345678}');
        O.Expect('12345678-1234-5678-9ABC-DEF012345678', 'ok|{12345678-1234-5678-9ABC-DEF012345678}|{12345678-1234-5678-9ABC-DEF012345678}');
        O.Expect('{12345678-1234-5678-9abc-def012345678}', 'ok|{12345678-1234-5678-9ABC-DEF012345678}|{12345678-1234-5678-9ABC-DEF012345678}');
        O.Expect('12345678123456789ABCDEF012345678', 'ok|{12345678-1234-5678-9ABC-DEF012345678}|{12345678-1234-5678-9ABC-DEF012345678}');
        O.Expect('{00000000-0000-0000-0000-000000000000}', 'ok|{00000000-0000-0000-0000-000000000000}|{00000000-0000-0000-0000-000000000000}');
        O.Expect('00000000-0000-0000-0000-000000000000', 'ok|{00000000-0000-0000-0000-000000000000}|{00000000-0000-0000-0000-000000000000}');
        O.Verify();
    end;

    [Test]
    procedure FieldRef_Evaluate_Guid_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvF(O, 'abc', 15, 'abc');
        EvF(O, '{12345678-1234-5678-9ABC-DEF01234567}', 15, '{12345678-1234-5678-9ABC-DEF01234567}');
        EvF(O, '{12345678-1234-5678-9ABC-DEF0123456789}', 15, '{12345678-1234-5678-9ABC-DEF0123456789}');
        EvF(O, '{12345678-1234-5678-9ABC-DEF012345678', 15, '{12345678-1234-5678-9ABC-DEF012345678');
        EvF(O, '12345678-1234-5678-9ABC-DEF012345678}', 15, '12345678-1234-5678-9ABC-DEF012345678}');
        EvF(O, '{GGGGGGGG-1234-5678-9ABC-DEF012345678}', 15, '{GGGGGGGG-1234-5678-9ABC-DEF012345678}');
        EvF(O, ' {12345678-1234-5678-9ABC-DEF012345678}', 15, ' {12345678-1234-5678-9ABC-DEF012345678}');
        EvF(O, '{12345678-1234-5678-9ABC-DEF012345678} ', 15, '{12345678-1234-5678-9ABC-DEF012345678} ');
        EvF(O, '1D', 15, '1D');
        EvF(O, '1T', 15, '1T');
        EvF(O, 'NUL', 15, Nul());
        EvF(O, '?', 15, '?');
        GlobalLanguage(Saved);
        O.Expect('abc', 'err:InvalidGuidFormat|{00000000-0000-0000-0000-000000000000}');
        O.Expect('{12345678-1234-5678-9ABC-DEF01234567}', 'err:InvalidGuidFormat|{00000000-0000-0000-0000-000000000000}');
        O.Expect('{12345678-1234-5678-9ABC-DEF0123456789}', 'err:InvalidGuidFormat|{00000000-0000-0000-0000-000000000000}');
        O.Expect('{12345678-1234-5678-9ABC-DEF012345678', 'err:InvalidGuidFormat|{00000000-0000-0000-0000-000000000000}');
        O.Expect('12345678-1234-5678-9ABC-DEF012345678}', 'err:InvalidGuidFormat|{00000000-0000-0000-0000-000000000000}');
        O.Expect('{GGGGGGGG-1234-5678-9ABC-DEF012345678}', 'err:InvalidGuidFormat|{00000000-0000-0000-0000-000000000000}');
        O.Expect(' {12345678-1234-5678-9ABC-DEF012345678}', 'ok|{12345678-1234-5678-9ABC-DEF012345678}|{12345678-1234-5678-9ABC-DEF012345678}');
        O.Expect('{12345678-1234-5678-9ABC-DEF012345678} ', 'ok|{12345678-1234-5678-9ABC-DEF012345678}|{12345678-1234-5678-9ABC-DEF012345678}');
        O.Expect('1D', 'err:InvalidGuidFormat|{00000000-0000-0000-0000-000000000000}');
        O.Expect('1T', 'err:InvalidGuidFormat|{00000000-0000-0000-0000-000000000000}');
        O.Expect('NUL', 'err:InvalidGuidFormat|{00000000-0000-0000-0000-000000000000}');
        O.Expect('?', 'err:InvalidGuidFormat|{00000000-0000-0000-0000-000000000000}');
        O.Verify();
    end;

    [Test]
    procedure FieldRef_Evaluate_Decimal_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvF(O, 'empty', 16, '');
        EvF(O, 'blank', 16, ' ');
        EvF(O, 'two blanks', 16, '  ');
        EvF(O, '0', 16, '0');
        EvF(O, '-0', 16, '-0');
        EvF(O, '+5', 16, '+5');
        EvF(O, '1', 16, '1');
        EvF(O, ' 5 ', 16, ' 5 ');
        EvF(O, '1,234', 16, '1,234');
        EvF(O, '1.5', 16, '1.5');
        EvF(O, '1,5', 16, '1,5');
        EvF(O, '.5', 16, '.5');
        EvF(O, '5.', 16, '5.');
        EvF(O, '12abc', 16, '12abc');
        EvF(O, 'abc', 16, 'abc');
        EvF(O, '--1', 16, '--1');
        EvF(O, '1e3', 16, '1e3');
        EvF(O, '1E3', 16, '1E3');
        EvF(O, '09e738195', 16, '09e738195');
        EvF(O, '1e-5', 16, '1e-5');
        EvF(O, '0x10', 16, '0x10');
        EvF(O, '5D', 16, '5D');
        EvF(O, '5T', 16, '5T');
        EvF(O, 'NUL', 16, Nul());
        EvF(O, '?', 16, '?');
        EvF(O, 'tab 5', 16, ''+Tab()+'5');
        EvF(O, '2147483647', 16, '2147483647');
        EvF(O, '2147483648', 16, '2147483648');
        EvF(O, '-2147483648', 16, '-2147483648');
        EvF(O, '-2147483649', 16, '-2147483649');
        EvF(O, '9223372036854775807', 16, '9223372036854775807');
        GlobalLanguage(Saved);
        O.Expect('empty', 'err:Evaluate|0');
        O.Expect('blank', 'err:Evaluate|0');
        O.Expect('two blanks', 'err:Evaluate|0');
        O.Expect('0', 'ok|0|0');
        O.Expect('-0', 'ok|0|0');
        O.Expect('+5', 'ok|5|5');
        O.Expect('1', 'ok|1|1');
        O.Expect(' 5 ', 'ok|5|5');
        O.Expect('1,234', 'ok|1234|1,234');
        O.Expect('1.5', 'ok|1.5|1.5');
        O.Expect('1,5', 'ok|15|15');
        O.Expect('.5', 'ok|0.5|0.5');
        O.Expect('5.', 'ok|5|5');
        O.Expect('12abc', 'err:Evaluate|0');
        O.Expect('abc', 'err:Evaluate|0');
        O.Expect('--1', 'err:Evaluate|0');
        O.Expect('1e3', 'ok|1000|1,000');
        O.Expect('1E3', 'ok|1000|1,000');
        O.Expect('09e738195', 'err:Evaluate|0');
        O.Expect('1e-5', 'ok|0.00001|0.00001');
        O.Expect('0x10', 'err:Evaluate|0');
        O.Expect('5D', 'err:Evaluate|0');
        O.Expect('5T', 'err:Evaluate|0');
        O.Expect('NUL', 'err:Evaluate|0');
        O.Expect('?', 'err:Evaluate|0');
        O.Expect('tab 5', 'ok|5|5');
        O.Expect('2147483647', 'ok|2147483647|2,147,483,647');
        O.Expect('2147483648', 'ok|2147483648|2,147,483,648');
        O.Expect('-2147483648', 'ok|-2147483648|-2,147,483,648');
        O.Expect('-2147483649', 'ok|-2147483649|-2,147,483,649');
        O.Expect('9223372036854775807', 'err:Evaluate|0');
        O.Verify();
    end;

    [Test]
    procedure FieldRef_Evaluate_Decimal_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvF(O, '9223372036854775808', 16, '9223372036854775808');
        EvF(O, '79228162514264337593543950335', 16, '79228162514264337593543950335');
        EvF(O, '99999999999999999999999999999', 16, '99999999999999999999999999999');
        EvF(O, '1 000', 16, '1 000');
        EvF(O, '1000', 16, '1''''000');
        EvF(O, '(5)', 16, '(5)');
        EvF(O, '5-', 16, '5-');
        EvF(O, 'true', 16, 'true');
        GlobalLanguage(Saved);
        O.Expect('9223372036854775808', 'err:Evaluate|0');
        O.Expect('79228162514264337593543950335', 'err:Evaluate|0');
        O.Expect('99999999999999999999999999999', 'err:Evaluate|0');
        O.Expect('1 000', 'err:Evaluate|0');
        O.Expect('1000', 'err:Evaluate|0');
        O.Expect('(5)', 'ok|-5|-5');
        O.Expect('5-', 'ok|-5|-5');
        O.Expect('true', 'err:Evaluate|0');
        O.Verify();
    end;

    [Test]
    procedure FieldRef_Evaluate_Integer_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvF(O, 'empty', 17, '');
        EvF(O, 'blank', 17, ' ');
        EvF(O, 'two blanks', 17, '  ');
        EvF(O, '0', 17, '0');
        EvF(O, '-0', 17, '-0');
        EvF(O, '+5', 17, '+5');
        EvF(O, '1', 17, '1');
        EvF(O, ' 5 ', 17, ' 5 ');
        EvF(O, '1,234', 17, '1,234');
        EvF(O, '1.5', 17, '1.5');
        EvF(O, '1,5', 17, '1,5');
        EvF(O, '.5', 17, '.5');
        EvF(O, '5.', 17, '5.');
        EvF(O, '12abc', 17, '12abc');
        EvF(O, 'abc', 17, 'abc');
        EvF(O, '--1', 17, '--1');
        EvF(O, '1e3', 17, '1e3');
        EvF(O, '1E3', 17, '1E3');
        EvF(O, '09e738195', 17, '09e738195');
        EvF(O, '1e-5', 17, '1e-5');
        EvF(O, '0x10', 17, '0x10');
        EvF(O, '5D', 17, '5D');
        EvF(O, '5T', 17, '5T');
        EvF(O, 'NUL', 17, Nul());
        EvF(O, '?', 17, '?');
        EvF(O, 'tab 5', 17, ''+Tab()+'5');
        EvF(O, '2147483647', 17, '2147483647');
        EvF(O, '2147483648', 17, '2147483648');
        EvF(O, '-2147483648', 17, '-2147483648');
        EvF(O, '-2147483649', 17, '-2147483649');
        EvF(O, '9223372036854775807', 17, '9223372036854775807');
        GlobalLanguage(Saved);
        O.Expect('empty', 'err:Evaluate|0');
        O.Expect('blank', 'err:Evaluate|0');
        O.Expect('two blanks', 'err:Evaluate|0');
        O.Expect('0', 'ok|0|0');
        O.Expect('-0', 'ok|0|0');
        O.Expect('+5', 'ok|5|5');
        O.Expect('1', 'ok|1|1');
        O.Expect(' 5 ', 'ok|5|5');
        O.Expect('1,234', 'ok|1234|1234');
        O.Expect('1.5', 'err:Evaluate|0');
        O.Expect('1,5', 'ok|15|15');
        O.Expect('.5', 'err:Evaluate|0');
        O.Expect('5.', 'ok|5|5');
        O.Expect('12abc', 'err:Evaluate|0');
        O.Expect('abc', 'err:Evaluate|0');
        O.Expect('--1', 'err:Evaluate|0');
        O.Expect('1e3', 'ok|1000|1000');
        O.Expect('1E3', 'ok|1000|1000');
        O.Expect('09e738195', 'err:Evaluate|0');
        O.Expect('1e-5', 'err:Evaluate|0');
        O.Expect('0x10', 'err:Evaluate|0');
        O.Expect('5D', 'err:Evaluate|0');
        O.Expect('5T', 'err:Evaluate|0');
        O.Expect('NUL', 'err:Evaluate|0');
        O.Expect('?', 'err:Evaluate|0');
        O.Expect('tab 5', 'ok|5|5');
        O.Expect('2147483647', 'ok|2147483647|2147483647');
        O.Expect('2147483648', 'err:Evaluate|0');
        O.Expect('-2147483648', 'ok|-2147483648|-2147483648');
        O.Expect('-2147483649', 'err:Evaluate|0');
        O.Expect('9223372036854775807', 'err:Evaluate|0');
        O.Verify();
    end;

    [Test]
    procedure FieldRef_Evaluate_Integer_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvF(O, '9223372036854775808', 17, '9223372036854775808');
        EvF(O, '79228162514264337593543950335', 17, '79228162514264337593543950335');
        EvF(O, '99999999999999999999999999999', 17, '99999999999999999999999999999');
        EvF(O, '1 000', 17, '1 000');
        EvF(O, '1000', 17, '1''''000');
        EvF(O, '(5)', 17, '(5)');
        EvF(O, '5-', 17, '5-');
        EvF(O, 'true', 17, 'true');
        GlobalLanguage(Saved);
        O.Expect('9223372036854775808', 'err:Evaluate|0');
        O.Expect('79228162514264337593543950335', 'err:Evaluate|0');
        O.Expect('99999999999999999999999999999', 'err:Evaluate|0');
        O.Expect('1 000', 'err:Evaluate|0');
        O.Expect('1000', 'err:Evaluate|0');
        O.Expect('(5)', 'ok|-5|-5');
        O.Expect('5-', 'ok|-5|-5');
        O.Expect('true', 'err:Evaluate|0');
        O.Verify();
    end;

    [Test]
    procedure FieldRef_Evaluate_Code10_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvF(O, '', 18, '');
        EvF(O, ' ', 18, ' ');
        EvF(O, 'abc', 18, 'abc');
        EvF(O, ' abc ', 18, ' abc ');
        EvF(O, 'a,b', 18, 'a,b');
        EvF(O, '1D', 18, '1D');
        EvF(O, '1T', 18, '1T');
        EvF(O, '?', 18, '?');
        EvF(O, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 18, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
        EvF(O, 'ä', 18, 'ä');
        EvF(O, '"q"', 18, '"q"');
        EvF(O, 'it''s', 18, 'it''s');
        EvF(O, 'NUL', 18, Nul());
        GlobalLanguage(Saved);
        O.Expect('', 'ok||');
        O.Expect(' ', 'ok||');
        O.Expect('abc', 'ok|ABC|ABC');
        O.Expect(' abc ', 'ok|ABC|ABC');
        O.Expect('a,b', 'ok|A,B|A,B');
        O.Expect('1D', 'ok|1D|1D');
        O.Expect('1T', 'ok|1T|1T');
        O.Expect('?', 'ok|?|?');
        O.Expect('ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'err:StringLengthExceeded|');
        O.Expect('ä', 'ok|Ä|Ä');
        O.Expect('"q"', 'ok|"Q"|"Q"');
        O.Expect('it''s', 'ok|IT''S|IT''S');
        O.Expect('NUL', 'ok|\u0000|\u0000');
        O.Verify();
    end;

    [Test]
    procedure FieldRef_FormatThenEvaluate_Roundtrip_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        Roundtrip(O, 'Duration_0', 2, 0);
        Roundtrip(O, 'Duration_1', 2, 1);
        Roundtrip(O, 'Duration_-1', 2, -1);
        Roundtrip(O, 'Duration_1000', 2, 1000);
        Roundtrip(O, 'Duration_-1000', 2, -1000);
        Roundtrip(O, 'Duration_90061001', 2, 90061001);
        Roundtrip(O, 'Duration_-90061001', 2, -90061001);
        Roundtrip(O, 'Option_0', 3, 0);
        Roundtrip(O, 'Option_1', 3, 1);
        Roundtrip(O, 'Option_2', 3, 2);
        Roundtrip(O, 'Option_3', 3, 3);
        Roundtrip(O, 'Date_0D', 10, 0D);
        Roundtrip(O, 'Date_20260309D', 10, 20260309D);
        Roundtrip(O, 'Date_17530101D', 10, 17530101D);
        Roundtrip(O, 'Time_0T', 11, 0T);
        Roundtrip(O, 'Time_123456T', 11, 123456T);
        Roundtrip(O, 'Time_235959.999T', 11, 235959.999T);
        GlobalLanguage(Saved);
        O.Expect('Duration_0', 'text=|back=P0DT0H0M0.0S');
        O.Expect('Duration_1', 'text=1 millisecond|back=P0DT0H0M0.001S');
        O.Expect('Duration_-1', 'text=-1 millisecond|back=-P0DT0H0M0.001S');
        O.Expect('Duration_1000', 'text=1 second|back=P0DT0H0M1.0S');
        O.Expect('Duration_-1000', 'text=-1 second|back=-P0DT0H0M1.0S');
        O.Expect('Duration_90061001', 'text=1 day 1 hour 1 minute 1 second 1 millisecond|back=P1DT1H1M1.001S');
        O.Expect('Duration_-90061001', 'text=-1 day 1 hour 1 minute 1 second 1 millisecond|back=-P1DT1H1M1.001S');
        O.Expect('Option_0', 'text= |back=0');
        O.Expect('Option_1', 'text=male|back=1');
        O.Expect('Option_2', 'text=female|back=2');
        O.Expect('Option_3', 'text=non-binary|back=3');
        O.Expect('Date_0D', 'text=|back=');
        O.Expect('Date_20260309D', 'text=03/09/26|back=2026-03-09');
        O.Expect('Date_17530101D', 'text=01/01/1753|back=1753-01-01');
        O.Expect('Time_0T', 'text=|back=');
        O.Expect('Time_123456T', 'text=12:34:56 PM|back=12:34:56');
        O.Expect('Time_235959.999T', 'text=11:59:59 PM|back=23:59:59');
        O.Verify();
    end;

    [Test]
    procedure FieldRef_FormatThenEvaluate_Roundtrip_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        Roundtrip(O, 'DateTime_0DT', 12, 0DT);
        Roundtrip(O, 'DateTime_CreateDateTime20260309D134512.123T', 12, CreateDateTime(20260309D, 134512.123T));
        Roundtrip(O, 'DateTime_CreateDateTime20260309D0T', 12, CreateDateTime(20260309D, 0T));
        Roundtrip(O, 'Boolean_true', 13, true);
        Roundtrip(O, 'Boolean_false', 13, false);
        Roundtrip(O, 'BigInteger_0L', 14, 0L);
        Roundtrip(O, 'BigInteger_-1L', 14, -1L);
        Roundtrip(O, 'BigInteger_1234567890123L', 14, 1234567890123L);
        Roundtrip(O, 'Decimal_0', 16, 0);
        Roundtrip(O, 'Decimal_0.5', 16, 0.5);
        Roundtrip(O, 'Decimal_-1234.5', 16, -1234.5);
        Roundtrip(O, 'Decimal_1234567.891', 16, 1234567.891);
        Roundtrip(O, 'Integer_0', 17, 0);
        Roundtrip(O, 'Integer_-1', 17, -1);
        Roundtrip(O, 'Integer_2147483647', 17, 2147483647);
        GlobalLanguage(Saved);
        O.Expect('DateTime_0DT', 'text=|back=');
        O.Expect('DateTime_CreateDateTime20260309D134512.123T', 'text=03/09/26 01:45 PM|back=2026-03-09T13:45:00Z');
        O.Expect('DateTime_CreateDateTime20260309D0T', 'text=03/09/26 12:00 AM|back=2026-03-09T00:00:00Z');
        O.Expect('Boolean_true', 'text=Yes|back=true');
        O.Expect('Boolean_false', 'text=No|back=false');
        O.Expect('BigInteger_0L', 'text=0|back=0');
        O.Expect('BigInteger_-1L', 'text=-1|back=-1');
        O.Expect('BigInteger_1234567890123L', 'text=1234567890123|back=1234567890123');
        O.Expect('Decimal_0', 'text=0|back=0');
        O.Expect('Decimal_0.5', 'text=0.5|back=0.5');
        O.Expect('Decimal_-1234.5', 'text=-1,234.5|back=-1234.5');
        O.Expect('Decimal_1234567.891', 'text=1,234,567.891|back=1234567.891');
        O.Expect('Integer_0', 'text=0|back=0');
        O.Expect('Integer_-1', 'text=-1|back=-1');
        O.Expect('Integer_2147483647', 'text=2147483647|back=2147483647');
        O.Verify();
    end;
}
