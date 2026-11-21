// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/biginteger/biginteger-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 27.5 service tier (Windows); every literal asserted below is what BC produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the "/" quotient of a 19-digit BigInteger (9223372036854775807, 4611686018427387905) or a 19-digit Duration by an Integer, a BigInteger, a
//   Decimal and a Duration: the Format(.., 0, 9) text, or the Decimal range error text and code; div and mod as controls; 18-digit controls; and
//   Format of a Duration at and past 922337203685477 milliseconds.
// Results (BC 27.5): 9223372036854775807 / 2 (Integer, BigInteger, Decimal or
//   Duration divisor) raises the Decimal range error with the current value 4,611,686,018,427,387,910 (OutsidePermittedRange); / 10000 gives
//   922337203685477.581, / 100000 gives 92233720368547.7581. div and mod stay exact. Format(Duration, 0, 9) of
//   900000000000000000 ms and of 9223372036854775807 ms raises "Arithmetic operation resulted in an overflow." (AL:Overflow); 1E17 ms formats.
// BC versions: 27.5 measured on a local Windows container (28.5 and 29.0 by the corpus CI matrix on BC on Linux)

codeunit 96387 "FLN Quotient Digits"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Got: Text;

    [Test]
    procedure BigInteger_Quotients_1()
    var
        Observer: Codeunit "Probe Observer";
        N: Integer;
    begin
        for N := 1 to 5 do
            Observer.Observe(CellName(N), Cell(N));
        Observer.Expect('B19 / 2 N=0', 'ERR The value of Decimal parameter  is outside of the permitted range. The current value is: 4,611,686,018,427,387,910. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange');
        Observer.Expect('B19 / 2 N=9', 'ERR The value of Decimal parameter  is outside of the permitted range. The current value is: 4,611,686,018,427,387,910. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange');
        Observer.Expect('-B19 / 2 N=9', 'ERR The value of Decimal parameter  is outside of the permitted range. The current value is: -4,611,686,018,427,387,910. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange');
        Observer.Expect('B19 / 3 N=9', 'ERR The value of Decimal parameter  is outside of the permitted range. The current value is: 3,074,457,345,618,258,600. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange');
        Observer.Expect('B19 / 2.0 N=9', 'ERR The value of Decimal parameter  is outside of the permitted range. The current value is: 4,611,686,018,427,387,910. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange');
        Observer.Verify();
    end;

    [Test]
    procedure BigInteger_Quotients_2()
    var
        Observer: Codeunit "Probe Observer";
        N: Integer;
    begin
        for N := 6 to 10 do
            Observer.Observe(CellName(N), Cell(N));
        Observer.Expect('B19 / 2L N=9', 'ERR The value of Decimal parameter  is outside of the permitted range. The current value is: 4,611,686,018,427,387,910. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange');
        Observer.Expect('B19 / 2 into Decimal N=9', 'ERR The value of Decimal parameter  is outside of the permitted range. The current value is: 4,611,686,018,427,387,910. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange');
        Observer.Expect('H19 / 1 N=9', 'ERR The value of Decimal parameter  is outside of the permitted range. The current value is: 4,611,686,018,427,387,910. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange');
        Observer.Expect('H19 / 7 N=9', 'ERR The value of Decimal parameter  is outside of the permitted range. The current value is: 658,812,288,346,769,701. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange');
        Observer.Expect('E18 / 2 N=9', 'ERR The value of Decimal parameter  is outside of the permitted range. The current value is: 500,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange');
        Observer.Verify();
    end;

    [Test]
    procedure BigInteger_Quotients_InRange_1()
    var
        Observer: Codeunit "Probe Observer";
        N: Integer;
    begin
        for N := 11 to 21 do
            Observer.Observe(CellName(N), Cell(N));
        Observer.Expect('B19 / 10000 N=9', '[922337203685477.581]');
        Observer.Expect('B19 / 10000 N=0', '[922,337,203,685,477.581]');
        Observer.Expect('B19 / 100000 N=9', '[92233720368547.7581]');
        Observer.Expect('H19 / 10000 N=9', '[461168601842738.791]');
        Observer.Expect('E18 / 10000 N=9', '[99999999999999.9999]');
        Observer.Expect('1 / H19 N=9', '[0]');
        Observer.Expect('1000 / B19 N=9', '[0.000000000000000108]');
        Observer.Expect('B19 / H19 N=9', '[2]');
        Observer.Expect('B19 div 2 N=9', '[4611686018427387903]');
        Observer.Expect('B19 mod 2 N=9', '[1]');
        Observer.Expect('Dec := B19, Dec / 10000 N=9', '[922337203685477.581]');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_Quotients_1()
    var
        Observer: Codeunit "Probe Observer";
        N: Integer;
    begin
        for N := 22 to 25 do
            Observer.Observe(CellName(N), Cell(N));
        Observer.Expect('Dur19 / 2 N=9', 'ERR The value of Decimal parameter  is outside of the permitted range. The current value is: 4,611,686,018,427,387,910. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange');
        Observer.Expect('Dur19 / 2 N=0', 'ERR The value of Decimal parameter  is outside of the permitted range. The current value is: 4,611,686,018,427,387,910. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange');
        Observer.Expect('Dur19 / 2L N=9', 'ERR The value of Decimal parameter  is outside of the permitted range. The current value is: 4,611,686,018,427,387,910. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange');
        Observer.Expect('Dur19 / 2.0 N=9', 'ERR The value of Decimal parameter  is outside of the permitted range. The current value is: 4,611,686,018,427,387,910. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_Quotients_2()
    var
        Observer: Codeunit "Probe Observer";
        N: Integer;
    begin
        for N := 26 to 29 do
            Observer.Observe(CellName(N), Cell(N));
        Observer.Expect('Dur19 / Dur2 N=9', 'ERR The value of Decimal parameter  is outside of the permitted range. The current value is: 4,611,686,018,427,387,910. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange');
        Observer.Expect('Dur19 / 3 N=9', 'ERR The value of Decimal parameter  is outside of the permitted range. The current value is: 3,074,457,345,618,258,600. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange');
        Observer.Expect('DurH19 / 7 N=9', 'ERR The value of Decimal parameter  is outside of the permitted range. The current value is: 658,812,288,346,769,701. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange');
        Observer.Expect('DurE18 / 2 N=9', 'ERR The value of Decimal parameter  is outside of the permitted range. The current value is: 500,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_Quotients_InRange_1()
    var
        Observer: Codeunit "Probe Observer";
        N: Integer;
    begin
        for N := 30 to 33 do
            Observer.Observe(CellName(N), Cell(N));
        Observer.Expect('Dur19 / 10000 N=9', '[922337203685477.581]');
        Observer.Expect('DurE18 / DurH19 N=9', '[0.216840434497100886]');
        Observer.Expect('Dur19 / DurH19 N=9', '[2]');
        Observer.Expect('DurE18 / 10000 N=9', '[99999999999999.9999]');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_Format_Range_1()
    var
        Observer: Codeunit "Probe Observer";
        N: Integer;
    begin
        for N := 34 to 38 do
            Observer.Observe(CellName(N), Cell(N));
        Observer.Expect('Format(Dur19, 0, 9)', 'ERR Arithmetic operation resulted in an overflow. | AL:Overflow');
        Observer.Expect('Format(DurE18, 0, 9)', 'ERR Arithmetic operation resulted in an overflow. | AL:Overflow');
        Observer.Expect('Format(DurE18)', 'ERR Arithmetic operation resulted in an overflow. | AL:Overflow');
        Observer.Expect('Format(Dur 922337203685477, 0, 9)', '[P10675199DT2H48M5.477S]');
        Observer.Expect('Format(Dur 922337203685477)', '[10675199 days 2 hours 48 minutes 5 seconds 477 milliseconds]');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_Format_Range_2()
    var
        Observer: Codeunit "Probe Observer";
        N: Integer;
    begin
        for N := 39 to 42 do
            Observer.Observe(CellName(N), Cell(N));
        Observer.Expect('Format(DurMax + 1, 0, 9)', '[922337203685478]');
        Observer.Expect('Format(DurMax + 1)', '[922337203685478]');
        Observer.Expect('Format(DurMax + 1, 10)', '[9223372036]');
        Observer.Expect('Format(-(DurMax + 1), 0, 9)', '[-922337203685478]');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_Format_Range_3()
    var
        Observer: Codeunit "Probe Observer";
        N: Integer;
    begin
        for N := 43 to 50 do
            Observer.Observe(CellName(N), Cell(N));
        Observer.Expect('Format(DurOver 922337203685478, 0, 9)', '[P10675199DT2H48M5.478S]');
        Observer.Expect('Format(DurOver 922337203685478)', '[10675199 days 2 hours 48 minutes 5 seconds 478 milliseconds]');
        Observer.Expect('Format(DurOver 922337203685478, 10)', '[10675199 d]');
        Observer.Expect('Format(DurMax, 10)', '[10675199 d]');
        Observer.Expect('Format(Dur 1E15, 0, 9)', '[P11574074DT1H46M40.0S]');
        Observer.Expect('Format(Dur 1E16, 0, 9)', '[P115740740DT17H46M40.0S]');
        Observer.Expect('Format(Dur 1E17, 0, 9)', '[P1157407407DT9H46M40.0S]');
        Observer.Expect('Format(Dur 9E17, 0, 9)', 'ERR Arithmetic operation resulted in an overflow. | AL:Overflow');
        Observer.Verify();
    end;

    local procedure Cell(N: Integer): Text
    var
        Result: Text;
    begin
        Got := '';
        if TryCell(N) then
            exit('[' + Got + ']');
        Result := 'ERR ' + GetLastErrorText() + ' | ' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    local procedure CellName(N: Integer): Text
    begin
        case N of
            1:
                exit('B19 / 2 N=0');
            2:
                exit('B19 / 2 N=9');
            3:
                exit('-B19 / 2 N=9');
            4:
                exit('B19 / 3 N=9');
            5:
                exit('B19 / 2.0 N=9');
            6:
                exit('B19 / 2L N=9');
            7:
                exit('B19 / 2 into Decimal N=9');
            8:
                exit('H19 / 1 N=9');
            9:
                exit('H19 / 7 N=9');
            10:
                exit('E18 / 2 N=9');
            11:
                exit('B19 / 10000 N=9');
            12:
                exit('B19 / 10000 N=0');
            13:
                exit('B19 / 100000 N=9');
            14:
                exit('H19 / 10000 N=9');
            15:
                exit('E18 / 10000 N=9');
            16:
                exit('1 / H19 N=9');
            17:
                exit('1000 / B19 N=9');
            18:
                exit('B19 / H19 N=9');
            19:
                exit('B19 div 2 N=9');
            20:
                exit('B19 mod 2 N=9');
            21:
                exit('Dec := B19, Dec / 10000 N=9');
            22:
                exit('Dur19 / 2 N=9');
            23:
                exit('Dur19 / 2 N=0');
            24:
                exit('Dur19 / 2L N=9');
            25:
                exit('Dur19 / 2.0 N=9');
            26:
                exit('Dur19 / Dur2 N=9');
            27:
                exit('Dur19 / 3 N=9');
            28:
                exit('DurH19 / 7 N=9');
            29:
                exit('DurE18 / 2 N=9');
            30:
                exit('Dur19 / 10000 N=9');
            31:
                exit('DurE18 / DurH19 N=9');
            32:
                exit('Dur19 / DurH19 N=9');
            33:
                exit('DurE18 / 10000 N=9');
            34:
                exit('Format(Dur19, 0, 9)');
            35:
                exit('Format(DurE18, 0, 9)');
            36:
                exit('Format(DurE18)');
            37:
                exit('Format(Dur 922337203685477, 0, 9)');
            38:
                exit('Format(Dur 922337203685477)');
            39:
                exit('Format(DurMax + 1, 0, 9)');
            40:
                exit('Format(DurMax + 1)');
            41:
                exit('Format(DurMax + 1, 10)');
            42:
                exit('Format(-(DurMax + 1), 0, 9)');
            43:
                exit('Format(DurOver 922337203685478, 0, 9)');
            44:
                exit('Format(DurOver 922337203685478)');
            45:
                exit('Format(DurOver 922337203685478, 10)');
            46:
                exit('Format(DurMax, 10)');
            47:
                exit('Format(Dur 1E15, 0, 9)');
            48:
                exit('Format(Dur 1E16, 0, 9)');
            49:
                exit('Format(Dur 1E17, 0, 9)');
            50:
                exit('Format(Dur 9E17, 0, 9)');
        end;
    end;

    local procedure DivInto(B: BigInteger; Divisor: Integer): Text
    var
        Dec: Decimal;
    begin
        Dec := B / Divisor;
        exit(Format(Dec, 0, 9));
    end;

    [TryFunction]
    local procedure TryCell(N: Integer)
    var
        B19: BigInteger;
        H19: BigInteger;
        E18: BigInteger;
        Dec19: Decimal;
        Dur19: Duration;
        DurH19: Duration;
        DurE18: Duration;
        DurMax: Duration;
        Dur2: Duration;
        DurOver: Duration;
        DurL15: Duration;
        DurL16: Duration;
        DurL17: Duration;
        DurL9E17: Duration;
    begin
        B19 := 9223372036854775807L;
        H19 := 4611686018427387905L;
        E18 := 999999999999999999L;
        Dur19 := B19;
        DurH19 := H19;
        DurE18 := E18;
        DurMax := 922337203685477L;
        Dur2 := 2;
        DurOver := 922337203685478L;
        DurL15 := 1000000000000000L;
        DurL16 := 10000000000000000L;
        DurL17 := 100000000000000000L;
        DurL9E17 := 900000000000000000L;
        case N of
            1:
                begin
                    Got := Format(B19 / 2);
                end;
            2:
                begin
                    Got := Format(B19 / 2, 0, 9);
                end;
            3:
                begin
                    Got := Format(-B19 / 2, 0, 9);
                end;
            4:
                begin
                    Got := Format(B19 / 3, 0, 9);
                end;
            5:
                begin
                    Got := Format(B19 / 2.0, 0, 9);
                end;
            6:
                begin
                    Got := Format(B19 / 2L, 0, 9);
                end;
            7:
                begin
                    Got := DivInto(B19, 2);
                end;
            8:
                begin
                    Got := Format(H19 / 1, 0, 9);
                end;
            9:
                begin
                    Got := Format(H19 / 7, 0, 9);
                end;
            10:
                begin
                    Got := Format(E18 / 2, 0, 9);
                end;
            11:
                begin
                    Got := Format(B19 / 10000, 0, 9);
                end;
            12:
                begin
                    Got := Format(B19 / 10000);
                end;
            13:
                begin
                    Got := Format(B19 / 100000, 0, 9);
                end;
            14:
                begin
                    Got := Format(H19 / 10000, 0, 9);
                end;
            15:
                begin
                    Got := Format(E18 / 10000, 0, 9);
                end;
            16:
                begin
                    Got := Format(1 / H19, 0, 9);
                end;
            17:
                begin
                    Got := Format(1000 / B19, 0, 9);
                end;
            18:
                begin
                    Got := Format(B19 / H19, 0, 9);
                end;
            19:
                begin
                    Got := Format(B19 div 2, 0, 9);
                end;
            20:
                begin
                    Got := Format(B19 mod 2, 0, 9);
                end;
            21:
                begin
                    Dec19 := B19;
                    Got := Format(Dec19 / 10000, 0, 9);
                end;
            22:
                begin
                    Got := Format(Dur19 / 2, 0, 9);
                end;
            23:
                begin
                    Got := Format(Dur19 / 2);
                end;
            24:
                begin
                    Got := Format(Dur19 / 2L, 0, 9);
                end;
            25:
                begin
                    Got := Format(Dur19 / 2.0, 0, 9);
                end;
            26:
                begin
                    Got := Format(Dur19 / Dur2, 0, 9);
                end;
            27:
                begin
                    Got := Format(Dur19 / 3, 0, 9);
                end;
            28:
                begin
                    Got := Format(DurH19 / 7, 0, 9);
                end;
            29:
                begin
                    Got := Format(DurE18 / 2, 0, 9);
                end;
            30:
                begin
                    Got := Format(Dur19 / 10000, 0, 9);
                end;
            31:
                begin
                    Got := Format(DurE18 / DurH19, 0, 9);
                end;
            32:
                begin
                    Got := Format(Dur19 / DurH19, 0, 9);
                end;
            33:
                begin
                    Got := Format(DurE18 / 10000, 0, 9);
                end;
            34:
                begin
                    Got := Format(Dur19, 0, 9);
                end;
            35:
                begin
                    Got := Format(DurE18, 0, 9);
                end;
            36:
                begin
                    Got := Format(DurE18);
                end;
            37:
                begin
                    Got := Format(DurMax, 0, 9);
                end;
            38:
                begin
                    Got := Format(DurMax);
                end;
            39:
                begin
                    Got := Format(DurMax + 1, 0, 9);
                end;
            40:
                begin
                    Got := Format(DurMax + 1);
                end;
            41:
                begin
                    Got := Format(DurMax + 1, 10);
                end;
            42:
                begin
                    Got := Format(-(DurMax + 1), 0, 9);
                end;
            43:
                begin
                    Got := Format(DurOver, 0, 9);
                end;
            44:
                begin
                    Got := Format(DurOver);
                end;
            45:
                begin
                    Got := Format(DurOver, 10);
                end;
            46:
                begin
                    Got := Format(DurMax, 10);
                end;
            47:
                begin
                    Got := Format(DurL15, 0, 9);
                end;
            48:
                begin
                    Got := Format(DurL16, 0, 9);
                end;
            49:
                begin
                    Got := Format(DurL17, 0, 9);
                end;
            50:
                begin
                    Got := Format(DurL9E17, 0, 9);
                end;
        end;
    end;
}
