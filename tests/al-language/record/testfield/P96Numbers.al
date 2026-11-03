// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Fixtures used: table 70738, enum 70739, codeunit 70740 (P96Objects.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Record.TestField(Field, Value) with Integer, BigInteger, Decimal values; FieldRef.TestField(Variant) with the same and with mismatching variant types
// BC versions: 29 (27 and 28 by CI)

codeunit 70742 "LT P96 Numbers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Numbers_Integer_Value()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT P96 Helper";
        Full: Record "LT P96 Rec";
        Empty: Record "LT P96 Rec";
    begin
        Full.DeleteAll();
        H.Seed();
        Full.Get('K1');
        Empty.Get('E1');
        H.ObservePair(Observer, 'int_equal', H.RecI(Full,4,5), H.RefV(Full,4,5));
        H.ObservePair(Observer, 'int_diff', H.RecI(Full,4,6), H.RefV(Full,4,6));
        H.ObservePair(Observer, 'int_zero_on_full', H.RecI(Full,4,0), H.RefV(Full,4,0));
        H.ObservePair(Observer, 'int_negative', H.RecI(Full,4,-5), H.RefV(Full,4,-5));
        H.ObservePair(Observer, 'int_max', H.RecI(Full,4,2147483647), H.RefV(Full,4,2147483647));
        H.ObservePair(Observer, 'int_zero_on_empty', H.RecI(Empty,4,0), H.RefV(Empty,4,0));
        H.ObservePair(Observer, 'int_value_on_empty', H.RecI(Empty,4,5), H.RefV(Empty,4,5));
        Observer.Expect('rec_int_equal', 'ok');
        Observer.Expect('ref_int_equal', 'ok');
        Observer.Expect('same_int_equal', 'Yes');
        Observer.Expect('rec_int_diff', 'Num Cap must be equal to ''6''  in P96 Rec Caption: Code Cap=K1. Current value is ''5''.|TestField');
        Observer.Expect('ref_int_diff', 'Num Cap must be equal to ''6''  in P96 Rec Caption: Code Cap=K1. Current value is ''5''.|TestField');
        Observer.Expect('same_int_diff', 'Yes');
        Observer.Expect('rec_int_zero_on_full', 'Num Cap must be equal to ''0''  in P96 Rec Caption: Code Cap=K1. Current value is ''5''.|TestField');
        Observer.Expect('ref_int_zero_on_full', 'Num Cap must be equal to ''0''  in P96 Rec Caption: Code Cap=K1. Current value is ''5''.|TestField');
        Observer.Expect('same_int_zero_on_full', 'Yes');
        Observer.Expect('rec_int_negative', 'Num Cap must be equal to ''-5''  in P96 Rec Caption: Code Cap=K1. Current value is ''5''.|TestField');
        Observer.Expect('ref_int_negative', 'Num Cap must be equal to ''-5''  in P96 Rec Caption: Code Cap=K1. Current value is ''5''.|TestField');
        Observer.Expect('same_int_negative', 'Yes');
        Observer.Expect('rec_int_max', 'Num Cap must be equal to ''2147483647''  in P96 Rec Caption: Code Cap=K1. Current value is ''5''.|TestField');
        Observer.Expect('ref_int_max', 'Num Cap must be equal to ''2147483647''  in P96 Rec Caption: Code Cap=K1. Current value is ''5''.|TestField');
        Observer.Expect('same_int_max', 'Yes');
        Observer.Expect('rec_int_zero_on_empty', 'ok');
        Observer.Expect('ref_int_zero_on_empty', 'ok');
        Observer.Expect('same_int_zero_on_empty', 'Yes');
        Observer.Expect('rec_int_value_on_empty', 'Num Cap must be equal to ''5''  in P96 Rec Caption: Code Cap=E1. Current value is ''0''.|TestField');
        Observer.Expect('ref_int_value_on_empty', 'Num Cap must be equal to ''5''  in P96 Rec Caption: Code Cap=E1. Current value is ''0''.|TestField');
        Observer.Expect('same_int_value_on_empty', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Numbers_BigInteger_Value()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT P96 Helper";
        Full: Record "LT P96 Rec";
        Empty: Record "LT P96 Rec";
        Big: BigInteger;
        Same: BigInteger;
        Other: BigInteger;
    begin
        Full.DeleteAll();
        H.Seed();
        Full.Get('K1');
        Empty.Get('E1');
        Big := 2147483647;
        Same := Big * 4;
        Other := Same + 1;
        H.ObservePair(Observer, 'big_equal', H.RecBig(Full,Same), H.RefV(Full,5,Same));
        H.ObservePair(Observer, 'big_diff', H.RecBig(Full,Other), H.RefV(Full,5,Other));
        H.ObservePair(Observer, 'big_small', H.RecBig(Full,5), H.RefV(Full,5,5));
        H.ObservePair(Observer, 'big_zero_on_full', H.RecBig(Full,0), H.RefV(Full,5,0));
        H.ObservePair(Observer, 'big_zero_on_empty', H.RecBig(Empty,0), H.RefV(Empty,5,0));
        H.ObservePair(Observer, 'big_value_on_empty', H.RecBig(Empty,Same), H.RefV(Empty,5,Same));
        H.ObservePair(Observer, 'big_negative', H.RecBig(Full,-Same), H.RefV(Full,5,-Same));
        Observer.Expect('rec_big_equal', 'ok');
        Observer.Expect('ref_big_equal', 'ok');
        Observer.Expect('same_big_equal', 'Yes');
        Observer.Expect('rec_big_diff', 'Big Cap must be equal to ''8589934589''  in P96 Rec Caption: Code Cap=K1. Current value is ''8589934588''.|TestField');
        Observer.Expect('ref_big_diff', 'Big Cap must be equal to ''8589934589''  in P96 Rec Caption: Code Cap=K1. Current value is ''8589934588''.|TestField');
        Observer.Expect('same_big_diff', 'Yes');
        Observer.Expect('rec_big_small', 'Big Cap must be equal to ''5''  in P96 Rec Caption: Code Cap=K1. Current value is ''8589934588''.|TestField');
        Observer.Expect('ref_big_small', 'Big Cap must be equal to ''5''  in P96 Rec Caption: Code Cap=K1. Current value is ''8589934588''.|TestField');
        Observer.Expect('same_big_small', 'Yes');
        Observer.Expect('rec_big_zero_on_full', 'Big Cap must be equal to ''0''  in P96 Rec Caption: Code Cap=K1. Current value is ''8589934588''.|TestField');
        Observer.Expect('ref_big_zero_on_full', 'Big Cap must be equal to ''0''  in P96 Rec Caption: Code Cap=K1. Current value is ''8589934588''.|TestField');
        Observer.Expect('same_big_zero_on_full', 'Yes');
        Observer.Expect('rec_big_zero_on_empty', 'ok');
        Observer.Expect('ref_big_zero_on_empty', 'ok');
        Observer.Expect('same_big_zero_on_empty', 'Yes');
        Observer.Expect('rec_big_value_on_empty', 'Big Cap must be equal to ''8589934588''  in P96 Rec Caption: Code Cap=E1. Current value is ''0''.|TestField');
        Observer.Expect('ref_big_value_on_empty', 'Big Cap must be equal to ''8589934588''  in P96 Rec Caption: Code Cap=E1. Current value is ''0''.|TestField');
        Observer.Expect('same_big_value_on_empty', 'Yes');
        Observer.Expect('rec_big_negative', 'Big Cap must be equal to ''-8589934588''  in P96 Rec Caption: Code Cap=K1. Current value is ''8589934588''.|TestField');
        Observer.Expect('ref_big_negative', 'Big Cap must be equal to ''-8589934588''  in P96 Rec Caption: Code Cap=K1. Current value is ''8589934588''.|TestField');
        Observer.Expect('same_big_negative', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Numbers_Decimal_Value_1()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT P96 Helper";
        Full: Record "LT P96 Rec";
        Empty: Record "LT P96 Rec";
    begin
        Full.DeleteAll();
        H.Seed();
        Full.Get('K1');
        Empty.Get('E1');
        H.ObservePair(Observer, 'dec_equal', H.RecD(Full,6,2.5), H.RefV(Full,6,2.5));
        H.ObservePair(Observer, 'dec_equal_scale', H.RecD(Full,6,2.50000), H.RefV(Full,6,2.50000));
        H.ObservePair(Observer, 'dec_diff', H.RecD(Full,6,2.51), H.RefV(Full,6,2.51));
        H.ObservePair(Observer, 'dec_tiny_diff', H.RecD(Full,6,2.500001), H.RefV(Full,6,2.500001));
        H.ObservePair(Observer, 'dec_zero_on_full', H.RecD(Full,6,0), H.RefV(Full,6,0.0));
        H.ObservePair(Observer, 'dec_zero_on_empty', H.RecD(Empty,6,0), H.RefV(Empty,6,0.0));
        H.ObservePair(Observer, 'dec_value_on_empty', H.RecD(Empty,6,1.5), H.RefV(Empty,6,1.5));
        H.ObservePair(Observer, 'dec_on_int_field_equal', H.RecD(Full,4,5), H.RefV(Full,4,5.0));
        Observer.Expect('rec_dec_equal', 'ok');
        Observer.Expect('ref_dec_equal', 'ok');
        Observer.Expect('same_dec_equal', 'Yes');
        Observer.Expect('rec_dec_equal_scale', 'ok');
        Observer.Expect('ref_dec_equal_scale', 'ok');
        Observer.Expect('same_dec_equal_scale', 'Yes');
        Observer.Expect('rec_dec_diff', 'Amt Cap must be equal to ''2.51''  in P96 Rec Caption: Code Cap=K1. Current value is ''2.5''.|TestField');
        Observer.Expect('ref_dec_diff', 'Amt Cap must be equal to ''2.51''  in P96 Rec Caption: Code Cap=K1. Current value is ''2.5''.|TestField');
        Observer.Expect('same_dec_diff', 'Yes');
        Observer.Expect('rec_dec_tiny_diff', 'Amt Cap must be equal to ''2.500001''  in P96 Rec Caption: Code Cap=K1. Current value is ''2.5''.|TestField');
        Observer.Expect('ref_dec_tiny_diff', 'Amt Cap must be equal to ''2.500001''  in P96 Rec Caption: Code Cap=K1. Current value is ''2.5''.|TestField');
        Observer.Expect('same_dec_tiny_diff', 'Yes');
        Observer.Expect('rec_dec_zero_on_full', 'Amt Cap must be equal to ''0''  in P96 Rec Caption: Code Cap=K1. Current value is ''2.5''.|TestField');
        Observer.Expect('ref_dec_zero_on_full', 'Amt Cap must be equal to ''0''  in P96 Rec Caption: Code Cap=K1. Current value is ''2.5''.|TestField');
        Observer.Expect('same_dec_zero_on_full', 'Yes');
        Observer.Expect('rec_dec_zero_on_empty', 'ok');
        Observer.Expect('ref_dec_zero_on_empty', 'ok');
        Observer.Expect('same_dec_zero_on_empty', 'Yes');
        Observer.Expect('rec_dec_value_on_empty', 'Amt Cap must be equal to ''1.5''  in P96 Rec Caption: Code Cap=E1. Current value is ''0''.|TestField');
        Observer.Expect('ref_dec_value_on_empty', 'Amt Cap must be equal to ''1.5''  in P96 Rec Caption: Code Cap=E1. Current value is ''0''.|TestField');
        Observer.Expect('same_dec_value_on_empty', 'Yes');
        Observer.Expect('rec_dec_on_int_field_equal', 'ok');
        Observer.Expect('ref_dec_on_int_field_equal', 'ok');
        Observer.Expect('same_dec_on_int_field_equal', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Numbers_Decimal_Value_2()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT P96 Helper";
        Full: Record "LT P96 Rec";
        Empty: Record "LT P96 Rec";
    begin
        Full.DeleteAll();
        H.Seed();
        Full.Get('K1');
        Empty.Get('E1');
        H.ObservePair(Observer, 'dec_on_int_field_diff', H.RecD(Full,4,5.5), H.RefV(Full,4,5.5));
        H.ObservePair(Observer, 'dec_negative', H.RecD(Full,6,-2.5), H.RefV(Full,6,-2.5));
        Observer.Expect('rec_dec_on_int_field_diff', 'Num Cap must be equal to ''5.5''  in P96 Rec Caption: Code Cap=K1. Current value is ''5''.|TestField');
        Observer.Expect('ref_dec_on_int_field_diff', 'Num Cap must be equal to ''5.5''  in P96 Rec Caption: Code Cap=K1. Current value is ''5''.|TestField');
        Observer.Expect('same_dec_on_int_field_diff', 'Yes');
        Observer.Expect('rec_dec_negative', 'Amt Cap must be equal to ''-2.5''  in P96 Rec Caption: Code Cap=K1. Current value is ''2.5''.|TestField');
        Observer.Expect('ref_dec_negative', 'Amt Cap must be equal to ''-2.5''  in P96 Rec Caption: Code Cap=K1. Current value is ''2.5''.|TestField');
        Observer.Expect('same_dec_negative', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Numbers_Variant_Type_Mismatch_On_Ref()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT P96 Helper";
        Full: Record "LT P96 Rec";
        Empty: Record "LT P96 Rec";
    begin
        Full.DeleteAll();
        H.Seed();
        Full.Get('K1');
        Empty.Get('E1');
        H.ObservePair(Observer, 'int_field_text_value', H.RecI(Full,4,5), H.RefV(Full,4,'5'));
        H.ObservePair(Observer, 'int_field_decimal_value', H.RecD(Full,4,5), H.RefV(Full,4,5.0));
        H.ObservePair(Observer, 'dec_field_int_value', H.RecD(Full,6,2), H.RefV(Full,6,2));
        H.ObservePair(Observer, 'dec_field_text_value', H.RecD(Full,6,2.5), H.RefV(Full,6,'2.5'));
        H.ObservePair(Observer, 'txt_field_int_value', H.RecT(Full,2,'5'), H.RefV(Full,2,5));
        H.ObservePair(Observer, 'bool_field_int_value', H.RecBool(Full,true), H.RefV(Full,7,1));
        Observer.Expect('rec_int_field_text_value', 'ok');
        Observer.Expect('ref_int_field_text_value', 'ok');
        Observer.Expect('same_int_field_text_value', 'Yes');
        Observer.Expect('rec_int_field_decimal_value', 'ok');
        Observer.Expect('ref_int_field_decimal_value', 'ok');
        Observer.Expect('same_int_field_decimal_value', 'Yes');
        Observer.Expect('rec_dec_field_int_value', 'Amt Cap must be equal to ''2''  in P96 Rec Caption: Code Cap=K1. Current value is ''2.5''.|TestField');
        Observer.Expect('ref_dec_field_int_value', 'Amt Cap must be equal to ''2''  in P96 Rec Caption: Code Cap=K1. Current value is ''2.5''.|TestField');
        Observer.Expect('same_dec_field_int_value', 'Yes');
        Observer.Expect('rec_dec_field_text_value', 'ok');
        Observer.Expect('ref_dec_field_text_value', 'ok');
        Observer.Expect('same_dec_field_text_value', 'Yes');
        Observer.Expect('rec_txt_field_int_value', 'Txt Cap must be equal to ''5''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('ref_txt_field_int_value', 'Txt Cap must be equal to ''5''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('same_txt_field_int_value', 'Yes');
        Observer.Expect('rec_bool_field_int_value', 'ok');
        Observer.Expect('ref_bool_field_int_value', 'ok');
        Observer.Expect('same_bool_field_int_value', 'Yes');
        Observer.Verify();
    end;
}
