// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-option-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 70063
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Defaults of scalar types, Clear, comparison across types, Variant type checks
// BC versions: 29 (27 and 28 by CI)

// Writer BP (corpus issue 664, microsoft/AL issue 6620): a global variable of the type DataScope in a codeunit. It once failed at publish
// ("Normal variable of type DataScope"). A `protected var` section in a codeunit is refused (must-not-compile case 1443).
codeunit 82556 "LT BP DataScope Holder"
{
    var
        MyDataScope: DataScope;

    procedure GetScope(): DataScope
    begin
        exit(MyDataScope);
    end;

    procedure SetScope(NewScope: DataScope)
    begin
        MyDataScope := NewScope;
    end;
}
codeunit 70063 "LT ScT Mixed Defaults"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Defaults_Scalars()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        By: Byte;
        C: Char;
        G: Guid;
        T: Text;
        Cd: Code[10];
    begin
        Observer.Observe('int', Format(I));
        Observer.Observe('big', Format(B));
        Observer.Observe('dec', Format(D));
        Observer.Observe('bool', Format(Bo));
        Observer.Observe('byte', Format(By));
        Observer.Observe('char', Format(C, 0, 2));
        Observer.Observe('guid_null', Format(IsNullGuid(G)));
        Observer.Observe('text_len', Format(StrLen(T)));
        Observer.Observe('code_len', Format(StrLen(Cd)));
        Observer.Expect('int', '0');
        Observer.Expect('big', '0');
        Observer.Expect('dec', '0');
        Observer.Expect('bool', 'No');
        Observer.Expect('byte', '\u0000');
        Observer.Expect('char', '\u0000');
        Observer.Expect('guid_null', 'Yes');
        Observer.Expect('text_len', '0');
        Observer.Expect('code_len', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_Scalars()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        Bo: Boolean;
        By: Byte;
        G: Guid;
    begin
        I := 5;
        Evaluate(B, '5000000000');
        D := 1.5;
        Bo := true;
        By := 9;
        G := CreateGuid();
        Clear(I);
        Clear(B);
        Clear(D);
        Clear(Bo);
        Clear(By);
        Clear(G);
        Observer.Observe('int', Format(I));
        Observer.Observe('big', Format(B));
        Observer.Observe('dec', Format(D));
        Observer.Observe('bool', Format(Bo));
        Observer.Observe('byte', Format(By));
        Observer.Observe('guid_null', Format(IsNullGuid(G)));
        Observer.Expect('int', '0');
        Observer.Expect('big', '0');
        Observer.Expect('dec', '0');
        Observer.Expect('bool', 'No');
        Observer.Expect('byte', '\u0000');
        Observer.Expect('guid_null', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Compare_MixedNumeric()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        B: BigInteger;
        D: Decimal;
        By: Byte;
    begin
        I := 5;
        B := 5;
        D := 5;
        By := 5;
        Observer.Observe('int_big', Format(I = B));
        Observer.Observe('int_dec', Format(I = D));
        Observer.Observe('big_dec', Format(B = D));
        Observer.Observe('byte_int', Format(By = I));
        Observer.Observe('byte_dec', Format(By = D));
        D := 5.0000001;
        Observer.Observe('dec_gt_int', Format(D > I));
        Observer.Observe('dec_ne_int', Format(D <> I));
        Evaluate(B, '5000000000');
        Observer.Observe('big_gt_int', Format(B > I));
        Observer.Observe('big_gt_maxint', Format(B > 2147483647));
        Observer.Expect('int_big', 'Yes');
        Observer.Expect('int_dec', 'Yes');
        Observer.Expect('big_dec', 'Yes');
        Observer.Expect('byte_int', 'Yes');
        Observer.Expect('byte_dec', 'Yes');
        Observer.Expect('dec_gt_int', 'Yes');
        Observer.Expect('dec_ne_int', 'Yes');
        Observer.Expect('big_gt_int', 'Yes');
        Observer.Expect('big_gt_maxint', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_Types()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        I: Integer;
        D: Decimal;
        B: BigInteger;
        Bo: Boolean;
        By: Byte;
        C: Char;
        G: Guid;
    begin
        V := 5;
        Observer.Observe('int_integer', Format(V.IsInteger()));
        Observer.Observe('int_decimal', Format(V.IsDecimal()));
        Observer.Observe('int_bigint', Format(V.IsBigInteger()));
        V := 5.5;
        Observer.Observe('dec_decimal', Format(V.IsDecimal()));
        Observer.Observe('dec_integer', Format(V.IsInteger()));
        B := 5;
        V := B;
        Observer.Observe('big_bigint', Format(V.IsBigInteger()));
        Observer.Observe('big_integer', Format(V.IsInteger()));
        V := true;
        Observer.Observe('bool_boolean', Format(V.IsBoolean()));
        By := 3;
        V := By;
        Observer.Observe('byte_byte', Format(V.IsByte()));
        Observer.Observe('byte_integer', Format(V.IsInteger()));
        C := 'a';
        V := C;
        Observer.Observe('char_char', Format(V.IsChar()));
        G := CreateGuid();
        V := G;
        Observer.Observe('guid_guid', Format(V.IsGuid()));
        Observer.Observe('guid_text', Format(V.IsText()));
        V := 5;
        D := V;
        Observer.Observe('int_to_dec', Format(D));
        V := 5.5;
        asserterror I := V;
        Observer.ObserveError('dec_to_int');
        V := 'abc';
        asserterror I := V;
        Observer.ObserveError('text_to_int');
        V := B;
        D := V;
        Observer.Observe('big_to_dec', Format(D));
        Bo := false;
        V := Bo;
        Observer.Observe('bool_fmt', Format(V));
        Observer.Expect('int_integer', 'Yes');
        Observer.Expect('int_decimal', 'No');
        Observer.Expect('int_bigint', 'No');
        Observer.Expect('dec_decimal', 'Yes');
        Observer.Expect('dec_integer', 'No');
        Observer.Expect('big_bigint', 'Yes');
        Observer.Expect('big_integer', 'No');
        Observer.Expect('bool_boolean', 'Yes');
        Observer.Expect('byte_byte', 'Yes');
        Observer.Expect('byte_integer', 'No');
        Observer.Expect('char_char', 'Yes');
        Observer.Expect('guid_guid', 'Yes');
        Observer.Expect('guid_text', 'No');
        Observer.Expect('int_to_dec', '5');
        Observer.Expect('dec_to_int|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 5.5 to System.Int32.');
        Observer.Expect('dec_to_int|code', 'ConversionCast');
        Observer.Expect('text_to_int|text', 'The expression Variant cannot be type-converted to a Integer value.');
        Observer.Expect('text_to_int|code', 'TypeConversion:Format');
        Observer.Expect('big_to_dec', '5');
        Observer.Expect('bool_fmt', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_MinMaxLiterals()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        B: BigInteger;
        D: Decimal;
    begin
        I := 2147483647;
        B := I;
        B += 1;
        Observer.Observe('big_past_int', Format(B));
        D := I;
        D += 1;
        Observer.Observe('dec_past_int', Format(D));
        Evaluate(I, '-2147483648');
        Observer.Observe('min_int', Format(I));
        Observer.Observe('literal_int_isbig', Format(IsBig(5)));
        Observer.Expect('big_past_int', '2147483648');
        Observer.Expect('dec_past_int', '2,147,483,648');
        Observer.Expect('min_int', '-2147483648');
        Observer.Expect('literal_int_isbig', 'No');
        Observer.Verify();
    end;

    local procedure IsBig(V: Variant): Boolean
    begin
        exit(V.IsBigInteger());
    end;

    // Writer BP (corpus issue 664, microsoft/AL issue 6620): the default and an assigned value of a global DataScope variable.
    [Test]
    procedure Defaults_DataScopeGlobal_BP()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT BP DataScope Holder";
    begin
        Observer.Observe('default', Format(Holder.GetScope()));
        Holder.SetScope(DataScope::Company);
        Observer.Observe('assigned', Format(Holder.GetScope()));
        Observer.Observe('is company', Format(Holder.GetScope() = DataScope::Company));
        Holder.SetScope(DataScope::User);
        Observer.Observe('reassigned', Format(Holder.GetScope()));
        Observer.Expect('default', 'Module');
        Observer.Expect('assigned', 'Company');
        Observer.Expect('is company', 'Yes');
        Observer.Expect('reassigned', 'User');
        Observer.Verify();
    end;
}
