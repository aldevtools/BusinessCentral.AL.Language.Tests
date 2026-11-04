// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 70054
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Guid: IsNullGuid, Format forms, Evaluate, comparison, CreateGuid relations
// BC versions: 29 (27 and 28 by CI)

codeunit 70054 "LT ScT Guid"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryF(V: Variant; N: Integer; var R: Text)
    begin
        R := Format(V, 0, N);
    end;

    local procedure F(V: Variant; N: Integer): Text
    var
        R: Text;
    begin
        if TryF(V, N, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Guid_Default()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        G2: Guid;
    begin
        Observer.Observe('default', Format(G));
        Observer.Observe('isnull', Format(IsNullGuid(G)));
        Observer.Observe('len', Format(StrLen(Format(G))));
        Observer.Observe('eq_default', Format(G = G2));
        Observer.Observe('text_empty', Format(Format(G) = ''));
        Observer.Expect('default', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('isnull', 'Yes');
        Observer.Expect('len', '38');
        Observer.Expect('eq_default', 'Yes');
        Observer.Expect('text_empty', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Guid_CreateGuid()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        G2: Guid;
    begin
        G := CreateGuid();
        G2 := CreateGuid();
        Observer.Observe('isnull', Format(IsNullGuid(G)));
        Observer.Observe('ne', Format(G <> G2));
        Observer.Observe('eq_self', Format(G = G));
        Observer.Observe('len', Format(StrLen(Format(G))));
        Observer.Observe('braces_start', CopyStr(Format(G), 1, 1));
        Observer.Observe('braces_end', CopyStr(Format(G), StrLen(Format(G)), 1));
        Observer.Observe('upper', Format(Format(G) = UpperCase(Format(G))));
        Observer.Observe('dash9', CopyStr(Format(G), 10, 1));
        Observer.Observe('dash14', CopyStr(Format(G), 15, 1));
        Observer.Observe('dash19', CopyStr(Format(G), 20, 1));
        Observer.Observe('dash24', CopyStr(Format(G), 25, 1));
        Observer.Observe('version', CopyStr(Format(G), 16, 1));
        Observer.Expect('isnull', 'No');
        Observer.Expect('ne', 'Yes');
        Observer.Expect('eq_self', 'Yes');
        Observer.Expect('len', '38');
        Observer.Expect('braces_start', '{');
        Observer.Expect('braces_end', '}');
        Observer.Expect('upper', 'Yes');
        Observer.Expect('dash9', '-');
        Observer.Expect('dash14', '-');
        Observer.Expect('dash19', '-');
        Observer.Expect('dash24', '-');
        Observer.Expect('version', '4');
        Observer.Verify();
    end;

    [Test]
    procedure Guid_FormatNumbers()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        n: Integer;
    begin
        Evaluate(G, '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        for n := 0 to 9 do
            Observer.Observe('n' + Format(n), F(G, n));
        Observer.Observe('len10', Format(G, 10));
        Observer.Observe('len50', Format(G, 50));
        Observer.Expect('n0', '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Observer.Expect('n1', '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Observer.Expect('n2', '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Observer.Expect('n3', 'error:Standard format number 3 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n4', 'error:Standard format number 4 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n5', 'error:Standard format number 5 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n6', 'error:Standard format number 6 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n7', 'error:Standard format number 7 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n8', 'error:Standard format number 8 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n9', '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Observer.Expect('len10', '{12345678-');
        Observer.Expect('len50', '{12345678-ABCD-4EF0-9A1B-0123456789AB}            ');
        Observer.Verify();
    end;

    [Test]
    procedure Guid_FormatStrings()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
    begin
        Evaluate(G, '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Observer.Observe('std0', Format(G, 0, '<Standard Format,0>'));
        Observer.Observe('std1', Format(G, 0, '<Standard Format,1>'));
        Observer.Observe('std2', Format(G, 0, '<Standard Format,2>'));
        Observer.Observe('std9', Format(G, 0, '<Standard Format,9>'));
        asserterror Observer.Observe('text', Format(G, 0, 'x'));
        Observer.ObserveError('af79');
        Observer.Observe('lower', LowerCase(Format(G)));
        Observer.Observe('nobraces', DelChr(Format(G), '=', '{}'));
        Observer.Observe('nodash', DelChr(Format(G), '=', '{}-'));
        Observer.Expect('std0', '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Observer.Expect('std1', '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Observer.Expect('std2', '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Observer.Expect('std9', '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Observer.Expect('af79|text', 'Standard format number -1 does not exist for the type ''GUID''.');
        Observer.Expect('af79|code', 'InvalidStandardFormat');
        Observer.Expect('lower', '{12345678-abcd-4ef0-9a1b-0123456789ab}');
        Observer.Expect('nobraces', '12345678-ABCD-4EF0-9A1B-0123456789AB');
        Observer.Expect('nodash', '12345678ABCD4EF09A1B0123456789AB');
        Observer.Verify();
    end;

    [Test]
    procedure Guid_EvaluateValid()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
    begin
        Observer.Observe('braces', Format(Evaluate(G, '{12345678-ABCD-4EF0-9A1B-0123456789AB}')));
        Observer.Observe('braces_v', Format(G));
        Clear(G);
        Observer.Observe('nobraces', Format(Evaluate(G, '12345678-ABCD-4EF0-9A1B-0123456789AB')));
        Observer.Observe('nobraces_v', Format(G));
        Clear(G);
        Observer.Observe('lower', Format(Evaluate(G, '{12345678-abcd-4ef0-9a1b-0123456789ab}')));
        Observer.Observe('lower_v', Format(G));
        Clear(G);
        Observer.Observe('lower_nobr', Format(Evaluate(G, '12345678-abcd-4ef0-9a1b-0123456789ab')));
        Observer.Observe('lower_nobr_v', Format(G));
        Clear(G);
        Observer.Observe('nodash', Format(Evaluate(G, '12345678ABCD4EF09A1B0123456789AB')));
        Observer.Observe('nodash_v', Format(G));
        Clear(G);
        Observer.Observe('nodash_br', Format(Evaluate(G, '{12345678ABCD4EF09A1B0123456789AB}')));
        Observer.Observe('nodash_br_v', Format(G));
        Clear(G);
        Observer.Observe('mixed', Format(Evaluate(G, '{12345678-aBcD-4Ef0-9A1b-0123456789aB}')));
        Observer.Observe('mixed_v', Format(G));
        Clear(G);
        Observer.Observe('null', Format(Evaluate(G, '{00000000-0000-0000-0000-000000000000}')));
        Observer.Observe('null_isnull', Format(IsNullGuid(G)));
        Observer.Expect('braces', 'Yes');
        Observer.Expect('braces_v', '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Observer.Expect('nobraces', 'Yes');
        Observer.Expect('nobraces_v', '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Observer.Expect('lower', 'Yes');
        Observer.Expect('lower_v', '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Observer.Expect('lower_nobr', 'Yes');
        Observer.Expect('lower_nobr_v', '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Observer.Expect('nodash', 'Yes');
        Observer.Expect('nodash_v', '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Observer.Expect('nodash_br', 'No');
        Observer.Expect('nodash_br_v', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('mixed', 'Yes');
        Observer.Expect('mixed_v', '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Observer.Expect('null', 'Yes');
        Observer.Expect('null_isnull', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Guid_EvaluateInvalid()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
    begin
        Observer.Observe('empty', Format(Evaluate(G, '')));
        Observer.Observe('empty_isnull', Format(IsNullGuid(G)));
        Observer.Observe('garbage', Format(Evaluate(G, 'not a guid')));
        Observer.Observe('short', Format(Evaluate(G, '{12345678-ABCD-4EF0-9A1B-0123456789A}')));
        Observer.Observe('long', Format(Evaluate(G, '{12345678-ABCD-4EF0-9A1B-0123456789ABC}')));
        Observer.Observe('nonhex', Format(Evaluate(G, '{1234567G-ABCD-4EF0-9A1B-0123456789AB}')));
        Observer.Observe('open_only', Format(Evaluate(G, '{12345678-ABCD-4EF0-9A1B-0123456789AB')));
        Observer.Observe('close_only', Format(Evaluate(G, '12345678-ABCD-4EF0-9A1B-0123456789AB}')));
        Observer.Observe('spaces', Format(Evaluate(G, ' {12345678-ABCD-4EF0-9A1B-0123456789AB} ')));
        Observer.Observe('parens', Format(Evaluate(G, '(12345678-ABCD-4EF0-9A1B-0123456789AB)')));
        Observer.Observe('blank', Format(Evaluate(G, ' ')));
        Observer.Expect('empty', 'No');
        Observer.Expect('empty_isnull', 'Yes');
        Observer.Expect('garbage', 'No');
        Observer.Expect('short', 'No');
        Observer.Expect('long', 'No');
        Observer.Expect('nonhex', 'No');
        Observer.Expect('open_only', 'No');
        Observer.Expect('close_only', 'No');
        Observer.Expect('spaces', 'Yes');
        Observer.Expect('parens', 'Yes');
        Observer.Expect('blank', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Guid_Comparison()
    var
        Observer: Codeunit "Probe Observer";
        A: Guid;
        B: Guid;
    begin
        Evaluate(A, '{00000000-0000-0000-0000-000000000001}');
        Evaluate(B, '{00000000-0000-0000-0000-000000000002}');
        Observer.Observe('lt', Format(A < B));
        Observer.Observe('gt', Format(A > B));
        Observer.Observe('le', Format(A <= B));
        Observer.Observe('ge', Format(A >= B));
        Observer.Observe('eq', Format(A = B));
        Observer.Observe('ne', Format(A <> B));
        Evaluate(A, '{10000000-0000-0000-0000-000000000000}');
        Evaluate(B, '{01000000-0000-0000-0000-000000000000}');
        Observer.Observe('lt_first', Format(A < B));
        Evaluate(A, '{00000000-0000-0000-0000-100000000000}');
        Evaluate(B, '{00000000-0000-0000-0000-010000000000}');
        Observer.Observe('lt_last', Format(A < B));
        Evaluate(A, '{00000000-0000-0000-0001-000000000000}');
        Evaluate(B, '{00000000-0000-0000-0000-FF0000000000}');
        Observer.Observe('lt_group4', Format(A < B));
        Evaluate(A, '{00000001-0000-0000-0000-000000000000}');
        Evaluate(B, '{00000000-0000-0000-0000-FFFFFFFFFFFF}');
        Observer.Observe('lt_group1', Format(A < B));
        Evaluate(A, '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Evaluate(B, '{12345678-abcd-4ef0-9a1b-0123456789ab}');
        Observer.Observe('case_eq', Format(A = B));
        Observer.Expect('lt', 'Yes');
        Observer.Expect('gt', 'No');
        Observer.Expect('le', 'Yes');
        Observer.Expect('ge', 'No');
        Observer.Expect('eq', 'No');
        Observer.Expect('ne', 'Yes');
        Observer.Expect('lt_first', 'No');
        Observer.Expect('lt_last', 'No');
        Observer.Expect('lt_group4', 'No');
        Observer.Expect('lt_group1', 'No');
        Observer.Expect('case_eq', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Guid_Conversions()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        T: Text;
        Code: Code[50];
    begin
        Evaluate(G, '12345678-abcd-4ef0-9a1b-0123456789ab');
        T := Format(G);
        Observer.Observe('text', T);
        Code := Format(G);
        Observer.Observe('code', Code);
        Observer.Observe('to_text_var', Format(G, 0, 9));
        Observer.Expect('text', '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Observer.Expect('code', '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Observer.Expect('to_text_var', '{12345678-ABCD-4EF0-9A1B-0123456789AB}');
        Observer.Verify();
    end;
}
