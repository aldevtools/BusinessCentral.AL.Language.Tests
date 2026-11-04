// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71526 "LT P103 Time Guid Max"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P103_TimeSecond()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
        Empty: Time;
    begin
        T := 123456T;
        Observer.Observe('second', Format(T.Second()));
        Observer.Observe('minute', Format(T.Minute()));
        Observer.Observe('hour', Format(T.Hour()));
        T := 000000T;
        Observer.Observe('second_midnight', Format(T.Second()));
        T := 235959T;
        Observer.Observe('second_max', Format(T.Second()));
        T := 120000T;
        Observer.Observe('second_zero', Format(T.Second()));
        T := 120007T;
        Observer.Observe('second_seven', Format(T.Second()));
        T := 120059T;
        Observer.Observe('second_59', Format(T.Second()));
        Observer.Observe('second_undefined', Format(Empty.Second()));
        Observer.Expect('second', '56');
        Observer.Expect('minute', '34');
        Observer.Expect('hour', '12');
        Observer.Expect('second_midnight', '0');
        Observer.Expect('second_max', '59');
        Observer.Expect('second_zero', '0');
        Observer.Expect('second_seven', '7');
        Observer.Expect('second_59', '59');
        Observer.Expect('second_undefined', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P103_GuidCreateStatic()
    var
        Observer: Codeunit "Probe Observer";
        G1: Guid;
        G2: Guid;
        Empty: Guid;
    begin
        G1 := Guid.CreateGuid();
        G2 := Guid.CreateGuid();
        Observer.Observe('g1_not_null', Format(IsNullGuid(G1)));
        Observer.Observe('g2_not_null', Format(IsNullGuid(G2)));
        Observer.Observe('g1_neq_g2', Format(G1 <> G2));
        Observer.Observe('g1_neq_empty', Format(G1 <> Empty));
        Observer.Observe('g1_len', Format(StrLen(Format(G1))));
        Observer.Observe('g1_first_char', CopyStr(Format(G1), 1, 1));
        Observer.Observe('g1_last_char', CopyStr(Format(G1), 38, 1));
        Observer.Observe('g1_dash_pos9', CopyStr(Format(G1), 10, 1));
        Observer.Observe('g1_tostext_len', Format(StrLen(G1.ToText())));
        Observer.Observe('g1_tostext_inv_len', Format(StrLen(G1.ToText(true))));
        Observer.Observe('g1_tostext_noninv_len', Format(StrLen(G1.ToText(false))));
        Observer.Observe('g1_text_uppercase', Format(G1.ToText() = UpperCase(G1.ToText())));
        Observer.Observe('g1_roundtrip', Format(G1 = Guid.CreateGuid()));
        Observer.Observe('g1_same_as_global', Format(IsNullGuid(CreateGuid())));
        Observer.Observe('g1_stable', Format(G1 = G1));
        Observer.Expect('g1_not_null', 'No');
        Observer.Expect('g2_not_null', 'No');
        Observer.Expect('g1_neq_g2', 'Yes');
        Observer.Expect('g1_neq_empty', 'Yes');
        Observer.Expect('g1_len', '38');
        Observer.Expect('g1_first_char', '{');
        Observer.Expect('g1_last_char', '}');
        Observer.Expect('g1_dash_pos9', '-');
        Observer.Expect('g1_tostext_len', '38');
        Observer.Expect('g1_tostext_inv_len', '38');
        Observer.Expect('g1_tostext_noninv_len', '38');
        Observer.Expect('g1_text_uppercase', 'Yes');
        Observer.Expect('g1_roundtrip', 'No');
        Observer.Expect('g1_same_as_global', 'No');
        Observer.Expect('g1_stable', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P103_TextMaxStrLen_Variant()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        T30: Text[30];
        T: Text;
        C10: Code[10];
        C: Code[20];
        I: Integer;
    begin
        V := T30;
        asserterror Observer.Observe('text30', Format(Text.MaxStrLen(V)));
        Observer.ObserveError('af77');
        V := C10;
        asserterror Observer.Observe('code10', Format(Text.MaxStrLen(V)));
        Observer.ObserveError('af80');
        V := C;
        asserterror Observer.Observe('code20', Format(Text.MaxStrLen(V)));
        Observer.ObserveError('af83');
        V := I;
        asserterror Observer.Observe('integer', Format(Text.MaxStrLen(V)));
        Observer.ObserveError('integer_err');
        Clear(V);
        asserterror Observer.Observe('empty_variant', Format(Text.MaxStrLen(V)));
        Observer.ObserveError('empty_variant_err');
        Observer.Observe('direct_t30', Format(Text.MaxStrLen(T30)));
        Observer.Observe('direct_c10', Format(Text.MaxStrLen(C10)));
        Observer.Observe('direct_t', Format(Text.MaxStrLen(T)));
        Observer.Expect('af77|text', 'The contents '''' of MAXSTRLEN parameter number 1 are invalid.');
        Observer.Expect('af77|code', 'Argument');
        Observer.Expect('af80|text', 'The contents '''' of MAXSTRLEN parameter number 1 are invalid.');
        Observer.Expect('af80|code', 'Argument');
        Observer.Expect('af83|text', 'The contents '''' of MAXSTRLEN parameter number 1 are invalid.');
        Observer.Expect('af83|code', 'Argument');
        Observer.Expect('integer_err|text', 'The contents ''0'' of MAXSTRLEN parameter number 1 are invalid.');
        Observer.Expect('integer_err|code', 'Argument');
        Observer.Expect('empty_variant_err|text', 'Microsoft.Dynamics.Nav.Runtime.NavVariant variable not initialized.');
        Observer.Expect('empty_variant_err|code', 'NotInitialized');
        Observer.Expect('direct_t30', '30');
        Observer.Expect('direct_c10', '10');
        Observer.Expect('direct_t', '2147483647');
        Observer.Verify();
    end;
}
