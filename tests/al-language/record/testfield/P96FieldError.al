// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-fielderror-method
// Scope: in-scope
// Fixtures used: table 70738, enum 70739, codeunit 70740 (P96Objects.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Record.FieldError(Field), (Field, Text), (Field, ErrorInfo) versus FieldRef.FieldError; captions and key in the text
// BC versions: 29 (27 and 28 by CI)

codeunit 70748 "LT P96 FieldError"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure FieldError_NoText()
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
        H.ObservePair(Observer, 'code_full', H.RecFieldError(Full,1,1,'',0), H.RefFieldError(Full,1,1,'',0));
        H.ObservePair(Observer, 'txt_full', H.RecFieldError(Full,2,1,'',0), H.RefFieldError(Full,2,1,'',0));
        H.ObservePair(Observer, 'num_full', H.RecFieldError(Full,4,1,'',0), H.RefFieldError(Full,4,1,'',0));
        H.ObservePair(Observer, 'amt_full', H.RecFieldError(Full,6,1,'',0), H.RefFieldError(Full,6,1,'',0));
        H.ObservePair(Observer, 'flag_full', H.RecFieldError(Full,7,1,'',0), H.RefFieldError(Full,7,1,'',0));
        H.ObservePair(Observer, 'dt_full', H.RecFieldError(Full,8,1,'',0), H.RefFieldError(Full,8,1,'',0));
        H.ObservePair(Observer, 'kind_full', H.RecFieldError(Full,12,1,'',0), H.RefFieldError(Full,12,1,'',0));
        H.ObservePair(Observer, 'opt_full', H.RecFieldError(Full,13,1,'',0), H.RefFieldError(Full,13,1,'',0));
        Observer.Expect('rec_code_full', 'Code Cap must not be K1 in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_code_full', 'Code Cap must not be K1 in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_code_full', 'Yes');
        Observer.Expect('rec_txt_full', 'Txt Cap must not be Hello in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_txt_full', 'Txt Cap must not be Hello in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_txt_full', 'Yes');
        Observer.Expect('rec_num_full', 'Num Cap must not be 5 in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_num_full', 'Num Cap must not be 5 in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_num_full', 'Yes');
        Observer.Expect('rec_amt_full', 'Amt Cap must not be 2.5 in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_amt_full', 'Amt Cap must not be 2.5 in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_amt_full', 'Yes');
        Observer.Expect('rec_flag_full', 'Flag Cap must not be Yes in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_flag_full', 'Flag Cap must not be Yes in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_flag_full', 'Yes');
        Observer.Expect('rec_dt_full', 'Dt Cap must not be 06/15/21 in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_dt_full', 'Dt Cap must not be 06/15/21 in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_dt_full', 'Yes');
        Observer.Expect('rec_kind_full', 'Kind Cap must not be Two in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_kind_full', 'Kind Cap must not be Two in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_kind_full', 'Yes');
        Observer.Expect('rec_opt_full', 'Opt Cap must not be Beta in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_opt_full', 'Opt Cap must not be Beta in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_opt_full', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure FieldError_NoText_Empty_Row()
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
        H.ObservePair(Observer, 'code_empty', H.RecFieldError(Empty,1,1,'',0), H.RefFieldError(Empty,1,1,'',0));
        H.ObservePair(Observer, 'txt_empty', H.RecFieldError(Empty,2,1,'',0), H.RefFieldError(Empty,2,1,'',0));
        H.ObservePair(Observer, 'num_empty', H.RecFieldError(Empty,4,1,'',0), H.RefFieldError(Empty,4,1,'',0));
        H.ObservePair(Observer, 'amt_empty', H.RecFieldError(Empty,6,1,'',0), H.RefFieldError(Empty,6,1,'',0));
        H.ObservePair(Observer, 'flag_empty', H.RecFieldError(Empty,7,1,'',0), H.RefFieldError(Empty,7,1,'',0));
        H.ObservePair(Observer, 'dt_empty', H.RecFieldError(Empty,8,1,'',0), H.RefFieldError(Empty,8,1,'',0));
        H.ObservePair(Observer, 'kind_empty', H.RecFieldError(Empty,12,1,'',0), H.RefFieldError(Empty,12,1,'',0));
        H.ObservePair(Observer, 'opt_empty', H.RecFieldError(Empty,13,1,'',0), H.RefFieldError(Empty,13,1,'',0));
        Observer.Expect('rec_code_empty', 'Code Cap must not be E1 in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_code_empty', 'Code Cap must not be E1 in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_code_empty', 'Yes');
        Observer.Expect('rec_txt_empty', 'You must specify Txt Cap in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_txt_empty', 'You must specify Txt Cap in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_txt_empty', 'Yes');
        Observer.Expect('rec_num_empty', 'Num Cap must not be 0 in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_num_empty', 'Num Cap must not be 0 in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_num_empty', 'Yes');
        Observer.Expect('rec_amt_empty', 'Amt Cap must not be 0 in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_amt_empty', 'Amt Cap must not be 0 in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_amt_empty', 'Yes');
        Observer.Expect('rec_flag_empty', 'Flag Cap must not be No in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_flag_empty', 'Flag Cap must not be No in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_flag_empty', 'Yes');
        Observer.Expect('rec_dt_empty', 'You must specify Dt Cap in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_dt_empty', 'You must specify Dt Cap in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_dt_empty', 'Yes');
        Observer.Expect('rec_kind_empty', 'Kind Cap must not be Zero in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_kind_empty', 'Kind Cap must not be Zero in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_kind_empty', 'Yes');
        Observer.Expect('rec_opt_empty', 'Opt Cap must not be Alpha in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_opt_empty', 'Opt Cap must not be Alpha in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_opt_empty', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure FieldError_Text()
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
        H.ObservePair(Observer, 'code_text', H.RecFieldError(Full,1,2,'my text',0), H.RefFieldError(Full,1,2,'my text',0));
        H.ObservePair(Observer, 'txt_text', H.RecFieldError(Full,2,2,'my text',0), H.RefFieldError(Full,2,2,'my text',0));
        H.ObservePair(Observer, 'num_text', H.RecFieldError(Full,4,2,'my text',0), H.RefFieldError(Full,4,2,'my text',0));
        H.ObservePair(Observer, 'amt_text', H.RecFieldError(Full,6,2,'my text',0), H.RefFieldError(Full,6,2,'my text',0));
        H.ObservePair(Observer, 'flag_text', H.RecFieldError(Full,7,2,'my text',0), H.RefFieldError(Full,7,2,'my text',0));
        H.ObservePair(Observer, 'dt_text', H.RecFieldError(Full,8,2,'my text',0), H.RefFieldError(Full,8,2,'my text',0));
        H.ObservePair(Observer, 'kind_text', H.RecFieldError(Full,12,2,'my text',0), H.RefFieldError(Full,12,2,'my text',0));
        H.ObservePair(Observer, 'opt_text', H.RecFieldError(Full,13,2,'my text',0), H.RefFieldError(Full,13,2,'my text',0));
        Observer.Expect('rec_code_text', 'Code Cap my text in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_code_text', 'Code Cap my text in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_code_text', 'Yes');
        Observer.Expect('rec_txt_text', 'Txt Cap my text in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_txt_text', 'Txt Cap my text in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_txt_text', 'Yes');
        Observer.Expect('rec_num_text', 'Num Cap my text in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_num_text', 'Num Cap my text in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_num_text', 'Yes');
        Observer.Expect('rec_amt_text', 'Amt Cap my text in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_amt_text', 'Amt Cap my text in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_amt_text', 'Yes');
        Observer.Expect('rec_flag_text', 'Flag Cap my text in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_flag_text', 'Flag Cap my text in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_flag_text', 'Yes');
        Observer.Expect('rec_dt_text', 'Dt Cap my text in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_dt_text', 'Dt Cap my text in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_dt_text', 'Yes');
        Observer.Expect('rec_kind_text', 'Kind Cap my text in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_kind_text', 'Kind Cap my text in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_kind_text', 'Yes');
        Observer.Expect('rec_opt_text', 'Opt Cap my text in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_opt_text', 'Opt Cap my text in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_opt_text', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure FieldError_Text_Empty_Row()
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
        H.ObservePair(Observer, 'code_text_empty', H.RecFieldError(Empty,1,2,'my text',0), H.RefFieldError(Empty,1,2,'my text',0));
        H.ObservePair(Observer, 'txt_text_empty', H.RecFieldError(Empty,2,2,'my text',0), H.RefFieldError(Empty,2,2,'my text',0));
        H.ObservePair(Observer, 'num_text_empty', H.RecFieldError(Empty,4,2,'my text',0), H.RefFieldError(Empty,4,2,'my text',0));
        H.ObservePair(Observer, 'amt_text_empty', H.RecFieldError(Empty,6,2,'my text',0), H.RefFieldError(Empty,6,2,'my text',0));
        H.ObservePair(Observer, 'flag_text_empty', H.RecFieldError(Empty,7,2,'my text',0), H.RefFieldError(Empty,7,2,'my text',0));
        H.ObservePair(Observer, 'dt_text_empty', H.RecFieldError(Empty,8,2,'my text',0), H.RefFieldError(Empty,8,2,'my text',0));
        H.ObservePair(Observer, 'kind_text_empty', H.RecFieldError(Empty,12,2,'my text',0), H.RefFieldError(Empty,12,2,'my text',0));
        H.ObservePair(Observer, 'opt_text_empty', H.RecFieldError(Empty,13,2,'my text',0), H.RefFieldError(Empty,13,2,'my text',0));
        Observer.Expect('rec_code_text_empty', 'Code Cap my text in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_code_text_empty', 'Code Cap my text in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_code_text_empty', 'Yes');
        Observer.Expect('rec_txt_text_empty', 'Txt Cap my text in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_txt_text_empty', 'Txt Cap my text in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_txt_text_empty', 'Yes');
        Observer.Expect('rec_num_text_empty', 'Num Cap my text in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_num_text_empty', 'Num Cap my text in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_num_text_empty', 'Yes');
        Observer.Expect('rec_amt_text_empty', 'Amt Cap my text in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_amt_text_empty', 'Amt Cap my text in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_amt_text_empty', 'Yes');
        Observer.Expect('rec_flag_text_empty', 'Flag Cap my text in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_flag_text_empty', 'Flag Cap my text in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_flag_text_empty', 'Yes');
        Observer.Expect('rec_dt_text_empty', 'Dt Cap my text in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_dt_text_empty', 'Dt Cap my text in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_dt_text_empty', 'Yes');
        Observer.Expect('rec_kind_text_empty', 'Kind Cap my text in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_kind_text_empty', 'Kind Cap my text in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_kind_text_empty', 'Yes');
        Observer.Expect('rec_opt_text_empty', 'Opt Cap my text in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_opt_text_empty', 'Opt Cap my text in P96 Rec Caption Code Cap=''E1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_opt_text_empty', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure FieldError_ErrorInfo_1()
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
        H.ObservePair(Observer, 'code_m0', H.RecFieldError(Full,1,3,'',0), H.RefFieldError(Full,1,3,'',0));
        H.ObservePair(Observer, 'code_m1', H.RecFieldError(Full,1,3,'',1), H.RefFieldError(Full,1,3,'',1));
        H.ObservePair(Observer, 'txt_m0', H.RecFieldError(Full,2,3,'',0), H.RefFieldError(Full,2,3,'',0));
        H.ObservePair(Observer, 'txt_m1', H.RecFieldError(Full,2,3,'',1), H.RefFieldError(Full,2,3,'',1));
        H.ObservePair(Observer, 'num_m0', H.RecFieldError(Full,4,3,'',0), H.RefFieldError(Full,4,3,'',0));
        H.ObservePair(Observer, 'num_m1', H.RecFieldError(Full,4,3,'',1), H.RefFieldError(Full,4,3,'',1));
        H.ObservePair(Observer, 'amt_m0', H.RecFieldError(Full,6,3,'',0), H.RefFieldError(Full,6,3,'',0));
        H.ObservePair(Observer, 'amt_m1', H.RecFieldError(Full,6,3,'',1), H.RefFieldError(Full,6,3,'',1));
        Observer.Expect('rec_code_m0', 'Code Cap must not be K1 in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_code_m0', 'Code Cap must not be K1 in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_code_m0', 'Yes');
        Observer.Expect('rec_code_m1', 'Code Cap Custom message in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_code_m1', 'Code Cap Custom message in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_code_m1', 'Yes');
        Observer.Expect('rec_txt_m0', 'Txt Cap must not be Hello in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_txt_m0', 'Txt Cap must not be Hello in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_txt_m0', 'Yes');
        Observer.Expect('rec_txt_m1', 'Txt Cap Custom message in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_txt_m1', 'Txt Cap Custom message in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_txt_m1', 'Yes');
        Observer.Expect('rec_num_m0', 'Num Cap must not be 5 in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_num_m0', 'Num Cap must not be 5 in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_num_m0', 'Yes');
        Observer.Expect('rec_num_m1', 'Num Cap Custom message in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_num_m1', 'Num Cap Custom message in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_num_m1', 'Yes');
        Observer.Expect('rec_amt_m0', 'Amt Cap must not be 2.5 in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_amt_m0', 'Amt Cap must not be 2.5 in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_amt_m0', 'Yes');
        Observer.Expect('rec_amt_m1', 'Amt Cap Custom message in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_amt_m1', 'Amt Cap Custom message in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_amt_m1', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure FieldError_ErrorInfo_2()
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
        H.ObservePair(Observer, 'txt_m5', H.RecFieldError(Full,2,3,'',5), H.RefFieldError(Full,2,3,'',5));
        H.ObservePair(Observer, 'txt_m3', H.RecFieldError(Full,2,3,'',3), H.RefFieldError(Full,2,3,'',3));
        H.ObservePair(Observer, 'txt_m4', H.RecFieldError(Full,2,3,'',4), H.RefFieldError(Full,2,3,'',4));
        Observer.Expect('rec_txt_m5', 'Txt Cap Custom message in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_txt_m5', 'Txt Cap Custom message in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_txt_m5', 'Yes');
        Observer.Expect('rec_txt_m3', 'Txt Cap must not be Hello in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_txt_m3', 'Txt Cap must not be Hello in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_txt_m3', 'Yes');
        Observer.Expect('rec_txt_m4', 'Txt Cap must not be Hello in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_txt_m4', 'Txt Cap must not be Hello in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_txt_m4', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure FieldError_Direct_Asserterror()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT P96 Helper";
        Full: Record "LT P96 Rec";
        Info: ErrorInfo;
    begin
        Full.DeleteAll();
        H.Seed();
        Full.Get('K1');
        asserterror Full.FieldError(Txt);
        Observer.ObserveError('no_text');
        asserterror Full.FieldError(Txt, 'my text');
        Observer.ObserveError('text');
        asserterror Full.FieldError(Num, 'my text');
        Observer.ObserveError('int_text');
        asserterror Full.FieldError(Code, 'my text');
        Observer.ObserveError('pk_text');
        Info.Message := 'Custom message';
        asserterror Full.FieldError(Txt, Info);
        Observer.ObserveError('info_message');
        Info.Message := '';
        asserterror Full.FieldError(Txt, Info);
        Observer.ObserveError('info_empty_message');
        asserterror Full.FieldError(Txt, '');
        Observer.ObserveError('empty_text');
        Observer.Expect('no_text|text', 'Txt Cap must not be Hello in P96 Rec Caption Code Cap=''K1''.');
        Observer.Expect('no_text|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('text|text', 'Txt Cap my text in P96 Rec Caption Code Cap=''K1''.');
        Observer.Expect('text|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('int_text|text', 'Num Cap my text in P96 Rec Caption Code Cap=''K1''.');
        Observer.Expect('int_text|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('pk_text|text', 'Code Cap my text in P96 Rec Caption Code Cap=''K1''.');
        Observer.Expect('pk_text|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('info_message|text', 'Txt Cap Custom message in P96 Rec Caption Code Cap=''K1''.');
        Observer.Expect('info_message|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('info_empty_message|text', 'Txt Cap must not be Hello in P96 Rec Caption Code Cap=''K1''.');
        Observer.Expect('info_empty_message|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('empty_text|text', 'Txt Cap must not be Hello in P96 Rec Caption Code Cap=''K1''.');
        Observer.Expect('empty_text|code', 'NCLCSRTS:TableErrorStr');
        Observer.Verify();
    end;

    [Test]
    procedure FieldError_Caption_And_Key_In_Text()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT P96 Helper";
        Full: Record "LT P96 Rec";
        Empty: Record "LT P96 Rec";
        Msg: Text;
    begin
        Full.DeleteAll();
        H.Seed();
        Full.Get('K1');
        Empty.Get('E1');
        Msg := H.RecFieldError(Full, 2, 1, '', 0);
        Observer.Observe('has_field_caption', Format(StrPos(Msg, 'Txt Cap') > 0));
        Observer.Observe('has_field_name', Format(StrPos(Msg, 'Txt ') > 0));
        Observer.Observe('has_table_caption', Format(StrPos(Msg, 'P96 Rec Caption') > 0));
        Observer.Observe('has_key_caption', Format(StrPos(Msg, 'Code Cap=K1') > 0));
        Observer.Observe('has_key_name', Format(StrPos(Msg, 'Code=K1') > 0));
        Msg := H.RecT(Full, 2, 'Other');
        Observer.Observe('tf_has_field_caption', Format(StrPos(Msg, 'Txt Cap') > 0));
        Observer.Observe('tf_has_table_caption', Format(StrPos(Msg, 'P96 Rec Caption') > 0));
        Observer.Observe('tf_has_key_caption', Format(StrPos(Msg, 'Code Cap=K1') > 0));
        Observer.Observe('tf_has_value_hello', Format(StrPos(Msg, 'Hello') > 0));
        Observer.Observe('tf_has_value_other', Format(StrPos(Msg, 'Other') > 0));
        Msg := H.RecNoValue(Empty, 4);
        Observer.Observe('nv_has_field_caption', Format(StrPos(Msg, 'Num Cap') > 0));
        Observer.Observe('nv_has_key_caption', Format(StrPos(Msg, 'Code Cap=E1') > 0));
        Msg := H.RecNoValue(Empty, 12);
        Observer.Observe('kind_nv', Msg);
        Msg := H.RecNoValue(Empty, 13);
        Observer.Observe('opt_nv', Msg);
        Observer.Expect('has_field_caption', 'Yes');
        Observer.Expect('has_field_name', 'Yes');
        Observer.Expect('has_table_caption', 'Yes');
        Observer.Expect('has_key_caption', 'No');
        Observer.Expect('has_key_name', 'No');
        Observer.Expect('tf_has_field_caption', 'Yes');
        Observer.Expect('tf_has_table_caption', 'Yes');
        Observer.Expect('tf_has_key_caption', 'Yes');
        Observer.Expect('tf_has_value_hello', 'Yes');
        Observer.Expect('tf_has_value_other', 'Yes');
        Observer.Expect('nv_has_field_caption', 'Yes');
        Observer.Expect('nv_has_key_caption', 'Yes');
        Observer.Expect('kind_nv', 'Kind Cap must not be Zero in P96 Rec Caption: Code Cap=E1|TestField');
        Observer.Expect('opt_nv', 'Opt Cap must not be Alpha in P96 Rec Caption: Code Cap=E1|TestField');
        Observer.Verify();
    end;
}
