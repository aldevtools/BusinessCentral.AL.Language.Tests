// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Fixtures used: table 70738, enum 70739, codeunit 70740 (P96Objects.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Record.TestField(Field) and the Value overloads on an empty row and a filled row for every field type: text and code, compared with FieldRef
// BC versions: 29 (27 and 28 by CI)

codeunit 70745 "LT P96 Empty"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure NoValue_EmptyRow_AllTypes()
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
        H.ObservePair(Observer, 'e_code', H.RecNoValue(Empty,1), H.RefNoValue(Empty,1));
        H.ObservePair(Observer, 'e_txt', H.RecNoValue(Empty,2), H.RefNoValue(Empty,2));
        H.ObservePair(Observer, 'e_cd', H.RecNoValue(Empty,3), H.RefNoValue(Empty,3));
        H.ObservePair(Observer, 'e_num', H.RecNoValue(Empty,4), H.RefNoValue(Empty,4));
        H.ObservePair(Observer, 'e_big', H.RecNoValue(Empty,5), H.RefNoValue(Empty,5));
        H.ObservePair(Observer, 'e_amt', H.RecNoValue(Empty,6), H.RefNoValue(Empty,6));
        H.ObservePair(Observer, 'e_flag', H.RecNoValue(Empty,7), H.RefNoValue(Empty,7));
        H.ObservePair(Observer, 'e_dt', H.RecNoValue(Empty,8), H.RefNoValue(Empty,8));
        Observer.Expect('rec_e_code', 'ok');
        Observer.Expect('ref_e_code', 'ok');
        Observer.Expect('same_e_code', 'Yes');
        Observer.Expect('rec_e_txt', 'Txt Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('ref_e_txt', 'Txt Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('same_e_txt', 'Yes');
        Observer.Expect('rec_e_cd', 'Cd Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('ref_e_cd', 'Cd Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('same_e_cd', 'Yes');
        Observer.Expect('rec_e_num', 'Num Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('ref_e_num', 'Num Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('same_e_num', 'Yes');
        Observer.Expect('rec_e_big', 'Big Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('ref_e_big', 'Big Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('same_e_big', 'Yes');
        Observer.Expect('rec_e_amt', 'Amt Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('ref_e_amt', 'Amt Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('same_e_amt', 'Yes');
        Observer.Expect('rec_e_flag', 'Flag Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('ref_e_flag', 'Flag Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('same_e_flag', 'Yes');
        Observer.Expect('rec_e_dt', 'Dt Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('ref_e_dt', 'Dt Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('same_e_dt', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure NoValue_EmptyRow_AllTypes_Rest()
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
        H.ObservePair(Observer, 'e_tm', H.RecNoValue(Empty,9), H.RefNoValue(Empty,9));
        H.ObservePair(Observer, 'e_dtm', H.RecNoValue(Empty,10), H.RefNoValue(Empty,10));
        H.ObservePair(Observer, 'e_gd', H.RecNoValue(Empty,11), H.RefNoValue(Empty,11));
        H.ObservePair(Observer, 'e_kind', H.RecNoValue(Empty,12), H.RefNoValue(Empty,12));
        H.ObservePair(Observer, 'e_opt', H.RecNoValue(Empty,13), H.RefNoValue(Empty,13));
        Observer.Expect('rec_e_tm', 'Tm Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('ref_e_tm', 'Tm Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('same_e_tm', 'Yes');
        Observer.Expect('rec_e_dtm', 'Dtm Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('ref_e_dtm', 'Dtm Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('same_e_dtm', 'Yes');
        Observer.Expect('rec_e_gd', 'Gd Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('ref_e_gd', 'Gd Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('same_e_gd', 'Yes');
        Observer.Expect('rec_e_kind', 'Kind Cap must not be Zero in P96 Rec Caption: Code Cap=E1|TestField');
        Observer.Expect('ref_e_kind', 'Kind Cap must not be Zero in P96 Rec Caption: Code Cap=E1|TestField');
        Observer.Expect('same_e_kind', 'Yes');
        Observer.Expect('rec_e_opt', 'Opt Cap must not be Alpha in P96 Rec Caption: Code Cap=E1|TestField');
        Observer.Expect('ref_e_opt', 'Opt Cap must not be Alpha in P96 Rec Caption: Code Cap=E1|TestField');
        Observer.Expect('same_e_opt', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure NoValue_FilledRow_AllTypes()
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
        H.ObservePair(Observer, 'f_code', H.RecNoValue(Full,1), H.RefNoValue(Full,1));
        H.ObservePair(Observer, 'f_txt', H.RecNoValue(Full,2), H.RefNoValue(Full,2));
        H.ObservePair(Observer, 'f_cd', H.RecNoValue(Full,3), H.RefNoValue(Full,3));
        H.ObservePair(Observer, 'f_num', H.RecNoValue(Full,4), H.RefNoValue(Full,4));
        H.ObservePair(Observer, 'f_big', H.RecNoValue(Full,5), H.RefNoValue(Full,5));
        H.ObservePair(Observer, 'f_amt', H.RecNoValue(Full,6), H.RefNoValue(Full,6));
        H.ObservePair(Observer, 'f_flag', H.RecNoValue(Full,7), H.RefNoValue(Full,7));
        H.ObservePair(Observer, 'f_dt', H.RecNoValue(Full,8), H.RefNoValue(Full,8));
        Observer.Expect('rec_f_code', 'ok');
        Observer.Expect('ref_f_code', 'ok');
        Observer.Expect('same_f_code', 'Yes');
        Observer.Expect('rec_f_txt', 'ok');
        Observer.Expect('ref_f_txt', 'ok');
        Observer.Expect('same_f_txt', 'Yes');
        Observer.Expect('rec_f_cd', 'ok');
        Observer.Expect('ref_f_cd', 'ok');
        Observer.Expect('same_f_cd', 'Yes');
        Observer.Expect('rec_f_num', 'ok');
        Observer.Expect('ref_f_num', 'ok');
        Observer.Expect('same_f_num', 'Yes');
        Observer.Expect('rec_f_big', 'ok');
        Observer.Expect('ref_f_big', 'ok');
        Observer.Expect('same_f_big', 'Yes');
        Observer.Expect('rec_f_amt', 'ok');
        Observer.Expect('ref_f_amt', 'ok');
        Observer.Expect('same_f_amt', 'Yes');
        Observer.Expect('rec_f_flag', 'ok');
        Observer.Expect('ref_f_flag', 'ok');
        Observer.Expect('same_f_flag', 'Yes');
        Observer.Expect('rec_f_dt', 'ok');
        Observer.Expect('ref_f_dt', 'ok');
        Observer.Expect('same_f_dt', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure NoValue_FilledRow_AllTypes_Rest()
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
        H.ObservePair(Observer, 'f_tm', H.RecNoValue(Full,9), H.RefNoValue(Full,9));
        H.ObservePair(Observer, 'f_dtm', H.RecNoValue(Full,10), H.RefNoValue(Full,10));
        H.ObservePair(Observer, 'f_gd', H.RecNoValue(Full,11), H.RefNoValue(Full,11));
        H.ObservePair(Observer, 'f_kind', H.RecNoValue(Full,12), H.RefNoValue(Full,12));
        H.ObservePair(Observer, 'f_opt', H.RecNoValue(Full,13), H.RefNoValue(Full,13));
        Observer.Expect('rec_f_tm', 'ok');
        Observer.Expect('ref_f_tm', 'ok');
        Observer.Expect('same_f_tm', 'Yes');
        Observer.Expect('rec_f_dtm', 'ok');
        Observer.Expect('ref_f_dtm', 'ok');
        Observer.Expect('same_f_dtm', 'Yes');
        Observer.Expect('rec_f_gd', 'ok');
        Observer.Expect('ref_f_gd', 'ok');
        Observer.Expect('same_f_gd', 'Yes');
        Observer.Expect('rec_f_kind', 'ok');
        Observer.Expect('ref_f_kind', 'ok');
        Observer.Expect('same_f_kind', 'Yes');
        Observer.Expect('rec_f_opt', 'ok');
        Observer.Expect('ref_f_opt', 'ok');
        Observer.Expect('same_f_opt', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Empty_Field_Against_Default_Value()
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
        H.ObservePair(Observer, 'txt_blank_vs_empty', H.RecT(Empty,2,''), H.RefV(Empty,2,''));
        H.ObservePair(Observer, 'num_zero', H.RecI(Empty,4,0), H.RefV(Empty,4,0));
        H.ObservePair(Observer, 'num_one', H.RecI(Empty,4,1), H.RefV(Empty,4,1));
        H.ObservePair(Observer, 'amt_zero', H.RecD(Empty,6,0), H.RefV(Empty,6,0.0));
        H.ObservePair(Observer, 'flag_false', H.RecBool(Empty,false), H.RefV(Empty,7,false));
        H.ObservePair(Observer, 'kind_first', H.RecOptMember(Empty,1), H.RefV(Empty,13,0));
        Observer.Expect('rec_txt_blank_vs_empty', 'ok');
        Observer.Expect('ref_txt_blank_vs_empty', 'ok');
        Observer.Expect('same_txt_blank_vs_empty', 'Yes');
        Observer.Expect('rec_num_zero', 'ok');
        Observer.Expect('ref_num_zero', 'ok');
        Observer.Expect('same_num_zero', 'Yes');
        Observer.Expect('rec_num_one', 'Num Cap must be equal to ''1''  in P96 Rec Caption: Code Cap=E1. Current value is ''0''.|TestField');
        Observer.Expect('ref_num_one', 'Num Cap must be equal to ''1''  in P96 Rec Caption: Code Cap=E1. Current value is ''0''.|TestField');
        Observer.Expect('same_num_one', 'Yes');
        Observer.Expect('rec_amt_zero', 'ok');
        Observer.Expect('ref_amt_zero', 'ok');
        Observer.Expect('same_amt_zero', 'Yes');
        Observer.Expect('rec_flag_false', 'ok');
        Observer.Expect('ref_flag_false', 'ok');
        Observer.Expect('same_flag_false', 'Yes');
        Observer.Expect('rec_kind_first', 'ok');
        Observer.Expect('ref_kind_first', 'ok');
        Observer.Expect('same_kind_first', 'Yes');
        Observer.Verify();
    end;
}
