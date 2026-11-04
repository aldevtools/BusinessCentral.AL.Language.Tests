// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); helper codeunit 85121 in this folder
// Probe: corpus issue #672 (odd AL behavior leads, part G), items 47 to 61. Each test covers only the cases the existing corpus did not pin
// (the file header of each test names the existing pins). Every literal asserted below is what BC produced; other BC versions by the CI matrix.
// BC versions: 27, 28, 29

codeunit 85120 "LT CR Text Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Codes(T: Text): Text
    var
        I: Integer;
        C: Integer;
        R: Text;
    begin
        for I := 1 to StrLen(T) do begin
            C := T[I];
            if R <> '' then
                R += ',';
            R += Format(C);
        end;
        exit(R);
    end;

    [TryFunction]
    local procedure TrySub(T: Text; Pos: Integer; Len: Integer; var Res: Text)
    begin
        Res := T.Substring(Pos, Len);
    end;

    local procedure Sub(T: Text; Pos: Integer; Len: Integer): Text
    var
        Res: Text;
    begin
        if TrySub(T, Pos, Len, Res) then
            exit('ok:' + Res);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    // Item 49 and 50 (Substring past the end). Already pinned: misc/lt-probes-needed-1/PnATextFunctions.al Substring_Cases
    // ('abc': Substring(0), (1,-1), (4) = '', (5) error, (2,10) = 'bc', (1,0), (-1)); text/lt-label-textbuilder/TxCLabel.al (Label receiver).
    // New here: the two-argument form with a start at or past the end, a start of 0 with a length, and the cases named in the lead.
    [Test]
    procedure Substring_StartAndLengthPastEnd()
    var
        Obs: Codeunit "Probe Observer";
        TC: TextConst ENU = 'textconst';
    begin
        Obs.Observe('string_1_20', Sub('string', 1, 20));
        Obs.Observe('abc_2_5', Sub('abc', 2, 5));
        Obs.Observe('digits_1_20', Sub('123456789', 1, 20));
        Obs.Observe('12345_3_10', Sub('12345', 3, 10));
        Obs.Observe('abc_4_0', Sub('abc', 4, 0));
        Obs.Observe('abc_4_1', Sub('abc', 4, 1));
        Obs.Observe('abc_5_0', Sub('abc', 5, 0));
        Obs.Observe('abc_5_1', Sub('abc', 5, 1));
        Obs.Observe('abc_0_1', Sub('abc', 0, 1));
        Obs.Observe('abc_3_1', Sub('abc', 3, 1));
        Obs.Observe('empty_1_0', Sub('', 1, 0));
        Obs.Observe('empty_1_1', Sub('', 1, 1));
        Obs.Observe('empty_2_1', Sub('', 2, 1));
        Obs.Observe('textconst_5_20', TC.Substring(5, 20));
        Obs.Expect('string_1_20', 'ok:string');
        Obs.Expect('abc_2_5', 'ok:bc');
        Obs.Expect('digits_1_20', 'ok:123456789');
        Obs.Expect('12345_3_10', 'ok:345');
        Obs.Expect('abc_4_0', 'ok:');
        Obs.Expect('abc_4_1', 'ok:');
        Obs.Expect('abc_5_0', 'error:startIndex cannot be larger than length of string. (Parameter ''startIndex'')|ArgumentOutOfRange');
        Obs.Expect('abc_5_1', 'error:startIndex cannot be larger than length of string. (Parameter ''startIndex'')|ArgumentOutOfRange');
        Obs.Expect('abc_0_1', 'error:startIndex (''-1'') must be a non-negative value. (Parameter ''startIndex'')\Actual value was -1.|ArgumentOutOfRange');
        Obs.Expect('abc_3_1', 'ok:c');
        Obs.Expect('empty_1_0', 'ok:');
        Obs.Expect('empty_1_1', 'ok:');
        Obs.Expect('empty_2_1', 'error:startIndex cannot be larger than length of string. (Parameter ''startIndex'')|ArgumentOutOfRange');
        Obs.Expect('textconst_5_20', 'const');
        Obs.Verify();
    end;

    // Item 51 (BigText boundaries). Already pinned: streams/StTBigText.al (AddText at 0, -1 and length+2; GetSubText 0, negative, length+1
    // and 20 raise no error; TextPos of '' and of a missing text = 0). New here: the values those calls return.
    [Test]
    procedure BigText_BoundaryValues()
    var
        Obs: Codeunit "Probe Observer";
        Big: BigText;
        T: Text;
        N: Integer;
    begin
        Big.AddText('abc');
        Big.AddText('x', 999);
        Big.GetSubText(T, 1);
        Obs.Observe('add999', T + '|' + Format(Big.Length()));
        Big.AddText('', 1);
        Big.GetSubText(T, 1);
        Obs.Observe('addEmpty', T + '|' + Format(Big.Length()));
        T := 'old';
        N := Big.GetSubText(T, 5, 1);
        Obs.Observe('sub_len_plus_1', T + '|' + Format(N));
        T := 'old';
        N := Big.GetSubText(T, 20);
        Obs.Observe('sub_20', T + '|' + Format(N));
        T := 'old';
        N := Big.GetSubText(T, 3, 50);
        Obs.Observe('sub_3_50', T + '|' + Format(N));
        Clear(Big);
        Obs.Observe('emptyTextPos', Format(Big.TextPos('a')));
        Obs.Observe('emptyTextPosEmpty', Format(Big.TextPos('')));
        Obs.Expect('add999', 'abcx|4');
        Obs.Expect('addEmpty', 'abcx|4');
        Obs.Expect('sub_len_plus_1', '|0');
        Obs.Expect('sub_20', '|0');
        Obs.Expect('sub_3_50', 'cx|2');
        Obs.Expect('emptyTextPos', '0');
        Obs.Expect('emptyTextPosEmpty', '0');
        Obs.Verify();
    end;

    [TryFunction]
    local procedure TrySetCode(var C: Code[10]; Pos: Integer; Ch: Char)
    begin
        C[Pos] := Ch;
    end;

    local procedure SetCode(var C: Code[10]; Pos: Integer; Ch: Char): Text
    begin
        if TrySetCode(C, Pos, Ch) then
            exit('ok:' + C);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TrySetText(var T: Text; Pos: Integer; Ch: Char)
    begin
        T[Pos] := Ch;
    end;

    local procedure SetText(var T: Text; Pos: Integer; Ch: Char): Text
    begin
        if TrySetText(T, Pos, Ch) then
            exit('ok:' + T);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    // Item 52 (index assignment past the end). Already pinned for Text[5]: misc/lt-probes-needed-2/PnBDateFormat.al TextCharAssign
    // (length+1 appends, a gap raises, the declared length is enforced). New here: Code, and an unbounded Text with a gap.
    [Test]
    procedure IndexAssign_CodeAndText()
    var
        Obs: Codeunit "Probe Observer";
        C: Code[10];
        T: Text;
    begin
        C := 'ABC';
        Obs.Observe('code_len_plus_1', SetCode(C, 4, 'd'));
        Obs.Observe('code_gap', SetCode(C, 6, 'x'));
        Obs.Observe('code_replace_lower', SetCode(C, 1, 'q'));
        Obs.Observe('code_after', C + '|' + Format(StrLen(C)));
        C := 'ABCDEFGHIJ';
        Obs.Observe('code_past_declared', SetCode(C, 11, 'K'));
        T := 'abc';
        Obs.Observe('text_len_plus_1', SetText(T, 4, 'd'));
        Obs.Observe('text_gap', SetText(T, 8, 'x'));
        Obs.Observe('text_after', T);
        Obs.Expect('code_len_plus_1', 'ok:ABCD');
        Obs.Expect('code_gap', 'error:The value of INDEXING parameter 1 is outside of the permitted range. The current value is: 6. The permitted range is: from 1 to 4.|OutsidePermittedRange');
        Obs.Expect('code_replace_lower', 'ok:QBCD');
        Obs.Expect('code_after', 'QBCD|4');
        Obs.Expect('code_past_declared', 'error:The length of the string is 11, but it must be less than or equal to 10 characters. Value: ABCDEFGHIJK|StringLengthExceeded');
        Obs.Expect('text_len_plus_1', 'ok:abcd');
        Obs.Expect('text_gap', 'error:The value of INDEXING parameter 1 is outside of the permitted range. The current value is: 8. The permitted range is: from 1 to 4.|OutsidePermittedRange');
        Obs.Expect('text_after', 'abcd');
        Obs.Verify();
    end;

    [TryFunction]
    local procedure TrySetLanguage(Id: Integer)
    begin
        GlobalLanguage(Id);
    end;

    local procedure Cases(var Obs: Codeunit "Probe Observer"; Prefix: Text)
    var
        Upper: Text;
        Lower: Text;
    begin
        Upper := 'I';
        Lower := 'i';
        Obs.Observe(Prefix + 'LowerCase_I', Codes(LowerCase(Upper)));
        Obs.Observe(Prefix + 'ToLower_I', Codes(Upper.ToLower()));
        Obs.Observe(Prefix + 'UpperCase_i', Codes(UpperCase(Lower)));
        Obs.Observe(Prefix + 'ToUpper_i', Codes(Lower.ToUpper()));
        Upper := 'İ';
        Lower := 'ı';
        Obs.Observe(Prefix + 'LowerCase_Idot', Codes(LowerCase(Upper)));
        Obs.Observe(Prefix + 'ToLower_Idot', Codes(Upper.ToLower()));
        Obs.Observe(Prefix + 'UpperCase_dotless', Codes(UpperCase(Lower)));
        Obs.Observe(Prefix + 'ToUpper_dotless', Codes(Lower.ToUpper()));
        Upper := 'ΑΣ';
        Lower := 'ας';
        Obs.Observe(Prefix + 'LowerCase_AS', Codes(LowerCase(Upper)));
        Obs.Observe(Prefix + 'ToLower_AS', Codes(Upper.ToLower()));
        Obs.Observe(Prefix + 'UpperCase_as', Codes(UpperCase(Lower)));
        Obs.Observe(Prefix + 'ToUpper_as', Codes(Lower.ToUpper()));
        Lower := 'ß';
        Obs.Observe(Prefix + 'UpperCase_sz', Codes(UpperCase(Lower)));
        Obs.Observe(Prefix + 'ToUpper_sz', Codes(Lower.ToUpper()));
    end;

    // Item 54 (LowerCase/UpperCase against ToLower/ToUpper under another GlobalLanguage). Already pinned with the default language only:
    // text/lt-text-functions/CaseConv.Codeunit.al, text/lt-text-instance/CaseTrim1.Codeunit.al. New here: GlobalLanguage 1055 (Turkish) and
    // 1032 (Greek). Values are UTF-16 code units.
    [Test]
    procedure CaseConversion_UnderGlobalLanguage()
    var
        Obs: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        Obs.Observe('default_language', Format(Saved));
        Cases(Obs, 'en.');
        if TrySetLanguage(1055) then
            Obs.Observe('set1055', 'ok:' + Format(GlobalLanguage()))
        else
            Obs.Observe('set1055', 'error:' + GetLastErrorText());
        Cases(Obs, 'tr.');
        if TrySetLanguage(1032) then
            Obs.Observe('set1032', 'ok:' + Format(GlobalLanguage()))
        else
            Obs.Observe('set1032', 'error:' + GetLastErrorText());
        Cases(Obs, 'el.');
        GlobalLanguage(Saved);
        Obs.Expect('default_language', '1033');
        Obs.Expect('en.LowerCase_I', '105');
        Obs.Expect('en.ToLower_I', '105');
        Obs.Expect('en.UpperCase_i', '73');
        Obs.Expect('en.ToUpper_i', '73');
        Obs.Expect('en.LowerCase_Idot', '105');
        Obs.Expect('en.ToLower_Idot', '304');
        Obs.Expect('en.UpperCase_dotless', '73');
        Obs.Expect('en.ToUpper_dotless', '305');
        Obs.Expect('en.LowerCase_AS', '945,963');
        Obs.Expect('en.ToLower_AS', '945,963');
        Obs.Expect('en.UpperCase_as', '913,931');
        Obs.Expect('en.ToUpper_as', '913,931');
        Obs.Expect('en.UpperCase_sz', '223');
        Obs.Expect('en.ToUpper_sz', '223');
        Obs.Expect('set1055', 'ok:1055');
        Obs.Expect('tr.LowerCase_I', '305');
        Obs.Expect('tr.ToLower_I', '105');
        Obs.Expect('tr.UpperCase_i', '304');
        Obs.Expect('tr.ToUpper_i', '73');
        Obs.Expect('tr.LowerCase_Idot', '105');
        Obs.Expect('tr.ToLower_Idot', '304');
        Obs.Expect('tr.UpperCase_dotless', '73');
        Obs.Expect('tr.ToUpper_dotless', '305');
        Obs.Expect('tr.LowerCase_AS', '945,963');
        Obs.Expect('tr.ToLower_AS', '945,963');
        Obs.Expect('tr.UpperCase_as', '913,931');
        Obs.Expect('tr.ToUpper_as', '913,931');
        Obs.Expect('tr.UpperCase_sz', '223');
        Obs.Expect('tr.ToUpper_sz', '223');
        Obs.Expect('set1032', 'ok:1032');
        Obs.Expect('el.LowerCase_I', '105');
        Obs.Expect('el.ToLower_I', '105');
        Obs.Expect('el.UpperCase_i', '73');
        Obs.Expect('el.ToUpper_i', '73');
        Obs.Expect('el.LowerCase_Idot', '105');
        Obs.Expect('el.ToLower_Idot', '304');
        Obs.Expect('el.UpperCase_dotless', '73');
        Obs.Expect('el.ToUpper_dotless', '305');
        Obs.Expect('el.LowerCase_AS', '945,963');
        Obs.Expect('el.ToLower_AS', '945,963');
        Obs.Expect('el.UpperCase_as', '913,931');
        Obs.Expect('el.ToUpper_as', '913,931');
        Obs.Expect('el.UpperCase_sz', '223');
        Obs.Expect('el.ToUpper_sz', '223');
        Obs.Verify();
    end;

    local procedure TakeCode20(C: Code[20]): Text
    begin
        exit('[' + C + ']');
    end;

    [TryFunction]
    local procedure TryTake(T: Text[100]; var Res: Text)
    begin
        Res := TakeCode20(T);
    end;

    [TryFunction]
    local procedure TryTakeField(var FinHdr: Record "Finance Charge Memo Header" temporary; var Res: Text)
    begin
        Res := TakeCode20(FinHdr.Name);
    end;

    [TryFunction]
    local procedure TryAssign(T: Text[100]; var C20: Code[20])
    begin
        C20 := T;
    end;

    local procedure Take(T: Text[100]): Text
    var
        Res: Text;
    begin
        if TryTake(T, Res) then
            exit('ok:' + Res);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure TakeField(var FinHdr: Record "Finance Charge Memo Header" temporary): Text
    var
        Res: Text;
    begin
        if TryTakeField(FinHdr, Res) then
            exit('ok:' + Res);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Assign(T: Text[100]): Text
    var
        C20: Code[20];
    begin
        if TryAssign(T, C20) then
            exit('ok:' + C20);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    // Item 56 (a long Text field passed to a Code[20] value parameter). Already pinned for a Label: text/lt-label-textbuilder/TxCLabel.al
    // Label_To_Short_Param_Errors. New here: a Text[100] table field (the reported case) and a Text[100] variable, as argument and in an
    // assignment. A var parameter of type Code[20] does not accept a Text[100] field: tests/must-not-compile/cases/1736-*.al.
    [Test]
    procedure LongTextField_ToCode20Parameter()
    var
        Obs: Codeunit "Probe Observer";
        FinHdr: Record "Finance Charge Memo Header" temporary;
    begin
        FinHdr.Name := 'abcdefghij0123456789';
        Obs.Observe('field20', TakeField(FinHdr));
        FinHdr.Name := 'abcdefghij0123456789x';
        Obs.Observe('field21', TakeField(FinHdr));
        FinHdr.Name := 'abcdefghij0123456789          ';
        Obs.Observe('field20_trailing_spaces', TakeField(FinHdr));
        Obs.Observe('text23', Take('abcdefghij0123456789xyz'));
        Obs.Observe('assign23', Assign('abcdefghij0123456789xyz'));
        Obs.Observe('assign20_trailing_spaces', Assign('abcdefghij0123456789   '));
        Obs.Expect('field20', 'ok:[ABCDEFGHIJ0123456789]');
        Obs.Expect('field21', 'error:The length of the string is 21, but it must be less than or equal to 20 characters. Value: abcdefghij0123456789x|StringLengthExceeded');
        Obs.Expect('field20_trailing_spaces', 'ok:[ABCDEFGHIJ0123456789]');
        Obs.Expect('text23', 'error:The length of the string is 23, but it must be less than or equal to 20 characters. Value: abcdefghij0123456789xyz|StringLengthExceeded');
        Obs.Expect('assign23', 'error:The length of the string is 23, but it must be less than or equal to 20 characters. Value: abcdefghij0123456789xyz|StringLengthExceeded');
        Obs.Expect('assign20_trailing_spaces', 'ok:ABCDEFGHIJ0123456789');
        Obs.Verify();
    end;

    // Item 57 (StrCheckSum). Already pinned: types/TestProbeScalarContracts.al (non-digit source and weight, empty source with a weight,
    // short weight, modulus 7 and 11), types/TestDateRoundFormatStringContracts.al. New here: the defaults, the Learn example and modulus 0/1.
    [Test]
    procedure StrCheckSum_DefaultsAndDocsExample()
    var
        Obs: Codeunit "Probe Observer";
        R: Integer;
    begin
        Obs.Observe('docs_4378_1234_7', Format(StrCheckSum('4378', '1234', 7)));
        Obs.Observe('empty_noweight', Format(StrCheckSum('')));
        Obs.Observe('12345_noweight', Format(StrCheckSum('12345')));
        Obs.Observe('12345_w11111', Format(StrCheckSum('12345', '11111')));
        Obs.Observe('12345_w11111_10', Format(StrCheckSum('12345', '11111', 10)));
        asserterror R := StrCheckSum('123', '12345');
        Obs.ObserveError('123_longweight');
        asserterror R := StrCheckSum('123', '111', 0);
        Obs.ObserveError('mod0');
        Obs.Observe('mod1', Format(StrCheckSum('123', '111', 1)));
        Obs.Expect('docs_4378_1234_7', '0');
        Obs.Expect('empty_noweight', '0');
        Obs.Expect('12345_noweight', '5');
        Obs.Expect('12345_w11111', '5');
        Obs.Expect('12345_w11111_10', '5');
        Obs.Expect('123_longweight|text', 'The weight parameter cannot be longer than the value string.');
        Obs.Expect('123_longweight|code', 'ALSystemString');
        Obs.Expect('mod0|text', 'The modulus parameter cannot be less than 1.');
        Obs.Expect('mod0|code', 'ALSystemString');
        Obs.Expect('mod1', '0');
        Obs.Verify();
    end;

    // Item 59 (StrSubstNo with a placeholder repeated non-adjacently). Already pinned: text/lt-text-functions/StrSubstNo.Codeunit.al
    // (adjacent %1%1), errors/lt-error-handling/ErTErrorFormat.al ('%2%1').
    [Test]
    procedure StrSubstNo_RepeatedNonAdjacent()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Obs.Observe('learn', StrSubstNo('Test %1 %3 %1', 555, 666, 777));
        Obs.Observe('forum', StrSubstNo('%1%2%1', 9, 0));
        Obs.Observe('sep', StrSubstNo('%2%1%3%1%4%1', ';', '1', '2', '3'));
        Obs.Observe('three', StrSubstNo('%1-%2-%1-%2-%1', 'a', 'b'));
        Obs.Expect('learn', 'Test 555 777 555');
        Obs.Expect('forum', '909');
        Obs.Expect('sep', '1;2;3;');
        Obs.Expect('three', 'a-b-a-b-a');
        Obs.Verify();
    end;

    // Item 60 (UTF-16 strings). Already pinned: text/lt-text-instance/Index1.Codeunit.al (StrLen of an emoji = 2 units, its code units,
    // Substring(1, 1) of a pair, ToUpper keeps the length). New here: CopyStr that splits a pair, and case conversion outside the BMP
    // (U+10428 DESERET SMALL LETTER LONG I and U+10400 DESERET CAPITAL LETTER LONG I).
    [Test]
    procedure Utf16_SurrogatePairs()
    var
        Obs: Codeunit "Probe Observer";
        T: Text;
        Small: Text;
        Capital: Text;
    begin
        T := 'a';
        T[2] := 55357;
        T[3] := 56832;
        T[4] := 'b';
        Obs.Observe('copy_1_2', Codes(CopyStr(T, 1, 2)));
        Obs.Observe('copy_3', Codes(CopyStr(T, 3)));
        Obs.Observe('copy_3_1', Codes(CopyStr(T, 3, 1)));
        Obs.Observe('delstr_2_1', Codes(DelStr(T, 2, 1)));
        Obs.Observe('strpos_low', Format(StrPos(T, CopyStr(T, 3, 1))));
        Small[1] := 55297;
        Small[2] := 56360;
        Capital[1] := 55297;
        Capital[2] := 56320;
        Obs.Observe('UpperCase_deseret', Codes(UpperCase(Small)));
        Obs.Observe('ToUpper_deseret', Codes(Small.ToUpper()));
        Obs.Observe('LowerCase_deseret', Codes(LowerCase(Capital)));
        Obs.Observe('ToLower_deseret', Codes(Capital.ToLower()));
        Obs.Observe('compare_upper', Format(UpperCase(Small) = Capital));
        Obs.Expect('copy_1_2', '97,55357');
        Obs.Expect('copy_3', '56832,98');
        Obs.Expect('copy_3_1', '56832');
        Obs.Expect('delstr_2_1', '97,56832,98');
        Obs.Expect('strpos_low', '3');
        Obs.Expect('UpperCase_deseret', '55297,56320');
        Obs.Expect('ToUpper_deseret', '55297,56320');
        Obs.Expect('LowerCase_deseret', '55297,56360');
        Obs.Expect('ToLower_deseret', '55297,56360');
        Obs.Expect('compare_upper', 'Yes');
        Obs.Verify();
    end;

    [TryFunction]
    local procedure TrySelect(N: Integer; S: Text; var Res: Text)
    begin
        Res := SelectStr(N, S);
    end;

    local procedure Select(N: Integer; S: Text): Text
    var
        Res: Text;
    begin
        if TrySelect(N, S, Res) then
            exit('ok:' + Format(StrLen(Res)) + ':' + CopyStr(Res, 1, 20));
        exit('error:' + CopyStr(GetLastErrorText(), 1, 60) + '|' + GetLastErrorCode());
    end;

    // Item 48 (SelectStr: quotes and the 391 character limit). Already pinned: text/lt-text-functions/SelectStr.Codeunit.al (trailing and
    // leading commas, empty items, index errors). New here: double quotes inside the list and long lists. Values: ok:<length>:<first 20>.
    [Test]
    procedure SelectStr_QuotesAndLongList()
    var
        Obs: Codeunit "Probe Observer";
        Long: Text;
    begin
        Obs.Observe('quote_3', Select(3, 'a,b,"c,d",e'));
        Obs.Observe('quote_4', Select(4, 'a,b,"c,d",e'));
        Obs.Observe('quote_5', Select(5, 'a,b,"c,d",e'));
        Obs.Observe('quote_6', Select(6, 'a,b,"c,d",e'));
        Long := PadStr('', 391, 'x');
        Obs.Observe('one_391', Select(1, Long));
        Long := PadStr('', 392, 'x');
        Obs.Observe('one_392', Select(1, Long));
        Long := PadStr('', 1000, 'x');
        Obs.Observe('one_1000', Select(1, Long));
        Long := PadStr('', 394, 'x') + ',' + PadStr('', 5, 'y');
        Obs.Observe('two_400', Select(2, Long));
        Long := PadStr('', 394, 'x') + ',' + PadStr('', 5, 'y') + ',,,';
        Obs.Observe('two_trailing', Select(2, Long));
        Obs.Expect('quote_3', 'ok:2:"c');
        Obs.Expect('quote_4', 'ok:2:d"');
        Obs.Expect('quote_5', 'ok:1:e');
        Obs.Expect('quote_6', 'error:The SELECTSTR comma-string a,b,"c,d",e does not contain a va|InvalidStringFormat');
        Obs.Expect('one_391', 'ok:391:xxxxxxxxxxxxxxxxxxxx');
        Obs.Expect('one_392', 'ok:392:xxxxxxxxxxxxxxxxxxxx');
        Obs.Expect('one_1000', 'ok:1000:xxxxxxxxxxxxxxxxxxxx');
        Obs.Expect('two_400', 'ok:5:yyyyy');
        Obs.Expect('two_trailing', 'ok:5:yyyyy');
        Obs.Verify();
    end;

    // Item 61 (Split with a Char returned by a procedure). The lead's case has the procedure in another app (not pinnable in one app); here
    // the procedure is in another codeunit of the same app. The multi-character separator is already pinned: text/lt-text-instance/
    // Split1.Codeunit.al:105.
    [Test]
    procedure Split_CharFromProcedure()
    var
        Obs: Codeunit "Probe Observer";
        Provider: Codeunit "LT CR Sep Provider";
        Parts: List of [Text];
        Txt: Text;
    begin
        Txt := 'a;b;;c';
        Parts := Txt.Split(Provider.GetSeparator());
        Obs.Observe('char_count', Format(Parts.Count()));
        Obs.Observe('char_3', Parts.Get(3));
        Obs.Observe('char_4', Parts.Get(4));
        Parts := 'Alpha::Bravo::Charlie'.Split('::');
        Obs.Observe('double_colon', Format(Parts.Count()) + '|' + Parts.Get(2));
        Parts := 'Alpha::Bravo::Charlie'.Split(Provider.GetColon());
        Obs.Observe('colon_char', Format(Parts.Count()));
        Obs.Expect('char_count', '4');
        Obs.Expect('char_3', '');
        Obs.Expect('char_4', 'c');
        Obs.Expect('double_colon', '3|Bravo');
        Obs.Expect('colon_char', '5');
        Obs.Verify();
    end;
}

codeunit 85121 "LT CR Sep Provider"
{
    procedure GetSeparator(): Char
    begin
        exit(';');
    end;

    procedure GetColon(): Char
    begin
        exit(':');
    end;
}
