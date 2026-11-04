// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT VaT Helper (71026), table LT VaT Rec (71027)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
codeunit 71034 "LT VaT Compare"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Variant operands of = <> < + - * / are rejected by the compiler (AL0175), so values are compared after conversion into typed variables.

    [Test]
    procedure Compare_After_Conversion_Numbers()
    var
        Observer: Codeunit "Probe Observer";
        A: Variant;
        B: Variant;
        IA: Integer;
        IB: Integer;
        DA: Decimal;
        DB: Decimal;
        BI: BigInteger;
    begin
        A := 5; B := 5.5;
        IA := A; DB := B; DA := A;
        Observer.Observe('int_eq_dec', Format(DA = DB));
        Observer.Observe('int_lt_dec', Format(DA < DB));
        BI := A; Observer.Observe('bigint_from_int', Format(BI = 5));
        A := 5; B := 5.0;
        DA := A; DB := B;
        Observer.Observe('int_vs_dec_eq', Format(DA = DB));
        IB := B; Observer.Observe('dec_5_0_to_int', Format(IA = IB));
        Observer.Expect('int_eq_dec', 'No');
        Observer.Expect('int_lt_dec', 'Yes');
        Observer.Expect('bigint_from_int', 'Yes');
        Observer.Expect('int_vs_dec_eq', 'Yes');
        Observer.Expect('dec_5_0_to_int', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Compare_After_Conversion_Text()
    var
        Observer: Codeunit "Probe Observer";
        A: Variant;
        B: Variant;
        TA: Text;
        TB: Text;
        C: Code[10];
    begin
        A := 'abc'; B := 'ABC';
        TA := A; TB := B;
        Observer.Observe('text_eq_case', Format(TA = TB));
        Observer.Observe('text_ne_case', Format(TA <> TB));
        A := 'abc'; B := 'abd';
        TA := A; TB := B;
        Observer.Observe('text_lt', Format(TA < TB));
        C := 'ABC'; B := C; TB := B;
        Observer.Observe('code_via_variant_eq_text', Format(TA = TB));
        Observer.Expect('text_eq_case', 'No');
        Observer.Expect('text_ne_case', 'Yes');
        Observer.Expect('text_lt', 'Yes');
        Observer.Expect('code_via_variant_eq_text', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Compare_Format_Of_Variants()
    var
        Observer: Codeunit "Probe Observer";
        A: Variant;
        B: Variant;
    begin
        A := 5; B := 5.0;
        Observer.Observe('format_int_vs_dec', Format(Format(A) = Format(B)));
        A := true; B := true;
        Observer.Observe('format_bool', Format(Format(A) = Format(B)));
        A := DMY2Date(1, 1, 2020); B := DMY2Date(1, 1, 2020);
        Observer.Observe('format_date', Format(Format(A) = Format(B)));
        A := '5'; B := 5;
        Observer.Observe('format_text5_vs_int5', Format(Format(A) = Format(B)));
        Observer.Expect('format_int_vs_dec', 'Yes');
        Observer.Expect('format_bool', 'Yes');
        Observer.Expect('format_date', 'Yes');
        Observer.Expect('format_text5_vs_int5', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Arithmetic_After_Conversion()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        W: Variant;
        I: Integer;
        J: Integer;
        Dec: Decimal;
        Dec2: Decimal;
    begin
        V := 5; W := 3;
        I := V; J := W;
        Observer.Observe('sum', Format(I + J));
        Observer.Observe('div', Format(I / J));
        Dec := V; Dec2 := W;
        Observer.Observe('dec_div', Format(Dec / Dec2));
        V := 5.5; W := 2;
        Dec := V; J := W;
        Observer.Observe('dec_plus_int', Format(Dec + J));
        V := '5'; W := 3;
        I := V;
        Observer.Observe('text_5_to_int', 'no error');
        Observer.Expect('sum', '8');
        Observer.Expect('div', '1.66666666666666667');
        Observer.Expect('dec_div', '1.66666666666666667');
        Observer.Expect('dec_plus_int', '7.5');
        Observer.Expect('text_5_to_int', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure Concat_After_Conversion()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        W: Variant;
        T: Text;
    begin
        V := 'a'; W := 'b';
        T := V; T += Format(W);
        Observer.Observe('text_plus_text', T);
        V := 5; W := 6;
        T := 'x' + Format(V) + Format(W);
        Observer.Observe('formatted_concat', T);
        asserterror T := V;
        Observer.ObserveError('af117');
        Observer.Observe('int_variant_to_text', T);
        V := DMY2Date(1, 1, 2020);
        asserterror T := V;
        Observer.ObserveError('af121');
        Observer.Observe('date_variant_to_text', T);
        Observer.Expect('text_plus_text', 'ab');
        Observer.Expect('formatted_concat', 'x56');
        Observer.Expect('af117|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('af117|code', 'TypeConversion');
        Observer.Expect('int_variant_to_text', 'x56');
        Observer.Expect('af121|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('af121|code', 'TypeConversion');
        Observer.Expect('date_variant_to_text', 'x56');
        Observer.Verify();
    end;
}
