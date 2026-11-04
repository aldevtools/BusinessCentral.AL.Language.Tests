// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Fixtures used: table 70738, enum 70739, codeunit 70740 (P96Objects.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Record.TestField / FieldRef.TestField with ErrorInfo overloads: Message, Title, DetailedMessage set or not; value and no-value forms
// BC versions: 29 (27 and 28 by CI)

codeunit 70747 "LT P96 ErrorInfo"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Info_Text_Value_Modes()
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
        H.ObservePair(Observer, 'mode0_diff', H.RecInfoT(Full,2,'Other',0), H.RefInfoV(Full,2,'Other',0));
        H.ObservePair(Observer, 'mode1_message', H.RecInfoT(Full,2,'Other',1), H.RefInfoV(Full,2,'Other',1));
        H.ObservePair(Observer, 'mode3_title', H.RecInfoT(Full,2,'Other',3), H.RefInfoV(Full,2,'Other',3));
        H.ObservePair(Observer, 'mode4_detail', H.RecInfoT(Full,2,'Other',4), H.RefInfoV(Full,2,'Other',4));
        H.ObservePair(Observer, 'mode5_all', H.RecInfoT(Full,2,'Other',5), H.RefInfoV(Full,2,'Other',5));
        H.ObservePair(Observer, 'mode1_match', H.RecInfoT(Full,2,'Hello',1), H.RefInfoV(Full,2,'Hello',1));
        H.ObservePair(Observer, 'mode1_code_diff', H.RecInfoT(Full,3,'XYZ',1), H.RefInfoV(Full,3,'XYZ',1));
        H.ObservePair(Observer, 'mode0_pk_diff', H.RecInfoT(Full,1,'K9',0), H.RefInfoV(Full,1,'K9',0));
        Observer.Expect('rec_mode0_diff', 'Txt Cap must be equal to ''Other''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('ref_mode0_diff', 'Txt Cap must be equal to ''Other''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('same_mode0_diff', 'Yes');
        Observer.Expect('rec_mode1_message', 'Txt Cap must be equal to ''Other''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('ref_mode1_message', 'Txt Cap must be equal to ''Other''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('same_mode1_message', 'Yes');
        Observer.Expect('rec_mode3_title', 'Txt Cap must be equal to ''Other''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('ref_mode3_title', 'Txt Cap must be equal to ''Other''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('same_mode3_title', 'Yes');
        Observer.Expect('rec_mode4_detail', 'Txt Cap must be equal to ''Other''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('ref_mode4_detail', 'Txt Cap must be equal to ''Other''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('same_mode4_detail', 'Yes');
        Observer.Expect('rec_mode5_all', 'Txt Cap must be equal to ''Other''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('ref_mode5_all', 'Txt Cap must be equal to ''Other''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('same_mode5_all', 'Yes');
        Observer.Expect('rec_mode1_match', 'ok');
        Observer.Expect('ref_mode1_match', 'ok');
        Observer.Expect('same_mode1_match', 'Yes');
        Observer.Expect('rec_mode1_code_diff', 'Cd Cap must be equal to ''XYZ''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABC''.|TestField');
        Observer.Expect('ref_mode1_code_diff', 'Cd Cap must be equal to ''XYZ''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABC''.|TestField');
        Observer.Expect('same_mode1_code_diff', 'Yes');
        Observer.Expect('rec_mode0_pk_diff', 'Code Cap must be equal to ''K9''  in P96 Rec Caption: Code Cap=K1. Current value is ''K1''.|TestField');
        Observer.Expect('ref_mode0_pk_diff', 'Code Cap must be equal to ''K9''  in P96 Rec Caption: Code Cap=K1. Current value is ''K1''.|TestField');
        Observer.Expect('same_mode0_pk_diff', 'Yes');
        Observer.Verify();
    end;





    [Test]
    procedure Info_Value_Types_A_1()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT P96 Helper";
        Full: Record "LT P96 Rec";
        Empty: Record "LT P96 Rec";
        BigV: BigInteger;
    begin
        Full.DeleteAll();
        H.Seed();
        Full.Get('K1');
        Empty.Get('E1');
        BigV := 7;
        H.ObservePair(Observer, 'mode1_num', H.RecInfoV(Full,1,1), H.RefInfoV(Full,4,99,1));
        H.ObservePair(Observer, 'mode1_big', H.RecInfoV(Full,2,1), H.RefInfoV(Full,5,BigV,1));
        H.ObservePair(Observer, 'mode1_amt', H.RecInfoV(Full,3,1), H.RefInfoV(Full,6,9.5,1));
        H.ObservePair(Observer, 'mode1_flag', H.RecInfoV(Full,4,1), H.RefInfoV(Full,7,false,1));
        H.ObservePair(Observer, 'mode1_dt', H.RecInfoV(Full,5,1), H.RefInfoV(Full,8,DMY2Date(1,1,2000),1));
        H.ObservePair(Observer, 'mode0_num', H.RecInfoV(Full,1,0), H.RefInfoV(Full,4,99,0));
        H.ObservePair(Observer, 'mode0_big', H.RecInfoV(Full,2,0), H.RefInfoV(Full,5,BigV,0));
        H.ObservePair(Observer, 'mode0_amt', H.RecInfoV(Full,3,0), H.RefInfoV(Full,6,9.5,0));
        Observer.Expect('rec_mode1_num', 'Num Cap must be equal to ''99''  in P96 Rec Caption: Code Cap=K1. Current value is ''5''.|TestField');
        Observer.Expect('ref_mode1_num', 'Num Cap must be equal to ''99''  in P96 Rec Caption: Code Cap=K1. Current value is ''5''.|TestField');
        Observer.Expect('same_mode1_num', 'Yes');
        Observer.Expect('rec_mode1_big', 'Big Cap must be equal to ''7''  in P96 Rec Caption: Code Cap=K1. Current value is ''8589934588''.|TestField');
        Observer.Expect('ref_mode1_big', 'Big Cap must be equal to ''7''  in P96 Rec Caption: Code Cap=K1. Current value is ''8589934588''.|TestField');
        Observer.Expect('same_mode1_big', 'Yes');
        Observer.Expect('rec_mode1_amt', 'Amt Cap must be equal to ''9.5''  in P96 Rec Caption: Code Cap=K1. Current value is ''2.5''.|TestField');
        Observer.Expect('ref_mode1_amt', 'Amt Cap must be equal to ''9.5''  in P96 Rec Caption: Code Cap=K1. Current value is ''2.5''.|TestField');
        Observer.Expect('same_mode1_amt', 'Yes');
        Observer.Expect('rec_mode1_flag', 'Flag Cap must be equal to ''No''  in P96 Rec Caption: Code Cap=K1. Current value is ''Yes''.|TestField');
        Observer.Expect('ref_mode1_flag', 'Flag Cap must be equal to ''No''  in P96 Rec Caption: Code Cap=K1. Current value is ''Yes''.|TestField');
        Observer.Expect('same_mode1_flag', 'Yes');
        Observer.Expect('rec_mode1_dt', 'Dt Cap must be equal to ''01/01/00''  in P96 Rec Caption: Code Cap=K1. Current value is ''06/15/21''.|TestField');
        Observer.Expect('ref_mode1_dt', 'Dt Cap must be equal to ''01/01/00''  in P96 Rec Caption: Code Cap=K1. Current value is ''06/15/21''.|TestField');
        Observer.Expect('same_mode1_dt', 'Yes');
        Observer.Expect('rec_mode0_num', 'Num Cap must be equal to ''99''  in P96 Rec Caption: Code Cap=K1. Current value is ''5''.|TestField');
        Observer.Expect('ref_mode0_num', 'Num Cap must be equal to ''99''  in P96 Rec Caption: Code Cap=K1. Current value is ''5''.|TestField');
        Observer.Expect('same_mode0_num', 'Yes');
        Observer.Expect('rec_mode0_big', 'Big Cap must be equal to ''7''  in P96 Rec Caption: Code Cap=K1. Current value is ''8589934588''.|TestField');
        Observer.Expect('ref_mode0_big', 'Big Cap must be equal to ''7''  in P96 Rec Caption: Code Cap=K1. Current value is ''8589934588''.|TestField');
        Observer.Expect('same_mode0_big', 'Yes');
        Observer.Expect('rec_mode0_amt', 'Amt Cap must be equal to ''9.5''  in P96 Rec Caption: Code Cap=K1. Current value is ''2.5''.|TestField');
        Observer.Expect('ref_mode0_amt', 'Amt Cap must be equal to ''9.5''  in P96 Rec Caption: Code Cap=K1. Current value is ''2.5''.|TestField');
        Observer.Expect('same_mode0_amt', 'Yes');
        Observer.Verify();
    end;





    [Test]
    procedure Info_Value_Types_A_2()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT P96 Helper";
        Full: Record "LT P96 Rec";
        Empty: Record "LT P96 Rec";
        BigV: BigInteger;
    begin
        Full.DeleteAll();
        H.Seed();
        Full.Get('K1');
        Empty.Get('E1');
        BigV := 7;
        H.ObservePair(Observer, 'mode0_flag', H.RecInfoV(Full,4,0), H.RefInfoV(Full,7,false,0));
        H.ObservePair(Observer, 'mode0_dt', H.RecInfoV(Full,5,0), H.RefInfoV(Full,8,DMY2Date(1,1,2000),0));
        Observer.Expect('rec_mode0_flag', 'Flag Cap must be equal to ''No''  in P96 Rec Caption: Code Cap=K1. Current value is ''Yes''.|TestField');
        Observer.Expect('ref_mode0_flag', 'Flag Cap must be equal to ''No''  in P96 Rec Caption: Code Cap=K1. Current value is ''Yes''.|TestField');
        Observer.Expect('same_mode0_flag', 'Yes');
        Observer.Expect('rec_mode0_dt', 'Dt Cap must be equal to ''01/01/00''  in P96 Rec Caption: Code Cap=K1. Current value is ''06/15/21''.|TestField');
        Observer.Expect('ref_mode0_dt', 'Dt Cap must be equal to ''01/01/00''  in P96 Rec Caption: Code Cap=K1. Current value is ''06/15/21''.|TestField');
        Observer.Expect('same_mode0_dt', 'Yes');
        Observer.Verify();
    end;

#if BC28PLUS
    [Test]
    procedure Info_Value_Types_B_1()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT P96 Helper";
        Full: Record "LT P96 Rec";
        Empty: Record "LT P96 Rec";
        G9: Guid;
        EZero: Enum "LT P96 Kind";
    begin
        Full.DeleteAll();
        H.Seed();
        Full.Get('K1');
        Empty.Get('E1');
        Evaluate(G9, '{99999999-2222-3333-4444-555555555555}');
        EZero := EZero::Zero;
        H.ObservePair(Observer, 'mode1_tm', H.RecInfoV(Full,6,1), H.RefInfoV(Full,9,010000T,1));
        H.ObservePair(Observer, 'mode1_dtm', H.RecInfoV(Full,7,1), H.RefInfoV(Full,10,CreateDateTime(DMY2Date(1,1,2000),010000T),1));
        H.ObservePair(Observer, 'mode1_gd', H.RecInfoV(Full,8,1), H.RefInfoV(Full,11,G9,1));
        H.ObservePair(Observer, 'mode1_kind', H.RecInfoV(Full,9,1), H.RefInfoV(Full,12,EZero,1));
        H.ObservePair(Observer, 'mode1_opt', H.RecInfoV(Full,10,1), H.RefInfoV(Full,13,2,1));
        H.ObservePair(Observer, 'mode0_tm', H.RecInfoV(Full,6,0), H.RefInfoV(Full,9,010000T,0));
        H.ObservePair(Observer, 'mode0_dtm', H.RecInfoV(Full,7,0), H.RefInfoV(Full,10,CreateDateTime(DMY2Date(1,1,2000),010000T),0));
        H.ObservePair(Observer, 'mode0_gd', H.RecInfoV(Full,8,0), H.RefInfoV(Full,11,G9,0));
        Observer.Expect('rec_mode1_tm', 'Tm Cap must be equal to '' 1:00:00 AM''  in P96 Rec Caption: Code Cap=K1. Current value is ''12:30:00 PM''.|TestField');
        Observer.Expect('ref_mode1_tm', 'Tm Cap must be equal to '' 1:00:00 AM''  in P96 Rec Caption: Code Cap=K1. Current value is ''12:30:00 PM''.|TestField');
        Observer.Expect('same_mode1_tm', 'Yes');
        Observer.Expect('rec_mode1_dtm', 'Dtm Cap must be equal to ''01/01/00 01:00 AM''  in P96 Rec Caption: Code Cap=K1. Current value is ''06/15/21 12:30 PM''.|TestField');
        Observer.Expect('ref_mode1_dtm', 'Dtm Cap must be equal to ''01/01/00 01:00 AM''  in P96 Rec Caption: Code Cap=K1. Current value is ''06/15/21 12:30 PM''.|TestField');
        Observer.Expect('same_mode1_dtm', 'Yes');
        Observer.Expect('rec_mode1_gd', 'Gd Cap must be equal to ''{99999999-2222-3333-4444-555555555555}''  in P96 Rec Caption: Code Cap=K1. Current value is ''{11111111-2222-3333-4444-555555555555}''.|TestField');
        Observer.Expect('ref_mode1_gd', 'Gd Cap must be equal to ''{99999999-2222-3333-4444-555555555555}''  in P96 Rec Caption: Code Cap=K1. Current value is ''{11111111-2222-3333-4444-555555555555}''.|TestField');
        Observer.Expect('same_mode1_gd', 'Yes');
        Observer.Expect('rec_mode1_kind', 'Kind Cap must be equal to ''Zero''  in P96 Rec Caption: Code Cap=K1. Current value is ''Two''.|TestField');
        Observer.Expect('ref_mode1_kind', 'Kind Cap must be equal to ''Zero''  in P96 Rec Caption: Code Cap=K1. Current value is ''Two''.|TestField');
        Observer.Expect('same_mode1_kind', 'Yes');
        Observer.Expect('rec_mode1_opt', 'Opt Cap must be equal to ''Gamma''  in P96 Rec Caption: Code Cap=K1. Current value is ''Beta''.|TestField');
        Observer.Expect('ref_mode1_opt', 'Opt Cap must be equal to ''Gamma''  in P96 Rec Caption: Code Cap=K1. Current value is ''Beta''.|TestField');
        Observer.Expect('same_mode1_opt', 'Yes');
        Observer.Expect('rec_mode0_tm', 'Tm Cap must be equal to '' 1:00:00 AM''  in P96 Rec Caption: Code Cap=K1. Current value is ''12:30:00 PM''.|TestField');
        Observer.Expect('ref_mode0_tm', 'Tm Cap must be equal to '' 1:00:00 AM''  in P96 Rec Caption: Code Cap=K1. Current value is ''12:30:00 PM''.|TestField');
        Observer.Expect('same_mode0_tm', 'Yes');
        Observer.Expect('rec_mode0_dtm', 'Dtm Cap must be equal to ''01/01/00 01:00 AM''  in P96 Rec Caption: Code Cap=K1. Current value is ''06/15/21 12:30 PM''.|TestField');
        Observer.Expect('ref_mode0_dtm', 'Dtm Cap must be equal to ''01/01/00 01:00 AM''  in P96 Rec Caption: Code Cap=K1. Current value is ''06/15/21 12:30 PM''.|TestField');
        Observer.Expect('same_mode0_dtm', 'Yes');
        Observer.Expect('rec_mode0_gd', 'Gd Cap must be equal to ''{99999999-2222-3333-4444-555555555555}''  in P96 Rec Caption: Code Cap=K1. Current value is ''{11111111-2222-3333-4444-555555555555}''.|TestField');
        Observer.Expect('ref_mode0_gd', 'Gd Cap must be equal to ''{99999999-2222-3333-4444-555555555555}''  in P96 Rec Caption: Code Cap=K1. Current value is ''{11111111-2222-3333-4444-555555555555}''.|TestField');
        Observer.Expect('same_mode0_gd', 'Yes');
        Observer.Verify();
    end;
#endif





    [Test]
    procedure Info_Value_Types_B_2()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT P96 Helper";
        Full: Record "LT P96 Rec";
        Empty: Record "LT P96 Rec";
        G9: Guid;
        EZero: Enum "LT P96 Kind";
    begin
        Full.DeleteAll();
        H.Seed();
        Full.Get('K1');
        Empty.Get('E1');
        Evaluate(G9, '{99999999-2222-3333-4444-555555555555}');
        EZero := EZero::Zero;
        H.ObservePair(Observer, 'mode0_kind', H.RecInfoV(Full,9,0), H.RefInfoV(Full,12,EZero,0));
        H.ObservePair(Observer, 'mode0_opt', H.RecInfoV(Full,10,0), H.RefInfoV(Full,13,2,0));
        Observer.Expect('rec_mode0_kind', 'Kind Cap must be equal to ''Zero''  in P96 Rec Caption: Code Cap=K1. Current value is ''Two''.|TestField');
        Observer.Expect('ref_mode0_kind', 'Kind Cap must be equal to ''Zero''  in P96 Rec Caption: Code Cap=K1. Current value is ''Two''.|TestField');
        Observer.Expect('same_mode0_kind', 'Yes');
        Observer.Expect('rec_mode0_opt', 'Opt Cap must be equal to ''Gamma''  in P96 Rec Caption: Code Cap=K1. Current value is ''Beta''.|TestField');
        Observer.Expect('ref_mode0_opt', 'Opt Cap must be equal to ''Gamma''  in P96 Rec Caption: Code Cap=K1. Current value is ''Beta''.|TestField');
        Observer.Expect('same_mode0_opt', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Info_NoValue_Empty_Modes_1()
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
        H.ObservePair(Observer, 'mode0_txt', H.RecInfoNoValue(Empty,2,0), H.RefInfoNoValue(Empty,2,0));
        H.ObservePair(Observer, 'mode0_num', H.RecInfoNoValue(Empty,4,0), H.RefInfoNoValue(Empty,4,0));
        H.ObservePair(Observer, 'mode0_dt', H.RecInfoNoValue(Empty,8,0), H.RefInfoNoValue(Empty,8,0));
        H.ObservePair(Observer, 'mode0_kind', H.RecInfoNoValue(Empty,12,0), H.RefInfoNoValue(Empty,12,0));
        H.ObservePair(Observer, 'mode0_opt', H.RecInfoNoValue(Empty,13,0), H.RefInfoNoValue(Empty,13,0));
        H.ObservePair(Observer, 'mode1_txt', H.RecInfoNoValue(Empty,2,1), H.RefInfoNoValue(Empty,2,1));
        H.ObservePair(Observer, 'mode1_num', H.RecInfoNoValue(Empty,4,1), H.RefInfoNoValue(Empty,4,1));
        H.ObservePair(Observer, 'mode1_dt', H.RecInfoNoValue(Empty,8,1), H.RefInfoNoValue(Empty,8,1));
        Observer.Expect('rec_mode0_txt', 'Txt Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('ref_mode0_txt', 'Txt Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('same_mode0_txt', 'Yes');
        Observer.Expect('rec_mode0_num', 'Num Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('ref_mode0_num', 'Num Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('same_mode0_num', 'Yes');
        Observer.Expect('rec_mode0_dt', 'Dt Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('ref_mode0_dt', 'Dt Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('same_mode0_dt', 'Yes');
        Observer.Expect('rec_mode0_kind', 'Kind Cap must not be Zero in P96 Rec Caption: Code Cap=E1|TestField');
        Observer.Expect('ref_mode0_kind', 'Kind Cap must not be Zero in P96 Rec Caption: Code Cap=E1|TestField');
        Observer.Expect('same_mode0_kind', 'Yes');
        Observer.Expect('rec_mode0_opt', 'Opt Cap must not be Alpha in P96 Rec Caption: Code Cap=E1|TestField');
        Observer.Expect('ref_mode0_opt', 'Opt Cap must not be Alpha in P96 Rec Caption: Code Cap=E1|TestField');
        Observer.Expect('same_mode0_opt', 'Yes');
        Observer.Expect('rec_mode1_txt', 'Txt Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('ref_mode1_txt', 'Txt Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('same_mode1_txt', 'Yes');
        Observer.Expect('rec_mode1_num', 'Num Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('ref_mode1_num', 'Num Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('same_mode1_num', 'Yes');
        Observer.Expect('rec_mode1_dt', 'Dt Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('ref_mode1_dt', 'Dt Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('same_mode1_dt', 'Yes');
        Observer.Verify();
    end;





    [Test]
    procedure Info_NoValue_Empty_Modes_2()
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
        H.ObservePair(Observer, 'mode1_kind', H.RecInfoNoValue(Empty,12,1), H.RefInfoNoValue(Empty,12,1));
        H.ObservePair(Observer, 'mode1_opt', H.RecInfoNoValue(Empty,13,1), H.RefInfoNoValue(Empty,13,1));
        Observer.Expect('rec_mode1_kind', 'Kind Cap must not be Zero in P96 Rec Caption: Code Cap=E1|TestField');
        Observer.Expect('ref_mode1_kind', 'Kind Cap must not be Zero in P96 Rec Caption: Code Cap=E1|TestField');
        Observer.Expect('same_mode1_kind', 'Yes');
        Observer.Expect('rec_mode1_opt', 'Opt Cap must not be Alpha in P96 Rec Caption: Code Cap=E1|TestField');
        Observer.Expect('ref_mode1_opt', 'Opt Cap must not be Alpha in P96 Rec Caption: Code Cap=E1|TestField');
        Observer.Expect('same_mode1_opt', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Info_NoValue_Empty_More_Modes_1()
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
        H.ObservePair(Observer, 'mode3_txt', H.RecInfoNoValue(Empty,2,3), H.RefInfoNoValue(Empty,2,3));
        H.ObservePair(Observer, 'mode3_num', H.RecInfoNoValue(Empty,4,3), H.RefInfoNoValue(Empty,4,3));
        H.ObservePair(Observer, 'mode3_dt', H.RecInfoNoValue(Empty,8,3), H.RefInfoNoValue(Empty,8,3));
        H.ObservePair(Observer, 'mode5_txt', H.RecInfoNoValue(Empty,2,5), H.RefInfoNoValue(Empty,2,5));
        H.ObservePair(Observer, 'mode5_num', H.RecInfoNoValue(Empty,4,5), H.RefInfoNoValue(Empty,4,5));
        H.ObservePair(Observer, 'mode5_dt', H.RecInfoNoValue(Empty,8,5), H.RefInfoNoValue(Empty,8,5));
        H.ObservePair(Observer, 'filled_txt', H.RecInfoNoValue(Full,2,1), H.RefInfoNoValue(Full,2,1));
        H.ObservePair(Observer, 'filled_kind', H.RecInfoNoValue(Full,12,1), H.RefInfoNoValue(Full,12,1));
        Observer.Expect('rec_mode3_txt', 'Txt Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('ref_mode3_txt', 'Txt Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('same_mode3_txt', 'Yes');
        Observer.Expect('rec_mode3_num', 'Num Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('ref_mode3_num', 'Num Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('same_mode3_num', 'Yes');
        Observer.Expect('rec_mode3_dt', 'Dt Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('ref_mode3_dt', 'Dt Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('same_mode3_dt', 'Yes');
        Observer.Expect('rec_mode5_txt', 'Txt Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('ref_mode5_txt', 'Txt Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('same_mode5_txt', 'Yes');
        Observer.Expect('rec_mode5_num', 'Num Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('ref_mode5_num', 'Num Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('same_mode5_num', 'Yes');
        Observer.Expect('rec_mode5_dt', 'Dt Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('ref_mode5_dt', 'Dt Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.|TestField');
        Observer.Expect('same_mode5_dt', 'Yes');
        Observer.Expect('rec_filled_txt', 'ok');
        Observer.Expect('ref_filled_txt', 'ok');
        Observer.Expect('same_filled_txt', 'Yes');
        Observer.Expect('rec_filled_kind', 'ok');
        Observer.Expect('ref_filled_kind', 'ok');
        Observer.Expect('same_filled_kind', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Info_NoValue_Empty_More_Modes_2()
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
        H.ObservePair(Observer, 'filled_opt', H.RecInfoNoValue(Full,13,1), H.RefInfoNoValue(Full,13,1));
        Observer.Expect('rec_filled_opt', 'ok');
        Observer.Expect('ref_filled_opt', 'ok');
        Observer.Expect('same_filled_opt', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Info_Direct_Asserterror()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT P96 Helper";
        Full: Record "LT P96 Rec";
        Empty: Record "LT P96 Rec";
        Info: ErrorInfo;
        Plain: ErrorInfo;
    begin
        Full.DeleteAll();
        H.Seed();
        Full.Get('K1');
        Empty.Get('E1');
        Info.Message := 'Custom message';
        asserterror Full.TestField(Txt, 'Other', Info);
        Observer.ObserveError('text_message');
        asserterror Full.TestField(Txt, 'Other', Plain);
        Observer.ObserveError('text_plain_info');
        asserterror Full.TestField(Num, 99, Info);
        Observer.ObserveError('int_message');
        asserterror Empty.TestField(Num, Info);
        Observer.ObserveError('empty_int_message');
        asserterror Empty.TestField(Num, Plain);
        Observer.ObserveError('empty_int_plain_info');
        asserterror Empty.TestField(Dt, Info);
        Observer.ObserveError('empty_date_message');
        asserterror Full.TestField(Kind, Full.Kind::One, Info);
        Observer.ObserveError('enum_message');
        asserterror Full.TestField(Flag, false, Plain);
        Observer.ObserveError('bool_plain_info');
        Full.TestField(Txt, 'Hello', Info);
        Observer.Observe('match_no_error', GetLastErrorText());
        Observer.Expect('text_message|text', 'Txt Cap must be equal to ''Other''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.');
        Observer.Expect('text_message|code', 'TestField');
        Observer.Expect('text_plain_info|text', 'Txt Cap must be equal to ''Other''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.');
        Observer.Expect('text_plain_info|code', 'TestField');
        Observer.Expect('int_message|text', 'Num Cap must be equal to ''99''  in P96 Rec Caption: Code Cap=K1. Current value is ''5''.');
        Observer.Expect('int_message|code', 'TestField');
        Observer.Expect('empty_int_message|text', 'Num Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.');
        Observer.Expect('empty_int_message|code', 'TestField');
        Observer.Expect('empty_int_plain_info|text', 'Num Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.');
        Observer.Expect('empty_int_plain_info|code', 'TestField');
        Observer.Expect('empty_date_message|text', 'Dt Cap must have a value in P96 Rec Caption: Code Cap=E1. It cannot be zero or empty.');
        Observer.Expect('empty_date_message|code', 'TestField');
        Observer.Expect('enum_message|text', 'Kind Cap must be equal to ''One''  in P96 Rec Caption: Code Cap=K1. Current value is ''Two''.');
        Observer.Expect('enum_message|code', 'TestField');
        Observer.Expect('bool_plain_info|text', 'Flag Cap must be equal to ''No''  in P96 Rec Caption: Code Cap=K1. Current value is ''Yes''.');
        Observer.Expect('bool_plain_info|code', 'TestField');
        Observer.Expect('match_no_error', '');
        Observer.Verify();
    end;
}
