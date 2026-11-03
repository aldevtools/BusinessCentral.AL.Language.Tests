// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73887, codeunit 73888
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "Date + Decimal, Date - Decimal, Next(Decimal) with a whole number" (Tests-SCM round 2)
// Facts: Date plus and minus a Decimal (whole, fractional, negative, from a division), Record.Next with a Decimal steps argument (whole and fractional, forward and backward)
// BC versions: 29 (27 and 28 by CI)

table 73887 "LT PnF DD Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73888 "LT PnF Date Decimal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryPlus(D: Date; N: Decimal; var R: Date)
    begin
        R := D + N;
    end;

    [TryFunction]
    local procedure TryMinus(D: Date; N: Decimal; var R: Date)
    begin
        R := D - N;
    end;

    local procedure Plus(D: Date; N: Decimal): Text
    var
        R: Date;
    begin
        if TryPlus(D, N, R) then
            exit(Format(R, 0, 9));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Minus(D: Date; N: Decimal): Text
    var
        R: Date;
    begin
        if TryMinus(D, N, R) then
            exit(Format(R, 0, 9));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure DatePlusDecimal()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := DMY2Date(10, 3, 2024);
        Observer.Observe('plus_2', Plus(D, 2));
        Observer.Observe('plus_0', Plus(D, 0));
        Observer.Observe('plus_neg_2', Plus(D, -2));
        Observer.Observe('plus_2_5', Plus(D, 2.5));
        Observer.Observe('plus_3_5', Plus(D, 3.5));
        Observer.Observe('plus_0_4', Plus(D, 0.4));
        Observer.Observe('plus_0_5', Plus(D, 0.5));
        Observer.Observe('plus_1_9', Plus(D, 1.9));
        Observer.Observe('plus_neg_2_5', Plus(D, -2.5));
        Observer.Observe('plus_neg_0_5', Plus(D, -0.5));
        Observer.Observe('plus_2_0', Plus(D, 2.0));
        Observer.Observe('plus_div', Plus(D, 12 / 5));
        Observer.Observe('plus_div_whole', Plus(D, 12 / 4));
        Observer.Expect('plus_2', '2024-03-12');
        Observer.Expect('plus_0', '2024-03-10');
        Observer.Expect('plus_neg_2', '2024-03-08');
        Observer.Expect('plus_2_5', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.|ConversionCast');
        Observer.Expect('plus_3_5', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 3.5 to System.Int32.|ConversionCast');
        Observer.Expect('plus_0_4', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.4 to System.Int32.|ConversionCast');
        Observer.Expect('plus_0_5', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.5 to System.Int32.|ConversionCast');
        Observer.Expect('plus_1_9', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.9 to System.Int32.|ConversionCast');
        Observer.Expect('plus_neg_2_5', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -2.5 to System.Int32.|ConversionCast');
        Observer.Expect('plus_neg_0_5', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -0.5 to System.Int32.|ConversionCast');
        Observer.Expect('plus_2_0', '2024-03-12');
        Observer.Expect('plus_div', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.4 to System.Int32.|ConversionCast');
        Observer.Expect('plus_div_whole', '2024-03-13');
        Observer.Verify();
    end;

    [Test]
    procedure DateMinusDecimal()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := DMY2Date(10, 3, 2024);
        Observer.Observe('minus_2', Minus(D, 2));
        Observer.Observe('minus_neg_2', Minus(D, -2));
        Observer.Observe('minus_2_5', Minus(D, 2.5));
        Observer.Observe('minus_3_5', Minus(D, 3.5));
        Observer.Observe('minus_0_4', Minus(D, 0.4));
        Observer.Observe('minus_0_5', Minus(D, 0.5));
        Observer.Observe('minus_1_9', Minus(D, 1.9));
        Observer.Observe('minus_neg_2_5', Minus(D, -2.5));
        Observer.Observe('minus_whole_div', Minus(D, (D - DMY2Date(1, 3, 2024) + 1) div 2));
        Observer.Expect('minus_2', '2024-03-08');
        Observer.Expect('minus_neg_2', '2024-03-12');
        Observer.Expect('minus_2_5', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -2.5 to System.Int32.|ConversionCast');
        Observer.Expect('minus_3_5', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -3.5 to System.Int32.|ConversionCast');
        Observer.Expect('minus_0_4', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -0.4 to System.Int32.|ConversionCast');
        Observer.Expect('minus_0_5', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -0.5 to System.Int32.|ConversionCast');
        Observer.Expect('minus_1_9', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -1.9 to System.Int32.|ConversionCast');
        Observer.Expect('minus_neg_2_5', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.|ConversionCast');
        Observer.Expect('minus_whole_div', '2024-03-05');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryNext(var Row: Record "LT PnF DD Row"; Steps: Decimal; var Moved: Integer)
    begin
        Moved := Row.Next(Steps);
    end;

    local procedure NextBy(Steps: Decimal; Start: Integer; var Row: Record "LT PnF DD Row"): Text
    var
        Moved: Integer;
    begin
        Row.Get(Start);
        if TryNext(Row, Steps, Moved) then
            exit(Format(Moved) + '|' + Format(Row.Id));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Next_Decimal_Whole()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF DD Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 10 do begin
            Row.Id := i;
            Row.Insert();
        end;
        Observer.Observe('next_1', NextBy(1, 3, Row));
        Observer.Observe('next_2', NextBy(2, 3, Row));
        Observer.Observe('next_neg_1', NextBy(-1, 5, Row));
        Observer.Observe('next_neg_2', NextBy(-2, 5, Row));
        Observer.Observe('next_div', NextBy(12 / 4, 2, Row));
        Observer.Observe('next_0', NextBy(0, 4, Row));
        Observer.Observe('next_past_end', NextBy(20, 5, Row));
        Observer.Expect('next_1', '1|4');
        Observer.Expect('next_2', '2|5');
        Observer.Expect('next_neg_1', '-1|4');
        Observer.Expect('next_neg_2', '-2|3');
        Observer.Expect('next_div', '3|5');
        Observer.Expect('next_0', '0|4');
        Observer.Expect('next_past_end', '5|10');
        Observer.Verify();
    end;

    [Test]
    procedure Next_Decimal_Fraction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF DD Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 10 do begin
            Row.Id := i;
            Row.Insert();
        end;
        Observer.Observe('next_1_5', NextBy(1.5, 3, Row));
        Observer.Observe('next_neg_1_5', NextBy(-1.5, 6, Row));
        Observer.Observe('next_2_5', NextBy(2.5, 3, Row));
        Observer.Observe('next_0_4', NextBy(0.4, 3, Row));
        Observer.Observe('next_0_5', NextBy(0.5, 3, Row));
        Observer.Observe('next_1_9', NextBy(1.9, 3, Row));
        Observer.Observe('next_neg_0_5', NextBy(-0.5, 6, Row));
        Observer.Expect('next_1_5', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.5 to System.Int32.|ConversionCast');
        Observer.Expect('next_neg_1_5', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -1.5 to System.Int32.|ConversionCast');
        Observer.Expect('next_2_5', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.|ConversionCast');
        Observer.Expect('next_0_4', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.4 to System.Int32.|ConversionCast');
        Observer.Expect('next_0_5', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.5 to System.Int32.|ConversionCast');
        Observer.Expect('next_1_9', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.9 to System.Int32.|ConversionCast');
        Observer.Expect('next_neg_0_5', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -0.5 to System.Int32.|ConversionCast');
        Observer.Verify();
    end;
}
