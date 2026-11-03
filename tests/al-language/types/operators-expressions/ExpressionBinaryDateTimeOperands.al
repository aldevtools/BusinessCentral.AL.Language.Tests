// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-operators-and-expressions
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained test codeunit 72791
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: binary operators over Date, Time, DateTime and Duration operands: comparisons, differences (Date - Date, Time - Time, DateTime - DateTime), sums and products with Duration, and comparisons against the undefined values 0D, 0T, 0DT.
codeunit 72791 "LT Binary DateTime Ops"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P195_Binary_DateOperands()
    var
        Observer: Codeunit "Probe Observer";
        D1: Date;
        D2: Date;
        Diff: Integer;
    begin
        D1 := 20240115D;
        D2 := 20240301D;
        Observer.Observe('eq-same', Format(D1 = 20240115D));
        Observer.Observe('ne', Format(D1 <> D2));
        Observer.Observe('lt', Format(D1 < D2));
        Observer.Observe('gt', Format(D1 > D2));
        Observer.Observe('le-equal', Format(D1 <= 20240115D));
        Observer.Observe('ge', Format(D1 >= D2));
        Diff := D2 - D1;
        Observer.Observe('date-minus-date', Format(Diff));
        Observer.Observe('date-minus-date-reverse', Format(D1 - D2));
        Observer.Observe('date-minus-itself', Format(D1 - D1));
        Observer.Observe('leap-year-diff', Format(20240301D - 20240228D));
        Observer.Observe('year-diff', Format(20250101D - 20240101D));
        Observer.Observe('undefined-lt-defined', Format(0D < D1));
        Observer.Observe('undefined-eq-undefined', Format(0D = 0D));
        asserterror Observer.Observe('undefined-minus-date', Format(0D - D1));
        Observer.ObserveError('af36');
        asserterror Observer.Observe('date-minus-undefined', Format(D1 - 0D));
        Observer.ObserveError('af38');
        Observer.Observe('date-in-range', Format(D1 in [20240101D .. 20240131D]));
        Observer.Observe('date-in-range-undefined-bounds', Format(D1 in [0D .. 20240131D]));
        Observer.Expect('eq-same', 'Yes');
        Observer.Expect('ne', 'Yes');
        Observer.Expect('lt', 'Yes');
        Observer.Expect('gt', 'No');
        Observer.Expect('le-equal', 'Yes');
        Observer.Expect('ge', 'No');
        Observer.Expect('date-minus-date', '46');
        Observer.Expect('date-minus-date-reverse', '-46');
        Observer.Expect('date-minus-itself', '0');
        Observer.Expect('leap-year-diff', '2');
        Observer.Expect('year-diff', '366');
        Observer.Expect('undefined-lt-defined', 'Yes');
        Observer.Expect('undefined-eq-undefined', 'Yes');
        Observer.Expect('af36|text', 'The date is not valid.');
        Observer.Expect('af36|code', 'DateInvalid');
        Observer.Expect('af38|text', 'The date is not valid.');
        Observer.Expect('af38|code', 'DateInvalid');
        Observer.Expect('date-in-range', 'Yes');
        Observer.Expect('date-in-range-undefined-bounds', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P195_Binary_TimeAndDateTimeOperands()
    var
        Observer: Codeunit "Probe Observer";
        T1: Time;
        T2: Time;
        DT1: DateTime;
        DT2: DateTime;
        Diff: Duration;
    begin
        T1 := 100000T;
        T2 := 123000T;
        Observer.Observe('time-eq', Format(T1 = 100000T));
        Observer.Observe('time-lt', Format(T1 < T2));
        Observer.Observe('time-ge', Format(T1 >= T2));
        Diff := T2 - T1;
        Observer.Observe('time-minus-time-ms', Format(Diff, 0, 9));
        Observer.Observe('time-minus-time-reverse-ms', Format(T1 - T2, 0, 9));
        Observer.Observe('undefined-time-lt', Format(0T < T1));
        Observer.Observe('undefined-time-eq', Format(0T = 0T));
        DT1 := CreateDateTime(20240115D, 100000T);
        DT2 := CreateDateTime(20240116D, 100000T);
        Observer.Observe('dt-eq', Format(DT1 = CreateDateTime(20240115D, 100000T)));
        Observer.Observe('dt-lt', Format(DT1 < DT2));
        Observer.Observe('dt-gt', Format(DT1 > DT2));
        Diff := DT2 - DT1;
        Observer.Observe('dt-minus-dt-ms', Format(Diff, 0, 9));
        Observer.Observe('dt-minus-dt-reverse-ms', Format(DT1 - DT2, 0, 9));
        Observer.Observe('dt-plus-duration', Format(DT1 + 3600000, 0, 9));
        Observer.Observe('dt-minus-duration', Format(DT1 - 3600000, 0, 9));
        Observer.Observe('undefined-dt-lt', Format(0DT < DT1));
        Observer.Observe('undefined-dt-eq', Format(0DT = 0DT));
        Observer.Expect('time-eq', 'Yes');
        Observer.Expect('time-lt', 'Yes');
        Observer.Expect('time-ge', 'No');
        Observer.Expect('time-minus-time-ms', 'P0DT2H30M0.0S');
        Observer.Expect('time-minus-time-reverse-ms', '-9000000');
        Observer.Expect('undefined-time-lt', 'Yes');
        Observer.Expect('undefined-time-eq', 'Yes');
        Observer.Expect('dt-eq', 'Yes');
        Observer.Expect('dt-lt', 'Yes');
        Observer.Expect('dt-gt', 'No');
        Observer.Expect('dt-minus-dt-ms', 'P1DT0H0M0.0S');
        Observer.Expect('dt-minus-dt-reverse-ms', '-P1DT0H0M0.0S');
        Observer.Expect('dt-plus-duration', '2024-01-15T11:00:00Z');
        Observer.Expect('dt-minus-duration', '2024-01-15T09:00:00Z');
        Observer.Expect('undefined-dt-lt', 'Yes');
        Observer.Expect('undefined-dt-eq', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P195_Binary_DurationOperands()
    var
        Observer: Codeunit "Probe Observer";
        A: Duration;
        B: Duration;
    begin
        A := 90000;
        B := 30000;
        Observer.Observe('add', Format(A + B, 0, 9));
        Observer.Observe('sub', Format(B - A, 0, 9));
        Observer.Observe('mul-int', Format(A * 2, 0, 9));
        Observer.Observe('slash-int', Format(A / 4, 0, 9));
        Observer.Observe('eq', Format(A = 90000));
        Observer.Observe('ne', Format(A <> B));
        Observer.Observe('lt', Format(B < A));
        Observer.Observe('ge', Format(B >= A));
        Observer.Observe('zero-eq', Format(0 = A - A));
        Observer.Observe('add-int', Format(A + 1000, 0, 9));
        Observer.Expect('add', '120000');
        Observer.Expect('sub', '-60000');
        Observer.Expect('mul-int', '180000');
        Observer.Expect('slash-int', '22500');
        Observer.Expect('eq', 'Yes');
        Observer.Expect('ne', 'Yes');
        Observer.Expect('lt', 'Yes');
        Observer.Expect('ge', 'No');
        Observer.Expect('zero-eq', 'Yes');
        Observer.Expect('add-int', '91000');
        Observer.Verify();
    end;
}
