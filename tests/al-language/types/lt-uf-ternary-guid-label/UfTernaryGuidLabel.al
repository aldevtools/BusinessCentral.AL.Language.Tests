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
        MyKey := false ? KeyId : PlainLbl;
        Observer.Observe('false plain label', MyKey);
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Other := 'other text';
        OtherCode := 'OTHERCODE';
        MyKey := true ? KeyId : Other;
        Observer.Observe('guid:text true', MyKey);
        MyKey := false ? KeyId : Other;
        Observer.Observe('guid:text false', MyKey);
        MyKey := false ? KeyId : OtherCode;
        Observer.Observe('guid:code false', MyKey);
        MyKey := true ? KeyId : OtherCode;
        Observer.Observe('guid:code true', MyKey);
        MyKey := false ? KeyId : 'literal';
        Observer.Observe('guid:literal false', MyKey);
        MyKey := true ? KeyId : 'literal';
        Observer.Observe('guid:literal true', MyKey);
        MyKey := false ? Other : KeyId;
        Observer.Observe('text:guid false', MyKey);
        Observer.Finish();
    end;
}
