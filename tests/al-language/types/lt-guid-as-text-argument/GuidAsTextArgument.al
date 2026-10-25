// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); test codeunit 73579
// Probe: written against BC on CI (no local container); every literal asserted below is what the CI tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a Guid passed where a Text is wanted: CopyStr(G, 1, 50), CopyStr(G, 2, 8), StrLen(G), UpperCase(G), LowerCase(G), and
//   Notification.SetData('k', G) followed by GetData('k'). The Guid is a fixed value, so the text form is asserted.
// BC versions: 27, 28, 29 by CI

codeunit 73579 "LT Guid As Text Argument"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";

    local procedure FixedGuid() G: Guid
    begin
        Evaluate(G, '{1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d}');
    end;

    [Test]
    procedure Guid_AsTextArgument_StringFunctions()
    var
        G: Guid;
    begin
        G := FixedGuid();
        Obs.Observe('format', Format(G));
        Obs.Observe('copystr_1_50', CopyStr(G, 1, 50));
        Obs.Observe('copystr_2_8', CopyStr(G, 2, 8));
        Obs.Observe('strlen', Format(StrLen(G)));
        Obs.Observe('uppercase', UpperCase(G));
        Obs.Observe('lowercase', LowerCase(G));
        Obs.Observe('strpos', Format(StrPos(G, '-')));
        Obs.Expect('format', '{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D}');
        Obs.Expect('copystr_1_50', '{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D}');
        Obs.Expect('copystr_2_8', '1A2B3C4D');
        Obs.Expect('strlen', '38');
        Obs.Expect('uppercase', '{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D}');
        Obs.Expect('lowercase', '{1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d}');
        Obs.Expect('strpos', '10');
        Obs.Verify();
    end;

    [Test]
    procedure Guid_AsTextArgument_NullGuidAndCreated()
    var
        Null: Guid;
        Created: Guid;
    begin
        Obs.Observe('null_strlen', Format(StrLen(Null)));
        Obs.Observe('null_copystr', CopyStr(Null, 1, 50));
        Created := CreateGuid();
        Obs.Observe('created_strlen', Format(StrLen(Created)));
        Obs.Observe('created_copystr_len', Format(StrLen(CopyStr(Created, 1, 50))));
        Obs.Observe('created_copystr_equals_format', Format(CopyStr(Created, 1, 50) = Format(Created)));
        Obs.Expect('null_strlen', '38');
        Obs.Expect('null_copystr', '{00000000-0000-0000-0000-000000000000}');
        Obs.Expect('created_strlen', '38');
        Obs.Expect('created_copystr_len', '38');
        Obs.Expect('created_copystr_equals_format', 'Yes');
        Obs.Verify();
    end;

    [Test]
    procedure Guid_AsTextArgument_NotificationData()
    var
        N: Notification;
        G: Guid;
    begin
        G := FixedGuid();
        N.SetData('k', G);
        Obs.Observe('has', Format(N.HasData('k')));
        Obs.Observe('get', N.GetData('k'));
        Obs.Observe('get_equals_format', Format(N.GetData('k') = Format(G)));
        Obs.Expect('has', 'Yes');
        Obs.Expect('get', '{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D}');
        Obs.Expect('get_equals_format', 'Yes');
        Obs.Verify();
    end;

    // Writer SG (al-runtime-rs assumption guid-as-text-argument): a Guid passed to more Text parameters: as the format of StrSubstNo,
    // DelStr, PadStr, ConvertStr, IncStr, SelectStr, InsStr, DelChr, Text.Contains / StartsWith / IndexOf / Replace, and a procedure's Text
    // and Code parameter. Results (BC 27.5, 28.5, 29.0 on CI): every one sees the text form {XXXXXXXX-...} in upper case (IncStr
    // increments its last digit, Contains is case-sensitive); a Text[10] parameter raises StringLengthExceeded.
    local procedure TakeText(T: Text): Text
    begin
        exit('[' + T + ']' + Format(StrLen(T)));
    end;

    local procedure TakeCode(C: Code[50]): Text
    begin
        exit('[' + C + ']' + Format(StrLen(C)));
    end;

    local procedure TakeText10(T: Text[10]): Text
    begin
        exit('[' + T + ']');
    end;

    [TryFunction]
    local procedure TryTakeText10(G: Guid; var R: Text)
    begin
        R := TakeText10(G);
    end;

    [Test]
    procedure Guid_AsTextArgument_MoreStringFunctions()
    var
        G: Guid;
        T: Text;
    begin
        G := FixedGuid();
        Obs.Observe('strsubstno_format', StrSubstNo(G, 'x'));
        Obs.Observe('delstr_1_1', DelStr(G, 1, 1));
        Obs.Observe('delstr_10', DelStr(G, 10));
        Obs.Observe('padstr_40', PadStr(G, 40, '*'));
        Obs.Observe('padstr_5', PadStr(G, 5));
        Obs.Observe('convertstr', ConvertStr(G, 'ABC-', 'xyz_'));
        Obs.Observe('incstr', '[' + IncStr(G) + ']');
        Obs.Observe('selectstr_1', SelectStr(1, G));
        Obs.Observe('insstr', InsStr(G, 'x', 2));
        Obs.Observe('delchr', DelChr(G, '=', '{}-'));
        T := 'k{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D}k';
        Obs.Observe('contains', Format(T.Contains(G)));
        Obs.Observe('contains_lower', Format(LowerCase(T).Contains(G)));
        Obs.Observe('indexof', Format(T.IndexOf(G)));
        Obs.Observe('startswith', Format(T.StartsWith(G)));
        Obs.Observe('replace', T.Replace(G, '#'));
        Obs.Expect('strsubstno_format', '{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D}');
        Obs.Expect('delstr_1_1', '1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D}');
        Obs.Expect('delstr_10', '{1A2B3C4D');
        Obs.Expect('padstr_40', '{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D}**');
        Obs.Expect('padstr_5', '{1A2B');
        Obs.Expect('convertstr', '{1x2y3z4D_5E6F_7x8y_9z0D_1E2F3x4y5z6D}');
        Obs.Expect('incstr', '[{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C7D}]');
        Obs.Expect('selectstr_1', '{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D}');
        Obs.Expect('insstr', '{x1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D}');
        Obs.Expect('delchr', '1A2B3C4D5E6F7A8B9C0D1E2F3A4B5C6D');
        Obs.Expect('contains', 'Yes');
        Obs.Expect('contains_lower', 'No');
        Obs.Expect('indexof', '2');
        Obs.Expect('startswith', 'No');
        Obs.Expect('replace', 'k#k');
        Obs.Verify();
    end;

    [Test]
    procedure Guid_AsTextArgument_ProcedureParameters()
    var
        G: Guid;
        Null: Guid;
        R: Text;
    begin
        G := FixedGuid();
        Obs.Observe('text_param', TakeText(G));
        Obs.Observe('code_param', TakeCode(G));
        Obs.Observe('null_text_param', TakeText(Null));
        ClearLastError();
        Obs.Observe('text10_ok', Format(TryTakeText10(G, R)));
        Obs.Observe('text10_r', R);
        Obs.Observe('text10_err', GetLastErrorText());
        Obs.Observe('text10_code', GetLastErrorCode());
        Obs.Expect('text_param', '[{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D}]38');
        Obs.Expect('code_param', '[{1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D}]38');
        Obs.Expect('null_text_param', '[{00000000-0000-0000-0000-000000000000}]38');
        Obs.Expect('text10_ok', 'No');
        Obs.Expect('text10_r', '');
        Obs.Expect('text10_err', 'The length of the string is 38, but it must be less than or equal to 10 characters. Value: {1A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D}');
        Obs.Expect('text10_code', 'StringLengthExceeded');
        Obs.Verify();
    end;
}
