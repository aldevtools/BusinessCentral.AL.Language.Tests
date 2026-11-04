// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Fixtures used: table 70738, enum 70739, codeunit 70740 (P96Objects.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Record.TestField(Field, Value) with Text, Code and Label values on Text and Code fields: text and code of the error, compared with FieldRef.TestField(Variant)
// BC versions: 29 (27 and 28 by CI)

codeunit 70741 "LT P96 Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Text_Field_Text_Value()
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
        H.ObservePair(Observer, 'txt_equal', H.RecT(Full,2,'Hello'), H.RefV(Full,2,'Hello'));
        H.ObservePair(Observer, 'txt_case', H.RecT(Full,2,'HELLO'), H.RefV(Full,2,'HELLO'));
        H.ObservePair(Observer, 'txt_diff', H.RecT(Full,2,'Other'), H.RefV(Full,2,'Other'));
        H.ObservePair(Observer, 'txt_trailing_blank', H.RecT(Full,2,'Hello '), H.RefV(Full,2,'Hello '));
        H.ObservePair(Observer, 'txt_leading_blank', H.RecT(Full,2,' Hello'), H.RefV(Full,2,' Hello'));
        H.ObservePair(Observer, 'txt_empty_value', H.RecT(Full,2,''), H.RefV(Full,2,''));
        H.ObservePair(Observer, 'txt_prefix', H.RecT(Full,2,'Hell'), H.RefV(Full,2,'Hell'));
        H.ObservePair(Observer, 'txt_unicode', H.RecT(Full,2,'Héllo'), H.RefV(Full,2,'Héllo'));
        Observer.Expect('rec_txt_equal', 'ok');
        Observer.Expect('ref_txt_equal', 'ok');
        Observer.Expect('same_txt_equal', 'Yes');
        Observer.Expect('rec_txt_case', 'Txt Cap must be equal to ''HELLO''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('ref_txt_case', 'Txt Cap must be equal to ''HELLO''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('same_txt_case', 'Yes');
        Observer.Expect('rec_txt_diff', 'Txt Cap must be equal to ''Other''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('ref_txt_diff', 'Txt Cap must be equal to ''Other''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('same_txt_diff', 'Yes');
        Observer.Expect('rec_txt_trailing_blank', 'Txt Cap must be equal to ''Hello ''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('ref_txt_trailing_blank', 'Txt Cap must be equal to ''Hello ''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('same_txt_trailing_blank', 'Yes');
        Observer.Expect('rec_txt_leading_blank', 'Txt Cap must be equal to '' Hello''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('ref_txt_leading_blank', 'Txt Cap must be equal to '' Hello''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('same_txt_leading_blank', 'Yes');
        Observer.Expect('rec_txt_empty_value', 'Txt Cap must be equal to ''''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('ref_txt_empty_value', 'Txt Cap must be equal to ''''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('same_txt_empty_value', 'Yes');
        Observer.Expect('rec_txt_prefix', 'Txt Cap must be equal to ''Hell''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('ref_txt_prefix', 'Txt Cap must be equal to ''Hell''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('same_txt_prefix', 'Yes');
        Observer.Expect('rec_txt_unicode', 'Txt Cap must be equal to ''Héllo''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('ref_txt_unicode', 'Txt Cap must be equal to ''Héllo''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('same_txt_unicode', 'Yes');
        Observer.Verify();
    end;





    [Test]
    procedure Text_Field_Code_Value()
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
        H.ObservePair(Observer, 'cd_equal', H.RecT(Full,3,'ABC'), H.RefV(Full,3,'ABC'));
        H.ObservePair(Observer, 'cd_lower', H.RecT(Full,3,'abc'), H.RefV(Full,3,'abc'));
        H.ObservePair(Observer, 'cd_diff', H.RecT(Full,3,'ABD'), H.RefV(Full,3,'ABD'));
        H.ObservePair(Observer, 'cd_empty_value', H.RecT(Full,3,''), H.RefV(Full,3,''));
        H.ObservePair(Observer, 'cd_trailing_blank', H.RecT(Full,3,'ABC '), H.RefV(Full,3,'ABC '));
        H.ObservePair(Observer, 'pk_equal', H.RecT(Full,1,'K1'), H.RefV(Full,1,'K1'));
        H.ObservePair(Observer, 'pk_diff', H.RecT(Full,1,'K2'), H.RefV(Full,1,'K2'));
        H.ObservePair(Observer, 'pk_lower', H.RecT(Full,1,'k1'), H.RefV(Full,1,'k1'));
        Observer.Expect('rec_cd_equal', 'ok');
        Observer.Expect('ref_cd_equal', 'ok');
        Observer.Expect('same_cd_equal', 'Yes');
        Observer.Expect('rec_cd_lower', 'ok');
        Observer.Expect('ref_cd_lower', 'ok');
        Observer.Expect('same_cd_lower', 'Yes');
        Observer.Expect('rec_cd_diff', 'Cd Cap must be equal to ''ABD''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABC''.|TestField');
        Observer.Expect('ref_cd_diff', 'Cd Cap must be equal to ''ABD''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABC''.|TestField');
        Observer.Expect('same_cd_diff', 'Yes');
        Observer.Expect('rec_cd_empty_value', 'Cd Cap must be equal to ''''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABC''.|TestField');
        Observer.Expect('ref_cd_empty_value', 'Cd Cap must be equal to ''''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABC''.|TestField');
        Observer.Expect('same_cd_empty_value', 'Yes');
        Observer.Expect('rec_cd_trailing_blank', 'Cd Cap must be equal to ''ABC ''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABC''.|TestField');
        Observer.Expect('ref_cd_trailing_blank', 'Cd Cap must be equal to ''ABC ''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABC''.|TestField');
        Observer.Expect('same_cd_trailing_blank', 'Yes');
        Observer.Expect('rec_pk_equal', 'ok');
        Observer.Expect('ref_pk_equal', 'ok');
        Observer.Expect('same_pk_equal', 'Yes');
        Observer.Expect('rec_pk_diff', 'Code Cap must be equal to ''K2''  in P96 Rec Caption: Code Cap=K1. Current value is ''K1''.|TestField');
        Observer.Expect('ref_pk_diff', 'Code Cap must be equal to ''K2''  in P96 Rec Caption: Code Cap=K1. Current value is ''K1''.|TestField');
        Observer.Expect('same_pk_diff', 'Yes');
        Observer.Expect('rec_pk_lower', 'ok');
        Observer.Expect('ref_pk_lower', 'ok');
        Observer.Expect('same_pk_lower', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Text_Field_CodeTyped_Value()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT P96 Helper";
        Full: Record "LT P96 Rec";
        Empty: Record "LT P96 Rec";
        CdVal: Code[20];
    begin
        Full.DeleteAll();
        H.Seed();
        Full.Get('K1');
        Empty.Get('E1');
        CdVal := 'ABC';
        H.ObservePair(Observer, 'cdv_equal', H.RecC(Full,3,'ABC'), H.RefV(Full,3,CdVal));
        H.ObservePair(Observer, 'cdv_diff', H.RecC(Full,3,'XYZ'), H.RefV(Full,3,CdVal));
        H.ObservePair(Observer, 'cdv_txt_field_equal', H.RecC(Full,2,'HELLO'), H.RefV(Full,2,CdVal));
        H.ObservePair(Observer, 'cdv_txt_field_diff', H.RecC(Full,2,'OTHER'), H.RefV(Full,2,CdVal));
        H.ObservePair(Observer, 'cdv_empty', H.RecC(Full,3,''), H.RefV(Full,3,CdVal));
        H.ObservePair(Observer, 'cdv_pk', H.RecC(Full,1,'K1'), H.RefV(Full,1,CdVal));
        Observer.Expect('rec_cdv_equal', 'ok');
        Observer.Expect('ref_cdv_equal', 'ok');
        Observer.Expect('same_cdv_equal', 'Yes');
        Observer.Expect('rec_cdv_diff', 'Cd Cap must be equal to ''XYZ''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABC''.|TestField');
        Observer.Expect('ref_cdv_diff', 'ok');
        Observer.Expect('same_cdv_diff', 'No');
        Observer.Expect('rec_cdv_txt_field_equal', 'Txt Cap must be equal to ''HELLO''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('ref_cdv_txt_field_equal', 'Txt Cap must be equal to ''ABC''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('same_cdv_txt_field_equal', 'No');
        Observer.Expect('rec_cdv_txt_field_diff', 'Txt Cap must be equal to ''OTHER''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('ref_cdv_txt_field_diff', 'Txt Cap must be equal to ''ABC''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('same_cdv_txt_field_diff', 'No');
        Observer.Expect('rec_cdv_empty', 'Cd Cap must be equal to ''''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABC''.|TestField');
        Observer.Expect('ref_cdv_empty', 'ok');
        Observer.Expect('same_cdv_empty', 'No');
        Observer.Expect('rec_cdv_pk', 'ok');
        Observer.Expect('ref_cdv_pk', 'Code Cap must be equal to ''ABC''  in P96 Rec Caption: Code Cap=K1. Current value is ''K1''.|TestField');
        Observer.Expect('same_cdv_pk', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Text_Field_Label_Value()
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
        H.ObservePair(Observer, 'lbl_txt_equal', H.RecL(Full,2,1), H.RefV(Full,2,'Hello'));
        H.ObservePair(Observer, 'lbl_txt_diff', H.RecL(Full,2,2), H.RefV(Full,2,'Other'));
        H.ObservePair(Observer, 'lbl_txt_empty', H.RecL(Full,2,3), H.RefV(Full,2,''));
        H.ObservePair(Observer, 'lbl_cd_diff', H.RecL(Full,3,2), H.RefV(Full,3,'Other'));
        H.ObservePair(Observer, 'lbl_cd_empty', H.RecL(Full,3,3), H.RefV(Full,3,''));
        H.ObservePair(Observer, 'lbl_cd_equal_case', H.RecL(Full,3,1), H.RefV(Full,3,'Hello'));
        Observer.Expect('rec_lbl_txt_equal', 'ok');
        Observer.Expect('ref_lbl_txt_equal', 'ok');
        Observer.Expect('same_lbl_txt_equal', 'Yes');
        Observer.Expect('rec_lbl_txt_diff', 'Txt Cap must be equal to ''Other''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('ref_lbl_txt_diff', 'Txt Cap must be equal to ''Other''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('same_lbl_txt_diff', 'Yes');
        Observer.Expect('rec_lbl_txt_empty', 'Txt Cap must be equal to ''''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('ref_lbl_txt_empty', 'Txt Cap must be equal to ''''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('same_lbl_txt_empty', 'Yes');
        Observer.Expect('rec_lbl_cd_diff', 'Cd Cap must be equal to ''Other''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABC''.|TestField');
        Observer.Expect('ref_lbl_cd_diff', 'Cd Cap must be equal to ''Other''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABC''.|TestField');
        Observer.Expect('same_lbl_cd_diff', 'Yes');
        Observer.Expect('rec_lbl_cd_empty', 'Cd Cap must be equal to ''''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABC''.|TestField');
        Observer.Expect('ref_lbl_cd_empty', 'Cd Cap must be equal to ''''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABC''.|TestField');
        Observer.Expect('same_lbl_cd_empty', 'Yes');
        Observer.Expect('rec_lbl_cd_equal_case', 'Cd Cap must be equal to ''Hello''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABC''.|TestField');
        Observer.Expect('ref_lbl_cd_equal_case', 'Cd Cap must be equal to ''Hello''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABC''.|TestField');
        Observer.Expect('same_lbl_cd_equal_case', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Text_Value_On_Empty_Fields()
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
        H.ObservePair(Observer, 'empty_txt_empty', H.RecT(Empty,2,''), H.RefV(Empty,2,''));
        H.ObservePair(Observer, 'empty_txt_value', H.RecT(Empty,2,'Hello'), H.RefV(Empty,2,'Hello'));
        H.ObservePair(Observer, 'empty_cd_empty', H.RecT(Empty,3,''), H.RefV(Empty,3,''));
        H.ObservePair(Observer, 'empty_cd_value', H.RecT(Empty,3,'ABC'), H.RefV(Empty,3,'ABC'));
        H.ObservePair(Observer, 'empty_cd_blank', H.RecT(Empty,3,' '), H.RefV(Empty,3,' '));
        H.ObservePair(Observer, 'empty_txt_blank', H.RecT(Empty,2,' '), H.RefV(Empty,2,' '));
        H.ObservePair(Observer, 'empty_lbl_empty', H.RecL(Empty,2,3), H.RefV(Empty,2,''));
        H.ObservePair(Observer, 'empty_lbl_value', H.RecL(Empty,2,1), H.RefV(Empty,2,'Hello'));
        Observer.Expect('rec_empty_txt_empty', 'ok');
        Observer.Expect('ref_empty_txt_empty', 'ok');
        Observer.Expect('same_empty_txt_empty', 'Yes');
        Observer.Expect('rec_empty_txt_value', 'Txt Cap must be equal to ''Hello''  in P96 Rec Caption: Code Cap=E1. Current value is ''''.|TestField');
        Observer.Expect('ref_empty_txt_value', 'Txt Cap must be equal to ''Hello''  in P96 Rec Caption: Code Cap=E1. Current value is ''''.|TestField');
        Observer.Expect('same_empty_txt_value', 'Yes');
        Observer.Expect('rec_empty_cd_empty', 'ok');
        Observer.Expect('ref_empty_cd_empty', 'ok');
        Observer.Expect('same_empty_cd_empty', 'Yes');
        Observer.Expect('rec_empty_cd_value', 'Cd Cap must be equal to ''ABC''  in P96 Rec Caption: Code Cap=E1. Current value is ''''.|TestField');
        Observer.Expect('ref_empty_cd_value', 'Cd Cap must be equal to ''ABC''  in P96 Rec Caption: Code Cap=E1. Current value is ''''.|TestField');
        Observer.Expect('same_empty_cd_value', 'Yes');
        Observer.Expect('rec_empty_cd_blank', 'Cd Cap must be equal to '' ''  in P96 Rec Caption: Code Cap=E1. Current value is ''''.|TestField');
        Observer.Expect('ref_empty_cd_blank', 'Cd Cap must be equal to '' ''  in P96 Rec Caption: Code Cap=E1. Current value is ''''.|TestField');
        Observer.Expect('same_empty_cd_blank', 'Yes');
        Observer.Expect('rec_empty_txt_blank', 'Txt Cap must be equal to '' ''  in P96 Rec Caption: Code Cap=E1. Current value is ''''.|TestField');
        Observer.Expect('ref_empty_txt_blank', 'Txt Cap must be equal to '' ''  in P96 Rec Caption: Code Cap=E1. Current value is ''''.|TestField');
        Observer.Expect('same_empty_txt_blank', 'Yes');
        Observer.Expect('rec_empty_lbl_empty', 'ok');
        Observer.Expect('ref_empty_lbl_empty', 'ok');
        Observer.Expect('same_empty_lbl_empty', 'Yes');
        Observer.Expect('rec_empty_lbl_value', 'Txt Cap must be equal to ''Hello''  in P96 Rec Caption: Code Cap=E1. Current value is ''''.|TestField');
        Observer.Expect('ref_empty_lbl_value', 'Txt Cap must be equal to ''Hello''  in P96 Rec Caption: Code Cap=E1. Current value is ''''.|TestField');
        Observer.Expect('same_empty_lbl_value', 'Yes');
        Observer.Verify();
    end;
}
