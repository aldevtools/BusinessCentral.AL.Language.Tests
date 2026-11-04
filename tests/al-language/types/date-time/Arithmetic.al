// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Topic: Date and Time Variant2Date, Variant2Time, comparisons, arithmetic
// BC versions: 29 (27 and 28 by CI)

codeunit 73802 "LT DtT Arithmetic"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Date_Plus_Minus_Integer()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := 20240228D;
        Observer.Observe('+1', Format(D + 1, 0, 9));
        Observer.Observe('+2', Format(D + 2, 0, 9));
        Observer.Observe('-1', Format(D - 1, 0, 9));
        Observer.Observe('+0', Format(D + 0, 0, 9));
        Observer.Observe('+366', Format(D + 366, 0, 9));
        Observer.Observe('-59', Format(D - 59, 0, 9));
        Observer.Observe('-58', Format(D - 58, 0, 9));
        Observer.Observe('date - date', Format(20240301D - 20240228D));
        Observer.Observe('date - date neg', Format(20240228D - 20240301D));
        Observer.Observe('date - date year', Format(20250101D - 20240101D));
        asserterror Observer.Observe('max - min', Format(99991231D - 00010101D));
        Observer.ObserveError('af30');
        asserterror Observer.Observe('date - 0D', Format(20240101D - 0D));
        Observer.ObserveError('af32');
        asserterror Observer.Observe('0D - date', Format(0D - 20240101D));
        Observer.ObserveError('af34');
        Observer.Observe('type of date - date', Format(20240301D - 20240228D + 1));
        Observer.Observe('+ negative', Format(D + (-1), 0, 9));
        Observer.Observe('+ big', Format(D + 100000, 0, 9));
        asserterror Observer.Observe('0D + 0', Format(0D + 0, 0, 9));
        Observer.ObserveError('af39');
        asserterror Observer.Observe('0D + 1', Format(0D + 1, 0, 9));
        Observer.ObserveError('af41');
        Observer.Expect('+1', '2024-02-29');
        Observer.Expect('+2', '2024-03-01');
        Observer.Expect('-1', '2024-02-27');
        Observer.Expect('+0', '2024-02-28');
        Observer.Expect('+366', '2025-02-28');
        Observer.Expect('-59', '2023-12-31');
        Observer.Expect('-58', '2024-01-01');
        Observer.Expect('date - date', '2');
        Observer.Expect('date - date neg', '-2');
        Observer.Expect('date - date year', '366');
        Observer.Expect('af30|text', 'The date is not valid.');
        Observer.Expect('af30|code', 'DateInvalid');
        Observer.Expect('af32|text', 'The date is not valid.');
        Observer.Expect('af32|code', 'DateInvalid');
        Observer.Expect('af34|text', 'The date is not valid.');
        Observer.Expect('af34|code', 'DateInvalid');
        Observer.Expect('type of date - date', '3');
        Observer.Expect('+ negative', '2024-02-27');
        Observer.Expect('+ big', '2297-12-13');
        Observer.Expect('af39|text', 'The date is not valid.');
        Observer.Expect('af39|code', 'DateInvalid');
        Observer.Expect('af41|text', 'The date is not valid.');
        Observer.Expect('af41|code', 'DateInvalid');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Arithmetic_Errors()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        asserterror D := 99991231D + 1;
        Observer.ObserveError('past max');
        asserterror D := 00010101D - 1;
        Observer.ObserveError('before min');
        asserterror D := 20240101D + 3000000;
        Observer.ObserveError('far past max');
        asserterror D := 20240101D - 3000000;
        Observer.ObserveError('far before min');
        asserterror D := 20240101D + 2147483647;
        Observer.ObserveError('int max');
        asserterror D := 0D - 1;
        Observer.ObserveError('0D minus 1');
        Observer.Expect('past max|text', 'The date is not valid.');
        Observer.Expect('past max|code', 'DateInvalid');
        Observer.Expect('before min|text', 'The date is not valid.');
        Observer.Expect('before min|code', 'DateInvalid');
        Observer.Expect('far past max|text', 'The date is not valid.');
        Observer.Expect('far past max|code', 'DateInvalid');
        Observer.Expect('far before min|text', 'The date is not valid.');
        Observer.Expect('far before min|code', 'DateInvalid');
        Observer.Expect('int max|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('int max|code', 'AL:Overflow');
        Observer.Expect('0D minus 1|text', 'The date is not valid.');
        Observer.Expect('0D minus 1|code', 'DateInvalid');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Comparisons()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('lt', Format(20240101D < 20240102D));
        Observer.Observe('gt', Format(20240101D > 20240102D));
        Observer.Observe('eq', Format(20240101D = 20240101D));
        Observer.Observe('ne', Format(20240101D <> 20240101D));
        asserterror Observer.Observe('0D lt date', Format(0D < 00010101D));
        Observer.ObserveError('af72');
        asserterror Observer.Observe('0D gt date', Format(0D > 00010101D));
        Observer.ObserveError('af75');
        Observer.Observe('0D eq 0D', Format(0D = 0D));
        asserterror Observer.Observe('0D eq min', Format(0D = 00010101D));
        Observer.ObserveError('af79');
        Observer.Observe('max gt', Format(99991231D > 20240101D));
        Observer.Observe('le', Format(20240101D <= 20240101D));
        Observer.Observe('ge', Format(20240101D >= 20240102D));
        Observer.Observe('0D le', Format(0D <= 20240101D));
        Observer.Expect('lt', 'Yes');
        Observer.Expect('gt', 'No');
        Observer.Expect('eq', 'Yes');
        Observer.Expect('ne', 'No');
        Observer.Expect('af72|text', 'The date is not valid.');
        Observer.Expect('af72|code', 'DateInvalid');
        Observer.Expect('af75|text', 'The date is not valid.');
        Observer.Expect('af75|code', 'DateInvalid');
        Observer.Expect('0D eq 0D', 'Yes');
        Observer.Expect('af79|text', 'The date is not valid.');
        Observer.Expect('af79|code', 'DateInvalid');
        Observer.Expect('max gt', 'Yes');
        Observer.Expect('le', 'Yes');
        Observer.Expect('ge', 'No');
        Observer.Expect('0D le', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Time_Arithmetic()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
    begin
        T := 120000T;
        Observer.Observe('base', Format(T, 0, 9));
        Observer.Observe('+1000', Format(T + 1000, 0, 9));
        Observer.Observe('-1000', Format(T - 1000, 0, 9));
        Observer.Observe('+3600000', Format(T + 3600000, 0, 9));
        Observer.Observe('+0', Format(T + 0, 0, 9));
        Observer.Observe('time - time', Format(130000T - 120000T));
        Observer.Observe('time - time neg', Format(120000T - 130000T));
        Observer.Observe('time - same', Format(120000T - 120000T));
        Observer.Observe('wrap past midnight', Format(235959T + 2000, 0, 9));
        Observer.Observe('wrap before midnight', Format(000001T - 2000, 0, 9));
        Observer.Observe('+86400000', Format(T + 86400000, 0, 9));
        Observer.Observe('+86400001', Format(T + 86400001, 0, 9));
        Observer.Observe('-86400000', Format(T - 86400000, 0, 9));
        Observer.Observe('ms', Format(120000.123T + 1, 0, 9));
        asserterror Observer.Observe('0T + 1', Format(0T + 1, 0, 9));
        Observer.ObserveError('af105');
        asserterror Observer.Observe('0T - 1', Format(0T - 1, 0, 9));
        Observer.ObserveError('af109');
        asserterror Observer.Observe('time - 0T', Format(120000T - 0T));
        Observer.ObserveError('af113');
        asserterror Observer.Observe('0T - time', Format(0T - 120000T));
        Observer.ObserveError('af116');
        Observer.Observe('min', Format(000000T, 0, 9));
        Observer.Observe('max', Format(235959.999T, 0, 9));
        Observer.Observe('max + 1', Format(235959.999T + 1, 0, 9));
        Observer.Expect('base', '12:00:00');
        Observer.Expect('+1000', '12:00:01');
        Observer.Expect('-1000', '11:59:59');
        Observer.Expect('+3600000', '13:00:00');
        Observer.Expect('+0', '12:00:00');
        Observer.Expect('time - time', '3600000');
        Observer.Expect('time - time neg', '-3600000');
        Observer.Expect('time - same', '0');
        Observer.Expect('wrap past midnight', '00:00:01');
        Observer.Expect('wrap before midnight', '23:59:59');
        Observer.Expect('+86400000', '12:00:00');
        Observer.Expect('+86400001', '12:00:00.001');
        Observer.Expect('-86400000', '12:00:00');
        Observer.Expect('ms', '12:00:00.124');
        Observer.Expect('af105|text', 'Adding to an undefined (0T) time.');
        Observer.Expect('af105|code', 'InvalidTime');
        Observer.Expect('af109|text', 'Adding to an undefined (0T) time.');
        Observer.Expect('af109|code', 'InvalidTime');
        Observer.Expect('af113|text', 'Subtracting an undefined (0T) time.');
        Observer.Expect('af113|code', 'InvalidTime');
        Observer.Expect('af116|text', 'Subtracting from an undefined (0T) time.');
        Observer.Expect('af116|code', 'InvalidTime');
        Observer.Expect('min', '00:00:00');
        Observer.Expect('max', '23:59:59.999');
        Observer.Expect('max + 1', '00:00:00');
        Observer.Verify();
    end;

    [Test]
    procedure Time_Comparisons()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('lt', Format(120000T < 130000T));
        Observer.Observe('gt', Format(120000T > 130000T));
        Observer.Observe('eq', Format(120000T = 120000T));
        Observer.Observe('0T eq 0T', Format(0T = 0T));
        Observer.Observe('0T eq midnight', Format(0T = 000000T));
        Observer.Observe('0T lt midnight', Format(0T < 000000T));
        Observer.Observe('0T lt time', Format(0T < 120000T));
        Observer.Observe('midnight lt time', Format(000000T < 120000T));
        Observer.Observe('ms lt', Format(120000.001T > 120000T));
        Observer.Observe('0T text', Format(0T));
        Observer.Observe('midnight text 9', Format(000000T, 0, 9));
        Observer.Observe('0T text 9', Format(0T, 0, 9));
        Observer.Expect('lt', 'Yes');
        Observer.Expect('gt', 'No');
        Observer.Expect('eq', 'Yes');
        Observer.Expect('0T eq 0T', 'Yes');
        Observer.Expect('0T eq midnight', 'No');
        Observer.Expect('0T lt midnight', 'Yes');
        Observer.Expect('0T lt time', 'Yes');
        Observer.Expect('midnight lt time', 'Yes');
        Observer.Expect('ms lt', 'Yes');
        Observer.Expect('0T text', '');
        Observer.Expect('midnight text 9', '00:00:00');
        Observer.Expect('0T text 9', '');
        Observer.Verify();
    end;

    [Test]
    procedure DateTime_Arithmetic()
    var
        Observer: Codeunit "Probe Observer";
        DT: DateTime;
        Dur: Duration;
    begin
        DT := CreateDateTime(20240115D, 120000T);
        Observer.Observe('base', Format(DT, 0, 9));
        Observer.Observe('+1000', Format(DT + 1000, 0, 9));
        Observer.Observe('-1000', Format(DT - 1000, 0, 9));
        Observer.Observe('+1 day', Format(DT + 86400000, 0, 9));
        Observer.Observe('+bigint', Format(DT + 86400000L, 0, 9));
        Observer.Observe('-bigint', Format(DT - 86400000L, 0, 9));
        Observer.Observe('dt - dt', Format(DT - CreateDateTime(20240114D, 120000T)));
        Observer.Observe('dt - dt neg', Format(CreateDateTime(20240114D, 120000T) - DT));
        Observer.Observe('dt - dt zero', Format(DT - DT));
        Dur := 3600000;
        Observer.Observe('+ duration', Format(DT + Dur, 0, 9));
        Observer.Observe('- duration', Format(DT - Dur, 0, 9));
        Observer.Observe('dt-dt type', Format((DT - CreateDateTime(20240114D, 120000T)) + 1));
        asserterror Observer.Observe('0DT + 1', Format(0DT + 1, 0, 9));
        Observer.ObserveError('af157');
        asserterror Observer.Observe('0DT - 1', Format(0DT - 1, 0, 9));
        Observer.ObserveError('af162');
        asserterror Observer.Observe('dt - 0DT', Format(DT - 0DT));
        Observer.ObserveError('af167');
        asserterror Observer.Observe('0DT - dt', Format(0DT - DT));
        Observer.ObserveError('af171');
        Observer.Observe('+0', Format(DT + 0, 0, 9));
        Observer.Observe('+ms', Format(DT + 1, 0, 9));
        Observer.Observe('day change', Format(CreateDateTime(20240115D, 235959.999T) + 1, 0, 9));
        Observer.Expect('base', '2024-01-15T12:00:00Z');
        Observer.Expect('+1000', '2024-01-15T12:00:01Z');
        Observer.Expect('-1000', '2024-01-15T11:59:59Z');
        Observer.Expect('+1 day', '2024-01-16T12:00:00Z');
        Observer.Expect('+bigint', '2024-01-16T12:00:00Z');
        Observer.Expect('-bigint', '2024-01-14T12:00:00Z');
        Observer.Expect('dt - dt', '1 day');
        Observer.Expect('dt - dt neg', '-1 day');
        Observer.Expect('dt - dt zero', '');
        Observer.Expect('+ duration', '2024-01-15T13:00:00Z');
        Observer.Expect('- duration', '2024-01-15T11:00:00Z');
        Observer.Expect('dt-dt type', '86400001');
        Observer.Expect('af157|text', 'The date is not valid.');
        Observer.Expect('af157|code', 'DateInvalid');
        Observer.Expect('af162|text', 'The date is not valid.');
        Observer.Expect('af162|code', 'DateInvalid');
        Observer.Expect('af167|text', 'The date is not valid.');
        Observer.Expect('af167|code', 'DateInvalid');
        Observer.Expect('af171|text', 'The date is not valid.');
        Observer.Expect('af171|code', 'DateInvalid');
        Observer.Expect('+0', '2024-01-15T12:00:00Z');
        Observer.Expect('+ms', '2024-01-15T12:00:00.001Z');
        Observer.Expect('day change', '2024-01-16T00:00:00Z');
        Observer.Verify();
    end;

    [Test]
    procedure DateTime_Arithmetic_Errors()
    var
        Observer: Codeunit "Probe Observer";
        DT: DateTime;
    begin
        asserterror DT := CreateDateTime(99991231D, 235959.999T) + 1;
        Observer.ObserveError('past max');
        asserterror DT := CreateDateTime(00010101D, 000000T) - 1;
        Observer.ObserveError('before min');
        asserterror DT := CreateDateTime(20240101D, 0T) + 9223372036854775807L;
        Observer.ObserveError('bigint max');
        asserterror DT := CreateDateTime(20240101D, 0T) - 9223372036854775807L;
        Observer.ObserveError('bigint -max');
        Observer.Expect('past max|text', 'The date is not valid.');
        Observer.Expect('past max|code', 'DateInvalid');
        Observer.Expect('before min|text', 'The date is not valid.');
        Observer.Expect('before min|code', 'DateInvalid');
        Observer.Expect('bigint max|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('bigint max|code', 'AL:Overflow');
        Observer.Expect('bigint -max|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('bigint -max|code', 'AL:Overflow');
        Observer.Verify();
    end;

    [Test]
    procedure DateTime_Comparisons()
    var
        Observer: Codeunit "Probe Observer";
        A: DateTime;
        B: DateTime;
    begin
        A := CreateDateTime(20240115D, 120000T);
        B := CreateDateTime(20240115D, 120001T);
        Observer.Observe('lt', Format(A < B));
        Observer.Observe('gt', Format(A > B));
        Observer.Observe('eq', Format(A = A));
        Observer.Observe('ne', Format(A <> B));
        Observer.Observe('0DT eq 0DT', Format(0DT = 0DT));
        Observer.Observe('0DT lt A', Format(0DT < A));
        asserterror Observer.Observe('0DT lt min', Format(0DT < CreateDateTime(00010101D, 000000T)));
        Observer.ObserveError('af200');
        asserterror Observer.Observe('0DT eq min', Format(0DT = CreateDateTime(00010101D, 000000T)));
        Observer.ObserveError('af206');
        Observer.Observe('0DT text', Format(0DT));
        Observer.Observe('0DT text 9', Format(0DT, 0, 9));
        Observer.Observe('ms diff', Format(CreateDateTime(20240115D, 120000.001T) > CreateDateTime(20240115D, 120000T)));
        Observer.Observe('0D 0T dt', Format(CreateDateTime(0D, 0T) = 0DT));
        Observer.Observe('date only', Format(CreateDateTime(20240115D, 0T)));
        Observer.Expect('lt', 'Yes');
        Observer.Expect('gt', 'No');
        Observer.Expect('eq', 'Yes');
        Observer.Expect('ne', 'Yes');
        Observer.Expect('0DT eq 0DT', 'Yes');
        Observer.Expect('0DT lt A', 'Yes');
        Observer.Expect('af200|text', 'The date is not valid.');
        Observer.Expect('af200|code', 'DateInvalid');
        Observer.Expect('af206|text', 'The date is not valid.');
        Observer.Expect('af206|code', 'DateInvalid');
        Observer.Expect('0DT text', '');
        Observer.Expect('0DT text 9', '');
        Observer.Expect('ms diff', 'Yes');
        Observer.Expect('0D 0T dt', 'Yes');
        Observer.Expect('date only', '01/15/24 12:00 AM');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_Arithmetic()
    var
        Observer: Codeunit "Probe Observer";
        A: Duration;
        B: Duration;
    begin
        A := 3600000;
        B := 1800000;
        Observer.Observe('A', Format(A));
        Observer.Observe('A+B', Format(A + B));
        Observer.Observe('A-B', Format(A - B));
        Observer.Observe('B-A', Format(B - A));
        Observer.Observe('A*2', Format(A * 2));
        Observer.Observe('A/2', Format(A / 2));
        Observer.Observe('A div 2', Format(A div 2));
        Observer.Observe('A mod 1000000', Format(A mod 1000000));
        Observer.Observe('A/B', Format(A / B));
        Observer.Observe('A + 1', Format(A + 1));
        Observer.Observe('A = B', Format(A = B));
        Observer.Observe('A > B', Format(A > B));
        Observer.Observe('A < B', Format(A < B));
        Observer.Observe('A = 3600000', Format(A = 3600000));
        Observer.Observe('0 duration', Format(Duration_Zero()));
        Observer.Observe('0 duration 9', Format(Duration_Zero(), 0, 9));
        Observer.Observe('A 9', Format(A, 0, 9));
        Observer.Observe('A 0', Format(A, 0, 0));
        Observer.Observe('A 1', Format(A, 0, 1));
        Observer.Observe('A 2', Format(A, 0, 2));
        Observer.Expect('A', '1 hour');
        Observer.Expect('A+B', '5400000');
        Observer.Expect('A-B', '1800000');
        Observer.Expect('B-A', '-1800000');
        Observer.Expect('A*2', '7200000');
        Observer.Expect('A/2', '1,800,000');
        Observer.Expect('A div 2', '1,800,000');
        Observer.Expect('A mod 1000000', '600000');
        Observer.Expect('A/B', '2');
        Observer.Expect('A + 1', '3600001');
        Observer.Expect('A = B', 'No');
        Observer.Expect('A > B', 'Yes');
        Observer.Expect('A < B', 'No');
        Observer.Expect('A = 3600000', 'Yes');
        Observer.Expect('0 duration', '');
        Observer.Expect('0 duration 9', 'P0DT0H0M0.0S');
        Observer.Expect('A 9', 'P0DT1H0M0.0S');
        Observer.Expect('A 0', '1 hour');
        Observer.Expect('A 1', '1 hour');
        Observer.Expect('A 2', '1 2');
        Observer.Verify();
    end;

    local procedure Duration_Zero(): Duration
    var
        D: Duration;
    begin
        exit(D);
    end;

    [Test]
    procedure Duration_Assignments()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
        I: Integer;
        Big: BigInteger;
        Dec: Decimal;
    begin
        D := 1500;
        Observer.Observe('from int', Format(D));
        I := D;
        Observer.Observe('to int', Format(I));
        Big := D;
        Observer.Observe('to bigint', Format(Big));
        Dec := D;
        Observer.Observe('to dec', Format(Dec));
        asserterror D := 1.5;
        Observer.ObserveError('af267');
        Observer.Observe('from dec 1.5', Format(D));
        asserterror D := 1.4;
        Observer.ObserveError('af275');
        Observer.Observe('from dec 1.4', Format(D));
        D := 2147483648L;
        Observer.Observe('from bigint', Format(D));
        D := -1;
        Observer.Observe('neg', Format(D));
        D := 86400000;
        Observer.Observe('one day', Format(D));
        D := 90061001;
        Observer.Observe('1d1h1m1s1ms', Format(D));
        D := 1;
        Observer.Observe('1 ms', Format(D));
        D := 1000;
        Observer.Observe('1 s', Format(D));
        D := 60000;
        Observer.Observe('1 min', Format(D));
        D := 3600000;
        Observer.Observe('1 h', Format(D));
        D := 31536000000L;
        Observer.Observe('365 days', Format(D));
        Observer.Expect('from int', '1 second 500 milliseconds');
        Observer.Expect('to int', '1500');
        Observer.Expect('to bigint', '1500');
        Observer.Expect('to dec', '1,500');
        Observer.Expect('af267|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.5 to System.Int64.');
        Observer.Expect('af267|code', 'ConversionCast');
        Observer.Expect('from dec 1.5', '1 second 500 milliseconds');
        Observer.Expect('af275|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.4 to System.Int64.');
        Observer.Expect('af275|code', 'ConversionCast');
        Observer.Expect('from dec 1.4', '1 second 500 milliseconds');
        Observer.Expect('from bigint', '24 days 20 hours 31 minutes 23 seconds 648 milliseconds');
        Observer.Expect('neg', '-1 millisecond');
        Observer.Expect('one day', '1 day');
        Observer.Expect('1d1h1m1s1ms', '1 day 1 hour 1 minute 1 second 1 millisecond');
        Observer.Expect('1 ms', '1 millisecond');
        Observer.Expect('1 s', '1 second');
        Observer.Expect('1 min', '1 minute');
        Observer.Expect('1 h', '1 hour');
        Observer.Expect('365 days', '365 days');
        Observer.Verify();
    end;

    [Test]
    procedure Variant2Date_Time()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
    begin
        V := 20240115D;
        Observer.Observe('v2d date', Format(Variant2Date(V), 0, 9));
        V := 0D;
        Observer.Observe('v2d 0D', Format(Variant2Date(V), 0, 9));
        V := 99991231D;
        Observer.Observe('v2d max', Format(Variant2Date(V), 0, 9));
        V := 123456T;
        Observer.Observe('v2t time', Format(Variant2Time(V), 0, 9));
        V := 0T;
        Observer.Observe('v2t 0T', Format(Variant2Time(V), 0, 9));
        V := 235959.999T;
        Observer.Observe('v2t max', Format(Variant2Time(V), 0, 9));
        V := 123456.789T;
        Observer.Observe('v2t ms', Format(Variant2Time(V), 0, 9));
        Observer.Expect('v2d date', '2024-01-15');
        Observer.Expect('v2d 0D', '');
        Observer.Expect('v2d max', '9999-12-31');
        Observer.Expect('v2t time', '12:34:56');
        Observer.Expect('v2t 0T', '');
        Observer.Expect('v2t max', '23:59:59.999');
        Observer.Expect('v2t ms', '12:34:56.789');
        Observer.Verify();
    end;

    [Test]
    procedure Variant2Date_Time_Errors()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        D: Date;
        T: Time;
    begin
        V := 'abc';
        asserterror D := Variant2Date(V);
        Observer.ObserveError('text to date');
        V := 5;
        asserterror D := Variant2Date(V);
        Observer.ObserveError('integer to date');
        V := 123456T;
        asserterror D := Variant2Date(V);
        Observer.ObserveError('time to date');
        V := CreateDateTime(20240115D, 120000T);
        D := Variant2Date(V);
        Observer.Observe('datetime to date', 'no error');
        V := 'abc';
        asserterror T := Variant2Time(V);
        Observer.ObserveError('text to time');
        V := 20240115D;
        asserterror T := Variant2Time(V);
        Observer.ObserveError('date to time');
        V := 5;
        asserterror T := Variant2Time(V);
        Observer.ObserveError('integer to time');
        V := CreateDateTime(20240115D, 120000T);
        T := Variant2Time(V);
        Observer.Observe('datetime to time', 'no error');
        D := Variant2Date(V);
        Observer.Observe('empty variant to date', 'no error');
        Clear(V);
        asserterror D := Variant2Date(V);
        Observer.ObserveError('cleared variant to date');
        asserterror T := Variant2Time(V);
        Observer.ObserveError('cleared variant to time');
        Observer.Expect('text to date|text', 'The supplied object is not of type Microsoft.Dynamics.Nav.Runtime.NavDate.');
        Observer.Expect('text to date|code', 'InvalidType');
        Observer.Expect('integer to date|text', 'The supplied object is not of type Microsoft.Dynamics.Nav.Runtime.NavDate.');
        Observer.Expect('integer to date|code', 'InvalidType');
        Observer.Expect('time to date|text', 'The supplied object is not of type Microsoft.Dynamics.Nav.Runtime.NavDate.');
        Observer.Expect('time to date|code', 'InvalidType');
        Observer.Expect('datetime to date', 'no error');
        Observer.Expect('text to time|text', 'The supplied object is not of type Microsoft.Dynamics.Nav.Runtime.NavTime.');
        Observer.Expect('text to time|code', 'InvalidType');
        Observer.Expect('date to time|text', 'The supplied object is not of type Microsoft.Dynamics.Nav.Runtime.NavTime.');
        Observer.Expect('date to time|code', 'InvalidType');
        Observer.Expect('integer to time|text', 'The supplied object is not of type Microsoft.Dynamics.Nav.Runtime.NavTime.');
        Observer.Expect('integer to time|code', 'InvalidType');
        Observer.Expect('datetime to time', 'no error');
        Observer.Expect('empty variant to date', 'no error');
        Observer.Expect('cleared variant to date|text', 'The supplied object is not of type Microsoft.Dynamics.Nav.Runtime.NavDate.');
        Observer.Expect('cleared variant to date|code', 'InvalidType');
        Observer.Expect('cleared variant to time|text', 'The supplied object is not of type Microsoft.Dynamics.Nav.Runtime.NavTime.');
        Observer.Expect('cleared variant to time|code', 'InvalidType');
        Observer.Verify();
    end;

    // Corpus issue 672 (odd AL behavior leads, part G), item 34: a Time variable left at its default against 0T and 000000T,
    // and what Evaluate of '00:00:00' gives. Item 35: 0T - 0T.
    [Test]
    procedure LT_BU_Time_DefaultAgainst0TAndMidnight()
    var
        Observer: Codeunit "Probe Observer";
        Time1: Time;
        Evaluated: Time;
        Ok: Boolean;
    begin
        Observer.Observe('default = 0T', Format(Time1 = 0T));
        Observer.Observe('default = 000000T', Format(Time1 = 000000T));
        Observer.Observe('default <> 0T', Format(Time1 <> 0T));
        Observer.Observe('default <> 000000T', Format(Time1 <> 000000T));
        Observer.Observe('0T <> 000000T', Format(0T <> 000000T));
        Observer.Observe('default format', '[' + Format(Time1) + ']');
        Observer.Observe('midnight format', '[' + Format(000000T) + ']');
        Ok := Evaluate(Evaluated, '00:00:00');
        Observer.Observe('evaluate 00:00:00 ok', Format(Ok));
        Observer.Observe('evaluate 00:00:00 = 0T', Format(Evaluated = 0T));
        Observer.Observe('evaluate 00:00:00 = 000000T', Format(Evaluated = 000000T));
        Ok := Evaluate(Evaluated, '');
        Observer.Observe('evaluate empty ok', Format(Ok));
        Observer.Observe('evaluate empty = 0T', Format(Evaluated = 0T));
        Time1 := 000000T;
        Observer.Observe('assigned midnight = 0T', Format(Time1 = 0T));
        Time1 := 0T;
        Observer.Observe('assigned 0T = 000000T', Format(Time1 = 000000T));
        ClearLastError();
        if TryTimeDifference(0T, 0T, Ok) then
            Observer.Observe('0T - 0T', 'no error')
        else
            Observer.Observe('0T - 0T', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('default = 0T', 'Yes');
        Observer.Expect('default = 000000T', 'No');
        Observer.Expect('default <> 0T', 'No');
        Observer.Expect('default <> 000000T', 'Yes');
        Observer.Expect('0T <> 000000T', 'Yes');
        Observer.Expect('default format', '[]');
        Observer.Expect('midnight format', '[12:00:00 AM]');
        Observer.Expect('evaluate 00:00:00 ok', 'Yes');
        Observer.Expect('evaluate 00:00:00 = 0T', 'No');
        Observer.Expect('evaluate 00:00:00 = 000000T', 'Yes');
        Observer.Expect('evaluate empty ok', 'Yes');
        Observer.Expect('evaluate empty = 0T', 'Yes');
        Observer.Expect('assigned midnight = 0T', 'No');
        Observer.Expect('assigned 0T = 000000T', 'No');
        Observer.Expect('0T - 0T', 'no error');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryTimeDifference(A: Time; B: Time; var Dummy: Boolean)
    var
        D: Integer;
    begin
        D := A - B;
        Dummy := D = 0;
    end;
}
