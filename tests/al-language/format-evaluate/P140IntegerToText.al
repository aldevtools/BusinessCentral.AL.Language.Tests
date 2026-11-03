// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/integer/integer-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 70903 "LT P140 Integer ToText"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure IntMax(): Integer
    var
        Half: Integer;
    begin
        Half := 1073741823;
        exit(Half + Half + 1);
    end;

    local procedure IntMin(): Integer
    begin
        exit(-IntMax() - 1);
    end;

    [Test]
    procedure P140_IntegerToText_Values()
    var
        Observer: Codeunit "Probe Observer";
        V: Integer;
    begin
        V := 0;
        Observer.Observe('i0', V.ToText());
        V := 999;
        Observer.Observe('i999', V.ToText());
        V := 1000;
        Observer.Observe('i1000', V.ToText());
        V := -999;
        Observer.Observe('im999', V.ToText());
        V := -1000;
        Observer.Observe('im1000', V.ToText());
        V := 1234;
        Observer.Observe('i1234', V.ToText());
        V := -1234;
        Observer.Observe('im1234', V.ToText());
        V := 1000000;
        Observer.Observe('i1000000', V.ToText());
        V := IntMax();
        Observer.Observe('imax', V.ToText());
        V := IntMin();
        Observer.Observe('imin', V.ToText());
        Observer.Observe('imax_via_literal_call', IntMax().ToText());
        Observer.Observe('imin_len', Format(StrLen(V.ToText())));
        Observer.Expect('i0', '0');
        Observer.Expect('i999', '999');
        Observer.Expect('i1000', '1000');
        Observer.Expect('im999', '-999');
        Observer.Expect('im1000', '-1000');
        Observer.Expect('i1234', '1234');
        Observer.Expect('im1234', '-1234');
        Observer.Expect('i1000000', '1000000');
        Observer.Expect('imax', '2147483647');
        Observer.Expect('imin', '-2147483648');
        Observer.Expect('imax_via_literal_call', '2147483647');
        Observer.Expect('imin_len', '11');
        Observer.Verify();
    end;

    [Test]
    procedure P140_IntegerFormat_Compare()
    var
        Observer: Codeunit "Probe Observer";
        V: Integer;
    begin
        V := 1234;
        Observer.Observe('f_1234', Format(V));
        Observer.Observe('f_1234_0_1', Format(V, 0, 1));
        Observer.Observe('f_1234_0_2', Format(V, 0, 2));
        Observer.Observe('f_1234_0_9', Format(V, 0, 9));
        Observer.Observe('f_1234_0_0', Format(V, 0, 0));
        V := -1234;
        Observer.Observe('f_m1234', Format(V));
        Observer.Observe('f_m1234_0_1', Format(V, 0, 1));
        Observer.Observe('f_m1234_0_2', Format(V, 0, 2));
        Observer.Observe('f_m1234_0_9', Format(V, 0, 9));
        Observer.Observe('f_m1234_0_0', Format(V, 0, 0));
        V := 1000000;
        Observer.Observe('f_1000000', Format(V));
        Observer.Observe('f_1000000_0_1', Format(V, 0, 1));
        Observer.Observe('f_1000000_0_2', Format(V, 0, 2));
        Observer.Observe('f_1000000_0_9', Format(V, 0, 9));
        Observer.Observe('f_1000000_0_0', Format(V, 0, 0));
        V := 999;
        Observer.Observe('f_999', Format(V));
        V := 1000;
        Observer.Observe('f_1000', Format(V));
        Observer.Observe('f_1000_0_9', Format(V, 0, 9));
        V := 0;
        Observer.Observe('f_0', Format(V));
        Observer.Observe('f_0_0_9', Format(V, 0, 9));
        V := IntMax();
        Observer.Observe('f_max', Format(V));
        Observer.Observe('f_max_0_9', Format(V, 0, 9));
        V := IntMin();
        Observer.Observe('f_min', Format(V));
        Observer.Observe('f_min_0_9', Format(V, 0, 9));
        Observer.Expect('f_1234', '1234');
        Observer.Expect('f_1234_0_1', '1234');
        Observer.Expect('f_1234_0_2', '1234');
        Observer.Expect('f_1234_0_9', '1234');
        Observer.Expect('f_1234_0_0', '1234');
        Observer.Expect('f_m1234', '-1234');
        Observer.Expect('f_m1234_0_1', '-1234');
        Observer.Expect('f_m1234_0_2', '-1234');
        Observer.Expect('f_m1234_0_9', '-1234');
        Observer.Expect('f_m1234_0_0', '-1234');
        Observer.Expect('f_1000000', '1000000');
        Observer.Expect('f_1000000_0_1', '1000000');
        Observer.Expect('f_1000000_0_2', '1000000');
        Observer.Expect('f_1000000_0_9', '1000000');
        Observer.Expect('f_1000000_0_0', '1000000');
        Observer.Expect('f_999', '999');
        Observer.Expect('f_1000', '1000');
        Observer.Expect('f_1000_0_9', '1000');
        Observer.Expect('f_0', '0');
        Observer.Expect('f_0_0_9', '0');
        Observer.Expect('f_max', '2147483647');
        Observer.Expect('f_max_0_9', '2147483647');
        Observer.Expect('f_min', '-2147483648');
        Observer.Expect('f_min_0_9', '-2147483648');
        Observer.Verify();
    end;

    [Test]
    procedure P140_BigIntegerToText()
    var
        Observer: Codeunit "Probe Observer";
        V: BigInteger;
    begin
        V := 0;
        Observer.Observe('b0', V.ToText());
        V := 999;
        Observer.Observe('b999', V.ToText());
        V := 1000;
        Observer.Observe('b1000', V.ToText());
        V := -999;
        Observer.Observe('bm999', V.ToText());
        V := -1000;
        Observer.Observe('bm1000', V.ToText());
        V := 1234;
        Observer.Observe('b1234', V.ToText());
        Observer.Observe('b1234_format', Format(V));
        Observer.Observe('b1234_format_0_9', Format(V, 0, 9));
        V := -1234;
        Observer.Observe('bm1234', V.ToText());
        Observer.Observe('bm1234_format', Format(V));
        V := 1000000;
        Observer.Observe('b1000000', V.ToText());
        Observer.Observe('b1000000_format', Format(V));
        Observer.Observe('b1000000_format_0_1', Format(V, 0, 1));
        Observer.Observe('b1000000_format_0_2', Format(V, 0, 2));
        Observer.Observe('b1000000_format_0_0', Format(V, 0, 0));
        V := IntMax();
        V := V * 4 + 3;
        Observer.Observe('bbig', V.ToText());
        Observer.Observe('bbig_format', Format(V));
        Observer.Observe('bbig_format_0_9', Format(V, 0, 9));
        V := -V;
        Observer.Observe('bnegbig', V.ToText());
        Observer.Observe('bnegbig_format', Format(V));
        Observer.Expect('b0', '0');
        Observer.Expect('b999', '999');
        Observer.Expect('b1000', '1000');
        Observer.Expect('bm999', '-999');
        Observer.Expect('bm1000', '-1000');
        Observer.Expect('b1234', '1234');
        Observer.Expect('b1234_format', '1234');
        Observer.Expect('b1234_format_0_9', '1234');
        Observer.Expect('bm1234', '-1234');
        Observer.Expect('bm1234_format', '-1234');
        Observer.Expect('b1000000', '1000000');
        Observer.Expect('b1000000_format', '1000000');
        Observer.Expect('b1000000_format_0_1', '1000000');
        Observer.Expect('b1000000_format_0_2', '1000000');
        Observer.Expect('b1000000_format_0_0', '1000000');
        Observer.Expect('bbig', '8589934591');
        Observer.Expect('bbig_format', '8589934591');
        Observer.Expect('bbig_format_0_9', '8589934591');
        Observer.Expect('bnegbig', '-8589934591');
        Observer.Expect('bnegbig_format', '-8589934591');
        Observer.Verify();
    end;

    [Test]
    procedure P140_DecimalToText()
    var
        Observer: Codeunit "Probe Observer";
        V: Decimal;
    begin
        V := 0;
        Observer.Observe('d0', V.ToText());
        V := 999;
        Observer.Observe('d999', V.ToText());
        V := 1000;
        Observer.Observe('d1000', V.ToText());
        V := -1000;
        Observer.Observe('dm1000', V.ToText());
        V := 1234;
        Observer.Observe('d1234', V.ToText());
        Observer.Observe('d1234_invariant_true', V.ToText(true));
        Observer.Observe('d1234_invariant_false', V.ToText(false));
        Observer.Observe('d1234_format', Format(V));
        Observer.Observe('d1234_format_0_1', Format(V, 0, 1));
        Observer.Observe('d1234_format_0_2', Format(V, 0, 2));
        Observer.Observe('d1234_format_0_9', Format(V, 0, 9));
        Observer.Observe('d1234_format_0_0', Format(V, 0, 0));
        V := -1234.5;
        Observer.Observe('dm1234_5', V.ToText());
        Observer.Observe('dm1234_5_invariant', V.ToText(true));
        Observer.Observe('dm1234_5_format', Format(V));
        Observer.Observe('dm1234_5_format_0_9', Format(V, 0, 9));
        V := 1000000;
        Observer.Observe('d1000000', V.ToText());
        Observer.Observe('d1000000_format', Format(V));
        Observer.Observe('d1000000_format_0_9', Format(V, 0, 9));
        V := 1234567.891;
        Observer.Observe('d1234567_891', V.ToText());
        Observer.Observe('d1234567_891_format', Format(V));
        Observer.Observe('d1234567_891_format_0_9', Format(V, 0, 9));
        Observer.Expect('d0', '0');
        Observer.Expect('d999', '999');
        Observer.Expect('d1000', '1,000');
        Observer.Expect('dm1000', '-1,000');
        Observer.Expect('d1234', '1,234');
        Observer.Expect('d1234_invariant_true', '1234');
        Observer.Expect('d1234_invariant_false', '1,234');
        Observer.Expect('d1234_format', '1,234');
        Observer.Expect('d1234_format_0_1', '1234');
        Observer.Expect('d1234_format_0_2', '1234');
        Observer.Expect('d1234_format_0_9', '1234');
        Observer.Expect('d1234_format_0_0', '1,234');
        Observer.Expect('dm1234_5', '-1,234.5');
        Observer.Expect('dm1234_5_invariant', '-1234.5');
        Observer.Expect('dm1234_5_format', '-1,234.5');
        Observer.Expect('dm1234_5_format_0_9', '-1234.5');
        Observer.Expect('d1000000', '1,000,000');
        Observer.Expect('d1000000_format', '1,000,000');
        Observer.Expect('d1000000_format_0_9', '1000000');
        Observer.Expect('d1234567_891', '1,234,567.891');
        Observer.Expect('d1234567_891_format', '1,234,567.891');
        Observer.Expect('d1234567_891_format_0_9', '1234567.891');
        Observer.Verify();
    end;

    [Test]
    procedure P140_ToText_UnderGlobalLanguage()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
        V: Integer;
        D: Decimal;
    begin
        Orig := GlobalLanguage();
        V := 1234567;
        D := 1234567.5;
        GlobalLanguage(1031);
        Observer.Observe('deu_int_totext', V.ToText());
        Observer.Observe('deu_int_format', Format(V));
        Observer.Observe('deu_dec_totext', D.ToText());
        Observer.Observe('deu_dec_format', Format(D));
        GlobalLanguage(1036);
        Observer.Observe('fra_int_totext', V.ToText());
        Observer.Observe('fra_int_format', Format(V));
        Observer.Observe('fra_dec_totext', D.ToText());
        Observer.Observe('fra_dec_format', Format(D));
        GlobalLanguage(Orig);
        Observer.Observe('restored_equal', Format(GlobalLanguage() = Orig));
        Observer.Expect('deu_int_totext', '1234567');
        Observer.Expect('deu_int_format', '1234567');
        Observer.Expect('deu_dec_totext', '1,234,567.5');
        Observer.Expect('deu_dec_format', '1,234,567.5');
        Observer.Expect('fra_int_totext', '1234567');
        Observer.Expect('fra_int_format', '1234567');
        Observer.Expect('fra_dec_totext', '1,234,567.5');
        Observer.Expect('fra_dec_format', '1,234,567.5');
        Observer.Expect('restored_equal', 'Yes');
        Observer.Verify();
    end;

    // corpus issue 669 (writer CO): after GlobalLanguage(1043) (Dutch), does Format use a Dutch decimal separator, and do date texts change?
    [Test]
    procedure P140_DutchGlobalLanguage_NumbersAndDates_CO()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
        D: Decimal;
        Dt: Date;
    begin
        Orig := GlobalLanguage();
        D := 1234.5;
        Dt := DMY2Date(5, 2, 2024);
        Observer.Observe('enu_dec_format', Format(D));
        Observer.Observe('enu_date_format', Format(Dt));
        Observer.Observe('enu_date_month_text', Format(Dt, 0, '<Month Text>'));
        Observer.Observe('enu_date_weekday_text', Format(Dt, 0, '<Weekday Text>'));
        GlobalLanguage(1043);
        Observer.Observe('nld_global_language', Format(GlobalLanguage()));
        Observer.Observe('nld_dec_format', Format(D));
        Observer.Observe('nld_dec_totext', D.ToText());
        Observer.Observe('nld_dec_format_1', Format(D, 0, 1));
        Observer.Observe('nld_date_format', Format(Dt));
        Observer.Observe('nld_date_format_4', Format(Dt, 0, 4));
        Observer.Observe('nld_date_month_text', Format(Dt, 0, '<Month Text>'));
        Observer.Observe('nld_date_weekday_text', Format(Dt, 0, '<Weekday Text>'));
        Observer.Observe('nld_bool', Format(true));
        GlobalLanguage(Orig);
        Observer.Observe('restored_equal', Format(GlobalLanguage() = Orig));
        Observer.Expect('enu_dec_format', '1,234.5');
        Observer.Expect('enu_date_format', '02/05/24');
        Observer.Expect('enu_date_month_text', 'February');
        Observer.Expect('enu_date_weekday_text', 'Monday');
        Observer.Expect('nld_global_language', '1043');
        Observer.Expect('nld_dec_format', '1,234.5');
        Observer.Expect('nld_dec_totext', '1,234.5');
        Observer.Expect('nld_dec_format_1', '1234.5');
        Observer.Expect('nld_date_format', '02/05/24');
        Observer.Expect('nld_date_format_4', 'februari 5, 2024');
        Observer.Expect('nld_date_month_text', 'februari');
        Observer.Expect('nld_date_weekday_text', 'maandag');
        Observer.Expect('nld_bool', 'Ja');
        Observer.Expect('restored_equal', 'Yes');
        Observer.Verify();
    end;
}
