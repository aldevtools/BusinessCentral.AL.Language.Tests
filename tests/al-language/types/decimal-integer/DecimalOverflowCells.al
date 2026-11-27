// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/decimal/decimal-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 73590, helper codeunit 73590, test codeunit 73591
// Probe (AL Runner issues 9267 and 9269): Decimal arithmetic and conversions at the limit of the Decimal type, MAX =
//   79228162514264337593543950335.0 (79228162514264337593543950335, the largest .NET Decimal). Cells: + and - past MAX and -MAX (a
//   variable, a record field, a by-value argument, += and -=), unary minus and Abs at the limit, * past MAX (Decimal times Integer,
//   Decimal, BigInteger; negative operands; a variable operand; values in the middle times a large Integer; the issue's control
//   7922816251426433759354395033.5 * 100), Evaluate, a Variant and JsonValue.AsDecimal of a 30-digit text, BigInteger to Decimal,
//   Round at the limit, a 29-digit literal, and the value a target keeps when the assignment raises.
//   Each cell runs in a TryFunction and records "ok: <Format(result, 0, 9)>" or "E: <GetLastErrorText> | <GetLastErrorCode>"; an
//   after_ cell records the target's value after the error. A test is named for its group.
//   Already pinned: MAX * 10 raises 'Value was either too large or too small for a Decimal.' (PnBErrorsCollections.al), kept here as
//   the control mul_max_10.
//   Observe round: every test ends with Observer.Finish(), which fails the test with the readings (OBSERVE:...); nothing is asserted yet.
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
                    Result := Format(R, 0, 9);
                end;
            // R := D + 1, D = MAX
            'add_max_1':
                begin
                    D := Max();
                    R := D + 1;
                    Result := Format(R, 0, 9);
                end;
            // R := D + 0.5, D = MAX
            'add_max_half':
                begin
                    D := Max();
                    R := D + 0.5;
                    Result := Format(R, 0, 9);
                end;
            // R := D - E, D = -MAX, E = MAX
            'sub_negmax_max':
                begin
                    D := -Max();
                    E := Max();
                    R := D - E;
                    Result := Format(R, 0, 9);
                end;
            // R := D - 1, D = -MAX
            'sub_negmax_1':
                begin
                    D := -Max();
                    R := D - 1;
                    Result := Format(R, 0, 9);
                end;
            // R := -D, D = MAX
            'neg_max':
                begin
                    D := Max();
                    R := -D;
                    Result := Format(R, 0, 9);
                end;
            // R := -D, D = -MAX
            'neg_negmax':
                begin
                    D := -Max();
                    R := -D;
                    Result := Format(R, 0, 9);
                end;
            // R := Abs(D), D = -MAX
            'abs_negmax':
                begin
                    D := -Max();
                    R := Abs(D);
                    Result := Format(R, 0, 9);
                end;
            // Row.Amount := D + D, D = MAX
            'field_add_max_max':
                begin
                    D := Max();
                    Row.Amount := D + D;
                    Result := Format(Row.Amount, 0, 9);
                end;
            // Row.Amount := D - E, D = -MAX, E = MAX
            'field_sub_negmax_max':
                begin
                    D := -Max();
                    E := Max();
                    Row.Amount := D - E;
                    Result := Format(Row.Amount, 0, 9);
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
                    Result := Format(D, 0, 9);
                end;
            // D -= E, D = -MAX, E = MAX
            'minusassign_negmax_max':
                begin
                    D := -Max();
                    E := Max();
                    D -= E;
                    Result := Format(D, 0, 9);
                end;
            // Row.Amount += E, Amount = E = MAX
            'field_plusassign_max_max':
                begin
                    Row.Amount := Max();
                    E := Max();
                    Row.Amount += E;
                    Result := Format(Row.Amount, 0, 9);
                end;
            // Row.Amount -= E, Amount = -MAX, E = MAX
            'field_minusassign_negmax_max':
                begin
                    Row.Amount := -Max();
                    E := Max();
                    Row.Amount -= E;
                    Result := Format(Row.Amount, 0, 9);
                end;
            // control (pinned): R := D * 10, D = MAX
            'mul_max_10':
                begin
                    D := Max();
                    R := D * 10;
                    Result := Format(R, 0, 9);
                end;
            // R := D * 2, D = MAX
            'mul_max_2':
                begin
                    D := Max();
                    R := D * 2;
                    Result := Format(R, 0, 9);
                end;
            // the issue's control: D = 7922816251426433759354395033.5, R := D * 100
            'mul_issue_100':
                begin
                    D := 7922816251426433759354395033.5;
                    R := D * 100;
                    Result := Format(R, 0, 9);
                end;
            // D = 1E20, R := D * 2147483647
            'mul_1e20_intmax':
                begin
                    D := 100000000000000000000.0;
                    R := D * 2147483647;
                    Result := Format(R, 0, 9);
                end;
            // D = 4E19, R := D * 2000000000 (8E28)
            'mul_4e19_2e9':
                begin
                    D := 40000000000000000000.0;
                    R := D * 2000000000;
                    Result := Format(R, 0, 9);
                end;
            // R := D * N, D = MAX, N = 10 (an Integer variable)
            'mul_max_var10':
                begin
                    D := Max();
                    N := 10;
                    R := D * N;
                    Result := Format(R, 0, 9);
                end;
            // R := D * N, D = MAX, N = 3
            'mul_max_var3':
                begin
                    D := Max();
                    N := 3;
                    R := D * N;
                    Result := Format(R, 0, 9);
                end;
            // R := D * E, D = MAX, E = 10 (a Decimal)
            'mul_max_dec10':
                begin
                    D := Max();
                    E := 10;
                    R := D * E;
                    Result := Format(R, 0, 9);
                end;
            // R := 10 * D, D = MAX
            'mul_10_max':
                begin
                    D := Max();
                    R := 10 * D;
                    Result := Format(R, 0, 9);
                end;
            // R := D * 10, D = -MAX
            'mul_negmax_10':
                begin
                    D := -Max();
                    R := D * 10;
                    Result := Format(R, 0, 9);
                end;
            // R := D * -10, D = MAX
            'mul_max_neg10':
                begin
                    D := Max();
                    R := D * -10;
                    Result := Format(R, 0, 9);
                end;
            // R := D * -10, D = -MAX
            'mul_negmax_neg10':
                begin
                    D := -Max();
                    R := D * -10;
                    Result := Format(R, 0, 9);
                end;
            // R := D * B, D = MAX, B = 10L
            'mul_max_big10':
                begin
                    D := Max();
                    B := 10;
                    R := D * B;
                    Result := Format(R, 0, 9);
                end;
            // R := D * B, D = 1E19, B = 9223372036854775807
            'mul_1e19_bigmax':
                begin
                    D := 10000000000000000000.0;
                    B := 9223372036854775807L;
                    R := D * B;
                    Result := Format(R, 0, 9);
                end;
            // Row.Amount := D * 10, D = MAX
            'field_mul_max_10':
                begin
                    D := Max();
                    Row.Amount := D * 10;
                    Result := Format(Row.Amount, 0, 9);
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
                    Result := Format(D, 0, 9);
                end;
            // Evaluate(D, '-792281625142643375935439503350') (statement)
            'evaluate_neg30digits':
                begin
                    Evaluate(D, '-792281625142643375935439503350');
                    Result := Format(D, 0, 9);
                end;
            // Evaluate(D, '1E29') (statement)
            'evaluate_1e29':
                begin
                    Evaluate(D, '1E29');
                    Result := Format(D, 0, 9);
                end;
            // Evaluate(D, '79228162514264337593543950335') (statement)
            'evaluate_max':
                begin
                    Evaluate(D, '79228162514264337593543950335');
                    Result := Format(D, 0, 9);
                end;
            // D := B, B = 9223372036854775807
            'bigmax_to_dec':
                begin
                    B := 9223372036854775807L;
                    D := B;
                    Result := Format(D, 0, 9);
                end;
            // D := B, then R := D * 10000000000.0
            'bigmax_times_1e10':
                begin
                    B := 9223372036854775807L;
                    D := B;
                    R := D * 10000000000.0;
                    Result := Format(R, 0, 9);
                end;
            // a Variant holding the Text '792281625142643375935439503350' into a Decimal
            'variant_text_30digits':
                begin
                    T := '792281625142643375935439503350';
                    V := T;
                    D := V;
                    Result := Format(D, 0, 9);
                end;
            // JsonValue.ReadFrom('792281625142643375935439503350'), then AsDecimal()
            'json_30digits':
                begin
                    J.ReadFrom('792281625142643375935439503350');
                    D := J.AsDecimal();
                    Result := Format(D, 0, 9);
                end;
            // Round(D, 1), D = MAX
            'round_max_1':
                begin
                    D := Max();
                    R := Round(D, 1);
                    Result := Format(R, 0, 9);
                end;
            // Round(D, 10), D = MAX
            'round_max_10':
                begin
                    D := Max();
                    R := Round(D, 10);
                    Result := Format(R, 0, 9);
                end;
            // Round(D, 0.01), D = MAX
            'round_max_001':
                begin
                    D := Max();
                    R := Round(D, 0.01);
                    Result := Format(R, 0, 9);
                end;
            // Round(D, 1), D = 79228162514264337593543950334.6
            'round_below_max_1':
                begin
                    D := 79228162514264337593543950334.6;
                    R := Round(D, 1);
                    Result := Format(R, 0, 9);
                end;
            // Format of the literal 7922816251426433759354395033.5
            'literal_29digits':
                begin
                    D := 7922816251426433759354395033.5;
                    Result := Format(D, 0, 9);
                end;
            // R := D * 10, D = 7922816251426433759354395033.5
            'literal_29digits_times_10':
                begin
                    D := 7922816251426433759354395033.5;
                    R := D * 10;
                    Result := Format(R, 0, 9);
                end;
            // Format of MAX itself
            'max_literal':
                begin
                    D := Max();
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
                    T := Format(R, 0, 9);
                end;
            'after_assign_add':
                begin
                    R := 1;
                    Ok := Try_after_assign_add(R);
                    T := Format(R, 0, 9);
                end;
            'after_mulassign':
                begin
                    D := Max();
                    Ok := Try_after_mulassign(D);
                    T := Format(D, 0, 9);
                end;
            'after_plusassign':
                begin
                    D := Max();
                    Ok := Try_after_plusassign(D);
                    T := Format(D, 0, 9);
                end;
            'after_field_mul':
                begin
                    Row.Amount := 1;
                    Ok := Try_after_field_mul(Row);
                    T := Format(Row.Amount, 0, 9);
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
    procedure Add_Cells()
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
        Probe.Cell(Observer, 'neg_negmax');
        Probe.Cell(Observer, 'abs_negmax');
        Probe.Cell(Observer, 'field_add_max_max');
        Probe.Cell(Observer, 'field_sub_negmax_max');
        Probe.Cell(Observer, 'argument_add_max_max');
        Probe.Cell(Observer, 'plusassign_max_max');
        Probe.Cell(Observer, 'minusassign_negmax_max');
        Probe.Cell(Observer, 'field_plusassign_max_max');
        Probe.Cell(Observer, 'field_minusassign_negmax_max');
        Observer.Finish();
    end;

    [Test]
    procedure Multiply_Cells()
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
        Probe.Cell(Observer, 'mul_max_var3');
        Probe.Cell(Observer, 'mul_max_dec10');
        Probe.Cell(Observer, 'mul_10_max');
        Probe.Cell(Observer, 'mul_negmax_10');
        Probe.Cell(Observer, 'mul_max_neg10');
        Probe.Cell(Observer, 'mul_negmax_neg10');
        Probe.Cell(Observer, 'mul_max_big10');
        Probe.Cell(Observer, 'mul_1e19_bigmax');
        Probe.Cell(Observer, 'field_mul_max_10');
        Probe.Cell(Observer, 'argument_mul_max_10');
        Observer.Finish();
    end;

    [Test]
    procedure Convert_Cells()
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
        Probe.Cell(Observer, 'variant_text_30digits');
        Probe.Cell(Observer, 'json_30digits');
        Probe.Cell(Observer, 'round_max_1');
        Probe.Cell(Observer, 'round_max_10');
        Probe.Cell(Observer, 'round_max_001');
        Probe.Cell(Observer, 'round_below_max_1');
        Probe.Cell(Observer, 'literal_29digits');
        Probe.Cell(Observer, 'literal_29digits_times_10');
        Probe.Cell(Observer, 'max_literal');
        Observer.Finish();
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
        Observer.Finish();
    end;
}
