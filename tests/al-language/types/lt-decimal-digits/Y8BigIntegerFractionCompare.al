// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/decimal/decimal-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: a BigInteger of 19 digits compared with a Decimal of 19 integer digits and a fraction (al-runtime-rs docs/probes-needed.md, "Decimal
// arithmetic"). Evaluate cannot build such a Decimal (it answers false for '4611686018427387905.5'); JsonValue.AsDecimal and BigInteger arithmetic
// are tried instead. Each step runs in its own TryFunction so the step that raises is visible: the value printed with Format(x, 0, 9), passing the
// Decimal to a Decimal parameter, and the comparisons =, < and > with the BigInteger.
// Probe: written against the BC 29 SaaS sandbox; other BC versions are checked by the corpus CI matrix. Writer Y8 (2026-10-30).

codeunit 91401 "LT Y8 BigInt Fraction Compare"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFormat(var D: Decimal; var Result: Text)
    begin
        Result := Format(D, 0, 9);
    end;

    [TryFunction]
    local procedure TryByValue(D: Decimal)
    begin
    end;

    [TryFunction]
    local procedure TryCompare(var B: BigInteger; var D: Decimal; var Result: Text)
    var
        Eq: Boolean;
        Lt: Boolean;
        Gt: Boolean;
    begin
        Eq := B = D;
        Lt := B < D;
        Gt := B > D;
        Result := 'eq=' + Format(Eq) + ' lt=' + Format(Lt) + ' gt=' + Format(Gt);
    end;

    local procedure Err(): Text
    begin
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    local procedure Steps(var Observer: Codeunit "Probe Observer"; Prefix: Text; B: BigInteger; var D: Decimal)
    var
        Result: Text;
    begin
        if TryFormat(D, Result) then
            Observer.Observe(Prefix + '_format9', Result)
        else
            Observer.Observe(Prefix + '_format9', Err());
        if TryByValue(D) then
            Observer.Observe(Prefix + '_by_value', 'ok')
        else
            Observer.Observe(Prefix + '_by_value', Err());
        if TryCompare(B, D, Result) then
            Observer.Observe(Prefix + '_compare', Result)
        else
            Observer.Observe(Prefix + '_compare', Err());
    end;

    [Test]
    procedure Y8_Evaluate_19Digits_Fraction()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
    begin
        Observer.Observe('eval9_ok', Format(Evaluate(D, '4611686018427387905.5', 9)));
        Observer.Observe('eval_ok', Format(Evaluate(D, '4611686018427387905.5')));
        Observer.Observe('eval9_ok_19_digits_whole', Format(Evaluate(D, '4611686018427387905', 9)));
        Observer.Finish();
    end;

    [Test]
    procedure Y8_Json_19Digits_Fraction()
    var
        Observer: Codeunit "Probe Observer";
        J: JsonValue;
        D: Decimal;
    begin
        J.ReadFrom('4611686018427387905.5');
        D := J.AsDecimal();
        Steps(Observer, 'json', 4611686018427387905L, D);
        Observer.Finish();
    end;

    [Test]
    procedure Y8_BigInteger_Plus_Fraction()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
        B: BigInteger;
    begin
        B := 4611686018427387905L;
        D := B;
        Steps(Observer, 'whole', B, D);
        D := D + 0.5;
        Steps(Observer, 'plus_half', B, D);
        Observer.Finish();
    end;

    [Test]
    procedure Y8_Decimal_Limit_16Digits()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
    begin
        D := 999999999999999.99;
        Steps(Observer, 'max_param', 999999999999999L, D);
        D := 1000000000000000.5;
        Steps(Observer, 'above_param', 1000000000000000L, D);
        Observer.Finish();
    end;
}
