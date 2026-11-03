// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Fixtures used: table 70738, enum 70739, codeunit 70740 (P96Objects.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Record.TestField(Field, Value) with an Enum value and with Option members / integers; FieldRef.TestField(Variant) with enum, integer and text variants
// BC versions: 29 (27 and 28 by CI)

codeunit 70744 "LT P96 EnumOption"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure EnumOption_Enum_Value()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT P96 Helper";
        Full: Record "LT P96 Rec";
        Empty: Record "LT P96 Rec";
        EZero: Enum "LT P96 Kind";
        ETwo: Enum "LT P96 Kind";
        EOne: Enum "LT P96 Kind";
    begin
        Full.DeleteAll();
        H.Seed();
        Full.Get('K1');
        Empty.Get('E1');
        EZero := EZero::Zero;
        EOne := EOne::One;
        ETwo := ETwo::Two;
        H.ObservePair(Observer, 'enum_equal', H.RecEnum(Full,ETwo), H.RefV(Full,12,ETwo));
        H.ObservePair(Observer, 'enum_diff', H.RecEnum(Full,EOne), H.RefV(Full,12,EOne));
        H.ObservePair(Observer, 'enum_zero_on_full', H.RecEnum(Full,EZero), H.RefV(Full,12,EZero));
        H.ObservePair(Observer, 'enum_zero_on_empty', H.RecEnum(Empty,EZero), H.RefV(Empty,12,EZero));
        H.ObservePair(Observer, 'enum_value_on_empty', H.RecEnum(Empty,ETwo), H.RefV(Empty,12,ETwo));
        H.ObservePair(Observer, 'enum_int_variant_equal', H.RecEnum(Full,ETwo), H.RefV(Full,12,2));
        H.ObservePair(Observer, 'enum_int_variant_diff', H.RecEnum(Full,EOne), H.RefV(Full,12,1));
        H.ObservePair(Observer, 'enum_text_variant', H.RecEnum(Full,ETwo), H.RefV(Full,12,'Two'));
        Observer.Expect('rec_enum_equal', 'ok');
        Observer.Expect('ref_enum_equal', 'ok');
        Observer.Expect('same_enum_equal', 'Yes');
        Observer.Expect('rec_enum_diff', 'Kind Cap must be equal to ''One''  in P96 Rec Caption: Code Cap=K1. Current value is ''Two''.|TestField');
        Observer.Expect('ref_enum_diff', 'Kind Cap must be equal to ''One''  in P96 Rec Caption: Code Cap=K1. Current value is ''Two''.|TestField');
        Observer.Expect('same_enum_diff', 'Yes');
        Observer.Expect('rec_enum_zero_on_full', 'Kind Cap must be equal to ''Zero''  in P96 Rec Caption: Code Cap=K1. Current value is ''Two''.|TestField');
        Observer.Expect('ref_enum_zero_on_full', 'Kind Cap must be equal to ''Zero''  in P96 Rec Caption: Code Cap=K1. Current value is ''Two''.|TestField');
        Observer.Expect('same_enum_zero_on_full', 'Yes');
        Observer.Expect('rec_enum_zero_on_empty', 'ok');
        Observer.Expect('ref_enum_zero_on_empty', 'ok');
        Observer.Expect('same_enum_zero_on_empty', 'Yes');
        Observer.Expect('rec_enum_value_on_empty', 'Kind Cap must be equal to ''Two''  in P96 Rec Caption: Code Cap=E1. Current value is ''Zero''.|TestField');
        Observer.Expect('ref_enum_value_on_empty', 'Kind Cap must be equal to ''Two''  in P96 Rec Caption: Code Cap=E1. Current value is ''Zero''.|TestField');
        Observer.Expect('same_enum_value_on_empty', 'Yes');
        Observer.Expect('rec_enum_int_variant_equal', 'ok');
        Observer.Expect('ref_enum_int_variant_equal', 'ok');
        Observer.Expect('same_enum_int_variant_equal', 'Yes');
        Observer.Expect('rec_enum_int_variant_diff', 'Kind Cap must be equal to ''One''  in P96 Rec Caption: Code Cap=K1. Current value is ''Two''.|TestField');
        Observer.Expect('ref_enum_int_variant_diff', 'Kind Cap must be equal to ''One''  in P96 Rec Caption: Code Cap=K1. Current value is ''Two''.|TestField');
        Observer.Expect('same_enum_int_variant_diff', 'Yes');
        Observer.Expect('rec_enum_text_variant', 'ok');
        Observer.Expect('ref_enum_text_variant', 'Kind Cap must be equal to ''Two''  in P96 Rec Caption: Code Cap=K1. Current value is ''Two''.|TestField');
        Observer.Expect('same_enum_text_variant', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure EnumOption_Option_Value_1()
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
        H.ObservePair(Observer, 'opt_int_equal', H.RecI(Full,13,1), H.RefV(Full,13,1));
        H.ObservePair(Observer, 'opt_int_diff', H.RecI(Full,13,2), H.RefV(Full,13,2));
        H.ObservePair(Observer, 'opt_int_out_of_range', H.RecI(Full,13,7), H.RefV(Full,13,7));
        H.ObservePair(Observer, 'opt_int_negative', H.RecI(Full,13,-1), H.RefV(Full,13,-1));
        H.ObservePair(Observer, 'opt_member_equal', H.RecOptMember(Full,2), H.RefV(Full,13,1));
        H.ObservePair(Observer, 'opt_member_diff', H.RecOptMember(Full,3), H.RefV(Full,13,2));
        H.ObservePair(Observer, 'opt_member_first_on_full', H.RecOptMember(Full,1), H.RefV(Full,13,0));
        H.ObservePair(Observer, 'opt_member_first_on_empty', H.RecOptMember(Empty,1), H.RefV(Empty,13,0));
        Observer.Expect('rec_opt_int_equal', 'ok');
        Observer.Expect('ref_opt_int_equal', 'ok');
        Observer.Expect('same_opt_int_equal', 'Yes');
        Observer.Expect('rec_opt_int_diff', 'Opt Cap must be equal to ''Gamma''  in P96 Rec Caption: Code Cap=K1. Current value is ''Beta''.|TestField');
        Observer.Expect('ref_opt_int_diff', 'Opt Cap must be equal to ''Gamma''  in P96 Rec Caption: Code Cap=K1. Current value is ''Beta''.|TestField');
        Observer.Expect('same_opt_int_diff', 'Yes');
        Observer.Expect('rec_opt_int_out_of_range', 'Opt Cap must be equal to ''7''  in P96 Rec Caption: Code Cap=K1. Current value is ''Beta''.|TestField');
        Observer.Expect('ref_opt_int_out_of_range', 'Opt Cap must be equal to ''7''  in P96 Rec Caption: Code Cap=K1. Current value is ''Beta''.|TestField');
        Observer.Expect('same_opt_int_out_of_range', 'Yes');
        Observer.Expect('rec_opt_int_negative', 'Opt Cap must be equal to ''-1''  in P96 Rec Caption: Code Cap=K1. Current value is ''Beta''.|TestField');
        Observer.Expect('ref_opt_int_negative', 'Opt Cap must be equal to ''-1''  in P96 Rec Caption: Code Cap=K1. Current value is ''Beta''.|TestField');
        Observer.Expect('same_opt_int_negative', 'Yes');
        Observer.Expect('rec_opt_member_equal', 'ok');
        Observer.Expect('ref_opt_member_equal', 'ok');
        Observer.Expect('same_opt_member_equal', 'Yes');
        Observer.Expect('rec_opt_member_diff', 'Opt Cap must be equal to ''Gamma''  in P96 Rec Caption: Code Cap=K1. Current value is ''Beta''.|TestField');
        Observer.Expect('ref_opt_member_diff', 'Opt Cap must be equal to ''Gamma''  in P96 Rec Caption: Code Cap=K1. Current value is ''Beta''.|TestField');
        Observer.Expect('same_opt_member_diff', 'Yes');
        Observer.Expect('rec_opt_member_first_on_full', 'Opt Cap must be equal to ''Alpha''  in P96 Rec Caption: Code Cap=K1. Current value is ''Beta''.|TestField');
        Observer.Expect('ref_opt_member_first_on_full', 'Opt Cap must be equal to ''Alpha''  in P96 Rec Caption: Code Cap=K1. Current value is ''Beta''.|TestField');
        Observer.Expect('same_opt_member_first_on_full', 'Yes');
        Observer.Expect('rec_opt_member_first_on_empty', 'ok');
        Observer.Expect('ref_opt_member_first_on_empty', 'ok');
        Observer.Expect('same_opt_member_first_on_empty', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure EnumOption_Option_Value_2()
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
        H.ObservePair(Observer, 'opt_member_other_on_empty', H.RecOptMember(Empty,2), H.RefV(Empty,13,1));
        H.ObservePair(Observer, 'opt_text_variant', H.RecOptMember(Full,2), H.RefV(Full,13,'Beta'));
        H.ObservePair(Observer, 'opt_int_on_empty_zero', H.RecI(Empty,13,0), H.RefV(Empty,13,0));
        Observer.Expect('rec_opt_member_other_on_empty', 'Opt Cap must be equal to ''Beta''  in P96 Rec Caption: Code Cap=E1. Current value is ''Alpha''.|TestField');
        Observer.Expect('ref_opt_member_other_on_empty', 'Opt Cap must be equal to ''Beta''  in P96 Rec Caption: Code Cap=E1. Current value is ''Alpha''.|TestField');
        Observer.Expect('same_opt_member_other_on_empty', 'Yes');
        Observer.Expect('rec_opt_text_variant', 'ok');
        Observer.Expect('ref_opt_text_variant', 'Opt Cap must be equal to ''Beta''  in P96 Rec Caption: Code Cap=K1. Current value is ''Beta''.|TestField');
        Observer.Expect('same_opt_text_variant', 'No');
        Observer.Expect('rec_opt_int_on_empty_zero', 'ok');
        Observer.Expect('ref_opt_int_on_empty_zero', 'ok');
        Observer.Expect('same_opt_int_on_empty_zero', 'Yes');
        Observer.Verify();
    end;
}
