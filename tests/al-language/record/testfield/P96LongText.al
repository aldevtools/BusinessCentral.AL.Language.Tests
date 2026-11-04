// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Fixtures used: table 70738, enum 70739, codeunit 70740 (P96Objects.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TestField with a value longer than the field, with trailing blanks and with a long value; FieldError with long, empty and special texts
// BC versions: 29 (27 and 28 by CI)

codeunit 70746 "LT P96 LongText"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure LongText_Longer_Than_Field()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT P96 Helper";
        Full: Record "LT P96 Rec";
        Empty: Record "LT P96 Rec";
        TenFull: Record "LT P96 Rec";
    begin
        Full.DeleteAll();
        H.Seed();
        Full.Get('K1');
        Empty.Get('E1');
        TenFull.Get('K1');
        TenFull.Txt := 'ABCDEFGHIJ';
        TenFull.Cd := 'ABCDEFGHIJ';
        H.ObservePair(Observer, 'exact_ten', H.RecT(TenFull,2,'ABCDEFGHIJ'), H.RefV(TenFull,2,'ABCDEFGHIJ'));
        H.ObservePair(Observer, 'fifteen_vs_ten', H.RecT(TenFull,2,'ABCDEFGHIJKLMNO'), H.RefV(TenFull,2,'ABCDEFGHIJKLMNO'));
        H.ObservePair(Observer, 'eleven_vs_ten', H.RecT(TenFull,2,'ABCDEFGHIJK'), H.RefV(TenFull,2,'ABCDEFGHIJK'));
        H.ObservePair(Observer, 'ten_plus_blank', H.RecT(TenFull,2,'ABCDEFGHIJ '), H.RefV(TenFull,2,'ABCDEFGHIJ '));
        H.ObservePair(Observer, 'ten_plus_blanks', H.RecT(TenFull,2,'ABCDEFGHIJ     '), H.RefV(TenFull,2,'ABCDEFGHIJ     '));
        H.ObservePair(Observer, 'cd_fifteen_vs_ten', H.RecT(TenFull,3,'ABCDEFGHIJKLMNO'), H.RefV(TenFull,3,'ABCDEFGHIJKLMNO'));
        H.ObservePair(Observer, 'cd_typed_fifteen', H.RecC(TenFull,3,'ABCDEFGHIJKLMNO'), H.RefV(TenFull,3,'ABCDEFGHIJKLMNO'));
        H.ObservePair(Observer, 'pk_fifteen', H.RecT(TenFull,1,'ABCDEFGHIJKLMNO'), H.RefV(TenFull,1,'ABCDEFGHIJKLMNO'));
        Observer.Expect('rec_exact_ten', 'ok');
        Observer.Expect('ref_exact_ten', 'ok');
        Observer.Expect('same_exact_ten', 'Yes');
        Observer.Expect('rec_fifteen_vs_ten', 'Txt Cap must be equal to ''ABCDEFGHIJKLMNO''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABCDEFGHIJ''.|TestField');
        Observer.Expect('ref_fifteen_vs_ten', 'Txt Cap must be equal to ''ABCDEFGHIJKLMNO''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABCDEFGHIJ''.|TestField');
        Observer.Expect('same_fifteen_vs_ten', 'Yes');
        Observer.Expect('rec_eleven_vs_ten', 'Txt Cap must be equal to ''ABCDEFGHIJK''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABCDEFGHIJ''.|TestField');
        Observer.Expect('ref_eleven_vs_ten', 'Txt Cap must be equal to ''ABCDEFGHIJK''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABCDEFGHIJ''.|TestField');
        Observer.Expect('same_eleven_vs_ten', 'Yes');
        Observer.Expect('rec_ten_plus_blank', 'Txt Cap must be equal to ''ABCDEFGHIJ ''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABCDEFGHIJ''.|TestField');
        Observer.Expect('ref_ten_plus_blank', 'Txt Cap must be equal to ''ABCDEFGHIJ ''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABCDEFGHIJ''.|TestField');
        Observer.Expect('same_ten_plus_blank', 'Yes');
        Observer.Expect('rec_ten_plus_blanks', 'Txt Cap must be equal to ''ABCDEFGHIJ     ''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABCDEFGHIJ''.|TestField');
        Observer.Expect('ref_ten_plus_blanks', 'Txt Cap must be equal to ''ABCDEFGHIJ     ''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABCDEFGHIJ''.|TestField');
        Observer.Expect('same_ten_plus_blanks', 'Yes');
        Observer.Expect('rec_cd_fifteen_vs_ten', 'Cd Cap must be equal to ''ABCDEFGHIJKLMNO''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABCDEFGHIJ''.|TestField');
        Observer.Expect('ref_cd_fifteen_vs_ten', 'Cd Cap must be equal to ''ABCDEFGHIJKLMNO''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABCDEFGHIJ''.|TestField');
        Observer.Expect('same_cd_fifteen_vs_ten', 'Yes');
        Observer.Expect('rec_cd_typed_fifteen', 'Cd Cap must be equal to ''ABCDEFGHIJKLMNO''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABCDEFGHIJ''.|TestField');
        Observer.Expect('ref_cd_typed_fifteen', 'Cd Cap must be equal to ''ABCDEFGHIJKLMNO''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABCDEFGHIJ''.|TestField');
        Observer.Expect('same_cd_typed_fifteen', 'Yes');
        Observer.Expect('rec_pk_fifteen', 'Code Cap must be equal to ''ABCDEFGHIJKLMNO''  in P96 Rec Caption: Code Cap=K1. Current value is ''K1''.|TestField');
        Observer.Expect('ref_pk_fifteen', 'Code Cap must be equal to ''ABCDEFGHIJKLMNO''  in P96 Rec Caption: Code Cap=K1. Current value is ''K1''.|TestField');
        Observer.Expect('same_pk_fifteen', 'Yes');
        Observer.Verify();
    end;





    [Test]
    procedure LongText_Hundred_Fifty_Chars()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT P96 Helper";
        Full: Record "LT P96 Rec";
        Empty: Record "LT P96 Rec";
        Long: Text;
        i: Integer;
    begin
        Full.DeleteAll();
        H.Seed();
        Full.Get('K1');
        Empty.Get('E1');
        for i := 1 to 15 do
            Long += '0123456789';
        H.ObservePair(Observer, 'long_vs_txt', H.RecT(Full,2,Long), H.RefV(Full,2,Long));
        H.ObservePair(Observer, 'long_vs_cd', H.RecT(Full,3,Long), H.RefV(Full,3,Long));
        H.ObservePair(Observer, 'long_vs_empty_txt', H.RecT(Empty,2,Long), H.RefV(Empty,2,Long));
        Observer.Observe('long_len', Format(StrLen(Long)));
        Observer.Expect('rec_long_vs_txt', 'Txt Cap must be equal to ''012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('ref_long_vs_txt', 'Txt Cap must be equal to ''012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789''  in P96 Rec Caption: Code Cap=K1. Current value is ''Hello''.|TestField');
        Observer.Expect('same_long_vs_txt', 'Yes');
        Observer.Expect('rec_long_vs_cd', 'Cd Cap must be equal to ''012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABC''.|TestField');
        Observer.Expect('ref_long_vs_cd', 'Cd Cap must be equal to ''012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789''  in P96 Rec Caption: Code Cap=K1. Current value is ''ABC''.|TestField');
        Observer.Expect('same_long_vs_cd', 'Yes');
        Observer.Expect('rec_long_vs_empty_txt', 'Txt Cap must be equal to ''012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789''  in P96 Rec Caption: Code Cap=E1. Current value is ''''.|TestField');
        Observer.Expect('ref_long_vs_empty_txt', 'Txt Cap must be equal to ''012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789''  in P96 Rec Caption: Code Cap=E1. Current value is ''''.|TestField');
        Observer.Expect('same_long_vs_empty_txt', 'Yes');
        Observer.Expect('long_len', '150');
        Observer.Verify();
    end;

    [Test]
    procedure LongText_FieldError_Message()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT P96 Helper";
        Full: Record "LT P96 Rec";
        Empty: Record "LT P96 Rec";
        Long: Text;
        i: Integer;
    begin
        Full.DeleteAll();
        H.Seed();
        Full.Get('K1');
        Empty.Get('E1');
        for i := 1 to 15 do
            Long += '0123456789';
        H.ObservePair(Observer, 'fe_short', H.RecFieldError(Full,2,2,'short',0), H.RefFieldError(Full,2,2,'short',0));
        H.ObservePair(Observer, 'fe_long', H.RecFieldError(Full,2,2,Long,0), H.RefFieldError(Full,2,2,Long,0));
        H.ObservePair(Observer, 'fe_empty', H.RecFieldError(Full,2,2,'',0), H.RefFieldError(Full,2,2,'',0));
        H.ObservePair(Observer, 'fe_blank', H.RecFieldError(Full,2,2,' ',0), H.RefFieldError(Full,2,2,' ',0));
        H.ObservePair(Observer, 'fe_quotes', H.RecFieldError(Full,2,2,'a ''quoted'' text',0), H.RefFieldError(Full,2,2,'a ''quoted'' text',0));
        H.ObservePair(Observer, 'fe_percent', H.RecFieldError(Full,2,2,'100% %1 done',0), H.RefFieldError(Full,2,2,'100% %1 done',0));
        Observer.Expect('rec_fe_short', 'Txt Cap short in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_fe_short', 'Txt Cap short in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_fe_short', 'Yes');
        Observer.Expect('rec_fe_long', 'Txt Cap 012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789 in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_fe_long', 'Txt Cap 012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789 in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_fe_long', 'Yes');
        Observer.Expect('rec_fe_empty', 'Txt Cap must not be Hello in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_fe_empty', 'Txt Cap must not be Hello in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_fe_empty', 'Yes');
        Observer.Expect('rec_fe_blank', 'Txt Cap   in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_fe_blank', 'Txt Cap   in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_fe_blank', 'Yes');
        Observer.Expect('rec_fe_quotes', 'Txt Cap a ''quoted'' text in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_fe_quotes', 'Txt Cap a ''quoted'' text in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_fe_quotes', 'Yes');
        Observer.Expect('rec_fe_percent', 'Txt Cap 100% %1 done in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('ref_fe_percent', 'Txt Cap 100% %1 done in P96 Rec Caption Code Cap=''K1''.|NCLCSRTS:TableErrorStr');
        Observer.Expect('same_fe_percent', 'Yes');
        Observer.Verify();
    end;
}
