// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/decimal/decimal-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 73590, helper codeunit 73590, test codeunit 73591
// Probe (AL Runner issues 9267 and 9269): Decimal arithmetic and conversions at the limit of the Decimal type, MAX =
//   79228162514264337593543950335.0 (79228162514264337593543950335, the largest .NET Decimal). Cells: + and - past MAX and -MAX (a
//   variable, a record field, a by-value argument, += and -=), unary minus and Abs at the limit, * past MAX (Decimal times Integer,
//   Decimal, BigInteger; negative operands; a variable operand; values in the middle times a large Integer; the issue's control
//   7922816251426433759354395033.5 * 100), Evaluate, a Variant and JsonValue.AsDecimal of a 30-digit text, BigInteger to Decimal,
//   Round at the limit, a 29-digit literal, and the value a target keeps when the assignment raises.
//   Each cell runs in a TryFunction and records "ok: <result>" or "E: <GetLastErrorText> | <GetLastErrorCode>"; a result outside
//   the range Format accepts (-999,999,999,999,999.99 .. 999,999,999,999,999.99) is shown as 'big <result / 10^15> e15'; an
//   after_ cell records the target's value after the error. A test is named for its group.
//   Already pinned: MAX * 10 raises 'Value was either too large or too small for a Decimal.' (PnBErrorsCollections.al), kept here as
//   the control mul_max_10.
//   Measured on BC 29.0 (Linux, W1, en-US session) with an invented app holding these objects, through the dev endpoint's
//   TestRunnerHub; the values are that run's readings, turned into Expect and Verify by convert.py verbatim. This pull request's CI
//   checks them on 27.5, 28.5 and 29.0; a version difference gets a version guard.
//   Facts (BC 29.0):
//   - The Decimal literal MAX holds 18 significant digits: MAX reads as 79228162514264.3375 e15 (79,228,162,514,264,337,500,000,000,000
//     in the Format error), and so does every value at the limit below (MAX + 1, MAX + 0.5, -(-MAX), Abs(-MAX), Round(MAX, 1 | 10 |
//     0.01), Round(79228162514264337593543950334.6, 1)): + 1, + 0.5 and - 1 at the limit raise nothing. The literal
//     7922816251426433759354395033.5 reads as 7922816251426.43376 e15.
//   - 'Value was either too large or too small for a Decimal.' (AL:Overflow): MAX + MAX and -MAX - MAX (variable, record field,
//     argument, += and -=), and every product past MAX: MAX times 2, 10, -10, an Integer variable of 10 or 3, a Decimal 10, a
//     BigInteger 10; 10 * MAX; -MAX times 10 and -10; the issue's 7922816251426433759354395033.5 * 100; 1E20 * 2147483647;
//     4E19 * 2000000000; 1E19 * 9223372036854775807; 9223372036854775807 (as a Decimal) * 1E10; the 29-digit literal * 10.
//   - A target keeps its value when the assignment raises: R stays 1 after R := MAX * 10 and R := MAX + MAX, a record field stays 1,
//     and D stays MAX after D *= 10 and D += D.
//   - Format(D, 0, 9) raises 'The value of Decimal parameter  is outside of the permitted range. The current value is: <D>. The
//     permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.' (OutsidePermittedRange) for D outside that range
//     (MAX, 1E15); 999999999999999.99 formats. Assigning MAX or -MAX to a record Decimal field raises the same error.
//   - Evaluate of '792281625142643375935439503350', its negative, '1E29' and '79228162514264337593543950335' raises 'The value
//     "<text>" can't be evaluated into type Decimal.' (Evaluate). A Variant holding that 30-digit Text into a Decimal: 'The expression
//     Variant cannot be type-converted to a Decimal value.' (TypeConversion:Overflow). JsonValue.ReadFrom of it, then AsDecimal:
//     'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.Decimal18.'
//     (Conversion). 9223372036854775807 into a Decimal holds 9223.37203685477581 e15.
// BC versions: 27, 28, 29 by CI
table 73590 "LT DOV Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Amount; Decimal) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73590 "LT DOV Probe"
{
    procedure Max(): Decimal
    begin
        exit(79228162514264337593543950335.0);
    end;

    local procedure TakeDec(X: Decimal): Text
    begin
        exit(Show(X));
    end;

    // Format(X, 0, 9) when X is inside -999,999,999,999,999.99 .. 999,999,999,999,999.99 (Format raises
    // OutsidePermittedRange outside it), else 'big ' and X / 10^15 formatted, then ' e15'.
    procedure Show(X: Decimal): Text
    begin
        if (X > 999999999999999.99) or (X < -999999999999999.99) then
            exit('big ' + Format(X / 1000000000000000.0, 0, 9) + ' e15');
        exit(Format(X, 0, 9));
    end;

    [TryFunction]
    local procedure TryCell(Cell: Text; var Result: Text)
    var
        Row: Record "LT DOV Row";
        J: JsonValue;
        V: Variant;
        D: Decimal;
        E: Decimal;
        R: Decimal;
        B: BigInteger;
        N: Integer;
        T: Text;
    begin
        case Cell of
            // R := D + D, D = MAX
            'add_max_max':
                begin
                    D := Max();
                    R := D + D;
                    Result := Show(R);
                end;
            // R := D + 1, D = MAX
            'add_max_1':
                begin
                    D := Max();
                    R := D + 1;
                    Result := Show(R);
                end;
            // R := D + 0.5, D = MAX
            'add_max_half':
                begin
                    D := Max();
                    R := D + 0.5;
                    Result := Show(R);
                end;
            // R := D - E, D = -MAX, E = MAX
            'sub_negmax_max':
                begin
                    D := -Max();
                    E := Max();
                    R := D - E;
                    Result := Show(R);
                end;
            // R := D - 1, D = -MAX
            'sub_negmax_1':
                begin
                    D := -Max();
                    R := D - 1;
                    Result := Show(R);
                end;
            // R := -D, D = MAX
            'neg_max':
                begin
                    D := Max();
                    R := -D;
                    Result := Show(R);
                end;
            // R := -D, D = -MAX
            'neg_negmax':
                begin
                    D := -Max();
                    R := -D;
                    Result := Show(R);
                end;
            // R := Abs(D), D = -MAX
            'abs_negmax':
                begin
                    D := -Max();
                    R := Abs(D);
                    Result := Show(R);
                end;
            // Row.Amount := D + D, D = MAX
            'field_add_max_max':
                begin
                    D := Max();
                    Row.Amount := D + D;
                    Result := Show(Row.Amount);
                end;
            // Row.Amount := D - E, D = -MAX, E = MAX
            'field_sub_negmax_max':
                begin
                    D := -Max();
                    E := Max();
                    Row.Amount := D - E;
                    Result := Show(Row.Amount);
                end;
            // a by-value Decimal argument D + D, D = MAX
            'argument_add_max_max':
                begin
                    D := Max();
                    Result := TakeDec(D + D);
                end;
            // D += E, D = E = MAX
            'plusassign_max_max':
                begin
                    D := Max();
                    E := Max();
                    D += E;
                    Result := Show(D);
                end;
            // D -= E, D = -MAX, E = MAX
            'minusassign_negmax_max':
                begin
                    D := -Max();
                    E := Max();
                    D -= E;
                    Result := Show(D);
                end;
            // Row.Amount += E, Amount = E = MAX
            'field_plusassign_max_max':
                begin
                    Row.Amount := Max();
                    E := Max();
                    Row.Amount += E;
                    Result := Show(Row.Amount);
                end;
            // Row.Amount -= E, Amount = -MAX, E = MAX
            'field_minusassign_negmax_max':
                begin
                    Row.Amount := -Max();
                    E := Max();
                    Row.Amount -= E;
                    Result := Show(Row.Amount);
                end;
            // control (pinned): R := D * 10, D = MAX
            'mul_max_10':
                begin
                    D := Max();
                    R := D * 10;
                    Result := Show(R);
                end;
            // R := D * 2, D = MAX
            'mul_max_2':
                begin
                    D := Max();
                    R := D * 2;
                    Result := Show(R);
                end;
            // the issue's control: D = 7922816251426433759354395033.5, R := D * 100
            'mul_issue_100':
                begin
                    D := 7922816251426433759354395033.5;
                    R := D * 100;
                    Result := Show(R);
                end;
            // D = 1E20, R := D * 2147483647
            'mul_1e20_intmax':
                begin
                    D := 100000000000000000000.0;
                    R := D * 2147483647;
                    Result := Show(R);
                end;
            // D = 4E19, R := D * 2000000000 (8E28)
            'mul_4e19_2e9':
                begin
                    D := 40000000000000000000.0;
                    R := D * 2000000000;
                    Result := Show(R);
                end;
            // R := D * N, D = MAX, N = 10 (an Integer variable)
            'mul_max_var10':
                begin
                    D := Max();
                    N := 10;
                    R := D * N;
                    Result := Show(R);
                end;
            // R := D * N, D = MAX, N = 3
            'mul_max_var3':
                begin
                    D := Max();
                    N := 3;
                    R := D * N;
                    Result := Show(R);
                end;
            // R := D * E, D = MAX, E = 10 (a Decimal)
            'mul_max_dec10':
                begin
                    D := Max();
                    E := 10;
                    R := D * E;
                    Result := Show(R);
                end;
            // R := 10 * D, D = MAX
            'mul_10_max':
                begin
                    D := Max();
                    R := 10 * D;
                    Result := Show(R);
                end;
            // R := D * 10, D = -MAX
            'mul_negmax_10':
                begin
                    D := -Max();
                    R := D * 10;
                    Result := Show(R);
                end;
            // R := D * -10, D = MAX
            'mul_max_neg10':
                begin
                    D := Max();
                    R := D * -10;
                    Result := Show(R);
                end;
            // R := D * -10, D = -MAX
            'mul_negmax_neg10':
                begin
                    D := -Max();
                    R := D * -10;
                    Result := Show(R);
                end;
            // R := D * B, D = MAX, B = 10L
            'mul_max_big10':
                begin
                    D := Max();
                    B := 10;
                    R := D * B;
                    Result := Show(R);
                end;
            // R := D * B, D = 1E19, B = 9223372036854775807
            'mul_1e19_bigmax':
                begin
                    D := 10000000000000000000.0;
                    B := 9223372036854775807L;
                    R := D * B;
                    Result := Show(R);
                end;
            // Row.Amount := D * 10, D = MAX
            'field_mul_max_10':
                begin
                    D := Max();
                    Row.Amount := D * 10;
                    Result := Show(Row.Amount);
                end;
            // a by-value Decimal argument D * 10, D = MAX
            'argument_mul_max_10':
                begin
                    D := Max();
                    Result := TakeDec(D * 10);
                end;
            // Evaluate(D, '792281625142643375935439503350') (statement)
            'evaluate_30digits':
                begin
                    Evaluate(D, '792281625142643375935439503350');
                    Result := Show(D);
                end;
            // Evaluate(D, '-792281625142643375935439503350') (statement)
            'evaluate_neg30digits':
                begin
                    Evaluate(D, '-792281625142643375935439503350');
                    Result := Show(D);
                end;
            // Evaluate(D, '1E29') (statement)
            'evaluate_1e29':
                begin
                    Evaluate(D, '1E29');
                    Result := Show(D);
                end;
            // Evaluate(D, '79228162514264337593543950335') (statement)
            'evaluate_max':
                begin
                    Evaluate(D, '79228162514264337593543950335');
                    Result := Show(D);
                end;
            // D := B, B = 9223372036854775807
            'bigmax_to_dec':
                begin
                    B := 9223372036854775807L;
                    D := B;
                    Result := Show(D);
                end;
            // D := B, then R := D * 10000000000.0
            'bigmax_times_1e10':
                begin
                    B := 9223372036854775807L;
                    D := B;
                    R := D * 10000000000.0;
                    Result := Show(R);
                end;
            // a Variant holding the Text '792281625142643375935439503350' into a Decimal
            'variant_text_30digits':
                begin
                    T := '792281625142643375935439503350';
                    V := T;
                    D := V;
                    Result := Show(D);
                end;
            // JsonValue.ReadFrom('792281625142643375935439503350'), then AsDecimal()
            'json_30digits':
                begin
                    J.ReadFrom('792281625142643375935439503350');
                    D := J.AsDecimal();
                    Result := Show(D);
                end;
            // Round(D, 1), D = MAX
            'round_max_1':
                begin
                    D := Max();
                    R := Round(D, 1);
                    Result := Show(R);
                end;
            // Round(D, 10), D = MAX
            'round_max_10':
                begin
                    D := Max();
                    R := Round(D, 10);
                    Result := Show(R);
                end;
            // Round(D, 0.01), D = MAX
            'round_max_001':
                begin
                    D := Max();
                    R := Round(D, 0.01);
                    Result := Show(R);
                end;
            // Round(D, 1), D = 79228162514264337593543950334.6
            'round_below_max_1':
                begin
                    D := 79228162514264337593543950334.6;
                    R := Round(D, 1);
                    Result := Show(R);
                end;
            // Format of the literal 7922816251426433759354395033.5
            'literal_29digits':
                begin
                    D := 7922816251426433759354395033.5;
                    Result := Show(D);
                end;
            // R := D * 10, D = 7922816251426433759354395033.5
            'literal_29digits_times_10':
                begin
                    D := 7922816251426433759354395033.5;
                    R := D * 10;
                    Result := Show(R);
                end;
            // MAX itself, read through Show
            'max_literal':
                begin
                    D := Max();
                    Result := Show(D);
                end;
            // Format(D, 0, 9) of MAX itself
            'format_max':
                begin
                    D := Max();
                    Result := Format(D, 0, 9);
                end;
            // Format(D, 0, 9), D = 1000000000000000 (one past the permitted range of Format)
            'format_1e15':
                begin
                    D := 1000000000000000.0;
                    Result := Format(D, 0, 9);
                end;
            // Format(D, 0, 9), D = 999999999999999.99
            'format_below_1e15':
                begin
                    D := 999999999999999.99;
                    Result := Format(D, 0, 9);
                end;
        end;
    end;

    procedure Cell(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Result: Text;
        T: Text;
    begin
        ClearLastError();
        if TryCell(Name, Result) then
            T := 'ok: ' + Result
        else
            T := 'E: ' + GetLastErrorText() + ' | ' + GetLastErrorCode();
        ClearLastError();
        Observer.Observe(Name, T);
    end;

    // R := 1; R := D * 10 (D = MAX) raises; R after.
    [TryFunction]
    local procedure Try_after_assign_mul(var R: Decimal)
    var
        D: Decimal;
    begin
        D := Max();
        R := D * 10;
    end;

    // R := 1; R := D + D (D = MAX) raises; R after.
    [TryFunction]
    local procedure Try_after_assign_add(var R: Decimal)
    var
        D: Decimal;
    begin
        D := Max();
        R := D + D;
    end;

    // D := MAX; D *= 10 raises; D after.
    [TryFunction]
    local procedure Try_after_mulassign(var D: Decimal)
    var
    begin
        D *= 10;
    end;

    // D := MAX; D += D raises; D after.
    [TryFunction]
    local procedure Try_after_plusassign(var D: Decimal)
    var
    begin
        D += D;
    end;

    // Row.Amount := 1; Row.Amount := D * 10 raises; Amount after.
    [TryFunction]
    local procedure Try_after_field_mul(var Row: Record "LT DOV Row")
    var
        D: Decimal;
    begin
        D := Max();
        Row.Amount := D * 10;
    end;

    // The after_ cells: the statement raises (or not), then the target's value.
    procedure AfterCell(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Row: Record "LT DOV Row";
        R: Decimal;
        D: Decimal;
        Ok: Boolean;
        T: Text;
    begin
        ClearLastError();
        case Name of
            'after_assign_mul':
                begin
                    R := 1;
                    Ok := Try_after_assign_mul(R);
                    T := Show(R);
                end;
            'after_assign_add':
                begin
                    R := 1;
                    Ok := Try_after_assign_add(R);
                    T := Show(R);
                end;
            'after_mulassign':
                begin
                    D := Max();
                    Ok := Try_after_mulassign(D);
                    T := Show(D);
                end;
            'after_plusassign':
                begin
                    D := Max();
                    Ok := Try_after_plusassign(D);
                    T := Show(D);
                end;
            'after_field_mul':
                begin
                    Row.Amount := 1;
                    Ok := Try_after_field_mul(Row);
                    T := Show(Row.Amount);
                end;
        end;
        if Ok then
            T := 'ok; after ' + T
        else
            T := 'E: ' + GetLastErrorText() + ' | ' + GetLastErrorCode() + '; after ' + T;
        ClearLastError();
        Observer.Observe(Name, T);
    end;
}

codeunit 73591 "LT DOV Overflow Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Add_Cells1()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOV Probe";
    begin
        Probe.Cell(Observer, 'add_max_max');
        Probe.Cell(Observer, 'add_max_1');
        Probe.Cell(Observer, 'add_max_half');
        Probe.Cell(Observer, 'sub_negmax_max');
        Probe.Cell(Observer, 'sub_negmax_1');
        Probe.Cell(Observer, 'neg_max');
        Observer.Expect('add_max_max', 'E: Value was either too large or too small for a Decimal. | AL:Overflow');
        Observer.Expect('add_max_1', 'ok: big 79228162514264.3375 e15');
        Observer.Expect('add_max_half', 'ok: big 79228162514264.3375 e15');
        Observer.Expect('sub_negmax_max', 'E: Value was either too large or too small for a Decimal. | AL:Overflow');
        Observer.Expect('sub_negmax_1', 'ok: big -79228162514264.3375 e15');
        Observer.Expect('neg_max', 'ok: big -79228162514264.3375 e15');
        Observer.Verify();
    end;

    [Test]
    procedure Add_Cells2()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOV Probe";
    begin
        Probe.Cell(Observer, 'neg_negmax');
        Probe.Cell(Observer, 'abs_negmax');
        Probe.Cell(Observer, 'field_add_max_max');
        Probe.Cell(Observer, 'field_sub_negmax_max');
        Probe.Cell(Observer, 'argument_add_max_max');
        Probe.Cell(Observer, 'plusassign_max_max');
        Observer.Expect('neg_negmax', 'ok: big 79228162514264.3375 e15');
        Observer.Expect('abs_negmax', 'ok: big 79228162514264.3375 e15');
        Observer.Expect('field_add_max_max', 'E: Value was either too large or too small for a Decimal. | AL:Overflow');
        Observer.Expect('field_sub_negmax_max', 'E: Value was either too large or too small for a Decimal. | AL:Overflow');
        Observer.Expect('argument_add_max_max', 'E: Value was either too large or too small for a Decimal. | AL:Overflow');
        Observer.Expect('plusassign_max_max', 'E: Value was either too large or too small for a Decimal. | AL:Overflow');
        Observer.Verify();
    end;

    [Test]
    procedure Add_Cells3()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOV Probe";
    begin
        Probe.Cell(Observer, 'minusassign_negmax_max');
        Probe.Cell(Observer, 'field_plusassign_max_max');
        Probe.Cell(Observer, 'field_minusassign_negmax_max');
        Observer.Expect('minusassign_negmax_max', 'E: Value was either too large or too small for a Decimal. | AL:Overflow');
        Observer.Expect('field_plusassign_max_max', 'E: The value of Decimal parameter  is outside of the permitted range. The current value is: 79,228,162,514,264,337,500,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange');
        Observer.Expect('field_minusassign_negmax_max', 'E: The value of Decimal parameter  is outside of the permitted range. The current value is: -79,228,162,514,264,337,500,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange');
        Observer.Verify();
    end;

    [Test]
    procedure Multiply_Cells1()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOV Probe";
    begin
        Probe.Cell(Observer, 'mul_max_10');
        Probe.Cell(Observer, 'mul_max_2');
        Probe.Cell(Observer, 'mul_issue_100');
        Probe.Cell(Observer, 'mul_1e20_intmax');
        Probe.Cell(Observer, 'mul_4e19_2e9');
        Probe.Cell(Observer, 'mul_max_var10');
        Observer.Expect('mul_max_10', 'E: Value was either too large or too small for a Decimal. | AL:Overflow');
        Observer.Expect('mul_max_2', 'E: Value was either too large or too small for a Decimal. | AL:Overflow');
        Observer.Expect('mul_issue_100', 'E: Value was either too large or too small for a Decimal. | AL:Overflow');
        Observer.Expect('mul_1e20_intmax', 'E: Value was either too large or too small for a Decimal. | AL:Overflow');
        Observer.Expect('mul_4e19_2e9', 'E: Value was either too large or too small for a Decimal. | AL:Overflow');
        Observer.Expect('mul_max_var10', 'E: Value was either too large or too small for a Decimal. | AL:Overflow');
        Observer.Verify();
    end;

    [Test]
    procedure Multiply_Cells2()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOV Probe";
    begin
        Probe.Cell(Observer, 'mul_max_var3');
        Probe.Cell(Observer, 'mul_max_dec10');
        Probe.Cell(Observer, 'mul_10_max');
        Probe.Cell(Observer, 'mul_negmax_10');
        Probe.Cell(Observer, 'mul_max_neg10');
        Probe.Cell(Observer, 'mul_negmax_neg10');
        Observer.Expect('mul_max_var3', 'E: Value was either too large or too small for a Decimal. | AL:Overflow');
        Observer.Expect('mul_max_dec10', 'E: Value was either too large or too small for a Decimal. | AL:Overflow');
        Observer.Expect('mul_10_max', 'E: Value was either too large or too small for a Decimal. | AL:Overflow');
        Observer.Expect('mul_negmax_10', 'E: Value was either too large or too small for a Decimal. | AL:Overflow');
        Observer.Expect('mul_max_neg10', 'E: Value was either too large or too small for a Decimal. | AL:Overflow');
        Observer.Expect('mul_negmax_neg10', 'E: Value was either too large or too small for a Decimal. | AL:Overflow');
        Observer.Verify();
    end;

    [Test]
    procedure Multiply_Cells3()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOV Probe";
    begin
        Probe.Cell(Observer, 'mul_max_big10');
        Probe.Cell(Observer, 'mul_1e19_bigmax');
        Probe.Cell(Observer, 'field_mul_max_10');
        Probe.Cell(Observer, 'argument_mul_max_10');
        Observer.Expect('mul_max_big10', 'E: Value was either too large or too small for a Decimal. | AL:Overflow');
        Observer.Expect('mul_1e19_bigmax', 'E: Value was either too large or too small for a Decimal. | AL:Overflow');
        Observer.Expect('field_mul_max_10', 'E: Value was either too large or too small for a Decimal. | AL:Overflow');
        Observer.Expect('argument_mul_max_10', 'E: Value was either too large or too small for a Decimal. | AL:Overflow');
        Observer.Verify();
    end;

    [Test]
    procedure Convert_Cells1()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOV Probe";
    begin
        Probe.Cell(Observer, 'evaluate_30digits');
        Probe.Cell(Observer, 'evaluate_neg30digits');
        Probe.Cell(Observer, 'evaluate_1e29');
        Probe.Cell(Observer, 'evaluate_max');
        Probe.Cell(Observer, 'bigmax_to_dec');
        Probe.Cell(Observer, 'bigmax_times_1e10');
        Observer.Expect('evaluate_30digits', 'E: The value "792281625142643375935439503350" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('evaluate_neg30digits', 'E: The value "-792281625142643375935439503350" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('evaluate_1e29', 'E: The value "1E29" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('evaluate_max', 'E: The value "79228162514264337593543950335" can''t be evaluated into type Decimal. | Evaluate');
        Observer.Expect('bigmax_to_dec', 'ok: big 9223.37203685477581 e15');
        Observer.Expect('bigmax_times_1e10', 'E: Value was either too large or too small for a Decimal. | AL:Overflow');
        Observer.Verify();
    end;

    [Test]
    procedure Convert_Cells2()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOV Probe";
    begin
        Probe.Cell(Observer, 'variant_text_30digits');
        Probe.Cell(Observer, 'json_30digits');
        Probe.Cell(Observer, 'round_max_1');
        Probe.Cell(Observer, 'round_max_10');
        Probe.Cell(Observer, 'round_max_001');
        Probe.Cell(Observer, 'round_below_max_1');
        Observer.Expect('variant_text_30digits', 'E: The expression Variant cannot be type-converted to a Decimal value. | TypeConversion:Overflow');
        Observer.Expect('json_30digits', 'E: Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.Decimal18. | Conversion');
        Observer.Expect('round_max_1', 'ok: big 79228162514264.3375 e15');
        Observer.Expect('round_max_10', 'ok: big 79228162514264.3375 e15');
        Observer.Expect('round_max_001', 'ok: big 79228162514264.3375 e15');
        Observer.Expect('round_below_max_1', 'ok: big 79228162514264.3375 e15');
        Observer.Verify();
    end;

    [Test]
    procedure Convert_Cells3()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOV Probe";
    begin
        Probe.Cell(Observer, 'literal_29digits');
        Probe.Cell(Observer, 'literal_29digits_times_10');
        Probe.Cell(Observer, 'max_literal');
        Probe.Cell(Observer, 'format_max');
        Probe.Cell(Observer, 'format_1e15');
        Probe.Cell(Observer, 'format_below_1e15');
        Observer.Expect('literal_29digits', 'ok: big 7922816251426.43376 e15');
        Observer.Expect('literal_29digits_times_10', 'E: Value was either too large or too small for a Decimal. | AL:Overflow');
        Observer.Expect('max_literal', 'ok: big 79228162514264.3375 e15');
        Observer.Expect('format_max', 'E: The value of Decimal parameter  is outside of the permitted range. The current value is: 79,228,162,514,264,337,500,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange');
        Observer.Expect('format_1e15', 'E: The value of Decimal parameter  is outside of the permitted range. The current value is: 1,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99. | OutsidePermittedRange');
        Observer.Expect('format_below_1e15', 'ok: 999999999999999.99');
        Observer.Verify();
    end;

    // What a target holds after the assignment raised.
    [Test]
    procedure TargetAfterError_Cells()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT DOV Probe";
    begin
        Probe.AfterCell(Observer, 'after_assign_mul');
        Probe.AfterCell(Observer, 'after_assign_add');
        Probe.AfterCell(Observer, 'after_mulassign');
        Probe.AfterCell(Observer, 'after_plusassign');
        Probe.AfterCell(Observer, 'after_field_mul');
        Observer.Expect('after_assign_mul', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('after_assign_add', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Expect('after_mulassign', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after big 79228162514264.3375 e15');
        Observer.Expect('after_plusassign', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after big 79228162514264.3375 e15');
        Observer.Expect('after_field_mul', 'E: Value was either too large or too small for a Decimal. | AL:Overflow; after 1');
        Observer.Verify();
    end;
}
