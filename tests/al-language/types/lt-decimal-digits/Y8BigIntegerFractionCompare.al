// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/decimal/decimal-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: a BigInteger of 19 digits compared with a Decimal of 19 integer digits and a fraction (al-runtime-rs docs/probes-needed.md, "Decimal
// arithmetic"). The Decimal is built in several ways (Evaluate with and without format 9, a JSON number, BigInteger plus a fraction) and printed
// with Format(x, 0, 9) first, so the comparison results can be read against the value that was really built.
// Probe: written against the BC 29 SaaS sandbox; other BC versions are checked by the corpus CI matrix. Writer Y8 (2026-10-30).

codeunit 91401 "LT Y8 BigInt Fraction Compare"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Cmp(B: BigInteger; D: Decimal): Text
    begin
        exit(StrSubstNo('eq=%1 lt=%2 gt=%3', B = D, B < D, B > D));
    end;

    [Test]
    procedure Y8_Evaluate_19Digits_Fraction()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
        B: BigInteger;
    begin
        B := 4611686018427387905L;
        Observer.Observe('eval9_ok', Format(Evaluate(D, '4611686018427387905.5', 9)));
        Observer.Observe('eval9_value', Format(D, 0, 9));
        Observer.Observe('eval9_cmp', Cmp(B, D));
        Clear(D);
        Observer.Observe('eval_ok', Format(Evaluate(D, '4611686018427387905.5')));
        Observer.Observe('eval_value', Format(D, 0, 9));
        Clear(D);
        Observer.Observe('eval9_small_fraction_ok', Format(Evaluate(D, '4611686018427387905.25', 9)));
        Observer.Observe('eval9_small_fraction_value', Format(D, 0, 9));
        Observer.Finish();
    end;

    [Test]
    procedure Y8_Json_19Digits_Fraction()
    var
        Observer: Codeunit "Probe Observer";
        J: JsonValue;
        D: Decimal;
        B: BigInteger;
    begin
        B := 4611686018427387905L;
        J.ReadFrom('4611686018427387905.5');
        D := J.AsDecimal();
        Observer.Observe('json_value', Format(D, 0, 9));
        Observer.Observe('json_cmp', Cmp(B, D));
        Observer.Observe('json_cmp_next', Cmp(4611686018427387906L, D));
        Observer.Observe('json_cmp_prev', Cmp(4611686018427387904L, D));
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
        D := D + 0.5;
        Observer.Observe('sum_value', Format(D, 0, 9));
        Observer.Observe('sum_cmp', Cmp(B, D));
        D := B / 2;
        D := D * 2;
        Observer.Observe('half_double_value', Format(D, 0, 9));
        Observer.Observe('half_double_cmp', Cmp(B, D));
        Observer.Finish();
    end;
}
