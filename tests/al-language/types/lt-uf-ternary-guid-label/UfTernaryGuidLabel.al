// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods/devenv-ternary-operator
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); test codeunit 90320 (ids 90320-90337 are writer UF)
// Probe (outside issue 6160): `MyKey := UseNewKeys ? KeyId : LegacyKeyLbl;` with a Guid true branch and a Label false branch (Locked Label holding a GUID text), and the
//   other mixes of Guid with Label, Text, Code and a text literal: which branch is converted, the Text/Code result, Format and the null Guid. The Code[N]/Label and Text/Label
//   matrix is in types/TestTernaryContracts.al (writer QW) and types/lt-qx-ternary-sized.
// BC versions: 27-29

codeunit 90320 "LT UF Tern Guid Label"
{
    Subtype = Test;

    var
        KeyLbl: Label '00000000-0000-0000-0000-000000000001', Locked = true;
        PlainLbl: Label 'plain label';

    [Test]
    procedure GuidTrue_LabelFalse_IntoText()
    var
        Observer: Codeunit "Probe Observer";
        KeyId: Guid;
        MyKey: Text;
    begin
        Evaluate(KeyId, '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        MyKey := true ? KeyId : KeyLbl;
        Observer.Observe('true', MyKey);
        MyKey := false ? KeyId : KeyLbl;
        Observer.Observe('false', MyKey);
        Observer.Observe('false len', Format(StrLen(MyKey)));
        Observer.Expect('true', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('false', '{00000000-0000-0000-0000-000000000001}');
        Observer.Expect('false len', '38');
        Observer.Verify();
    end;

    [Test]
    procedure LabelTrue_GuidFalse_IntoText()
    var
        Observer: Codeunit "Probe Observer";
        KeyId: Guid;
        MyKey: Text;
    begin
        Evaluate(KeyId, '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        MyKey := true ? KeyLbl : KeyId;
        Observer.Observe('true', MyKey);
        MyKey := false ? KeyLbl : KeyId;
        Observer.Observe('false', MyKey);
        Observer.Expect('true', '00000000-0000-0000-0000-000000000001');
        Observer.Expect('false', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Verify();
    end;

    [Test]
    procedure GuidTrue_LabelFalse_NullGuidAndFormat()
    var
        Observer: Codeunit "Probe Observer";
        NullId: Guid;
        MyKey: Text;
    begin
        MyKey := true ? NullId : KeyLbl;
        Observer.Observe('null guid true', MyKey);
        Observer.Observe('format true', Format(true ? NullId : KeyLbl));
        Observer.Observe('format false', Format(false ? NullId : KeyLbl));
        Observer.Observe('len false', Format(StrLen(false ? NullId : KeyLbl)));
        Observer.Expect('null guid true', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('format true', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('format false', '{00000000-0000-0000-0000-000000000001}');
        Observer.Expect('len false', '38');
        Observer.Verify();
    end;

    [Test]
    procedure GuidTrue_LabelFalse_IntoCodeAndVariant()
    var
        Observer: Codeunit "Probe Observer";
        KeyId: Guid;
        MyCode: Code[50];
        V: Variant;
    begin
        Evaluate(KeyId, '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        MyCode := true ? KeyId : KeyLbl;
        Observer.Observe('code true', MyCode);
        MyCode := false ? KeyId : KeyLbl;
        Observer.Observe('code false', MyCode);
        V := true ? KeyId : KeyLbl;
        Observer.Observe('variant true is guid', Format(V.IsGuid()));
        Observer.Observe('variant true is text', Format(V.IsText()));
        V := false ? KeyId : KeyLbl;
        Observer.Observe('variant false is guid', Format(V.IsGuid()));
        Observer.Observe('variant false is text', Format(V.IsText()));
        Observer.Expect('code true', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('code false', '{00000000-0000-0000-0000-000000000001}');
        Observer.Expect('variant true is guid', 'Yes');
        Observer.Expect('variant true is text', 'No');
        Observer.Expect('variant false is guid', 'Yes');
        Observer.Expect('variant false is text', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure GuidTrue_TextAndLiteralFalse()
    var
        Observer: Codeunit "Probe Observer";
        KeyId: Guid;
        Other: Text;
        OtherCode: Code[40];
        MyKey: Text;
    begin
        Evaluate(KeyId, '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Other := '11111111-2222-3333-4444-555555555555';
        OtherCode := '66666666-7777-8888-9999-000000000000';
        MyKey := true ? KeyId : Other;
        Observer.Observe('guid:text true', MyKey);
        MyKey := false ? KeyId : Other;
        Observer.Observe('guid:text false', MyKey);
        MyKey := false ? KeyId : OtherCode;
        Observer.Observe('guid:code false', MyKey);
        MyKey := true ? KeyId : OtherCode;
        Observer.Observe('guid:code true', MyKey);
        MyKey := false ? KeyId : '11111111-2222-3333-4444-555555555555';
        Observer.Observe('guid:literal false', MyKey);
        MyKey := true ? KeyId : '11111111-2222-3333-4444-555555555555';
        Observer.Observe('guid:literal true', MyKey);
        MyKey := false ? Other : KeyId;
        Observer.Observe('text:guid false', MyKey);
        MyKey := true ? Other : KeyId;
        Observer.Observe('text:guid true', MyKey);
        MyKey := false ? OtherCode : KeyId;
        Observer.Observe('code:guid false', MyKey);
        MyKey := true ? OtherCode : KeyId;
        Observer.Observe('code:guid true', MyKey);
        Observer.Expect('guid:text true', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('guid:text false', '{11111111-2222-3333-4444-555555555555}');
        Observer.Expect('guid:code false', '{66666666-7777-8888-9999-000000000000}');
        Observer.Expect('guid:code true', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('guid:literal false', '{11111111-2222-3333-4444-555555555555}');
        Observer.Expect('guid:literal true', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('text:guid false', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('text:guid true', '11111111-2222-3333-4444-555555555555');
        Observer.Expect('code:guid false', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('code:guid true', '66666666-7777-8888-9999-000000000000');
        Observer.Verify();
    end;

    // The branch that is not a Guid is converted to a Guid, so a text that is no GUID raises on the conversion when that branch is taken; the other branch is not affected.
    [Test]
    procedure GuidTrue_NonGuidTextBranch()
    var
        Observer: Codeunit "Probe Observer";
        KeyId: Guid;
        MyKey: Text;
    begin
        Evaluate(KeyId, '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        MyKey := true ? KeyId : PlainLbl;
        Observer.Observe('guid:plain label true', MyKey);
        asserterror MyKey := false ? KeyId : PlainLbl;
        Observer.ObserveError('guid:plain label false');
        asserterror MyKey := false ? KeyId : 'literal';
        Observer.ObserveError('guid:plain literal false');
        MyKey := false ? PlainLbl : KeyId;
        Observer.Observe('plain label:guid false', MyKey);
        MyKey := true ? PlainLbl : KeyId;
        Observer.Observe('plain label:guid true', MyKey);
        Observer.Expect('guid:plain label true', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('guid:plain label false|text', 'Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('guid:plain label false|code', 'InvalidGuidFormat');
        Observer.Expect('guid:plain literal false|text', 'Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('guid:plain literal false|code', 'InvalidGuidFormat');
        Observer.Expect('plain label:guid false', '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('plain label:guid true', 'plain label');
        Observer.Verify();
    end;
}
