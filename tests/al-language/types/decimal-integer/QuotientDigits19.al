// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/biginteger/biginteger-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: observe form (values not yet asserted).
// Facts: the "/" quotient of a 19-digit BigInteger (9223372036854775807, 4611686018427387905) or a 19-digit Duration by an Integer, a BigInteger, a
//   Decimal and a Duration: the Format(.., 0, 9) text, or the Decimal range error text and code; div and mod as controls; 18-digit controls.
// BC versions: measured locally, checked by the corpus CI matrix

codeunit 96387 "FLN Quotient Digits"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Got: Text;

    [Test]
    procedure BigInteger_Quotients()
    var
        Observer: Codeunit "Probe Observer";
        N: Integer;
    begin
        for N := 1 to 20 do
            Observer.Observe(CellName(N), Cell(N));
        Observer.Finish();
    end;

    [Test]
    procedure Duration_Quotients()
    var
        Observer: Codeunit "Probe Observer";
        N: Integer;
    begin
        for N := 21 to 31 do
            Observer.Observe(CellName(N), Cell(N));
        Observer.Finish();
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
                exit('B19 / 10000 N=9');
            8:
                exit('B19 / 10000 N=0');
            9:
                exit('B19 / 100000 N=9');
            10:
                exit('H19 / 1 N=9');
            11:
                exit('H19 / 7 N=9');
            12:
                exit('H19 / 10000 N=9');
            13:
                exit('1 / H19 N=9');
            14:
                exit('B19 / H19 N=9');
            15:
                exit('B19 div 2 N=9');
            16:
                exit('B19 mod 2 N=9');
            17:
                exit('E18 / 2 N=9');
            18:
                exit('E18 / 10000 N=9');
            19:
                exit('Dec := B19, Dec / 10000 N=9');
            20:
                exit('B19 / 2 into Decimal N=9');
            21:
                exit('Dur19 N=9');
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
                exit('Dur19 / 10000 N=9');
            28:
                exit('Dur19 / 3 N=9');
            29:
                exit('DurE18 / DurH19 N=9');
            30:
                exit('DurH19 / 7 N=9');
            31:
                exit('DurE18 / 2 N=9');
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
        Dur2: Duration;
    begin
        B19 := 9223372036854775807L;
        H19 := 4611686018427387905L;
        E18 := 999999999999999999L;
        Dur2 := 2;
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
                    Got := Format(B19 / 10000, 0, 9);
                end;
            8:
                begin
                    Got := Format(B19 / 10000);
                end;
            9:
                begin
                    Got := Format(B19 / 100000, 0, 9);
                end;
            10:
                begin
                    Got := Format(H19 / 1, 0, 9);
                end;
            11:
                begin
                    Got := Format(H19 / 7, 0, 9);
                end;
            12:
                begin
                    Got := Format(H19 / 10000, 0, 9);
                end;
            13:
                begin
                    Got := Format(1 / H19, 0, 9);
                end;
            14:
                begin
                    Got := Format(B19 / H19, 0, 9);
                end;
            15:
                begin
                    Got := Format(B19 div 2, 0, 9);
                end;
            16:
                begin
                    Got := Format(B19 mod 2, 0, 9);
                end;
            17:
                begin
                    Got := Format(E18 / 2, 0, 9);
                end;
            18:
                begin
                    Got := Format(E18 / 10000, 0, 9);
                end;
            19:
                begin
                    Dec19 := B19;
                    Got := Format(Dec19 / 10000, 0, 9);
                end;
            20:
                begin
                    Got := DivInto(B19, 2);
                end;
            21:
                begin
                    Dur19 := B19;
                    DurH19 := H19;
                    DurE18 := E18;
                    Got := Format(Dur19, 0, 9);
                end;
            22:
                begin
                    Dur19 := B19;
                    DurH19 := H19;
                    DurE18 := E18;
                    Got := Format(Dur19 / 2, 0, 9);
                end;
            23:
                begin
                    Dur19 := B19;
                    DurH19 := H19;
                    DurE18 := E18;
                    Got := Format(Dur19 / 2);
                end;
            24:
                begin
                    Dur19 := B19;
                    DurH19 := H19;
                    DurE18 := E18;
                    Got := Format(Dur19 / 2L, 0, 9);
                end;
            25:
                begin
                    Dur19 := B19;
                    DurH19 := H19;
                    DurE18 := E18;
                    Got := Format(Dur19 / 2.0, 0, 9);
                end;
            26:
                begin
                    Dur19 := B19;
                    DurH19 := H19;
                    DurE18 := E18;
                    Got := Format(Dur19 / Dur2, 0, 9);
                end;
            27:
                begin
                    Dur19 := B19;
                    DurH19 := H19;
                    DurE18 := E18;
                    Got := Format(Dur19 / 10000, 0, 9);
                end;
            28:
                begin
                    Dur19 := B19;
                    DurH19 := H19;
                    DurE18 := E18;
                    Got := Format(Dur19 / 3, 0, 9);
                end;
            29:
                begin
                    Dur19 := B19;
                    DurH19 := H19;
                    DurE18 := E18;
                    Got := Format(DurE18 / DurH19, 0, 9);
                end;
            30:
                begin
                    Dur19 := B19;
                    DurH19 := H19;
                    DurE18 := E18;
                    Got := Format(DurH19 / 7, 0, 9);
                end;
            31:
                begin
                    Dur19 := B19;
                    DurH19 := H19;
                    DurE18 := E18;
                    Got := Format(DurE18 / 2, 0, 9);
                end;
        end;
    end;
}
