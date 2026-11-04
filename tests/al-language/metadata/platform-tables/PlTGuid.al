// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type
// Scope: in-scope
// Fixtures used: self-contained codeunit 74219; no generated GUID is ever observed, only relations between them and fixed literal GUIDs
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Members: CreateGuid, IsNullGuid, Evaluate to Guid, Format of Guid (format numbers), comparison, Guid in Text/Code conversions.
// BC versions: 29 (27 and 28 by CI)

codeunit 74219 "LT PlT Guid"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure CreateGuid_Relations()
    var
        Observer: Codeunit "Probe Observer";
        A: Guid;
        B: Guid;
    begin
        A := CreateGuid();
        B := CreateGuid();
        Observer.Observe('a_not_null', Format(IsNullGuid(A)));
        Observer.Observe('a_ne_b', Format(A <> B));
        Observer.Observe('a_eq_a', Format(A = A));
        Observer.Observe('len', Format(StrLen(Format(A))));
        Observer.Observe('braces', Format(CopyStr(Format(A), 1, 1) + CopyStr(Format(A), 38, 1)));
        Observer.Observe('dash_positions', Format(CopyStr(Format(A), 10, 1) + CopyStr(Format(A), 15, 1) + CopyStr(Format(A), 20, 1) + CopyStr(Format(A), 25, 1)));
        Observer.Observe('version_nibble', CopyStr(Format(A), 16, 1));
        Observer.Observe('upper_case', Format(Format(A) = UpperCase(Format(A))));
        Observer.Expect('a_not_null', 'No');
        Observer.Expect('a_ne_b', 'Yes');
        Observer.Expect('a_eq_a', 'Yes');
        Observer.Expect('len', '38');
        Observer.Expect('braces', '{}');
        Observer.Expect('dash_positions', '----');
        Observer.Expect('version_nibble', '4');
        Observer.Expect('upper_case', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure NullGuid_Values()
    var
        Observer: Codeunit "Probe Observer";
        Empty: Guid;
        Cleared: Guid;
    begin
        Observer.Observe('default_is_null', Format(IsNullGuid(Empty)));
        Observer.Observe('default_format', Format(Empty));
        Observer.Observe('default_format_0', Format(Empty, 0, 0));
        Observer.Observe('default_format_1', Format(Empty, 0, 1));
        Observer.Observe('default_format_2', Format(Empty, 0, 2));
        Observer.Observe('default_format_3', Format(Empty, 0, 3));
        Observer.Observe('default_format_4', Format(Empty, 0, 4));
        Cleared := CreateGuid();
        Clear(Cleared);
        Observer.Observe('cleared_is_null', Format(IsNullGuid(Cleared)));
        Observer.Observe('cleared_eq_default', Format(Cleared = Empty));
        Observer.Observe('as_text_is_not_empty', Format(Format(Empty) <> ''));
        Observer.Expect('default_is_null', 'Yes');
        Observer.Expect('default_format', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('default_format_0', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('default_format_1', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('default_format_2', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('default_format_3', '00000000000000000000000000000000');
        Observer.Expect('default_format_4', '00000000-0000-0000-0000-000000000000');
        Observer.Expect('cleared_is_null', 'Yes');
        Observer.Expect('cleared_eq_default', 'Yes');
        Observer.Expect('as_text_is_not_empty', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Format_Numbers()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
    begin
        Evaluate(G, '{12345678-ABCD-4EF0-9876-0123456789AB}');
        Observer.Observe('default', Format(G));
        Observer.Observe('format_0', Format(G, 0, 0));
        Observer.Observe('format_1', Format(G, 0, 1));
        Observer.Observe('format_2', Format(G, 0, 2));
        Observer.Observe('format_3', Format(G, 0, 3));
        Observer.Observe('format_4', Format(G, 0, 4));
        Observer.Observe('format_9', Format(G, 0, 9));
        Observer.Observe('format_length_ignored', Format(G, 10, 0));
        Observer.Observe('format_wide_length', Format(G, 50, 0));
        Observer.Expect('default', '{12345678-ABCD-4EF0-9876-0123456789AB}');
        Observer.Expect('format_0', '{12345678-ABCD-4EF0-9876-0123456789AB}');
        Observer.Expect('format_1', '{12345678-ABCD-4EF0-9876-0123456789AB}');
        Observer.Expect('format_2', '{12345678-ABCD-4EF0-9876-0123456789AB}');
        Observer.Expect('format_3', '12345678ABCD4EF098760123456789AB');
        Observer.Expect('format_4', '12345678-ABCD-4EF0-9876-0123456789AB');
        Observer.Expect('format_9', '{12345678-ABCD-4EF0-9876-0123456789AB}');
        Observer.Expect('format_length_ignored', '{12345678-');
        Observer.Expect('format_wide_length', '{12345678-ABCD-4EF0-9876-0123456789AB}            ');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_Forms()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
    begin
        Observer.Observe('braced_ok', Format(Evaluate(G, '{12345678-ABCD-4EF0-9876-0123456789AB}')));
        Observer.Observe('braced_value', Format(G));
        Observer.Observe('plain_ok', Format(Evaluate(G, '12345678-ABCD-4EF0-9876-0123456789AB')));
        Observer.Observe('plain_value', Format(G));
        Observer.Observe('lower_ok', Format(Evaluate(G, '{12345678-abcd-4ef0-9876-0123456789ab}')));
        Observer.Observe('lower_value', Format(G));
        Observer.Observe('nodash_ok', Format(Evaluate(G, '12345678ABCD4EF098760123456789AB')));
        Observer.Observe('nodash_value', Format(G));
        Observer.Observe('parens_ok', Format(Evaluate(G, '(12345678-ABCD-4EF0-9876-0123456789AB)')));
        Observer.Observe('parens_value', Format(G));
        Observer.Observe('braced_nodash_ok', Format(Evaluate(G, '{12345678ABCD4EF098760123456789AB}')));
        Observer.Observe('braced_nodash_value', Format(G));
        Observer.Observe('padded_ok', Format(Evaluate(G, '  {12345678-ABCD-4EF0-9876-0123456789AB}  ')));
        Observer.Observe('padded_value', Format(G));
        Observer.Expect('braced_ok', 'Yes');
        Observer.Expect('braced_value', '{12345678-ABCD-4EF0-9876-0123456789AB}');
        Observer.Expect('plain_ok', 'Yes');
        Observer.Expect('plain_value', '{12345678-ABCD-4EF0-9876-0123456789AB}');
        Observer.Expect('lower_ok', 'Yes');
        Observer.Expect('lower_value', '{12345678-ABCD-4EF0-9876-0123456789AB}');
        Observer.Expect('nodash_ok', 'Yes');
        Observer.Expect('nodash_value', '{12345678-ABCD-4EF0-9876-0123456789AB}');
        Observer.Expect('parens_ok', 'Yes');
        Observer.Expect('parens_value', '{12345678-ABCD-4EF0-9876-0123456789AB}');
        Observer.Expect('braced_nodash_ok', 'No');
        Observer.Expect('braced_nodash_value', '{12345678-ABCD-4EF0-9876-0123456789AB}');
        Observer.Expect('padded_ok', 'Yes');
        Observer.Expect('padded_value', '{12345678-ABCD-4EF0-9876-0123456789AB}');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_Invalid()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
    begin
        G := CreateGuid();
        Observer.Observe('empty_ok', Format(Evaluate(G, '')));
        Observer.Observe('empty_null', Format(IsNullGuid(G)));
        G := CreateGuid();
        Observer.Observe('garbage_ok', Format(Evaluate(G, 'garbage')));
        Observer.Observe('garbage_null', Format(IsNullGuid(G)));
        G := CreateGuid();
        Observer.Observe('short_ok', Format(Evaluate(G, '{12345678-ABCD-4EF0-9876-0123456789A}')));
        Observer.Observe('short_null', Format(IsNullGuid(G)));
        G := CreateGuid();
        Observer.Observe('long_ok', Format(Evaluate(G, '{12345678-ABCD-4EF0-9876-0123456789ABC}')));
        Observer.Observe('long_null', Format(IsNullGuid(G)));
        G := CreateGuid();
        Observer.Observe('nonhex_ok', Format(Evaluate(G, '{1234567G-ABCD-4EF0-9876-0123456789AB}')));
        Observer.Observe('nonhex_null', Format(IsNullGuid(G)));
        G := CreateGuid();
        Observer.Observe('unbalanced_ok', Format(Evaluate(G, '{12345678-ABCD-4EF0-9876-0123456789AB')));
        Observer.Observe('unbalanced_null', Format(IsNullGuid(G)));
        Observer.Expect('empty_ok', 'No');
        Observer.Expect('empty_null', 'No');
        Observer.Expect('garbage_ok', 'No');
        Observer.Expect('garbage_null', 'No');
        Observer.Expect('short_ok', 'No');
        Observer.Expect('short_null', 'No');
        Observer.Expect('long_ok', 'No');
        Observer.Expect('long_null', 'No');
        Observer.Expect('nonhex_ok', 'No');
        Observer.Expect('nonhex_null', 'No');
        Observer.Expect('unbalanced_ok', 'No');
        Observer.Expect('unbalanced_null', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Assignment_FromText()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        T: Text;
    begin
        T := '{12345678-ABCD-4EF0-9876-0123456789AB}';
        G := T;
        Observer.Observe('text_assign', Format(G));
        T := '12345678-ABCD-4EF0-9876-0123456789AB';
        G := T;
        Observer.Observe('text_assign_plain', Format(G));
        T := 'nonsense';
        asserterror G := T;
        Observer.ObserveError('text_assign_invalid');
        T := '';
        G := CreateGuid();
        asserterror G := T;
        Observer.ObserveError('af142');
        Observer.Observe('text_assign_empty_null', Format(IsNullGuid(G)));
        Observer.Expect('text_assign', '{12345678-ABCD-4EF0-9876-0123456789AB}');
        Observer.Expect('text_assign_plain', '{12345678-ABCD-4EF0-9876-0123456789AB}');
        Observer.Expect('text_assign_invalid|text', 'Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('text_assign_invalid|code', 'InvalidGuidFormat');
        Observer.Expect('af142|text', 'Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('af142|code', 'InvalidGuidFormat');
        Observer.Expect('text_assign_empty_null', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Comparison_FixedValues()
    var
        Observer: Codeunit "Probe Observer";
        A: Guid;
        B: Guid;
        C: Guid;
    begin
        Evaluate(A, '{00000000-0000-0000-0000-000000000001}');
        Evaluate(B, '{00000000-0000-0000-0000-000000000002}');
        Evaluate(C, '{00000000-0000-0000-0000-000000000001}');
        Observer.Observe('a_eq_c', Format(A = C));
        Observer.Observe('a_ne_b', Format(A <> B));
        Observer.Observe('a_lt_b', Format(A < B));
        Observer.Observe('a_gt_b', Format(A > B));
        Observer.Observe('a_le_c', Format(A <= C));
        Observer.Observe('a_ge_b', Format(A >= B));
        Evaluate(B, '{10000000-0000-0000-0000-000000000000}');
        Observer.Observe('first_group_decides_lt', Format(A < B));
        Evaluate(B, '{00000000-0000-0000-0001-000000000000}');
        Observer.Observe('fourth_group_vs_last', Format(A < B));
        Evaluate(B, '{00000000-0000-0001-0000-000000000000}');
        Observer.Observe('third_group_vs_last', Format(A < B));
        Observer.Observe('null_lt_a', Format(IsNullGuid(B) or (B > A)));
        Observer.Expect('a_eq_c', 'Yes');
        Observer.Expect('a_ne_b', 'Yes');
        Observer.Expect('a_lt_b', 'Yes');
        Observer.Expect('a_gt_b', 'No');
        Observer.Expect('a_le_c', 'Yes');
        Observer.Expect('a_ge_b', 'No');
        Observer.Expect('first_group_decides_lt', 'Yes');
        Observer.Expect('fourth_group_vs_last', 'Yes');
        Observer.Expect('third_group_vs_last', 'Yes');
        Observer.Expect('null_lt_a', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Guid_InTextAndCode()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        C: Code[50];
        T: Text[50];
        Short: Code[10];
    begin
        G := CreateGuid();
        C := Format(G);
        T := Format(G);
        Observer.Observe('code_len', Format(StrLen(C)));
        Observer.Observe('text_len', Format(StrLen(T)));
        Observer.Observe('roundtrip_equal', Format(Format(G) = T));
        Observer.Observe('roundtrip_eval', Format(Evaluate(G, C)));
        Observer.Observe('stripped_len', Format(StrLen(DelChr(Format(G, 0, 4), '=', '{}-'))));
        Observer.Expect('code_len', '38');
        Observer.Expect('text_len', '38');
        Observer.Expect('roundtrip_equal', 'Yes');
        Observer.Expect('roundtrip_eval', 'Yes');
        Observer.Expect('stripped_len', '32');
        Observer.Verify();
    end;

    [Test]
    procedure Guid_InCollections()
    var
        Observer: Codeunit "Probe Observer";
        A: Guid;
        B: Guid;
        L: List of [Guid];
        D: Dictionary of [Guid, Text];
    begin
        A := CreateGuid();
        B := CreateGuid();
        L.Add(A);
        L.Add(B);
        L.Add(A);
        Observer.Observe('count', Format(L.Count()));
        Observer.Observe('contains_a', Format(L.Contains(A)));
        Observer.Observe('contains_new', Format(L.Contains(CreateGuid())));
        Observer.Observe('index_of_b', Format(L.IndexOf(B)));
        Observer.Observe('last_index_of_a', Format(L.LastIndexOf(A)));
        D.Add(A, 'a');
        D.Add(B, 'b');
        Observer.Observe('dict_a', D.Get(A));
        Observer.Observe('dict_has_new', Format(D.ContainsKey(CreateGuid())));
        asserterror D.Add(A, 'again');
        Observer.ObserveError('dict_duplicate_key');
        Observer.Expect('count', '3');
        Observer.Expect('contains_a', 'Yes');
        Observer.Expect('contains_new', 'No');
        Observer.Expect('index_of_b', '2');
        Observer.Expect('last_index_of_a', '3');
        Observer.Expect('dict_a', 'a');
        Observer.Expect('dict_has_new', 'No');
        Observer.Expect('dict_duplicate_key|text', 'An item with the same key has already been added.');
        Observer.Expect('dict_duplicate_key|code', 'Argument');
        Observer.Verify();
    end;

    [Test]
    procedure Guid_InJsonAndVariant()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        G2: Guid;
        V: Variant;
        Obj: JsonObject;
        Tok: JsonToken;
    begin
        Evaluate(G, '{12345678-ABCD-4EF0-9876-0123456789AB}');
        V := G;
        Observer.Observe('variant_is_guid', Format(V.IsGuid()));
        Observer.Observe('variant_is_text', Format(V.IsText()));
        G2 := V;
        Observer.Observe('variant_back', Format(G2 = G));
        Obj.Add('id', G);
        Obj.Get('id', Tok);
        Observer.Observe('json', Tok.AsValue().AsText());
        Observer.Observe('json_is_value', Format(Tok.IsValue()));
        Observer.Expect('variant_is_guid', 'Yes');
        Observer.Expect('variant_is_text', 'No');
        Observer.Expect('variant_back', 'Yes');
        Observer.Expect('json', '{12345678-ABCD-4EF0-9876-0123456789AB}');
        Observer.Expect('json_is_value', 'Yes');
        Observer.Verify();
    end;
}
